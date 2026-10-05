import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../widgets/week_calendar_strip.dart';
import '../widgets/action_pill_button.dart';
import 'paywall_screen.dart';

class PersonalizedPlanScreen extends StatefulWidget {
  const PersonalizedPlanScreen({super.key});

  @override
  State<PersonalizedPlanScreen> createState() => _PersonalizedPlanScreenState();
}

class _PersonalizedPlanScreenState extends State<PersonalizedPlanScreen> {
  int _selectedDay = 0; // MON 1

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      // Top Tag
                      const Text(
                        'WEEK ONE  ·  5 MIN A DAY',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Heading with royal blue accent
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: AppColors.textPrimary,
                            fontSize: 34,
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
                      const SizedBox(height: 8),

                      // User track summary
                      const Text(
                        'Sales & Marketing · Mid-level · Focus: go blank on the spot',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Week Calendar
                      WeekCalendarStrip(
                        selectedDayIndex: _selectedDay,
                        onDaySelected: (idx) => setState(() => _selectedDay = idx),
                      ),
                      const SizedBox(height: 20),

                      // Today's Featured Card (Dark Navy Card)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141522),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
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
                                    'TODAY  ·  60 SEC  ·  1 OF 3',
                                    style: TextStyle(
                                      color: Color(0xFFA3A6B8),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Think First',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Three seconds to think. Then speak.',
                                    style: TextStyle(
                                      color: Color(0xFF8E91A6),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Play Button
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: AppColors.royalBlue,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Upcoming Activities List
                      _buildUpcomingRow('02', 'Debate Me', 'Hold your ground on price'),
                      const SizedBox(height: 14),
                      _buildUpcomingRow('03', 'Cut it in Half', 'Lead with the point'),
                      const SizedBox(height: 14),
                      _buildUpcomingRow('04', 'Connect the Dots', 'Link ideas on the fly'),
                      const SizedBox(height: 14),
                      _buildUpcomingRow('05', 'Re-assess', 'See how far you’ve come'),

                      const SizedBox(height: 24),

                      // Change activities link
                      GestureDetector(
                        onTap: () {},
                        child: const Text(
                          'Change my activities',
                          style: TextStyle(
                            color: AppColors.royalBlue,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.royalBlue,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // Bottom Continue Button
              ActionPillButton(
                label: 'Continue',
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const PaywallScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingRow(String num, String title, String subtitle) {
    return Row(
      children: [
        SizedBox(
          width: 26,
          child: Text(
            num,
            style: const TextStyle(
              color: AppColors.royalBlue,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
