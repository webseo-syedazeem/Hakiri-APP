import 'dart:math';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class ConfidenceGaugeWidget extends StatelessWidget {
  // 'not_at_all', 'slightly', 'fairly', 'confident', 'very'
  // ('not_very' kept for backwards compatibility).
  final String level;

  const ConfidenceGaugeWidget({
    super.key,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    double targetAngle;
    switch (level) {
      case 'not_at_all':
      case 'not_very':
        targetAngle = -0.55 * pi; // far left — lowest
        break;
      case 'slightly':
        targetAngle = -0.35 * pi;
        break;
      case 'confident':
        targetAngle = 0.10 * pi;
        break;
      case 'very':
        targetAngle = 0.35 * pi; // far right — highest
        break;
      case 'fairly':
      default:
        targetAngle = -0.15 * pi; // centre
        break;
    }

    return SizedBox(
      width: 200,
      height: 100,
      child: CustomPaint(
        painter: _GaugePainter(angle: targetAngle),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double angle;

  _GaugePainter({required this.angle});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 4);
    final radius = size.width * 0.42;

    // Track arc
    final trackPaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9.0
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi,
      pi,
      false,
      trackPaint,
    );

    // Active progress arc (lavender / royal blue tint)
    final activePaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFC7D2FE),
          AppColors.royalBlue,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9.0
      ..strokeCap = StrokeCap.round;

    final sweep = ((angle + pi) / pi).clamp(0.15, 0.95) * pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi,
      sweep,
      false,
      activePaint,
    );

    // Tick marks at intervals (4 tick notches)
    final tickPaint = Paint()
      ..color = const Color(0xFFD1D5DB)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i <= 4; i++) {
      final tickAngle = pi + (i * pi / 4);
      final p1 = Offset(
        center.dx + (radius + 8) * cos(tickAngle),
        center.dy + (radius + 8) * sin(tickAngle),
      );
      final p2 = Offset(
        center.dx + (radius + 14) * cos(tickAngle),
        center.dy + (radius + 14) * sin(tickAngle),
      );
      canvas.drawLine(p1, p2, tickPaint);
    }

    // Dial needle
    final needlePaint = Paint()
      ..color = const Color(0xFF13141F)
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    final needleLength = radius * 0.72;
    // Angle in standard math: 0 is right, -pi/2 is up
    final needleEnd = Offset(
      center.dx + needleLength * cos(angle - pi / 2),
      center.dy + needleLength * sin(angle - pi / 2),
    );

    canvas.drawLine(center, needleEnd, needlePaint);

    // Center pivot circle
    final pivotPaint = Paint()
      ..color = const Color(0xFF13141F)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 5.5, pivotPaint);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) => oldDelegate.angle != angle;
}
