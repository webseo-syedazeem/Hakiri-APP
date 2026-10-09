import 'package:flutter/material.dart';

class CustomSparkline extends StatelessWidget {
  final List<double> values;
  final Color color;
  final double strokeWidth;
  final double height;
  final bool isDotted;
  final bool showDots;

  const CustomSparkline({
    super.key,
    required this.values,
    required this.color,
    this.strokeWidth = 2.0,
    this.height = 24.0,
    this.isDotted = false,
    this.showDots = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _SparklinePainter(
          values: values,
          color: color,
          strokeWidth: strokeWidth,
          isDotted: isDotted,
          showDots: showDots,
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;
  final double strokeWidth;
  final bool isDotted;
  final bool showDots;

  _SparklinePainter({
    required this.values,
    required this.color,
    required this.strokeWidth,
    required this.isDotted,
    required this.showDots,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final minVal = values.reduce((a, b) => a < b ? a : b);
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final range = (maxVal - minVal) == 0 ? 1.0 : (maxVal - minVal);

    final points = <Offset>[];
    for (int i = 0; i < values.length; i++) {
      final x = (size.width / (values.length - 1)) * i;
      final normalized = (values[i] - minVal) / range;
      // Invert Y so highest value is at top
      final y = size.height - (normalized * (size.height - strokeWidth * 2)) - strokeWidth;
      points.add(Offset(x, y));
    }

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlX = (p0.dx + p1.dx) / 2;
      path.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
    }

    canvas.drawPath(path, paint);

    if (showDots) {
      final dotPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      final dotBorderPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      for (int i = 0; i < points.length; i++) {
        if (i == 0 || i == points.length - 1 || i % 2 == 1) {
          canvas.drawCircle(points[i], 3.5, dotPaint);
          canvas.drawCircle(points[i], 3.5, dotBorderPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
