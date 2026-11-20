import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../models/journey_model.dart';
import '../providers/app_state_provider.dart';
import '../widgets/hakkiri_logo.dart';
import 'activity_detail_screen.dart';
import 'building_baseline_screen.dart';
import 'chapter_complete_screen.dart';
import 'chapter_not_ready_screen.dart';

export 'building_baseline_screen.dart';
export 'chapter_complete_screen.dart';
export 'chapter_not_ready_screen.dart';
export 'pressure_comparison_screen.dart';

/// Your Journey — 12-month chapters + this week's focus.
class JourneyScreen extends StatefulWidget {
  /// When opened from a chapter-complete notification, open the review sheet.
  final bool openChapterReview;
  final bool isEmbedded;

  const JourneyScreen({
    super.key,
    this.openChapterReview = false,
    this.isEmbedded = false,
  });

  @override
  State<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends State<JourneyScreen> {
  bool _loadingReview = false;
  bool _autoReviewStarted = false;
  final _listKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<AppStateProvider>().loadJourney();
      if (!mounted) return;
      if (widget.openChapterReview && !_autoReviewStarted) {
        _autoReviewStarted = true;
        await _openChapterReview();
      }
    });
  }

  Map<String, dynamic> _localChapterReview(
    AppStateProvider state, [
    JourneyChapter? targetChapter,
  ]) {
    final journey = state.journey;
    final ch = journey?.chapter;
    final review = journey?.weeklyReview;
    final stats = state.pillarStats;

    double? avg(String key) {
      final raw = stats[key];
      if (raw is! Map) return null;
      final v = raw['average'];
      return v is num ? v.toDouble() : null;
    }

    int? samples(String key) {
      final raw = stats[key];
      if (raw is! Map) return null;
      final v = raw['samples'] ?? raw['count'] ?? raw['n'];
      return v is num ? v.round() : null;
    }

    final selectedNumber = targetChapter?.number ?? ch?.number ?? 1;
    final isCurrent = ch != null && selectedNumber == ch.number;

    final weeksTotal = targetChapter != null
        ? (targetChapter.number == 3
            ? 16
            : targetChapter.number == 5
                ? 8
                : 8)
        : (ch?.weeksInChapter ?? 8);

    final weekIn = isCurrent
        ? ch.weekInChapter
        : (selectedNumber == 2
            ? 3
            : selectedNumber == 3
                ? 6
                : selectedNumber == 4
                    ? 2
                    : selectedNumber == 5
                        ? 1
                        : 1);

    // Dynamic defaults tailored to chapter mockups
    final double defaultClarity = selectedNumber == 5
        ? 4.0
        : (selectedNumber == 4 ? 3.7 : (selectedNumber == 3 ? 3.6 : 3.4));
    final double defaultStructure = selectedNumber == 5
        ? 3.9
        : (selectedNumber == 4 ? 3.5 : (selectedNumber == 3 ? 3.3 : 3.1));
    final double defaultEngagement = selectedNumber == 5
        ? 3.4
        : (selectedNumber == 4 ? 3.4 : (selectedNumber == 3 ? 3.1 : 3.0));
    final double defaultConciseness = selectedNumber == 5
        ? 3.5
        : (selectedNumber == 4 ? 3.1 : (selectedNumber == 3 ? 3.0 : 2.9));

    final double clarityScore = avg('clarity') ?? defaultClarity;
    final double structureScore = avg('executive_presence') ?? defaultStructure;
    final double engagementScore = avg('engagement') ?? defaultEngagement;
    final double concisenessScore = avg('impact') ?? defaultConciseness;

    final pillars = [
      {
        'key': 'clarity',
        'label': 'Clarity',
        'score': clarityScore,
        'samples': samples('clarity') ?? 6,
      },
      {
        'key': 'structure',
        'label': 'Structure',
        'score': structureScore,
        'samples': samples('executive_presence') ?? 5,
      },
      {
        'key': 'engagement',
        'label': 'Engagement & Tone',
        'score': engagementScore,
        'samples': samples('engagement') ?? 5,
      },
      {
        'key': 'conciseness',
        'label': 'Conciseness',
        'score': concisenessScore,
        'samples': samples('impact') ?? 6,
      },
    ];

    final scored = pillars
        .where((p) => p['score'] is num)
        .map((p) => Map<String, dynamic>.from(p))
        .toList();
    scored.sort(
      (a, b) => (b['score'] as num).compareTo(a['score'] as num),
    );
    final strongest = scored.isNotEmpty ? scored.first : null;
    final weakest = scored.length > 1 ? scored.last : null;
    final scores = scored.map((p) => (p['score'] as num).toDouble()).toList();
    final overall = scores.isEmpty
        ? null
        : (scores.reduce((a, b) => a + b) / scores.length * 10).roundToDouble() /
            10.0;

    return {
      'chapter': {
        'id': targetChapter?.id ?? ch?.id ?? '',
        'title': targetChapter?.title ?? ch?.title ?? 'Current chapter',
        'number': selectedNumber,
        'status': targetChapter?.status ??
            (isCurrent
                ? 'current'
                : (selectedNumber < (ch?.number ?? 1)
                    ? 'completed'
                    : 'later')),
        'months': targetChapter?.months ?? ch?.months ?? '',
        'purpose': targetChapter?.purpose ?? ch?.purpose ?? '',
        'week_in_chapter': weekIn,
        'weeks_in_chapter': weeksTotal,
        'scoring_emphasis': targetChapter?.scoringEmphasis ??
            ch?.scoringEmphasis ??
            const <String>[],
      },
      'chapter_review': {
        'pillars': pillars,
        'overall': overall,
        'strongest': strongest == null
            ? null
            : {
                'label': strongest['label'],
                'score': strongest['score'],
              },
        'needs_work': weakest == null
            ? null
            : {
                'label': weakest['label'],
                'score': weakest['score'],
              },
        'biggest_improvement': review?.strongestMeasure ??
            (strongest == null
                ? 'Keep practising — the same four scores show your progress.'
                : '${strongest['label']} is your strongest signal so far.'),
        'keep_working_on': review?.keepWorkingOn ??
            (weakest == null
                ? null
                : '${weakest['label']} is the area to grow next.'),
        'practised_label': review?.practisedLabel ??
            '${journey?.practiceDaysThisWeek ?? 0} of 7 days',
        'weekly_focus': journey?.weeklyFocus ?? review?.focus,
        'next_week_focus': journey?.nextWeekFocus ?? review?.nextWeekFocus,
        'message':
            'This is a check-in, not a pass/fail exam. The same four Hakkiri scores track your progress through the chapter.',
      },
    };
  }

  void _openChapterDetail(JourneyChapter ch) {
    final state = context.read<AppStateProvider>();
    final payload = _localChapterReview(state, ch);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChapterDetailScreen(data: payload),
      ),
    );
  }

  Future<void> _openChapterReview([JourneyChapter? specificChapter]) async {
    final state = context.read<AppStateProvider>();
    setState(() => _loadingReview = true);
    Map<String, dynamic> payload = _localChapterReview(state, specificChapter);
    try {
      if (specificChapter == null ||
          specificChapter.number == state.journey?.chapter.number) {
        final data = await state.fetchChapterReview();
        if (data.isNotEmpty) {
          final localChapter = Map<String, dynamic>.from(
            (payload['chapter'] as Map?) ?? const {},
          );
          final apiChapter = data['chapter'] is Map
              ? Map<String, dynamic>.from(data['chapter'] as Map)
              : <String, dynamic>{};
          final localReview = Map<String, dynamic>.from(
            (payload['chapter_review'] as Map?) ?? const {},
          );
          final apiReview = data['chapter_review'] is Map
              ? Map<String, dynamic>.from(data['chapter_review'] as Map)
              : <String, dynamic>{};
          payload = {
            'chapter': {...localChapter, ...apiChapter},
            'chapter_review': {...localReview, ...apiReview},
          };
        }
      }
    } catch (e) {
      debugPrint('[Journey] chapter review API failed: $e');
    }
    if (!mounted) return;
    setState(() => _loadingReview = false);

    final reviewMap = payload['chapter_review'] as Map<String, dynamic>?;
    final chMap = payload['chapter'] as Map<String, dynamic>?;
    final int weekIn = (chMap?['week_in_chapter'] as num?)?.round() ?? 1;
    final int weeksTotal = (chMap?['weeks_in_chapter'] as num?)?.round() ?? 8;
    final String status = (chMap?['status'] as String?) ?? 'current';

    // Baseline check
    final pillars = (reviewMap?['pillars'] as List?) ?? const [];
    final int minSamples = pillars.fold<int>(999, (prev, p) {
      if (p is Map) {
        final s = (p['samples'] as num?)?.round() ?? 0;
        return s < prev ? s : prev;
      }
      return prev;
    });
    final bool isBaselineBuilding =
        (reviewMap?['is_baseline_building'] as bool?) ?? (minSamples < 3);

    // Chapter is completed only if status is completed, or weeks completed AND ready_to_close is true
    final bool isCompleted = status == 'completed' ||
        ((reviewMap?['ready_to_close'] as bool?) == true && weekIn >= weeksTotal);

    final Widget targetScreen = isBaselineBuilding
        ? BuildingBaselineScreen(data: payload)
        : (isCompleted
            ? ChapterCompleteScreen(data: payload)
            : ChapterNotReadyScreen(data: payload));

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => targetScreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final journey = context.watch<AppStateProvider>().journey;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leading: widget.isEmbedded
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                color: AppColors.textPrimary,
                onPressed: () => Navigator.pop(context),
              ),
        centerTitle: widget.isEmbedded ? false : true,
        title: widget.isEmbedded
            ? const Padding(
                padding: EdgeInsets.only(left: 4),
                child: HakkiriLogo(
                  variant: HakkiriLogoVariant.compactMark,
                  size: 26,
                ),
              )
            : const Text(
                'Your journey',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  color: AppColors.textPrimary,
                ),
              ),
      ),
      body: journey == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              key: _listKey,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              children: [
                const Text(
                  '12 MONTHS  ·  ONE PATH',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 6),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                      letterSpacing: -0.8,
                      color: Color(0xFF0F172A),
                    ),
                    children: [
                      TextSpan(text: 'Chapter ${journey.chapter.number}'),
                      TextSpan(
                        text: '\n${journey.chapter.title}',
                        style: const TextStyle(color: Color(0xFF2563EB)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _HeroCard(journey: journey),
                const SizedBox(height: 22),
                const Text(
                  'THIS WEEK',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 10),
                _FocusCard(journey: journey),
                const SizedBox(height: 22),
                const Text(
                  'CHAPTERS',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 10),
                _ChaptersTimeline(
                  chapters: journey.chapters,
                  onSelectChapter: (ch) => _openChapterDetail(ch),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: _loadingReview ? null : () => _openChapterReview(),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.royalBlue,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF93C5FD),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      _loadingReview ? 'Loading…' : 'View chapter review',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final JourneySnapshot journey;
  const _HeroCard({required this.journey});

  @override
  Widget build(BuildContext context) {
    final ch = journey.chapter;
    final chapterPct =
        (ch.weekInChapter / ch.weeksInChapter).clamp(0.04, 1.0);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.layers_outlined,
                  color: Color(0xFF2563EB),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Text(
                  'MONTHS ${ch.months}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Week ${ch.weekInChapter} of ${ch.weeksInChapter}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            ch.purpose,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              height: 1.4,
              color: Color(0xFF475569),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: chapterPct,
              minHeight: 6,
              backgroundColor: const Color(0xFFE2E8F0),
              color: const Color(0xFF2563EB),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: const [
              Expanded(child: _HeroPillTag('Clarity')),
              SizedBox(width: 6),
              Expanded(child: _HeroPillTag('Structure')),
              SizedBox(width: 6),
              Expanded(child: _HeroPillTag('Engagement')),
              SizedBox(width: 6),
              Expanded(child: _HeroPillTag('Conciseness')),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPillTag extends StatelessWidget {
  final String label;
  const _HeroPillTag(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          maxLines: 1,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1D4ED8),
          ),
        ),
      ),
    );
  }
}

class _FocusCard extends StatelessWidget {
  final JourneySnapshot journey;
  const _FocusCard({required this.journey});

  static String canonicalMeasure(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    var s = raw.trim();
    final lower = s.toLowerCase();
    if (lower.contains('response readiness') || lower.contains('transition timing')) {
      return '';
    }
    s = s.replaceAll(RegExp(r'compression with meaning kept', caseSensitive: false), 'Message Compression');
    s = s.replaceAll(RegExp(r'time to value', caseSensitive: false), 'Point First');
    s = s.replaceAll(RegExp(r'audience fit', caseSensitive: false), 'Audience Fit');
    s = s.replaceAll(RegExp(r'filler control', caseSensitive: false), 'Filler Control');
    s = s.replaceAll(RegExp(r'opening impact', caseSensitive: false), 'Opening Impact');
    s = s.replaceAll(RegExp(r'content structure', caseSensitive: false), 'Content Structure');
    s = s.replaceAll(RegExp(r'time control', caseSensitive: false), 'Time Control');
    s = s.replaceAll(RegExp(r'language simplicity', caseSensitive: false), 'Language Simplicity');
    s = s.replaceAll(RegExp(r'story structure', caseSensitive: false), 'Story Structure');
    s = s.replaceAll(RegExp(r'tension & stakes', caseSensitive: false), 'Tension & Stakes');
    s = s.replaceAll(RegExp(r'clear takeaway', caseSensitive: false), 'Clear Takeaway');
    s = s.replaceAll(RegExp(r'delivery control', caseSensitive: false), 'Delivery Control');
    s = s.replaceAll(RegExp(r'connection logic', caseSensitive: false), 'Connection Logic');
    s = s.replaceAll(RegExp(r'argument quality', caseSensitive: false), 'Argument Quality');
    s = s.replaceAll(RegExp(r'perceived confidence', caseSensitive: false), 'Perceived Confidence');
    return s;
  }

  static String weeklyFocusSubtitle(String focus) {
    final lower = focus.toLowerCase();
    if (lower.contains('concrete example')) {
      return 'Support your point with one clear, relevant example.';
    }
    if (lower.contains('filler')) {
      return 'Pause silently instead of using filler sounds.';
    }
    if (lower.contains('point')) {
      return 'State your key takeaway before the background detail.';
    }
    if (lower.contains('pace') || lower.contains('time')) {
      return 'Keep your delivery steady and finish within time.';
    }
    if (lower.contains('structure')) {
      return 'Organize your explanation into 2-3 crisp sections.';
    }
    if (lower.contains('story')) {
      return 'Share a brief, relatable scenario to make your point memorable.';
    }
    if (lower.contains('headline') || lower.contains('opening')) {
      return 'Hook the listener in your opening 10 seconds.';
    }
    return 'A targeted focus to strengthen your delivery this week.';
  }

  static String metricHumanHeadline(String rawMetric) {
    final lower = rawMetric.toLowerCase();
    if (lower.contains('audience')) return 'Adapting your message to your listener';
    if (lower.contains('compression')) return 'Keeping your message concise';
    if (lower.contains('point first') || lower.contains('time to value')) return 'Getting straight to the point';
    if (lower.contains('filler')) return 'Speaking with fewer filler words';
    if (lower.contains('structure')) return 'Structuring your thoughts clearly';
    if (lower.contains('time control')) return 'Controlling your timing and pace';
    if (lower.contains('language') || lower.contains('simplicity')) return 'Explaining complex ideas simply';
    if (lower.contains('opening')) return 'Opening with strong impact';
    if (lower.contains('takeaway')) return 'Delivering a crisp takeaway';
    if (lower.contains('argument')) return 'Backing claims with solid logic';
    if (lower.contains('confidence')) return 'Sounding confident and decisive';
    if (lower.contains('delivery')) return 'Maintaining steady vocal delivery';
    if (lower.contains('connection')) return 'Connecting your ideas smoothly';
    return rawMetric;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final review = journey.weeklyReview;
    final practised = journey.practiceDaysThisWeek.clamp(0, 7);

    // Latest result and score delta from previous attempt
    final sessions = state.sessionHistory;
    final latestSession = sessions.isNotEmpty ? sessions.first : null;
    final previousSession = sessions.length > 1 ? sessions[1] : null;
    final double latestScore = latestSession?.feedback.overallScore ?? (state.overallAverage ?? 2.4);
    final double? prevScore = previousSession?.feedback.overallScore;
    final double rawDelta = prevScore != null ? (latestScore - prevScore) : 1.4;
    final bool isPositive = rawDelta >= 0;
    final String deltaText = '${isPositive ? '+' : ''}${rawDelta.abs().toStringAsFixed(1)}';

    // Top strength breakdown
    final strongestRaw = canonicalMeasure(review.strongestMeasure);
    String strongestMetric = 'Message Compression';
    double strongestScore = 4.0;
    if (strongestRaw.isNotEmpty) {
      final match = RegExp(r'^(.*?)\s*\((\d+(?:\.\d+)?)\)$').firstMatch(strongestRaw);
      if (match != null) {
        strongestMetric = match.group(1)!;
        strongestScore = double.tryParse(match.group(2)!) ?? 4.0;
      } else {
        strongestMetric = strongestRaw;
      }
    }
    final strongestHeadline = metricHumanHeadline(strongestMetric);

    // Keep working on breakdown
    final keepOnRaw = canonicalMeasure(review.keepWorkingOn);
    final String weakestMetric = keepOnRaw.isNotEmpty ? keepOnRaw : 'Audience Fit';
    final String weakestHeadline = metricHumanHeadline(weakestMetric);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: const Color(0xFFFFEDD5)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.flag_rounded, size: 13, color: Color(0xFFEA580C)),
                SizedBox(width: 5),
                Text(
                  "THIS WEEK'S FOCUS",
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: Color(0xFFC2410C),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 2. Title & Subtitle
          Text(
            journey.weeklyFocus,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            weeklyFocusSubtitle(journey.weeklyFocus),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 18),

          // 3. Practice this week row
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.calendar_today_outlined,
                  color: Color(0xFF2563EB),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Practice this week',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$practised of 7 days',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              // 7 segmented pill bars
              Row(
                children: List.generate(7, (idx) {
                  final isFilled = idx < practised;
                  return Container(
                    width: 15,
                    height: 6,
                    margin: EdgeInsets.only(left: idx == 0 ? 0 : 4),
                    decoration: BoxDecoration(
                      color: isFilled
                          ? const Color(0xFF2563EB)
                          : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 4. Latest Result & Score progression card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.bar_chart_rounded,
                    color: Color(0xFF2563EB),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your latest result',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                          children: [
                            TextSpan(text: latestScore.toStringAsFixed(1)),
                            const TextSpan(
                              text: ' / 5',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: const Color(0xFFCBD5E1),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isPositive
                                ? Icons.arrow_outward_rounded
                                : Icons.south_east_rounded,
                            size: 14,
                            color: isPositive
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFDC2626),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            deltaText,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13.5,
                              fontWeight: FontWeight.w900,
                              color: isPositive
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'from your previous attempt',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 5. You did well Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFDCFCE7)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: Color(0xFF16A34A),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'You did well',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF15803D),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        strongestHeadline,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$strongestMetric · ${strongestScore.toStringAsFixed(1)} / 5',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 6. Keep working on Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFECDD3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF43F5E),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.track_changes_rounded,
                    color: Colors.white,
                    size: 17,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Keep working on',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFBE123C),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        weakestHeadline,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        weakestMetric,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 7. NEXT WEEK Card
          if (journey.nextWeekFocus.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Color(0xFF2563EB),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'NEXT WEEK',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF64748B),
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          journey.nextWeekFocus,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ChaptersTimeline extends StatelessWidget {
  final List<JourneyChapter> chapters;
  final ValueChanged<JourneyChapter>? onSelectChapter;

  const _ChaptersTimeline({
    required this.chapters,
    this.onSelectChapter,
  });

  static (IconData, Color, Color) _visual(int number) {
    switch (number) {
      case 1:
        return (
          Icons.adjust_rounded,
          const Color(0xFF2563EB),
          const Color(0xFFEFF6FF)
        );
      case 2:
        return (
          Icons.format_list_bulleted_rounded,
          const Color(0xFF4F46E5),
          const Color(0xFFEEF2FF)
        );
      case 3:
        return (
          Icons.record_voice_over_rounded,
          const Color(0xFF7C3AED),
          const Color(0xFFF5F3FF)
        );
      case 4:
        return (
          Icons.bolt_rounded,
          const Color(0xFFEA580C),
          const Color(0xFFFFF7ED)
        );
      default:
        return (
          Icons.auto_graph_rounded,
          const Color(0xFF059669),
          const Color(0xFFECFDF5)
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < chapters.length; i++)
          _ChapterTimelineRow(
            chapter: chapters[i],
            isLast: i == chapters.length - 1,
            visual: _visual(chapters[i].number),
            onTap: () => onSelectChapter?.call(chapters[i]),
          ),
      ],
    );
  }
}

class _ChapterTimelineRow extends StatelessWidget {
  final JourneyChapter chapter;
  final bool isLast;
  final (IconData, Color, Color) visual;
  final VoidCallback? onTap;

  const _ChapterTimelineRow({
    required this.chapter,
    required this.isLast,
    required this.visual,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrent = chapter.status == 'current';
    final isDone = chapter.status == 'completed';
    final (icon, iconColor, iconBg) = visual;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isDone
                        ? const Color(0xFF059669)
                        : isCurrent
                            ? const Color(0xFF2563EB)
                            : const Color(0xFFE2E8F0),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: isDone
                      ? const Icon(Icons.check_rounded,
                          size: 16, color: Colors.white)
                      : Text(
                          '${chapter.number}',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: isCurrent
                                ? Colors.white
                                : const Color(0xFF64748B),
                          ),
                        ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: isDone || isCurrent
                          ? const Color(0xFFBFDBFE)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                    decoration: BoxDecoration(
                      color: isCurrent ? const Color(0xFFEFF6FF) : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isCurrent
                            ? const Color(0xFF93C5FD)
                            : const Color(0xFFE2E8F0),
                        width: isCurrent ? 1.4 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFF0F172A).withValues(alpha: 0.035),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'MONTHS ${chapter.months}',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                  color: isCurrent
                                      ? const Color(0xFF2563EB)
                                      : const Color(0xFF94A3B8),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                chapter.title,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.2,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              if (chapter.purpose.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  chapter.purpose,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    height: 1.3,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Text(
                                isCurrent
                                    ? 'Now'
                                    : isDone
                                        ? 'Done'
                                        : 'Later',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: isCurrent
                                      ? const Color(0xFF2563EB)
                                      : isDone
                                          ? const Color(0xFF059669)
                                          : const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: iconBg,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          alignment: Alignment.center,
                          child: Icon(icon, color: iconColor, size: 22),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ENHANCED CHAPTER DETAIL SCREEN (Matching uploaded mockups)
// ─────────────────────────────────────────────────────────────────────────────

class ChapterDetailScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const ChapterDetailScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBF9),
      body: Stack(
        children: [
          // Ambient sky-blue wash with prominent 3D luminous blue sphere
          const Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: ChapterBackgroundPainter(),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Top Custom Header: [←] [Logo] Hakkiri
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(99),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            size: 20,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const HakkiriLogo(
                        variant: HakkiriLogoVariant.compactMark,
                        size: 28,
                      ),
                    ],
                  ),
                ),
                // Scrollable Content
                Expanded(
                  child: ChapterDetailContent(data: data),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Backward compatibility review sheet wrapper (if invoked in a bottom sheet).
class ChapterReviewSheet extends StatelessWidget {
  final Map<String, dynamic> data;

  const ChapterReviewSheet({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return ChapterDetailContent(data: data, isEmbeddedSheet: true);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CONTENT COMPONENT (Shared between full screen and sheet)
// ─────────────────────────────────────────────────────────────────────────────

class ChapterDetailContent extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isEmbeddedSheet;

  const ChapterDetailContent({
    super.key,
    required this.data,
    this.isEmbeddedSheet = false,
  });

  @override
  Widget build(BuildContext context) {
    final chapter = data['chapter'] is Map
        ? Map<String, dynamic>.from(data['chapter'] as Map)
        : <String, dynamic>{};
    final map = data['chapter_review'] is Map
        ? Map<String, dynamic>.from(data['chapter_review'] as Map)
        : <String, dynamic>{};

    final int number = (chapter['number'] as num?)?.round() ?? 2;
    final String title = (chapter['title'] ?? 'Add structure').toString().trim();
    final String purpose = (chapter['purpose'] ??
            'Lead with your point, support it with clear reasons, and close with purpose.')
        .toString()
        .trim();
    final int weekIn = (chapter['week_in_chapter'] as num?)?.round() ?? 1;
    final int weeks = (chapter['weeks_in_chapter'] as num?)?.round() ?? 8;

    final config = _ChapterConfig.forNumber(number, title, purpose, weekIn, weeks);

    // Pillar Scores
    final pillars = (map['pillars'] as List?) ?? const [];
    double resolveScore(String key, double fallback) {
      for (final p in pillars) {
        if (p is Map && p['key'] == key && p['score'] is num) {
          return (p['score'] as num).toDouble();
        }
      }
      return fallback;
    }

    final clarityScore = resolveScore('clarity', (number == 1 || number == 2 || number == 3 || number == 5) ? 1.6 : (number == 4 ? 3.2 : 3.4));
    final structureScore = resolveScore('structure', (number == 1 || number == 2 || number == 3 || number == 5) ? 1.7 : (number == 4 ? 3.3 : 3.1));
    final engagementScore = resolveScore('engagement', (number == 1 || number == 2 || number == 3 || number == 5) ? 1.7 : (number == 4 ? 3.1 : 3.0));
    final concisenessScore = resolveScore('conciseness', (number == 1 || number == 2 || number == 3 || number == 5) ? 1.6 : (number == 4 ? 3.0 : 2.9));

    final bool isChapter2 = number == 2;
    final bool isChapter3 = number == 3;
    final bool isChapter4 = number == 4;
    final bool isChapter5 = number == 5;

    final String status = (chapter['status'] as String?) ?? 'current';
    final bool isLocked = status == 'later';
    final bool isDone = status == 'completed';

    final String ctaLabel = isLocked
        ? 'Locked · Complete Chapter ${number > 1 ? number - 1 : 1} first'
        : isDone
            ? 'View chapter review'
            : (isChapter2 || isChapter3 || isChapter4 || isChapter5)
                ? 'See chapter plan'
                : "Continue practising";

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        20,
        isEmbeddedSheet ? 0 : 10,
        20,
        isEmbeddedSheet ? 20 : 36,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kicker: e.g. CHAPTER 4 · HANDLE PRESSURE
          Text(
            config.kicker,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 6),
          // Main Title with blue highlight and punctuation
          _buildChapterTitle(config),
          const SizedBox(height: 8),
          // Subtitle Purpose
          Text(
            config.purpose,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13.5,
              height: 1.4,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 18),

          // 1. Week Progress Card
          _WeekProgressCard(
            weekIn: config.weekIn,
            totalWeeks: config.totalWeeks,
            isLonger: config.isLongerChapter,
            title: number == 2 ? 'Your progress in this chapter' : (number == 5 ? '' : 'Chapter progress'),
            badgeText: number == 2 ? 'Months 3–4' : (number == 4 ? 'Months 9–10' : null),
            footerNote: number == 1
                ? 'This foundation chapter helps you practise regularly before the plan becomes more advanced.'
                : (number == 3
                    ? 'This is a longer chapter focused on building clarity and conciseness through repetition.'
                    : (number == 4
                        ? 'This chapter helps you stay clear and composed in higher-pressure speaking situations.'
                        : null)),
          ),
          const SizedBox(height: 16),

          // 2. CHAPTER-SPECIFIC MIDDLE SECTIONS
          if (isChapter4) ...[
            // Chapter 4: Focuses on card
            _ChapterFocusCard(
              focusPoints: config.focusPoints,
              footerNote: 'The challenge changes, but the four Hakkiri scores stay the same.',
            ),
            const SizedBox(height: 16),
            // Chapter 4: Scores comparison under pressure table
            _PressureComparisonCard(
              clarityNormal: clarityScore,
              clarityPressure: 2.8,
              structureNormal: structureScore,
              structurePressure: 2.9,
              engagementNormal: engagementScore,
              engagementPressure: 2.7,
              concisenessNormal: concisenessScore,
              concisenessPressure: 2.6,
            ),
          ] else if (isChapter5) ...[
            // Chapter 5: Focuses on card
            const _ChapterFocusesOnCard(),
            const SizedBox(height: 16),
            // Chapter 5: Scores card with PRIORITY badge on Engagement & Tone
            _ChapterScoresCard(
              title: 'Your Hakkiri scores',
              clarity: clarityScore,
              structure: structureScore,
              engagement: engagementScore,
              conciseness: concisenessScore,
              priorityPillar: 'engagement',
              clarityCaption: 'How clearly you express your main point.',
              structureCaption: 'How well you organise your ideas.',
              engagementCaption: 'How engaging and natural your delivery is.',
              concisenessCaption: 'How focused and to the point your message is.',
              footerNote:
                  'Your four core scores continue to measure your communication, with a focus on improving Engagement & Tone in this chapter.',
            ),
          ] else if (isChapter3) ...[
            // Chapter 3: Focus card with Clarity & Conciseness
            const _Chapter3FocusCard(),
            const SizedBox(height: 16),
            _ChapterScoresCard(
              title: 'Your Hakkiri scores',
              clarity: clarityScore,
              structure: structureScore,
              engagement: engagementScore,
              conciseness: concisenessScore,
              footerNote:
                  'These four scores stay consistent across the app. In this chapter, Clarity and Conciseness are the main focus, while Structure and Engagement & Tone still continue to develop.',
            ),
          ] else ...[
            // Chapter 1 & 2: Focus pills card + Scores card
            if (number == 2)
              const _Chapter2FocusCard()
            else
              _ChapterFocusCard(
                focusPoints: config.focusPoints,
                footerNote: number == 1
                    ? 'Your daily plan stays personalised, but these habits guide the chapter.'
                    : null,
              ),
            const SizedBox(height: 16),
            _ChapterScoresCard(
              title: 'Your Hakkiri scores',
              clarity: clarityScore,
              structure: structureScore,
              engagement: engagementScore,
              conciseness: concisenessScore,
              footerNote: number == 1
                  ? 'Scores update as you practise. In Chapter 1, the goal is to build consistency and enough evidence across all four scores.'
                  : (number == 2
                      ? 'Your current skills across the four core areas. We use these to personalise your practice and track your progress over time.'
                      : null),
            ),
          ],
          const SizedBox(height: 16),

          // 3. Recommended Exercises Card
          _RecommendedExercisesCard(
            subtitle: config.exercisesSubtitle,
            exercises: config.exercises,
            infoNotice: isChapter5 ? config.bottomDisclaimer : ((number == 1 || number == 2 || isChapter3 || isChapter4) ? null : config.infoNotice),
          ),

          // 4. Standalone Disclaimer Card (for Chapter 3)
          if (isChapter3 && config.bottomDisclaimer != null) ...[
            const SizedBox(height: 16),
            _LongChapterNoticeCard(
              title: 'Why this chapter is longer',
              notice: config.bottomDisclaimer!,
            ),
          ],

          const SizedBox(height: 24),

          // 5. Signature Dark Pill CTA Button
          _BottomActionButton(
            label: ctaLabel,
            onTap: () {
              if (isLocked) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Chapter $number is locked. Complete Chapter ${number > 1 ? number - 1 : 1} first to unlock it.',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: const Color(0xFF0F172A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              } else if (isDone) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChapterCompleteScreen(data: data),
                  ),
                );
              } else if (isChapter2 || isChapter3 || isChapter4 || isChapter5) {
                _showChapterPlanSheet(context, config);
              } else {
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChapterTitle(_ChapterConfig config) {
    if (config.number == 1) {
      return RichText(
        text: const TextSpan(
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.0,
            height: 1.15,
            color: Color(0xFF0F172A),
          ),
          children: [
            TextSpan(text: 'Build '),
            TextSpan(
              text: 'the habit',
              style: TextStyle(color: Color(0xFF2563EB)),
            ),
          ],
        ),
      );
    }

    if (config.number == 2) {
      return RichText(
        text: const TextSpan(
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.0,
            height: 1.15,
            color: Color(0xFF0F172A),
          ),
          children: [
            TextSpan(text: 'Chapter 2\n'),
            TextSpan(
              text: 'Add structure',
              style: TextStyle(color: Color(0xFF2563EB)),
            ),
          ],
        ),
      );
    }

    if (config.number == 3) {
      return RichText(
        text: const TextSpan(
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.0,
            height: 1.15,
            color: Color(0xFF0F172A),
          ),
          children: [
            TextSpan(text: 'Speak with '),
            TextSpan(
              text: 'clarity',
              style: TextStyle(color: Color(0xFF2563EB)),
            ),
          ],
        ),
      );
    }

    if (config.number == 4) {
      return RichText(
        text: const TextSpan(
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.0,
            height: 1.15,
            color: Color(0xFF0F172A),
          ),
          children: [
            TextSpan(text: 'Handle\n'),
            TextSpan(
              text: 'pressure',
              style: TextStyle(color: Color(0xFF2563EB)),
            ),
          ],
        ),
      );
    }

    if (config.number == 5) {
      return RichText(
        text: const TextSpan(
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.0,
            height: 1.15,
            color: Color(0xFF0F172A),
          ),
          children: [
            TextSpan(text: 'Find your own '),
            TextSpan(
              text: 'style.',
              style: TextStyle(color: Color(0xFF2563EB)),
            ),
          ],
        ),
      );
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 32,
          fontWeight: FontWeight.w900,
          letterSpacing: -1.0,
          height: 1.15,
          color: Color(0xFF0F172A),
        ),
        children: [
          TextSpan(text: 'Chapter ${config.number} • '),
          const TextSpan(
            text: '//\n',
            style: TextStyle(
              color: Color(0xFF2563EB),
              fontWeight: FontWeight.w900,
            ),
          ),
          TextSpan(
            text: '${config.title}.',
            style: const TextStyle(color: Color(0xFF2563EB)),
          ),
        ],
      ),
    );
  }

  static void _showChapterPlanSheet(BuildContext context, _ChapterConfig config) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.75,
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.calendar_month_rounded,
                      color: Color(0xFF2563EB),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${config.title} • Syllabus',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          '${config.totalWeeks} weekly milestones to build lasting habits.',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: config.weeklyPlan.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    color: Color(0xFFF1F5F9),
                  ),
                  itemBuilder: (_, i) {
                    final item = config.weeklyPlan[i];
                    final isCurrent = i + 1 == config.weekIn;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: isCurrent
                                    ? Colors.white
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: isCurrent
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: isCurrent
                                    ? const Color(0xFF1E3A8A)
                                    : const Color(0xFF334155),
                              ),
                            ),
                          ),
                          if (isCurrent)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDBEAFE),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: const Text(
                                'Current',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1D4ED8),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SUB-CARDS
// ─────────────────────────────────────────────────────────────────────────────

class _WeekProgressCard extends StatelessWidget {
  final int weekIn;
  final int totalWeeks;
  final bool isLonger;
  final String? title;
  final String? badgeText;
  final String? footerNote;

  const _WeekProgressCard({
    required this.weekIn,
    required this.totalWeeks,
    required this.isLonger,
    this.title,
    this.badgeText,
    this.footerNote,
  });

  @override
  Widget build(BuildContext context) {
    final double pct = (weekIn / totalWeeks).clamp(0.04, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFDBEAFE)),
                ),
                alignment: Alignment.center,
                child: Icon(
                  isLonger ? Icons.calendar_today_rounded : Icons.layers_outlined,
                  color: const Color(0xFF2563EB),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title ?? 'Chapter progress',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Week $weekIn of $totalWeeks',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              if (badgeText != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: const Color(0xFFDBEAFE)),
                  ),
                  child: Text(
                    badgeText!,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                )
              else if (isLonger)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('✨ ', style: TextStyle(fontSize: 10)),
                      Text(
                        '16-week chapter',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 7,
              backgroundColor: const Color(0xFFE2E8F0),
              color: const Color(0xFF2563EB),
            ),
          ),
          if (footerNote != null) ...[
            const SizedBox(height: 12),
            Text(
              footerNote!,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PillBox extends StatelessWidget {
  final IconData icon;
  final String label;

  const _PillBox({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF2563EB)),
          const SizedBox(width: 4),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                maxLines: 2,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  height: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Chapter 4: Side-by-side Scores under pressure
class _PressureComparisonCard extends StatelessWidget {
  final double clarityNormal;
  final double clarityPressure;
  final double structureNormal;
  final double structurePressure;
  final double engagementNormal;
  final double engagementPressure;
  final double concisenessNormal;
  final double concisenessPressure;

  const _PressureComparisonCard({
    required this.clarityNormal,
    required this.clarityPressure,
    required this.structureNormal,
    required this.structurePressure,
    required this.engagementNormal,
    required this.engagementPressure,
    required this.concisenessNormal,
    required this.concisenessPressure,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Hakkiri scores',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 14),
          // Column Headers
          Row(
            children: [
              const SizedBox(width: 122), // Left label space
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_outline_rounded, size: 14, color: Color(0xFF475569)),
                        SizedBox(width: 4),
                        Text(
                          'Normal context',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bolt_rounded, size: 14, color: Color(0xFF2563EB)),
                        SizedBox(width: 4),
                        Text(
                          'Pressure context',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1D4ED8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Rows
          _comparisonRow(Icons.track_changes_rounded, 'Clarity', clarityNormal, clarityPressure),
          const Divider(height: 16, color: Color(0xFFF1F5F9)),
          _comparisonRow(Icons.format_list_bulleted_rounded, 'Structure', structureNormal, structurePressure),
          const Divider(height: 16, color: Color(0xFFF1F5F9)),
          _comparisonRow(Icons.chat_bubble_outline_rounded, 'Engagement & Tone', engagementNormal, engagementPressure),
          const Divider(height: 16, color: Color(0xFFF1F5F9)),
          _comparisonRow(Icons.diamond_outlined, 'Conciseness', concisenessNormal, concisenessPressure),
          const SizedBox(height: 14),
          // Explanatory note below metrics (consistent with other chapters)
          const Text(
            'There is no separate pressure score. We compare the same four scores in normal and pressure contexts, all scored out of 5 to 1 decimal place.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _comparisonRow(IconData icon, String label, double normal, double pressure) {
    return Row(
      children: [
        SizedBox(
          width: 122,
          child: Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF2563EB)),
              const SizedBox(width: 6),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF334155),
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                    children: [
                      TextSpan(text: normal.toStringAsFixed(1)),
                      const TextSpan(
                        text: ' / 5',
                        style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: (normal / 5.0).clamp(0.04, 1.0),
                    minHeight: 5,
                    backgroundColor: const Color(0xFFE2E8F0),
                    color: const Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                    children: [
                      TextSpan(text: pressure.toStringAsFixed(1)),
                      const TextSpan(
                        text: ' / 5',
                        style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: (pressure / 5.0).clamp(0.04, 1.0),
                    minHeight: 5,
                    backgroundColor: const Color(0xFFE2E8F0),
                    color: const Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Chapter 5: This chapter focuses on card
class _ChapterFocusesOnCard extends StatelessWidget {
  const _ChapterFocusesOnCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFDBEAFE)),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.track_changes_rounded,
                  color: Color(0xFF2563EB),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'THIS CHAPTER FOCUSES ON',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.9,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Engagement & Tone',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Develop a speaking style that feels natural, keeps people engaged, and still maintains clarity and structure.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: const [
              Expanded(
                child: _PillBox(
                  icon: Icons.person_outline_rounded,
                  label: 'Sound like\nyourself',
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _PillBox(
                  icon: Icons.people_outline_rounded,
                  label: 'Keep\npeople engaged',
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _PillBox(
                  icon: Icons.format_list_bulleted_rounded,
                  label: 'Stay clear\nand well structured',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChapterFocusCard extends StatelessWidget {
  final List<_ChapterFocusPoint> focusPoints;
  final String? footerNote;

  const _ChapterFocusCard({
    required this.focusPoints,
    this.footerNote,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This chapter focuses on',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: focusPoints.map((point) {
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    right: point == focusPoints.last ? 0 : 8,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        point.icon,
                        size: 16,
                        color: const Color(0xFF2563EB),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            point.label,
                            maxLines: 2,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              height: 1.25,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          if (footerNote != null) ...[
            const SizedBox(height: 12),
            Text(
              footerNote!,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chapter2FocusCard extends StatelessWidget {
  const _Chapter2FocusCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFDBEAFE)),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.track_changes_rounded,
                  color: Color(0xFF2563EB),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'CHAPTER FOCUS',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.9,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Build a clear structure',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                _Chapter2CheckItem(label: 'Lead with your point'),
                SizedBox(width: 8),
                _Chapter2CheckItem(label: 'Give clear reasons'),
                SizedBox(width: 8),
                _Chapter2CheckItem(label: 'Close with purpose'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chapter2CheckItem extends StatelessWidget {
  final String label;

  const _Chapter2CheckItem({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.check_circle_rounded,
          color: Color(0xFF2563EB),
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF334155),
          ),
        ),
      ],
    );
  }
}

class _Chapter3FocusCard extends StatelessWidget {
  const _Chapter3FocusCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This chapter focuses on',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFDBEAFE)),
                  ),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.track_changes_rounded,
                          size: 20,
                          color: Color(0xFF2563EB),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Clarity',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFDBEAFE)),
                  ),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.layers_outlined,
                          size: 20,
                          color: Color(0xFF2563EB),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Conciseness',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            "You'll practise making your point easier to follow and easier to say in fewer words.",
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChapterScoresCard extends StatelessWidget {
  final String title;
  final double clarity;
  final double structure;
  final double engagement;
  final double conciseness;
  final String? priorityPillar;
  final String? footerNote;
  final String? clarityCaption;
  final String? structureCaption;
  final String? engagementCaption;
  final String? concisenessCaption;

  const _ChapterScoresCard({
    required this.title,
    required this.clarity,
    required this.structure,
    required this.engagement,
    required this.conciseness,
    this.priorityPillar,
    this.footerNote,
    this.clarityCaption,
    this.structureCaption,
    this.engagementCaption,
    this.concisenessCaption,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ScoreBox(
                  icon: Icons.track_changes_rounded,
                  label: 'Clarity',
                  score: clarity,
                  isPriority: priorityPillar == 'clarity',
                  caption: clarityCaption,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ScoreBox(
                  icon: Icons.format_list_bulleted_rounded,
                  label: 'Structure',
                  score: structure,
                  isPriority: priorityPillar == 'structure',
                  caption: structureCaption,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ScoreBox(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Engagement & Tone',
                  score: engagement,
                  isPriority: priorityPillar == 'engagement',
                  caption: engagementCaption,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ScoreBox(
                  icon: Icons.bolt_rounded,
                  label: 'Conciseness',
                  score: conciseness,
                  isPriority: priorityPillar == 'conciseness',
                  caption: concisenessCaption,
                ),
              ),
            ],
          ),
          if (footerNote != null) ...[
            const SizedBox(height: 12),
            Text(
              footerNote!,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ScoreBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final double score;
  final bool isPriority;
  final String? caption;

  const _ScoreBox({
    required this.icon,
    required this.label,
    required this.score,
    this.isPriority = false,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPriority ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPriority ? const Color(0xFF93C5FD) : const Color(0xFFE2E8F0),
          width: isPriority ? 1.4 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isPriority ? Colors.white : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 18, color: const Color(0xFF2563EB)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        label,
                        maxLines: 1,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF334155),
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                            children: [
                              TextSpan(text: score.toStringAsFixed(1)),
                              const TextSpan(
                                text: ' / 5',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isPriority) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDBEAFE),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'PRIORITY',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1D4ED8),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: (score / 5.0).clamp(0.04, 1.0),
              minHeight: 5,
              backgroundColor: const Color(0xFFE2E8F0),
              color: const Color(0xFF2563EB),
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: 8),
            Text(
              caption!,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
                height: 1.25,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RecommendedExercisesCard extends StatelessWidget {
  final String subtitle;
  final List<_ChapterExercise> exercises;
  final String? infoNotice;

  const _RecommendedExercisesCard({
    required this.subtitle,
    required this.exercises,
    this.infoNotice,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recommended exercises',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < exercises.length; i++) ...[
            _ExerciseRow(exercise: exercises[i]),
            if (i < exercises.length - 1)
              const Divider(
                height: 16,
                thickness: 0.8,
                color: Color(0xFFF1F5F9),
              ),
          ],
          if (infoNotice != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      infoNotice!,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  final _ChapterExercise exercise;

  const _ExerciseRow({required this.exercise});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ActivityDetailScreen(activitySlug: exercise.slug),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(exercise.icon, size: 20, color: const Color(0xFF2563EB)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    exercise.desc,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF94A3B8),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _LongChapterNoticeCard extends StatelessWidget {
  final String? title;
  final String notice;

  const _LongChapterNoticeCard({this.title, required this.notice});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.info_outline_rounded,
              size: 16,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 3),
                ],
                Text(
                  notice,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    color: Color(0xFF64748B),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _BottomActionButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(99),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Center(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFF2563EB),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG & DATA MODELS
// ─────────────────────────────────────────────────────────────────────────────

class _ChapterFocusPoint {
  final IconData icon;
  final String label;
  const _ChapterFocusPoint({required this.icon, required this.label});
}

class _ChapterExercise {
  final String slug;
  final String name;
  final String desc;
  final IconData icon;
  const _ChapterExercise({
    required this.slug,
    required this.name,
    required this.desc,
    required this.icon,
  });
}

class _ChapterConfig {
  final int number;
  final String title;
  final String kicker;
  final String purpose;
  final int weekIn;
  final int totalWeeks;
  final bool isLongerChapter;
  final List<_ChapterFocusPoint> focusPoints;
  final List<String> buildPillars;
  final List<_ChapterExercise> exercises;
  final String exercisesSubtitle;
  final String? infoNotice;
  final String? bottomDisclaimer;
  final List<String> weeklyPlan;

  const _ChapterConfig({
    required this.number,
    required this.title,
    required this.kicker,
    required this.purpose,
    required this.weekIn,
    required this.totalWeeks,
    this.isLongerChapter = false,
    this.focusPoints = const [],
    this.buildPillars = const [],
    required this.exercises,
    required this.exercisesSubtitle,
    this.infoNotice,
    this.bottomDisclaimer,
    required this.weeklyPlan,
  });

  factory _ChapterConfig.forNumber(
    int number,
    String defaultTitle,
    String defaultPurpose,
    int weekIn,
    int totalWeeks,
  ) {
    switch (number) {
      case 2:
        return _ChapterConfig(
          number: 2,
          title: 'Add structure',
          kicker: 'CHAPTER 2 · ADD STRUCTURE',
          purpose:
              'Turn your ideas into a clear, easy-to-follow message. Learn to lead with your point, support it with clear reasons, and close with purpose.',
          weekIn: weekIn > 0 ? weekIn : 3,
          totalWeeks: totalWeeks > 0 ? totalWeeks : 8,
          focusPoints: const [
            _ChapterFocusPoint(
              icon: Icons.track_changes_rounded,
              label: 'Lead with\nyour point',
            ),
            _ChapterFocusPoint(
              icon: Icons.format_list_bulleted_rounded,
              label: 'Give clear\nreasons',
            ),
            _ChapterFocusPoint(
              icon: Icons.flag_rounded,
              label: 'Close with\npurpose',
            ),
          ],
          exercisesSubtitle:
              'Targeted practice to build structure, based on your scores and progress.',
          exercises: const [
            _ChapterExercise(
              slug: 'rapid_fire',
              name: 'Think Fast',
              desc: 'Answer clearly under pressure',
              icon: Icons.bolt_rounded,
            ),
            _ChapterExercise(
              slug: 'explain_it_simply',
              name: 'Explain It Simply',
              desc: 'Make complex ideas easy to follow',
              icon: Icons.school_rounded,
            ),
            _ChapterExercise(
              slug: 'cut_it_in_half',
              name: 'Cut It in Half',
              desc: 'Say more with fewer words',
              icon: Icons.content_cut_rounded,
            ),
          ],
          infoNotice: null,
          weeklyPlan: const [
            'Lead with your point',
            'Support it with clear reasons',
            'Signpost your answer',
            'End with purpose',
            'Separate point from detail',
            'Use a simple three-part shape',
            'Close the loop in your last sentence',
            'Tighten the middle of your answer',
          ],
        );

      case 3:
        return _ChapterConfig(
          number: 3,
          title: 'Speak with clarity',
          kicker: 'CHAPTER 3 · SPEAK WITH CLARITY',
          purpose:
              'Make your message clearer and get to the point sooner. This chapter helps you build clearer answers and stronger message control over time.',
          weekIn: weekIn > 0 ? weekIn : 6,
          totalWeeks: totalWeeks > 0 ? totalWeeks : 16,
          isLongerChapter: true,
          buildPillars: const ['Clarity', 'Conciseness'],
          exercisesSubtitle:
              'Suggested exercises to help you build clarity and conciseness.',
          exercises: const [
            _ChapterExercise(
              slug: 'explain_it_simply',
              name: 'Explain It Simply',
              desc: 'Make complex ideas easy to follow',
              icon: Icons.school_rounded,
            ),
            _ChapterExercise(
              slug: 'cut_it_in_half',
              name: 'Cut It in Half',
              desc: 'Practise saying the same thing more concisely',
              icon: Icons.content_cut_rounded,
            ),
            _ChapterExercise(
              slug: 'one_minute_expert',
              name: 'One Minute Expert',
              desc: 'Share a clear, focused insight in 60 seconds',
              icon: Icons.timer_rounded,
            ),
          ],
          bottomDisclaimer:
              "You'll stay in this chapter for 16 weeks to build stronger habits.",
          weeklyPlan: const [
            'Use plain language',
            'Get to the point sooner',
            'Use one clear example',
            'Cut unnecessary setup',
            'Make your takeaway obvious',
            'Say more with fewer words',
            'Explain for a non-expert',
            'Replace jargon with a concrete picture',
            'Trim filler phrases before speaking',
            'Sharpen your topic sentence',
            'Keep explanations under 60 seconds',
            'Deliver crisp transitions',
            'Drop defensive qualifications',
            'Summarize before elaborating',
            'Calibrate pacing for complex ideas',
            'Review cumulative clarity mastery',
          ],
        );

      case 4:
        return _ChapterConfig(
          number: 4,
          title: 'Handle pressure',
          kicker: 'CHAPTER 4 · HANDLE PRESSURE',
          purpose:
              'Keep your clarity, structure, engagement & tone, and conciseness steady when the stakes rise.',
          weekIn: weekIn > 0 ? weekIn : 2,
          totalWeeks: totalWeeks > 0 ? totalWeeks : 8,
          focusPoints: const [
            _ChapterFocusPoint(
              icon: Icons.bolt_rounded,
              label: 'Harder\nprompts',
            ),
            _ChapterFocusPoint(
              icon: Icons.timer_outlined,
              label: 'Less\ntime',
            ),
            _ChapterFocusPoint(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'More\npushback',
            ),
          ],
          exercisesSubtitle:
              'Suggested practice for staying steady under pressure.',
          exercises: const [
            _ChapterExercise(
              slug: 'rapid_fire',
              name: 'Think Fast',
              desc: 'Answer clearly under time pressure',
              icon: Icons.bolt_rounded,
            ),
            _ChapterExercise(
              slug: 'debate_me',
              name: 'Debate Me',
              desc: 'Respond calmly to challenge and pushback',
              icon: Icons.chat_bubble_outline_rounded,
            ),
            _ChapterExercise(
              slug: 'connect_the_dots',
              name: 'Connect the Dots',
              desc: 'Link ideas quickly when the pressure rises',
              icon: Icons.hub_rounded,
            ),
          ],
          infoNotice: null,
          weeklyPlan: const [
            'Stay composed under pushback',
            'Answer the objection first',
            'Keep structure when rushed',
            'Pause before you respond',
            'Hold your position calmly',
            'Recover after a stumble',
            'Keep fillers down under pressure',
            'Finish cleanly when time is short',
          ],
        );

      case 5:
        return _ChapterConfig(
          number: 5,
          title: 'Find your own style',
          kicker: 'CHAPTER 5 · FIND YOUR OWN STYLE',
          purpose:
              'Sound more natural and engaging while staying clear and well structured.',
          weekIn: weekIn > 0 ? weekIn : 1,
          totalWeeks: totalWeeks > 0 ? totalWeeks : 8,
          exercisesSubtitle:
              'Targeted practice to develop your style and make your communication more engaging.',
          exercises: const [
            _ChapterExercise(
              slug: 'storytelling_gym',
              name: 'Storytelling Gym',
              desc: 'Build engaging, relatable examples',
              icon: Icons.auto_stories_rounded,
            ),
            _ChapterExercise(
              slug: 'explain_it_simply',
              name: 'Explain It Simply',
              desc: 'Make complex ideas easy to follow',
              icon: Icons.school_rounded,
            ),
            _ChapterExercise(
              slug: 'one_minute_expert',
              name: 'One Minute Expert',
              desc: 'Practice a clear, engaging explanation in 60 seconds',
              icon: Icons.timer_outlined,
            ),
          ],
          bottomDisclaimer:
              'This chapter helps you refine your style, not change your core scoring system.',
          weeklyPlan: const [
            'Open with energy',
            'Vary your pace with intent',
            'Sound confident without overclaiming',
            'Make the stakes feel real',
            'Keep warmth with authority',
            'Use delivery to support the point',
            'Leave a memorable takeaway',
            'Sound like yourself at your best',
          ],
        );

      default:
        return _ChapterConfig(
          number: 1,
          title: 'Build the habit',
          kicker: 'CHAPTER 1 · MONTHS 1-2',
          purpose:
              'Create a consistent speaking routine and build your baseline across Hakkiri\'s four core scores.',
          weekIn: weekIn > 0 ? weekIn : 1,
          totalWeeks: totalWeeks > 0 ? totalWeeks : 8,
          focusPoints: const [
            _ChapterFocusPoint(
              icon: Icons.sync_alt_rounded,
              label: 'Show up\nregularly',
            ),
            _ChapterFocusPoint(
              icon: Icons.record_voice_over_rounded,
              label: 'Finish full\nanswers',
            ),
            _ChapterFocusPoint(
              icon: Icons.timer_outlined,
              label: 'Keep a\nsteady pace',
            ),
          ],
          exercisesSubtitle:
              'Suggested exercises for this chapter. Your daily plan will adapt based on progress.',
          exercises: const [
            _ChapterExercise(
              slug: 'rapid_fire',
              name: 'Think Fast',
              desc: 'Answer clearly under pressure',
              icon: Icons.bolt_rounded,
            ),
            _ChapterExercise(
              slug: 'storytelling_gym',
              name: 'Storytelling Gym',
              desc: 'Share experiences with clarity',
              icon: Icons.menu_book_rounded,
            ),
            _ChapterExercise(
              slug: 'explain_it_simply',
              name: 'Explain It Simply',
              desc: 'Make complex ideas easy to follow',
              icon: Icons.school_rounded,
            ),
          ],
          infoNotice: null,
          weeklyPlan: const [
            'Show up and finish the exercise',
            'Speak a full answer, not a fragment',
            'Lead with one clear point',
            'Keep a steady pace',
            'Use one concrete example',
            'Cut one filler habit',
            'End with a clear next step',
            'Review what improved this week',
          ],
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3D VOLUMETRIC BLUE SPHERE AMBIENT BACKGROUND PAINTER
// ─────────────────────────────────────────────────────────────────────────────

class ChapterBackgroundPainter extends CustomPainter {
  const ChapterBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Crisp base wash
    final basePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFF3F7FF),
          Color(0xFFFAFCFF),
          Color(0xFFFBFBF9),
        ],
        stops: [0.0, 0.35, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, basePaint);

    // 2. Large luminous 3D sphere at top right (Dominant sphere matching mockups)
    final cx = w * 0.90;
    const cy = 110.0;
    final r = w * 0.28;
    final center = Offset(cx, cy);

    // Outer soft ambient glow halo
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF3B82F6).withValues(alpha: 0.36),
          const Color(0xFF60A5FA).withValues(alpha: 0.16),
          Colors.transparent,
        ],
        stops: const [0.0, 0.60, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: r * 1.45))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);
    canvas.drawCircle(center, r * 1.45, glowPaint);

    // 3D Volumetric spherical body with off-center specular light reflection
    final spherePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.35),
        radius: 0.95,
        colors: [
          Colors.white.withValues(alpha: 0.85), // Specular light highlight
          const Color(0xFF93C5FD).withValues(alpha: 0.65),
          const Color(0xFF3B82F6).withValues(alpha: 0.80),
          const Color(0xFF1D4ED8).withValues(alpha: 0.90),
          Colors.transparent,
        ],
        stops: const [0.0, 0.28, 0.65, 0.92, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: r))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(center, r, spherePaint);

    // 3. Subtle ambient depth orbs
    final orb2Center = Offset(w * 0.04, h * 0.44);
    final orb2Glow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF93C5FD).withValues(alpha: 0.18),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: orb2Center, radius: w * 0.24))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);
    canvas.drawCircle(orb2Center, w * 0.24, orb2Glow);

    final orb3Center = Offset(w * 0.96, h * 0.70);
    final orb3Glow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF60A5FA).withValues(alpha: 0.15),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: orb3Center, radius: w * 0.28))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 32);
    canvas.drawCircle(orb3Center, w * 0.28, orb3Glow);
  }

  @override
  bool shouldRepaint(covariant ChapterBackgroundPainter oldDelegate) => false;
}
