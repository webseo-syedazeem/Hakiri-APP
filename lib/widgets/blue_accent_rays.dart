import 'package:flutter/material.dart';

/// Playful royal-blue radiating accent rays seen in the Hakkiri design system.
class BlueAccentRays extends StatelessWidget {
  final double size;
  final Color color;

  const BlueAccentRays({
    super.key,
    this.size = 22,
    this.color = const Color(0xFF2563EB),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BlueAccentRaysPainter(color: color),
      ),
    );
  }
}

class _BlueAccentRaysPainter extends CustomPainter {
  final Color color;

  const _BlueAccentRaysPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.16
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Ray 1: Left / upper diagonal accent dash (~50 deg tilt)
    canvas.drawLine(
      Offset(size.width * 0.28, size.height * 0.62),
      Offset(size.width * 0.48, size.height * 0.14),
      paint,
    );

    // Ray 2: Right / lower diagonal accent dash (~50 deg tilt)
    canvas.drawLine(
      Offset(size.width * 0.62, size.height * 0.88),
      Offset(size.width * 0.88, size.height * 0.42),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
