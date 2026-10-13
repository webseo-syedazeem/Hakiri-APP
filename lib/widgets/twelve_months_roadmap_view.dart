import 'package:flutter/material.dart';

/// Ultra-crisp native vector roadmap graphic for "Twelve months, one step at a time."
/// Replaces low-resolution blurry PNG with 100% razor-sharp native typography and vector graphics.
class TwelveMonthsRoadmapView extends StatelessWidget {
  const TwelveMonthsRoadmapView({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final cardWidth = (availableWidth * 0.76).clamp(240.0, 290.0);

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
                      tag: 'MONTH 1-2',
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
                      tag: 'MONTH 3-4',
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
                      tag: 'MONTH 5-8',
                      title: 'Persuade.',
                      subtitle: 'Make it a natural part.',
                      iconWidget: _buildSpeechIcon(),
                      isIconOnRight: true,
                    ),
                  ),

                  // MILESTONE 4 (Aligned Left)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _buildMilestoneCard(
                      width: cardWidth,
                      tag: 'MONTH 9-10',
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
                      tag: 'MONTH 11-12',
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          if (!isIconOnRight) ...[
            iconWidget,
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tag,
                  style: const TextStyle(
                    color: Color(0xFF2563EB),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(
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

  // 1. Target Bullseye Icon
  Widget _buildTargetIcon() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.track_changes_rounded, color: Color(0xFF2563EB), size: 20),
    );
  }

  // 2. Structure Icon
  Widget _buildStructureIcon() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.format_list_bulleted_rounded, color: Color(0xFF2563EB), size: 18),
    );
  }

  // 3. Speech Bubble Icon
  Widget _buildSpeechIcon() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF2563EB), size: 18),
    );
  }

  // 4. Mountain Summit Icon
  Widget _buildMountainIcon() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.flag_rounded, color: Color(0xFF2563EB), size: 18),
    );
  }

  // 5. Bar Chart Icon
  Widget _buildBarChartIcon() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.bar_chart_rounded, color: Color(0xFF2563EB), size: 20),
    );
  }
}

/// Custom Canvas Painter that draws the continuous smooth winding S-curve and numbered milestone badges
class _TwelveMonthsCurvePainter extends CustomPainter {
  final double availableWidth;

  const _TwelveMonthsCurvePainter({required this.availableWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final leftX = (w * 0.10).clamp(24.0, 36.0);
    final rightX = (w * 0.90).clamp(w - 36.0, w - 24.0);

    final y1 = h * 0.08;
    final y2 = h * 0.28;
    final y3 = h * 0.50;
    final y4 = h * 0.72;
    final y5 = h * 0.92;

    // 1. Continuous Winding S-Curve Path
    final path = Path();
    path.moveTo(leftX, y1);

    // Curve 1 -> 2 (Left to Right)
    path.cubicTo(leftX, y1 + (y2 - y1) * 0.6, rightX, y1 + (y2 - y1) * 0.4, rightX, y2);

    // Curve 2 -> 3 (Right to Left)
    path.cubicTo(rightX, y2 + (y3 - y2) * 0.6, leftX, y2 + (y3 - y2) * 0.4, leftX, y3);

    // Curve 3 -> 4 (Left to Right)
    path.cubicTo(leftX, y3 + (y4 - y3) * 0.6, rightX, y3 + (y4 - y3) * 0.4, rightX, y4);

    // Curve 4 -> 5 (Right to Left)
    path.cubicTo(rightX, y4 + (y5 - y4) * 0.6, leftX, y4 + (y5 - y4) * 0.4, leftX, y5);

    // Road Stroke
    final roadPaint = Paint()
      ..color = const Color(0xFF3B82F6).withValues(alpha: 0.7)
      ..strokeWidth = 2.2
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
    // Outer Glow / Ring
    final ringPaint = Paint()
      ..color = const Color(0xFF3B82F6).withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 17, ringPaint);

    // Solid Inner Circle
    final circlePaint = Paint()
      ..color = const Color(0xFF2563EB)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 12, circlePaint);

    // Number text
    final textPainter = TextPainter(
      text: TextSpan(
        text: number,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
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
