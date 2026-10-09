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
          filterQuality: FilterQuality.high,
        );

      case HakkiriLogoVariant.iconOnly:
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: HakkiriMarkPainter(isDark: isDark),
          ),
        );

      case HakkiriLogoVariant.paywallDarkLockup:
        return Image.asset(
          'assets/images/hakkiri_paywall_master.png',
          height: size,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
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
                painter: HakkiriMarkPainter(isDark: isDark),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Hakkiri',
              style: TextStyle(
                color: isDark ? AppColors.textInverse : const Color(0xFF13141F),
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
            filterQuality: FilterQuality.high,
          );
        }
        final textColor = isDark ? AppColors.textInverse : AppColors.textPrimary;
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: size * 1.15,
              height: size * 1.15,
              child: CustomPaint(
                painter: HakkiriMarkPainter(isDark: isDark),
              ),
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

/// Ultra-sharp vector painter for the Hakkiri circular soundwave mark
class HakkiriMarkPainter extends CustomPainter {
  final bool isDark;
  final Color? color;
  final Color? dotColor;

  const HakkiriMarkPainter({
    this.isDark = false,
    this.color,
    this.dotColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fg = color ?? (isDark ? Colors.white : const Color(0xFF13141F));
    final dot = dotColor ?? const Color(0xFFFF4838);

    final cx = size.width * 0.43;
    final cy = size.height * 0.50;
    final radius = size.width * 0.38;
    final strokeW = size.width * 0.088;

    // Smooth outer C-arc
    final arcPaint = Paint()
      ..color = fg
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    // Opening on the right: ~37 degrees above and below horizontal axis
    const startAngle = 0.64;
    const sweepAngle = 2 * pi - 1.28;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      startAngle,
      sweepAngle,
      false,
      arcPaint,
    );

    // Coral/red dot in the opening
    final dotPaint = Paint()
      ..color = dot
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final dotX = cx + radius * 0.98;
    final dotRadius = size.width * 0.098;
    canvas.drawCircle(Offset(dotX, cy), dotRadius, dotPaint);

    // 4 vertical soundwave bars
    final barPaint = Paint()
      ..color = fg
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final barW = size.width * 0.068;
    final bars = [
      (cx - size.width * 0.160, size.height * 0.23),
      (cx - size.width * 0.053, size.height * 0.46),
      (cx + size.width * 0.053, size.height * 0.35),
      (cx + size.width * 0.160, size.height * 0.23),
    ];

    for (final bar in bars) {
      final bx = bar.$1;
      final bh = bar.$2;
      final rect = Rect.fromCenter(
        center: Offset(bx, cy),
        width: barW,
        height: bh,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(barW / 2)),
        barPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant HakkiriMarkPainter oldDelegate) {
    return oldDelegate.isDark != isDark ||
        oldDelegate.color != color ||
        oldDelegate.dotColor != dotColor;
  }
}
