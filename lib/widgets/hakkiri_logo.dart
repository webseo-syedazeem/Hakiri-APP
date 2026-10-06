import 'dart:math';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

enum HakkiriLogoVariant {
  fullImage,
  compactMark,
  iconOnly,
  paywallDarkLockup,
  headerPlanLockup,
  watermarkJapanese,
}

class HakkiriLogo extends StatelessWidget {
  final HakkiriLogoVariant variant;
  final double size;
  final bool isDark;
  final String? brandText;

  const HakkiriLogo({
    super.key,
    this.variant = HakkiriLogoVariant.compactMark,
    this.size = 24.0,
    this.isDark = false,
    this.brandText,
  });

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case HakkiriLogoVariant.fullImage:
        return Image.asset(
          isDark ? 'assets/images/hakkiri_logo_dark.png' : 'assets/images/hakkiri_logo_master.png',
          height: size,
          fit: BoxFit.contain,
        );

      case HakkiriLogoVariant.iconOnly:
        return Image.asset(
          isDark ? 'assets/images/hakkiri_icon_dark.png' : 'assets/images/hakkiri_mark_master.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
        );

      case HakkiriLogoVariant.paywallDarkLockup:
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: size * 1.25,
              height: size * 1.25,
              child: CustomPaint(
                painter: _PaywallLogoPainter(),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Hakkiri',
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.95,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
          ],
        );

      case HakkiriLogoVariant.headerPlanLockup:
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: size * 1.15,
              height: size * 1.15,
              child: CustomPaint(
                painter: _PlanLogoPainter(),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'hakkiri',
              style: TextStyle(
                color: const Color(0xFF13141F),
                fontSize: size * 0.95,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
          ],
        );

      case HakkiriLogoVariant.compactMark:
        if (brandText == null || brandText == 'Hakkiri' || brandText == 'hakkiri') {
          return Image.asset(
            isDark
                ? 'assets/images/hakkiri_horizontal_dark.png'
                : 'assets/images/hakkiri_horizontal_lockup.png',
            height: size,
            fit: BoxFit.contain,
          );
        }
        final textColor = isDark ? AppColors.textInverse : AppColors.textPrimary;
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              isDark ? 'assets/images/hakkiri_icon_dark.png' : 'assets/images/hakkiri_mark_master.png',
              width: size * 1.15,
              height: size * 1.15,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            Text(
              brandText!,
              style: TextStyle(
                color: textColor,
                fontSize: size * 0.95,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
          ],
        );

      case HakkiriLogoVariant.watermarkJapanese:
        return Text(
          'はっきり',
          style: TextStyle(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.045),
            fontSize: size,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
          ),
        );
    }
  }
}

class _PaywallLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.44, size.height * 0.5);
    final radius = size.width * 0.40;

    // Metallic silver/white gradient open circular ring
    final ringPaint = Paint()
      ..shader = const SweepGradient(
        startAngle: 0.0,
        endAngle: 2 * pi,
        colors: [
          Colors.white,
          Color(0xFFE2E8F0),
          Color(0xFF94A3B8),
          Colors.white,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.12
      ..strokeCap = StrokeCap.round;

    // Draw arc leaving gap on the right
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0.35,
      2 * pi - 0.7,
      false,
      ringPaint,
    );

    // 5 vertical soundwave bars inside the ring
    final barPaint = Paint()
      ..color = const Color(0xFF88A6FE)
      ..style = PaintingStyle.fill;

    final barWidth = size.width * 0.065;
    final barSpacing = size.width * 0.035;
    final heights = [0.26, 0.48, 0.76, 0.52, 0.28];
    final startX = center.dx - (5 * barWidth + 4 * barSpacing) / 2;

    for (int i = 0; i < 5; i++) {
      final x = startX + i * (barWidth + barSpacing);
      final h = radius * 2 * heights[i];
      final y = center.dy - h / 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, h),
          Radius.circular(barWidth / 2),
        ),
        barPaint,
      );
    }

    // Coral red dot in the right opening
    final dotPaint = Paint()
      ..color = const Color(0xFFFF443A)
      ..style = PaintingStyle.fill;

    final dotCenter = Offset(center.dx + radius * 0.98, center.dy);
    canvas.drawCircle(dotCenter, size.width * 0.11, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PlanLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.44, size.height * 0.5);
    final radius = size.width * 0.40;

    // Dark ring
    final ringPaint = Paint()
      ..color = const Color(0xFF13141F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.13
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0.35,
      2 * pi - 0.7,
      false,
      ringPaint,
    );

    // Center dark solid circle
    final centerPaint = Paint()
      ..color = const Color(0xFF13141F)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.38, centerPaint);

    // Blue accent dot in the opening
    final blueDotPaint = Paint()
      ..color = const Color(0xFF3446EB)
      ..style = PaintingStyle.fill;
    final dotCenter = Offset(center.dx + radius * 0.98, center.dy);
    canvas.drawCircle(dotCenter, size.width * 0.10, blueDotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
