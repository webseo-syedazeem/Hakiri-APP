import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../widgets/action_pill_button.dart';
import '../widgets/hakkiri_logo.dart';
import '../widgets/week_calendar_strip.dart';
import 'paywall_screen.dart';

class PersonalizedPlanScreen extends StatefulWidget {
  const PersonalizedPlanScreen({super.key});

  @override
  State<PersonalizedPlanScreen> createState() => _PersonalizedPlanScreenState();
}

class _PersonalizedPlanScreenState extends State<PersonalizedPlanScreen> {
  int _selectedDay = 0; // Monday 1

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBF9),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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
                    variant: HakkiriLogoVariant.compactMark,
                    size: 22,
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
                      const Center(
                        child: Text(
                          'WEEK 1  ·  5 MIN A DAY',
                          style: TextStyle(
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

                      // Subtitle
                      const Text(
                        'Built around: thinking on your feet',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Dual Focus Cards (Side by side)
                      Row(
                        children: [
                          Expanded(
                            child: _buildFocusCard(
                              tag: 'FOCUS 1',
                              title: 'Answer first, then explain',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildFocusCard(
                              tag: 'FOCUS 2',
                              title: 'Pause instead of filling',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // 7-Day Calendar Strip
                      WeekCalendarStrip(
                        selectedDayIndex: _selectedDay,
                        onDaySelected: (idx) => setState(() => _selectedDay = idx),
                      ),
                      const SizedBox(height: 20),

                      // Today's Featured Drill Card (Dark Navy Card with Blue Play Button)
                      Container(
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'TODAY  ·  50 SEC  ·  1 OF 4',
                                    style: TextStyle(
                                      color: Color(0xFFA3A6B8),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Think Fast',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Three quick reps to think, then speak.',
                                    style: TextStyle(
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
                                color: AppColors.royalBlue,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Upcoming Drills List with chevron >
                      _buildDrillItem('02', 'Cut it in Half', 'Lead with the point'),
                      const Divider(height: 24, color: Color(0xFFEAE9E2)),
                      _buildDrillItem('03', 'Debate Me', 'Stay clear when challenged'),
                      const Divider(height: 24, color: Color(0xFFEAE9E2)),
                      _buildDrillItem('04', 'Storytelling Gym', 'Make one point land'),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Bottom Continue Action Button
              ActionPillButton(
                label: 'Continue',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PaywallScreen()),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFocusCard({required String tag, required String title}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAE9E2), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tag,
            style: const TextStyle(
              color: AppColors.royalBlue,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrillItem(String index, String title, String subtitle) {
    return Row(
      children: [
        Text(
          index,
          style: const TextStyle(
            color: AppColors.royalBlue,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        const Icon(
          Icons.chevron_right_rounded,
          color: AppColors.textMuted,
          size: 18,
        ),
      ],
    );
  }
}
