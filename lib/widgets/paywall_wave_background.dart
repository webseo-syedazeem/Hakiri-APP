import 'package:flutter/material.dart';

/// Silk-smooth sapphire neon waves background matching authentic Figma paywall designs
/// (media_1791307866234.png & media_1791310512072.png).
class PaywallWaveBackground extends StatelessWidget {
  const PaywallWaveBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _PaywallWavePainter(),
        ),
      ),
    );
  }
}

class _PaywallWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Deep midnight base gradient
    final basePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF020617),
          Color(0xFF030712),
          Color(0xFF00030A),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, basePaint);

    // 2. Teal-Emerald deep translucent back wave swooping from top
    final backWavePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          const Color(0xFF0E4A68).withValues(alpha: 0.40),
          const Color(0xFF07243B).withValues(alpha: 0.25),
          Colors.transparent,
        ],
        stops: const [0.0, 0.50, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.45));

    final backWavePath = Path();
    backWavePath.moveTo(size.width * 0.30, 0);
    backWavePath.cubicTo(
      size.width * 0.45, size.height * 0.12,
      size.width * 0.65, size.height * 0.22,
      size.width, size.height * 0.25,
    );
    backWavePath.lineTo(size.width, 0);
    backWavePath.close();
    canvas.drawPath(backWavePath, backWavePaint);

    // 3. Primary Luminous Sapphire Silk Ribbon
    final primaryWavePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          const Color(0xFF2563EB).withValues(alpha: 0.60),
          const Color(0xFF1D4ED8).withValues(alpha: 0.35),
          const Color(0xFF0A1E42).withValues(alpha: 0.05),
          Colors.transparent,
        ],
        stops: const [0.0, 0.40, 0.80, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.40));

    final primaryWavePath = Path();
    primaryWavePath.moveTo(size.width * 0.48, 0);
    primaryWavePath.cubicTo(
      size.width * 0.56, size.height * 0.08,
      size.width * 0.72, size.height * 0.18,
      size.width, size.height * 0.19,
    );
    primaryWavePath.lineTo(size.width, 0);
    primaryWavePath.close();
    canvas.drawPath(primaryWavePath, primaryWavePaint);

    // 4. Subtle glowing rim crest highlight along the wave crest
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..shader = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          const Color(0xFF60A5FA).withValues(alpha: 0.70),
          const Color(0xFF3B82F6).withValues(alpha: 0.30),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.35));

    final rimPath = Path();
    rimPath.moveTo(size.width * 0.48, 0);
    rimPath.cubicTo(
      size.width * 0.56, size.height * 0.08,
      size.width * 0.72, size.height * 0.18,
      size.width, size.height * 0.19,
    );
    canvas.drawPath(rimPath, rimPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
