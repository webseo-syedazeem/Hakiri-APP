import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class ChallengesScreen extends StatelessWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'COMMUNICATION GYM  ·  WEEKLY SPRINTS',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
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
                    TextSpan(text: 'Challenges\n'),
                    TextSpan(
                      text: 'Build the reflex.',
                      style: TextStyle(color: AppColors.royalBlue),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Active Challenge 1 (Featured Dark Card)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF141522),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.royalBlue,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'ACTIVE CHALLENGE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const Text(
                          'DAY 3 OF 7',
                          style: TextStyle(
                            color: Color(0xFFA0A3B5),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'The 7-Day BLUF Sprint',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Deliver Bottom-Line-Up-Front. Open your answer within 5 seconds without narrative warm-ups or filler words.',
                      style: TextStyle(
                        color: Color(0xFF8E91A6),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: const LinearProgressIndicator(
                        value: 0.43,
                        minHeight: 6,
                        backgroundColor: Color(0xFF26283D),
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.royalBlue),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Challenge 2 (White Card)
              _buildChallengeCard(
                title: 'The Silent Power Pause',
                tag: 'EXECUTIVE PRESENCE',
                description: 'Hold a 1.5s deliberate silent pause immediately before stating your core business recommendation.',
                progress: '1/3 Completed',
              ),
              const SizedBox(height: 12),

              // Challenge 3 (White Card)
              _buildChallengeCard(
                title: 'Jargon Elimination',
                tag: 'EXPLAIN IT SIMPLY',
                description: 'Complete 3 technical explanations without uttering buzzwords or multi-clausal run-ons.',
                progress: 'Ready to Start',
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChallengeCard({
    required String title,
    required String tag,
    required String description,
    required String progress,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              Text(
                progress,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
