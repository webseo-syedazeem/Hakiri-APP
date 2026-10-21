import 'package:flutter/material.dart';

class ConnectTheDotsIcon extends StatelessWidget {
  final Color color;
  final double size;

  const ConnectTheDotsIcon({
    super.key,
    required this.color,
    this.size = 18,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ConnectTheDotsPainter(color: color),
      ),
    );
  }
}

class _ConnectTheDotsPainter extends CustomPainter {
  final Color color;

  const _ConnectTheDotsPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final nodePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final topNode = Offset(size.width * 0.5, size.height * 0.22);
    final bottomLeft = Offset(size.width * 0.22, size.height * 0.78);
    final bottomRight = Offset(size.width * 0.78, size.height * 0.78);

    // Connecting lines
    canvas.drawLine(topNode, bottomLeft, linePaint);
    canvas.drawLine(topNode, bottomRight, linePaint);

    final nodeRadius = size.width * 0.16;

    // Outer ring or solid circle with white center for modern look
    for (final node in [topNode, bottomLeft, bottomRight]) {
      canvas.drawCircle(node, nodeRadius, nodePaint);
      canvas.drawCircle(
        node,
        nodeRadius * 0.45,
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ConnectTheDotsPainter oldDelegate) =>
      oldDelegate.color != color;
}
