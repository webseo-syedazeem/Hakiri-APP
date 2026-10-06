import 'package:flutter/material.dart';

class AuthWaveformWatermark extends StatelessWidget {
  final double width;
  final double height;

  const AuthWaveformWatermark({
    super.key,
    this.width = 160,
    this.height = 140,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _SoundwaveWatermarkPainter(),
      ),
    );
  }
}

class _SoundwaveWatermarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final barCount = 10;
    final barWidth = 4.2;
    final spacing = (size.width - (barCount * barWidth)) / (barCount - 1);

    // Height profiles ramping up and tapering
    final heights = [
      0.15,
      0.28,
      0.45,
      0.65,
      0.82,
      0.95,
      0.72,
      0.55,
      0.35,
      0.20,
    ];

    for (int i = 0; i < barCount; i++) {
      final x = i * (barWidth + spacing);
      final barH = size.height * heights[i];
      final y = size.height - barH;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barH),
        const Radius.circular(3),
      );

      final paint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x303B82F6),
            Color(0x083B82F6),
          ],
        ).createShader(Rect.fromLTWH(x, y, barWidth, barH));

      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
