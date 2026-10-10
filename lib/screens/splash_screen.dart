import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'landing_screen.dart';

/// Cinematic Splash Screen with live tech bioluminescent aurora movement
/// matching user specification and media_1791553918548_044104b3.png
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final AnimationController _ambientController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;
  Timer? _timer;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    // Entry fade & scale animation
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _scaleAnimation = Tween<double>(begin: 0.90, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeIn),
    );

    // Live continuous ambient fluid / tech aurora loop
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat();

    _entryController.forward();

    // Navigate to Onboarding after splash duration
    _timer = Timer(const Duration(milliseconds: 2800), _navigateToNext);
  }

  void _navigateToNext() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => const LandingScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _entryController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _navigateToNext,
      child: Scaffold(
        backgroundColor: const Color(0xFF000512),
        body: Stack(
          children: [
            // Live Bioluminescent Tech Background Painter
            AnimatedBuilder(
              animation: _ambientController,
              builder: (context, _) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: BioluminescentTechBackgroundPainter(
                    animationValue: _ambientController.value,
                  ),
                );
              },
            ),

            // Glowing Hakkiri Logo in Center
            Center(
              child: AnimatedBuilder(
                animation: Listenable.merge([_entryController, _ambientController]),
                builder: (context, _) {
                  final breatheScale = 1.0 + 0.02 * sin(_ambientController.value * 2 * pi);
                  return Opacity(
                    opacity: _opacityAnimation.value,
                    child: Transform.scale(
                      scale: _scaleAnimation.value * breatheScale,
                      child: Image.asset(
                        'assets/images/splash_glowing_logo_hi.png',
                        width: 215,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ultra-smooth bioluminescent tech background with elegant acoustic resonance
class BioluminescentTechBackgroundPainter extends CustomPainter {
  final double animationValue;

  BioluminescentTechBackgroundPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final t = animationValue * 2 * pi;

    // 1. Deep midnight/cyber abyss gradient base
    final rect = Offset.zero & size;
    final bgPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment(0.0, -0.08 + 0.04 * sin(t)),
        radius: 1.15,
        colors: const [
          Color(0xFF072152),
          Color(0xFF031234),
          Color(0xFF010818),
          Color(0xFF00030A),
        ],
        stops: const [0.0, 0.38, 0.78, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    // 2. Center bioluminescent core bloom (directly behind the glowing logo)
    final pulseScale = 1.0 + 0.08 * sin(t);
    final coreGlowPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.65 * pulseScale,
        colors: [
          const Color(0xFF00D2FF).withValues(alpha: 0.16 + 0.04 * cos(t)),
          const Color(0xFF3B82F6).withValues(alpha: 0.08),
          const Color(0x00010818), // Clean fade into deep space
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(rect);
    canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.62 * pulseScale, coreGlowPaint);

    // 3. Subtle concentric acoustic / orbital resonance rings
    _drawAcousticRings(canvas, size, phase: t);

    // 4. Fluid acoustic waveform ribbons (positioned below logo so mark remains pristine)
    _drawFluidAuroraRibbon(
      canvas,
      size,
      phase: t,
      amplitude: h * 0.035,
      baseY: h * 0.69,
      strokeWidth: 2.5,
      glowWidth: 14.0,
      color: const Color(0xFF38BDF8),
    );

    _drawFluidAuroraRibbon(
      canvas,
      size,
      phase: t + 2.1,
      amplitude: h * 0.045,
      baseY: h * 0.75,
      strokeWidth: 2.2,
      glowWidth: 16.0,
      color: const Color(0xFF00E5FF),
    );

    // 5. Floating bioluminescent light particles/motes
    final particlePaint = Paint()..style = PaintingStyle.fill;
    final particles = [
      (0.24, 0.34, 2.5, 0.8),
      (0.78, 0.28, 2.2, 1.4),
      (0.18, 0.62, 1.8, 2.0),
      (0.82, 0.68, 2.8, 0.5),
      (0.35, 0.76, 1.8, 1.8),
      (0.65, 0.78, 2.4, 2.7),
      (0.48, 0.22, 2.0, 0.3),
      (0.55, 0.85, 1.8, 1.1),
    ];

    for (final p in particles) {
      final px = (p.$1 * w + sin(t + p.$4) * 14) % w;
      final py = (p.$2 * h - (animationValue * h * 0.10) + cos(t * 0.7 + p.$4) * 8) % h;
      final alpha = (0.35 + 0.30 * sin(t * 1.5 + p.$4)).clamp(0.0, 1.0);
      particlePaint.color = const Color(0xFF67E8F9).withValues(alpha: alpha);
      canvas.drawCircle(Offset(px, py), p.$3, particlePaint);
    }
  }

  void _drawAcousticRings(Canvas canvas, Size size, {required double phase}) {
    final center = Offset(size.width * 0.5, size.height * 0.5);
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final rings = [
      (size.width * 0.36, 0.07 + 0.02 * sin(phase)),
      (size.width * 0.52, 0.05 + 0.02 * cos(phase)),
      (size.width * 0.70, 0.03 + 0.01 * sin(phase * 1.3)),
    ];

    for (final (radius, alpha) in rings) {
      ringPaint.color = const Color(0xFF38BDF8).withValues(alpha: alpha);
      canvas.drawCircle(center, radius, ringPaint);
    }
  }

  void _drawFluidAuroraRibbon(
    Canvas canvas,
    Size size, {
    required double phase,
    required double amplitude,
    required double baseY,
    required double strokeWidth,
    required double glowWidth,
    required Color color,
  }) {
    final path = Path();
    const points = 24;
    for (int i = 0; i <= points; i++) {
      final x = size.width * (i / points);
      final wave1 = sin(phase + (i / points) * 2 * pi) * amplitude;
      final wave2 = cos(phase * 0.7 + (i / points) * 3 * pi) * (amplitude * 0.45);
      final y = baseY + wave1 + wave2;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Outer soft glow
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = glowWidth
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawPath(path, glowPaint);

    // Inner bright core
    final corePaint = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, corePaint);
  }

  @override
  bool shouldRepaint(covariant BioluminescentTechBackgroundPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
