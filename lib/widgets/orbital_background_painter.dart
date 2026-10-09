import 'package:flutter/material.dart';

class OrbitalBackgroundPainter extends CustomPainter {
  final Color color;

  const OrbitalBackgroundPainter({
    this.color = const Color(0xFF3446EB),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    final path = Path();
    // Arc curving across top right
    path.moveTo(size.width * 0.45, 0);
    path.quadraticBezierTo(
      size.width * 0.70,
      size.height * 0.35,
      size.width * 1.05,
      size.height * 0.55,
    );
    canvas.drawPath(path, paintLine);

    // Glowing orbital dot near end of arc
    final dotPaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width * 0.82, size.height * 0.28),
      6,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ProgressWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Soft gradient wave
    final wavePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF3446EB).withValues(alpha: 0.15),
          const Color(0xFF9EA7FA).withValues(alpha: 0.05),
          Colors.transparent,
        ],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.6);
    path.quadraticBezierTo(
      size.width * 0.35,
      size.height * 0.2,
      size.width * 0.7,
      size.height * 0.45,
    );
    path.quadraticBezierTo(
      size.width * 0.85,
      size.height * 0.55,
      size.width,
      size.height * 0.1,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, wavePaint);

    // Upward trend arrow line
    final linePaint = Paint()
      ..color = const Color(0xFF3446EB).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final linePath = Path();
    linePath.moveTo(size.width * 0.55, size.height * 0.6);
    linePath.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.5,
      size.width * 0.95,
      size.height * 0.15,
    );
    canvas.drawPath(linePath, linePaint);

    // Arrow tip
    final arrowPath = Path();
    final tipX = size.width * 0.95;
    final tipY = size.height * 0.15;
    arrowPath.moveTo(tipX - 10, tipY + 1);
    arrowPath.lineTo(tipX, tipY);
    arrowPath.lineTo(tipX - 1, tipY + 10);
    canvas.drawPath(arrowPath, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
