import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../widgets/action_pill_button.dart';
import '../widgets/hakkiri_logo.dart';
import 'assessment_screen.dart';

class AssessmentIntroScreen extends StatelessWidget {
  const AssessmentIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBF9),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Centered Official Hakkiri Brand Mark
              Center(
                child: const HakkiriLogo(
                  variant: HakkiriLogoVariant.fullImage,
                  size: 85,
                ),
              ),
              const SizedBox(height: 24),

              // Category Tracker & Step
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'YOUR ASSESSMENT',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    '01/07',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Step Progress Line
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: 1 / 7,
                  minHeight: 3.5,
                  backgroundColor: const Color(0xFFECEBE4),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.royalBlue),
                ),
              ),
              const SizedBox(height: 28),

              // Main Heading: "Let's personalize your plan"
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    height: 1.15,
                    letterSpacing: -1.0,
                  ),
                  children: [
                    TextSpan(text: "Let's personalize\n"),
                    TextSpan(
                      text: 'your plan',
                      style: TextStyle(color: AppColors.royalBlue),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Subtitle
              const Text(
                'Answer 7 quick questions to understand how you speak, where you get stuck, and what you want to improve.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 28),

              // 3 Value Benefit Cards
              _buildBenefitCard(
                icon: Icons.bar_chart_rounded,
                title: 'Find your biggest speaking blockers',
                subtitle: "Identify what's holding you back.",
              ),
              const SizedBox(height: 12),

              _buildBenefitCard(
                icon: Icons.article_outlined,
                title: 'Get a personalized practice plan',
                subtitle: 'Tailored to your goals and needs.',
              ),
              const SizedBox(height: 12),

              _buildBenefitCard(
                icon: Icons.auto_awesome_outlined,
                title: 'Build more clarity, confidence and presence',
                subtitle: 'Speak with greater impact.',
              ),

              const Spacer(),

              // Takes less than 2 minutes
              Row(
                children: const [
                  Icon(
                    Icons.access_time_rounded,
                    color: AppColors.textMuted,
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Takes less than 2 minutes.',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Start Assessment Pill Button
              ActionPillButton(
                label: 'Start assessment',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AssessmentScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAE9E2), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: AppColors.textPrimary, size: 22),
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
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
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
