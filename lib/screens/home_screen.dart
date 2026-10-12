import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/app_state_provider.dart';
import '../widgets/hakkiri_logo.dart';
import 'activity_detail_screen.dart';
import 'live_conversation_screen.dart';
import 'main_tab_scaffold.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainTabScaffold(initialIndex: 0);
  }
}

class HomeScreenContent extends StatelessWidget {
  const HomeScreenContent({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final completedCount = state.completedTodayDrills();
    final bool hasStarted = completedCount > 0 || state.completedSessions > 0;
    final weekDays = state.practiceDaysThisWeek;
    final drills = state.todayDrillSlugs;
    final primarySlug = drills.isNotEmpty ? drills.first : 'think_fast';
    final primaryActivity = state.activities.firstWhere(
      (a) => a.slug == primarySlug,
      orElse: () => state.activities.first,
    );
    final nextSlug = drills.length > 1
        ? drills[completedCount.clamp(0, drills.length - 1)]
        : primarySlug;
    final nextActivity = state.activities.firstWhere(
      (a) => a.slug == nextSlug,
      orElse: () => primaryActivity,
    );
    final planTotal = drills.isEmpty ? 3 : drills.length;
    final planDone = completedCount.clamp(0, planTotal);
    final remaining = (planTotal - planDone).clamp(0, planTotal);
    final latest = state.sessionHistory.isNotEmpty ? state.sessionHistory.first : null;
    final progressTitle = hasStarted ? "THIS WEEK'S PROGRESS" : 'YOUR STARTING POINT';
    final String progressHeadline;
    final String progressSub;
    if (!hasStarted) {
      progressHeadline = "Complete today's exercises";
      progressSub = 'to start tracking your progress.';
    } else if (state.overallAverage != null) {
      progressHeadline =
          'Average ${state.overallAverage!.toStringAsFixed(1)}/5';
      progressSub = 'from ${state.overallSamples} scored sessions.';
    } else if (latest != null) {
      progressHeadline =
          'Last session ${latest.feedback.overallScore}/5';
      progressSub = latest.feedback.pillars.crutchCount > 0
          ? '${latest.feedback.pillars.crutchCount} filler habits flagged.'
          : 'Keep building your streak.';
    } else {
      progressHeadline = '${state.completedSessions} sessions logged';
      progressSub = 'View progress in Insights.';
    }

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top App Bar Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const HakkiriLogo(
                  variant: HakkiriLogoVariant.compactMark,
                  size: 22,
                ),
                // Streak Badge Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.surfaceBorder, width: 1.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '🔥',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${state.currentStreak}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Subtag
            const Text(
              'TODAY',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 6),

            // Dynamic Heading based on progress
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                  height: 1.15,
                ),
                children: [
                  TextSpan(
                    text: hasStarted
                        ? (remaining == 0 ? 'Nice work.\n' : 'Nice start.\n')
                        : 'Your plan is ready.\n',
                  ),
                  TextSpan(
                    text: hasStarted
                        ? (remaining == 0
                            ? 'Plan complete today.'
                            : remaining == 1
                                ? 'One to go today.'
                                : '$remaining to go today.')
                        : "Let's get started.",
                    style: const TextStyle(color: AppColors.royalBlue),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Weekly Streak Progress Card (from img_2.png)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
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
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: AppColors.textPrimary,
                            fontSize: 13,
                          ),
                          children: [
                            TextSpan(
                              text: '$weekDays of 7 days ',
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            const TextSpan(
                              text: 'this week',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.ac_unit_rounded, size: 14, color: AppColors.royalBlue),
                          const SizedBox(width: 4),
                          Text(
                            state.streakFreezeCount > 0
                                ? '${state.streakFreezeCount} freeze ready'
                                : 'No freeze left',
                            style: const TextStyle(
                              color: AppColors.royalBlue,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // 7 segmented rounded pill bars
                  Row(
                    children: List.generate(7, (idx) {
                      final isCompleted = idx < weekDays;
                      return Expanded(
                        child: Container(
                          height: 7,
                          margin: EdgeInsets.only(right: idx < 6 ? 6 : 0),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? const Color(0xFFF95B3D)
                                : const Color(0xFFE5E5EA),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Assessment Personalization Banner Card (from img_0.png)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.surfaceBorder, width: 1.0),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE9FE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0xFF6366F1),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Personalised from your assessment',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Focus: ${state.focusLine}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textMuted,
                    size: 22,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Hero Dark Card (Navy Gradient Card with Circular Progress and Play button)
            GestureDetector(
              onTap: () {
                state.selectActivity(nextActivity.slug);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ActivityDetailScreen()),
                );
              },
              child: Container(
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
                child: Row(
                  children: [
                    // Circular Progress 1/3
                    SizedBox(
                      width: 58,
                      height: 58,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: planTotal == 0 ? 0 : (planDone / planTotal).clamp(0.0, 1.0),
                            strokeWidth: 4,
                            backgroundColor: Colors.white.withValues(alpha: 0.15),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF10B981),
                            ),
                          ),
                          Text(
                            '$planDone/$planTotal',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Center Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hasStarted ? 'UP NEXT · ~2 MIN' : 'START HERE · ~2 MIN',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            nextActivity.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            nextActivity.tagline,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.65),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Large Blue Play Button with Concentric Rings
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.45),
                            blurRadius: 14,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Section Heading: TODAY'S PLAN
            Text(
              hasStarted
                  ? "TODAY'S PLAN · PERSONALISED FOR YOU"
                  : "TODAY'S PLAN · $planTotal EXERCISES",
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),

            ...drills.take(3).toList().asMap().entries.map((entry) {
              final index = entry.key;
              final slug = entry.value;
              final activity = state.activities.firstWhere(
                (a) => a.slug == slug,
                orElse: () => state.activities.first,
              );
              final doneToday = state.sessionHistory.any((s) {
                final now = DateTime.now();
                return s.activitySlug == slug &&
                    s.timestamp.year == now.year &&
                    s.timestamp.month == now.month &&
                    s.timestamp.day == now.day;
              });
              final visuals = _exerciseVisual(slug);
              return Padding(
                padding: EdgeInsets.only(bottom: index < drills.take(3).length - 1 ? 10 : 0),
                child: _buildExerciseCard(
                  context: context,
                  icon: visuals.$1,
                  iconColor: visuals.$2,
                  iconBgColor: visuals.$3,
                  title: activity.name,
                  subtitle: activity.tagline,
                  isCompleted: doneToday,
                  trailingText: doneToday ? null : '~2 min',
                  onTap: () {
                    state.selectActivity(slug);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ActivityDetailScreen()),
                    );
                  },
                ),
              );
            }),
            const SizedBox(height: 18),

            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LiveConversationScreen()),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFBFDBFE), width: 1.0),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Color(0xFFDBEAFE),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.graphic_eq_rounded,
                        color: Color(0xFF2563EB),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LIVE COACH',
                            style: TextStyle(
                              color: Color(0xFF2563EB),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Back-and-forth voice practice',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Native mic + Gemini live conversation',
                            style: TextStyle(
                              color: Color(0xFF1D4ED8),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF2563EB),
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Bottom Highlight Mint Green Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFC8E6C9), width: 1.0),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFC8E6C9),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      hasStarted ? Icons.track_changes_rounded : Icons.bar_chart_rounded,
                      color: const Color(0xFF2E7D32),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          progressTitle,
                          style: const TextStyle(
                            color: Color(0xFF2E7D32),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          progressHeadline,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          progressSub,
                          style: const TextStyle(
                            color: Color(0xFF2E7D32),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF2E7D32),
                    size: 22,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  static (IconData, Color, Color) _exerciseVisual(String slug) {
    switch (slug) {
      case 'cut_it_in_half':
        return (Icons.content_cut_rounded, const Color(0xFFEF4444), const Color(0xFFFEF2F2));
      case 'debate_me':
        return (Icons.chat_bubble_outline_rounded, const Color(0xFFF59E0B), const Color(0xFFFFFBEB));
      case 'storytelling_gym':
        return (Icons.auto_stories_outlined, const Color(0xFF8B5CF6), const Color(0xFFF5F3FF));
      case 'explain_it_simply':
        return (Icons.lightbulb_outline_rounded, const Color(0xFF10B981), const Color(0xFFECFDF5));
      default:
        return (Icons.bolt_rounded, const Color(0xFF3B82F6), const Color(0xFFEFF6FF));
    }
  }

  static Widget _buildExerciseCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required bool isCompleted,
    required String? trailingText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceBorder, width: 1.0),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: iconColor, size: 20),
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
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.radio_button_checked, size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          subtitle,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isCompleted)
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              )
            else if (trailingText != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    trailingText,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
                ],
              )
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFCBD5E1), width: 1.8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
