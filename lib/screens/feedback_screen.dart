import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import 'home_screen.dart';
import 'recording_screen.dart';

/// Comprehensive, high-fidelity Activity Feedback Screen
/// Exactly matching client design specification (reference-images/img_4.png).
class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final feedback = state.latestFeedback;

    final overallScore = feedback != null
        ? feedback.overallScore.toDouble().toStringAsFixed(1)
        : '3.7';

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBF9),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar (< back, centered THINK FIRST)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.chevron_left_rounded,
                      color: Color(0xFF0F172A),
                      size: 28,
                    ),
                  ),
                  const Text(
                    'THINK FIRST',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: Color(0xFF0F172A),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.6,
                    ),
                  ),
                  const SizedBox(width: 28), // balance chevron
                ],
              ),
            ),

            // Horizontal Progress Bar
            Container(
              height: 3,
              width: double.infinity,
              color: const Color(0xFF2563EB),
            ),

            // Scrollable Feedback Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overall Score Header
                    _buildOverallScoreSection(overallScore),
                    const SizedBox(height: 20),

                    // 3 Metric Cards (Content, Structure, Fluency)
                    _buildMetricsRow(),
                    const SizedBox(height: 16),

                    // WHAT WORKED WELL Card (Green)
                    _buildWhatWorkedWellCard(),
                    const SizedBox(height: 16),

                    // SUGGESTED ANSWER Card (Dark Card with Audio Preview)
                    _buildSuggestedAnswerCard(),
                    const SizedBox(height: 16),

                    // KEY POINTS TO IMPROVE Card
                    _buildKeyPointsToImproveCard(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Bottom Buttons (Try again | Next ->)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  // Try again Button
                  Expanded(
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: const Color(0xFFCBD5E1),
                          width: 1.2,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(28),
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RecordingScreen(),
                              ),
                            );
                          },
                          child: const Center(
                            child: Text(
                              'Try again',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                color: Color(0xFF0F172A),
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Next -> Button
                  Expanded(
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(28),
                          onTap: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const HomeScreen(),
                              ),
                              (route) => false,
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const SizedBox(width: 32),
                                const Text(
                                  'Next',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF2563EB),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.white,
                                    size: 17,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Overall Score Row (Circle Score Ring + Headline)
  Widget _buildOverallScoreSection(String overallScore) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Circular Score Ring
        SizedBox(
          width: 96,
          height: 96,
          child: CustomPaint(
            painter: _ScoreRingPainter(
              scoreFraction: 3.7 / 5.0,
              trackColor: const Color(0xFFDBEAFE),
              activeColor: const Color(0xFF2563EB),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    overallScore,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      letterSpacing: -1.0,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'OUT OF 5',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 18),

        // Copy Column
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pill: GOOD EFFORT
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'GOOD EFFORT',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF4F46E5),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // Title: Clear answer. Tidy up the fillers.
              const Text(
                'Clear answer.\nTidy up the fillers.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.6,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 4),

              // Subtitle
              const Text(
                'Here\'s how you did and how to improve.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 3 Metrics Row (Content, Structure, Fluency)
  Widget _buildMetricsRow() {
    return Row(
      children: [
        // Content
        Expanded(
          child: _buildMetricCard(
            icon: Icons.bolt_rounded,
            iconColor: const Color(0xFF2563EB),
            ringColor: const Color(0xFF2563EB),
            scoreFraction: 4.0 / 5.0,
            title: 'Content',
            score: '4/5',
            desc: 'Clear structure and relevant examples.',
          ),
        ),
        const SizedBox(width: 10),

        // Structure
        Expanded(
          child: _buildMetricCard(
            icon: Icons.assignment_outlined,
            iconColor: const Color(0xFF059669),
            ringColor: const Color(0xFF059669),
            scoreFraction: 4.0 / 5.0,
            title: 'Structure',
            score: '4/5',
            desc: 'Well organised and easy to follow.',
          ),
        ),
        const SizedBox(width: 10),

        // Fluency
        Expanded(
          child: _buildMetricCard(
            icon: Icons.pause_circle_outline_rounded,
            iconColor: const Color(0xFFDC2626),
            ringColor: const Color(0xFFDC2626),
            scoreFraction: 3.0 / 5.0,
            title: 'Fluency',
            score: '3/5',
            desc: 'Some filler words and hesitations.',
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required Color ringColor,
    required double scoreFraction,
    required String title,
    required String score,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
      ),
      child: Column(
        children: [
          // Circular Mini Ring with Icon inside
          SizedBox(
            width: 44,
            height: 44,
            child: CustomPaint(
              painter: _ScoreRingPainter(
                scoreFraction: scoreFraction,
                trackColor: ringColor.withValues(alpha: 0.2),
                activeColor: ringColor,
                strokeWidth: 4.5,
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Title
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),

          // Score
          Text(
            score,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),

          // Description
          Text(
            desc,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  /// WHAT WORKED WELL Card
  Widget _buildWhatWorkedWellCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFA7F3D0), width: 1.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Green Checkmark Icon Circle
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: Color(0xFFD1FAE5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Color(0xFF059669),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),

          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'WHAT WORKED WELL',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: Color(0xFF047857),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'You demonstrated a clear and practical approach to handling a difficult stakeholder.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF065F46),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// SUGGESTED ANSWER Card (Dark Box with Audio Preview & Peach Pill Keywords)
  Widget _buildSuggestedAnswerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SUGGESTED ANSWER',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: Color(0xFF818CF8),
            ),
          ),
          const SizedBox(height: 8),

          const Text(
            'You said a great start. Here\'s a more refined version you can aim for:',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFFE2E8F0),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),

          // Audio Player Preview Container
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Play Button
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2563EB),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),

                // Transcript with Highlighted Pills
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'I would start by ',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12.5,
                          color: Color(0xFFCBD5E1),
                        ),
                      ),
                      _buildPeachHighlightPill('listening'),
                      const Text(
                        ' to understand their concerns, ',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12.5,
                          color: Color(0xFFCBD5E1),
                        ),
                      ),
                      _buildPeachHighlightPill('acknowledge'),
                      const Text(
                        ' their perspective...',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12.5,
                          color: Color(0xFFCBD5E1),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeachHighlightPill(String text) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEDD5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFFC2410C),
        ),
      ),
    );
  }

  /// KEY POINTS TO IMPROVE Card
  Widget _buildKeyPointsToImproveCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'KEY POINTS TO IMPROVE',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 14),

          // Point 1: FILLERS
          _buildImprovementRow(
            tag: 'FILLERS',
            tagBg: const Color(0xFFFFEDD5),
            tagTextColor: const Color(0xFFC2410C),
            text: 'Reduce words like “um”, “so” and “I mean”.',
          ),
          const SizedBox(height: 12),

          // Point 2: STRUCTURE
          _buildImprovementRow(
            tag: 'STRUCTURE',
            tagBg: const Color(0xFFEDE9FE),
            tagTextColor: const Color(0xFF6D28D9),
            text: 'Open with a clear approach, then give a specific example.',
          ),
          const SizedBox(height: 12),

          // Point 3: FLUENCY
          _buildImprovementRow(
            tag: 'FLUENCY',
            tagBg: const Color(0xFFDCFCE7),
            tagTextColor: const Color(0xFF15803D),
            text: 'Try to keep a steady pace and avoid long pauses.',
          ),
        ],
      ),
    );
  }

  Widget _buildImprovementRow({
    required String tag,
    required Color tagBg,
    required Color tagTextColor,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 72,
          padding: const EdgeInsets.symmetric(vertical: 3),
          decoration: BoxDecoration(
            color: tagBg,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            tag,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: tagTextColor,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF334155),
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

/// Circular Score Ring Painter
class _ScoreRingPainter extends CustomPainter {
  final double scoreFraction;
  final Color trackColor;
  final Color activeColor;
  final double strokeWidth;

  _ScoreRingPainter({
    required this.scoreFraction,
    required this.trackColor,
    required this.activeColor,
    this.strokeWidth = 8.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - (strokeWidth / 2);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * scoreFraction.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreRingPainter oldDelegate) =>
      oldDelegate.scoreFraction != scoreFraction ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.activeColor != activeColor ||
      oldDelegate.strokeWidth != strokeWidth;
}
