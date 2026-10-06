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
        return Image.asset(
          'assets/images/hakkiri_paywall_master.png',
          height: size,
          fit: BoxFit.contain,
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
