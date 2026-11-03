import 'package:flutter/material.dart';

class AppColors {
  // Clean, crisp, modern canvas (no yellowish / ivory tint)
  static const Color background = Color(0xFFF8FAFC);
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color surfaceBorder = Color(0xFFE2E8F0);
  static const Color surfaceBorderLight = Color(0xFFF1F5F9);

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
  static const Color chartMuted = Color(0xFFE2E8F0);

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
  static const Color metricTrack = Color(0xFFE2E8F0);
}

/// Single source of truth for all activity icon visuals & colors across Hakiri.
class ActivityVisual {
  final IconData icon;
  final Color color;
  final Color bgColor;

  const ActivityVisual({
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  static ActivityVisual forSlug(String slug) {
    switch (slug) {
      case 'think_fast':
        return const ActivityVisual(
          icon: Icons.bolt_rounded,
          color: Color(0xFF2563EB),
          bgColor: Color(0xFFEFF6FF),
        );
      case 'debate_me':
      case 'debate':
        return const ActivityVisual(
          icon: Icons.chat_bubble_rounded,
          color: Color(0xFFF59E0B),
          bgColor: Color(0xFFFFFBEB),
        );
      case 'connect_the_dots':
        return const ActivityVisual(
          icon: Icons.hub_rounded,
          color: Color(0xFF9333EA),
          bgColor: Color(0xFFF5F3FF),
        );
      case 'cut_it_in_half':
        return const ActivityVisual(
          icon: Icons.content_cut_rounded,
          color: Color(0xFFD97706),
          bgColor: Color(0xFFFFFBEB),
        );
      case 'one_minute_expert':
        return const ActivityVisual(
          icon: Icons.timer_rounded,
          color: Color(0xFFEA580C),
          bgColor: Color(0xFFFFF1EC),
        );
      case 'storytelling_gym':
        return const ActivityVisual(
          icon: Icons.auto_stories_rounded,
          color: Color(0xFF8B5CF6),
          bgColor: Color(0xFFF5F3FF),
        );
      case 'explain_it_simply':
        return const ActivityVisual(
          icon: Icons.lightbulb_rounded,
          color: Color(0xFF10B981),
          bgColor: Color(0xFFECFDF5),
        );
      default:
        return const ActivityVisual(
          icon: Icons.bolt_rounded,
          color: Color(0xFF2563EB),
          bgColor: Color(0xFFEFF6FF),
        );
    }
  }
}
