import 'package:flutter/material.dart';

/// Full-screen ambient background with organic curved waves and soundwave watermark.
/// Matches the authentic Figma designs for Login and Signup.
class AuthScreenBackground extends StatelessWidget {
  final bool showBottomWave;

  const AuthScreenBackground({
    super.key,
    this.showBottomWave = false,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _AuthScreenBackgroundPainter(showBottomWave: showBottomWave),
        ),
      ),
    );
  }
}

class _AuthScreenBackgroundPainter extends CustomPainter {
  final bool showBottomWave;

  const _AuthScreenBackgroundPainter({this.showBottomWave = false});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Soft organic wave shape swooping from top-right
    final topWavePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          const Color(0xFFE3EDFE).withValues(alpha: 0.65),
          const Color(0xFFF1F6FE).withValues(alpha: 0.40),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.55));

    final topWavePath = Path();
    topWavePath.moveTo(size.width * 0.28, 0);
    topWavePath.cubicTo(
      size.width * 0.24, size.height * 0.16,
      size.width * 0.52, size.height * 0.32,
      size.width, size.height * 0.38,
    );
    topWavePath.lineTo(size.width, 0);
    topWavePath.close();
    canvas.drawPath(topWavePath, topWavePaint);

    // 2. Soundwave bars positioned in top right
    final waveBoxWidth = size.width * 0.46;
    final waveBoxHeight = size.height * 0.26;
    final waveBoxLeft = size.width * 0.54;
    final waveBoxTop = size.height * 0.08;

    _drawSoundwaveBars(canvas, Rect.fromLTWH(waveBoxLeft, waveBoxTop, waveBoxWidth, waveBoxHeight));

    // 3. Optional bottom-left organic wave (prominent on Login screen)
    if (showBottomWave) {
      final bottomWavePaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [
            const Color(0xFFE8F1FE).withValues(alpha: 0.75),
            const Color(0xFFF3F7FE).withValues(alpha: 0.45),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, size.height * 0.78, size.width * 0.55, size.height * 0.22));

      final bottomPath = Path();
      bottomPath.moveTo(0, size.height * 0.84);
      bottomPath.cubicTo(
        size.width * 0.18, size.height * 0.82,
        size.width * 0.32, size.height * 0.94,
        size.width * 0.44, size.height,
      );
      bottomPath.lineTo(0, size.height);
      bottomPath.close();
      canvas.drawPath(bottomPath, bottomWavePaint);
    }
  }

  void _drawSoundwaveBars(Canvas canvas, Rect bounds) {
    // Ambient radial glow behind the bars
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.3, 0.0),
        radius: 0.85,
        colors: [
          const Color(0xFFBFD5FE).withValues(alpha: 0.42),
          const Color(0xFFBFD5FE).withValues(alpha: 0.16),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(bounds);

    canvas.drawRect(bounds, glowPaint);

    final heights = [
      0.09, // 1: tiny pill dot
      0.15, // 2: small pill
      0.24, // 3: medium-low
      0.35, // 4: medium
      0.49, // 5: medium-high
      0.33, // 6: dip
      0.73, // 7: tall
      0.50, // 8: dip
      1.00, // 9: tallest royal blue bar
      0.64, // 10: trailing tall
    ];

    final opacities = [
      0.22,
      0.30,
      0.40,
      0.52,
      0.65,
      0.58,
      0.82,
      0.72,
      1.00,
      0.78,
    ];

    final barCount = heights.length;
    final barWidth = 6.2;
    final totalBarsWidth = barCount * barWidth;
    final spacing = (bounds.width - totalBarsWidth) / (barCount - 1);
    final centerY = bounds.top + (bounds.height * 0.50);

    for (int i = 0; i < barCount; i++) {
      final x = bounds.left + i * (barWidth + spacing);
      final barH = bounds.height * heights[i];
      final y = centerY - (barH / 2);

      final barRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barH),
        Radius.circular(barWidth / 2),
      );

      final isVibrant = i >= 6;
      final topColor = isVibrant ? const Color(0xFF3B82F6) : const Color(0xFF7B9AFE);
      final bottomColor = isVibrant ? const Color(0xFF60A5FA) : const Color(0xFFBACDFE);

      final barPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            topColor.withValues(alpha: opacities[i]),
            bottomColor.withValues(alpha: opacities[i] * 0.85),
          ],
        ).createShader(Rect.fromLTWH(x, y, barWidth, barH));

      canvas.drawRRect(barRect, barPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AuthScreenBackgroundPainter oldDelegate) =>
      oldDelegate.showBottomWave != showBottomWave;
}

/// Standalone soundwave watermark widget for flexible placement
class AuthWaveformWatermark extends StatelessWidget {
  final double width;
  final double height;

  const AuthWaveformWatermark({
    super.key,
    this.width = 180,
    this.height = 210,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _StandaloneWavePainter(),
      ),
    );
  }
}

class _StandaloneWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Ambient radial glow behind the bars
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.3, 0.0),
        radius: 0.85,
        colors: [
          const Color(0xFFBFD5FE).withValues(alpha: 0.42),
          const Color(0xFFBFD5FE).withValues(alpha: 0.16),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), glowPaint);

    final heights = [
      0.09, // 1: tiny pill dot
      0.15, // 2: small pill
      0.24, // 3: medium-low
      0.35, // 4: medium
      0.49, // 5: medium-high
      0.33, // 6: dip
      0.73, // 7: tall
      0.50, // 8: dip
      1.00, // 9: tallest royal blue bar
      0.64, // 10: trailing tall
    ];

    final opacities = [
      0.22,
      0.30,
      0.40,
      0.52,
      0.65,
      0.58,
      0.82,
      0.72,
      1.00,
      0.78,
    ];

    final barCount = heights.length;
    final barWidth = 6.2;
    final totalBarsWidth = barCount * barWidth;
    final spacing = (size.width - totalBarsWidth) / (barCount - 1);
    final centerY = size.height * 0.50;

    for (int i = 0; i < barCount; i++) {
      final x = i * (barWidth + spacing);
      final barH = size.height * heights[i];
      final y = centerY - (barH / 2);

      final barRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barH),
        Radius.circular(barWidth / 2),
      );

      final isVibrant = i >= 6;
      final topColor = isVibrant ? const Color(0xFF3B82F6) : const Color(0xFF7B9AFE);
      final bottomColor = isVibrant ? const Color(0xFF60A5FA) : const Color(0xFFBACDFE);

      final barPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            topColor.withValues(alpha: opacities[i]),
            bottomColor.withValues(alpha: opacities[i] * 0.85),
          ],
        ).createShader(Rect.fromLTWH(x, y, barWidth, barH));

      canvas.drawRRect(barRect, barPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

