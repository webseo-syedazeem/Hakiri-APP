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

    // 1. Crisp base wash
    final basePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFF8FAFF),
          Color(0xFFFFFFFF),
          Color(0xFFF5F9FF),
        ],
        stops: [0.0, 0.5, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, basePaint);

    // 2. Vivid 3D Volumetric Spheres with luminous highlights matching the design screenshots
    void draw3DSphere({
      required double cx,
      required double cy,
      required double r,
      double coreOpacity = 0.60,
      double glowOpacity = 0.35,
    }) {
      final center = Offset(cx, cy);

      // A. Outer soft ambient luminous glow halo
      final glowPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF3B82F6).withValues(alpha: glowOpacity),
            const Color(0xFF60A5FA).withValues(alpha: glowOpacity * 0.5),
            Colors.transparent,
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: r * 1.35))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
      canvas.drawCircle(center, r * 1.35, glowPaint);

      // B. 3D Volumetric spherical body with off-center specular light
      final spherePaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.35),
          radius: 0.95,
          colors: [
            const Color(0xFFFFFFFF).withValues(alpha: 0.65), // Specular light reflection
            const Color(0xFF93C5FD).withValues(alpha: coreOpacity * 0.7),
            const Color(0xFF3B82F6).withValues(alpha: coreOpacity),
            const Color(0xFF1D4ED8).withValues(alpha: coreOpacity * 0.85),
            Colors.transparent,
          ],
          stops: const [0.0, 0.28, 0.65, 0.92, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: r))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(center, r, spherePaint);
    }

    // SPHERE 1: Top-Right Large Sphere (dominant right-side cluster)
    draw3DSphere(cx: w * 0.96, cy: h * 0.28, r: w * 0.28, coreOpacity: 0.70, glowOpacity: 0.45);

    // SPHERE 2: Top-Right Secondary Upper Sphere
    draw3DSphere(cx: w * 0.82, cy: h * 0.16, r: w * 0.18, coreOpacity: 0.55, glowOpacity: 0.35);

    // SPHERE 3: Mid-Right Sphere (directly behind & beside the Countdown "3" widget!)
    draw3DSphere(cx: w * 0.94, cy: h * 0.52, r: w * 0.24, coreOpacity: 0.65, glowOpacity: 0.42);

    // SPHERE 4: Lower-Right Sphere (behind right soundwave bars)
    draw3DSphere(cx: w * 0.92, cy: h * 0.68, r: w * 0.22, coreOpacity: 0.60, glowOpacity: 0.40);

    // SPHERE 5: Lower-Left Sphere (behind left soundwave bars)
    draw3DSphere(cx: w * 0.10, cy: h * 0.68, r: w * 0.22, coreOpacity: 0.55, glowOpacity: 0.38);

    // SPHERE 6: Mid-Left Sphere (peeking out behind left side of card)
    draw3DSphere(cx: w * 0.02, cy: h * 0.44, r: w * 0.18, coreOpacity: 0.50, glowOpacity: 0.32);
  }

  @override
  bool shouldRepaint(covariant _BubbleBackgroundPainter oldDelegate) => false;
}
