import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/services/analytics_service.dart';
import '../models/session_model.dart';
import '../providers/app_state_provider.dart';
import '../widgets/coach_play_button.dart';
import '../widgets/hakkiri_loading_overlay.dart';
import 'conversation_chat_screen.dart';
import 'debate_me_screen.dart';
import 'home_screen.dart';
import 'live_conversation_screen.dart';
import 'paywall_screen.dart';
import 'recording_screen.dart';
import 'targeted_retry_screen.dart';

/// Comprehensive, high-fidelity Activity Feedback Screen
/// Exactly matching client design specification (doc_images/img_4.png).
class FeedbackScreen extends StatelessWidget {
  /// When set (e.g. from Progress), show that session instead of latest.
  final PracticeSessionRecord? session;
  final bool fromHistory;

  /// Guest Think Fast free try — after feedback, back/next go to IAP.
  final bool isGuestTrial;

  const FeedbackScreen({
    super.key,
    this.session,
    this.fromHistory = false,
    this.isGuestTrial = false,
  });

  Future<void> _exitGuestTrialToPaywall(BuildContext context) async {
    final state = Provider.of<AppStateProvider>(context, listen: false);
    await state.markGuestReachedPaywall();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const PaywallScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService.instance.logScreenView(screenName: 'FeedbackScreen');
    });

    final state = Provider.of<AppStateProvider>(context);
    final activeSession = session ?? state.latestSession;
    final feedback = activeSession?.feedback ?? state.latestFeedback;
    final overallValue = (feedback?.overallScore ?? 0).toDouble();
    final overallScore = feedback != null
        ? overallValue.toStringAsFixed(1)
        : '0.0';
    final activityTitle = (activeSession?.activityName ??
            state.selectedActivity?.name ??
            'SESSION')
        .toUpperCase();

    return PopScope(
      canPop: !isGuestTrial,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && isGuestTrial) {
          unawaited(_exitGuestTrialToPaywall(context));
        }
      },
      child: Scaffold(
      backgroundColor: const Color(0xFFFBFBF9),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar (< back, centered THINK FIRST)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (isGuestTrial) {
                        unawaited(_exitGuestTrialToPaywall(context));
                        return;
                      }
                      Navigator.pop(context);
                    },
                    child: const Icon(
                      Icons.chevron_left_rounded,
                      color: Color(0xFF0F172A),
                      size: 28,
                    ),
                  ),
                  Text(
                    activityTitle,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: Color(0xFF0F172A),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.6,
                    ),
                  ),
                  if (activeSession != null && !isGuestTrial)
                    GestureDetector(
                      onTap: () => _confirmDeleteSession(context, state, activeSession),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFFCA5A5).withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          color: Color(0xFFEF4444),
                          size: 18,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 32), // balance chevron
                ],
              ),
            ),

            // Horizontal Progress Bar
            Container(
              height: 3,
              width: double.infinity,
              color: const Color(0xFF2563EB),
            ),

            // Scrollable Feedback Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (feedback == null)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 20),
                        child: Text(
                          'No scored session yet. Finish a drill to see real feedback here.',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    // Overall Score Header
                    _buildOverallScoreSection(
                      overallScore: overallScore,
                      overallValue: overallValue,
                      feedback: feedback,
                    ),
                    const SizedBox(height: 20),

                    // Activity measures (spreadsheet weights) or pillar fallback
                    if (feedback != null &&
                        feedback.activityMeasures.isNotEmpty)
                      _buildActivityMeasuresRow(feedback)
                    else
                      _buildMetricsRow(feedback),
                    const SizedBox(height: 16),

                    // WHAT WORKED WELL Card (Green)
                    _buildWhatWorkedWellCard(feedback),
                    const SizedBox(height: 16),

                    // Live coach only — hide on Debate Me (guided opening/rebuttal).
                    if (activeSession != null &&
                        activeSession.activitySlug != 'debate_me' &&
                        activeSession.activitySlug != 'debate') ...[
                      Builder(
                        builder: (_) {
                          final turns = _conversationTurnsForDisplay(
                            activeSession,
                          );
                          if (turns.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Column(
                            children: [
                              _buildShowConversationButton(context, turns),
                              const SizedBox(height: 16),
                            ],
                          );
                        },
                      ),
                    ],

                    // SUGGESTED ANSWER Card (Dark Card with Audio Preview)
                    _buildSuggestedAnswerCard(
                      feedback,
                      session: activeSession,
                    ),
                    const SizedBox(height: 16),

                    // KEY POINTS TO IMPROVE Card
                    _buildKeyPointsToImproveCard(feedback),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Bottom Buttons — same after new recording and from Progress history.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: const Color(0xFFCBD5E1),
                          width: 1.2,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(28),
                          onTap: () {
                            if (isGuestTrial) {
                              unawaited(_exitGuestTrialToPaywall(context));
                              return;
                            }
                            final slug = activeSession?.activitySlug ?? '';
                            if (slug.isNotEmpty) {
                              state.selectActivity(slug);
                            }
                            final isDebate =
                                slug == 'debate_me' || slug == 'debate';
                            final liveAgain =
                                !isDebate &&
                                activeSession?.isBackAndForth == true;
                            final topic =
                                state.selectedPrompt?.promptText.trim();
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) {
                                  if (isDebate) {
                                    return DebateMeScreen(
                                      topic: (topic != null &&
                                              topic.isNotEmpty)
                                          ? topic
                                          : null,
                                      startAtPrompt: true,
                                    );
                                  }
                                  if (liveAgain) {
                                    return const LiveConversationScreen();
                                  }
                                  return RecordingScreen(
                                    promptAlreadyLoaded: !fromHistory,
                                  );
                                },
                              ),
                            );
                          },
                          child: const Center(
                            child: Text(
                              'Try again',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                color: Color(0xFF0F172A),
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(28),
                          onTap: () {
                            if (isGuestTrial) {
                              unawaited(_exitGuestTrialToPaywall(context));
                              return;
                            }
                            if (fromHistory) {
                              Navigator.pop(context);
                              return;
                            }
                            // 10/15 min: after 3 core drills, offer retry / stretch.
                            if (state.shouldOfferPlanExtras) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TargetedRetryScreen(
                                    is15MinutePlan:
                                        state.dailyAnchorMinutes >= 15,
                                  ),
                                ),
                                (route) => false,
                              );
                              return;
                            }
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const HomeScreen(),
                              ),
                              (route) => false,
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(width: 32),
                                Text(
                                  'Next',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: Color(0xFF2563EB),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Colors.white,
                                      size: 17,
                                    ),
                                  ),
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
            ),
          ],
        ),
      ),
    ),
    );
  }

  Future<void> _confirmDeleteSession(
    BuildContext context,
    AppStateProvider state,
    PracticeSessionRecord session,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Session?',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: Color(0xFF0F172A),
          ),
        ),
        content: const Text(
          'Are you sure you want to delete this session? This action cannot be undone.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: Color(0xFF64748B),
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await HakkiriLoadingOverlay.run(
        context,
        message: 'Deleting session…',
        detail: 'Please wait a moment.',
        action: () => state.deleteSession(session.id),
      );
      if (context.mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  String _effortLabel(int score) {
    if (score >= 5) return 'EXCELLENT';
    if (score >= 4) return 'STRONG';
    if (score >= 3) return 'GOOD EFFORT';
    if (score >= 2) return 'WEAK';
    if (score >= 1) return 'RETRY';
    return 'NO SCORE YET';
  }

  String _headlineFor(EvaluationFeedback? feedback) {
    if (feedback == null) {
      return 'Finish a drill\nto unlock scoring.';
    }
    if (feedback.withholdJudgement) {
      return 'Not enough signal.\nRetry for a score.';
    }
    if (feedback.overallScore <= 2) {
      return 'Not enough answer.\nTry the question again.';
    }
    if (feedback.pillars.crutchCount > 0) {
      return 'Clear answer.\nTidy up the fillers.';
    }
    if (feedback.overallScore >= 4) {
      return 'Solid delivery.\nKeep the momentum.';
    }
    return 'Decent baseline.\nTighten the close.';
  }

  /// Per-activity measures from weighted scoring engine.
  Widget _buildActivityMeasuresRow(EvaluationFeedback feedback) {
    final measures = feedback.activityMeasures;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (feedback.capped && (feedback.scoringReason?.isNotEmpty ?? false))
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              feedback.scoringReason!,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        Builder(
          builder: (context) {
            final perRow = measures.length <= 3 ? measures.length : 2;
            final rows = <Widget>[];
            for (var start = 0; start < measures.length; start += perRow) {
              final slice = measures.sublist(
                start,
                (start + perRow).clamp(0, measures.length),
              );
              rows.add(
                Row(
                  children: [
                    for (var i = 0; i < slice.length; i++) ...[
                      if (i > 0) const SizedBox(width: 10),
                      Builder(
                        builder: (_) {
                          final globalIdx = start + i;
                          final measure = slice[i];
                          final cardIcon = _iconForMeasure(
                            measure.key,
                            measure.label,
                            isHeaviest: measure.isHeaviest,
                            index: globalIdx,
                          );
                          final cardColor = _colorForMeasure(
                            measure.key,
                            measure.label,
                            isHeaviest: measure.isHeaviest,
                            index: globalIdx,
                          );

                          return Expanded(
                            child: _buildMetricCard(
                              icon: cardIcon,
                              iconColor: cardColor,
                              ringColor: cardColor,
                              scoreFraction: (measure.score ?? 0) / 5.0,
                              title: measure.label,
                              score: measure.score == null
                                  ? '0/5'
                                  : '${measure.score}/5',
                              desc: measure.isHeaviest
                                  ? 'Heaviest weight'
                                  : '${(measure.weight * 100).round()}% weight',
                            ),
                          );
                        },
                      ),
                    ],
                    for (var i = slice.length; i < perRow; i++) ...[
                      const SizedBox(width: 10),
                      const Expanded(child: SizedBox()),
                    ],
                  ],
                ),
              );
              if (start + perRow < measures.length) {
                rows.add(const SizedBox(height: 10));
              }
            }
            return Column(children: rows);
          },
        ),
      ],
    );
  }

  IconData _iconForMeasure(
    String key,
    String label, {
    bool isHeaviest = false,
    int index = 0,
  }) {
    final k = key.toLowerCase().trim();
    final l = label.toLowerCase().trim();

    if (k.contains('tension') || l.contains('tension')) {
      return Icons.bolt_rounded;
    }
    if (k.contains('significance') || l.contains('significance')) {
      return Icons.lightbulb_rounded;
    }
    if (k.contains('delivery') || l.contains('delivery') || k.contains('speech')) {
      return Icons.record_voice_over_rounded;
    }
    if (k.contains('structure') || l.contains('structure')) {
      return isHeaviest ? Icons.star_rounded : Icons.account_tree_rounded;
    }
    if (k.contains('latency') || l.contains('latency') || k.contains('speed')) {
      return Icons.speed_rounded;
    }
    if (k.contains('filler') || l.contains('filler')) {
      return Icons.cleaning_services_rounded;
    }
    if (k.contains('compress') || l.contains('compress')) {
      return Icons.compress_rounded;
    }
    if (k.contains('time_to_value') || l.contains('time to value')) {
      return Icons.hourglass_bottom_rounded;
    }
    if (k.contains('paraphras') || l.contains('paraphras')) {
      return Icons.sync_alt_rounded;
    }
    if (k.contains('depth') || l.contains('depth')) {
      return Icons.layers_rounded;
    }
    if (k.contains('hook') || l.contains('hook')) {
      return Icons.anchor_rounded;
    }
    if (k.contains('time_management') || l.contains('time management')) {
      return Icons.schedule_rounded;
    }
    if (k.contains('audience') || l.contains('audience')) {
      return Icons.people_alt_rounded;
    }
    if (k.contains('linguistic') || l.contains('linguistic')) {
      return Icons.translate_rounded;
    }
    if (k.contains('bridge') || l.contains('bridge')) {
      return Icons.alt_route_rounded;
    }
    if (k.contains('integration') || l.contains('integration')) {
      return Icons.hub_rounded;
    }
    if (k.contains('pivot') || l.contains('pivot')) {
      return Icons.turn_right_rounded;
    }
    if (k.contains('objection') || l.contains('objection')) {
      return Icons.shield_rounded;
    }
    if (k.contains('reason') || l.contains('reason')) {
      return Icons.psychology_rounded;
    }
    if (isHeaviest) {
      return Icons.star_rounded;
    }

    const fallbacks = [
      Icons.insights_rounded,
      Icons.trending_up_rounded,
      Icons.auto_awesome_rounded,
      Icons.bar_chart_rounded,
      Icons.track_changes_rounded,
    ];
    return fallbacks[index % fallbacks.length];
  }

  Color _colorForMeasure(
    String key,
    String label, {
    bool isHeaviest = false,
    int index = 0,
  }) {
    if (isHeaviest) return const Color(0xFF2563EB);
    final k = key.toLowerCase().trim();
    final l = label.toLowerCase().trim();

    if (k.contains('tension') || l.contains('tension')) {
      return const Color(0xFFE11D48); // Rose / dramatic tension
    }
    if (k.contains('significance') || l.contains('significance')) {
      return const Color(0xFF7C3AED); // Violet / significance & meaning
    }
    if (k.contains('delivery') || l.contains('delivery') || k.contains('speech')) {
      return const Color(0xFF059669); // Emerald / voice delivery
    }
    if (k.contains('latency') || l.contains('latency')) {
      return const Color(0xFF0284C7); // Sky blue / speed
    }
    if (k.contains('filler') || l.contains('filler')) {
      return const Color(0xFFD97706); // Amber / purity
    }

    const palette = [
      Color(0xFF2563EB),
      Color(0xFF7C3AED),
      Color(0xFF059669),
      Color(0xFFE11D48),
      Color(0xFF0284C7),
    ];
    return palette[index % palette.length];
  }

  /// Overall Score Row (Circle Score Ring + Headline)
  Widget _buildOverallScoreSection({
    required String overallScore,
    required double overallValue,
    required EvaluationFeedback? feedback,
  }) {
    final score = feedback?.overallScore ?? 0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Circular Score Ring
        SizedBox(
          width: 96,
          height: 96,
          child: CustomPaint(
            painter: _ScoreRingPainter(
              scoreFraction: (overallValue <= 0 ? 0 : overallValue) / 5.0,
              trackColor: const Color(0xFFDBEAFE),
              activeColor: const Color(0xFF2563EB),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    overallScore,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      letterSpacing: -1.0,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'OUT OF 5',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 18),

        // Copy Column
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _effortLabel(score),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF4F46E5),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _headlineFor(feedback),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.6,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                feedback == null
                    ? 'Scores appear after you complete a practice session.'
                    : 'Here\'s how you did and how to improve.',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 3 Metrics Row mapped from the 4-pillar evaluation.
  Widget _buildMetricsRow(EvaluationFeedback? feedback) {
    final impact = feedback?.pillars.impactScore ?? 0;
    final clarity = feedback?.pillars.clarityScore ?? 0;
    final fluency = feedback?.pillars.executiveScore ?? 0;
    final crutches = feedback?.pillars.crutchCount ?? 0;
    final wpm = feedback?.pillars.pacingWpm ?? 0;

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            icon: Icons.bolt_rounded,
            iconColor: const Color(0xFF2563EB),
            ringColor: const Color(0xFF2563EB),
            scoreFraction: impact / 5.0,
            title: 'Content',
            score: feedback == null ? '0/5' : '$impact/5',
            desc: feedback == null
                ? 'Waiting for your first scored answer.'
                : impact <= 1
                    ? 'No real answer to the prompt.'
                    : impact >= 4
                        ? 'Point landed with useful detail.'
                        : 'Lead with the decision sooner.',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.assignment_outlined,
            iconColor: const Color(0xFF059669),
            ringColor: const Color(0xFF059669),
            scoreFraction: clarity / 5.0,
            title: 'Structure',
            score: feedback == null ? '0/5' : '$clarity/5',
            desc: feedback == null
                ? 'Waiting for your first scored answer.'
                : clarity <= 1
                    ? 'Need a fuller spoken answer.'
                    : wpm > 0
                        ? 'Pace around $wpm wpm.'
                        : 'Keep ideas organised and easy to follow.',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.pause_circle_outline_rounded,
            iconColor: const Color(0xFFDC2626),
            ringColor: const Color(0xFFDC2626),
            scoreFraction: fluency / 5.0,
            title: 'Fluency',
            score: feedback == null ? '0/5' : '$fluency/5',
            desc: feedback == null
                ? 'Waiting for your first scored answer.'
                : fluency <= 1
                    ? 'Filler / noise only — retry.'
                    : crutches > 0
                        ? '$crutches filler habits spotted.'
                        : 'Steady delivery with fewer crutches.',
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required Color ringColor,
    required double scoreFraction,
    required String title,
    required String score,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
      ),
      child: Column(
        children: [
          // Circular Mini Ring with Icon inside
          SizedBox(
            width: 44,
            height: 44,
            child: CustomPaint(
              painter: _ScoreRingPainter(
                scoreFraction: scoreFraction,
                trackColor: ringColor.withValues(alpha: 0.2),
                activeColor: ringColor,
                strokeWidth: 4.5,
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Title
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),

          // Score
          Text(
            score,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),

          // Description
          Text(
            desc,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  /// Prefer saved turns; for Debate Me, rebuild from scored transcript if needed.
  List<ConversationTurn> _conversationTurnsForDisplay(
    PracticeSessionRecord session,
  ) {
    if (session.isDebateMe) {
      final rebuilt = PracticeSessionRecord.debateTurnsFrom(
        transcript: session.transcript,
        fallback: session.conversationTurns,
      );
      if (rebuilt.isNotEmpty) return rebuilt;
    }
    if (session.conversationTurns.isNotEmpty) {
      return session.conversationTurns
          .where((t) => !PracticeSessionRecord.isPlaceholderSpeech(t.text))
          .toList();
    }
    return const [];
  }

  Widget _buildShowConversationButton(
    BuildContext context,
    List<ConversationTurn> turns,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ConversationChatScreen(turns: turns),
            ),
          );
        },
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFBFDBFE), width: 1.2),
          ),
          child: const Row(
            children: [
              Icon(Icons.forum_rounded, color: Color(0xFF2563EB), size: 22),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Show your conversation',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Open the full coach ↔ you chat',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }

  /// Strength / coaching note card
  Widget _buildWhatWorkedWellCard(EvaluationFeedback? feedback) {
    final score = feedback?.overallScore ?? 0;
    final isWeak = score > 0 && score <= 2;
    // Weak takes: show the fix. Strong takes: show what worked.
    final body = isWeak
        ? (feedback?.oneSpecificImprovement.trim().isNotEmpty == true
            ? feedback!.oneSpecificImprovement
            : 'Answer the prompt out loud with a clear point, then one reason.')
        : (feedback?.oneStrength.trim().isNotEmpty == true
            ? feedback!.oneStrength
            : 'Complete a drill to unlock a personalised strength note.');
    final label = isWeak ? 'WHAT TO FIX' : 'WHAT WORKED WELL';
    final bg = isWeak ? const Color(0xFFFFF7ED) : const Color(0xFFECFDF5);
    final border = isWeak ? const Color(0xFFFED7AA) : const Color(0xFFA7F3D0);
    final iconBg = isWeak ? const Color(0xFFFFEDD5) : const Color(0xFFD1FAE5);
    final iconColor = isWeak ? const Color(0xFFC2410C) : const Color(0xFF059669);
    final labelColor = isWeak ? const Color(0xFFC2410C) : const Color(0xFF047857);
    final bodyColor = isWeak ? const Color(0xFF9A3412) : const Color(0xFF065F46);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border, width: 1.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isWeak ? Icons.priority_high_rounded : Icons.check_rounded,
              color: iconColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: labelColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: bodyColor,
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

  static bool _isEmptySpeechPlaceholder(String raw) {
    final t = raw.trim().toLowerCase();
    if (t.isEmpty) return true;
    return (t.contains('empty') && t.contains('usable speech')) ||
        t.contains('no clear speech') ||
        t == '(no speech)' ||
        t.startsWith('(empty');
  }

  /// SUGGESTED ANSWER — clean exemplar + separate "you said" highlight.
  Widget _buildSuggestedAnswerCard(
    EvaluationFeedback? feedback, {
    PracticeSessionRecord? session,
  }) {
    final exemplar = feedback?.exemplarResponse.trim().isNotEmpty == true
        ? feedback!.exemplarResponse
        : 'Your coached exemplar appears here after a scored session.';
    final phrase = feedback?.highlightedPhrase.phrase.trim() ?? '';
    final isDebate = session != null &&
        (session.activitySlug == 'debate_me' ||
            session.activitySlug == 'debate' ||
            session.isBackAndForth);
    final List<ConversationTurn> debateTurns = session != null
        ? _conversationTurnsForDisplay(session)
        : const <ConversationTurn>[];
    final transcript = session?.transcript.trim() ?? '';
    final rawYouSaid = (!isDebate && transcript.isNotEmpty)
        ? transcript
        : (phrase.isNotEmpty ? phrase : '');
    final noSpeech = _isEmptySpeechPlaceholder(rawYouSaid) ||
        (transcript.isEmpty && _isEmptySpeechPlaceholder(phrase));
    final youSaid = noSpeech
        ? 'No clear speech was captured this take.'
        : rawYouSaid;
    final critique = feedback?.highlightedPhrase.critique.trim() ?? '';
    final score = feedback?.overallScore ?? 0;
    final intro = feedback == null
        ? 'Finish a practice take to unlock a coached rewrite.'
        : noSpeech
            ? 'Speak a full answer next time. Meanwhile, here is a strong model answer:'
            : score <= 2
                ? 'Here is a strong model answer for this prompt:'
                : 'Here\'s a more refined version you can aim for:';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SUGGESTED ANSWER',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: Color(0xFF818CF8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            intro,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFFE2E8F0),
              height: 1.35,
            ),
          ),
          if (youSaid.isNotEmpty ||
              debateTurns.isNotEmpty ||
              session != null) ...[
            const SizedBox(height: 12),
            const Text(
              'YOU SAID',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 6),
            if (isDebate && debateTurns.isNotEmpty)
              _buildDebateYouSaidPill(debateTurns)
            else if (youSaid.isNotEmpty)
              _buildPeachHighlightPill(youSaid),
          ],
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CoachPlayButton(text: exemplar),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exemplar,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12.5,
                          color: Color(0xFFCBD5E1),
                          height: 1.4,
                        ),
                      ),
                      if (critique.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          critique,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11.5,
                            color: Color(0xFF94A3B8),
                            height: 1.35,
                          ),
                        ),
                      ],
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

  Widget _buildPeachHighlightPill(String text) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEDD5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: Color(0xFFC2410C),
          height: 1.35,
        ),
      ),
    );
  }

  /// Debate Me: label opening / pushback / rebuttal clearly in YOU SAID.
  Widget _buildDebateYouSaidPill(List<ConversationTurn> turns) {
    final labels = <String>['Opening argument', 'Hakkiri pushback', 'Rebuttal'];
    final children = <Widget>[];
    for (var i = 0; i < turns.length; i++) {
      final turn = turns[i];
      var text = turn.text.trim();
      if (text.isEmpty) continue;
      // Avoid "Rebuttal: Rebuttal: …" when body already starts with the label.
      final labelPrefix = RegExp(
        r'^(opening argument|rebuttal|hakkiri pushback|coach pushback)\s*:\s*',
        caseSensitive: false,
      );
      for (var n = 0; n < 3; n++) {
        final next = text.replaceFirst(labelPrefix, '').trim();
        if (next == text) break;
        text = next;
      }
      if (text.isEmpty) {
        text = turn.text.trim();
      }
      if (PracticeSessionRecord.isPlaceholderSpeech(text)) continue;
      final isCoach = turn.role == 'coach';
      final label = i < labels.length
          ? labels[i]
          : (isCoach ? 'Hakkiri' : 'You');
      if (children.isNotEmpty) children.add(const SizedBox(height: 10));
      children.add(
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '$label: ',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: isCoach
                      ? const Color(0xFFC2410C)
                      : const Color(0xFF9A3412),
                  height: 1.35,
                ),
              ),
              TextSpan(
                text: text,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: isCoach
                      ? const Color(0xFFEA580C)
                      : const Color(0xFFC2410C),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (children.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEDD5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  /// KEY POINTS TO IMPROVE Card
  Widget _buildKeyPointsToImproveCard(EvaluationFeedback? feedback) {
    final improvement = feedback?.oneSpecificImprovement.trim().isNotEmpty == true
        ? feedback!.oneSpecificImprovement
        : 'Complete a drill to unlock a specific coaching note.';
    final retry = feedback?.retryInstruction.trim().isNotEmpty == true
        ? feedback!.retryInstruction
        : 'Lead with the decision in the first 5 seconds.';
    final fluencyNote = feedback == null
        ? 'Scores unlock after your first practice take.'
        : feedback.pillars.crutchCount > 0
            ? 'Cut ${feedback.pillars.crutchCount} filler habit${feedback.pillars.crutchCount == 1 ? '' : 's'} next take.'
            : 'Keep a steady pace around ${feedback.pillars.pacingWpm} wpm.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'KEY POINTS TO IMPROVE',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 14),
          _buildImprovementRow(
            tag: 'FOCUS',
            tagBg: const Color(0xFFFFEDD5),
            tagTextColor: const Color(0xFFC2410C),
            text: improvement,
          ),
          const SizedBox(height: 12),
          _buildImprovementRow(
            tag: 'RETRY',
            tagBg: const Color(0xFFEDE9FE),
            tagTextColor: const Color(0xFF6D28D9),
            text: retry,
          ),
          const SizedBox(height: 12),
          _buildImprovementRow(
            tag: 'FLUENCY',
            tagBg: const Color(0xFFDCFCE7),
            tagTextColor: const Color(0xFF15803D),
            text: fluencyNote,
          ),
        ],
      ),
    );
  }

  Widget _buildImprovementRow({
    required String tag,
    required Color tagBg,
    required Color tagTextColor,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 72,
          padding: const EdgeInsets.symmetric(vertical: 3),
          decoration: BoxDecoration(
            color: tagBg,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            tag,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: tagTextColor,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF334155),
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

/// Circular Score Ring Painter
class _ScoreRingPainter extends CustomPainter {
  final double scoreFraction;
  final Color trackColor;
  final Color activeColor;
  final double strokeWidth;

  _ScoreRingPainter({
    required this.scoreFraction,
    required this.trackColor,
    required this.activeColor,
    this.strokeWidth = 8.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - (strokeWidth / 2);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * scoreFraction.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreRingPainter oldDelegate) =>
      oldDelegate.scoreFraction != scoreFraction ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.activeColor != activeColor ||
      oldDelegate.strokeWidth != strokeWidth;
}
