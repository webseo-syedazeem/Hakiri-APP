import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/services/analytics_service.dart';
import '../providers/app_state_provider.dart';
import '../widgets/action_pill_button.dart';
import '../widgets/blue_accent_rays.dart';
import '../widgets/live_waveform_bars.dart';

/// Full 6-step guided "Debate Me" activity implementing the interactive AI Live Coach:
/// 1. Overview (Rules, Timeline & Response Strategy)
/// 2. Prompt + 10s Think Time
/// 3. Opening argument recording (60s speech drill)
/// 4. Hakkiri Challenges Your Point (AI Coach Pushback + 10s prep time)
/// 5. Rebuttal recording (60s counter-argument drill against the coach)
/// 6. Dual-part Feedback & Assessment scoring
class DebateMeScreen extends StatefulWidget {
  final String? topic;

  const DebateMeScreen({super.key, this.topic});

  @override
  State<DebateMeScreen> createState() => _DebateMeScreenState();
}

class _DebateMeScreenState extends State<DebateMeScreen> {
  // Step 1 to 6
  int _currentStep = 1;

  // Timers
  Timer? _countdownTimer;
  int _thinkSecondsRemaining = 10;
  int _openingSecondsRemaining = 60;
  int _prepSecondsRemaining = 10;
  int _rebuttalSecondsRemaining = 60;

  bool _isAssessingPart1 = true;

  // Assigned topic
  late String _topic;

  // AI Pushback quote
  final String _pushbackQuote =
      "But you're assuming flexibility won't weaken collaboration. "
      "If everyone chooses when to come in, what stops teams becoming "
      "fragmented and junior staff missing opportunities to learn from colleagues?";

  @override
  void initState() {
    super.initState();
    _topic = widget.topic ??
        "Should companies require employees to work in the office three days a week?";
    AnalyticsService.instance.logScreenView(screenName: 'DebateMe_Overview');
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _goToStep(int step) {
    _countdownTimer?.cancel();
    setState(() => _currentStep = step);

    AnalyticsService.instance.logScreenView(
      screenName: 'DebateMe_Step$step',
    );

    if (step == 2) {
      // Step 2: 10s think time
      _thinkSecondsRemaining = 10;
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return;
        if (_thinkSecondsRemaining > 1) {
          setState(() => _thinkSecondsRemaining--);
        } else {
          _countdownTimer?.cancel();
          _goToStep(3); // Auto-advance to opening recording
        }
      });
    } else if (step == 3) {
      // Step 3: 60s opening argument recording
      _openingSecondsRemaining = 60;
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return;
        if (_openingSecondsRemaining > 1) {
          setState(() => _openingSecondsRemaining--);
        } else {
          _countdownTimer?.cancel();
          _goToStep(4);
        }
      });
    } else if (step == 4) {
      // Step 4: 10s prep time for coach challenge
      _prepSecondsRemaining = 10;
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return;
        if (_prepSecondsRemaining > 1) {
          setState(() => _prepSecondsRemaining--);
        } else {
          _countdownTimer?.cancel();
          _goToStep(5); // Auto-advance to rebuttal recording
        }
      });
    } else if (step == 5) {
      // Step 5: 60s rebuttal recording
      _rebuttalSecondsRemaining = 60;
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return;
        if (_rebuttalSecondsRemaining > 1) {
          setState(() => _rebuttalSecondsRemaining--);
        } else {
          _countdownTimer?.cancel();
          _goToStep(6);
        }
      });
    } else if (step == 6) {
      // Record completed drill in app state
      final app = context.read<AppStateProvider>();
      app.finishDrillAndIncrementStreak();
    }
  }

  void _onBack() {
    if (_currentStep > 1) {
      _goToStep(_currentStep - 1);
    } else {
      Navigator.maybePop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkStep = _currentStep == 3 || _currentStep == 5;

    return AnnotatedRegion<SystemUiOverlayStyle>(
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
                          children: [
                            _buildTimelineStep('1. Prompt', 'You\'re assigned a topic.', Icons.description_outlined),
                            _buildTimelineDivider(),
                            _buildTimelineStep('2. Think', 'You have 10 seconds.', Icons.timer_outlined),
                            _buildTimelineDivider(),
                            _buildTimelineStep('3. Opening', 'Speak for 60 seconds.', Icons.mic_none_outlined),
                            _buildTimelineDivider(),
                            _buildTimelineStep('4. Feedback', 'Hakkiri challenges your point.', Icons.chat_bubble_outline_rounded),
                            _buildTimelineDivider(),
                            _buildTimelineStep('5. Rebuttal', 'Respond, then get feedback.', Icons.insights_rounded),
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
                      Text(
                        _topic,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 2),

                // Circular Countdown Timer (10s)
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 140,
                        height: 140,
                        child: CircularProgressIndicator(
                          value: _thinkSecondsRemaining / 10.0,
                          strokeWidth: 8,
                          backgroundColor: const Color(0xFFEFF6FF),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$_thinkSecondsRemaining',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 44,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                              letterSpacing: -1.0,
                            ),
                          ),
                          const Text(
                            'seconds to think',
                            style: TextStyle(
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
            label: 'Start opening',
            onTap: () => _goToStep(3),
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

                // Topic Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Row(
                    children: [
                      Container(
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
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
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
                        value: _openingSecondsRemaining / 60.0,
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

                // Recording badge
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Recording',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Animated Soundwaves
                const SizedBox(
                  width: double.infinity,
                  child: LiveWaveformBars(
                    barCount: 28,
                    maxHeight: 52,
                    color: Color(0xFF38BDF8),
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
            onTap: () => _goToStep(4),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // STEP 4: HAKKIRI CHALLENGES YOUR POINT (AI Coach Pushback)
  // ===========================================================================
  Widget _buildStep4CoachPushback() {
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
                    const Text(
                      'Hakkiri challenges',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.6,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'your point.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2563EB),
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
                const SizedBox(height: 14),

                // AI Coach Quote Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
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
                      Text(
                        _pushbackQuote,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 2),

                // Circular countdown timer (10s response prep)
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 140,
                        height: 140,
                        child: CircularProgressIndicator(
                          value: _prepSecondsRemaining / 10.0,
                          strokeWidth: 8,
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
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 44,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                              letterSpacing: -1.0,
                            ),
                          ),
                          const Text(
                            'seconds to prepare\nyour response',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 3),

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
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
          child: ActionPillButton(
            label: 'Start response',
            onTap: () => _goToStep(5),
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
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
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
                        value: _rebuttalSecondsRemaining / 60.0,
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

                // REC indicator
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
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
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Soundwaves
                const SizedBox(
                  width: double.infinity,
                  child: LiveWaveformBars(
                    barCount: 28,
                    maxHeight: 52,
                    color: Color(0xFF38BDF8),
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
                onTap: () => _goToStep(6),
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
      width: 90,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF2563EB)),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineDivider() {
    return Container(
      width: 14,
      height: 1.5,
      color: const Color(0xFFCBD5E1),
      margin: const EdgeInsets.symmetric(horizontal: 2),
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
