import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../widgets/hakkiri_logo.dart';
import '../widgets/action_pill_button.dart';
import '../widgets/live_waveform_bars.dart';
import 'assessment_intro_screen.dart';
import 'login_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

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
              // Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const HakkiriLogo(
                    variant: HakkiriLogoVariant.compactMark,
                    size: 20,
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    child: const Text(
                      'Log in',
                      style: TextStyle(
                        color: AppColors.royalBlue,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              // Main Hero Area
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Title with Japanese Watermark Stack
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: -8,
                        top: -24,
                        child: Text(
                          'はっきり',
                          style: TextStyle(
                            fontSize: 72,
                            fontWeight: FontWeight.w900,
                            color: Colors.black.withValues(alpha: 0.04),
                            letterSpacing: 4.0,
                          ),
                        ),
                      ),
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 44,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                            height: 1.15,
                            letterSpacing: -1.2,
                          ),
                          children: [
                            TextSpan(text: 'Say what\nyou mean.\n'),
                            TextSpan(
                              text: 'First time.',
                              style: TextStyle(color: AppColors.royalBlue),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // LIVE · THINK FIRST Waveform Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'LIVE  ·  THINK FIRST',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: AppColors.coralRed,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'REC 0:12',
                                  style: TextStyle(
                                    color: AppColors.coralRed,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    fontFeatures: [FontFeature.tabularFigures()],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Live dynamic animated waveform bars
                        const LiveWaveformBars(
                          barCount: 22,
                          maxHeight: 44,
                          color: AppColors.royalBlue,
                          isAnimated: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Description Text
                  const Text(
                    'Short daily speaking practice built around your job, with instant feedback on speed, structure and filler words.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                      height: 1.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Carousel Indicator (Dash + Dots)
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.textPrimary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppColors.textMuted.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppColors.textMuted.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Bottom Area
              Column(
                children: [
                  ActionPillButton(
                    label: 'Start your assessment',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AssessmentIntroScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'CLEARLY  ·  DISTINCTLY  ·  FIRST TIME',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
