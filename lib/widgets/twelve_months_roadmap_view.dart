import 'package:flutter/material.dart';

/// Ultra-crisp native vector roadmap graphic for "Twelve months, one step at a time."
/// Matching Image 4 pixel-perfect with continuous winding S-curve and milestone cards.
class TwelveMonthsRoadmapView extends StatelessWidget {
  const TwelveMonthsRoadmapView({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final cardWidth = (availableWidth * 0.77).clamp(240.0, 300.0);

        return Stack(
          alignment: Alignment.center,
          children: [
            // 1. Smooth Continuous Winding S-Curve Path Behind Cards
            Positioned.fill(
              child: CustomPaint(
                painter: _TwelveMonthsCurvePainter(availableWidth: availableWidth),
              ),
            ),

            // 2. The 5 Connected Milestone Cards
            SizedBox(
              width: double.infinity,
              height: 440,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // MILESTONE 1 (Aligned Right)
                  Align(
                    alignment: Alignment.centerRight,
                    child: _buildMilestoneCard(
                      width: cardWidth,
                      tag: 'MONTH 1–2',
                      title: 'Build the habit.',
                      subtitle: 'Learn the basics to daily.',
                      iconWidget: _buildTargetIcon(),
                      isIconOnRight: true,
                    ),
                  ),

                  // MILESTONE 2 (Aligned Left)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _buildMilestoneCard(
                      width: cardWidth,
                      tag: 'MONTH 3–4',
                      title: 'Add structure.',
                      subtitle: 'Get a routine that fits you.',
                      iconWidget: _buildStructureIcon(),
                      isIconOnRight: false,
                    ),
                  ),

                  // MILESTONE 3 (Aligned Right)
                  Align(
                    alignment: Alignment.centerRight,
                    child: _buildMilestoneCard(
                      width: cardWidth,
                      tag: 'MONTH 5–8',
                      title: 'Persuade.',
                      subtitle: 'Make it a natural part.',
                      iconWidget: _buildSpeechIcon(),
                      isIconOnRight: false,
                    ),
                  ),

                  // MILESTONE 4 (Aligned Left)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _buildMilestoneCard(
                      width: cardWidth,
                      tag: 'MONTH 9–10',
                      title: 'Practice under pressure.',
                      subtitle: 'Turn it into second nature.',
                      iconWidget: _buildMountainIcon(),
                      isIconOnRight: false,
                    ),
                  ),

                  // MILESTONE 5 (Aligned Right)
                  Align(
                    alignment: Alignment.centerRight,
                    child: _buildMilestoneCard(
                      width: cardWidth,
                      tag: 'MONTH 11–12',
                      title: 'Find your own style.',
                      subtitle: 'Mix exercises with real-world purpose and progress.',
                      iconWidget: _buildBarChartIcon(),
                      isIconOnRight: false,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMilestoneCard({
    required double width,
    required String tag,
    required String title,
    required String subtitle,
    required Widget iconWidget,
    required bool isIconOnRight,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0).withValues(alpha: 0.8), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (!isIconOnRight) ...[
            iconWidget,
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tag,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF2563EB),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF0F172A),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF64748B),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          if (isIconOnRight) ...[
            const SizedBox(width: 10),
            iconWidget,
          ],
        ],
      ),
    );
  }

  // 1. Target Bullseye Icon matching Image 4
  Widget _buildTargetIcon() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: SizedBox(
        width: 30,
        height: 30,
        child: CustomPaint(
          painter: _BullseyeArrowPainter(),
        ),
      ),
    );
  }

  // 2. Structure Icon matching Image 4
  Widget _buildStructureIcon() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 18, height: 3, decoration: BoxDecoration(color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 3),
          Container(width: 18, height: 3, decoration: BoxDecoration(color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 3),
          Container(width: 18, height: 3, decoration: BoxDecoration(color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(2))),
        ],
      ),
    );
  }

  // 3. Speech Bubble Icon with 3 white dots matching Image 4
  Widget _buildSpeechIcon() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(Icons.chat_bubble_rounded, color: Color(0xFF2563EB), size: 24),
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 2.5, height: 2.5, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                const SizedBox(width: 2),
                Container(width: 2.5, height: 2.5, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                const SizedBox(width: 2),
                Container(width: 2.5, height: 2.5, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 4. Mountain Summit Icon with Flag matching Image 4
  Widget _buildMountainIcon() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: SizedBox(
        width: 30,
        height: 24,
        child: CustomPaint(
          painter: _MountainFlagPainter(),
        ),
      ),
    );
  }

  // 5. Bar Chart Icon with 3 vertical bars matching Image 4
  Widget _buildBarChartIcon() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(width: 4.5, height: 10, decoration: BoxDecoration(color: const Color(0xFF93C5FD), borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 3),
          Container(width: 4.5, height: 16, decoration: BoxDecoration(color: const Color(0xFF60A5FA), borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 3),
          Container(width: 4.5, height: 22, decoration: BoxDecoration(color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(2))),
        ],
      ),
    );
  }
}

class _BullseyeArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.45, size.height * 0.52);
    final ringPaint = Paint()
      ..color = const Color(0xFF2563EB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawCircle(center, 9, ringPaint);
    canvas.drawCircle(center, 5, ringPaint..strokeWidth = 2.0);
    canvas.drawCircle(center, 2, Paint()..color = const Color(0xFF2563EB));

    // Arrow hitting target
    final arrowPaint = Paint()
      ..color = const Color(0xFF2563EB)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(size.width * 0.85, size.height * 0.15), center, arrowPaint);
    // Arrow head
    final headPath = Path();
    headPath.moveTo(size.width * 0.85, size.height * 0.15);
    headPath.lineTo(size.width * 0.72, size.height * 0.14);
    headPath.moveTo(size.width * 0.85, size.height * 0.15);
    headPath.lineTo(size.width * 0.86, size.height * 0.28);
    canvas.drawPath(headPath, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MountainFlagPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Mountain path
    final mPath = Path();
    mPath.moveTo(2, size.height);
    mPath.lineTo(size.width * 0.55, 6);
    mPath.lineTo(size.width * 0.85, size.height);
    mPath.close();

    final mPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF93C5FD), Color(0xFF60A5FA)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(mPath, mPaint);

    // Front smaller mountain
    final sPath = Path();
    sPath.moveTo(size.width * 0.4, size.height);
    sPath.lineTo(size.width * 0.75, 12);
    sPath.lineTo(size.width - 2, size.height);
    sPath.close();
    canvas.drawPath(sPath, Paint()..color = const Color(0xFF3B82F6).withValues(alpha: 0.8));

    // Flagpole
    final pole = Paint()
      ..color = const Color(0xFF1D4ED8)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(size.width * 0.55, 6), Offset(size.width * 0.55, 0), pole);

    // Flag
    final flagPath = Path();
    flagPath.moveTo(size.width * 0.55, 0);
    flagPath.lineTo(size.width * 0.42, 3);
    flagPath.lineTo(size.width * 0.55, 6);
    flagPath.close();
    canvas.drawPath(flagPath, Paint()..color = const Color(0xFF2563EB));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom Canvas Painter that draws the continuous smooth winding S-curve and numbered milestone badges
class _TwelveMonthsCurvePainter extends CustomPainter {
  final double availableWidth;

  const _TwelveMonthsCurvePainter({required this.availableWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final leftX = (w * 0.08).clamp(18.0, 28.0);
    final rightX = (w * 0.92).clamp(w - 28.0, w - 18.0);

    final y1 = h * 0.07;
    final y2 = h * 0.28;
    final y3 = h * 0.50;
    final y4 = h * 0.72;
    final y5 = h * 0.93;

    // 1. Continuous Winding S-Curve Path
    final path = Path();
    path.moveTo(leftX, y1);

    // Curve 1 -> 2 (Left to Right)
    path.cubicTo(leftX, y1 + (y2 - y1) * 0.65, rightX, y1 + (y2 - y1) * 0.35, rightX, y2);

    // Curve 2 -> 3 (Right to Left)
    path.cubicTo(rightX, y2 + (y3 - y2) * 0.65, leftX, y2 + (y3 - y2) * 0.35, leftX, y3);

    // Curve 3 -> 4 (Left to Right)
    path.cubicTo(leftX, y3 + (y4 - y3) * 0.65, rightX, y3 + (y4 - y3) * 0.35, rightX, y4);

    // Curve 4 -> 5 (Right to Left)
    path.cubicTo(rightX, y4 + (y5 - y4) * 0.65, leftX, y4 + (y5 - y4) * 0.35, leftX, y5);

    // Road Stroke
    final roadPaint = Paint()
      ..color = const Color(0xFF2563EB)
      ..strokeWidth = 2.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, roadPaint);

    // 2. Draw Numbered Milestone Badges (1, 2, 3, 4, 5)
    _drawMilestoneBadge(canvas, Offset(leftX, y1), '1');
    _drawMilestoneBadge(canvas, Offset(rightX, y2), '2');
    _drawMilestoneBadge(canvas, Offset(leftX, y3), '3');
    _drawMilestoneBadge(canvas, Offset(rightX, y4), '4');
    _drawMilestoneBadge(canvas, Offset(leftX, y5), '5');
  }

  void _drawMilestoneBadge(Canvas canvas, Offset center, String number) {
    // Solid Inner Circle
    final circlePaint = Paint()
      ..color = const Color(0xFF2563EB)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 13, circlePaint);

    // Number text
    final textPainter = TextPainter(
      text: TextSpan(
        text: number,
        style: const TextStyle(
          fontFamily: 'Inter',
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
