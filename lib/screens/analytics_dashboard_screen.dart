import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/app_state_provider.dart';
import '../widgets/dashed_border.dart';
import 'main_tab_scaffold.dart';

class AnalyticsDashboardScreen extends StatelessWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainTabScaffold(initialIndex: 1);
  }
}

class AnalyticsDashboardContent extends StatelessWidget {
  const AnalyticsDashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final fluency = _barFromPillar(state, 'executive_presence');
    final clarity = _barFromPillar(state, 'clarity');
    final engagement = _barFromPillar(state, 'engagement');
    final impact = _barFromPillar(state, 'impact');
    final recent = state.sessionHistory.take(3).toList();

    return SafeArea(
      bottom: false,
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
                  child: fluency.$1
                      ? _buildNeedMoreBarColumn(label: 'Fluency &\npresence')
                      : _buildBarColumn(
                          scoreText: fluency.$2,
                          label: 'Fluency &\npresence',
                          fillPercentage: fluency.$3,
                          barColor: const Color(0xFF9EA7FA),
                        ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: clarity.$1
                      ? _buildNeedMoreBarColumn(label: 'Clarity')
                      : _buildBarColumn(
                          scoreText: clarity.$2,
                          label: 'Clarity',
                          fillPercentage: clarity.$3,
                          barColor: AppColors.royalBlue,
                        ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: engagement.$1
                      ? _buildNeedMoreBarColumn(label: 'Engagement &\ntone')
                      : _buildBarColumn(
                          scoreText: engagement.$2,
                          label: 'Engagement &\ntone',
                          fillPercentage: engagement.$3,
                          barColor: const Color(0xFF9EA7FA),
                        ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: impact.$1
                      ? _buildNeedMoreBarColumn(label: 'Conciseness &\nimpact')
                      : _buildBarColumn(
                          scoreText: impact.$2,
                          label: 'Conciseness &\nimpact',
                          fillPercentage: impact.$3,
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
                  Expanded(
                    child: Text(
                      state.overallAverage == null
                          ? 'Unlocks when every skill has 3 valid attempts.'
                          : 'Overall ${state.overallAverage!.toStringAsFixed(1)} from ${state.overallSamples} fresh prompts.',
                      style: const TextStyle(
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
                children: [
                  Text(
                    '${state.currentStreak}-day streak · ${state.totalXp} XP',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
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

            if (recent.isEmpty)
              const Text(
                'No sessions yet.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              )
            else
              ...recent.map(
                (session) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _buildRecentPracticeRow(
                    score: session.feedback.overallScore.toStringAsFixed(1),
                    title: session.activityName,
                    date: _shortDay(session.timestamp),
                  ),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  static (bool, String, double) _barFromPillar(AppStateProvider state, String key) {
    final raw = state.pillarStats[key];
    if (raw is! Map) return (true, '--', 0);
    final map = Map<String, dynamic>.from(raw);
    final average = map['average'];
    final samples = (map['samples'] as num?)?.round() ?? 0;
    if (average == null || samples < 3 || map['status'] == 'need_more') {
      return (true, '--', 0);
    }
    final value = (average as num).toDouble();
    return (false, value.toStringAsFixed(1), (value / 5).clamp(0.0, 1.0));
  }

  static String _shortDay(DateTime stamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(stamp.year, stamp.month, stamp.day);
    if (day == today) return 'Today';
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[stamp.weekday - 1];
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
        // Dotted / Dashed Box with DashedBorderContainer
        DashedBorderContainer(
          borderRadius: 12,
          strokeWidth: 1.5,
          dashWidth: 4.5,
          dashGap: 4.0,
          color: const Color(0xFFC4C2B8),
          child: const SizedBox(
            height: 120,
            width: double.infinity,
            child: Center(
              child: Text(
                'NEED MORE',
                style: TextStyle(
                  color: Color(0xFF8B8E9E),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
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
