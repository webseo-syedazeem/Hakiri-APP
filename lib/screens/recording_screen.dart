import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/app_state_provider.dart';
import '../widgets/waveform_visualizer.dart';
import 'feedback_screen.dart';

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  bool _isPrepPhase = true;
  int _prepSecondsRemaining = 3;
  int _recordingSecondsRemaining = 60;
  Timer? _prepTimer;
  Timer? _recordingTimer;

  @override
  void initState() {
    super.initState();
    final state = Provider.of<AppStateProvider>(context, listen: false);
    _prepSecondsRemaining = state.selectedActivity?.prepDurationSeconds ?? 3;
    _recordingSecondsRemaining = state.selectedPrompt?.durationSeconds ?? 60;
    _startPrepTimer();
  }

  void _startPrepTimer() {
    _prepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_prepSecondsRemaining > 1) {
        setState(() => _prepSecondsRemaining -= 1);
      } else {
        _prepTimer?.cancel();
        setState(() => _isPrepPhase = false);
        _startRecordingTimer();
      }
    });
  }

  void _startRecordingTimer() {
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_recordingSecondsRemaining > 1) {
        setState(() => _recordingSecondsRemaining -= 1);
      } else {
        _finishAndEvaluate();
      }
    });
  }

  void _finishAndEvaluate() {
    _prepTimer?.cancel();
    _recordingTimer?.cancel();

    final state = Provider.of<AppStateProvider>(context, listen: false);
    final prompt = state.selectedPrompt;

    final simulatedTranscript = prompt?.activitySlug == 'cut_it_in_half'
        ? 'Starting Monday, to protect personal downtime and sustain daytime focus, team members are not required to respond to Slack messages after 6:00 PM.'
        : 'I believe we should ban video calls on Friday mornings. Basically, constant screen fatigue degrades deep work. By creating quiet blocks, team members can execute deep focus tasks without interruption.';

    state.evaluateCurrentSession(
      transcript: simulatedTranscript,
      durationSeconds: (prompt?.durationSeconds ?? 60) - _recordingSecondsRemaining,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const FeedbackScreen()),
    );
  }

  @override
  void dispose() {
    _prepTimer?.cancel();
    _recordingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final prompt = state.selectedPrompt;

    if (prompt == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.accentCyan)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: _isPrepPhase
              ? _buildPrepView()
              : _buildRecordingView(prompt),
        ),
      ),
    );
  }

  Widget _buildPrepView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'GET READY TO THINK ON YOUR FEET',
            style: TextStyle(
              color: AppColors.accentCyan,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '$_prepSecondsRemaining',
            style: const TextStyle(
              color: AppColors.accentCyan,
              fontSize: 96,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Prompt will flash instantly. Mic activates automatically.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingView(dynamic prompt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accentRose,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'LIVE DRILL IN PROGRESS',
                      style: TextStyle(
                        color: AppColors.accentRose,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                Text(
                  prompt.activitySlug,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Prompt Flash Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.accentCyan),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'YOUR SPEAKING PROMPT:',
                    style: TextStyle(
                      color: AppColors.accentCyan,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    prompt.promptText,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  if (prompt.secondaryText != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceBorder,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        prompt.secondaryText!,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Waveform & Live Timer
            WaveformVisualizer(
              isRecording: true,
              secondsRemaining: _recordingSecondsRemaining,
            ),
          ],
        ),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _finishAndEvaluate,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentCyan,
              foregroundColor: AppColors.textInverse,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Stop & Analyze Speech Output 🎙️',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
