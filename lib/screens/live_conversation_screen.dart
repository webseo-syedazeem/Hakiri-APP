import 'dart:async';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/services/analytics_service.dart';
import '../core/services/hakkiri_api_service.dart';
import '../core/services/live_voice_service.dart';
import '../models/session_model.dart';
import '../providers/app_state_provider.dart';
import '../widgets/hakkiri_loading_overlay.dart';
import '../widgets/live_waveform_bars.dart';
import 'feedback_screen.dart';

class LiveConversationScreen extends StatefulWidget {
  const LiveConversationScreen({super.key});

  @override
  State<LiveConversationScreen> createState() => _LiveConversationScreenState();

  static String workSettingForCareer(String? careerType) {
    switch (careerType) {
      case 'tech_product':
        return 'product/engineering standups, sprint reviews, demos, tech trade-offs, stakeholder updates';
      case 'corporate_finance':
        return 'finance reviews, board/client reporting, budget decisions, risk updates';
      case 'sales_marketing':
        return 'client pitches, pipeline reviews, objections, campaign or deal updates';
      case 'healthcare_edu':
        return 'patient and family conversations, clinical handoffs, medication explanations, triage and care-plan discussions, ward rounds — healthcare first, not school-lesson topics';
      default:
        return 'workplace meetings, stakeholder updates, and on-the-spot professional answers';
    }
  }
}

class _LiveConversationScreenState extends State<LiveConversationScreen>
    with WidgetsBindingObserver {
  final LiveVoiceService _voice = LiveVoiceService.instance;
  final List<ConversationTurn> _turns = [];
  final ScrollController _chatScroll = ScrollController();
  final List<String> _userUtterances = [];
  StreamSubscription? _sub;
  bool _connecting = true;
  bool _listening = false;
  bool _booting = false;
  bool _ending = false;
  bool _turnSealed = true;
  bool _userSpeaking = false;
  bool _awaitingUserSpeech = false;
  bool _silenceDialogOpen = false;
  bool _coachHasSpoken = false;
  Timer? _silenceTimer;
  Timer? _speakingHoldTimer;
  Timer? _coachRevealTimer;
  /// Latest full coach transcript from the stream (may jump ahead of UI).
  String _coachTargetText = '';
  /// What is shown in the bubble — catches up smoothly word-by-word.
  String _coachDisplayedText = '';
  /// After coach turn_complete, ignore late duplicate STT until the user speaks.
  bool _coachTurnLocked = false;
  /// iOS: how much of the coach audio has actually played (text follows this).
  double _coachPlayProgress = 1.0;
  String _status = 'Connecting…';
  String? _error;
  bool _micDenied = false;
  DateTime? _startedAt;

  static const _silenceTimeout = Duration(seconds: 18);

  /// Only iOS queues PCM ahead of the speaker — pace chat to playback there.
  bool get _paceCoachTextToAudio =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// True when launched from Debate Me (Begin exercise → live pushback).
  bool _debateMode = false;

  String _norm(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

  /// True when [incoming] is the same coach line (or a fragment) already shown.
  bool _isDuplicateCoachText(String incoming) {
    if (_turns.isEmpty || _turns.last.role != 'coach') return false;
    final last = _norm(_turns.last.text);
    final next = _norm(incoming);
    if (last.isEmpty || next.isEmpty) return false;
    if (next == last) return true;
    if (last.startsWith(next) || next.startsWith(last)) return true;
    // Near-identical re-send with tiny punctuation drift.
    if (last.length > 24 && next.length > 24) {
      final a = last.replaceAll(RegExp(r'[^a-z0-9 ]'), '');
      final b = next.replaceAll(RegExp(r'[^a-z0-9 ]'), '');
      if (a == b || a.startsWith(b) || b.startsWith(a)) return true;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _boot();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _micDenied &&
        !_listening &&
        !_booting) {
      _boot();
    }
  }

  void _scrollChatToEnd({bool soft = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_chatScroll.hasClients) return;
      final target = _chatScroll.position.maxScrollExtent;
      if (soft) {
        _chatScroll.jumpTo(target);
        return;
      }
      _chatScroll.animateTo(
        target,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  /// Merge cumulative or delta STT chunks without flicker.
  String _mergeTranscript(String prev, String incoming) {
    final a = prev.trimRight();
    final b = incoming.trim();
    if (b.isEmpty) return a;
    if (a.isEmpty) return b;
    if (b.startsWith(a)) return b;
    if (a.startsWith(b)) return a;
    if (a.endsWith(b)) return a;
    final maxOverlap = a.length < b.length ? a.length : b.length;
    for (var n = maxOverlap; n > 0; n--) {
      if (b.startsWith(a.substring(a.length - n))) {
        return a + b.substring(n);
      }
    }
    if (b.startsWith(' ') || a.endsWith(' ') || a.endsWith('\n')) {
      return '$a$b';
    }
    return '$a $b';
  }

  /// Always update the open coach bubble — never spawn a second copy.
  void _writeCoachBubble(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    if (_turns.isNotEmpty && _turns.last.role == 'coach') {
      final prev = _turns.last.text.trim();
      if (trimmed == prev) return;
      // Don't shrink an already-complete bubble with a late fragment.
      if (prev.startsWith(trimmed) && trimmed.length < prev.length) return;
      _turns[_turns.length - 1] =
          ConversationTurn(role: 'coach', text: trimmed);
      return;
    }

    _turns.add(ConversationTurn(role: 'coach', text: trimmed));
    _turnSealed = false;
  }

  void _flushCoachReveal({bool scheduleSetState = true}) {
    _coachRevealTimer?.cancel();
    _coachRevealTimer = null;
    if (_coachTargetText.isEmpty) return;
    _coachDisplayedText = _coachTargetText;
    _writeCoachBubble(_coachDisplayedText);
    if (scheduleSetState && mounted) {
      setState(() {});
    }
    _scrollChatToEnd(soft: true);
  }

  void _ensureCoachRevealRunning() {
    if (_coachRevealTimer != null) return;
    // iOS: slower tick + playback gate so text tracks speech.
    // Android: faster tick is fine (AudioTrack is already in sync).
    final tick = _paceCoachTextToAudio
        ? const Duration(milliseconds: 70)
        : const Duration(milliseconds: 42);
    _coachRevealTimer = Timer.periodic(tick, (_) {
      if (!mounted) {
        _coachRevealTimer?.cancel();
        _coachRevealTimer = null;
        return;
      }
      if (_coachTargetText.isEmpty) {
        _coachRevealTimer?.cancel();
        _coachRevealTimer = null;
        return;
      }

      // Cap how much text may show based on real speaker progress (iOS only).
      var maxChars = _coachTargetText.length;
      if (_paceCoachTextToAudio) {
        if (_coachPlayProgress >= 0.985) {
          // Audio done (or nearly) — never leave the last letters stuck.
          maxChars = _coachTargetText.length;
        } else {
          // Track speech 1:1 while playing (no permanent shortfall).
          final gated =
              (_coachTargetText.length * _coachPlayProgress).floor();
          maxChars = gated.clamp(0, _coachTargetText.length);
          if (maxChars < _coachDisplayedText.length) {
            maxChars = _coachDisplayedText.length;
          }
        }
      }

      if (_coachDisplayedText.length >= _coachTargetText.length) {
        _coachRevealTimer?.cancel();
        _coachRevealTimer = null;
        return;
      }
      if (_coachDisplayedText.length >= maxChars) {
        // Wait for more audio to play before revealing the next words.
        return;
      }

      final remaining =
          _coachTargetText.substring(_coachDisplayedText.length);
      final word = RegExp(r'^(\s*\S+)').firstMatch(remaining)?.group(0);
      var step = word != null && word.length <= 28
          ? word
          : (remaining.length <= 3 ? remaining : remaining.substring(0, 3));
      final room = maxChars - _coachDisplayedText.length;
      if (step.length > room) {
        step = remaining.substring(0, room);
        if (step.isEmpty) return;
      }
      setState(() {
        _coachDisplayedText += step;
        _writeCoachBubble(_coachDisplayedText);
      });
      _scrollChatToEnd(soft: true);
    });
  }

  /// Returns false when the chunk should be ignored (late duplicate).
  bool _onCoachTranscriptChunk(String chunk) {
    final t = chunk.trim();
    if (t.isEmpty) return false;

    // Locked after turn_complete — drop Gemini's repeated final transcript.
    if (_coachTurnLocked && _isDuplicateCoachText(t)) {
      return false;
    }
    if (_coachTurnLocked && !_isDuplicateCoachText(t)) {
      // Rare: coach starts a brand-new line without a user turn.
      _coachTurnLocked = false;
      _coachTargetText = '';
      _coachDisplayedText = '';
      if (_paceCoachTextToAudio) _coachPlayProgress = 0;
    }

    if (_turns.isNotEmpty && _turns.last.role == 'user') {
      _coachTurnLocked = false;
      _turnSealed = false;
      _coachTargetText = '';
      _coachDisplayedText = '';
      if (_paceCoachTextToAudio) _coachPlayProgress = 0;
    }

    // Open / continue a single coach bubble (never a second copy).
    if (_turns.isEmpty || _turns.last.role != 'coach') {
      _turnSealed = false;
      _coachTargetText = '';
      _coachDisplayedText = '';
      if (_paceCoachTextToAudio) _coachPlayProgress = 0;
    }

    _coachTargetText = _mergeTranscript(_coachTargetText, t);
    if (_isDuplicateCoachText(_coachTargetText) &&
        _turns.isNotEmpty &&
        _turns.last.role == 'coach' &&
        _norm(_turns.last.text) == _norm(_coachTargetText)) {
      // Already rendered this exact line.
      _coachDisplayedText = _coachTargetText;
      return false;
    }

    if (_coachDisplayedText.isEmpty) {
      final first =
          RegExp(r'^\S+\s*').firstMatch(_coachTargetText)?.group(0) ??
              _coachTargetText;
      _coachDisplayedText = first;
      _writeCoachBubble(_coachDisplayedText);
    }
    _ensureCoachRevealRunning();
    return true;
  }

  /// Merge streaming transcript chunks into one bubble per speaker turn.
  /// Returns false if a coach chunk was ignored as a duplicate.
  bool _upsertTurn(String role, String chunk) {
    if (role == 'coach') {
      return _onCoachTranscriptChunk(chunk);
    }

    final t = chunk.trim();
    if (t.isEmpty) return false;

    // Finish any pending coach reveal before user text.
    if (_coachTargetText.isNotEmpty &&
        _coachDisplayedText.length < _coachTargetText.length) {
      _flushCoachReveal(scheduleSetState: false);
    }
    _coachTurnLocked = true;
    _turnSealed = true;

    if (_turns.isNotEmpty && _turns.last.role == role) {
      final prev = _turns.last.text;
      final next = _mergeTranscript(prev, t);
      _turns[_turns.length - 1] = ConversationTurn(role: role, text: next);
    } else {
      _turns.add(ConversationTurn(role: role, text: t));
    }

    final joined = _turns
        .where((e) => e.role == 'user')
        .map((e) => e.text)
        .join(' ')
        .trim();
    _userUtterances
      ..clear()
      ..addAll(joined.isEmpty ? <String>[] : <String>[joined]);
    _scrollChatToEnd();
    return true;
  }

  void _cancelSilenceTimer() {
    _silenceTimer?.cancel();
    _silenceTimer = null;
  }

  void _armSilenceTimer() {
    _cancelSilenceTimer();
    if (!_awaitingUserSpeech ||
        _ending ||
        _connecting ||
        _error != null ||
        !_coachHasSpoken ||
        _userSpeaking ||
        _silenceDialogOpen) {
      return;
    }
    _silenceTimer = Timer(_silenceTimeout, _onSilenceTimeout);
  }

  Future<void> _onSilenceTimeout() async {
    if (!mounted ||
        _ending ||
        _silenceDialogOpen ||
        !_awaitingUserSpeech ||
        _userSpeaking) {
      return;
    }
    _silenceDialogOpen = true;
    final shouldEnd = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Still there?',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        content: const Text(
          "You haven't said anything for a while. Do you want to end this conversation?",
          style: TextStyle(
            color: Color(0xFFCBD5E1),
            fontWeight: FontWeight.w600,
            height: 1.4,
            fontSize: 14.5,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Keep talking',
              style: TextStyle(
                color: Color(0xFF93C5FD),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0F172A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
            ),
            child: const Text(
              'End conversation',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
    _silenceDialogOpen = false;
    if (!mounted) return;
    if (shouldEnd == true) {
      await _end();
    } else {
      _armSilenceTimer();
    }
  }

  void _setUserSpeaking(bool speaking, {bool scheduleSetState = true}) {
    _speakingHoldTimer?.cancel();
    if (speaking) {
      final changed = !_userSpeaking;
      _userSpeaking = true;
      _cancelSilenceTimer();
      if (changed && scheduleSetState && mounted) {
        setState(() {});
        _scrollChatToEnd();
      } else if (changed) {
        _scrollChatToEnd();
      }
      return;
    }
    // Hold the dots briefly so they don't flicker between audio frames.
    _speakingHoldTimer = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      setState(() => _userSpeaking = false);
      if (_awaitingUserSpeech) _armSilenceTimer();
    });
  }

  void _markCoachSpeaking() {
    _awaitingUserSpeech = false;
    _coachHasSpoken = true;
    _cancelSilenceTimer();
    _speakingHoldTimer?.cancel();
    _userSpeaking = false;
  }

  void _markAwaitingUser() {
    if (!_coachHasSpoken || _ending) return;
    _awaitingUserSpeech = true;
    _armSilenceTimer();
  }

  Future<void> _boot() async {
    if (_booting) return;
    _booting = true;
    _cancelSilenceTimer();
    _speakingHoldTimer?.cancel();
    _coachRevealTimer?.cancel();
    _coachRevealTimer = null;
    _coachTargetText = '';
    _coachDisplayedText = '';
    _coachTurnLocked = false;
    setState(() {
      _connecting = true;
      _error = null;
      _micDenied = false;
      _status = 'Connecting…';
      _turns.clear();
      _userUtterances.clear();
      _turnSealed = true;
      _userSpeaking = false;
      _awaitingUserSpeech = false;
      _coachHasSpoken = false;
      _silenceDialogOpen = false;
      _coachPlayProgress = _paceCoachTextToAudio ? 0.0 : 1.0;
    });

    final state = context.read<AppStateProvider>();
    final prompt = state.selectedPrompt;
    final focus = prompt?.promptText.isNotEmpty == true
        ? prompt!.promptText
        : (state.focusLine.isNotEmpty
            ? state.focusLine
            : 'Practise clear, calm professional speech at work.');
    final activity = state.selectedActivity?.name ?? 'practice';
    final name =
        state.fullName.isEmpty ? 'there' : state.fullName.split(' ').first;
    final career = state.careerTypeLabel;
    final stage = state.careerStageLabel;
    final roadblock = state.roadblockLabel;
    final goal = state.primaryGoalLabel;
    final workSetting =
        LiveConversationScreen.workSettingForCareer(state.answers.careerType);
    final objective = prompt?.objective.trim().isNotEmpty == true
        ? prompt!.objective.trim()
        : state.focusLine;

    final isDebate = activity.toLowerCase().contains('debate') ||
        (state.selectedActivity?.slug == 'debate_me' ||
            state.selectedActivity?.slug == 'debate');
    _debateMode = isDebate;

    final String instruction;
    final String kickoff;
    if (isDebate) {
      instruction =
          'You are Hakkiri Debate Coach for $name — a live workplace debate partner. '
          'Work track: $career. Career stage: $stage. Situations: $workSetting. '
          'Goal: $goal. Roadblock: $roadblock. '
          'Assigned debate topic (must use this): "$focus". '
          'Skill objective: $objective. '
          'Flow: '
          '1) Speak first. Briefly state the debate topic as a clear yes/no or take-a-side prompt. '
          '2) Ask them to take a position and give ONE clear reason (their opening). Then wait. '
          '3) After their opening: push back once — challenge a weak assumption, like a sharp colleague. Keep pushback to 2–3 spoken sentences. '
          '4) Ask them to respond to THAT challenge (rebuttal). Then wait. '
          '5) After rebuttal: one short coaching note on argument strength / clarity / composure, then optionally one tighter follow-up challenge. '
          '6) One short spoken turn at a time. Do not score mid-call. Stay in $career workplace context. '
          '7) Let them finish — do not interrupt while they speak. '
          '8) ENGLISH ONLY. If they use another language, ask them to retry in English.';
      kickoff =
          'Start now as Hakkiri Debate Coach. '
          'My work setting is $career ($workSetting). '
          'Introduce this exact debate topic, ask me to take a side and give one reason, then wait: "$focus". '
          'English only.';
    } else {
      instruction =
          'You are Hakkiri Live Coach for $name — a spoken workplace communication coach. '
          'Stay inside THEIR real work environment only. '
          'Work track: $career. Career stage: $stage. '
          'Typical situations: $workSetting. '
          'Their practice goal: $goal. Main roadblock: $roadblock. '
          'Activity: $activity. '
          'Core practice prompt (ask this, do not replace with a random topic): "$focus". '
          'Skill objective: $objective. '
          'Hard rules: '
          '1) Speak first. One short greeting, then ask the practice prompt above in a natural spoken way. '
          '2) Every question and follow-up must fit a $career workplace — meetings, stakeholders, clients, teammates, managers. '
          '3) Do NOT ask about holidays, hobbies, dating, sports, or generic life chat unless the practice prompt itself requires it. '
          '4) After they answer: brief coaching on clarity/structure/confidence, then ONE work-context follow-up. '
          '5) One short spoken turn at a time. Do not score mid-call. Do not invent a different industry. '
          '6) Let them finish their full thought — short pauses are normal. Do not interrupt or answer while they are still speaking. '
          '7) ENGLISH ONLY training. You must speak only in English. If they speak Urdu, Hindi, Arabic, or any other language '
          '(or mix heavily), do NOT continue that language. Kindly say something like: '
          '"I am your English coach, so I will only train you in English. Please try that answer again in English." '
          'Then re-ask the practice question in English and wait. Accents are fine — other languages are not for practice.';
      kickoff =
          'Start now. Greet me briefly as Hakkiri Live Coach. '
          'My work setting is $career ($workSetting). '
          'Ask me this exact workplace practice question next, then wait for my spoken answer: "$focus". '
          'Keep the whole conversation in that work environment, and only in English.';
    }

    await _sub?.cancel();
    _sub = _voice.events.listen((event) {
      final type = (event['type'] ?? '').toString();
      if (!mounted) return;

      if (type == 'user_speaking') {
        final speaking = event['speaking'] == true;
        // Only show speaking UI on the user's turn (avoid coach speaker bleed).
        if (speaking && _awaitingUserSpeech) {
          _setUserSpeaking(true);
          if (mounted) {
            setState(() => _status = 'Listening…');
          }
        } else if (!speaking) {
          _setUserSpeaking(false);
        }
        return;
      }

      if (type == 'coach_playback') {
        if (!_paceCoachTextToAudio) return;
        final played = (event['played_ms'] as num?)?.toDouble() ?? 0;
        final scheduled = (event['scheduled_ms'] as num?)?.toDouble() ?? 0;
        final next = scheduled <= 0 ? 0.0 : (played / scheduled).clamp(0.0, 1.0);
        if ((next - _coachPlayProgress).abs() < 0.005 && next < 1.0) return;
        _coachPlayProgress = next;
        if (next >= 0.985 &&
            _coachTargetText.isNotEmpty &&
            _coachDisplayedText.length < _coachTargetText.length) {
          // Finish the bubble so the last word/letters are not left cut off.
          _flushCoachReveal();
        } else {
          _ensureCoachRevealRunning();
        }
        return;
      }

      if (type == 'model_transcript') {
        final text = (event['text'] ?? '').toString().trim();
        if (text.isEmpty) return;
        // Late duplicate after coach finished — do NOT flip back to "coach speaking"
        // (that was delaying the user's listen turn).
        if (_coachTurnLocked && _isDuplicateCoachText(text)) {
          return;
        }
        _markCoachSpeaking();
        if (!mounted) return;
        setState(() {
          final accepted = _upsertTurn('coach', text);
          if (accepted) {
            _status = 'Coach is speaking…';
          }
        });
        return;
      }

      if (type == 'turn_complete') {
        // Keep word-by-word reveal running — dumping here made chat jump ahead
        // of speech (worse on iOS). Mic / "Your turn" comes from native after
        // coach audio actually finishes playing.
        _coachTurnLocked = true;
        _turnSealed = true;
        return;
      }

      setState(() {
        if (type == 'status') {
          final msg = (event['message'] ?? _status).toString();
          final lower = msg.toLowerCase();
          // Native may open the mic on short audio gaps before turn_complete.
          // Keep UI on "Coach is speaking…" until the coach turn is sealed —
          // otherwise the top line flickers Your turn → Coach → Your turn.
          final prematureYourTurn =
              lower.contains('your turn') && !_coachTurnLocked;
          if (!prematureYourTurn) {
            _status = msg;
          }
          _listening = (event['listening'] == true) ||
              lower.contains('listen') ||
              lower.contains('coach is speaking') ||
              lower.contains('your turn');
          _connecting = lower.contains('connect');
          if (_listening) _error = null;
          // Only hand the turn to the user after the coach turn is complete.
          if (lower.contains('your turn') &&
              _coachHasSpoken &&
              _coachTurnLocked) {
            // Audio drained — complete any truncated coach bubble immediately.
            _coachPlayProgress = 1.0;
            if (_coachTargetText.isNotEmpty &&
                _coachDisplayedText.length < _coachTargetText.length) {
              _flushCoachReveal(scheduleSetState: false);
            }
            _markAwaitingUser();
          }
        } else if (type == 'user_transcript') {
          final text = (event['text'] ?? '').toString().trim();
          // Ignore kickoff + anything while coach is still talking (speaker echo).
          final isKickoffEcho = text.toLowerCase().contains('please start now') ||
              text.toLowerCase().contains('please greet me');
          final isCoachEcho = _isDuplicateCoachText(text) ||
              (_turns.isNotEmpty &&
                  _turns.last.role == 'coach' &&
                  _norm(_turns.last.text).contains(_norm(text)) &&
                  _norm(text).length >= 12);
          if (text.isNotEmpty &&
              !isKickoffEcho &&
              !isCoachEcho &&
              _awaitingUserSpeech) {
            _upsertTurn('user', text);
            _status = 'Listening…';
            _setUserSpeaking(true, scheduleSetState: false);
            _cancelSilenceTimer();
          }
        } else if (type == 'error') {
          _error = (event['message'] ?? 'Live voice failed.').toString();
          _connecting = false;
          _listening = false;
          _awaitingUserSpeech = false;
          _cancelSilenceTimer();
          _userSpeaking = false;
        } else if (type == 'closed') {
          _listening = false;
          _status = 'Session ended';
          _awaitingUserSpeech = false;
          _cancelSilenceTimer();
          _userSpeaking = false;
        }
      });
    });

    try {
      await _voice.stop();
      await _voice.start(
        systemInstruction: instruction,
        kickoff: kickoff,
      );
      if (!mounted) return;
      _startedAt = DateTime.now();
      AnalyticsService.instance.logLiveVoiceStarted();
      AnalyticsService.instance.logScreenView(screenName: 'LiveConversationScreen');
      setState(() {
        _micDenied = false;
        _error = null;
        if (!_listening) {
          _connecting = true;
          _status = 'Connecting to coach…';
        }
      });
    } on HakkiriApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _connecting = false;
        _error = e.message;
      });
    } on PlatformException catch (e) {
      if (!mounted) return;
      final isMic = e.code == 'mic_permission' ||
          (e.message ?? '').toLowerCase().contains('microphone');
      setState(() {
        _connecting = false;
        _micDenied = isMic;
        _error = e.message ?? 'Could not start native live voice.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _connecting = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      _booting = false;
    }
  }

  Future<bool> _confirmLeave() async {
    if (_ending) return false;
    final leave = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Leave conversation?',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        content: const Text(
          'Do you want to go back? The coach will stop speaking and this live session will end.',
          style: TextStyle(
            color: Color(0xFFCBD5E1),
            fontWeight: FontWeight.w600,
            height: 1.4,
            fontSize: 14.5,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Stay',
              style: TextStyle(
                color: Color(0xFF93C5FD),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0F172A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
            ),
            child: const Text(
              'Yes, go back',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
    return leave == true;
  }

  Future<void> _requestEnd() async {
    if (_ending) return;
    final ok = await _confirmLeave();
    if (!mounted || !ok) return;
    await _end();
  }

  Future<void> _end() async {
    if (_ending) return;
    _ending = true;
    _cancelSilenceTimer();
    _speakingHoldTimer?.cancel();
    _flushCoachReveal();
    _awaitingUserSpeech = false;
    _userSpeaking = false;
    if (mounted) setState(() {});

    // Hard-stop native playback first so coach voice dies before we leave.
    await _voice.stop();
    if (!mounted) return;

    final transcript = _userUtterances.join(' ').trim();
    final started = _startedAt ?? DateTime.now();
    final spoken = DateTime.now().difference(started).inSeconds.clamp(5, 600);
    AnalyticsService.instance.logLiveVoiceEnded(
      durationSeconds: spoken,
      messageCount: _turns.where((t) => t.role == 'user').length,
    );

    if (transcript.isEmpty) {
      if (mounted) Navigator.pop(context);
      return;
    }

    final state = context.read<AppStateProvider>();
    final turns = _turns.length;
    await HakkiriLoadingOverlay.run(
      context,
      message: 'Wrapping up your conversation…',
      detail: turns > 2
          ? 'Scoring the full back-and-forth exchange.'
          : 'Reviewing what you said with the live coach.',
      action: () => state.evaluateCurrentSession(
        transcript: transcript,
        durationSeconds: spoken,
        conversationMode: 'back_and_forth',
        conversationTurns: List<ConversationTurn>.from(_turns),
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
    WidgetsBinding.instance.removeObserver(this);
    _cancelSilenceTimer();
    _speakingHoldTimer?.cancel();
    _coachRevealTimer?.cancel();
    _sub?.cancel();
    _chatScroll.dispose();
    unawaited(_voice.stop());
    super.dispose();
  }

  /// Dots while mic hears you — hide once your text bubble is already streaming.
  bool get _showSpeakingDots {
    if (!_userSpeaking || !_awaitingUserSpeech) return false;
    if (_turns.isEmpty) return true;
    if (_turns.last.role == 'coach') return true;
    return _turnSealed;
  }

  Widget _buildSpeakingDotsBubble() {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.royalBlue,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(14),
            topRight: Radius.circular(14),
            bottomLeft: Radius.circular(14),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You',
              style: TextStyle(
                color: Color(0xB3FFFFFF),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 6),
            _SpeakingDots(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final slug =
        context.watch<AppStateProvider>().selectedActivity?.slug ?? '';
    final debateMode =
        _debateMode || slug == 'debate_me' || slug == 'debate';
    final userTurns = _turns.where((t) => t.role == 'user').length;
    final tipText = !debateMode
        ? null
        : (userTurns == 0
            ? 'Take a position, then give one clear reason.'
            : 'Address the challenge, then defend your position.');

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || _ending) return;
        await _requestEnd();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: _ending ? null : _requestEnd,
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_listening && !_connecting && !_ending) ...[
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: Color(0xFFEF4444),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            _connecting
                                ? 'CONNECTING'
                                : (_ending
                                    ? 'SCORING'
                                    : (_listening
                                        ? (debateMode ? 'REC' : 'LIVE')
                                        : 'IDLE')),
                            style: TextStyle(
                              color: _listening
                                  ? const Color(0xFF34D399)
                                  : const Color(0xFF93C5FD),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  debateMode ? 'DEBATE ME' : 'LIVE COACH',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  debateMode
                      ? (userTurns == 0
                          ? 'Opening argument'
                          : 'Give your rebuttal')
                      : 'Back-and-forth\nvoice practice',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _error ?? _status,
                  style: TextStyle(
                    color: _error != null
                        ? const Color(0xFFF87171)
                        : const Color(0xFFCBD5E1),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 18),
                Center(
                  child: SizedBox(
                    height: 56,
                    child: LiveWaveformBars(
                      isAnimated: _listening && _error == null && !_ending,
                      color: AppColors.royalBlue,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: _turns.isEmpty && !_showSpeakingDots
                        ? Center(
                            child: Text(
                              debateMode
                                  ? 'Hakkiri will give you the topic,\nthen challenge your point live.'
                                  : 'Coach will greet you first,\nthen ask your practice question.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: _chatScroll,
                            itemCount:
                                _turns.length + (_showSpeakingDots ? 1 : 0),
                            itemBuilder: (_, index) {
                              if (_showSpeakingDots &&
                                  index == _turns.length) {
                                return _buildSpeakingDotsBubble();
                              }
                              final turn = _turns[index];
                              final isUser = turn.role == 'user';
                              return Align(
                                alignment: isUser
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.sizeOf(context).width *
                                            0.72,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isUser
                                        ? AppColors.royalBlue
                                        : Colors.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(14),
                                      topRight: const Radius.circular(14),
                                      bottomLeft:
                                          Radius.circular(isUser ? 14 : 4),
                                      bottomRight:
                                          Radius.circular(isUser ? 4 : 14),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isUser
                                            ? 'You'
                                            : (debateMode
                                                ? 'Hakkiri'
                                                : 'Coach'),
                                        style: TextStyle(
                                          color: isUser
                                              ? Colors.white
                                                  .withValues(alpha: 0.7)
                                              : const Color(0xFF93C5FD),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      AnimatedSize(
                                        duration: const Duration(
                                          milliseconds: 120,
                                        ),
                                        curve: Curves.easeOutCubic,
                                        alignment: Alignment.topLeft,
                                        child: Text(
                                          turn.text,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            height: 1.4,
                                            letterSpacing: 0.1,
                                          ),
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
                if (tipText != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A5F).withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.lightbulb_outline_rounded,
                          color: Color(0xFF93C5FD),
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            tipText,
                            style: const TextStyle(
                              color: Color(0xFFE2E8F0),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                if (_micDenied) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: (_booting || _ending) ? null : _boot,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.royalBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Text(
                        _booting
                            ? 'Checking mic…'
                            : 'Try again with microphone',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _ending ? null : _requestEnd,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: debateMode
                          ? AppColors.royalBlue
                          : Colors.white,
                      foregroundColor: debateMode
                          ? Colors.white
                          : const Color(0xFF0F172A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: Text(
                      _ending
                          ? 'Scoring your answers…'
                          : (debateMode
                              ? 'Finish debate'
                              : 'End conversation'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SpeakingDots extends StatefulWidget {
  const _SpeakingDots();

  @override
  State<_SpeakingDots> createState() => _SpeakingDotsState();
}

class _SpeakingDotsState extends State<_SpeakingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = (_controller.value + i * 0.22) % 1.0;
            final t = (phase < 0.5) ? phase * 2 : (1 - phase) * 2;
            final size = 6.0 + 3.0 * t;
            return Container(
              margin: EdgeInsets.only(right: i == 2 ? 0 : 5),
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.55 + 0.45 * t),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
