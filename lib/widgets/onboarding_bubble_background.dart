import 'package:flutter/material.dart';

/// Soft blue "bubble" ambient background used behind the onboarding flow, to
/// match the design spec where every screen floats over gentle, blurred
/// light-blue orbs on a near-white canvas (instead of flat white).
class OnboardingBubbleBackground extends StatelessWidget {
  const OnboardingBubbleBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _BubbleBackgroundPainter(),
        ),
      ),
    );
  }
}

class _BubbleBackgroundPainter extends CustomPainter {
  const _BubbleBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Base wash — a whisper of blue over white so cards still read crisply.
    final basePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFF7FAFF),
          Color(0xFFFFFFFF),
          Color(0xFFF4F8FF),
        ],
        stops: [0.0, 0.5, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, basePaint);

    // 2. Soft blurred orbs. Each is a radial gradient fading to transparent so
    // there are no hard edges — they read as out-of-focus light.
    void orb(double cx, double cy, double r, Color color) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [color, color.withValues(alpha: 0.0)],
          stops: const [0.0, 1.0],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
      canvas.drawCircle(Offset(cx, cy), r, paint);
    }

    const blue = Color(0xFFBFD4FF);
    const paleBlue = Color(0xFFDCE8FF);

    // Top-right cluster (the largest, most prominent in the spec).
    orb(w * 1.02, h * 0.14, w * 0.42, blue.withValues(alpha: 0.55));
    orb(w * 0.82, h * 0.05, w * 0.22, paleBlue.withValues(alpha: 0.65));

    // Left / mid-left softness.
    orb(w * -0.08, h * 0.42, w * 0.34, paleBlue.withValues(alpha: 0.5));
    orb(w * 0.10, h * 0.66, w * 0.24, blue.withValues(alpha: 0.32));

    // Lower-right anchor.
    orb(w * 0.95, h * 0.82, w * 0.40, paleBlue.withValues(alpha: 0.55));
    orb(w * 0.70, h * 0.95, w * 0.26, blue.withValues(alpha: 0.30));

    // A couple of small floating accents.
    orb(w * 0.20, h * 0.10, w * 0.10, paleBlue.withValues(alpha: 0.5));
    orb(w * 0.55, h * 0.50, w * 0.14, paleBlue.withValues(alpha: 0.28));
  }

  @override
  bool shouldRepaint(covariant _BubbleBackgroundPainter oldDelegate) => false;
}
