import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Clean, high-resolution vector illustration for empty debate & drill history.
class EmptyHistoryWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? buttonText;
  final VoidCallback? onButtonPressed;

  const EmptyHistoryWidget({
    super.key,
    this.title = 'No Debate History Yet',
    this.subtitle =
        'You haven\'t completed any debate drills yet. Start a 60-second challenge above to test your cognitive agility under fire.',
    this.buttonText = 'Start Debate Drill',
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceBorder, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // SVG / Vector Custom Painter Illustration
          const CustomEmptyStateSvg(size: 110),
          const SizedBox(height: 18),

          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),

          // Subtitle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w400,
                height: 1.45,
              ),
            ),
          ),

          if (buttonText != null && onButtonPressed != null) ...[
            const SizedBox(height: 18),
            GestureDetector(
              onTap: onButtonPressed,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF141522),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      buttonText!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Custom Canvas-rendered vector graphic representing empty speech/debate history
class CustomEmptyStateSvg extends StatelessWidget {
  final double size;

  const CustomEmptyStateSvg({super.key, this.size = 110});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _EmptyStatePainter(),
      ),
    );
  }
}

class _EmptyStatePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // 1. Soft Outer Ambient Circle
    final outerGlowPaint = Paint()
      ..color = const Color(0xFF2563EB).withValues(alpha: 0.07)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, size.width * 0.46, outerGlowPaint);

    // 2. Middle Ring
    final middleRingPaint = Paint()
      ..color = const Color(0xFF2563EB).withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, size.width * 0.36, middleRingPaint);

    // 3. Primary Speech Bubble Background
    final bubbleRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx - 6, center.dy - 6),
        width: size.width * 0.52,
        height: size.height * 0.44,
      ),
      const Radius.circular(14),
    );

    final bubblePaint = Paint()
      ..color = const Color(0xFF141522)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(bubbleRect, bubblePaint);

    // Speech bubble tail
    final tailPath = Path()
      ..moveTo(center.dx - 18, center.dy + size.height * 0.14)
      ..lineTo(center.dx - 28, center.dy + size.height * 0.24)
      ..lineTo(center.dx - 8, center.dy + size.height * 0.16)
      ..close();
    canvas.drawPath(tailPath, bubblePaint);

    // 4. Waveform / Debate lines inside main bubble
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.5;

    // Line 1
    canvas.drawLine(
      Offset(center.dx - 22, center.dy - 12),
      Offset(center.dx + 10, center.dy - 12),
      linePaint,
    );
    // Line 2 (shorter)
    canvas.drawLine(
      Offset(center.dx - 22, center.dy - 4),
      Offset(center.dx + 2, center.dy - 4),
      linePaint,
    );

    // 5. Clock / History Overlay Badge on bottom right
    final clockCenter = Offset(center.dx + size.width * 0.22, center.dy + size.height * 0.16);
    final clockRadius = size.width * 0.18;

    // Clock background
    final clockBgPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(clockCenter, clockRadius, clockBgPaint);

    final clockBorderPaint = Paint()
      ..color = const Color(0xFF2563EB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;
    canvas.drawCircle(clockCenter, clockRadius, clockBorderPaint);

    // Clock Hands (representing time / history)
    final clockHandsPaint = Paint()
      ..color = const Color(0xFF2563EB)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.0;

    // Center pivot
    canvas.drawCircle(clockCenter, 1.8, clockHandsPaint);
    // Hour hand (pointing up)
    canvas.drawLine(
      clockCenter,
      Offset(clockCenter.dx, clockCenter.dy - clockRadius * 0.52),
      clockHandsPaint,
    );
    // Minute hand (pointing right)
    canvas.drawLine(
      clockCenter,
      Offset(clockCenter.dx + clockRadius * 0.45, clockCenter.dy),
      clockHandsPaint,
    );

    // 6. Sparkle accents (Top Right & Left)
    final sparklePaint = Paint()
      ..color = const Color(0xFF2563EB)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.8;

    // Top right sparkle
    _drawSparkle(canvas, Offset(center.dx + size.width * 0.32, center.dy - size.height * 0.28), 6, sparklePaint);

    // Small left accent dot
    final dotPaint = Paint()
      ..color = const Color(0xFF6366F1).withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(center.dx - size.width * 0.36, center.dy - size.height * 0.1), 3.0, dotPaint);
  }

  void _drawSparkle(Canvas canvas, Offset p, double r, Paint paint) {
    canvas.drawLine(Offset(p.dx - r, p.dy), Offset(p.dx + r, p.dy), paint);
    canvas.drawLine(Offset(p.dx, p.dy - r), Offset(p.dx, p.dy + r), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
