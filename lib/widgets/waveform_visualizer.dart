import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class WaveformVisualizer extends StatelessWidget {
  final bool isRecording;
  final int secondsRemaining;

  const WaveformVisualizer({
    super.key,
    required this.isRecording,
    required this.secondsRemaining,
  });

  String _formatTime(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    return '$m:${s < 10 ? '0' : ''}$s';
  }

  @override
  Widget build(BuildContext context) {
    final barHeights = [20.0, 45.0, 60.0, 85.0, 70.0, 35.0, 55.0, 80.0, 95.0, 65.0, 40.0, 75.0, 85.0, 50.0, 30.0, 70.0, 80.0, 40.0];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRecording ? AppColors.accentRose : AppColors.surfaceBorder,
        ),
      ),
      child: Column(
        children: [
          Text(
            _formatTime(secondsRemaining),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 48,
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isRecording ? AppColors.accentRose : AppColors.textMuted,
                  boxShadow: isRecording
                      ? [
                          BoxShadow(
                            color: AppColors.accentRose.withValues(alpha: 0.6),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isRecording ? 'LIVE MIC TELEMETRY ACTIVE' : 'MIC STANDBY',
                style: TextStyle(
                  color: isRecording ? AppColors.accentRose : AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 70,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: barHeights.map((h) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  width: 4,
                  height: isRecording ? h : 12.0,
                  decoration: BoxDecoration(
                    color: isRecording ? AppColors.accentCyan : AppColors.surfaceBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
