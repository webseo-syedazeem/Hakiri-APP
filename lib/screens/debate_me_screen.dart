import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';

import '../core/services/analytics_service.dart';
import '../core/services/hakkiri_api_service.dart';
import '../core/services/ios_drill_recorder.dart';
import '../core/services/session_audio_store.dart';
import '../models/session_model.dart';
import '../providers/app_state_provider.dart';
import '../widgets/action_pill_button.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/blue_accent_rays.dart';
import '../widgets/hakkiri_loading_overlay.dart';
import '../widgets/mic_reactive_waveform.dart';
import 'feedback_screen.dart';
import 'paywall_screen.dart';

/// Guided Debate Me (client 6-step flow):
/// 1. Overview → 2. Prompt + think → 3. Opening record →
/// 4. AI pushback + prep → 5. Rebuttal record → 6. FeedbackScreen
class DebateMeScreen extends StatefulWidget {
  final String? topic;

  /// When true (from Activity Detail Begin), skip in-screen overview.
  final bool startAtPrompt;

  /// Guest plan free try — after feedback / leave, go to IAP.
  final bool isGuestTrial;

  const DebateMeScreen({
    super.key,
    this.topic,
    this.startAtPrompt = false,
    this.isGuestTrial = false,
  });

  @override
  State<DebateMeScreen> createState() => _DebateMeScreenState();
}

class _DebateMeScreenState extends State<DebateMeScreen> {
  int _currentStep = 1;

  Timer? _countdownTimer;
  Timer? _topicRevealTimer;
  Timer? _pushbackRevealTimer;
  static const _karaokeMs = 400;
  int _thinkSecondsRemaining = 10;
  int _openingSecondsRemaining = 60;
  int _prepSecondsRemaining = 10;
  int _rebuttalSecondsRemaining = 60;
  static const _openingTotal = 60;
  static const _rebuttalTotal = 60;

  /// Word-by-word highlight for assigned topic (no voice).
  List<String> _topicWords = const [];
  int _topicRevealedCount = 0;
  bool _topicSpeaking = false;
  bool _thinkTimerStarted = false;

  List<String> _pushbackWords = const [];
  int _pushbackRevealedCount = 0;
  bool _pushbackRevealing = false;

  bool _isAssessingPart1 = true;
  bool _busy = false;

  late String _topic;
  String _pushbackQuote =
      "That still leaves a gap in the claim you just made. "
      "If a senior stakeholder rejected it, what evidence would you use next?";

  final AudioRecorder _audioRecorder = AudioRecorder();
  final ValueNotifier<double> _micLevel = ValueNotifier<double>(0.12);
  StreamSubscription<Amplitude>? _ampSub;
  String? _audioTempPath;
  bool _recorderLive = false;
  String _openingTranscript = '';
  String? _openingAudioBase64;
  String? _openingAudioPath;
  int _openingSpokenSeconds = 0;
  int _rebuttalSpokenSeconds = 0;

  @override
  void initState() {
    super.initState();
    _topic = widget.topic?.trim().isNotEmpty == true
        ? widget.topic!.trim()
        : "Should companies require employees to work in the office three days a week?";
    AnalyticsService.instance.logScreenView(screenName: 'DebateMe_Overview');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = context.read<AppStateProvider>();
      final fromPrompt = state.selectedPrompt?.promptText.trim();
      if ((widget.topic == null || widget.topic!.trim().isEmpty) &&
          fromPrompt != null &&
          fromPrompt.isNotEmpty) {
        setState(() => _topic = fromPrompt);
      }
      if (widget.startAtPrompt) {
        _goToStep(2);
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _topicRevealTimer?.cancel();
    _pushbackRevealTimer?.cancel();
    unawaited(_ampSub?.cancel());
    unawaited(_audioRecorder.dispose());
    _micLevel.dispose();
    super.dispose();
  }

  void _startTopicSpeakAndReveal() {
    _topicRevealTimer?.cancel();

    _topicWords =
        _topic.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    _topicRevealedCount = _topicWords.isEmpty ? 0 : 1;
    _topicSpeaking = true;
    _thinkTimerStarted = false;
    if (mounted) setState(() {});
    if (_topicWords.isEmpty) {
      _topicSpeaking = false;
      _beginThinkCountdown();
      return;
    }

    _topicRevealTimer = Timer.periodic(const Duration(milliseconds: _karaokeMs), (t) {
      if (!mounted || _currentStep != 2 || !_topicSpeaking) {
        t.cancel();
        return;
      }
      if (_topicRevealedCount >= _topicWords.length) {
        t.cancel();
        setState(() => _topicSpeaking = false);
        _beginThinkCountdown();
        return;
      }
      setState(() => _topicRevealedCount++);
    });
  }

  void _beginThinkCountdown() {
    if (_thinkTimerStarted || _currentStep != 2) return;
    _thinkTimerStarted = true;
    _thinkSecondsRemaining = 10;
    _countdownTimer?.cancel();
    if (mounted) setState(() {});
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_thinkSecondsRemaining > 1) {
        setState(() => _thinkSecondsRemaining--);
      } else {
        _countdownTimer?.cancel();
        _goToStep(3);
      }
    });
  }

  Future<bool> _startRecorder({int attempt = 0}) async {
    _recorderLive = false;
    if (Platform.isIOS) {
      try {
        final granted = await IosDrillRecorder.instance.hasPermission();
        if (!granted) {
          if (mounted) {
            AppSnackBar.showError(
              context,
              'Microphone permission is needed to record your debate.',
            );
          }
          return false;
        }
        await IosDrillRecorder.instance.cancel();
        final path = await IosDrillRecorder.instance.start(
          onAmplitude: (level) {
            _micLevel.value = level;
          },
        );
        _audioTempPath = path;
        _recorderLive = true;
        if (mounted) setState(() {});
        return true;
      } catch (_) {
        _audioTempPath = null;
        _recorderLive = false;
        if (attempt < 1) {
          await Future<void>.delayed(const Duration(milliseconds: 450));
          return _startRecorder(attempt: attempt + 1);
        }
        if (mounted) {
          AppSnackBar.showError(
            context,
            'Could not start the mic. Tap Finish and try again.',
          );
        }
        return false;
      }
    }
    try {
      // hasPermission() also requests on iOS/Android.
      final granted = await _audioRecorder.hasPermission();
      if (!granted) {
        if (mounted) {
          AppSnackBar.showError(
            context,
            'Microphone permission is needed to record your debate.',
          );
        }
        return false;
      }

      // Stop any leftover session before starting a new file.
      try {
        if (await _audioRecorder.isRecording()) {
          await _audioRecorder.stop();
        }
      } catch (_) {}

      _audioTempPath = await SessionAudioStore.instance.startTempPath();
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 64000,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: _audioTempPath!,
      );

      final live = await _audioRecorder.isRecording();
      if (!live) {
        throw StateError('Recorder started but is not live');
      }

      await _ampSub?.cancel();
      _ampSub = _audioRecorder
          .onAmplitudeChanged(const Duration(milliseconds: 55))
          .listen((amp) {
        final raw = ((amp.current + 50) / 50).clamp(0.0, 1.0);
        _micLevel.value =
            math.pow(raw, 0.72).toDouble().clamp(0.08, 1.0);
      });
      _recorderLive = true;
      if (mounted) setState(() {});
      return true;
    } catch (_) {
      _audioTempPath = null;
      _recorderLive = false;
      // Mic start race: retry once after a short pause.
      if (attempt < 1) {
        await Future<void>.delayed(const Duration(milliseconds: 450));
        return _startRecorder(attempt: attempt + 1);
      }
      if (mounted) {
        AppSnackBar.showError(
          context,
          'Could not start the mic. Tap Finish and try again.',
        );
      }
      return false;
    }
  }

  Future<String?> _stopRecorder() async {
    await _ampSub?.cancel();
    _ampSub = null;
    _recorderLive = false;
    if (Platform.isIOS) {
      final stopped = await IosDrillRecorder.instance.stop();
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

  Future<String?> _readAudioBase64(String? path) async {
    if (path == null || path.isEmpty) return null;
    try {
      final bytes = await File(path).readAsBytes();
      // ~90s AAC @ 64kbps is well under 1MB; allow headroom for longer takes.
      if (bytes.isEmpty || bytes.length > 3 * 1024 * 1024) return null;
      return base64Encode(bytes);
    } catch (_) {
      return null;
    }
  }

  String _clipPushback(String raw) {
    var t = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (t.isEmpty) return _topicAwareFallbackPushback();
    final two = RegExp(r'^(.+?[.!?]\s+.+?[.!?])(?:\s|$)').firstMatch(t) ??
        RegExp(r'^(.+?[.!?])(?:\s|$)').firstMatch(t);
    if (two != null) t = two.group(1)!.trim();
    final words = t.split(' ').where((w) => w.isNotEmpty).toList();
    if (words.length > 40) t = words.take(40).join(' ');
    if (t.length > 280) t = '${t.substring(0, 277)}…';
    return t;
  }

  String _topicAwareFallbackPushback() {
    return "That still leaves a gap in the claim you just made. "
        "If a senior stakeholder rejected it, what evidence would you use next?";
  }

  void _goToStep(int step) {
    _countdownTimer?.cancel();
    setState(() => _currentStep = step);

    AnalyticsService.instance.logScreenView(
      screenName: 'DebateMe_Step$step',
    );

    if (step == 2) {
      _thinkSecondsRemaining = 10;
      _startTopicSpeakAndReveal();
    } else if (step == 3) {
      unawaited(_enterOpeningRecord());
    } else if (step == 4) {
      _prepSecondsRemaining = 10;
      _startPushbackReveal();
    } else if (step == 5) {
      _pushbackRevealTimer?.cancel();
      unawaited(_enterRebuttalRecord());
    }
  }

  void _startPushbackReveal() {
    _pushbackRevealTimer?.cancel();
    _countdownTimer?.cancel();
    _pushbackQuote = _clipPushback(_pushbackQuote);
    _pushbackWords =
        _pushbackQuote.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    _pushbackRevealedCount = _pushbackWords.isEmpty ? 0 : 1;
    _pushbackRevealing = true;
    _prepSecondsRemaining = 10;
    if (mounted) setState(() {});
    if (_pushbackWords.length <= 1) {
      _pushbackRevealing = false;
      _startPushbackPrep();
      return;
    }
    _pushbackRevealTimer =
        Timer.periodic(const Duration(milliseconds: _karaokeMs), (t) {
      if (!mounted || _currentStep != 4 || !_pushbackRevealing) {
        t.cancel();
        return;
      }
      if (_pushbackRevealedCount >= _pushbackWords.length) {
        t.cancel();
        setState(() => _pushbackRevealing = false);
        _startPushbackPrep();
        return;
      }
      setState(() => _pushbackRevealedCount++);
    });
  }

  Future<void> _startPushbackPrep() async {
    if (!mounted || _currentStep != 4) return;
    _prepSecondsRemaining = 10;
    if (mounted) setState(() {});
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || _currentStep != 4) {
        t.cancel();
        return;
      }
      if (_prepSecondsRemaining > 1) {
        setState(() => _prepSecondsRemaining--);
      } else {
        t.cancel();
        _goToStep(5);
      }
    });
  }

  Future<void> _enterOpeningRecord() async {
    _topicRevealTimer?.cancel();
    if (!mounted || _currentStep != 3) return;

    _openingSecondsRemaining = _openingTotal;
    await _startRecorder();
    if (!mounted || _currentStep != 3) return;

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_openingSecondsRemaining > 1) {
        setState(() => _openingSecondsRemaining--);
      } else {
        _countdownTimer?.cancel();
        unawaited(_finishOpening());
      }
    });
  }

  Future<void> _enterRebuttalRecord() async {
    if (!mounted || _currentStep != 5) return;

    _rebuttalSecondsRemaining = _rebuttalTotal;
    await _startRecorder();
    if (!mounted || _currentStep != 5) return;

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_rebuttalSecondsRemaining > 1) {
        setState(() => _rebuttalSecondsRemaining--);
      } else {
        _countdownTimer?.cancel();
        unawaited(_finishRebuttal());
      }
    });
  }

  Future<void> _finishOpening() async {
    if (_busy) return;
    _busy = true;
    _countdownTimer?.cancel();
    _openingSpokenSeconds =
        (_openingTotal - _openingSecondsRemaining).clamp(1, _openingTotal);

    final path = await _stopRecorder();
    // Keep opening clip for transcript recovery + feedback playback.
    _openingAudioPath = path;
    final audioBase64 = await _readAudioBase64(path);
    _openingAudioBase64 = audioBase64;
    if (!mounted) {
      _busy = false;
      return;
    }

    final hasClip = audioBase64 != null && audioBase64.isNotEmpty;
    if (!hasClip && mounted) {
      AppSnackBar.showInfo(
        context,
        'No opening audio was captured. Check mic permission and try again.',
      );
    }

    final state = context.read<AppStateProvider>();
    final api = HakkiriApiService.instance;
    var gotPushback = false;

    Future<void> requestPushback({required bool includeAudio}) async {
      final data = await api.debatePushback({
        'topic': _topic,
        'prompt_text': _topic,
        'career_context': state.careerTypeLabel,
        if (_openingTranscript.isNotEmpty)
          'opening_transcript': _openingTranscript,
        if (includeAudio && hasClip) ...{
          'audio_base64': audioBase64,
          'audio_mime_type': 'audio/mp4',
        },
      });
      final transcript = (data['transcript'] ?? '').toString().trim();
      if (transcript.isNotEmpty) _openingTranscript = transcript;
      final push = (data['pushback'] ?? '').toString().trim();
      if (push.isNotEmpty) {
        _pushbackQuote = _clipPushback(push);
        gotPushback = true;
      }
    }

    try {
      if (state.isLoggedIn && api.isLoggedIn) {
        await HakkiriLoadingOverlay.run(
          context,
          message: 'Hakkiri is crafting a challenge…',
          detail: hasClip
              ? 'Listening to your opening, then pushing back.'
              : 'Building a challenge from your topic…',
          action: () async {
            // Prefer audio so pushback is grounded in what the user said.
            try {
              await requestPushback(includeAudio: hasClip);
            } catch (_) {
              // Audio STT can fail; still try topic-only so the drill continues.
              if (hasClip) {
                await requestPushback(includeAudio: false);
              } else {
                rethrow;
              }
            }
            // Empty transcript after audio pass → one more topic+transcript retry.
            if (_openingTranscript.isEmpty && hasClip && !gotPushback) {
              await requestPushback(includeAudio: false);
            }
          },
        );
      }
    } catch (_) {
      // Fall through to topic-aware local challenge below.
    }

    if (!gotPushback) {
      _pushbackQuote = _topicAwareFallbackPushback();
      if (mounted) {
        AppSnackBar.showInfo(
          context,
          'Could not hear your opening clearly. Pushback is based on the topic — try speaking closer to the mic next time.',
        );
      }
    }

    if (!mounted) {
      _busy = false;
      return;
    }
    _busy = false;
    _goToStep(4);
  }

  Future<void> _finishRebuttal() async {
    if (_busy) return;
    _busy = true;
    _countdownTimer?.cancel();
    _rebuttalSpokenSeconds =
        (_rebuttalTotal - _rebuttalSecondsRemaining).clamp(1, _rebuttalTotal);

    final path = await _stopRecorder();
    final audioBase64 = await _readAudioBase64(path);
    if (!mounted) {
      _busy = false;
      return;
    }

    final state = context.read<AppStateProvider>();
    final api = HakkiriApiService.instance;

    PracticeSessionRecord? scoredSession;
    try {
      await HakkiriLoadingOverlay.run(
        context,
        message: 'Scoring your debate…',
        detail: 'Opening, pushback response, and delivery.',
        action: () async {
          // Recover opening words if pushback step never returned a transcript.
          if (_openingTranscript.isEmpty &&
              (_openingAudioBase64 ?? '').isNotEmpty &&
              state.isLoggedIn &&
              api.isLoggedIn) {
            try {
              final data = await api.debatePushback({
                'topic': _topic,
                'prompt_text': _topic,
                'career_context': state.careerTypeLabel,
                'audio_base64': _openingAudioBase64,
                'audio_mime_type': 'audio/mp4',
              });
              final recovered =
                  (data['transcript'] ?? '').toString().trim();
              if (recovered.isNotEmpty) {
                _openingTranscript = recovered;
              }
              final push = (data['pushback'] ?? '').toString().trim();
              if (push.isNotEmpty) _pushbackQuote = _clipPushback(push);
            } catch (_) {}
          }

          final openingText = _openingTranscript.isNotEmpty
              ? _openingTranscript
              : ((_openingAudioBase64 ?? '').isNotEmpty
                  ? '(Opening was recorded — transcript unavailable.)'
                  : '(No opening captured.)');

          final combinedTranscript = [
            'Opening argument:',
            openingText,
            '',
            'Hakkiri pushback:',
            _pushbackQuote,
            '',
            'Rebuttal:',
          ].join('\n');

          final turns = <ConversationTurn>[
            ConversationTurn(role: 'user', text: openingText),
            ConversationTurn(role: 'coach', text: _pushbackQuote),
            const ConversationTurn(
              role: 'user',
              text: '(rebuttal recorded)',
            ),
          ];

          final totalSpoken =
              (_openingSpokenSeconds + _rebuttalSpokenSeconds).clamp(5, 600);

          await state.evaluateCurrentSession(
            transcript: combinedTranscript,
            durationSeconds: totalSpoken,
            conversationMode: 'back_and_forth',
            conversationTurns: turns,
            localAudioTempPath: path,
            localOpeningAudioTempPath: _openingAudioPath,
            audioBase64: audioBase64,
            audioMimeType: 'audio/mp4',
          );
          final latest = state.latestSession;
          if (latest != null) {
            scoredSession = latest;
          }
        },
      );
    } catch (_) {
      _busy = false;
      if (mounted) {
        AppSnackBar.showError(
          context,
          'Could not score this debate. Please try again.',
        );
      }
      return;
    }

    if (!mounted) {
      _busy = false;
      return;
    }
    _busy = false;
    final sessionForUi = scoredSession ?? state.latestSession;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => FeedbackScreen(
          session: sessionForUi,
          isGuestTrial: widget.isGuestTrial,
        ),
      ),
    );
  }

  Future<void> _exitGuestTrialToPaywall() async {
    final state = context.read<AppStateProvider>();
    await state.markGuestReachedPaywall();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const PaywallScreen()),
      (route) => false,
    );
  }

  /// While the guided debate is running, confirm before leaving.
  /// Confirm → Activity Detail (Begin exercise) screen.
  Future<void> _onBack() async {
    if (_busy) return;

    if (widget.isGuestTrial) {
      await _exitGuestTrialToPaywall();
      return;
    }

    // In-screen overview (step 1) can leave without a dialog.
    if (_currentStep <= 1 && !widget.startAtPrompt) {
      Navigator.maybePop(context);
      return;
    }

    final leave = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final dark = _currentStep == 3 || _currentStep == 5;
        return AlertDialog(
          backgroundColor:
              dark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Cancel debate?',
            style: TextStyle(
              color: dark ? Colors.white : const Color(0xFF0F172A),
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          content: Text(
            'Do you want to go back? Your current debate will end and you’ll return to Begin exercise.',
            style: TextStyle(
              color: dark
                  ? const Color(0xFFCBD5E1)
                  : const Color(0xFF475569),
              fontWeight: FontWeight.w600,
              height: 1.4,
              fontSize: 14.5,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Stay',
                style: TextStyle(
                  color: dark
                      ? const Color(0xFF93C5FD)
                      : const Color(0xFF2563EB),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: dark
                    ? Colors.white
                    : const Color(0xFF0F172A),
                foregroundColor: dark
                    ? const Color(0xFF0F172A)
                    : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              child: const Text(
                'Go back',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        );
      },
    );

    if (leave != true || !mounted) return;
    await _exitDebateToBeginScreen();
  }

  Future<void> _exitDebateToBeginScreen() async {
    _countdownTimer?.cancel();
    _topicRevealTimer?.cancel();
    _pushbackRevealTimer?.cancel();
    if (_currentStep == 3 || _currentStep == 5) {
      await _stopRecorder();
    }
    if (!mounted) return;
    // Pop back to Activity Detail (Begin exercise).
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkStep = _currentStep == 3 || _currentStep == 5;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || _busy) return;
        await _onBack();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDarkStep ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDarkStep ? Brightness.dark : Brightness.light,
        systemNavigationBarColor:
            isDarkStep ? const Color(0xFF070F22) : Colors.white,
        systemNavigationBarIconBrightness:
            isDarkStep ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor:
            isDarkStep ? const Color(0xFF070F22) : Colors.white,
        body: SafeArea(
          child: Stack(
            children: [
              // Light ambient background blobs for light steps
              if (!isDarkStep) ...[
                Positioned(
                  top: -50,
                  right: -40,
                  child: IgnorePointer(
                    child: Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFBFDBFE).withValues(alpha: 0.45),
                            const Color(0xFFEFF6FF).withValues(alpha: 0.15),
                            const Color(0x00FFFFFF),
                          ],
                          stops: const [0.0, 0.55, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 80,
                  left: -50,
                  child: IgnorePointer(
                    child: Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFDBEAFE).withValues(alpha: 0.35),
                            const Color(0x00FFFFFF),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],

              // Active step view
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                child: _buildStepContent(),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 1:
        return _buildStep1Overview();
      case 2:
        return _buildStep2PromptThink();
      case 3:
        return _buildStep3OpeningRecord();
      case 4:
        return _buildStep4CoachPushback();
      case 5:
        return _buildStep5RebuttalRecord();
      case 6:
      default:
        return _buildStep6Feedback();
    }
  }

  // ===========================================================================
  // STEP 1: OVERVIEW (Rules, Timeline & Response Strategy)
  // ===========================================================================
  Widget _buildStep1Overview() {
    return Column(
      key: const ValueKey(1),
      children: [
        _buildTopBar(showBack: true),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                const Text(
                  '7. DEBATE ME',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Debate Me.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Transform.translate(
                      offset: const Offset(0, -6),
                      child: const BlueAccentRays(size: 24),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Take a position, handle pushback, and respond with a clear, confident counterpoint.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),

                // 3D Illustration
                Center(
                  child: Image.asset(
                    'assets/images/exercise_3d_debate.png',
                    height: 160,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 14),

                // HOW IT WORKS card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'HOW IT WORKS',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTimelineStep(
                              '1. Prompt',
                              "You're assigned\na topic.",
                              Icons.description_outlined,
                            ),
                            _buildTimelineDivider(),
                            _buildTimelineStep(
                              '2. Think',
                              'You have\n10 seconds.',
                              Icons.timer_outlined,
                            ),
                            _buildTimelineDivider(),
                            _buildTimelineStep(
                              '3. Opening',
                              'Speak for\n60 seconds.',
                              Icons.mic_none_outlined,
                            ),
                            _buildTimelineDivider(),
                            _buildTimelineStep(
                              '4. Pushback',
                              'Hakkiri challenges\nyour point.',
                              Icons.chat_bubble_outline_rounded,
                            ),
                            _buildTimelineDivider(),
                            _buildTimelineStep(
                              '5. Rebuttal',
                              'Respond, then\nget feedback.',
                              Icons.insights_rounded,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // BUILD YOUR RESPONSE card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'BUILD YOUR RESPONSE',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStrategyPill(
                              number: '1',
                              label: 'State your\nposition',
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                          const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF94A3B8)),
                          Expanded(
                            child: _buildStrategyPill(
                              number: '2',
                              label: 'Give your\nreason',
                              color: const Color(0xFFF95B3D),
                            ),
                          ),
                          const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF94A3B8)),
                          Expanded(
                            child: _buildStrategyPill(
                              number: '3',
                              label: 'Counter the\nobjection',
                              color: const Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                ActionPillButton(
                  label: 'Begin exercise',
                  onTap: () => _goToStep(2),
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // STEP 2: PROMPT + 10s THINK TIME
  // ===========================================================================
  Widget _buildStep2PromptThink() {
    return Column(
      key: const ValueKey(2),
      children: [
        _buildTopBar(showBack: true),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                const Text(
                  'DEBATE ME • OPENING',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Your prompt.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Transform.translate(
                      offset: const Offset(0, -6),
                      child: const BlueAccentRays(size: 24),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'You\'ve been assigned a topic. Take 10 seconds to plan your opening.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 18),

                // Assigned Topic Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.05),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Color(0xFFEFF6FF),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.record_voice_over_rounded, size: 16, color: Color(0xFF2563EB)),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'ASSIGNED TOPIC',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Word-by-word highlight (no voice).
                      if (_topicWords.isEmpty)
                        Text(
                          _topic,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            height: 1.35,
                          ),
                        )
                      else
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: List.generate(_topicWords.length, (index) {
                            final word = _topicWords[index];
                            final isRevealed = index < _topicRevealedCount;
                            final isCurrent = index == _topicRevealedCount - 1 &&
                                _topicSpeaking;
                            Color wordColor;
                            if (!isRevealed) {
                              wordColor = const Color(0xFFCBD5E1)
                                  .withValues(alpha: 0.5);
                            } else if (isCurrent) {
                              wordColor = const Color(0xFF2563EB);
                            } else {
                              wordColor = const Color(0xFF0F172A);
                            }
                            return AnimatedScale(
                              scale: isCurrent ? 1.06 : 1.0,
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOutCubic,
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOutCubic,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w800,
                                  color: wordColor,
                                  height: 1.35,
                                ),
                                child: Text(word),
                              ),
                            );
                          }),
                        ),
                    ],
                  ),
                ),
                const Spacer(flex: 2),

                // Circular Countdown Timer (10s) — starts after topic is spoken.
                Center(
                  child: Opacity(
                    opacity: _thinkTimerStarted ? 1 : 0.45,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 140,
                          height: 140,
                          child: CircularProgressIndicator(
                            value: _thinkTimerStarted
                                ? _thinkSecondsRemaining / 10.0
                                : 1.0,
                            strokeWidth: 8,
                            backgroundColor: const Color(0xFFEFF6FF),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF2563EB),
                            ),
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _thinkTimerStarted
                                  ? '$_thinkSecondsRemaining'
                                  : '—',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 44,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                                letterSpacing: -1.0,
                              ),
                            ),
                            Text(
                              _thinkTimerStarted
                                  ? 'seconds to think'
                                  : 'read first…',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(flex: 3),

                // QUICK TIPS Card
                const Text(
                  'QUICK TIPS',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildTipCard(Icons.description_outlined, 'State your view')),
                    const SizedBox(width: 8),
                    Expanded(child: _buildTipCard(Icons.lightbulb_outline_rounded, 'Give one reason')),
                    const SizedBox(width: 8),
                    Expanded(child: _buildTipCard(Icons.chat_bubble_outline_rounded, 'Keep it clear')),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
          child: ActionPillButton(
            label: _topicSpeaking
                ? 'Stop clock · Start recording'
                : 'Start recording',
            onTap: () {
              _topicRevealTimer?.cancel();
              _countdownTimer?.cancel();
              _goToStep(3);
            },
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // STEP 3: YOUR OPENING (Dark Audio Recording)
  // ===========================================================================
  Widget _buildStep3OpeningRecord() {
    final mins = _openingSecondsRemaining ~/ 60;
    final secs = _openingSecondsRemaining % 60;
    final timeStr = '$mins:${secs < 10 ? '0' : ''}$secs';

    return Column(
      key: const ValueKey(3),
      children: [
        _buildDarkTopBar('DEBATE ME • OPENING'),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 8),

                // Topic card — full question, no truncation
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFF2563EB),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.chat_bubble_rounded, size: 14, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _topic,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Opening argument',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const Spacer(flex: 2),

                // Circular Timer Ring
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 160,
                      height: 160,
                      child: CircularProgressIndicator(
                        value: _openingSecondsRemaining / _openingTotal,
                        strokeWidth: 8,
                        backgroundColor: const Color(0xFF1E293B),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          timeStr,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -1.0,
                          ),
                        ),
                        const Text(
                          'left to speak',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Recording badge — reflects real mic state
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _recorderLive
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF94A3B8),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _recorderLive ? 'Recording' : 'Mic starting…',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _recorderLive
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Live mic waveform
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: Center(
                    child: MicReactiveWaveform(
                      active: _recorderLive,
                      barCount: 28,
                      width: 280,
                      height: 52,
                      color: const Color(0xFF38BDF8),
                      externalLevel: _micLevel,
                    ),
                  ),
                ),
                const Spacer(flex: 3),

                // Lightbulb tip card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF1E293B)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lightbulb_rounded, size: 20, color: Color(0xFF38BDF8)),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Take a position, then give one clear reason.',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
          child: ActionPillButton(
            label: 'Finish opening',
            onTap: _busy ? null : () => unawaited(_finishOpening()),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // STEP 4: HAKKIRI CHALLENGES YOUR POINT (AI Coach Pushback)
  // ===========================================================================
  Widget _buildStep4CoachPushback() {
    final wordCount = _pushbackWords.isNotEmpty
        ? _pushbackWords.length
        : _pushbackQuote.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    // Long pushback → shrink the prep timer so the quote stays readable.
    final longPushback = wordCount >= 28;
    final timerSize = longPushback ? 96.0 : 140.0;
    final timerStroke = longPushback ? 6.0 : 8.0;
    final timerNumberSize = longPushback ? 32.0 : 44.0;
    final timerLabelSize = longPushback ? 10.0 : 11.5;
    final quoteFontSize = longPushback ? 13.5 : 14.5;

    return Column(
      key: const ValueKey(4),
      children: [
        _buildTopBar(showBack: true),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                const Text(
                  'DEBATE ME • PUSHBACK',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Hakkiri challenges',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: longPushback ? 24 : 27,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F172A),
                        letterSpacing: -0.6,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'your point.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: longPushback ? 24 : 27,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF2563EB),
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Transform.translate(
                      offset: const Offset(0, -6),
                      child: const BlueAccentRays(size: 24),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // AI Coach Quote Box — flexible so long text isn't crushed.
                Flexible(
                  flex: longPushback ? 5 : 3,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(longPushback ? 14 : 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFBFDBFE), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEFF6FF),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.smart_toy_rounded, size: 16, color: Color(0xFF2563EB)),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Hakkiri says',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (_pushbackWords.isEmpty)
                            Text(
                              _pushbackQuote,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: quoteFontSize,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0F172A),
                                height: 1.45,
                              ),
                            )
                          else
                            Wrap(
                              spacing: 5,
                              runSpacing: 6,
                              children: List.generate(_pushbackWords.length, (index) {
                                final word = _pushbackWords[index];
                                final isRevealed = index < _pushbackRevealedCount;
                                final isCurrent = index ==
                                        _pushbackRevealedCount - 1 &&
                                    _pushbackRevealing;
                                Color wordColor;
                                if (!isRevealed) {
                                  wordColor = const Color(0xFFCBD5E1)
                                      .withValues(alpha: 0.5);
                                } else if (isCurrent) {
                                  wordColor = const Color(0xFF2563EB);
                                } else {
                                  wordColor = const Color(0xFF0F172A);
                                }
                                return AnimatedScale(
                                  scale: isCurrent ? 1.05 : 1.0,
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOutCubic,
                                  child: AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 220),
                                    curve: Curves.easeOutCubic,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: quoteFontSize,
                                      fontWeight: FontWeight.w700,
                                      color: wordColor,
                                      height: 1.45,
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
                ),
                SizedBox(height: longPushback ? 10 : 16),

                // Circular countdown timer — smaller when pushback text is long.
                Center(
                  child: Opacity(
                    opacity: _pushbackRevealing ? 0.45 : 1,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: timerSize,
                          height: timerSize,
                          child: CircularProgressIndicator(
                            value: _prepSecondsRemaining / 10.0,
                            strokeWidth: timerStroke,
                            backgroundColor: const Color(0xFFEFF6FF),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$_prepSecondsRemaining',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: timerNumberSize,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF0F172A),
                                letterSpacing: -1.0,
                              ),
                            ),
                            Text(
                              'seconds to prepare\nyour response',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: timerLabelSize,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: longPushback ? 10 : 16),

                // RESPONSE HINTS
                const Text(
                  'RESPONSE HINTS',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildTipCard(Icons.description_outlined, 'Acknowledge\nthe concern')),
                    const SizedBox(width: 8),
                    Expanded(child: _buildTipCard(Icons.check_circle_outline_rounded, 'Answer it\ndirectly')),
                    const SizedBox(width: 8),
                    Expanded(child: _buildTipCard(Icons.bar_chart_rounded, 'Reinforce\nyour position')),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
          child: ActionPillButton(
            label: _pushbackRevealing
                ? 'Stop clock · Start recording'
                : 'Start recording',
            onTap: () {
              _pushbackRevealTimer?.cancel();
              _countdownTimer?.cancel();
              _goToStep(5);
            },
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // STEP 5: YOUR REBUTTAL (Dark Audio Recording against AI Coach)
  // ===========================================================================
  Widget _buildStep5RebuttalRecord() {
    final mins = _rebuttalSecondsRemaining ~/ 60;
    final secs = _rebuttalSecondsRemaining % 60;
    final timeStr = '$mins:${secs < 10 ? '0' : ''}$secs';

    return Column(
      key: const ValueKey(5),
      children: [
        _buildDarkTopBar('DEBATE ME'),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 6),
                const Text(
                  'Give your rebuttal.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Respond to Hakkiri\'s challenge below.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 14),

                // Challenge Quote Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.chat_bubble_rounded, size: 14, color: Color(0xFF38BDF8)),
                          SizedBox(width: 8),
                          Text(
                            'HAKKIRI\'S CHALLENGE',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                              color: Color(0xFF38BDF8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _pushbackQuote,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFE2E8F0),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 2),

                // Circular Timer Ring
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 160,
                      height: 160,
                      child: CircularProgressIndicator(
                        value: _rebuttalSecondsRemaining / _rebuttalTotal,
                        strokeWidth: 8,
                        backgroundColor: const Color(0xFF1E293B),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          timeStr,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -1.0,
                          ),
                        ),
                        const Text(
                          'left to speak',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // REC indicator — real mic state
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _recorderLive
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF94A3B8),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _recorderLive ? 'REC' : 'Mic starting…',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _recorderLive
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: Center(
                    child: MicReactiveWaveform(
                      active: _recorderLive,
                      barCount: 28,
                      width: 280,
                      height: 52,
                      color: const Color(0xFF38BDF8),
                      externalLevel: _micLevel,
                    ),
                  ),
                ),
                const Spacer(flex: 3),

                // Tip Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF1E293B)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lightbulb_rounded, size: 20, color: Color(0xFF38BDF8)),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Address the risk, then defend your position.',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),

        // Warm white pill button matching mockup
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
          child: SizedBox(
            height: 56,
            width: double.infinity,
            child: Material(
              color: const Color(0xFFF1EFEA),
              borderRadius: BorderRadius.circular(30),
              elevation: 4,
              shadowColor: Colors.black.withValues(alpha: 0.3),
              child: InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: _busy ? null : () => unawaited(_finishRebuttal()),
                child: const Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Finish rebuttal',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 19, color: Color(0xFF1E293B)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // STEP 6: FEEDBACK & DUAL SCORING
  // ===========================================================================
  Widget _buildStep6Feedback() {
    return Column(
      key: const ValueKey(6),
      children: [
        _buildTopBar(showBack: false),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                const Text(
                  'DEBATE ME • FEEDBACK',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'See your feedback.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Transform.translate(
                      offset: const Offset(0, -6),
                      child: const BlueAccentRays(size: 24),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'See how clearly you argued and how well you handled pushback.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),

                // Overall Score Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.05),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF2563EB), width: 3),
                        ),
                        alignment: Alignment.center,
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: const TextSpan(
                            children: [
                              TextSpan(
                                text: '3.9\n',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F172A),
                                  height: 1.1,
                                ),
                              ),
                              TextSpan(
                                text: '/ 5',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Overall score',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'You argued clearly, handled pushback well, and stayed calm throughout.',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF64748B),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Detailed Score Metrics
                _buildMetricBar(Icons.shield_outlined, 'Argument strength', 4, 5),
                const SizedBox(height: 10),
                _buildMetricBar(Icons.lightbulb_outline_rounded, 'Clarity', 4, 5),
                const SizedBox(height: 10),
                _buildMetricBar(Icons.chat_bubble_outline_rounded, 'Response to pushback', 3, 5),
                const SizedBox(height: 10),
                _buildMetricBar(Icons.sentiment_satisfied_alt_rounded, 'Composure', 4, 5),
                const SizedBox(height: 16),

                // SPEECH METRICS
                const Text(
                  'SPEECH METRICS',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF10B981)),
                          SizedBox(width: 6),
                          Text(
                            'Fillers: Low',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF065F46),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.speed_rounded, size: 14, color: Color(0xFF2563EB)),
                          SizedBox(width: 6),
                          Text(
                            'Pace: Steady',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E40AF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // BOTH PARTS ASSESSED toggles
                const Text(
                  'BOTH PARTS ASSESSED',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildPartAssessedPill('1  Opening', true, _isAssessingPart1, () {
                      setState(() => _isAssessingPart1 = true);
                    }),
                    const SizedBox(width: 10),
                    _buildPartAssessedPill('2  Response', true, !_isAssessingPart1, () {
                      setState(() => _isAssessingPart1 = false);
                    }),
                  ],
                ),
                const SizedBox(height: 16),

                // What went well card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF16A34A)),
                          SizedBox(width: 6),
                          Text(
                            'What went well',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF166534),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Clear position and calm tone. You answered the challenge directly.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF166534),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Next time card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFED7AA)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFEA580C)),
                          SizedBox(width: 6),
                          Text(
                            'Next time',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF9A3412),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Make your evidence more specific and tighten your final sentence.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF9A3412),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
          child: ActionPillButton(
            label: 'Try again',
            onTap: () => _goToStep(1),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // HELPER COMPONENTS
  // ===========================================================================

  Widget _buildTopBar({required bool showBack}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (showBack)
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19, color: Color(0xFF0F172A)),
              onPressed: _onBack,
            )
          else
            const SizedBox(width: 48, height: 48),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildDarkTopBar(String badgeLabel) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19, color: Colors.white),
            onPressed: _onBack,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              badgeLabel,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: Color(0xFF38BDF8),
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildTimelineStep(String title, String desc, IconData icon) {
    return SizedBox(
      width: 118,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF2563EB)),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            textAlign: TextAlign.center,
            maxLines: 2,
            softWrap: true,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineDivider() {
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Container(
        width: 16,
        height: 1.5,
        color: const Color(0xFFCBD5E1),
        margin: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }

  Widget _buildStrategyPill({
    required String number,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
            height: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildTipCard(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF2563EB)),
          const SizedBox(height: 6),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBar(IconData icon, String label, int score, int max) {
    final progress = score / max;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF2563EB)),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              Text(
                '$score / $max',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2563EB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: const Color(0xFFEFF6FF),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartAssessedPill(String label, bool isDone, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.check_rounded,
              size: 14,
              color: isSelected ? Colors.white : const Color(0xFF475569),
            ),
          ],
        ),
      ),
    );
  }
}
