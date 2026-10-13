import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/services/analytics_service.dart';
import '../models/session_model.dart';
import '../providers/app_state_provider.dart';
import 'home_screen.dart';
import 'recording_screen.dart';

/// Comprehensive, high-fidelity Activity Feedback Screen
/// Exactly matching client design specification (doc_images/img_4.png).
class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService.instance.logScreenView(screenName: 'FeedbackScreen');
    });

    final state = Provider.of<AppStateProvider>(context);
    final feedback = state.latestFeedback;
    final overallValue = (feedback?.overallScore ?? 0).toDouble();
    final overallScore = feedback != null
        ? overallValue.toStringAsFixed(1)
        : '--';
    final activityTitle =
        (state.selectedActivity?.name ?? 'SESSION').toUpperCase();

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
                  Text(
                    activityTitle,
                    style: const TextStyle(
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
                    if (feedback == null)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 20),
                        child: Text(
                          'No scored session yet. Finish a drill to see real feedback here.',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    // Overall Score Header
                    _buildOverallScoreSection(
                      overallScore: overallScore,
                      overallValue: overallValue,
                      feedback: feedback,
                    ),
                    const SizedBox(height: 20),

                    // 3 Metric Cards (Content, Structure, Fluency)
                    _buildMetricsRow(feedback),
                    const SizedBox(height: 16),

                    // WHAT WORKED WELL Card (Green)
                    _buildWhatWorkedWellCard(feedback),
                    const SizedBox(height: 16),

                    // SUGGESTED ANSWER Card (Dark Card with Audio Preview)
                    _buildSuggestedAnswerCard(feedback),
                    const SizedBox(height: 16),

                    // KEY POINTS TO IMPROVE Card
                    _buildKeyPointsToImproveCard(feedback),
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

  String _effortLabel(int score) {
    if (score >= 5) return 'EXCELLENT';
    if (score >= 4) return 'STRONG';
    if (score >= 3) return 'GOOD EFFORT';
    if (score >= 2) return 'WEAK';
    if (score >= 1) return 'RETRY';
    return 'NO SCORE YET';
  }

  String _headlineFor(EvaluationFeedback? feedback) {
    if (feedback == null) {
      return 'Finish a drill\nto unlock scoring.';
    }
    if (feedback.overallScore <= 2) {
      return 'Not enough answer.\nTry the question again.';
    }
    if (feedback.pillars.crutchCount > 0) {
      return 'Clear answer.\nTidy up the fillers.';
    }
    if (feedback.overallScore >= 4) {
      return 'Solid delivery.\nKeep the momentum.';
    }
    return 'Decent baseline.\nTighten the close.';
  }

  /// Overall Score Row (Circle Score Ring + Headline)
  Widget _buildOverallScoreSection({
    required String overallScore,
    required double overallValue,
    required EvaluationFeedback? feedback,
  }) {
    final score = feedback?.overallScore ?? 0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Circular Score Ring
        SizedBox(
          width: 96,
          height: 96,
          child: CustomPaint(
            painter: _ScoreRingPainter(
              scoreFraction: (overallValue <= 0 ? 0 : overallValue) / 5.0,
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _effortLabel(score),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF4F46E5),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _headlineFor(feedback),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.6,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                feedback == null
                    ? 'Scores appear after you complete a practice session.'
                    : 'Here\'s how you did and how to improve.',
                style: const TextStyle(
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

  /// 3 Metrics Row mapped from the 4-pillar evaluation.
  Widget _buildMetricsRow(EvaluationFeedback? feedback) {
    final impact = feedback?.pillars.impactScore ?? 0;
    final clarity = feedback?.pillars.clarityScore ?? 0;
    final fluency = feedback?.pillars.executiveScore ?? 0;
    final crutches = feedback?.pillars.crutchCount ?? 0;
    final wpm = feedback?.pillars.pacingWpm ?? 0;

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            icon: Icons.bolt_rounded,
            iconColor: const Color(0xFF2563EB),
            ringColor: const Color(0xFF2563EB),
            scoreFraction: impact / 5.0,
            title: 'Content',
            score: feedback == null ? '--/5' : '$impact/5',
            desc: feedback == null
                ? 'Waiting for your first scored answer.'
                : impact <= 1
                    ? 'No real answer to the prompt.'
                    : impact >= 4
                        ? 'Point landed with useful detail.'
                        : 'Lead with the decision sooner.',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.assignment_outlined,
            iconColor: const Color(0xFF059669),
            ringColor: const Color(0xFF059669),
            scoreFraction: clarity / 5.0,
            title: 'Structure',
            score: feedback == null ? '--/5' : '$clarity/5',
            desc: feedback == null
                ? 'Waiting for your first scored answer.'
                : clarity <= 1
                    ? 'Need a fuller spoken answer.'
                    : wpm > 0
                        ? 'Pace around $wpm wpm.'
                        : 'Keep ideas organised and easy to follow.',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.pause_circle_outline_rounded,
            iconColor: const Color(0xFFDC2626),
            ringColor: const Color(0xFFDC2626),
            scoreFraction: fluency / 5.0,
            title: 'Fluency',
            score: feedback == null ? '--/5' : '$fluency/5',
            desc: feedback == null
                ? 'Waiting for your first scored answer.'
                : fluency <= 1
                    ? 'Filler / noise only — retry.'
                    : crutches > 0
                        ? '$crutches filler habits spotted.'
                        : 'Steady delivery with fewer crutches.',
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

  /// Strength / coaching note card
  Widget _buildWhatWorkedWellCard(EvaluationFeedback? feedback) {
    final score = feedback?.overallScore ?? 0;
    final isWeak = score > 0 && score <= 2;
    final strength = feedback?.oneStrength.trim().isNotEmpty == true
        ? feedback!.oneStrength
        : 'Complete a drill to unlock a personalised strength note.';
    final label = isWeak ? 'WHAT TO FIX' : 'WHAT WORKED WELL';
    final bg = isWeak ? const Color(0xFFFFF7ED) : const Color(0xFFECFDF5);
    final border = isWeak ? const Color(0xFFFED7AA) : const Color(0xFFA7F3D0);
    final iconBg = isWeak ? const Color(0xFFFFEDD5) : const Color(0xFFD1FAE5);
    final iconColor = isWeak ? const Color(0xFFC2410C) : const Color(0xFF059669);
    final labelColor = isWeak ? const Color(0xFFC2410C) : const Color(0xFF047857);
    final bodyColor = isWeak ? const Color(0xFF9A3412) : const Color(0xFF065F46);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border, width: 1.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isWeak ? Icons.priority_high_rounded : Icons.check_rounded,
              color: iconColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: labelColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  strength,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: bodyColor,
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

  /// SUGGESTED ANSWER — clean exemplar + separate "you said" highlight.
  Widget _buildSuggestedAnswerCard(EvaluationFeedback? feedback) {
    final exemplar = feedback?.exemplarResponse.trim().isNotEmpty == true
        ? feedback!.exemplarResponse
        : 'Your coached exemplar appears here after a scored session.';
    final phrase = feedback?.highlightedPhrase.phrase.trim() ?? '';
    final critique = feedback?.highlightedPhrase.critique.trim() ?? '';
    final score = feedback?.overallScore ?? 0;
    final intro = feedback == null
        ? 'Finish a practice take to unlock a coached rewrite.'
        : score <= 2
            ? 'Here is a strong model answer for this prompt:'
            : 'Here\'s a more refined version you can aim for:';

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
          Text(
            intro,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFFE2E8F0),
              height: 1.35,
            ),
          ),
          if (phrase.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'YOU SAID',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 6),
            _buildPeachHighlightPill(phrase),
          ],
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exemplar,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12.5,
                          color: Color(0xFFCBD5E1),
                          height: 1.4,
                        ),
                      ),
                      if (critique.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          critique,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11.5,
                            color: Color(0xFF94A3B8),
                            height: 1.35,
                          ),
                        ),
                      ],
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
  Widget _buildKeyPointsToImproveCard(EvaluationFeedback? feedback) {
    final improvement = feedback?.oneSpecificImprovement.trim().isNotEmpty == true
        ? feedback!.oneSpecificImprovement
        : 'Complete a drill to unlock a specific coaching note.';
    final retry = feedback?.retryInstruction.trim().isNotEmpty == true
        ? feedback!.retryInstruction
        : 'Lead with the decision in the first 5 seconds.';
    final fluencyNote = feedback == null
        ? 'Scores unlock after your first practice take.'
        : feedback.pillars.crutchCount > 0
            ? 'Cut ${feedback.pillars.crutchCount} filler habit${feedback.pillars.crutchCount == 1 ? '' : 's'} next take.'
            : 'Keep a steady pace around ${feedback.pillars.pacingWpm} wpm.';

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
          _buildImprovementRow(
            tag: 'FOCUS',
            tagBg: const Color(0xFFFFEDD5),
            tagTextColor: const Color(0xFFC2410C),
            text: improvement,
          ),
          const SizedBox(height: 12),
          _buildImprovementRow(
            tag: 'RETRY',
            tagBg: const Color(0xFFEDE9FE),
            tagTextColor: const Color(0xFF6D28D9),
            text: retry,
          ),
          const SizedBox(height: 12),
          _buildImprovementRow(
            tag: 'FLUENCY',
            tagBg: const Color(0xFFDCFCE7),
            tagTextColor: const Color(0xFF15803D),
            text: fluencyNote,
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
