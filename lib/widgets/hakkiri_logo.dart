import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

enum HakkiriLogoVariant {
  fullImage,
  compactMark,
  iconOnly,
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
          isDark ? 'assets/images/hakkiri_logo_dark.png' : 'assets/images/hakkiri_logo.png',
          width: size,
          fit: BoxFit.contain,
        );

      case HakkiriLogoVariant.iconOnly:
        return Image.asset(
          isDark ? 'assets/images/hakkiri_icon_dark.png' : 'assets/images/hakkiri_icon.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
        );

      case HakkiriLogoVariant.compactMark:
        final textColor = isDark ? AppColors.textInverse : AppColors.textPrimary;
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              isDark ? 'assets/images/hakkiri_icon_dark.png' : 'assets/images/hakkiri_icon.png',
              width: size * 1.15,
              height: size * 1.15,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            Text(
              brandText ?? 'hakkiri',
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
