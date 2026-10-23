import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/services/hakkiri_api_service.dart';
import '../core/services/push_notification_service.dart';
import '../providers/app_state_provider.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/hakkiri_loading_overlay.dart';
import '../widgets/hakkiri_logo.dart';
import '../widgets/shimmer_loading.dart';
import 'activity_detail_screen.dart';
import 'main_tab_scaffold.dart';
import 'profile_section_screen.dart';
import 'targeted_retry_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainTabScaffold(initialIndex: 0);
  }
}

class HomeScreenContent extends StatelessWidget {
  const HomeScreenContent({super.key});

  Future<void> _onFreezeTap(BuildContext context) async {
    final state = context.read<AppStateProvider>();
    if (!state.isLoggedIn) {
      AppSnackBar.showInfo(context, 'Sign in to use a streak freeze.');
      return;
    }
    if (state.streakFreezeCount < 1) {
      AppSnackBar.showInfo(context, 'No streak freezes left.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Use streak freeze?'),
        content: Text(
          state.streakFreezeCount == 1
              ? 'This uses your last freeze to protect your streak after a missed day. Skill scores stay the same.'
              : 'This uses 1 of ${state.streakFreezeCount} freezes to protect your streak after a missed day. Skill scores stay the same.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Apply freeze'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await HakkiriLoadingOverlay.run(
        context,
        message: 'Applying freeze…',
        detail: 'Protecting your streak.',
        action: () => state.freezeStreakFromApi(),
      );
      if (!context.mounted) return;
      AppSnackBar.showSuccess(
        context,
        state.streakFreezeCount > 0
            ? 'Freeze applied. ${state.streakFreezeCount} freeze${state.streakFreezeCount == 1 ? '' : 's'} left.'
            : 'Freeze applied. No freezes left.',
      );
    } on HakkiriApiException catch (e) {
      if (!context.mounted) return;
      AppSnackBar.showError(context, e.message);
    } catch (_) {
      if (!context.mounted) return;
      AppSnackBar.showError(
        context,
        'Could not apply freeze. Check your connection.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PushNotificationService.instance.requestPermissionOnHomeScreen();
    });

    final state = Provider.of<AppStateProvider>(context);
    // First open: shimmer until API bootstrap — don't flash default placeholder data.
    if (state.isLoggedIn && !state.hasBootstrapped) {
      return const HomeLoadingShimmer();
    }

    final coreDone = state.completedTodayDrills().clamp(0, 3);
    final planTotal = state.totalTodayActivitiesCount();
    final planDone = state.completedTotalActivitiesToday().clamp(0, planTotal);
    final remaining = (planTotal - planDone).clamp(0, planTotal);
    final bool hasStarted = planDone > 0 || state.completedSessions > 0;
    final weekDays = state.practiceDaysThisWeek;
    final drills = state.todayDrillSlugs.take(3).toList();
    final minutes = state.dailyAnchorMinutes;
    final offerExtras = state.shouldOfferPlanExtras;
    final weakest = state.getWeakestExerciseToday();
    final primarySlug = drills.isNotEmpty ? drills.first : 'think_fast';
    final primaryActivity = state.activities.firstWhere(
      (a) => a.slug == primarySlug,
      orElse: () => state.activities.first,
    );
    String nextSlug;
    String nextLabel;
    final nextIncomplete = state.firstIncompleteCoreSlug();
    if (offerExtras) {
      nextSlug = (weakest['slug'] as String?) ?? primarySlug;
      nextLabel = minutes >= 15
          ? 'Choose retry or stretch'
          : 'Targeted retry';
    } else if (nextIncomplete == null) {
      nextSlug = primarySlug;
      nextLabel = 'Plan complete';
    } else {
      nextSlug = nextIncomplete;
      nextLabel = hasStarted ? 'UP NEXT · ~2 MIN' : 'START HERE · ~2 MIN';
    }
    final nextActivity = state.activities.firstWhere(
      (a) => a.slug == nextSlug,
      orElse: () => primaryActivity,
    );
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
                        ? (remaining == 0
                            ? (minutes >= 15
                                ? 'Excellent work —\n'
                                : 'Nice work —\n')
                            : 'Nice start.\n')
                        : 'Your $minutes-minute plan is ready.\n',
                  ),
                  TextSpan(
                    text: hasStarted
                        ? (remaining == 0
                            ? 'your $minutes-minute plan is complete.'
                            : offerExtras
                                ? (minutes >= 15
                                    ? 'Ready for a bigger stretch?'
                                    : 'One more to lock it in.')
                                : remaining == 1
                                    ? 'One to go today.'
                                    : '$remaining to go today.')
                        : minutes >= 15
                            ? 'More time, deeper practice.'
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
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: state.streakFreezeCount > 0
                              ? () => _onFreezeTap(context)
                              : null,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.ac_unit_rounded,
                                  size: 14,
                                  color: state.streakFreezeCount > 0
                                      ? AppColors.royalBlue
                                      : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  state.streakFreezeCount > 0
                                      ? '${state.streakFreezeCount} freeze ready'
                                      : 'No freeze left',
                                  style: TextStyle(
                                    color: state.streakFreezeCount > 0
                                        ? AppColors.royalBlue
                                        : AppColors.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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
            Material(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProfileSectionScreen(
                        focus: ProfileSectionFocus.goals,
                      ),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
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
              ),
            ),
            const SizedBox(height: 18),

            // Hero Dark Card (Navy Gradient Card with Circular Progress and Play button)
            if (remaining > 0)
              GestureDetector(
                onTap: () {
                  if (offerExtras) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TargetedRetryScreen(
                          is15MinutePlan: minutes >= 15,
                        ),
                      ),
                    );
                    return;
                  }
                  state.selectActivity(nextActivity.slug);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ActivityDetailScreen(),
                    ),
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
                      SizedBox(
                        width: 58,
                        height: 58,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: planTotal == 0
                                  ? 0
                                  : (planDone / planTotal).clamp(0.0, 1.0),
                              strokeWidth: 4,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.15),
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nextLabel.toUpperCase(),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              offerExtras
                                  ? (weakest['name'] as String? ??
                                      nextActivity.name)
                                  : nextActivity.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              offerExtras
                                  ? 'Based on today\'s scores'
                                  : nextActivity.tagline,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.65),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
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
                              color: const Color(0xFF2563EB)
                                  .withValues(alpha: 0.45),
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
            if (remaining > 0) const SizedBox(height: 24),

            // Section Heading: TODAY'S PLAN
            Text(
              remaining == 0
                  ? "TODAY'S PLAN · $planDone/$planTotal ACTIVITIES"
                  : coreDone >= 3
                      ? "TODAY'S PLAN · PERSONALISED FOR YOU"
                      : "TODAY'S PLAN · 3 CORE EXERCISES",
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),

            ...drills.asMap().entries.map((entry) {
              final index = entry.key;
              final slug = entry.value;
              final activity = state.activities.firstWhere(
                (a) => a.slug == slug,
                orElse: () => state.activities.first,
              );
              final doneToday = state.isCoreSlugDoneToday(slug);
              final visuals = _exerciseVisual(slug);
              return Padding(
                padding: EdgeInsets.only(bottom: index < drills.length - 1 ? 10 : 0),
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
                      MaterialPageRoute(
                        builder: (_) => const ActivityDetailScreen(),
                      ),
                    );
                  },
                ),
              );
            }),

            // 10/15 bonus rows
            if (minutes >= 10) ...[
              const SizedBox(height: 10),
              _buildExerciseCard(
                context: context,
                icon: Icons.refresh_rounded,
                iconColor: const Color(0xFF2563EB),
                iconBgColor: const Color(0xFFDBEAFE),
                title: 'Targeted retry',
                subtitle: state.isTargetedRetryCompletedToday
                    ? '${weakest['name']} again'
                    : (coreDone >= 3
                        ? '${weakest['name']} · weakest area'
                        : 'Unlocks after 3 core exercises'),
                isCompleted: state.isTargetedRetryCompletedToday,
                trailingText: state.isTargetedRetryCompletedToday
                    ? null
                    : (coreDone >= 3 ? 'Ready' : 'Locked'),
                onTap: coreDone >= 3 && !state.isTargetedRetryCompletedToday
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TargetedRetryScreen(
                              is15MinutePlan: minutes >= 15,
                            ),
                          ),
                        );
                      }
                    : null,
              ),
            ],
            if (minutes >= 15) ...[
              const SizedBox(height: 10),
              _buildExerciseCard(
                context: context,
                icon: Icons.bolt_rounded,
                iconColor: const Color(0xFFDC2626),
                iconBgColor: const Color(0xFFFEE2E2),
                title: 'Tougher challenge',
                subtitle: state.isTougherChallengeCompletedToday
                    ? '${weakest['stretchName']} stretch'
                    : (coreDone >= 3
                        ? '${weakest['stretchName']} · stretch round'
                        : 'Unlocks after 3 core exercises'),
                isCompleted: state.isTougherChallengeCompletedToday,
                trailingText: state.isTougherChallengeCompletedToday
                    ? null
                    : (coreDone >= 3 ? 'Ready' : 'Locked'),
                onTap: coreDone >= 3 && !state.isTougherChallengeCompletedToday
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TargetedRetryScreen(
                              is15MinutePlan: true,
                            ),
                          ),
                        );
                      }
                    : null,
              ),
            ],
            const SizedBox(height: 12),

            // Bottom Highlight Mint Green Card → Progress tab
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => MainTabScaffold.switchTab(context, 1),
                borderRadius: BorderRadius.circular(18),
                child: Ink(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFC8E6C9),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Color(0xFFC8E6C9),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          remaining == 0
                              ? Icons.emoji_events_rounded
                              : coreDone >= 3
                                  ? Icons.lock_open_rounded
                                  : Icons.lock_outline_rounded,
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
                              remaining == 0
                                  ? 'PLAN COMPLETE'
                                  : minutes == 5
                                      ? progressTitle
                                      : 'AFTER THESE 3',
                              style: const TextStyle(
                                color: Color(0xFF2E7D32),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              remaining == 0
                                  ? 'You completed $planDone/$planTotal activities today.'
                                  : minutes == 5
                                      ? progressHeadline
                                      : minutes == 10
                                          ? 'Unlock 1 targeted retry. We\'ll pick the exercise that needs one more go.'
                                          : 'Unlock 1 targeted retry + 1 tougher challenge. Finish your core 3, then keep going.',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (minutes == 5 && remaining > 0)
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
    VoidCallback? onTap,
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
