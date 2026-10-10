import 'package:flutter/material.dart';

class AppColors {
  // Editorial warm ivory canvas (as seen in screenshots)
  static const Color background = Color(0xFFF4F3ED);
  static const Color backgroundLight = Color(0xFFFAF9F5);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color surfaceBorder = Color(0xFFE2E0D5);
  static const Color surfaceBorderLight = Color(0xFFEAE8DE);

  // Dark High-Contrast Canvas (used on Recording screen, Paywall, and Dark Cards)
  static const Color darkBackground = Color(0xFF10111A);
  static const Color darkSurface = Color(0xFF161724);
  static const Color darkSurfaceCard = Color(0xFF1A1C2B);
  static const Color darkBorder = Color(0xFF26283D);

  // Brand Accents — unified to the #2563EB family used across onboarding & the
  // reference design, so every screen shares one brand blue.
  static const Color royalBlue = Color(0xFF2563EB);
  static const Color royalBlueLight = Color(0xFF3B82F6);
  static const Color royalBlueSoft = Color(0xFFEFF6FF);
  static const Color coralRed = Color(0xFFFF443A);
  static const Color coralBadge = Color(0xFFE55745);

  // Chart & Metric Tints
  static const Color chartLavender = Color(0xFF9EA7FA);
  static const Color chartBlue = Color(0xFF2563EB);
  static const Color chartMuted = Color(0xFFE4E2D8);

  // Text Colors
  static const Color textPrimary = Color(0xFF10121E);
  static const Color textSecondary = Color(0xFF5A5D6E);
  static const Color textMuted = Color(0xFF8E91A0);
  static const Color textInverse = Color(0xFFFFFFFF);
  static const Color textInverseMuted = Color(0xFFA0A3B5);

  // Legacy mappings for backwards-compatibility
  static const Color accentCyan = royalBlue;
  static const Color accentBlue = royalBlue;
  static const Color accentEmerald = Color(0xFF10B981);
  static const Color accentRose = coralRed;
  static const Color accentPurple = chartLavender;
  static const Color accentAmber = Color(0xFFF59E0B);
  static const Color surface = surfaceWhite;
  static const Color metricTrack = Color(0xFFECEAE2);
}
