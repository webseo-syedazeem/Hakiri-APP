import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/services/hakkiri_api_service.dart';
import '../core/services/live_voice_service.dart';
import '../providers/app_state_provider.dart';
import '../widgets/live_waveform_bars.dart';
import 'feedback_screen.dart';

class LiveConversationScreen extends StatefulWidget {
  const LiveConversationScreen({super.key});

  @override
  State<LiveConversationScreen> createState() => _LiveConversationScreenState();
}

class _LiveConversationScreenState extends State<LiveConversationScreen>
    with WidgetsBindingObserver {
  final LiveVoiceService _voice = LiveVoiceService.instance;
  final List<String> _lines = [];
  final List<String> _userUtterances = [];
  StreamSubscription? _sub;
  bool _connecting = true;
  bool _listening = false;
  bool _booting = false;
  bool _ending = false;
  String _status = 'Connecting…';
  String? _error;
  bool _micDenied = false;
  DateTime? _startedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _boot();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // User may grant mic in Settings then return — retry once.
    if (state == AppLifecycleState.resumed &&
        _micDenied &&
        !_listening &&
        !_booting) {
      _boot();
    }
  }

  Future<void> _boot() async {
    if (_booting) return;
    _booting = true;
    setState(() {
      _connecting = true;
      _error = null;
      _micDenied = false;
      _status = 'Connecting…';
    });

    final state = context.read<AppStateProvider>();
    final prompt = state.selectedPrompt;
    final focus = prompt?.promptText.isNotEmpty == true
        ? prompt!.promptText
        : (state.focusLine.isNotEmpty
            ? state.focusLine
            : 'Practise clear, calm professional speech.');
    final activity = state.selectedActivity?.name ?? 'practice';
    final instruction =
        'You are Hakkiri Live Coach for ${state.fullName.isEmpty ? 'the user' : state.fullName}. '
        'Activity: $activity. Practice prompt to work on: "$focus". '
        '${prompt?.objective.isNotEmpty == true ? 'Objective: ${prompt!.objective}. ' : ''}'
        'Keep spoken replies short. Challenge them like a stakeholder. '
        'Ask one follow-up question at a time. Do not score them mid-call.';

    await _sub?.cancel();
    _sub = _voice.events.listen((event) {
      final type = (event['type'] ?? '').toString();
      if (!mounted) return;
      setState(() {
        if (type == 'status') {
          _status = (event['message'] ?? _status).toString();
          _listening =
              (event['listening'] == true) || _status.toLowerCase().contains('listen');
          _connecting = _status.toLowerCase().contains('connect');
          if (_listening) _error = null;
        } else if (type == 'user_transcript') {
          final text = (event['text'] ?? '').toString().trim();
          if (text.isNotEmpty) {
            _lines.add('You: $text');
            _userUtterances.add(text);
          }
        } else if (type == 'model_transcript') {
          final text = (event['text'] ?? '').toString().trim();
          if (text.isNotEmpty) _lines.add('Coach: $text');
        } else if (type == 'error') {
          _error = (event['message'] ?? 'Live voice failed.').toString();
          _connecting = false;
          _listening = false;
        } else if (type == 'closed') {
          _listening = false;
          _status = 'Session ended';
        }
      });
    });

    try {
      await _voice.stop();
      await _voice.start(systemInstruction: instruction);
      if (!mounted) return;
      _startedAt = DateTime.now();
      setState(() {
        _connecting = false;
        _listening = true;
        _micDenied = false;
        _error = null;
        _status = 'Listening — speak naturally';
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
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _connecting = false;
        _error = 'Could not start live voice. Check mic permission and network.';
      });
    } finally {
      _booting = false;
    }
  }

  Future<void> _end() async {
    if (_ending) return;
    _ending = true;

    await _voice.stop();
    if (!mounted) return;

    final transcript = _userUtterances.join(' ').trim();
    final started = _startedAt ?? DateTime.now();
    final spoken = DateTime.now().difference(started).inSeconds.clamp(5, 600);

    // No usable speech — just leave without a fake high score.
    if (transcript.isEmpty) {
      if (mounted) Navigator.pop(context);
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF2563EB)),
      ),
    );

    final state = context.read<AppStateProvider>();
    try {
      await state.evaluateCurrentSession(
        transcript: transcript,
        durationSeconds: spoken,
      );
    } finally {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop(); // loading
      }
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const FeedbackScreen()),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sub?.cancel();
    unawaited(_voice.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    onTap: _ending ? null : _end,
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _connecting
                          ? 'CONNECTING'
                          : (_ending
                              ? 'SCORING'
                              : (_listening ? 'LIVE' : 'IDLE')),
                      style: TextStyle(
                        color: _listening
                            ? const Color(0xFF34D399)
                            : const Color(0xFF93C5FD),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const Text(
                'LIVE COACH',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Back-and-forth\nvoice practice',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _error ?? _status,
                style: TextStyle(
                  color: _error != null ? const Color(0xFFF87171) : const Color(0xFFCBD5E1),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 28),
              Center(
                child: SizedBox(
                  height: 72,
                  child: LiveWaveformBars(
                    isAnimated: _listening && _error == null && !_ending,
                    color: AppColors.royalBlue,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: _lines.isEmpty
                      ? const Center(
                          child: Text(
                            'Start speaking. The coach will reply in voice.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _lines.length,
                          itemBuilder: (_, index) {
                            final line = _lines[index];
                            final isUser = line.startsWith('You:');
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Text(
                                line,
                                style: TextStyle(
                                  color: isUser ? const Color(0xFF93C5FD) : Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  height: 1.35,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
              const SizedBox(height: 18),
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
                      _booting ? 'Checking mic…' : 'Try again with microphone',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _ending ? null : _end,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0F172A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Text(
                    _ending ? 'Scoring your answers…' : 'End conversation',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
