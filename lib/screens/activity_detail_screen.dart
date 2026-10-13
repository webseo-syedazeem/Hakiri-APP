import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../widgets/action_pill_button.dart';
import '../widgets/blue_accent_rays.dart';
import 'recording_screen.dart';

/// Activity detail screen rendered to match Image 1 (the 7 MVP "Begin exercise" screens).
/// Each activity has its uppercase label, inline large outline icon + bold title with blue rays,
/// subtitle, connected HOW IT WORKS timeline card, 3-step colored strategy card, and
/// the bottom "Begin exercise" action pill button.
class ActivityDetailScreen extends StatelessWidget {
  const ActivityDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final slug = state.selectedActivity?.slug ?? 'think_fast';
    final spec = _activitySpecs[slug] ?? _activitySpecs['think_fast']!;
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final bottomGap = isIOS ? (safeBottom > 0 ? 20.0 : 12.0) : 14.0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // Soft ambient top-right pastel organic blue glow
            Positioned(
              top: -50,
              right: -50,
              child: IgnorePointer(
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFE0EDFD).withValues(alpha: 0.70),
                        const Color(0xFFEFF6FF).withValues(alpha: 0.35),
                        const Color(0x00FFFFFF),
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            SafeArea(
              bottom: !isIOS,
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomGap),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Bar (< back arrow)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Color(0xFF0F172A),
                            size: 20,
                          ),
                        ),
                      ),
                    ),

                    // Scrollable content
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Tag: e.g. "1. THINK FAST"
                            Text(
                              spec.label,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // 2. Icon + Title Row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Large outline vector icon
                                Icon(
                                  spec.icon,
                                  color: const Color(0xFF2563EB),
                                  size: 44,
                                ),
                                const SizedBox(width: 14),

                                // Title text with blue accent rays
                                Expanded(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          spec.title,
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 32,
                                            fontWeight: FontWeight.w900,
                                            color: Color(0xFF0F172A),
                                            height: 1.15,
                                            letterSpacing: -0.8,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Transform.translate(
                                        offset: const Offset(0, -6),
                                        child: const BlueAccentRays(size: 24),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // 3. Subtitle
                            Text(
                              spec.subtitle,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF64748B),
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // 4. Card: HOW IT WORKS
                            _buildHowItWorksCard(spec.steps),
                            const SizedBox(height: 14),

                            // 5. Card: Strategy (USE YOUR 5 SECONDS / ...)
                            _buildStrategyCard(spec.strategyTitle, spec.strategy),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),

                    // Bottom Primary Action CTA
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: ActionPillButton(
                        label: 'Begin exercise',
                        onPressed: () async {
                          final nav = Navigator.of(context);
                          final app = context.read<AppStateProvider>();
                          if (app.isLoggedIn) {
                            await app.fetchNextPromptFromApi();
                          }
                          if (!context.mounted) return;
                          nav.push(
                            MaterialPageRoute(builder: (_) => const RecordingScreen()),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// CARD 1: HOW IT WORKS — connected 3- or 4-step horizontal timeline
  Widget _buildHowItWorksCard(List<_Step> steps) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(22),
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
              // Continuous connecting line behind the circle nodes
              Positioned(
                top: 22,
                left: 24,
                right: 24,
                child: Container(height: 2, color: const Color(0xFFDBEAFE)),
              ),
              Row(
                mainAxisAlignment: steps.length == 3
                    ? MainAxisAlignment.spaceAround
                    : MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final s in steps)
                    _buildTimelineStep(
                      icon: s.icon,
                      title: s.title,
                      subtitle: s.sub,
                      width: steps.length == 3 ? 90 : 70,
                    ),
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
    required double width,
  }) {
    return SizedBox(
      width: width,
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
              fontSize: 11,
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

  /// CARD 2: Strategy — 3 mini cards (blue / red / green) with connecting arrows
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
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: Color(0xFF64748B),
              ),
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
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
          const SizedBox(height: 7),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10.5,
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

// ── Per-activity specifications matching Image 1 ──────────────────────────────

class _Step {
  final IconData icon;
  final String title;
  final String sub;
  const _Step(this.icon, this.title, this.sub);
}

class _ActivitySpec {
  final IconData icon;
  final String label;
  final String title;
  final String subtitle;
  final List<_Step> steps;
  final String strategyTitle;
  final List<String> strategy;

  const _ActivitySpec({
    required this.icon,
    required this.label,
    required this.title,
    required this.subtitle,
    required this.steps,
    required this.strategyTitle,
    required this.strategy,
  });
}

const _thinkStep = _Step(Icons.timer_outlined, '2. Think', 'You have\n5 seconds.');
const _feedbackStep = _Step(Icons.bar_chart_rounded, '4. Feedback', 'Get personalised\nfeedback.');

final Map<String, _ActivitySpec> _activitySpecs = {
  // Screen 1: Think Fast.
  'think_fast': const _ActivitySpec(
    icon: Icons.bolt_rounded,
    label: '1. THINK FAST',
    title: 'Think Fast.',
    subtitle: 'Answer a surprise question clearly, the way you would in a real meeting.',
    steps: [
      _Step(Icons.description_outlined, '1. Question', 'A random question\nappears.'),
      _thinkStep,
      _Step(Icons.mic_none_rounded, '3. Speak', 'Record for\n60 seconds.'),
      _feedbackStep,
    ],
    strategyTitle: 'USE YOUR 5 SECONDS',
    strategy: ['Pick\nyour point', 'Choose\nwhy', 'Add one\nexample'],
  ),

  // Screen 2: Connect the Dots.
  'connect_the_dots': const _ActivitySpec(
    icon: Icons.hub_rounded,
    label: '2. CONNECT THE DOTS',
    title: 'Connect\nthe Dots.',
    subtitle: 'Link two random ideas into a clear, compelling story.',
    steps: [
      _Step(Icons.hub_outlined, '1. Two topics', "You'll see two\nunrelated ideas."),
      _thinkStep,
      _Step(Icons.mic_none_rounded, '3. Connect', 'Speak for\n60 seconds.'),
      _feedbackStep,
    ],
    strategyTitle: 'BUILD THE CONNECTION',
    strategy: ['Start with\nthe first idea', 'Find the\nlink or bridge', 'Land on\nthe second idea'],
  ),

  // Screen 3: Explain It Simply.
  'explain_it_simply': const _ActivitySpec(
    icon: Icons.lightbulb_outline_rounded,
    label: '3. EXPLAIN IT SIMPLY',
    title: 'Explain\nIt Simply.',
    subtitle: 'Take a complex topic and explain it in clear, simple language.',
    steps: [
      _Step(Icons.description_outlined, '1. Topic + audience', "You'll see a topic\nand who to explain it to."),
      _thinkStep,
      _Step(Icons.mic_none_rounded, '3. Explain', 'Speak\nclearly.'),
      _feedbackStep,
    ],
    strategyTitle: 'KEEP IT SIMPLE',
    strategy: ['What is it?\n(in simple terms)', 'Make it\nrelatable', 'Why does\nit matter?'],
  ),

  // Screen 4: Cut It in Half.
  'cut_it_in_half': const _ActivitySpec(
    icon: Icons.content_cut_rounded,
    label: '4. CUT IT IN HALF',
    title: 'Cut It\nin Half.',
    subtitle: 'Read a longer message and make it shorter, clearer and more impactful.',
    steps: [
      _Step(Icons.description_outlined, '1. Read', 'A longer text\nappears (45-60s).'),
      _Step(Icons.format_list_bulleted_rounded, '2. Find point', 'Identify what\nmatters.'),
      _Step(Icons.mic_none_rounded, '3. Summarise', 'Speak your\nshorter version.'),
      _feedbackStep,
    ],
    strategyTitle: 'CUT THE CLUTTER',
    strategy: ["Main point\n(key message?)", 'Essential\ndetail', 'Action\n(what next?)'],
  ),

  // Screen 5: Storytelling Gym. (3 steps matching Image 1)
  'storytelling_gym': const _ActivitySpec(
    icon: Icons.menu_book_rounded,
    label: '5. STORYTELLING GYM',
    title: 'Storytelling\nGym.',
    subtitle: 'Turn a scenario into a clear, memorable story.',
    steps: [
      _Step(Icons.description_outlined, '1. Scenario', 'A scenario\nappears.'),
      _Step(Icons.mic_none_rounded, '2. Speak', 'You have\n60 seconds.'),
      _Step(Icons.bar_chart_rounded, '3. Feedback', 'Get personalised\nfeedback.'),
    ],
    strategyTitle: 'BUILD YOUR STORY',
    strategy: ['Set the\nscene', 'Show what\nhappened', 'Land\nthe point'],
  ),

  // Screen 6: One Minute Expert.
  'one_minute_expert': const _ActivitySpec(
    icon: Icons.school_outlined,
    label: '6. ONE MINUTE EXPERT',
    title: 'One Minute\nExpert.',
    subtitle: 'Choose a topic you want to speak about and explain it confidently in one minute.',
    steps: [
      _Step(Icons.format_list_bulleted_rounded, '1. Choose topic', 'Pick a topic you\nwant to speak about.'),
      _thinkStep,
      _Step(Icons.mic_none_rounded, '3. Speak', 'You have\n60 seconds.'),
      _feedbackStep,
    ],
    strategyTitle: 'MAKE IT LAND',
    strategy: ['Hook\n(get attention)', 'Two clear\npoints', 'Strong\nfinish'],
  ),

  // Screen 7: Debate Me.
  'debate_me': const _ActivitySpec(
    icon: Icons.forum_outlined,
    label: '7. DEBATE ME',
    title: 'Debate Me.',
    subtitle: 'See a different perspective and respond with a clear, confident counterpoint.',
    steps: [
      _Step(Icons.description_outlined, '1. Position', "You'll see a statement\nor opposing view."),
      _thinkStep,
      _Step(Icons.mic_none_rounded, '3. Respond', 'Speak for\n60 seconds.'),
      _feedbackStep,
    ],
    strategyTitle: 'BUILD YOUR RESPONSE',
    strategy: ['State your\nposition', 'Give your\nreason', 'Counter\nthe objection'],
  ),
};
