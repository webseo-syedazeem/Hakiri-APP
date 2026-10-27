import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/app_state_provider.dart';
import '../widgets/action_pill_button.dart';
import '../widgets/hakkiri_logo.dart';
import '../widgets/week_calendar_strip.dart';
import 'activity_detail_screen.dart';
import 'paywall_screen.dart';

class PersonalizedPlanScreen extends StatefulWidget {
  const PersonalizedPlanScreen({super.key});

  @override
  State<PersonalizedPlanScreen> createState() => _PersonalizedPlanScreenState();
}

class _PersonalizedPlanScreenState extends State<PersonalizedPlanScreen> {
  int _selectedDay = 0; // Monday 1
  bool _startingTrial = false;

  static const _drillNames = {
    'think_fast': 'Think Fast',
    'connect_the_dots': 'Connect the Dots',
    'explain_it_simply': 'Explain it Simply',
    'cut_it_in_half': 'Cut it in Half',
    'storytelling_gym': 'Storytelling Gym',
    'one_minute_expert': 'One Minute Expert',
    'debate_me': 'Debate Me',
  };

  static const _drillSubtitles = {
    'think_fast': 'Three quick reps to think, then speak.',
    'connect_the_dots': 'Link two random ideas into one story.',
    'explain_it_simply': 'Make complex concepts plain & simple.',
    'cut_it_in_half': 'Lead with the point, cut the clutter.',
    'storytelling_gym': 'Make one clear point land with impact.',
    'one_minute_expert': 'Deliver your message in sixty seconds.',
    'debate_me': 'Stay clear and steady when challenged.',
  };

  Future<void> _openDrillDetail(
    AppStateProvider state,
    String activitySlug,
  ) async {
    if (_startingTrial || state.isLoggedIn) return;
    if (state.guestTrialUsed) {
      await _goToPaywall(state);
      return;
    }
    setState(() => _startingTrial = true);
    try {
      state.ensureActivitySelected(activitySlug);
      if (!mounted) return;
      // Plan → activity detail (same as Home) → one free Begin → IAP.
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ActivityDetailScreen(activitySlug: activitySlug),
        ),
      );
    } finally {
      if (mounted) setState(() => _startingTrial = false);
    }
  }

  Future<void> _goToPaywall(AppStateProvider state) async {
    if (!state.isLoggedIn) {
      await state.markGuestReachedPaywall();
    }
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PaywallScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final plan = state.personalizedPlan;
    final drills = plan?.initialDrills ?? ['think_fast', 'cut_it_in_half', 'debate_me'];

    // Guest: one free try on any listed drill (same detail screens as Home).
    final primarySlug = 'think_fast';
    final primaryTitle = _drillNames[primarySlug]!;
    final trialUsed = !state.isLoggedIn && state.guestTrialUsed;

    final otherSlugs = drills
        .where((s) => s != 'think_fast')
        .toList();
    final focusOthers = otherSlugs.isNotEmpty
        ? otherSlugs
        : <String>['cut_it_in_half', 'debate_me'];

    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final bottomGap = isIOS ? (safeBottom > 0 ? 20.0 : 12.0) : 14.0;

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBF9),
      body: SafeArea(
        bottom: !isIOS,
        child: Padding(
          padding: EdgeInsets.fromLTRB(14, 10, 14, bottomGap),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar with back chevron and centered logo
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.chevron_left_rounded,
                      color: AppColors.textPrimary,
                      size: 28,
                    ),
                  ),
                  const HakkiriLogo(
                    variant: HakkiriLogoVariant.headerPlanLockup,
                    size: 24,
                  ),
                  const SizedBox(width: 28), // Balance spacing
                ],
              ),
              const SizedBox(height: 16),

              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Centered Week Tag
                      Center(
                        child: Text(
                          'WEEK 1  ·  ${state.selectedDifficulty.toUpperCase()}  ·  5 MIN A DAY',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Heading with Royal Blue Accent
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: AppColors.textPrimary,
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.0,
                            height: 1.15,
                          ),
                          children: [
                            TextSpan(text: 'Your plan is\n'),
                            TextSpan(
                              text: 'ready.',
                              style: TextStyle(color: AppColors.royalBlue),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Subtitle: Built around Goal & Challenge
                      Text(
                        state.primaryGoalLabel.isNotEmpty && state.primaryGoalLabel != 'Not set'
                            ? 'Built around: ${state.primaryGoalLabel} & ${state.roadblockLabel}'
                            : 'Built around: ${state.roadblockLabel}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Three Focus Cards
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        clipBehavior: Clip.none,
                        child: Row(
                          children: [
                            _buildFocusCard(
                              tag: 'FOCUS 1',
                              title: primaryTitle,
                            ),
                            const SizedBox(width: 12),
                            _buildFocusCard(
                              tag: 'FOCUS 2',
                              title: focusOthers.isNotEmpty
                                  ? (_drillNames[focusOthers[0]] ?? 'Practice')
                                  : 'Cut it in Half',
                            ),
                            const SizedBox(width: 12),
                            _buildFocusCard(
                              tag: 'FOCUS 3',
                              title: focusOthers.length > 1
                                  ? (_drillNames[focusOthers[1]] ?? 'Debate Me')
                                  : 'Debate Me',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 7-Day Calendar Strip
                      WeekCalendarStrip(
                        selectedDayIndex: _selectedDay,
                        onDaySelected: (idx) => setState(() => _selectedDay = idx),
                      ),
                      const SizedBox(height: 20),

                      // Guest: one free try (any drill). Then IAP.
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: state.isLoggedIn
                              ? null
                              : () => _openDrillDetail(state, primarySlug),
                          borderRadius: BorderRadius.circular(20),
                          child: Ink(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF141522),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.10),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        trialUsed
                                            ? 'FREE TRY USED'
                                            : 'FREE TRY  ·  ONCE  ·  ANY DRILL',
                                        style: const TextStyle(
                                          color: Color(0xFFA3A6B8),
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        primaryTitle,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        trialUsed
                                            ? 'Subscribe to practise again — this try isn’t saved.'
                                            : 'Try one drill free. Fresh question from Hakkiri.',
                                        style: const TextStyle(
                                          color: Color(0xFF8E91A6),
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: trialUsed
                                        ? const Color(0xFF475569)
                                        : AppColors.royalBlue,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    trialUsed
                                        ? Icons.lock_outline_rounded
                                        : Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Other drills — same detail screens as Home; one shared trial.
                      for (int i = 0; i < focusOthers.length; i++) ...[
                        _buildDrillItem(
                          '0${i + 2}',
                          _drillNames[focusOthers[i]] ?? focusOthers[i],
                          _drillSubtitles[focusOthers[i]] ??
                              'Targeted daily practice',
                          onTap: state.isLoggedIn
                              ? null
                              : () => _openDrillDetail(state, focusOthers[i]),
                        ),
                        if (i < focusOthers.length - 1)
                          const Divider(height: 24, color: Color(0xFFEAE9E2)),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              ActionPillButton(
                label: state.isLoggedIn ? 'Continue' : 'Unlock Hakkiri Pro',
                onTap: () => _goToPaywall(state),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFocusCard({required String tag, required String title}) {
    return Container(
      width: 155,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFECECE8), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tag,
            style: const TextStyle(
              color: AppColors.royalBlue,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrillItem(
    String num,
    String title,
    String subtitle, {
    VoidCallback? onTap,
  }) {
    final row = Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F0E9),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            num,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
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
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const Icon(
          Icons.chevron_right_rounded,
          color: Color(0xFFBDBCAF),
          size: 22,
        ),
      ],
    );
    if (onTap == null) return row;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: row,
        ),
      ),
    );
  }
}
