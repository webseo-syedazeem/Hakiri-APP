import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state_provider.dart';
import 'activity_detail_screen.dart';
import 'home_screen.dart';

/// Screen matching doc_img_2.png (10-minute plan: "One more to lock it in")
/// and doc_img_3.png (15-minute plan: "Ready for a bigger stretch?")
class TargetedRetryScreen extends StatelessWidget {
  final bool is15MinutePlan;

  const TargetedRetryScreen({
    super.key,
    this.is15MinutePlan = false,
  });

  /// Feedback clears the stack before this screen — never bare [Navigator.pop]
  /// or the user lands on a black empty navigator.
  void _goBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final weakest = state.getWeakestExerciseToday();
    final slug = weakest['slug'] as String? ?? 'cut_it_in_half';
    final name = weakest['name'] as String? ?? 'Cut It in Half';
    final weakestArea = weakest['weakestArea'] as String? ?? 'Conciseness';
    final score = (weakest['score'] as num?)?.toDouble() ?? 3.1;
    final feedback = weakest['feedback'] as String? ??
        'Your answers were clear, but you took too long to land the point.';

    final stretchSlug = weakest['stretchSlug'] as String? ?? 'debate_me';
    final stretchName = weakest['stretchName'] as String? ?? 'Debate Me';
    final stretchArea = weakest['stretchArea'] as String? ?? 'Response to pushback';
    final stretchFeedback = weakest['stretchFeedback'] as String? ??
        'You held your position well, but your rebuttal could be sharper under pressure.';

    final planMinutes = is15MinutePlan ? 15 : 10;

    return PopScope(
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goBack(context);
      },
      child: Scaffold(
      backgroundColor: const Color(0xFFFBFBF9),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(
                        Icons.chevron_left_rounded,
                        color: Color(0xFF0F172A),
                        size: 32,
                      ),
                      onPressed: () => _goBack(context),
                      splashRadius: 24,
                    ),
                  ),
                  Text(
                    '$planMinutes-minute plan',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subhead: YOU'VE COMPLETED 3 ACTIVITIES
                    const Text(
                      "YOU'VE COMPLETED 3 ACTIVITIES.",
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Heading
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.8,
                          height: 1.15,
                        ),
                        children: is15MinutePlan
                            ? const [
                                TextSpan(
                                  text: 'Ready for a\n',
                                  style: TextStyle(color: Color(0xFF0F172A)),
                                ),
                                TextSpan(
                                  text: 'bigger stretch?',
                                  style: TextStyle(color: Color(0xFF2563EB)),
                                ),
                              ]
                            : const [
                                TextSpan(
                                  text: 'One more\n',
                                  style: TextStyle(color: Color(0xFF0F172A)),
                                ),
                                TextSpan(
                                  text: 'to lock it in.',
                                  style: TextStyle(color: Color(0xFF2563EB)),
                                ),
                              ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Subtitle
                    Text(
                      is15MinutePlan
                          ? 'Hakkiri has spotted your weaker area and recommends a targeted retry or a tougher challenge next.'
                          : 'Hakkiri has spotted your weakest area and recommends a targeted retry.',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Card 1: TARGETED RETRY CARD
                    _buildTargetedRetryCard(
                      slug: slug,
                      name: name,
                      weakestArea: weakestArea,
                      score: score,
                      feedback: feedback,
                      is15Min: is15MinutePlan,
                    ),

                    // Card 2: If 15-minute plan, show LEVEL UP CHALLENGE
                    if (is15MinutePlan) ...[
                      const SizedBox(height: 16),
                      _buildTougherChallengeCard(
                        slug: stretchSlug,
                        name: stretchName,
                        weakestArea: stretchArea,
                        feedback: stretchFeedback,
                      ),
                      const SizedBox(height: 16),
                      _buildThisRoundIncludesCard(),
                    ],

                    const SizedBox(height: 16),

                    // Two pills row: "3 activities done" + "Feedback after every exercise"
                    if (!is15MinutePlan)
                      Row(
                        children: [
                          Expanded(
                            child: _buildSmallPill(
                              icon: Icons.check_circle_rounded,
                              iconColor: const Color(0xFF2563EB),
                              label: '3 activities done',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildSmallPill(
                              icon: Icons.bar_chart_rounded,
                              iconColor: const Color(0xFF2563EB),
                              label: 'Feedback after every exercise',
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 14),

                    // Lightbulb Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F7FF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFDBEAFE), width: 1.0),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: Color(0xFFDBEAFE),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.lightbulb_outline_rounded,
                              color: Color(0xFF2563EB),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              is15MinutePlan
                                  ? 'Choose a retry to reinforce a weaker skill, or take a tougher round to stretch yourself.'
                                  : 'You\'ll get a fresh round of feedback after this retry.',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1E293B),
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Bottom Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 18),
              child: is15MinutePlan
                  ? Row(
                      children: [
                        // Left: Targeted retry outline button
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _launchExercise(
                              context,
                              state,
                              slug,
                              planExtra: 'targeted_retry',
                            ),
                            child: Container(
                              height: 54,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(27),
                                border: Border.all(
                                  color: const Color(0xFF2563EB),
                                  width: 1.5,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'Targeted retry',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Right: Tougher challenge button
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _launchExercise(
                              context,
                              state,
                              stretchSlug,
                              planExtra: 'tougher_challenge',
                            ),
                            child: Container(
                              height: 54,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(27),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.12),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'Tougher challenge',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : GestureDetector(
                      onTap: () => _launchExercise(
                        context,
                        state,
                        slug,
                        planExtra: 'targeted_retry',
                      ),
                      child: Container(
                        height: 56,
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Spacer(),
                            Text(
                              'Retry $name',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.1,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              width: 38,
                              height: 38,
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
                    ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildTargetedRetryCard({
    required String slug,
    required String name,
    required String weakestArea,
    required double score,
    required String feedback,
    required bool is15Min,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDBEAFE), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subheader row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TARGETED RETRY',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: Color(0xFF2563EB),
                ),
              ),
              if (is15Min)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.track_changes_rounded, size: 13, color: Color(0xFF2563EB)),
                      SizedBox(width: 4),
                      Text(
                        'Targeted retry',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          // Design: 8px below label, then 18px before feedback body.
          const SizedBox(height: 8),

          // Exercise row
          Row(
            children: [
              Builder(
                builder: (_) {
                  final visual = _activityVisual(slug);
                  return Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: visual.$3,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      visual.$1,
                      color: visual.$2,
                      size: 24,
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.radio_button_checked_rounded,
                          size: 13,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: RichText(
                            overflow: TextOverflow.ellipsis,
                            text: TextSpan(
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                              children: [
                                const TextSpan(text: 'Weakest area: '),
                                TextSpan(
                                  text: weakestArea,
                                  style: const TextStyle(
                                    color: Color(0xFF2563EB),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!is15Min)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBFDBFE), width: 1.0),
                  ),
                  child: Text(
                    '${score.toStringAsFixed(1)} / 5',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 18),

          Text(
            feedback,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Color(0xFF475569),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  /// Icon + colors for an activity slug (scissors only for Cut It in Half).
  static (IconData, Color, Color) _activityVisual(String slug) {
    switch (slug) {
      case 'cut_it_in_half':
        return (
          Icons.content_cut_rounded,
          const Color(0xFFF95B3D),
          const Color(0xFFFFEDE8),
        );
      case 'debate_me':
      case 'debate':
        return (
          Icons.chat_bubble_outline_rounded,
          const Color(0xFFF59E0B),
          const Color(0xFFFFFBEB),
        );
      case 'storytelling_gym':
        return (
          Icons.auto_stories_outlined,
          const Color(0xFF8B5CF6),
          const Color(0xFFF5F3FF),
        );
      case 'explain_it_simply':
        return (
          Icons.lightbulb_outline_rounded,
          const Color(0xFF10B981),
          const Color(0xFFECFDF5),
        );
      case 'connect_the_dots':
        return (
          Icons.hub_rounded,
          const Color(0xFF6366F1),
          const Color(0xFFEEF2FF),
        );
      case 'think_fast':
      default:
        return (
          Icons.bolt_rounded,
          const Color(0xFF2563EB),
          const Color(0xFFEFF6FF),
        );
    }
  }

  Widget _buildTougherChallengeCard({
    required String slug,
    required String name,
    required String weakestArea,
    required String feedback,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDBEAFE), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'LEVEL UP CHALLENGE',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: Color(0xFF2563EB),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEDE8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bar_chart_rounded, size: 13, color: Color(0xFFF95B3D)),
                    SizedBox(width: 4),
                    Text(
                      'Tougher round',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFF95B3D),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Builder(
                builder: (_) {
                  final visual = _activityVisual(slug);
                  return Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: visual.$3,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      visual.$1,
                      color: visual.$2,
                      size: 24,
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.radio_button_checked_rounded,
                          size: 13,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Weakest area: $weakestArea',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Text(
            feedback,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Color(0xFF475569),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThisRoundIncludesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This round includes',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildFeatureItem(Icons.refresh_rounded, 'Focused retry'),
              ),
              Expanded(
                child: _buildFeatureItem(Icons.bolt_rounded, 'Tougher prompt'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildFeatureItem(Icons.groups_rounded, '1 extra pushback'),
              ),
              Expanded(
                child: _buildFeatureItem(Icons.bar_chart_rounded, 'Feedback at end'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSmallPill(
                  icon: Icons.emoji_events_outlined,
                  iconColor: const Color(0xFF2563EB),
                  label: '3 activities done',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSmallPill(
                  icon: Icons.insights_rounded,
                  iconColor: const Color(0xFF2563EB),
                  label: 'Built from your results',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String label) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: Color(0xFFEFF6FF),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 16, color: const Color(0xFF2563EB)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSmallPill({
    required IconData icon,
    required Color iconColor,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _launchExercise(
    BuildContext context,
    AppStateProvider state,
    String slug, {
    required String planExtra,
  }) {
    state.selectActivity(slug);
    state.setPendingPlanExtra(planExtra);
    // All drills go through activity detail; Debate Me Begin opens guided flow.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActivityDetailScreen(activitySlug: slug),
      ),
    );
  }
}
