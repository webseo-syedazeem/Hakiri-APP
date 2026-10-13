import 'dart:math';
import 'package:flutter/material.dart';

/// Polished, 3D-glassmorphic illustrations for the onboarding activity
/// carousel, approximating the design-doc artwork in pure code (blue volume
/// gradients, soft ground shadows and specular highlights).
class ExerciseIllustration extends StatelessWidget {
  final String type;
  final double size;

  const ExerciseIllustration({super.key, required this.type, this.size = 150});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 0.82,
      child: CustomPaint(painter: _painterFor(type)),
    );
  }

  CustomPainter _painterFor(String type) {
    switch (type) {
      case 'connect_dots':
        return _MoleculePainter();
      case 'explain':
        return _LightbulbPainter();
      case 'cut_it_in_half':
        return _CutInHalfPainter();
      case 'storytelling':
        return _StoryPathPainter();
      case 'debate':
        return _DebatePainter();
      case 'stopwatch':
      case 'think_fast':
      default:
        return _StopwatchPainter();
    }
  }
}

// ── shared helpers ───────────────────────────────────────────────────────────

const _blueLight = Color(0xFF93C5FD);
const _blueMid = Color(0xFF3B82F6);
const _blueDeep = Color(0xFF1D4ED8);
const _bluePale = Color(0xFFDBEAFE);

void _groundShadow(Canvas c, Offset center, double w, double h) {
  final p = Paint()
    ..color = const Color(0xFF2563EB).withValues(alpha: 0.18)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
  c.drawOval(Rect.fromCenter(center: center, width: w, height: h), p);
}

Paint _volume(Rect r) => Paint()
  ..shader = const LinearGradient(
    begin: Alignment(-0.6, -0.7),
    end: Alignment(0.6, 0.8),
    colors: [_blueLight, _blueMid, _blueDeep],
    stops: [0.0, 0.5, 1.0],
  ).createShader(r);

void _highlight(Canvas c, Offset at, double r) {
  c.drawCircle(at, r, Paint()..color = Colors.white.withValues(alpha: 0.5));
}

// ── stopwatch (Think Fast / One Minute Expert) ───────────────────────────────

class _StopwatchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final center = Offset(w * 0.56, h * 0.56);
    final radius = h * 0.34;

    _groundShadow(canvas, Offset(center.dx, h * 0.92), radius * 1.9, radius * 0.5);

    // Motion lines (left).
    final line = Paint()
      ..color = _blueLight.withValues(alpha: 0.9)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4;
    for (int i = 0; i < 3; i++) {
      final y = center.dy - radius * 0.4 + i * radius * 0.5;
      final len = radius * (1.1 - i * 0.22);
      canvas.drawLine(
        Offset(center.dx - radius * 1.25 - len, y),
        Offset(center.dx - radius * 1.2, y),
        line,
      );
    }

    // Top button + ears.
    final btn = Paint()..color = _blueDeep;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx, center.dy - radius - 7), width: 12, height: 12),
        const Radius.circular(3),
      ),
      btn,
    );

    // Body.
    final bodyRect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(center, radius, _volume(bodyRect));
    // Rim.
    canvas.drawCircle(
      center, radius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    // Inner face.
    canvas.drawCircle(center, radius * 0.72, Paint()..color = const Color(0xFFEFF6FF));
    canvas.drawCircle(
      center, radius * 0.72,
      Paint()
        ..color = _blueMid.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    // Hands.
    final hand = Paint()
      ..color = _blueDeep
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3;
    canvas.drawLine(center, center + Offset(0, -radius * 0.5), hand);
    canvas.drawLine(center, center + Offset(radius * 0.34, radius * 0.12), hand);
    canvas.drawCircle(center, 3.2, Paint()..color = _blueDeep);

    _highlight(canvas, center + Offset(-radius * 0.38, -radius * 0.42), radius * 0.18);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── molecule (Connect the Dots) ──────────────────────────────────────────────

class _MoleculePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    _groundShadow(canvas, Offset(w * 0.5, h * 0.93), w * 0.6, h * 0.14);

    final nodes = [
      Offset(w * 0.24, h * 0.70),
      Offset(w * 0.54, h * 0.30),
      Offset(w * 0.80, h * 0.64),
    ];
    const radii = [18.0, 24.0, 15.0];

    final link = Paint()
      ..color = _blueLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(nodes[0], nodes[1], link);
    canvas.drawLine(nodes[1], nodes[2], link);

    for (int i = 0; i < nodes.length; i++) {
      final r = radii[i];
      canvas.drawCircle(nodes[i], r, _volume(Rect.fromCircle(center: nodes[i], radius: r)));
      _highlight(canvas, nodes[i].translate(-r * 0.35, -r * 0.4), r * 0.26);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── lightbulb (Explain It Simply) ────────────────────────────────────────────

class _LightbulbPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final bulb = Offset(w * 0.48, h * 0.46);
    final r = h * 0.3;

    _groundShadow(canvas, Offset(bulb.dx, h * 0.93), r * 1.8, r * 0.45);

    // Glow.
    canvas.drawCircle(
      bulb, r * 1.5,
      Paint()
        ..shader = RadialGradient(
          colors: [const Color(0xFFBFDBFE).withValues(alpha: 0.6), const Color(0x00BFDBFE)],
        ).createShader(Rect.fromCircle(center: bulb, radius: r * 1.5)),
    );

    // Base.
    final base = Paint()..color = _blueDeep;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(bulb.dx, bulb.dy + r * 1.05), width: r * 0.8, height: r * 0.55),
        const Radius.circular(4),
      ),
      base,
    );

    // Bulb.
    canvas.drawCircle(bulb, r, _volume(Rect.fromCircle(center: bulb, radius: r)));
    canvas.drawCircle(bulb, r * 0.6, Paint()..color = Colors.white.withValues(alpha: 0.35));
    _highlight(canvas, bulb.translate(-r * 0.35, -r * 0.4), r * 0.2);

    // Chat accent (top-right).
    final chat = Offset(w * 0.82, h * 0.22);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: chat, width: w * 0.22, height: h * 0.18),
        const Radius.circular(8),
      ),
      Paint()..color = _bluePale,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── cut in half (Cut It in Half) ─────────────────────────────────────────────

class _CutInHalfPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    _groundShadow(canvas, Offset(w * 0.5, h * 0.93), w * 0.7, h * 0.14);

    void doc(Rect r, Color color, int lines) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(r.translate(1.5, 3), const Radius.circular(8)),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.08)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(8)), Paint()..color = color);
      final lp = Paint()
        ..color = (color == _blueMid ? Colors.white : _blueLight)
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 2.5;
      for (int i = 0; i < lines; i++) {
        final y = r.top + r.height * 0.26 + i * (r.height * 0.52 / max(1, lines - 1));
        canvas.drawLine(Offset(r.left + 8, y), Offset(r.right - 8, y), lp);
      }
    }

    // Long doc (light) -> short doc (blue).
    doc(Rect.fromLTWH(w * 0.05, h * 0.2, w * 0.34, h * 0.62), const Color(0xFFEFF4FF), 4);
    doc(Rect.fromLTWH(w * 0.62, h * 0.34, w * 0.32, h * 0.34), _blueMid, 2);

    // Arrow.
    final arrow = Paint()
      ..color = _blueDeep
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    final ay = h * 0.5;
    canvas.drawLine(Offset(w * 0.44, ay), Offset(w * 0.57, ay), arrow);
    canvas.drawLine(Offset(w * 0.57, ay), Offset(w * 0.52, ay - 6), arrow);
    canvas.drawLine(Offset(w * 0.57, ay), Offset(w * 0.52, ay + 6), arrow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── story path (Storytelling Gym) ────────────────────────────────────────────

class _StoryPathPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    _groundShadow(canvas, Offset(w * 0.5, h * 0.93), w * 0.7, h * 0.14);

    // Winding path.
    final path = Path()
      ..moveTo(w * 0.1, h * 0.78)
      ..cubicTo(w * 0.35, h * 0.9, w * 0.4, h * 0.45, w * 0.62, h * 0.5)
      ..cubicTo(w * 0.8, h * 0.54, w * 0.82, h * 0.2, w * 0.95, h * 0.2);
    canvas.drawPath(
      path,
      Paint()
        ..color = _blueLight
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );

    void card(Offset at, Color color) {
      final r = Rect.fromCenter(center: at, width: w * 0.26, height: h * 0.3);
      canvas.drawRRect(
        RRect.fromRectAndRadius(r.translate(1.5, 3), const Radius.circular(7)),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.08)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(7)),
          color == _blueMid ? _volume(r) : (Paint()..color = color));
      final lp = Paint()
        ..color = (color == _blueMid ? Colors.white : _blueLight)
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 2;
      canvas.drawLine(r.topLeft + Offset(7, r.height * 0.4),
          r.topLeft + Offset(r.width - 7, r.height * 0.4), lp);
      canvas.drawLine(r.topLeft + Offset(7, r.height * 0.62),
          r.topLeft + Offset(r.width * 0.6, r.height * 0.62), lp);
    }

    card(Offset(w * 0.18, h * 0.66), const Color(0xFFEFF4FF));
    card(Offset(w * 0.5, h * 0.44), _blueMid);
    card(Offset(w * 0.82, h * 0.26), const Color(0xFFEFF4FF));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── debate (Debate Me) ───────────────────────────────────────────────────────

class _DebatePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    _groundShadow(canvas, Offset(w * 0.5, h * 0.92), w * 0.66, h * 0.14);

    // Light bubble (back).
    final back = Rect.fromLTWH(w * 0.42, h * 0.3, w * 0.5, h * 0.4);
    canvas.drawRRect(RRect.fromRectAndRadius(back, const Radius.circular(16)),
        Paint()..color = _bluePale);
    final backTail = Path()
      ..moveTo(back.right - 22, back.bottom - 2)
      ..lineTo(back.right - 6, back.bottom + 14)
      ..lineTo(back.right - 6, back.bottom - 2)
      ..close();
    canvas.drawPath(backTail, Paint()..color = _bluePale);
    // dots
    for (int i = 0; i < 3; i++) {
      canvas.drawCircle(Offset(back.center.dx - 12 + i * 12, back.center.dy), 3.2,
          Paint()..color = _blueMid);
    }

    // Blue bubble (front) with lightning.
    final front = Rect.fromLTWH(w * 0.08, h * 0.18, w * 0.5, h * 0.42);
    canvas.drawRRect(
      RRect.fromRectAndRadius(front.translate(1.5, 3), const Radius.circular(16)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawRRect(RRect.fromRectAndRadius(front, const Radius.circular(16)), _volume(front));
    final frontTail = Path()
      ..moveTo(front.left + 22, front.bottom - 2)
      ..lineTo(front.left + 6, front.bottom + 14)
      ..lineTo(front.left + 6, front.bottom - 2)
      ..close();
    canvas.drawPath(frontTail, Paint()..color = _blueDeep);
    // lightning
    final bolt = Path()
      ..moveTo(front.center.dx + 2, front.center.dy - 13)
      ..lineTo(front.center.dx - 8, front.center.dy + 2)
      ..lineTo(front.center.dx, front.center.dy + 2)
      ..lineTo(front.center.dx - 2, front.center.dy + 14)
      ..lineTo(front.center.dx + 9, front.center.dy - 3)
      ..lineTo(front.center.dx + 1, front.center.dy - 3)
      ..close();
    canvas.drawPath(bolt, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
