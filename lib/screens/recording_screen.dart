import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../core/services/analytics_service.dart';
import '../core/services/ios_drill_recorder.dart';
import '../core/services/session_audio_store.dart';
import '../providers/app_state_provider.dart';
import '../widgets/action_pill_button.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/hakkiri_loading_overlay.dart';
import '../widgets/mic_reactive_waveform.dart';
import '../widgets/shimmer_loading.dart';
import 'feedback_screen.dart';
import 'paywall_screen.dart';

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

  /// Guest plan free try — score + feedback locally, then IAP on leave.
  final bool isGuestTrial;

  const RecordingScreen({
    super.key,
    this.promptAlreadyLoaded = false,
    this.isGuestTrial = false,
  });

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
  bool _promptSpeaking = false;

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
  /// Cut It In Half: long passage — skip karaoke stage (avoids huge→tiny glitch).
  bool _isCutInHalf = false;

  final SpeechToText _speech = SpeechToText();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final ValueNotifier<double> _micLevel = ValueNotifier<double>(0.12);
  StreamSubscription<Amplitude>? _ampSub;
  String _committedTranscript = '';
  String _partialTranscript = '';
  bool _finishing = false;
  bool _speechReady = false;
  bool _speechResumeInFlight = false;
  // ignore: unused_field
  bool _fileRecorderActive = false;
  String? _audioTempPath;
  Timer? _speechSoftWatchdog;
  Timer? _idleWaveTimer;
  DateTime? _lastSpeechResumeAt;
  DateTime? _lastMicLevelAt;
  double _idlePhase = 0;
  /// True once amplitude rises above idle noise — proves mic actually heard audio.
  bool _heardRealAudio = false;

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

  /// Cut It In Half must show the long PASSAGE to compress.
  /// New catalog: passage is [promptText]. Legacy: passage was [secondaryText].
  String? _cutItInHalfPassage(dynamic prompt) {
    if (prompt == null) return null;
    final primary = (prompt.promptText as String?)?.trim() ?? '';
    final secondary = (prompt.secondaryText as String?)?.trim() ?? '';
    if (secondary.length > primary.length && secondary.length >= 80) {
      return secondary;
    }
    if (primary.isNotEmpty) return primary;
    if (secondary.isNotEmpty) return secondary;
    return null;
  }

  void _applyPromptAndStart(AppStateProvider state) {
    final activity = state.selectedActivity;
    var prompt = state.selectedPrompt;
    // Never speak a Think Fast question inside One Minute Expert / etc.
    if (prompt != null &&
        activity != null &&
        AppStateProvider.normalizeActivitySlug(prompt.activitySlug) !=
            activity.slug) {
      debugPrint(
        '[Recording] prompt/activity mismatch '
        '(${prompt.activitySlug} vs ${activity.slug}) — clearing',
      );
      prompt = null;
    }

    _speakingTotalSeconds =
        prompt?.durationSeconds ?? activity?.defaultDurationSeconds ?? 60;
    _prepTotalSeconds =
        prompt?.prepSeconds ?? activity?.prepDurationSeconds ?? 5;
    if (_speakingTotalSeconds < 10) _speakingTotalSeconds = 10;
    if (_prepTotalSeconds < 1) _prepTotalSeconds = 1;
    // Product copy: Think Fast / One Minute Expert / Explain It Simply = 5s think.
    final slug = activity?.slug ?? '';
    if (slug == 'think_fast' ||
        slug == 'one_minute_expert' ||
        slug == 'explain_it_simply') {
      _prepTotalSeconds = 5;
    }
    // Cut It In Half: 60s to read the passage, 30s to speak the short version.
    if (slug == 'cut_it_in_half') {
      _prepTotalSeconds = 60;
      _speakingTotalSeconds = 30;
    }

    _speakingSecondsRemaining = _speakingTotalSeconds;
    _prepSecondsRemaining = _prepTotalSeconds;
    _prepArcController.duration = Duration(seconds: _prepTotalSeconds);

    // Cut It In Half: show the PASSAGE (to compress), never a quiz-style question.
    // Prefer longer secondaryText when legacy prompts still store the brief there.
    _promptHeadline = _cutItInHalfPassage(prompt) ??
        prompt?.promptText ??
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
    _isCutInHalf = (activity?.slug ?? '') == 'cut_it_in_half';
    // CIH: go straight to the 60s read countdown with stable passage size.
    // Karaoke stage uses 32pt type and was causing a sudden shrink glitch.
    if (_isCutInHalf) {
      _revealedWordCount = _words.length;
      _promptSpeaking = false;
      _start5sCountdown();
      return;
    }
    _startWordByWordReveal();
  }

  // -------------------------------------------------------------
  // PHASE 1: WORD-BY-WORD REVEAL (no coach voice)
  // -------------------------------------------------------------
  void _startWordByWordReveal() {
    _wordRevealTimer?.cancel();

    if (_words.isEmpty) {
      _revealedWordCount = 0;
      _promptSpeaking = false;
      setState(() {});
      _start5sCountdown();
      return;
    }

    _revealedWordCount = 1;
    _promptSpeaking = true;
    setState(() {});

    _wordRevealTimer =
        Timer.periodic(const Duration(milliseconds: 400), (timer) {
      if (!mounted ||
          _stage != ExerciseStage.wordByWordReveal ||
          !_promptSpeaking) {
        timer.cancel();
        return;
      }
      if (_revealedWordCount >= _words.length) {
        timer.cancel();
        setState(() => _promptSpeaking = false);
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted && _stage == ExerciseStage.wordByWordReveal) {
            _start5sCountdown();
          }
        });
        return;
      }
      setState(() => _revealedWordCount++);
    });
  }

  // -------------------------------------------------------------
  // PHASE 2: PREPARATION COUNTDOWN (activity prep seconds)
  // -------------------------------------------------------------
  void _start5sCountdown() {
    _wordRevealTimer?.cancel();
    setState(() {
      _stage = ExerciseStage.countdown5s;
      _prepSecondsRemaining = _prepTotalSeconds;
      _promptSpeaking = false;
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

  /// Skip remaining prep time and start the speak/record phase immediately.
  void _skipPrepToRecording() {
    if (_stage == ExerciseStage.recordingScreen) return;
    _wordRevealTimer?.cancel();
    _prepCountdownTimer?.cancel();
    try {
      _prepArcController.stop();
    } catch (_) {}
    if (_stage == ExerciseStage.wordByWordReveal) {
      setState(() {
        _revealedWordCount = _words.length;
        _promptSpeaking = false;
      });
    }
    _startRecording();
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
      _heardRealAudio = false;
    });

    // ONE mic owner only: file recorder.
    // Never run speech_to_text in parallel — on iOS it steals the session after
    // a few words, so Gemini / YOU SAID only get "I would like to…".
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

  /// iOS: coach TTS / feedback playback can leave AVAudioSession on
  /// `.playback`, so the next Think Fast capture writes silence.
  Future<void> _prepareMicAudioSession() async {
    if (!Platform.isIOS) return;
    try {
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playAndRecord,
            options: const {
              AVAudioSessionOptions.defaultToSpeaker,
              AVAudioSessionOptions.allowBluetooth,
              AVAudioSessionOptions.mixWithOthers,
            },
          ),
          android: const AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: false,
            contentType: AndroidContentType.speech,
            usageType: AndroidUsageType.voiceCommunication,
            audioFocus: AndroidAudioFocus.gain,
          ),
        ),
      );
    } catch (e) {
      debugPrint('[Recording] prepare mic session failed: $e');
    }
  }

  RecordConfig _recordConfig() {
    // Keep payloads under API limits (~60s). On iOS omit bitRate (AAC + forced
    // low bitRate has produced silent files); 16 kHz mono stays speech-sized.
    if (Platform.isIOS) {
      return const RecordConfig(
        encoder: AudioEncoder.aacLc,
        numChannels: 1,
        sampleRate: 16000,
      );
    }
    return const RecordConfig(
      encoder: AudioEncoder.aacLc,
      bitRate: 64000,
      sampleRate: 16000,
      numChannels: 1,
    );
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

  /// Soft STT recovery only — rare restarts, never start a second file recorder.
  void _startSoftSpeechWatchdog() {
    _speechSoftWatchdog?.cancel();
    _speechSoftWatchdog = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_drillActive || !_speechReady) return;
      if (_speech.isListening || _speechResumeInFlight) return;
      unawaited(_resumeSpeechCapture());
    });
  }

  Future<void> _startContinuousRecorder() async {
    // iOS: native AVAudioRecorder — Flutter `record` often writes silent m4a.
    if (Platform.isIOS) {
      await _startIosNativeRecorder();
      return;
    }
    try {
      await _prepareMicAudioSession();
      if (!await _audioRecorder.hasPermission()) {
        debugPrint('[Recording] mic permission denied');
        if (mounted) {
          AppSnackBar.showInfo(
            context,
            'Microphone permission is required to score your answer.',
          );
        }
        return;
      }
      _audioTempPath = await SessionAudioStore.instance.startTempPath();
      await _audioRecorder.start(
        _recordConfig(),
        path: _audioTempPath!,
      );
      final live = await _audioRecorder.isRecording();
      if (!live) {
        throw StateError('Recorder started but isRecording() is false');
      }
      _fileRecorderActive = true;
      await _ampSub?.cancel();
      _ampSub = _audioRecorder
          .onAmplitudeChanged(const Duration(milliseconds: 55))
          .listen((amp) {
        final raw = ((amp.current + 50) / 50).clamp(0.0, 1.0);
        final level = math.pow(raw, 0.72).toDouble().clamp(0.08, 1.0);
        if (amp.current > -35) {
          _heardRealAudio = true;
        }
        _micLevel.value = level;
        _lastMicLevelAt = DateTime.now();
      });
    } catch (e, st) {
      debugPrint('[Recording] file recorder failed: $e\n$st');
      _audioTempPath = null;
      _fileRecorderActive = false;
      try {
        await _prepareMicAudioSession();
        final fallback =
            '${Directory.systemTemp.path}/hakkiri_rec_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _audioRecorder.start(
          _recordConfig(),
          path: fallback,
        );
        _audioTempPath = fallback;
        _fileRecorderActive = true;
        await _ampSub?.cancel();
        _ampSub = _audioRecorder
            .onAmplitudeChanged(const Duration(milliseconds: 55))
            .listen((amp) {
          final raw = ((amp.current + 50) / 50).clamp(0.0, 1.0);
          final level = math.pow(raw, 0.72).toDouble().clamp(0.08, 1.0);
          if (amp.current > -35) _heardRealAudio = true;
          _micLevel.value = level;
          _lastMicLevelAt = DateTime.now();
        });
      } catch (e2, st2) {
        debugPrint('[Recording] fallback recorder failed: $e2\n$st2');
      }
    }
  }

  Future<void> _startIosNativeRecorder() async {
    try {
      final granted = await IosDrillRecorder.instance.hasPermission();
      if (!granted) {
        debugPrint('[Recording] iOS native mic permission denied');
        if (mounted) {
          AppSnackBar.showInfo(
            context,
            'Microphone permission is required to score your answer.',
          );
        }
        return;
      }
      final path = await IosDrillRecorder.instance.start(
        onAmplitude: (level) {
          if (level > 0.22) _heardRealAudio = true;
          _micLevel.value = level;
          _lastMicLevelAt = DateTime.now();
        },
      );
      _audioTempPath = path;
      _fileRecorderActive = true;
      debugPrint('[Recording] iOS native recorder started → $path');
    } catch (e, st) {
      debugPrint('[Recording] iOS native recorder failed: $e\n$st');
      _audioTempPath = null;
      _fileRecorderActive = false;
      if (mounted) {
        AppSnackBar.showInfo(
          context,
          'Could not start microphone. Check Settings → Hakkiri → Microphone.',
        );
      }
    }
  }

  Future<String?> _stopContinuousRecorder() async {
    await _ampSub?.cancel();
    _ampSub = null;
    _fileRecorderActive = false;
    if (Platform.isIOS) {
      final stopped = await IosDrillRecorder.instance.stop();
      debugPrint(
        '[Recording] iOS native stop path=${stopped.path} bytes=${stopped.bytes}',
      );
      if (stopped.path != null && stopped.path!.isNotEmpty) {
        _audioTempPath = stopped.path;
      }
      return _audioTempPath;
    }
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
      // Give the file recorder a beat to own the session first on iOS.
      if (Platform.isIOS) {
        await Future<void>.delayed(const Duration(milliseconds: 400));
      }
      _speechReady = await _speech.initialize(
        onError: (e) => debugPrint('[Recording] STT error: $e'),
        onStatus: (s) => debugPrint('[Recording] STT status: $s'),
      );
      if (!_speechReady || !mounted) return;
      _startSoftSpeechWatchdog();
      await _resumeSpeechCapture();
    } catch (e) {
      debugPrint('[Recording] STT init failed: $e');
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

  Future<void> _exitGuestTrialToPaywall() async {
    final state = Provider.of<AppStateProvider>(context, listen: false);
    await state.markGuestReachedPaywall();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const PaywallScreen()),
      (route) => false,
    );
  }

  Future<void> _onBack() async {
    if (widget.isGuestTrial) {
      await _stopContinuousRecorder();
      if (!mounted) return;
      await _exitGuestTrialToPaywall();
      return;
    }
    Navigator.pop(context);
  }

  Future<void> _finishSession() async {
    if (_finishing) return;
    _finishing = true;

    _wordRevealTimer?.cancel();
    _prepCountdownTimer?.cancel();
    _speakingTimer?.cancel();
    _speechSoftWatchdog?.cancel();
    _idleWaveTimer?.cancel();

    try {
      await _speech.stop();
    } catch (_) {}

    final audioPath = await _stopContinuousRecorder();

    final spoken = (_speakingTotalSeconds - _speakingSecondsRemaining)
        .clamp(1, _speakingTotalSeconds);

    String? audioBase64;
    var audioBytes = 0;
    if (audioPath != null && audioPath.isNotEmpty) {
      try {
        final bytes = await File(audioPath).readAsBytes();
        audioBytes = bytes.length;
        // Tiny iOS files are usually silent/corrupt headers only.
        final minBytes = Platform.isIOS ? 2500 : 400;
        // Allow larger clips so a full 60s answer is never dropped (which
        // previously forced a 2–3 word STT stub into YOU SAID).
        final maxBytes = 4 * 1024 * 1024;
        if (bytes.length >= minBytes && bytes.length <= maxBytes) {
          audioBase64 = base64Encode(bytes);
        } else {
          debugPrint(
            '[Recording] audio file unusable '
            '(${bytes.length} bytes, heard=$_heardRealAudio)',
          );
        }
      } catch (_) {}
    }

    if (!mounted) return;

    final state = Provider.of<AppStateProvider>(context, listen: false);
    final hasClip = audioBase64 != null && audioBase64.isNotEmpty;
    // Always let Gemini transcribe the full m4a when we have one.
    // Do NOT pass partial on-device STT — that was truncating YOU SAID.
    final transcriptForScore = '';

    if (!hasClip && mounted) {
      AppSnackBar.showInfo(
        context,
        Platform.isIOS
            ? 'No usable audio on this device. On Simulator the mic is often silent — try a real iPhone, or check Mic permission.'
            : 'No usable audio was captured. Check microphone permission and try again.',
      );
    }

    debugPrint(
      '[Recording] finish bytes=$audioBytes heard=$_heardRealAudio '
      'hasClip=$hasClip',
    );

    await HakkiriLoadingOverlay.run(
      context,
      message: hasClip
          ? 'Transcribing your answer…'
          : 'Scoring your answer…',
      detail: hasClip
          ? 'Saving playback and scoring structure, pace, and fillers.'
          : 'Matching your answer to the prompt — almost there.',
      action: () => state.evaluateCurrentSession(
        transcript: transcriptForScore,
        durationSeconds: spoken,
        conversationMode: 'single',
        localAudioTempPath: hasClip ? audioPath : null,
        audioBase64: widget.isGuestTrial ? null : audioBase64,
        audioMimeType: 'audio/mp4',
      ),
    );

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => FeedbackScreen(isGuestTrial: widget.isGuestTrial),
      ),
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
    Widget body;
    if (!_promptReady) {
      final state = Provider.of<AppStateProvider>(context, listen: false);
      body = QuestionLoadingShimmer(
        activityName: state.selectedActivity?.name,
        onBack: () => unawaited(_onBack()),
      );
    } else {
      switch (_stage) {
        case ExerciseStage.wordByWordReveal:
          body = _buildWordByWordRevealScreen();
        case ExerciseStage.countdown5s:
          body = _buildCountdown5sScreen();
        case ExerciseStage.recordingScreen:
          body = _buildRecordingScreen();
      }
    }
    return PopScope(
      canPop: !widget.isGuestTrial,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && widget.isGuestTrial) {
          unawaited(_onBack());
        }
      },
      child: body,
    );
  }

  // =============================================================
  // SCREEN 1: WORD-BY-WORD REVEAL (doc_images/img_0.png)
  // =============================================================
  (IconData, String) _activityTagParts() {
    final state = Provider.of<AppStateProvider>(context, listen: false);
    final activity = state.selectedActivity;
    final slug = activity?.slug ?? 'think_fast';
    final name = (activity?.name ?? 'Think Fast').toUpperCase();
    final icon = switch (slug) {
      'cut_it_in_half' => Icons.content_cut_rounded,
      'debate_me' || 'debate' => Icons.forum_outlined,
      'one_minute_expert' => Icons.school_outlined,
      'explain_it_simply' => Icons.lightbulb_outline_rounded,
      'storytelling_gym' => Icons.auto_stories_outlined,
      'connect_the_dots' => Icons.hub_rounded,
      _ => Icons.bolt_rounded,
    };
    return (icon, name);
  }

  Widget _buildActivityTagBadge({bool boxed = false}) {
    final (tagIcon, activityName) = _activityTagParts();
    final icon = Icon(tagIcon, color: const Color(0xFF2563EB), size: 22);
    return Row(
      children: [
        if (boxed)
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFDBEAFE), width: 1),
            ),
            child: icon,
          )
        else
          icon,
        SizedBox(width: boxed ? 10 : 8),
        Text(
          activityName,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildWordByWordRevealScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBF9),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Button
              GestureDetector(
                onTap: () => unawaited(_onBack()),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Icon(
                    Icons.chevron_left_rounded,
                    color: Color(0xFF0F172A),
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              _buildActivityTagBadge(),
              const SizedBox(height: 20),

              // Question revealed word-by-word with karaoke style highlight & scale transition
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 10,
                        children: List.generate(_words.length, (index) {
                          final word = _words[index];
                          final isRevealed = index < _revealedWordCount;
                          final isCurrentWord =
                              index == _revealedWordCount - 1 && _promptSpeaking;

                          Color wordColor;
                          if (!isRevealed) {
                            wordColor = const Color(0xFFCBD5E1)
                                .withValues(alpha: 0.45);
                          } else if (isCurrentWord) {
                            wordColor = const Color(0xFF2563EB);
                          } else {
                            wordColor = const Color(0xFF0F172A);
                          }

                          return AnimatedScale(
                            scale: isCurrentWord ? 1.04 : 1.0,
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeOutCubic,
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 280),
                              curve: Curves.easeOutCubic,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: wordColor,
                                letterSpacing: -0.6,
                                height: 1.25,
                              ),
                              child: Text(word),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
              ActionPillButton(
                label: 'Skip to recording',
                onTap: _skipPrepToRecording,
              ),
              const SizedBox(height: 8),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Button
              GestureDetector(
                onTap: () => unawaited(_onBack()),
                child: const Icon(
                  Icons.chevron_left_rounded,
                  color: Color(0xFF0F172A),
                  size: 32,
                ),
              ),
              const SizedBox(height: 24),

              _buildActivityTagBadge(boxed: true),
              const SizedBox(height: 12),

              if (_isCutInHalf)
                // Readable passage size first; timer uses leftover space (capped).
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final wordCount = _promptHeadline
                          .split(RegExp(r'\s+'))
                          .where((w) => w.isNotEmpty)
                          .length;
                      // Slightly smaller type only for very long passages.
                      final passageSize = wordCount > 100
                          ? 16.0
                          : wordCount > 70
                              ? 17.5
                              : 19.0;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CUT THIS TEXT',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: Color(0xFF2563EB),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.4,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _promptHeadline,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: passageSize,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                              letterSpacing: -0.25,
                              height: 1.38,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, timerBox) {
                                // Cap timer so short passages don't look tiny vs a giant ring.
                                final timerSize = math
                                    .min(
                                      timerBox.maxWidth * 0.62,
                                      timerBox.maxHeight * 0.88,
                                    )
                                    .clamp(120.0, 188.0);
                                final numberSize =
                                    (timerSize * 0.30).clamp(32.0, 54.0);
                                final labelSize =
                                    (timerSize * 0.052).clamp(9.0, 11.0);
                                return Center(
                                  child: SizedBox(
                                    width: timerSize,
                                    height: timerSize,
                                    child: AnimatedBuilder(
                                      animation: _prepArcController,
                                      builder: (context, child) {
                                        return CustomPaint(
                                          painter: _CountdownCirclePainter(
                                            progress: 1.0 -
                                                _prepArcController.value,
                                          ),
                                          child: Center(
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: timerSize * 0.14,
                                              ),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    '$_prepSecondsRemaining',
                                                    style: TextStyle(
                                                      fontFamily: 'Inter',
                                                      fontSize: numberSize,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      color: const Color(
                                                          0xFF0F172A),
                                                      letterSpacing: -1.0,
                                                      height: 1.0,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    'SEC TO READ',
                                                    textAlign: TextAlign.center,
                                                    maxLines: 1,
                                                    softWrap: false,
                                                    style: TextStyle(
                                                      fontFamily: 'Inter',
                                                      fontSize: labelSize,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      letterSpacing: 1.1,
                                                      color: const Color(
                                                          0xFF64748B),
                                                      height: 1.0,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                )
              else ...[
                _buildPromptHeadlineRichText(),
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
              ActionPillButton(
                label: 'Stop clock · Start recording',
                onTap: _skipPrepToRecording,
              ),
              const SizedBox(height: 8),
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
    final activityTitle = _activityTagParts().$2;

    return Scaffold(
      backgroundColor: const Color(0xFF0B101D),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar: back + selected drill name (not hardcoded Think Fast)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => unawaited(_onBack()),
                        child: const Icon(
                          Icons.chevron_left_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          activityTitle,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: Color(0xFFA0A3B5),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.6,
                          ),
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

              // Cut It In Half shows a passage to compress, not a Q&A question.
              Text(
                Provider.of<AppStateProvider>(context, listen: false)
                            .selectedActivity
                            ?.slug ==
                        'cut_it_in_half'
                    ? 'CUT THIS TEXT'
                    : 'YOUR QUESTION',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF818CF8),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 8),

              // Passage / question — keep CIH size stable (same as read screen).
              Text(
                _promptHeadline,
                maxLines: _isCutInHalf ? 8 : 6,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: _isCutInHalf ? 15.5 : 24,
                  fontWeight: _isCutInHalf ? FontWeight.w600 : FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: _isCutInHalf ? -0.2 : -0.6,
                  height: _isCutInHalf ? 1.35 : 1.25,
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
  /// Cut It In Half passages use a smaller readable size (not a short question).
  Widget _buildPromptHeadlineRichText() {
    final words = _promptHeadline.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final isLongPassage = words.length > 28;
    final fontSize = isLongPassage ? 17.0 : 27.0;
    final weight = isLongPassage ? FontWeight.w700 : FontWeight.w900;
    if (words.isEmpty) {
      return Text(
        'Ready when you are.',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: fontSize,
          fontWeight: weight,
          color: const Color(0xFF0F172A),
          letterSpacing: -0.6,
          height: 1.22,
        ),
      );
    }
    // Long CIH passages: show full text plainly so the user can read and cut it.
    if (isLongPassage) {
      return Text(
        _promptHeadline,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: fontSize,
          fontWeight: weight,
          color: const Color(0xFF0F172A),
          letterSpacing: -0.2,
          height: 1.35,
        ),
      );
    }
    final highlightCount = words.length <= 3 ? words.length : 3;
    final head = words.sublist(0, words.length - highlightCount).join(' ');
    final tail = words.sublist(words.length - highlightCount).join(' ');
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: fontSize,
          fontWeight: weight,
          color: const Color(0xFF0F172A),
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

