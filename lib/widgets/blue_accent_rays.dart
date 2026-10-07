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
      ..strokeWidth = size.width * 0.13
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Ray 1: Top-most / vertical-leaning ray (~70 deg)
    canvas.drawLine(
      Offset(size.width * 0.16, size.height * 0.52),
      Offset(size.width * 0.28, size.height * 0.08),
      paint,
    );

    // Ray 2: Middle ray (~45 deg)
    canvas.drawLine(
      Offset(size.width * 0.38, size.height * 0.68),
      Offset(size.width * 0.76, size.height * 0.30),
      paint,
    );

    // Ray 3: Right-most / horizontal-leaning ray (~20 deg)
    canvas.drawLine(
      Offset(size.width * 0.48, size.height * 0.88),
      Offset(size.width * 0.96, size.height * 0.66),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
