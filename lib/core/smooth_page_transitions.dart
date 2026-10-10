import 'package:flutter/material.dart';

/// Professional "shared-axis" (horizontal) page transition used across the app.
///
/// This mirrors Google's Material Motion spec: when a new screen is pushed, the
/// outgoing screen fades out and drifts slightly left while the incoming screen
/// slides in from the right and fades through — all on Material's "emphasized"
/// easing curve. The result feels deliberate and premium rather than abrupt.
///
/// Wired in via [ThemeData.pageTransitionsTheme], so every [MaterialPageRoute]
/// navigation gets it automatically (and it reverses cleanly on back).
class SmoothPageTransitionsBuilder extends PageTransitionsBuilder {
  const SmoothPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return _SharedAxisHorizontalTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      child: child,
    );
  }
}

class _SharedAxisHorizontalTransition extends StatelessWidget {
  const _SharedAxisHorizontalTransition({
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
  });

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  /// Material 3 "emphasized" easing — a confident, premium acceleration curve.
  static const Curve _emphasized = Cubic(0.2, 0.0, 0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    // ── Incoming screen (driven by this route's own animation) ──────────────
    // Slides in from the right and fades through in the latter 70%.
    final Animation<Offset> enterSlide = Tween<Offset>(
      begin: const Offset(0.14, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: _emphasized,
      reverseCurve: _emphasized.flipped,
    ));

    final Animation<double> enterFade = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.30, 1.0, curve: Curves.easeOut),
      reverseCurve: const Interval(0.0, 0.70, curve: Curves.easeIn),
    );

    // ── Outgoing screen (driven by the next route covering this one) ─────────
    // Drifts left and fades out early so the stack reads as layered depth.
    final Animation<Offset> exitSlide = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.10, 0.0),
    ).animate(CurvedAnimation(
      parent: secondaryAnimation,
      curve: _emphasized,
      reverseCurve: _emphasized.flipped,
    ));

    final Animation<double> exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: secondaryAnimation,
        curve: const Interval(0.0, 0.45, curve: Curves.easeIn),
        reverseCurve: const Interval(0.55, 1.0, curve: Curves.easeOut),
      ),
    );

    return SlideTransition(
      position: exitSlide,
      child: FadeTransition(
        opacity: exitFade,
        child: SlideTransition(
          position: enterSlide,
          child: FadeTransition(
            opacity: enterFade,
            child: child,
          ),
        ),
      ),
    );
  }
}
