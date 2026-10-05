import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../widgets/hakkiri_bottom_nav.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  int _navIndex = 1; // Tab 1: Analytics active

  void _onBottomNavTap(int index) {
    if (index == 0) {
      Navigator.pop(context);
    } else {
      setState(() => _navIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: HakkiriBottomNav(
        currentIndex: _navIndex,
        onTap: _onBottomNavTap,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Tag
              const Text(
                'LAST 30 DAYS  ·  FRESH PROMPTS ONLY',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),

              // Title with Royal Blue Accent
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
                    TextSpan(text: 'Analytics\n'),
                    TextSpan(
                      text: 'Your clarity profile.',
                      style: TextStyle(color: AppColors.royalBlue),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // 4-Column Bar Chart
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: _buildBarColumn(
                      scoreText: '3.4',
                      label: 'Fluency &\npresence',
                      fillPercentage: 0.68,
                      barColor: const Color(0xFF9EA7FA),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildBarColumn(
                      scoreText: '3.8',
                      label: 'Clarity',
                      fillPercentage: 0.76,
                      barColor: AppColors.royalBlue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildNeedMoreBarColumn(
                      label: 'Engagement &\ntone',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildBarColumn(
                      scoreText: '3.1',
                      label: 'Conciseness &\nimpact',
                      fillPercentage: 0.62,
                      barColor: const Color(0xFF9EA7FA),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // OVERALL Requirement Card (Dark Navy)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF141522),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'OVERALL',
                      style: TextStyle(
                        color: Color(0xFF7A89FF),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Unlocks when every skill has 3 valid attempts. Engagement needs 2 more.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Streak & XP Rewards Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      '4-day streak · 320 XP',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Rewards for showing up. Never part of your skill scores.',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Recent Practice Section
              const Text(
                'RECENT  PRACTICE',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 14),

              _buildRecentPracticeRow(score: '3.7', title: 'Think First', date: 'Today'),
              const SizedBox(height: 14),
              _buildRecentPracticeRow(score: '—', title: 'Cut it in Half', date: 'Retry · practice', isMuted: true),
              const SizedBox(height: 14),
              _buildRecentPracticeRow(score: '3.3', title: 'Explain it Simply', date: 'Sat'),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBarColumn({
    required String scoreText,
    required String label,
    required double fillPercentage,
    required Color barColor,
  }) {
    return Column(
      children: [
        Text(
          scoreText,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        // Bar Container
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: const Color(0xFFECEAE2),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.bottomCenter,
          child: Container(
            height: 120 * fillPercentage,
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildNeedMoreBarColumn({required String label}) {
    return Column(
      children: [
        const Text(
          '–',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        // Dotted / Dashed Box
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFC4C2B8),
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: const Text(
            'NEED MORE',
            style: TextStyle(
              color: Color(0xFF8B8E9E),
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentPracticeRow({
    required String score,
    required String title,
    required String date,
    bool isMuted = false,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 30,
          child: Text(
            score,
            style: TextStyle(
              color: isMuted ? AppColors.textMuted : AppColors.royalBlue,
              fontSize: 14,
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
          date,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
