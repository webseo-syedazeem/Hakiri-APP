import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

enum HakkiriLogoVariant {
  fullImage,
  compactMark,
  watermarkJapanese,
}

class HakkiriLogo extends StatelessWidget {
  final HakkiriLogoVariant variant;
  final double size;
  final bool isDark;

  const HakkiriLogo({
    super.key,
    this.variant = HakkiriLogoVariant.compactMark,
    this.size = 24.0,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case HakkiriLogoVariant.fullImage:
        return Image.asset(
          'assets/images/hakkiri_logo.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => _buildVectorEnso(),
        );

      case HakkiriLogoVariant.compactMark:
        final textColor = isDark ? AppColors.textInverse : AppColors.textPrimary;
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CustomPaint(
              size: Size(size * 0.9, size * 0.9),
              painter: _HakkiriIconPainter(isDark: isDark),
            ),
            const SizedBox(width: 8),
            Text(
              'hakkiri',
              style: TextStyle(
                color: textColor,
                fontSize: size * 0.85,
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

  Widget _buildVectorEnso() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: Size(size * 0.6, size * 0.6),
          painter: _HakkiriIconPainter(isDark: isDark),
        ),
        const SizedBox(height: 8),
        Text(
          'Hakkiri',
          style: TextStyle(
            color: isDark ? AppColors.textInverse : AppColors.textPrimary,
            fontSize: size * 0.22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// Custom painter for the Hakkiri minimalist icon mark
class _HakkiriIconPainter extends CustomPainter {
  final bool isDark;

  _HakkiriIconPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final strokeColor = isDark ? Colors.white : const Color(0xFF13141F);
    final paintStroke = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final paintDot = Paint()
      ..color = AppColors.coralRed
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // Corner viewfinder / bracket mark as seen in the app header:
    // Top-left bracket
    final path = Path()
      ..moveTo(w * 0.1, h * 0.45)
      ..lineTo(w * 0.1, h * 0.15)
      ..lineTo(w * 0.45, h * 0.15);

    // Bottom-right bracket
    path.moveTo(w * 0.9, h * 0.55);
    path.lineTo(w * 0.9, h * 0.85);
    path.lineTo(w * 0.55, h * 0.85);

    canvas.drawPath(path, paintStroke);

    // Center recording / sound wave dot
    canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.14, paintDot);
  }

  @override
  bool shouldRepaint(covariant _HakkiriIconPainter oldDelegate) => oldDelegate.isDark != isDark;
}
