import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../core/services/analytics_service.dart';
import '../core/services/session_audio_store.dart';
import '../providers/app_state_provider.dart';
import '../widgets/hakkiri_loading_overlay.dart';
import '../widgets/mic_reactive_waveform.dart';
import '../widgets/shimmer_loading.dart';
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
  /// When true (Begin exercise already fetched), skip a second API call + shimmer.
  final bool promptAlreadyLoaded;

  const RecordingScreen({super.key, this.promptAlreadyLoaded = false});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen>
    with TickerProviderStateMixin {
  ExerciseStage _stage = ExerciseStage.wordByWordReveal;

  // Question words — seed before async API prompt fetch finishes.
  List<String> _words = const ['Loading', 'your', 'question…'];
  int _revealedWordCount = 0;
  Timer? _wordRevealTimer;
  bool _promptReady = false;

  // Prep countdown (per activity / prompt)
  int _prepTotalSeconds = 5;
  int _prepSecondsRemaining = 5;
  Timer? _prepCountdownTimer;
  late AnimationController _prepArcController;

  // Speaking countdown (per activity / prompt — not a fixed 45s)
  int _speakingTotalSeconds = 60;
  int _speakingSecondsRemaining = 60;
  Timer? _speakingTimer;
  String _promptHeadline = 'How would you handle a difficult stakeholder?';

  final SpeechToText _speech = SpeechToText();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final ValueNotifier<double> _micLevel = ValueNotifier<double>(0.12);
  StreamSubscription<Amplitude>? _ampSub;
  String _committedTranscript = '';
  String _partialTranscript = '';
  bool _finishing = false;
  bool _speechReady = false;
  bool _speechResumeInFlight = false;
  bool _fileRecorderActive = false;
  String? _audioTempPath;
  Timer? _speechSoftWatchdog;
  Timer? _idleWaveTimer;
  DateTime? _lastSpeechResumeAt;
  DateTime? _lastMicLevelAt;
  double _idlePhase = 0;

  String get _liveTranscript =>
      '$_committedTranscript $_partialTranscript'.trim();

  bool get _drillActive =>
      !_finishing &&
      mounted &&
      _stage == ExerciseStage.recordingScreen &&
      _speakingSecondsRemaining > 0;

  @override
  void initState() {
    super.initState();

    _prepArcController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    if (widget.promptAlreadyLoaded) {
      // Apply prompt immediately — no shimmer flash after Begin exercise.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _applyPromptAndStart(
          Provider.of<AppStateProvider>(context, listen: false),
        );
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initSessionPrompt();
      });
    }
  }

  Future<void> _initSessionPrompt() async {
    final state = Provider.of<AppStateProvider>(context, listen: false);
    // Begin exercise already loaded the question — do not fetch again (avoids
    // stuck shimmer + same-question double call).
    if (!widget.promptAlreadyLoaded && state.isLoggedIn) {
      try {
        await state.fetchNextPromptFromApi(excludeCurrent: true);
      } catch (_) {}
    }
    if (!mounted) return;
    _applyPromptAndStart(state);
  }

  void _applyPromptAndStart(AppStateProvider state) {
    final activity = state.selectedActivity;
    final prompt = state.selectedPrompt;

    _speakingTotalSeconds =
        prompt?.durationSeconds ?? activity?.defaultDurationSeconds ?? 60;
    _prepTotalSeconds =
        prompt?.prepSeconds ?? activity?.prepDurationSeconds ?? 5;
    if (_speakingTotalSeconds < 10) _speakingTotalSeconds = 10;
    if (_prepTotalSeconds < 1) _prepTotalSeconds = 1;

    _speakingSecondsRemaining = _speakingTotalSeconds;
    _prepSecondsRemaining = _prepTotalSeconds;
    _prepArcController.duration = Duration(seconds: _prepTotalSeconds);

    _promptHeadline = prompt?.promptText ??
        'How would you handle a difficult stakeholder?';
    final nextWords =
        _promptHeadline.split(' ').where((w) => w.isNotEmpty).toList();
    _words = nextWords.isEmpty ? ['Ready', 'when', 'you', 'are.'] : nextWords;
    _promptReady = true;
    AnalyticsService.instance.logPracticeStarted(
      activitySlug: activity?.slug ?? 'drill',
      activityName: activity?.name ?? 'Practice Drill',
      promptTitle: _promptHeadline,
      difficulty: state.selectedDifficulty,
    );
    AnalyticsService.instance.logScreenView(screenName: 'RecordingScreen');
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
  // PHASE 2: PREPARATION COUNTDOWN (activity prep seconds)
  // -------------------------------------------------------------
  void _start5sCountdown() {
    setState(() {
      _stage = ExerciseStage.countdown5s;
      _prepSecondsRemaining = _prepTotalSeconds;
    });

    _prepArcController.duration = Duration(seconds: _prepTotalSeconds);
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
  // PHASE 3: RECORDING SCREEN (activity speak seconds)
  // -------------------------------------------------------------
  void _startRecording() {
    setState(() {
      _stage = ExerciseStage.recordingScreen;
      _speakingSecondsRemaining = _speakingTotalSeconds;
      _committedTranscript = '';
      _partialTranscript = '';
    });

    // ONE mic owner only: file recorder.
    // Dual capture (record + speech_to_text) causes on/off thrash — never both.
    // Transcript comes from Gemini after upload of this local m4a (playback works too).
    _startIdleWave();
    unawaited(_startContinuousRecorder());

    _speakingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_speakingSecondsRemaining > 0) {
        setState(() {
          _speakingSecondsRemaining--;
        });
      } else {
        unawaited(_finishSession());
      }
    });
  }

  /// Gentle pulse so the UI stays "alive" even in silence (timer still running).
  void _startIdleWave() {
    _idleWaveTimer?.cancel();
    _lastMicLevelAt = DateTime.now();
    _idleWaveTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (!_drillActive) return;
      final last = _lastMicLevelAt;
      final quiet = last == null ||
          DateTime.now().difference(last) > const Duration(milliseconds: 350);
      if (!quiet) return;
      _idlePhase += 0.18;
      final pulse = 0.14 + (math.sin(_idlePhase) + 1) * 0.08;
      _micLevel.value = pulse.clamp(0.08, 0.45);
    });
  }

  /// Soft STT recovery only — rare restarts, never start a second mic/file recorder.
  void _startSoftSpeechWatchdog() {
    _speechSoftWatchdog?.cancel();
    _speechSoftWatchdog = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_drillActive || !_speechReady) return;
      if (_speech.isListening || _speechResumeInFlight) return;
      unawaited(_resumeSpeechCapture());
    });
  }

  Future<void> _startContinuousRecorder() async {
    try {
      if (!await _audioRecorder.hasPermission()) return;
      _audioTempPath = await SessionAudioStore.instance.startTempPath();
      // Speech-optimised AAC keeps analyze payloads under the API body limit.
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 64000,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: _audioTempPath!,
      );
      _fileRecorderActive = true;
      await _ampSub?.cancel();
      _ampSub = _audioRecorder
          .onAmplitudeChanged(const Duration(milliseconds: 55))
          .listen((amp) {
        // Current is typically ~-60 (quiet) to 0 (loud).
        final raw = ((amp.current + 50) / 50).clamp(0.0, 1.0);
        final level = math.pow(raw, 0.72).toDouble().clamp(0.08, 1.0);
        _micLevel.value = level;
        _lastMicLevelAt = DateTime.now();
      });
    } catch (_) {
      _audioTempPath = null;
      _fileRecorderActive = false;
    }
  }

  Future<String?> _stopContinuousRecorder() async {
    await _ampSub?.cancel();
    _ampSub = null;
    _fileRecorderActive = false;
    try {
      if (await _audioRecorder.isRecording()) {
        final path = await _audioRecorder.stop();
        return path ?? _audioTempPath;
      }
    } catch (_) {}
    return _audioTempPath;
  }

  Future<void> _startSpeechCapture() async {
    try {
      _speechReady = await _speech.initialize(
        onError: (_) {},
        onStatus: (_) {},
      );
      if (!_speechReady || !mounted) return;
      await _resumeSpeechCapture();
    } catch (_) {
      _speechReady = false;
    }
  }

  Future<void> _resumeSpeechCapture() async {
    if (!_drillActive || !_speechReady) return;
    if (_speech.isListening || _speechResumeInFlight) return;
    final now = DateTime.now();
    if (_lastSpeechResumeAt != null &&
        now.difference(_lastSpeechResumeAt!) < const Duration(seconds: 4)) {
      return;
    }
    _speechResumeInFlight = true;
    _lastSpeechResumeAt = now;
    if (_partialTranscript.isNotEmpty) {
      _committedTranscript =
          '$_committedTranscript $_partialTranscript'.trim();
      _partialTranscript = '';
    }
    try {
      final remaining = _speakingSecondsRemaining.clamp(5, 600);
      final ok = await _speech.listen(
        onResult: (result) {
          if (_finishing) return;
          final text = result.recognizedWords.trim();
          if (result.finalResult) {
            if (text.isNotEmpty) {
              _committedTranscript = '$_committedTranscript $text'.trim();
            }
            _partialTranscript = '';
          } else {
            _partialTranscript = text;
          }
          if (mounted) setState(() {});
        },
        onSoundLevelChange: (level) {
          final normalized = ((level + 2) / 12).clamp(0.08, 1.0);
          _micLevel.value = normalized;
          _lastMicLevelAt = DateTime.now();
        },
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.dictation,
          partialResults: true,
          cancelOnError: false,
          listenFor: Duration(seconds: remaining + 120),
          pauseFor: Duration(seconds: remaining + 120),
        ),
      );
      if (ok != true && _drillActive) {
        // listen() returned false — retry once after a beat.
        await Future<void>.delayed(const Duration(milliseconds: 800));
        if (_drillActive && !_speech.isListening) {
          _speechResumeInFlight = false;
          _lastSpeechResumeAt = null;
          unawaited(_resumeSpeechCapture());
          return;
        }
      }
    } catch (_) {
      // Keep the drill alive — timer + idle wave continue.
    } finally {
      _speechResumeInFlight = false;
    }
  }

  Future<void> _finishSession() async {
    if (_finishing) return;
    _finishing = true;

    _wordRevealTimer?.cancel();
    _prepCountdownTimer?.cancel();
    _speakingTimer?.cancel();
    _speechSoftWatchdog?.cancel();
    _idleWaveTimer?.cancel();

    final audioPath = await _stopContinuousRecorder();

    final spoken = (_speakingTotalSeconds - _speakingSecondsRemaining)
        .clamp(1, _speakingTotalSeconds);

    String? audioBase64;
    if (audioPath != null && audioPath.isNotEmpty) {
      try {
        final bytes = await File(audioPath).readAsBytes();
        // ~2.5MB raw keeps the analyze payload under Vercel body limits.
        if (bytes.isNotEmpty && bytes.length <= 2 * 1024 * 1024) {
          audioBase64 = base64Encode(bytes);
        }
      } catch (_) {}
    }

    if (!mounted) return;

    final state = Provider.of<AppStateProvider>(context, listen: false);
    final hasClip = audioBase64 != null && audioBase64.isNotEmpty;

    await HakkiriLoadingOverlay.run(
      context,
      message: hasClip ? 'Transcribing your answer…' : 'Scoring your answer…',
      detail: hasClip
          ? 'Saving playback and scoring structure, pace, and fillers.'
          : 'Matching your answer to the prompt — almost there.',
      action: () => state.evaluateCurrentSession(
        transcript: '',
        durationSeconds: spoken,
        conversationMode: 'single',
        localAudioTempPath: audioPath,
        audioBase64: audioBase64,
        audioMimeType: 'audio/mp4',
      ),
    );

    if (!mounted) return;
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
    _speechSoftWatchdog?.cancel();
    _idleWaveTimer?.cancel();
    _prepArcController.dispose();
    unawaited(_ampSub?.cancel());
    unawaited(_speech.stop());
    unawaited(_speech.cancel());
    unawaited(_stopContinuousRecorder());
    unawaited(_audioRecorder.dispose());
    _micLevel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_promptReady) {
      final state = Provider.of<AppStateProvider>(context, listen: false);
      return QuestionLoadingShimmer(
        activityName: state.selectedActivity?.name,
        onBack: () => Navigator.maybePop(context),
      );
    }
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

              // Live prompt from API/local — highlight the closing phrase
              _buildPromptHeadlineRichText(),

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
              Text(
                _promptHeadline,
                style: const TextStyle(
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
                      progress: _speakingSecondsRemaining /
                          _speakingTotalSeconds.clamp(1, 999),
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

              // Live Waveform — levels from speech_to_text (same mic as transcript)
              Center(
                child: MicReactiveWaveform(
                  active: true,
                  barCount: 28,
                  width: 220,
                  height: 48,
                  color: const Color(0xFF818CF8),
                  externalLevel: _micLevel,
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
                    onTap: () => unawaited(_finishSession()),
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

  /// Dynamic prompt title — last ~3 words highlighted blue (same look as Faizan).
  Widget _buildPromptHeadlineRichText() {
    final words = _promptHeadline.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) {
      return const Text(
        'Ready when you are.',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 27,
          fontWeight: FontWeight.w900,
          color: Color(0xFF0F172A),
          letterSpacing: -0.6,
          height: 1.22,
        ),
      );
    }
    final highlightCount = words.length <= 3 ? words.length : 3;
    final head = words.sublist(0, words.length - highlightCount).join(' ');
    final tail = words.sublist(words.length - highlightCount).join(' ');
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 27,
          fontWeight: FontWeight.w900,
          color: Color(0xFF0F172A),
          letterSpacing: -0.6,
          height: 1.22,
        ),
        children: [
          if (head.isNotEmpty) TextSpan(text: '$head '),
          TextSpan(
            text: tail,
            style: const TextStyle(color: Color(0xFF2563EB)),
          ),
        ],
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

