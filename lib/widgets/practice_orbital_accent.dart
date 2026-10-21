import 'package:flutter/material.dart';

class PracticeOrbitalAccent extends StatelessWidget {
  final double topOffset;
  final double rightOffset;

  const PracticeOrbitalAccent({
    super.key,
    this.topOffset = 0,
    this.rightOffset = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: topOffset,
      right: rightOffset,
      width: 220,
      height: 180,
      child: IgnorePointer(
        child: CustomPaint(
          painter: _PracticeOrbitalPainter(),
        ),
      ),
    );
  }
}

class _PracticeOrbitalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Center of curvature off-screen to the top right
    final center = Offset(size.width * 0.95, -15);

    // 1. Broad soft ambient outer arc band
    final ambientBandPaint = Paint()
      ..color = const Color(0xFF3B82F6).withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, 135, ambientBandPaint);

    // 2. Crisp medium arc line
    final outerArcPaint = Paint()
      ..color = const Color(0xFF60A5FA).withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(center, 120, outerArcPaint);

    // 3. Inner faint arc line
    final innerArcPaint = Paint()
      ..color = const Color(0xFF2563EB).withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, 85, innerArcPaint);

    // 4. Distinct Royal Blue Accent Dot sitting clearly on the outer arc
    // Positioned at an angle around 210 degrees from center
    // This places it around x = 85, y = 62 in this 220x180 box
    final dotCenter = Offset(size.width * 0.38, size.height * 0.38);

    // Soft subtle glow
    final glowPaint = Paint()
      ..color = const Color(0xFF2563EB).withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(dotCenter, 8.0, glowPaint);

    // Solid Royal Blue Dot
    final dotPaint = Paint()
      ..color = const Color(0xFF2563EB)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(dotCenter, 5.0, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
