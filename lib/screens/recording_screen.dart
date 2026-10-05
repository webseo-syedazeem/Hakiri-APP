import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/app_state_provider.dart';
import 'feedback_screen.dart';

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  int _secondsRemaining = 42; // Matches Page 7 screenshot "0:42"
  Timer? _countdownTimer;
  final int _fillerCount = 2;
  final double _startTime = 1.2;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining -= 1);
      } else {
        _finishDrill();
      }
    });
  }

  void _finishDrill() {
    _countdownTimer?.cancel();
    final state = Provider.of<AppStateProvider>(context, listen: false);

    // Evaluate speech using exact prompt and realistic transcription
    state.evaluateCurrentSession(
      transcript:
          'Pick up the phone when the deal matters. A call shows real effort, and you hear subtle hesitation you’d miss in an email. Then send a short recap email so basically there are no misaligned expectations.',
      durationSeconds: 60 - _secondsRemaining,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const FeedbackScreen()),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = _secondsRemaining ~/ 60;
    final s = _secondsRemaining % 60;
    final timeFormatted = '$m:${s < 10 ? '0' : ''}$s';

    return Scaffold(
      backgroundColor: const Color(0xFF10111A), // Dark mode canvas as in Page 7
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Bar
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
                        'THINK FIRST  ·  1 OF 3',
                        style: TextStyle(
                          color: Color(0xFFA0A3B5),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const Text(
                        'SALES',
                        style: TextStyle(
                          color: Color(0xFFA0A3B5),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Progress line
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: const LinearProgressIndicator(
                      value: 0.33,
                      minHeight: 2.5,
                      backgroundColor: Color(0xFF26283D),
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4C5CFF)),
                    ),
                  ),
                ],
              ),

              // Question Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'YOUR QUESTION',
                    style: TextStyle(
                      color: Color(0xFF8B8FA3),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Is it better to follow up with a\nclient by email or pick up the\nphone?',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),

              // Timer & Waveform Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TIME LEFT',
                            style: TextStyle(
                              color: Color(0xFF8B8FA3),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            timeFormatted,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 54,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1.0,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.coralRed,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'REC',
                              style: TextStyle(
                                color: AppColors.coralRed,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Waveform Visualizer
                  SizedBox(
                    height: 60,
                    width: double.infinity,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: _buildLiveWaveform(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 3 Telemetry Cards (START, PACE, FILLERS)
                  Row(
                    children: [
                      Expanded(child: _buildTelemetryCard('START', '${_startTime}s')),
                      const SizedBox(width: 8),
                      Expanded(child: _buildTelemetryCard('PACE', 'Steady')),
                      const SizedBox(width: 8),
                      Expanded(child: _buildTelemetryCard('FILLERS', '$_fillerCount')),
                    ],
                  ),
                ],
              ),

              // Bottom Button (Finish answer)
              SizedBox(
                height: 56,
                child: Material(
                  color: const Color(0xFFECEAE2),
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: _finishDrill,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Finish answer',
                            style: TextStyle(
                              color: Color(0xFF13141F),
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.royalBlue,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildTelemetryCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF161726),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF26283D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF7E8296),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildLiveWaveform() {
    final heights = [
      12.0, 18.0, 28.0, 42.0, 24.0, 14.0, 32.0, 50.0, 44.0, 54.0, 36.0, 20.0,
      38.0, 48.0, 28.0, 16.0, 26.0, 36.0, 44.0, 22.0, 14.0, 20.0, 34.0, 24.0,
    ];

    return heights.map((h) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 2.0),
        width: 3.5,
        height: h,
        decoration: BoxDecoration(
          color: const Color(0xFF5B6BFF),
          borderRadius: BorderRadius.circular(2),
        ),
      );
    }).toList();
  }
}
