import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/services/analytics_service.dart';
import '../providers/app_state_provider.dart';
import '../widgets/action_pill_button.dart';
import '../widgets/blue_accent_rays.dart';
import 'live_conversation_screen.dart';
import 'recording_screen.dart';

/// Activity intro screen, rendered per-activity to match the design spec
/// (the 7 MVP "Begin exercise" screens). Each activity has its own icon,
/// label, two-tone title, subtitle, HOW IT WORKS steps and strategy card.
/// Note: Beginner / intermediate / pro levels removed as per client decision.
class ActivityDetailScreen extends StatelessWidget {
  const ActivityDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final slug = state.selectedActivity?.slug ?? 'think_fast';
    final spec = _activitySpecs[slug] ?? _activitySpecs['think_fast']!;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService.instance.logScreenView(
        screenName: 'ActivityDetailScreen_$slug',
      );
    });

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBF9),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar (< back)
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Icon(
                    Icons.chevron_left_rounded,
                    color: Color(0xFF0F172A),
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Scrollable Body
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Activity icon badge
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFDBEAFE),
                            width: 1.2,
                          ),
                        ),
                        child: Icon(
                          spec.icon,
                          color: const Color(0xFF2563EB),
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Tag: e.g. "1. THINK FAST"
                      Text(
                        spec.label,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Two-tone heading + accent rays
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flexible(
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 34,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: -1.0,
                                  height: 1.1,
                                ),
                                children: [
                                  TextSpan(text: spec.titleBlack),
                                  TextSpan(
                                    text: spec.titleBlue,
                                    style: const TextStyle(color: Color(0xFF2563EB)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Transform.translate(
                            offset: const Offset(0, 2),
                            child: const BlueAccentRays(size: 22),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Subtitle
                      Text(
                        spec.subtitle,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // CARD 1: HOW IT WORKS
                      _buildHowItWorksCard(spec.steps),
                      const SizedBox(height: 16),

                      // CARD 2: strategy (USE YOUR 5 SECONDS / BUILD THE CONNECTION / ...)
                      _buildStrategyCard(spec.strategyTitle, spec.strategy),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // Bottom CTAs
              ActionPillButton(
                label: 'Begin exercise',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RecordingScreen()),
                  );
                },
              ),
              const SizedBox(height: 10),
              ActionPillButton(
                label: 'Live coach conversation',
                isSecondary: true,
                onPressed: () async {
                  final nav = Navigator.of(context);
                  final app = context.read<AppStateProvider>();
                  if (app.isLoggedIn) {
                    await app.fetchNextPromptFromApi();
                  }
                  if (!context.mounted) return;
                  nav.push(
                    MaterialPageRoute(builder: (_) => const LiveConversationScreen()),
                  );
                },
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }

  /// CARD 1: HOW IT WORKS — a connected 3- or 4-step timeline.
  Widget _buildHowItWorksCard(List<_Step> steps) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Text(
              'HOW IT WORKS',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              // Connecting horizontal line behind the icons.
              Positioned(
                top: 22,
                left: 30,
                right: 30,
                child: Container(height: 2, color: const Color(0xFFDBEAFE)),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final s in steps)
                    _buildTimelineStep(icon: s.icon, title: s.title, subtitle: s.sub),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return SizedBox(
      width: 74,
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: const Color(0xFF2563EB), size: 21),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  /// CARD 2: strategy — 3 mini cards (blue / red / green) with arrows.
  Widget _buildStrategyCard(String title, List<String> steps) {
    const bgColors = [Color(0xFFEFF6FF), Color(0xFFFEF2F2), Color(0xFFF0FDF4)];
    const numColors = [Color(0xFF2563EB), Color(0xFFEF4444), Color(0xFF10B981)];

    final children = <Widget>[];
    for (int i = 0; i < steps.length; i++) {
      children.add(
        Expanded(
          child: _buildMiniStepCard(
            number: '${i + 1}',
            text: steps[i],
            bgColor: bgColors[i % bgColors.length],
            numColor: numColors[i % numColors.length],
          ),
        ),
      );
      if (i < steps.length - 1) {
        children.add(const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Icon(Icons.arrow_forward_rounded, color: Color(0xFF94A3B8), size: 15),
        ));
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 14),
          IntrinsicHeight(child: Row(children: children)),
        ],
      ),
    );
  }

  Widget _buildMiniStepCard({
    required String number,
    required String text,
    required Color bgColor,
    required Color numColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(color: numColor, shape: BoxShape.circle),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Per-activity content ─────────────────────────────────────────────────────

class _Step {
  final IconData icon;
  final String title;
  final String sub;
  const _Step(this.icon, this.title, this.sub);
}

class _ActivitySpec {
  final IconData icon;
  final String label;
  final String titleBlack;
  final String titleBlue;
  final String subtitle;
  final List<_Step> steps;
  final String strategyTitle;
  final List<String> strategy;
  const _ActivitySpec({
    required this.icon,
    required this.label,
    required this.titleBlack,
    required this.titleBlue,
    required this.subtitle,
    required this.steps,
    required this.strategyTitle,
    required this.strategy,
  });
}

const _questionStep = _Step(Icons.format_list_bulleted_rounded, '1. Question', 'A random question appears.');
const _thinkStep = _Step(Icons.timer_outlined, '2. Think', 'You have 5 seconds.');
const _feedbackStep = _Step(Icons.bar_chart_rounded, '4. Feedback', 'Get personalised feedback.');

final Map<String, _ActivitySpec> _activitySpecs = {
  'think_fast': const _ActivitySpec(
    icon: Icons.bolt_rounded,
    label: '1. THINK FAST',
    titleBlack: 'Think ',
    titleBlue: 'Fast.',
    subtitle: 'Answer a surprise question clearly, the way you would in a real meeting.',
    steps: [
      _questionStep,
      _thinkStep,
      _Step(Icons.mic_none_rounded, '3. Speak', 'Record for 60 seconds.'),
      _feedbackStep,
    ],
    strategyTitle: 'USE YOUR 5 SECONDS',
    strategy: ['Pick\nyour point', 'Choose\nwhy', 'Add one\nexample'],
  ),
  'connect_the_dots': const _ActivitySpec(
    icon: Icons.hub_rounded,
    label: '2. CONNECT THE DOTS',
    titleBlack: 'Connect the ',
    titleBlue: 'Dots.',
    subtitle: 'Link two random ideas into a clear, compelling story.',
    steps: [
      _Step(Icons.link_rounded, '1. Two topics', "You'll see two unrelated ideas."),
      _thinkStep,
      _Step(Icons.mic_none_rounded, '3. Connect', 'Speak for 60 seconds.'),
      _feedbackStep,
    ],
    strategyTitle: 'BUILD THE CONNECTION',
    strategy: ['Start with\nthe first idea', 'Find the\nlink or bridge', 'Land on\nthe second idea'],
  ),
  'explain_it_simply': const _ActivitySpec(
    icon: Icons.lightbulb_outline_rounded,
    label: '3. EXPLAIN IT SIMPLY',
    titleBlack: 'Explain It ',
    titleBlue: 'Simply.',
    subtitle: 'Take a complex topic and explain it in clear, simple language.',
    steps: [
      _Step(Icons.description_outlined, '1. Topic + audience', 'Who to explain it to.'),
      _thinkStep,
      _Step(Icons.mic_none_rounded, '3. Explain', 'Speak clearly.'),
      _feedbackStep,
    ],
    strategyTitle: 'KEEP IT SIMPLE',
    strategy: ['What is it?\n(in simple terms)', 'Make it\nrelatable', 'Why does\nit matter?'],
  ),
  'cut_it_in_half': const _ActivitySpec(
    icon: Icons.content_cut_rounded,
    label: '4. CUT IT IN HALF',
    titleBlack: 'Cut It in ',
    titleBlue: 'Half.',
    subtitle: 'Read a longer message and make it shorter, clearer and more impactful.',
    steps: [
      _Step(Icons.description_outlined, '1. Read', 'A longer text appears.'),
      _Step(Icons.search_rounded, '2. Find the point', 'Identify what matters.'),
      _Step(Icons.mic_none_rounded, '3. Summarise', 'Speak your shorter version.'),
      _feedbackStep,
    ],
    strategyTitle: 'CUT THE CLUTTER',
    strategy: ["Main point\n(key message?)", 'Essential\ndetail', 'Action\n(what next?)'],
  ),
  'storytelling_gym': const _ActivitySpec(
    icon: Icons.menu_book_rounded,
    label: '5. STORYTELLING GYM',
    titleBlack: 'Storytelling ',
    titleBlue: 'Gym.',
    subtitle: 'Turn a scenario into a clear, memorable story.',
    steps: [
      _Step(Icons.description_outlined, '1. Scenario', 'A scenario appears.'),
      _Step(Icons.mic_none_rounded, '2. Speak', 'You have 60 seconds.'),
      _Step(Icons.bar_chart_rounded, '3. Feedback', 'Get personalised feedback.'),
    ],
    strategyTitle: 'BUILD YOUR STORY',
    strategy: ['Set the\nscene', 'Show what\nhappened', 'Land\nthe point'],
  ),
  'one_minute_expert': const _ActivitySpec(
    icon: Icons.school_outlined,
    label: '6. ONE MINUTE EXPERT',
    titleBlack: 'One Minute ',
    titleBlue: 'Expert.',
    subtitle: 'Choose a topic you want to speak about and explain it confidently in one minute.',
    steps: [
      _Step(Icons.format_list_bulleted_rounded, '1. Choose a topic', 'Pick what to speak about.'),
      _thinkStep,
      _Step(Icons.mic_none_rounded, '3. Speak', 'You have 60 seconds.'),
      _feedbackStep,
    ],
    strategyTitle: 'MAKE IT LAND',
    strategy: ['Hook\n(get attention)', 'Two clear\npoints', 'Strong\nfinish'],
  ),
  'debate_me': const _ActivitySpec(
    icon: Icons.forum_outlined,
    label: '7. DEBATE ME',
    titleBlack: 'Debate ',
    titleBlue: 'Me.',
    subtitle: 'See a different perspective and respond with a clear, confident counterpoint.',
    steps: [
      _Step(Icons.description_outlined, '1. Position', 'A statement or opposing view.'),
      _thinkStep,
      _Step(Icons.mic_none_rounded, '3. Respond', 'Speak for 60 seconds.'),
      _feedbackStep,
    ],
    strategyTitle: 'BUILD YOUR RESPONSE',
    strategy: ['State your\nposition', 'Give your\nreason', 'Counter\nthe objection'],
  ),
};
