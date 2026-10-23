import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/services/analytics_service.dart';
import '../providers/app_state_provider.dart';
import '../widgets/action_pill_button.dart';
import '../widgets/blue_accent_rays.dart';
import '../widgets/hakkiri_loading_overlay.dart';
import 'debate_me_screen.dart';
import 'recording_screen.dart';

/// Activity detail screen rendered pixel-perfect matching Image 2 ("Think Fast.")
/// and Image 5 ("Connect the Dots.").
class ActivityDetailScreen extends StatelessWidget {
  final String? activitySlug;

  const ActivityDetailScreen({super.key, this.activitySlug});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final slug = AppStateProvider.normalizeActivitySlug(
      activitySlug ?? state.selectedActivity?.slug ?? 'think_fast',
    );
    final spec = _activitySpecs[slug] ?? _activitySpecs['think_fast']!;
    final isDebateMe = slug == 'debate_me';
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final bottomGap = isIOS ? (safeBottom > 0 ? 20.0 : 12.0) : 14.0;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Detail UI slug must match provider — otherwise Begin loads Think Fast prompts.
      state.ensureActivitySelected(slug);
      AnalyticsService.instance.logScreenView(
        screenName: 'ActivityDetailScreen_$slug',
      );
    });

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
            // Ambient blue organic glows matching mockups
            Positioned(
              top: -40,
              right: -30,
              child: IgnorePointer(
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFBFDBFE).withValues(alpha: 0.45),
                        const Color(0xFFEFF6FF).withValues(alpha: 0.20),
                        const Color(0x00FFFFFF),
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 120,
              left: -40,
              child: IgnorePointer(
                child: Container(
                  width: 220,
                  height: 220,
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

            SafeArea(
              bottom: !isIOS,
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomGap),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Bar (< back arrow)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 6, 14, 4),
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
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Squircle Icon + Tag & Title Row (Matching Image 2 & 5)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Squircle badge (enlarged, matching design specs)
                                Container(
                                  width: 78,
                                  height: 78,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                  alignment: Alignment.center,
                                  child: spec.customIconWidget ??
                                      Icon(
                                        spec.icon,
                                        color: const Color(0xFF2563EB),
                                        size: 44,
                                      ),
                                ),
                                const SizedBox(width: 14),

                                // Tag + Title Column
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
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
                                      const SizedBox(height: 2),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Flexible(
                                            child: spec.titleWidget ??
                                                Text(
                                                  spec.title,
                                                  style: const TextStyle(
                                                    fontFamily: 'Inter',
                                                    fontSize: 30,
                                                    fontWeight: FontWeight.w900,
                                                    color: Color(0xFF0F172A),
                                                    height: 1.15,
                                                    letterSpacing: -0.7,
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
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // 2. Subtitle
                            Text(
                              spec.subtitle,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16.5,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF475569),
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 14),

                            // 3. Card: HOW IT WORKS
                            _buildHowItWorksCard(spec.steps),
                            const SizedBox(height: 12),
                            // 4. Card: Strategy (USE YOUR 5 SECONDS / BUILD THE CONNECTION)
                            _buildStrategyCard(spec.strategyTitle, spec.strategy),
                            const SizedBox(height: 14),
                            _AssignedLevelLabel(slug: slug),
                            const SizedBox(height: 18),
                          ],
                        ),
                      ),
                    ),

                    // Pinned bottom CTA — Debate Me → guided 6-step drill.
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                      child: ActionPillButton(
                        label: 'Begin exercise',
                        onTap: () async {
                          final nav = Navigator.of(context);
                          final app = context.read<AppStateProvider>();
                          // Lock provider to this drill before fetching the prompt.
                          app.ensureActivitySelected(slug);
                          app.syncDifficultyForActivity(slug);

                          if (app.isLoggedIn) {
                            await HakkiriLoadingOverlay.run(
                              context,
                              message: isDebateMe
                                  ? 'Setting up your debate…'
                                  : 'Getting your question…',
                              detail: isDebateMe
                                  ? 'Loading a workplace topic for opening + pushback.'
                                  : 'Picking a fresh prompt for this drill.',
                              action: () => app.fetchNextPromptFromApi(
                                excludeCurrent: true,
                              ),
                            );
                          } else if (!isDebateMe) {
                            app.setDifficulty(app.levelForActivity(slug));
                          }
                          if (!context.mounted) return;

                          if (isDebateMe) {
                            final topic =
                                app.selectedPrompt?.promptText.trim();
                            nav.push(
                              MaterialPageRoute(
                                builder: (_) => DebateMeScreen(
                                  topic: (topic != null && topic.isNotEmpty)
                                      ? topic
                                      : null,
                                  startAtPrompt: true,
                                ),
                              ),
                            );
                            return;
                          }

                          nav.push(
                            MaterialPageRoute(
                              builder: (_) => const RecordingScreen(
                                promptAlreadyLoaded: true,
                              ),
                            ),
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

  /// CARD 1: HOW IT WORKS — connected 4-step horizontal timeline
  Widget _buildHowItWorksCard(List<_Step> steps) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
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
                color: Color(0xFF475569),
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
                left: 28,
                right: 28,
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
            width: 50,
            height: 50,
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
            child: Icon(icon, color: const Color(0xFF2563EB), size: 23),
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
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  /// CARD 2: Strategy — 3 mini cards (blue / red / green) with connecting arrows
  Widget _buildStrategyCard(String title, List<String> steps) {
    const bgColors = [Color(0xFFEFF6FF), Color(0xFFFFF1F2), Color(0xFFF0FDF4)];
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
          child: Icon(Icons.arrow_forward_rounded, color: Color(0xFF2563EB), size: 15),
        ));
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
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
                color: Color(0xFF475569),
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(color: numColor, shape: BoxShape.circle),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
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
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Per-activity specifications matching Image 2 & Image 5 ────────────────────

class _Step {
  final IconData icon;
  final String title;
  final String sub;
  const _Step(this.icon, this.title, this.sub);
}

class _ActivitySpec {
  final IconData icon;
  final Widget? customIconWidget;
  final String label;
  final String title;
  final Widget? titleWidget;
  final String subtitle;
  final List<_Step> steps;
  final String strategyTitle;
  final List<String> strategy;

  const _ActivitySpec({
    required this.icon,
    this.customIconWidget,
    required this.label,
    required this.title,
    this.titleWidget,
    required this.subtitle,
    required this.steps,
    required this.strategyTitle,
    required this.strategy,
  });
}

const _thinkStep = _Step(Icons.timer_outlined, '2. Think', 'You have\n5 seconds.');
const _feedbackStep = _Step(Icons.bar_chart_rounded, '4. Feedback', 'Get\npersonalised\nfeedback.');

final Map<String, _ActivitySpec> _activitySpecs = {
  // Screen 1: Think Fast. (Matching Image 2)
  'think_fast': _ActivitySpec(
    icon: Icons.bolt_rounded,
    customIconWidget: SizedBox(
      width: 38,
      height: 38,
      child: CustomPaint(painter: _LightningBoltPainter()),
    ),
    label: '1. THINK FAST',
    title: 'Think Fast.',
    titleWidget: RichText(
      text: const TextSpan(
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 32,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.8,
        ),
        children: [
          TextSpan(text: 'Think ', style: TextStyle(color: Color(0xFF0F172A))),
          TextSpan(text: 'Fast.', style: TextStyle(color: Color(0xFF2563EB))),
        ],
      ),
    ),
    subtitle: 'Answer a surprise question clearly, the way you would in a real meeting.',
    steps: const [
      _Step(Icons.description_outlined, '1. Question', 'A random\nquestion\nappears.'),
      _thinkStep,
      _Step(Icons.mic_none_rounded, '3. Speak', 'Record for\n60 seconds.'),
      _feedbackStep,
    ],
    strategyTitle: 'USE YOUR 5 SECONDS',
    strategy: const ['Pick\nyour point', 'Choose\nwhy', 'Add one\nexample'],
  ),

  // Screen 2: Connect the Dots. (Matching Image 5)
  'connect_the_dots': _ActivitySpec(
    icon: Icons.hub_rounded,
    customIconWidget: SizedBox(
      width: 38,
      height: 38,
      child: CustomPaint(painter: _ConnectedNodesPainter()),
    ),
    label: '2. CONNECT THE DOTS',
    title: 'Connect\nthe Dots.',
    titleWidget: RichText(
      text: const TextSpan(
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 30,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.8,
          height: 1.15,
        ),
        children: [
          TextSpan(text: 'Connect\n', style: TextStyle(color: Color(0xFF0F172A))),
          TextSpan(text: 'the Dots.', style: TextStyle(color: Color(0xFF2563EB))),
        ],
      ),
    ),
    subtitle: 'Link two random ideas into a clear, compelling story.',
    steps: const [
      _Step(Icons.link_rounded, '1. Two topics', "You'll see two\nunrelated ideas."),
      _thinkStep,
      _Step(Icons.mic_none_rounded, '3. Connect', 'Speak a\n60 second story.'),
      _feedbackStep,
    ],
    strategyTitle: 'BUILD THE CONNECTION',
    strategy: const ['Start with\nthe first idea', 'Find the\nlink or bridge', 'Land on\nthe second idea'],
  ),

  // Screen 3: Explain It Simply.
  'explain_it_simply': _ActivitySpec(
    icon: Icons.lightbulb_outline_rounded,
    label: '3. EXPLAIN IT SIMPLY',
    title: 'Explain\nIt Simply.',
    titleWidget: RichText(
      text: const TextSpan(
        style: TextStyle(fontFamily: 'Inter', fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: -0.8, height: 1.15),
        children: [
          TextSpan(text: 'Explain\n', style: TextStyle(color: Color(0xFF0F172A))),
          TextSpan(text: 'It Simply.', style: TextStyle(color: Color(0xFF2563EB))),
        ],
      ),
    ),
    subtitle: 'Take a complex topic and explain it in clear, simple language.',
    steps: const [
      _Step(Icons.description_outlined, '1. Topic + audience', "You'll see a topic\nand audience."),
      _thinkStep,
      _Step(Icons.mic_none_rounded, '3. Explain', 'Speak\nclearly.'),
      _feedbackStep,
    ],
    strategyTitle: 'KEEP IT SIMPLE',
    strategy: const ['What is it?\n(in simple terms)', 'Make it\nrelatable', 'Why does\nit matter?'],
  ),

  // Screen 4: Cut It in Half.
  'cut_it_in_half': _ActivitySpec(
    icon: Icons.content_cut_rounded,
    label: '4. CUT IT IN HALF',
    title: 'Cut It\nin Half.',
    titleWidget: RichText(
      text: const TextSpan(
        style: TextStyle(fontFamily: 'Inter', fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: -0.8, height: 1.15),
        children: [
          TextSpan(text: 'Cut It\n', style: TextStyle(color: Color(0xFF0F172A))),
          TextSpan(text: 'in Half.', style: TextStyle(color: Color(0xFF2563EB))),
        ],
      ),
    ),
    subtitle: 'Read a longer message and make it shorter, clearer and more impactful.',
    steps: const [
      _Step(Icons.description_outlined, '1. Read', 'A longer text\nappears (45-60s).'),
      _Step(Icons.format_list_bulleted_rounded, '2. Find point', 'Identify what\nmatters.'),
      _Step(Icons.mic_none_rounded, '3. Summarise', 'Speak your\nshorter version.'),
      _feedbackStep,
    ],
    strategyTitle: 'CUT THE CLUTTER',
    strategy: const [
      "Main point\n(What's the key message?)",
      'Essential\ndetail',
      'Action\n(what next?)',
    ],
  ),

  // Screen 5: Storytelling Gym.
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

  // Screen 7: Debate Me. — overview only; Begin starts live back-and-forth.
  'debate_me': const _ActivitySpec(
    icon: Icons.forum_outlined,
    label: '7. DEBATE ME',
    title: 'Debate Me.',
    subtitle:
        'Practice. Respond. Improve. A guided debate to help you think clearly, respond with confidence, and get better.',
    steps: [
      _Step(Icons.description_outlined, '1. Prompt', 'A debate\ntopic appears.'),
      _thinkStep,
      _Step(Icons.mic_none_rounded, '3. Opening', 'State your\nposition live.'),
      _Step(Icons.forum_outlined, '4. Pushback', 'Hakkiri\nchallenges you.'),
    ],
    strategyTitle: 'BUILD YOUR RESPONSE',
    strategy: [
      'State your\nposition',
      'Give your\nreason',
      'Counter\nthe objection',
    ],
  ),
};

/// Crisp custom painter for the outline lightning bolt matching Image 2
class _LightningBoltPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final path = Path();
    path.moveTo(w * 0.58, 2);
    path.lineTo(w * 0.20, h * 0.56);
    path.lineTo(w * 0.52, h * 0.56);
    path.lineTo(w * 0.38, h - 2);
    path.lineTo(w * 0.82, h * 0.42);
    path.lineTo(w * 0.50, h * 0.42);
    path.close();

    final paint = Paint()
      ..color = const Color(0xFF2563EB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AssignedLevelLabel extends StatelessWidget {
  final String slug;
  const _AssignedLevelLabel({required this.slug});

  static String _label(String code) {
    switch (code) {
      case 'beginner':
        return 'Beginner';
      case 'professional':
      case 'pro':
        return 'Pro';
      default:
        return 'Intermediate';
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final current = _label(state.levelForActivity(slug));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'LEVEL',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            color: Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  current,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'You’ll practice at this level. Hakkiri may suggest a change after a week.',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Crisp custom painter for the connected nodes icon matching Image 5
class _ConnectedNodesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final topNode = Offset(w * 0.5, h * 0.22);
    final leftNode = Offset(w * 0.22, h * 0.78);
    final rightNode = Offset(w * 0.78, h * 0.78);

    final linePaint = Paint()
      ..color = const Color(0xFF2563EB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(topNode, leftNode, linePaint);
    canvas.drawLine(topNode, rightNode, linePaint);
    canvas.drawLine(leftNode, rightNode, linePaint);

    final nodeOutline = Paint()
      ..color = const Color(0xFF2563EB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;

    final nodeFill = Paint()..color = const Color(0xFFEFF6FF);

    for (final node in [topNode, leftNode, rightNode]) {
      canvas.drawCircle(node, 4.5, nodeFill);
      canvas.drawCircle(node, 4.5, nodeOutline);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
