import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import 'feedback_screen.dart';

enum ExerciseStage {
  wordByWordReveal, // Step 1 (doc_images/img_0.png)
  countdown5s,       // Step 2 (doc_images/img_2.png)
  recordingScreen,   // Step 3 (doc_images/img_1.png)
}

/// Opal-style interactive speaking practice session:
/// 1. Question appears word-by-word with royal blue karaoke highlight
/// 2. 5-second preparation countdown automatically starts
/// 3. Transitions automatically into dark mode recording screen with animated waveform
class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen>
    with TickerProviderStateMixin {
  ExerciseStage _stage = ExerciseStage.wordByWordReveal;

  // Question words
  late List<String> _words;
  int _revealedWordCount = 0;
  Timer? _wordRevealTimer;

  // 5-second countdown
  int _prepSecondsRemaining = 5;
  Timer? _prepCountdownTimer;
  late AnimationController _prepArcController;

  // Recording countdown
  int _speakingSecondsRemaining = 41; // Matches doc_images/img_1.png (0:41)
  Timer? _speakingTimer;
  late AnimationController _waveAnimController;

  @override
  void initState() {
    super.initState();

    _prepArcController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _waveAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSessionPrompt();
    });
  }

  void _initSessionPrompt() {
    final state = Provider.of<AppStateProvider>(context, listen: false);
    final promptText = state.selectedPrompt?.promptText ??
        'How would you handle a difficult stakeholder?';

    _words = promptText.split(' ');
    _startWordByWordReveal();
  }

  // -------------------------------------------------------------
  // PHASE 1: WORD-BY-WORD REVEAL (doc_images/img_0.png)
  // -------------------------------------------------------------
  void _startWordByWordReveal() {
    _revealedWordCount = 1; // start with first word
    setState(() {});

    _wordRevealTimer = Timer.periodic(const Duration(milliseconds: 280), (timer) {
      if (_revealedWordCount < _words.length) {
        setState(() {
          _revealedWordCount++;
        });
      } else {
        _wordRevealTimer?.cancel();
        // Wait brief beat after last word, then start 5s countdown
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) {
            _start5sCountdown();
          }
        });
      }
    });
  }

  // -------------------------------------------------------------
  // PHASE 2: 5-SECOND PREPARATION COUNTDOWN (doc_images/img_2.png)
  // -------------------------------------------------------------
  void _start5sCountdown() {
    setState(() {
      _stage = ExerciseStage.countdown5s;
      _prepSecondsRemaining = 5;
    });

    _prepArcController.reset();
    _prepArcController.forward();

    _prepCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_prepSecondsRemaining > 1) {
        setState(() {
          _prepSecondsRemaining--;
        });
      } else {
        _prepCountdownTimer?.cancel();
        if (mounted) {
          _startRecording();
        }
      }
    });
  }

  // -------------------------------------------------------------
  // PHASE 3: RECORDING SCREEN (doc_images/img_1.png)
  // -------------------------------------------------------------
  void _startRecording() {
    setState(() {
      _stage = ExerciseStage.recordingScreen;
      _speakingSecondsRemaining = 41;
    });

    _speakingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_speakingSecondsRemaining > 0) {
        setState(() {
          _speakingSecondsRemaining--;
        });
      } else {
        _finishSession();
      }
    });
  }

  void _finishSession() {
    _wordRevealTimer?.cancel();
    _prepCountdownTimer?.cancel();
    _speakingTimer?.cancel();

    final state = Provider.of<AppStateProvider>(context, listen: false);
    state.evaluateCurrentSession(
      transcript:
          'I would start by listening to understand their concerns, acknowledge their perspective, and then align on shared objectives.',
      durationSeconds: 41 - _speakingSecondsRemaining,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const FeedbackScreen()),
    );
  }

  @override
  void dispose() {
    _wordRevealTimer?.cancel();
    _prepCountdownTimer?.cancel();
    _speakingTimer?.cancel();
    _prepArcController.dispose();
    _waveAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (_stage) {
      case ExerciseStage.wordByWordReveal:
        return _buildWordByWordRevealScreen();
      case ExerciseStage.countdown5s:
        return _buildCountdown5sScreen();
      case ExerciseStage.recordingScreen:
        return _buildRecordingScreen();
    }
  }

  // =============================================================
  // SCREEN 1: WORD-BY-WORD REVEAL (doc_images/img_0.png)
  // =============================================================
  Widget _buildWordByWordRevealScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBF9),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(
                  Icons.chevron_left_rounded,
                  color: Color(0xFF0F172A),
                  size: 32,
                ),
              ),
              const SizedBox(height: 24),

              // Lightning bolt icon badge + THINK FAST
              Row(
                children: const [
                  Icon(
                    Icons.bolt_rounded,
                    color: Color(0xFF2563EB),
                    size: 24,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'THINK FAST',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Question revealed word-by-word with karaoke style highlight
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 10,
                    children: List.generate(_words.length, (index) {
                      final word = _words[index];
                      final isRevealed = index < _revealedWordCount;
                      final isCurrentWord = index == _revealedWordCount - 1;

                      Color wordColor;
                      if (!isRevealed) {
                        wordColor = const Color(0xFFCBD5E1).withValues(alpha: 0.35);
                      } else if (isCurrentWord) {
                        wordColor = const Color(0xFF2563EB); // Royal blue active
                      } else {
                        wordColor = const Color(0xFF0F172A); // Dark navy for past
                      }

                      return AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: wordColor,
                          letterSpacing: -0.6,
                          height: 1.25,
                        ),
                        child: Text(word),
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =============================================================
  // SCREEN 2: 5-SECOND COUNTDOWN (doc_images/img_2.png)
  // =============================================================
  Widget _buildCountdown5sScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBF9),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(
                  Icons.chevron_left_rounded,
                  color: Color(0xFF0F172A),
                  size: 32,
                ),
              ),
              const SizedBox(height: 24),

              // Lightning bolt icon badge + THINK FAST
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFDBEAFE), width: 1),
                    ),
                    child: const Icon(
                      Icons.bolt_rounded,
                      color: Color(0xFF2563EB),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'THINK FAST',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Question with "difficult stakeholder?" highlighted in blue
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.6,
                    height: 1.22,
                  ),
                  children: [
                    TextSpan(text: 'How would you handle\na '),
                    TextSpan(
                      text: 'difficult stakeholder?',
                      style: TextStyle(color: Color(0xFF2563EB)),
                    ),
                  ],
                ),
              ),

              // Center Circular 5s Countdown Timer
              Expanded(
                child: Center(
                  child: SizedBox(
                    width: 220,
                    height: 220,
                    child: AnimatedBuilder(
                      animation: _prepArcController,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: _CountdownCirclePainter(
                            progress: 1.0 - _prepArcController.value,
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$_prepSecondsRemaining',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 64,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF0F172A),
                                    letterSpacing: -1.0,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'SECONDS',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.6,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =============================================================
  // SCREEN 3: DARK MODE RECORDING SCREEN (doc_images/img_1.png)
  // =============================================================
  Widget _buildRecordingScreen() {
    final m = _speakingSecondsRemaining ~/ 60;
    final s = _speakingSecondsRemaining % 60;
    final timeFormatted = '$m:${s < 10 ? '0' : ''}$s';

    return Scaffold(
      backgroundColor: const Color(0xFF0B101D),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar with centered THINK FIRST & horizontal progress
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(
                          Icons.chevron_left_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const Text(
                        'THINK FIRST',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: Color(0xFFA0A3B5),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.6,
                        ),
                      ),
                      const SizedBox(width: 28), // balance chevron
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Horizontal Progress Bar
                  Stack(
                    children: [
                      Container(
                        height: 2.5,
                        width: double.infinity,
                        color: const Color(0xFF1E293B),
                      ),
                      Container(
                        height: 2.5,
                        width: MediaQuery.of(context).size.width * 0.40,
                        color: const Color(0xFF818CF8),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // YOUR QUESTION
              const Text(
                'YOUR QUESTION',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF818CF8),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 8),

              // Question Headline
              const Text(
                'How would you handle a difficult stakeholder?',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.6,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 36),

              // Central Circular Speak Timer
              Center(
                child: SizedBox(
                  width: 210,
                  height: 210,
                  child: CustomPaint(
                    painter: _RecordingCirclePainter(
                      progress: _speakingSecondsRemaining / 60.0,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            timeFormatted,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 52,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'left to speak',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: Color(0xFFA0A3B5),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // REC Pill Badge
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E1116),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'REC',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: Color(0xFFEF4444),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Live Waveform Visualizer
              Center(
                child: AnimatedBuilder(
                  animation: _waveAnimController,
                  builder: (context, child) {
                    return CustomPaint(
                      size: const Size(220, 48),
                      painter: _RecordingWaveformPainter(
                        animationValue: _waveAnimController.value,
                      ),
                    );
                  },
                ),
              ),

              const Spacer(),

              // Finish answer Button
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3EFE6),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: _finishSession,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(width: 38), // balance arrow
                          const Text(
                            'Finish answer',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: Color(0xFF0F172A),
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Container(
                            width: 38,
                            height: 38,
                            decoration: const BoxDecoration(
                              color: Color(0xFF2563EB),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 19,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

/// Painter for the 5-second preparation countdown circular arc
class _CountdownCirclePainter extends CustomPainter {
  final double progress;

  _CountdownCirclePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 10;

    // Background circle track
    final trackPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9;

    canvas.drawCircle(center, radius, trackPaint);

    // Active progress arc
    final arcPaint = Paint()
      ..color = const Color(0xFF2563EB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CountdownCirclePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Painter for the dark mode recording timer circular arc
class _RecordingCirclePainter extends CustomPainter {
  final double progress;

  _RecordingCirclePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 10;

    // Track
    final trackPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9;

    canvas.drawCircle(center, radius, trackPaint);

    // Progress
    final arcPaint = Paint()
      ..color = const Color(0xFF818CF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RecordingCirclePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Dynamic live audio waveform painter
class _RecordingWaveformPainter extends CustomPainter {
  final double animationValue;

  _RecordingWaveformPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final barPaint = Paint()
      ..color = const Color(0xFF818CF8)
      ..strokeCap = StrokeCap.round;

    const barCount = 28;
    final barWidth = 3.6;
    final totalWidth = size.width;
    final spacing = (totalWidth - (barCount * barWidth)) / (barCount - 1);
    final centerY = size.height / 2;

    for (int i = 0; i < barCount; i++) {
      final x = i * (barWidth + spacing) + (barWidth / 2);
      // Symmetrical Gaussian wave modulated by animation
      final distFromCenter = (i - (barCount / 2)).abs() / (barCount / 2);
      final envelope = math.exp(-distFromCenter * distFromCenter * 2.5);
      final wave = math.sin((i * 0.45) + (animationValue * 2 * math.pi)).abs();
      final h = (size.height * 0.2) + (size.height * 0.75 * envelope * (0.4 + 0.6 * wave));

      canvas.drawLine(
        Offset(x, centerY - h / 2),
        Offset(x, centerY + h / 2),
        barPaint..strokeWidth = barWidth,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RecordingWaveformPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}
