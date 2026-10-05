import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/session_model.dart';

class MetricRadarCard extends StatelessWidget {
  final FourPillarsScore pillars;

  const MetricRadarCard({
    super.key,
    required this.pillars,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _MetricItem(
        label: 'Executive Presence',
        score: pillars.executiveScore,
        subtitle: '${pillars.crutchCount} crutches • ${pillars.powerPauseCount} power pauses',
        color: AppColors.accentCyan,
      ),
      _MetricItem(
        label: 'Clarity & Articulation',
        score: pillars.clarityScore,
        subtitle: '${pillars.pacingWpm} WPM • ${pillars.intelligibilityPercentage}% intelligibility',
        color: AppColors.accentBlue,
      ),
      _MetricItem(
        label: 'Content Impact & Conciseness',
        score: pillars.impactScore,
        subtitle: '${pillars.actionVerbPercentage}% active verbs • BLUF check',
        color: AppColors.accentPurple,
      ),
      _MetricItem(
        label: 'Engagement Dynamics',
        score: pillars.engagementScore,
        subtitle: pillars.isMonotoneWarning ? 'Monotone Warning' : 'Dynamic Pitch & Decibel Peaks',
        color: AppColors.accentEmerald,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Four Pillars Executive Analysis',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '1–5 Scale',
                style: TextStyle(
                  color: AppColors.accentCyan,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...metrics.map((m) => _buildMetricRow(m)),
        ],
      ),
    );
  }

  Widget _buildMetricRow(_MetricItem item) {
    final progress = (item.score / 5.0).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${item.score}.0 / 5.0',
                style: TextStyle(
                  color: item.color,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.metricTrack,
              valueColor: AlwaysStoppedAnimation<Color>(item.color),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.subtitle,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricItem {
  final String label;
  final int score;
  final String subtitle;
  final Color color;

  _MetricItem({
    required this.label,
    required this.score,
    required this.subtitle,
    required this.color,
  });
}
