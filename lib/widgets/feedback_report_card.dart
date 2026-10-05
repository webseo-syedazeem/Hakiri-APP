import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/session_model.dart';
import 'metric_radar_card.dart';

class FeedbackReportCard extends StatelessWidget {
  final EvaluationFeedback feedback;
  final VoidCallback onRetry;
  final VoidCallback onFinish;

  const FeedbackReportCard({
    super.key,
    required this.feedback,
    required this.onRetry,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Overall Score
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feedback.isCoachedRetry ? 'COACHED RETRY EVALUATION' : 'INITIAL DRILL EVALUATION',
                      style: const TextStyle(
                        color: AppColors.accentCyan,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Executive Presence Score',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${feedback.overallScore}.0',
                        style: const TextStyle(
                          color: AppColors.accentCyan,
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const TextSpan(
                        text: ' / 5.0',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4 Pillars Radar Card
          MetricRadarCard(pillars: feedback.pillars),
          const SizedBox(height: 16),

          // Mandatory 4 Strict Items
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Coaching Directives & Action Items',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),

                // 1. One Strength
                _buildFeedbackBlock(
                  badge: '✓ VERIFIED STRENGTH',
                  badgeColor: AppColors.accentEmerald,
                  bgColor: AppColors.accentEmerald.withValues(alpha: 0.08),
                  borderColor: AppColors.accentEmerald,
                  text: feedback.oneStrength,
                ),
                const SizedBox(height: 12),

                // 2. One Specific Improvement
                _buildFeedbackBlock(
                  badge: '⚡ PRIMARY AREA FOR IMPROVEMENT',
                  badgeColor: AppColors.accentRose,
                  bgColor: AppColors.accentRose.withValues(alpha: 0.08),
                  borderColor: AppColors.accentRose,
                  text: feedback.oneSpecificImprovement,
                ),
                const SizedBox(height: 12),

                // 3. Highlighted Phrase / Timestamp
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceBorder,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '⏱️ TIMESTAMP ${feedback.highlightedPhrase.timestampRange}',
                        style: const TextStyle(
                          color: AppColors.accentCyan,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '"${feedback.highlightedPhrase.phrase}"',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        feedback.highlightedPhrase.critique,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 4. Clear Instruction for the Retry
                _buildFeedbackBlock(
                  badge: '🔄 NEXT REP COACHING DIRECTIVE',
                  badgeColor: AppColors.accentCyan,
                  bgColor: AppColors.accentCyan.withValues(alpha: 0.08),
                  borderColor: AppColors.accentCyan,
                  text: feedback.retryInstruction,
                ),
                const SizedBox(height: 16),

                // Exemplar Response
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F141E),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🌟 EXEMPLAR HIGH-IMPACT RESPONSE',
                        style: TextStyle(
                          color: AppColors.accentPurple,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '"${feedback.exemplarResponse}"',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentCyan,
                    foregroundColor: AppColors.textInverse,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Start Coached Retry 🔄',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  onPressed: onFinish,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.surfaceBorder),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Finish Drill ✓'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildFeedbackBlock({
    required String badge,
    required Color badgeColor,
    required Color bgColor,
    required Color borderColor,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: borderColor, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            badge,
            style: TextStyle(
              color: badgeColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
