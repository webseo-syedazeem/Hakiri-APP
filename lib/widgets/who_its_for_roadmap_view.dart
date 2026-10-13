import 'package:flutter/material.dart';

/// Ultra-crisp native vector roadmap graphic for "Built for meetings, interviews and everyday conversations."
/// Replaces low-resolution blurry bitmaps with 100% razor-sharp native typography and vector shapes.
class WhoItsForRoadmapView extends StatelessWidget {
  const WhoItsForRoadmapView({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final cardWidth = (availableWidth * 0.76).clamp(240.0, 290.0);

        return Stack(
          alignment: Alignment.center,
          children: [
            // 1. Ambient soft background fluid blobs
            Positioned.fill(
              child: CustomPaint(
                painter: _RoadmapAmbientBlobsPainter(),
              ),
            ),

            // 2. Continuous connecting S-curve path behind cards
            Positioned.fill(
              child: CustomPaint(
                painter: _RoadmapConnectingCurvePainter(),
              ),
            ),

            // 3. Audio waveform badge 1 (between Card 1 & Card 2)
            Positioned(
              top: 88,
              right: availableWidth * 0.16,
              child: _buildAudioPillBadge(),
            ),

            // 4. Audio waveform badge 2 (between Card 2 & Card 3)
            Positioned(
              top: 182,
              left: availableWidth * 0.14,
              child: _buildAudioPillBadge(),
            ),

            // 5. The 3 Connected Cards
            SizedBox(
              width: double.infinity,
              height: 330,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // CARD 01: Meetings
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _buildRoadmapCard(
                      width: cardWidth,
                      stepNumber: '01',
                      title: 'Meetings',
                      subtitle: 'Capture key points and\naction items.',
                      illustration: _buildMeetingsIllustration(),
                    ),
                  ),

                  // CARD 02: Interviews (Shifted right)
                  Align(
                    alignment: Alignment.centerRight,
                    child: _buildRoadmapCard(
                      width: cardWidth,
                      stepNumber: '02',
                      title: 'Interviews',
                      subtitle: 'Answer with clarity and\nstructure.',
                      illustration: _buildInterviewsIllustration(),
                    ),
                  ),

                  // CARD 03: Everyday conversations
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _buildRoadmapCard(
                      width: cardWidth,
                      stepNumber: '03',
                      title: 'Everyday conversations',
                      subtitle: 'Stay in clearly.\nSet tone.\nFeel sure.',
                      illustration: _buildEverydayIllustration(),
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

  Widget _buildRoadmapCard({
    required double width,
    required String stepNumber,
    required String title,
    required String subtitle,
    required Widget illustration,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  stepNumber,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF93C5FD),
                    height: 1.0,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Right Illustration
          illustration,
        ],
      ),
    );
  }

  /// Illustration 01: Bullet points mini-card + People badge
  Widget _buildMeetingsIllustration() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 72,
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F6FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFDBEAFE), width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildBulletRow(),
              const SizedBox(height: 5),
              _buildBulletRow(),
              const SizedBox(height: 5),
              _buildBulletRow(),
            ],
          ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: const Color(0xFFBFDBFE), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.people_alt_rounded,
              color: Color(0xFF2563EB),
              size: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBulletRow() {
    return Row(
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: const BoxDecoration(
            color: Color(0xFF2563EB),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFBFDBFE),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ],
    );
  }

  /// Illustration 02: Horizontal accent card + Briefcase badge
  Widget _buildInterviewsIllustration() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 72,
          height: 60,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F6FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFDBEAFE), width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              const SizedBox(height: 5),
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFBFDBFE),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 28,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: const Color(0xFFBFDBFE), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.business_center_rounded,
              color: Color(0xFF2563EB),
              size: 13,
            ),
          ),
        ),
      ],
    );
  }

  /// Illustration 03: Speech bubble + waveform bars + Chat badge
  Widget _buildEverydayIllustration() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 72,
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F6FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFDBEAFE), width: 1),
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildMiniBar(8),
                const SizedBox(width: 3),
                _buildMiniBar(16),
                const SizedBox(width: 3),
                _buildMiniBar(24, isPrimary: true),
                const SizedBox(width: 3),
                _buildMiniBar(16),
                const SizedBox(width: 3),
                _buildMiniBar(8),
              ],
            ),
          ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: const Color(0xFFBFDBFE), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: Color(0xFF2563EB),
              size: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniBar(double height, {bool isPrimary = false}) {
    return Container(
      width: 3.5,
      height: height,
      decoration: BoxDecoration(
        color: isPrimary ? const Color(0xFF2563EB) : const Color(0xFF60A5FA),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  /// Round floating soundwave badge along the connector line
  Widget _buildAudioPillBadge() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.14),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildMiniBar(8, isPrimary: true),
            const SizedBox(width: 2.5),
            _buildMiniBar(16, isPrimary: true),
            const SizedBox(width: 2.5),
            _buildMiniBar(8, isPrimary: true),
          ],
        ),
      ),
    );
  }
}

/// S-Curve connecting path between the three cards
class _RoadmapConnectingCurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF3B82F6)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    // Start at right edge of Card 1
    final startX = size.width * 0.58;
    final startY = size.height * 0.18;

    // Loop through Badge 1 down to Card 2
    final midX1 = size.width * 0.88;
    final midY1 = size.height * 0.32;

    final card2X = size.width * 0.40;
    final card2Y = size.height * 0.58;

    path.moveTo(startX, startY);
    path.cubicTo(
      midX1, startY,
      midX1, midY1,
      size.width * 0.82, size.height * 0.42,
    );

    // From Card 2 loop down to Card 3 via Badge 2
    final midX2 = size.width * 0.15;
    final midY2 = size.height * 0.68;

    final endX = size.width * 0.42;
    final endY = size.height * 0.86;

    path.cubicTo(
      card2X, card2Y,
      midX2, midY2,
      endX, endY,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Subtle fluid ambient blobs in the background
class _RoadmapAmbientBlobsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final blobPaint1 = Paint()
      ..color = const Color(0xFFE8F1FE).withValues(alpha: 0.55);

    final blobPaint2 = Paint()
      ..color = const Color(0xFFF0F6FE).withValues(alpha: 0.45);

    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.20), 70, blobPaint1);
    canvas.drawCircle(Offset(size.width * 0.10, size.height * 0.65), 65, blobPaint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
