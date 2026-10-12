import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../models/session_model.dart';
import '../providers/app_state_provider.dart';
import '../widgets/custom_sparkline.dart';
import '../widgets/hakkiri_logo.dart';
import '../widgets/orbital_background_painter.dart';
import 'activity_detail_screen.dart';
import 'main_tab_scaffold.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainTabScaffold(initialIndex: 1);
  }
}

class ProgressScreenContent extends StatefulWidget {
  const ProgressScreenContent({super.key});

  @override
  State<ProgressScreenContent> createState() => _ProgressScreenContentState();
}

class _ProgressScreenContentState extends State<ProgressScreenContent> {
  int _selectedFilter = 0; // 0: 7 days, 1: 30 days, 2: 3 months

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);

    final filterDuration = _selectedFilter == 0
        ? const Duration(days: 7)
        : _selectedFilter == 1
            ? const Duration(days: 30)
            : const Duration(days: 90);
    final filterLabel = _selectedFilter == 0
        ? '7 days'
        : _selectedFilter == 1
            ? '30 days'
            : '3 months';

    final cutoff = DateTime.now().subtract(filterDuration);
    final filteredSessions = state.sessionHistory
        .where((s) => s.timestamp.isAfter(cutoff))
        .toList();

    // Overall Score for the active period
    final double? periodAverage = filteredSessions.isNotEmpty
        ? (filteredSessions.fold<double>(0.0, (sum, s) => sum + s.feedback.overallScore) /
            filteredSessions.length)
        : state.overallAverage;
    final overallText = periodAverage == null
        ? '—'
        : periodAverage.toStringAsFixed(1);

    final fluency = _periodPillarStat(filteredSessions, state, 'executive_presence');
    final clarity = _periodPillarStat(filteredSessions, state, 'clarity');
    final engagement = _periodPillarStat(filteredSessions, state, 'engagement');
    final impact = _periodPillarStat(filteredSessions, state, 'impact');

    final List<double> sparkline;
    if (filteredSessions.length >= 2) {
      sparkline = filteredSessions
          .take(10)
          .toList()
          .reversed
          .map((s) => s.feedback.overallScore.toDouble())
          .toList();
    } else if (filteredSessions.length == 1) {
      final s = filteredSessions.first.feedback.overallScore.toDouble();
      sparkline = [s, s, s];
    } else if (state.sessionHistory.isNotEmpty) {
      sparkline = state.sessionHistory
          .take(10)
          .toList()
          .reversed
          .map((s) => s.feedback.overallScore.toDouble())
          .toList();
    } else {
      sparkline = const [3.0, 3.0, 3.0];
    }

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Logo + Filter Tabs Pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const HakkiriLogo(
                  variant: HakkiriLogoVariant.compactMark,
                  size: 22,
                ),
                // Pill Selector: [ 7 days | 30 days | 3 months ]
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.surfaceBorder, width: 1.0),
                  ),
                  child: Row(
                    children: [
                      _buildFilterPill(0, '7 days'),
                      _buildFilterPill(1, '30 days'),
                      _buildFilterPill(2, '3 months'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Header Section with Wave Background
            Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  right: -10,
                  top: -10,
                  bottom: -10,
                  width: 140,
                  child: CustomPaint(painter: ProgressWavePainter()),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'YOUR PROGRESS',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: AppColors.textPrimary,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.8,
                          height: 1.15,
                        ),
                        children: [
                          TextSpan(text: "You're getting clearer.\n"),
                          TextSpan(
                            text: 'Keep it going.',
                            style: TextStyle(color: AppColors.royalBlue),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Hero Dark Card (Overall Score + Wavy Chart)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E1B4B).withValues(alpha: 0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Circular Score Ring
                      Container(
                        width: 74,
                        height: 74,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF38BDF8),
                            width: 4.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF38BDF8).withValues(alpha: 0.3),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'OVERALL',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 8.0,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              overallText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const Text(
                              '/ 5',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 9.0,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.local_fire_department_rounded,
                                        color: Color(0xFF10B981),
                                        size: 15,
                                      ),
                                      const SizedBox(width: 2),
                                      Flexible(
                                        child: Text(
                                          '${state.currentStreak}-day streak · ${state.totalXp} XP',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Color(0xFF10B981),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () => _showScoreExplainer(context),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(Icons.info_outline_rounded, color: Colors.white70, size: 10),
                                        SizedBox(width: 2),
                                        Text(
                                          'How scores work',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              filteredSessions.length >= 3
                                  ? 'Great progress.'
                                  : (filteredSessions.isNotEmpty ? 'Keep practising.' : 'Start practising.'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              filteredSessions.isNotEmpty
                                  ? '${filteredSessions.length} session${filteredSessions.length == 1 ? '' : 's'} recorded in the last $filterLabel.'
                                  : 'No sessions yet in the last $filterLabel. ${state.focusLine}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 11.5,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Glowing trendline with dots
                  CustomSparkline(
                    values: sparkline,
                    color: const Color(0xFF60A5FA),
                    strokeWidth: 2.5,
                    height: 28,
                    showDots: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // SKILL BREAKDOWN Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'SKILL BREAKDOWN',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                Row(
                  children: const [
                    Text(
                      'Tap a skill to see more details',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textMuted),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 2x2 Grid of Skill Cards
            Row(
              children: [
                Expanded(
                  child: _buildSkillCard(
                    icon: Icons.mic_rounded,
                    iconColor: const Color(0xFF3B82F6),
                    iconBgColor: const Color(0xFFEFF6FF),
                    title: 'Fluency & presence',
                    scoreText: fluency.$1,
                    deltaText: fluency.$3,
                    isDeltaPositive: fluency.$4,
                    description: 'Steadier pace, fewer hesitations.',
                    sparklinePoints: fluency.$5,
                    sparklineColor: const Color(0xFF3B82F6),
                    isLocked: fluency.$2,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSkillCard(
                    icon: Icons.visibility_rounded,
                    iconColor: const Color(0xFF10B981),
                    iconBgColor: const Color(0xFFECFDF5),
                    title: 'Clarity',
                    scoreText: clarity.$1,
                    deltaText: clarity.$3,
                    isDeltaPositive: clarity.$4,
                    description: 'Your main points are easier to follow.',
                    sparklinePoints: clarity.$5,
                    sparklineColor: const Color(0xFF10B981),
                    isLocked: clarity.$2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSkillCard(
                    icon: Icons.auto_awesome_rounded,
                    iconColor: const Color(0xFFEF4444),
                    iconBgColor: const Color(0xFFFEF2F2),
                    title: 'Engagement & tone',
                    scoreText: engagement.$1,
                    deltaText: engagement.$3,
                    isDeltaPositive: engagement.$4,
                    description: engagement.$2
                        ? 'Complete more sessions to unlock this score.'
                        : 'Keep people with you.',
                    sparklinePoints: engagement.$5,
                    sparklineColor: const Color(0xFFCBD5E1),
                    isLocked: engagement.$2,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSkillCard(
                    icon: Icons.content_cut_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    iconBgColor: const Color(0xFFFFFBEB),
                    title: 'Conciseness',
                    scoreText: impact.$1,
                    deltaText: impact.$3,
                    isDeltaPositive: impact.$4,
                    description: 'Get to the point faster.',
                    sparklinePoints: impact.$5,
                    sparklineColor: const Color(0xFFF59E0B),
                    isLocked: impact.$2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // RECOMMENDED NEXT Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFFEF3C7), width: 1.0),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.content_cut_rounded, color: Color(0xFFD97706), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Row(
                          children: [
                            Text(
                              'RECOMMENDED NEXT',
                              style: TextStyle(
                                color: Color(0xFFD97706),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                            SizedBox(width: 6),
                            Text(
                              '· ~2 min',
                              style: TextStyle(
                                color: Color(0xFFB45309),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Cut it in Half',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Build your conciseness with short, focused answers.',
                          style: TextStyle(
                            color: Color(0xFF92400E),
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      state.selectActivity('cut_it_in_half');
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ActivityDetailScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.royalBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'Start',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, size: 14),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // SESSIONS Header with active period indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'SESSIONS',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.royalBlue.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.royalBlue.withValues(alpha: 0.2),
                          width: 1.0,
                        ),
                      ),
                      child: Text(
                        filterLabel,
                        style: const TextStyle(
                          color: AppColors.royalBlue,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  '${filteredSessions.length} total',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (filteredSessions.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceBorder, width: 1.0),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.history_toggle_off_rounded,
                      size: 34,
                      color: AppColors.textMuted.withValues(alpha: 0.6),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No sessions in the last $filterLabel',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Complete a drill to see your progress here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...filteredSessions.take(10).map((session) {
                final score = session.feedback.overallScore;
                final minutes = (session.durationSeconds / 60).ceil().clamp(1, 99);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildRecentSessionCard(
                    scoreFraction: '$score/5',
                    scoreFractionValue: score / 5,
                    ringColor: score >= 4
                        ? const Color(0xFF10B981)
                        : const Color(0xFF6366F1),
                    title: session.activityName,
                    dateDuration:
                        '${_formatSessionDay(session.timestamp)} · 🕒 $minutes min',
                    scoreBadge: score.toStringAsFixed(1),
                    onTap: () {
                      state.selectActivity(session.activitySlug);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ActivityDetailScreen()),
                      );
                    },
                  ),
                );
              }),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  /// Calculates dynamic pillar statistics based on the active filtered sessions
  (String, bool, String?, bool?, List<double>) _periodPillarStat(
    List<PracticeSessionRecord> filtered,
    AppStateProvider state,
    String key,
  ) {
    if (filtered.isNotEmpty) {
      final scores = filtered.map((s) {
        switch (key) {
          case 'executive_presence':
            return s.feedback.pillars.executiveScore.toDouble();
          case 'clarity':
            return s.feedback.pillars.clarityScore.toDouble();
          case 'engagement':
            return s.feedback.pillars.engagementScore.toDouble();
          case 'impact':
          default:
            return s.feedback.pillars.impactScore.toDouble();
        }
      }).toList();
      final avg = scores.reduce((a, b) => a + b) / scores.length;
      final points = scores.length >= 3
          ? scores.reversed.take(6).toList()
          : [avg - 0.2, avg - 0.1, avg];
      return (
        avg.toStringAsFixed(1),
        false,
        '${scores.length} ${scores.length == 1 ? 'drill' : 'drills'}',
        true,
        points,
      );
    }
    // Fall back to general server or baseline pillar stats
    return _pillarAverage(state, key);
  }

  /// score text, locked, delta text, delta positive?, sparkline
  (String, bool, String?, bool?, List<double>) _pillarAverage(
    AppStateProvider state,
    String key,
  ) {
    final raw = state.pillarStats[key];
    if (raw is! Map) {
      return ('--', true, null, null, const [2.0, 2.0, 2.0]);
    }
    final map = Map<String, dynamic>.from(raw);
    final average = map['average'];
    final samples = (map['samples'] as num?)?.round() ?? 0;
    final locked = map['status'] == 'need_more' || average == null || samples < 3;
    if (locked) {
      return ('--', true, null, null, const [2.0, 2.0, 2.0]);
    }
    final value = (average as num).toDouble();
    return (
      value.toStringAsFixed(1),
      false,
      '$samples samples',
      true,
      [value - 0.3, value - 0.2, value - 0.1, value],
    );
  }

  void _showScoreExplainer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: const [
                  Icon(Icons.insights_rounded, color: AppColors.royalBlue, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'How Scores Work',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Hakkiri evaluates your speaking across a 1.0 to 5.0 scale using 4 foundational communication pillars:',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              _buildScorePrincipleRow(
                icon: Icons.mic_rounded,
                color: const Color(0xFF3B82F6),
                title: 'Fluency & Presence',
                desc: 'Steadier pace, optimal power pauses, and fewer filler words (crutches).',
              ),
              const SizedBox(height: 10),
              _buildScorePrincipleRow(
                icon: Icons.visibility_rounded,
                color: const Color(0xFF10B981),
                title: 'Clarity',
                desc: 'High intelligibility, logical structuring, and clear main takeaways.',
              ),
              const SizedBox(height: 10),
              _buildScorePrincipleRow(
                icon: Icons.auto_awesome_rounded,
                color: const Color(0xFFEF4444),
                title: 'Engagement & Tone',
                desc: 'Dynamic vocal energy, action verbs, and captivating delivery.',
              ),
              const SizedBox(height: 10),
              _buildScorePrincipleRow(
                icon: Icons.content_cut_rounded,
                color: const Color(0xFFF59E0B),
                title: 'Conciseness (Impact)',
                desc: 'High information density — get straight to the point without rambling.',
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.royalBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Got it', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScorePrincipleRow({
    required IconData icon,
    required Color color,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(9),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11.5,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatSessionDay(DateTime stamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(stamp.year, stamp.month, stamp.day);
    if (day == today) {
      return 'Today, ${stamp.hour.toString().padLeft(2, '0')}:${stamp.minute.toString().padLeft(2, '0')}';
    }
    return '${stamp.day} ${_month(stamp.month)} ${stamp.year}';
  }

  String _month(int month) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return names[(month - 1).clamp(0, 11)];
  }

  Widget _buildFilterPill(int index, String label) {
    final isSelected = _selectedFilter == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.royalBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.royalBlue.withValues(alpha: 0.28),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSkillCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String scoreText,
    required String? deltaText,
    required bool? isDeltaPositive,
    required String description,
    required List<double> sparklinePoints,
    required Color sparklineColor,
    required bool isLocked,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              if (isLocked) ...[
                const Icon(Icons.lock_outline_rounded, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 4),
              ],
              Text(
                scoreText,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (deltaText != null) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    deltaText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDeltaPositive == true
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          CustomSparkline(
            values: sparklinePoints,
            color: sparklineColor,
            strokeWidth: 2,
            height: 16,
            isDotted: isLocked,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSessionCard({
    required String scoreFraction,
    required double scoreFractionValue,
    required Color ringColor,
    required String title,
    required String dateDuration,
    required String scoreBadge,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceBorder, width: 1.0),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      value: scoreFractionValue,
                      strokeWidth: 3,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation<Color>(ringColor),
                    ),
                  ),
                  Text(
                    scoreFraction,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateDuration,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Text(
                  scoreBadge,
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
