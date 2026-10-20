import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/services/analytics_service.dart';
import '../providers/app_state_provider.dart';
import 'assessment_screen.dart';
import 'home_screen.dart';
import 'landing_screen.dart';
import 'locked_profile_screen.dart';

/// Splash: cosmic canvas + logo, then auto-route.
/// Logged-out users land on LandingScreen (Get started).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _rayController;
  late final AnimationController _pulseController;
  Timer? _timer;
  bool _hasNavigated = false;

  late final List<_LightRayData> _rays;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenView(screenName: 'SplashScreen');

    // Continuous outward cosmic light ray streaks
    _rayController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();

    // Subtle gentle breathing pulse on the glowing brand mark
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    // Initialize deterministic high-density light rays (streaks radiating in 360°)
    _rays = _generateLightRays();

    // Auto-advance — no Get Started / Touch the light on splash.
    _timer = Timer(const Duration(milliseconds: 2800), _navigateToNext);
  }

  List<_LightRayData> _generateLightRays() {
    final rand = Random(42); // deterministic seed for consistent, beautiful layout
    final list = <_LightRayData>[];

    const colors = [
      Color(0xFFFFFFFF), // pure white core
      Color(0xFF38BDF8), // neon sky cyan
      Color(0xFF00E5FF), // electric cyan
      Color(0xFF60A5FA), // royal blue
      Color(0xFFC084FC), // light neon violet
      Color(0xFFE879F9), // electric lavender
      Color(0xFF93C5FD), // soft ice blue
    ];

    const int count = 76;
    for (int i = 0; i < count; i++) {
      // Angle spanning full 360 degrees with natural organic jitter
      final baseAngle = (i / count) * 2 * pi;
      final angle = baseAngle + (rand.nextDouble() - 0.5) * 0.12;

      final length = 60.0 + rand.nextDouble() * 190.0;
      final speed = 0.65 + rand.nextDouble() * 0.70;
      final phase = rand.nextDouble();
      final strokeWidth = 1.3 + rand.nextDouble() * 2.2;
      final color = colors[rand.nextInt(colors.length)];
      final maxReach = 0.85 + rand.nextDouble() * 0.45;

      list.add(_LightRayData(
        angle: angle,
        length: length,
        speed: speed,
        phase: phase,
        strokeWidth: strokeWidth,
        color: color,
        maxReach: maxReach,
      ));
    }
    return list;
  }

  Future<void> _navigateToNext() async {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    _timer?.cancel();

    final state = Provider.of<AppStateProvider>(context, listen: false);
    await state.restoreLocalSessionOnly();
    if (!mounted) return;

    // Sync subscription from API before routing — local session has no plan flag.
    if (state.isLoggedIn) {
      try {
        await state.refreshFromApi();
      } catch (_) {
        // Offline: fall back to last known in-memory flags.
      }
    }
    if (!mounted) return;

    final Widget next;
    if (state.isLoggedIn && state.isOnboarded && state.isSubscribed) {
      next = const HomeScreen();
    } else if (state.isLoggedIn && state.isOnboarded && !state.isSubscribed) {
      next = const LockedProfileScreen();
    } else if (state.isLoggedIn && !state.isOnboarded) {
      next = const AssessmentScreen();
    } else {
      next = const LandingScreen();
    }

    // Restore dark icons for light home / landing canvas
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 650),
        reverseTransitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => next,
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _rayController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFF000512),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF000512),
        body: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, -0.15),
                  radius: 1.15,
                  colors: [
                    Color(0xFF0044D6),
                    Color(0xFF00289E),
                    Color(0xFF001460),
                    Color(0xFF000826),
                    Color(0xFF000414),
                  ],
                  stops: [0.0, 0.32, 0.60, 0.85, 1.0],
                ),
              ),
              child: SizedBox.expand(),
            ),
            AnimatedBuilder(
              animation: _rayController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _RadiatingLightRaysPainter(
                    progress: _rayController.value,
                    rays: _rays,
                  ),
                  child: const SizedBox.expand(),
                );
              },
            ),
            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final breathe = 1.0 + 0.025 * _pulseController.value;
                      final glowAlpha = 0.85 + 0.15 * _pulseController.value;
                      return Transform.scale(
                        scale: breathe,
                        child: Opacity(opacity: glowAlpha, child: child),
                      );
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/splash_glowing_logo_hi.png',
                          width: 215,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Say what you mean. First time.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15.5,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withValues(alpha: 0.95),
                            letterSpacing: -0.2,
                            shadows: const [
                              Shadow(
                                color: Color(0x800044D6),
                                blurRadius: 16,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(flex: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Metadata model for a radiating light ray streak
class _LightRayData {
  final double angle;
  final double length;
  final double speed;
  final double phase;
  final double strokeWidth;
  final Color color;
  final double maxReach;

  const _LightRayData({
    required this.angle,
    required this.length,
    required this.speed,
    required this.phase,
    required this.strokeWidth,
    required this.color,
    required this.maxReach,
  });
}

/// Custom painter rendering dynamic 360° radiating light ray streaks bursting from center
class _RadiatingLightRaysPainter extends CustomPainter {
  final double progress;
  final List<_LightRayData> rays;

  _RadiatingLightRaysPainter({
    required this.progress,
    required this.rays,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.38);
    final maxDistance = size.longestSide * 0.78;

    // 1. Soft glowing bloom core behind the emblem
    final pulseScale = 1.0 + 0.08 * sin(progress * 2 * pi);
    final coreBloomPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [
          const Color(0xFF00E5FF).withValues(alpha: 0.28 * pulseScale),
          const Color(0xFF0052FF).withValues(alpha: 0.32),
          const Color(0xFF002288).withValues(alpha: 0.15),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 0.65, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: 190 * pulseScale));
    canvas.drawCircle(center, 190 * pulseScale, coreBloomPaint);

    // 2. Radiating light ray streaks
    final rayPaint = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);

    final angleOffset = progress * 0.18; // smooth subtle celestial rotation

    for (final ray in rays) {
      // Outward progression (0.0 to 1.0)
      final t = (ray.phase + progress * ray.speed) % 1.0;
      final innerDist = 45.0 + t * (maxDistance * ray.maxReach);
      final outerDist = innerDist + ray.length;

      // Opacity envelope: fade in near center, stay bright, fade out at periphery
      double alpha = 1.0;
      if (innerDist < 95.0) {
        alpha = (innerDist - 45.0) / 50.0;
      } else if (outerDist > maxDistance * 0.75) {
        alpha = ((maxDistance - outerDist) / (maxDistance * 0.25)).clamp(0.0, 1.0);
      }
      alpha = alpha.clamp(0.0, 1.0);

      if (alpha <= 0.01) continue;

      final currentAngle = ray.angle + angleOffset;
      final cosA = cos(currentAngle);
      final sinA = sin(currentAngle);

      final p1 = Offset(center.dx + cosA * innerDist, center.dy + sinA * innerDist);
      final p2 = Offset(center.dx + cosA * outerDist, center.dy + sinA * outerDist);

      // Soft ambient bloom streak
      glowPaint
        ..strokeWidth = ray.strokeWidth * 3.0
        ..color = ray.color.withValues(alpha: alpha * 0.28);
      canvas.drawLine(p1, p2, glowPaint);

      // Sharp luminous core streak
      rayPaint
        ..strokeWidth = ray.strokeWidth
        ..color = ray.color.withValues(alpha: alpha * 0.85);
      canvas.drawLine(p1, p2, rayPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadiatingLightRaysPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
