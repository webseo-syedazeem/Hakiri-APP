import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/action_pill_button.dart';
import '../widgets/blue_accent_rays.dart';
import '../widgets/onboarding_bubble_background.dart';
import '../widgets/who_its_for_roadmap_view.dart';
import '../widgets/twelve_months_roadmap_view.dart';
import 'assessment_screen.dart';
import 'login_screen.dart';

/// Onboarding experience.
///
/// New-account funnel:
///   Welcome (Get started) → Signup → onboarding pages → Assessment → Home
///
/// [postSignup] = true starts at page 1 (skip welcome) after account create.
class LandingScreen extends StatefulWidget {
  final int initialPage;

  /// After signup: show onboarding pages then Assessment (not Signup again).
  final bool postSignup;

  const LandingScreen({
    super.key,
    this.initialPage = 0,
    this.postSignup = false,
  });

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late final PageController _trainCardController;
  late final AnimationController _entryController;
  late final Animation<Offset> _entrySlide;
  int _currentPage = 0;
  int _carouselIndex = 0;

  static const _sectionLabels = [
    'Get started',
    'See feedback',
    'Explore exercises',
    'Is Hakkiri for me?',
    'Why Hakkiri?',
    'Explore your learning path',
    'Start assessment',
  ];

  @override
  void initState() {
    super.initState();
    // Post-signup onboarding skips the welcome/signup page.
    final start = widget.postSignup
        ? (widget.initialPage > 0 ? widget.initialPage : 1)
        : widget.initialPage;
    _currentPage = start;
    _pageController = PageController(initialPage: start);
    _trainCardController = PageController(viewportFraction: 0.76);

    // Smooth entrance: the screen fades in and gently rises into place as it
    // opens, so it never pops in abruptly after the splash transition.
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _entrySlide = Tween<Offset>(
      begin: const Offset(0.0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic));

    // Start just after first frame so the opening is seen, not skipped.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entryController.forward();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _trainCardController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 6) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _goToAssessment();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.animateToPage(
        _currentPage - 1,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _goToAssessment() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AssessmentScreen()),
    );
  }

  void _goToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    // iOS SafeArea was leaving a tall empty band under the button.
    // Keep a small clearance for the home indicator instead of the full inset.
    final bottomGap = isIOS ? (safeBottom > 0 ? 20.0 : 12.0) : 14.0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark, // Dark text/icons on Android
        statusBarBrightness: Brightness.light,    // Dark text/icons on iOS
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // Soft blue ambient bubbles behind the whole onboarding flow
            // (matches the design spec; replaces the flat white canvas).
            const OnboardingBubbleBackground(),
            SafeArea(
          bottom: !isIOS,
          child: SlideTransition(
            position: _entrySlide,
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomGap),
              child: Column(
            children: [
              // Pinned Still Top Bar (< back, Skip) - stays fixed while pages slide
              if (_currentPage > 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 6, 24, 0),
                  child: _buildTopBar(),
                ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (idx) => setState(() => _currentPage = idx),
                  children: [
                    _buildWelcomePage(),
                    _buildSeeHowItWorksPage(),
                    _buildSeeFeedbackPage(),
                    _buildTrainCarouselPage(),
                    _buildWhoItsForPage(),
                    _buildTrustedByProfessionalsPage(),
                    _buildSuggestedPracticePathPage(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 6, 24, 0),
                child: Column(
                  children: [
                    // Screen-specific pagination indicators above button
                    if (_currentPage == 1) ...[
                      // See how it works: 2-dot sub-flow (prompt)
                      _buildDotsIndicator(activeIndex: 0, totalDots: 2),
                      const SizedBox(height: 12),
                    ] else if (_currentPage == 2) ...[
                      // See your feedback: 2-dot sub-flow (feedback)
                      _buildDotsIndicator(activeIndex: 1, totalDots: 2),
                      const SizedBox(height: 12),
                    ] else if (_currentPage == 4) ...[
                      // Who it's for: 5 dots
                      _buildDotsIndicator(activeIndex: 0, totalDots: 5),
                      const SizedBox(height: 12),
                    ] else if (_currentPage == 5) ...[
                      // Testimonials: 4 dots
                      _buildDotsIndicator(activeIndex: 0, totalDots: 4),
                      const SizedBox(height: 12),
                    ] else if (_currentPage == 6) ...[
                      // Plan: 6 dots left-aligned
                      _buildDotsIndicator(
                        activeIndex: 5,
                        totalDots: 6,
                        alignment: MainAxisAlignment.start,
                      ),
                      const SizedBox(height: 12),
                    ],

                    ActionPillButton(
                      // Walk through every onboarding screen in order; the last
                      // one ("Start assessment") goes to the assessment, which
                      // prompts sign-up on completion if needed.
                      label: _sectionLabels[_currentPage],
                      onTap: _currentPage >= _sectionLabels.length - 1
                          ? _goToAssessment
                          : _nextPage,
                    ),

                    if (_currentPage == 0) ...[
                      const SizedBox(height: 14),
                      Center(
                        child: GestureDetector(
                          onTap: _goToLogin,
                          child: RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13.5,
                                color: Color(0xFF64748B),
                              ),
                              children: [
                                TextSpan(text: 'I already have an account. '),
                                TextSpan(
                                  text: 'Log in',
                                  style: TextStyle(
                                    color: Color(0xFF2563EB),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDotsIndicator(activeIndex: 0, totalDots: 3),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
            ),
      ),
          ],
        ),
    ));
  }

  // ==========================================
  // PAGE 0: WELCOME (media_1791376750433.png)
  // ==========================================
  Widget _buildWelcomePage() {
    return Stack(
      children: [
        // Subtle ambient top-right pastel organic gradient backdrop (Image 2)
        Positioned(
          top: -40,
          right: -40,
          child: IgnorePointer(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFE8F2FE).withValues(alpha: 0.60),
                    const Color(0xFFF1F6FF).withValues(alpha: 0.35),
                    const Color(0x00FFFFFF),
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // Heading
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Think clearly.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          height: 1.15,
                          letterSpacing: -1.0,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Transform.translate(
                        offset: const Offset(0, -8),
                        child: const BlueAccentRays(size: 26),
                      ),
                    ],
                  ),
                  const Text(
                    'Speak with\npurpose.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2563EB),
                      height: 1.15,
                      letterSpacing: -1.0,
                    ),
                  ),
                ],
              ),

              // Center Logo & Clean Pastel Ambient Surrounds (Matching Image 2)
              Expanded(
                child: Center(
                  child: SizedBox(
                    width: 290,
                    height: 290,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Soft clean pastel background blobs & floating accent bubbles
                        CustomPaint(
                          size: const Size(290, 290),
                          painter: _FluidAmbientBlobsPainter(),
                        ),
                        // Ambient accent rays to the top left of the mark
                        Positioned(
                          top: 40,
                          left: 32,
                          child: Transform.rotate(
                            angle: -0.65,
                            child: const BlueAccentRays(size: 26),
                          ),
                        ),
                        // Hakkiri Iconic Mark
                        Image.asset(
                          'assets/images/hakkiri_icon.png',
                          width: 155,
                          height: 155,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Subtitle: Exercises. AI feedback. Data insights.
              const Center(
                child: Text(
                  'Exercises. AI feedback. Data insights.',
                  style: TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // PAGE 1: WHO IT'S FOR (media_1791376777628.png)
  // ==========================================
  Widget _buildWhoItsForPage() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tag: WHO IT'S FOR
          const Text(
            'WHO IT\'S FOR',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 6),

          // Headline
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Built for meetings,',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 27,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      height: 1.18,
                      letterSpacing: -0.7,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Transform.translate(
                    offset: const Offset(0, -6),
                    child: const BlueAccentRays(size: 24),
                  ),
                ],
              ),
              const Text(
                'interviews and everyday\nconversations.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2563EB),
                  height: 1.18,
                  letterSpacing: -0.7,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Center Roadmap Graphic (100% Crisp Native Vector)
          const Expanded(
            child: Center(
              child: WhoItsForRoadmapView(),
            ),
          ),

          // Subtitle Caption
          const Center(
            child: Text(
              'Use it wherever you need to think and speak\nmore clearly.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ==========================================
  // PAGE 2: TRAIN CAROUSEL (media_1791376770055.png)
  // ==========================================
  Widget _buildTrainCarouselPage() {
    final exercises = [
      {
        'tag': '01 - 07',
        'title': 'Think Fast',
        'tagline': 'Think clearly under pressure.',
        'desc': 'Answer an unexpected question with a few seconds to prepare, then speak for 60 seconds.',
        'type': 'think_fast',
      },
      {
        'tag': '02 - 07',
        'title': 'Connect\nthe Dots',
        'tagline': 'Make unexpected connections.',
        'desc': 'Link two unrelated topics into one clear, logical idea.',
        'type': 'connect_dots',
      },
      {
        'tag': '03 - 07',
        'title': 'Explain\nIt Simply',
        'tagline': 'Make complex ideas easy to understand.',
        'desc': 'Take a complicated topic and explain it clearly to someone without specialist knowledge.',
        'type': 'explain',
      },
      {
        'tag': '04 - 07',
        'title': 'Cut It\nin Half',
        'tagline': 'Get to the point faster.',
        'desc': 'Turn a long message into a shorter, clearer summary without losing the meaning.',
        'type': 'cut_it_in_half',
      },
      {
        'tag': '05 - 07',
        'title': 'Storytelling\nGym',
        'tagline': 'Make people lean in.',
        'desc': 'Turn information into a structured, memorable story with a clear point.',
        'type': 'storytelling',
      },
      {
        'tag': '06 - 07',
        'title': 'One Minute\nExpert',
        'tagline': 'Know it. Explain it.',
        'desc': 'Choose a topic and explain it clearly, confidently and coherently in 60 seconds.',
        'type': 'stopwatch',
      },
      {
        'tag': '07 - 07',
        'title': 'Debate\nMe',
        'tagline': 'Hold your ground.',
        'desc': 'Respond to a challenging position with a clear, confident rebuttal under pressure.',
        'type': 'debate',
      },
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Headline
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                height: 1.15,
                letterSpacing: -0.8,
              ),
              children: [
                TextSpan(text: 'Train the way you\n'),
                TextSpan(
                  text: 'think and speak.',
                  style: TextStyle(color: Color(0xFF2563EB)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Subtitle
          const Text(
            'Short guided exercises for clearer, quicker, more confident communication.',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),

          // Exercise Carousel Cards
          Expanded(
            child: PageView.builder(
              itemCount: exercises.length,
              controller: _trainCardController,
              onPageChanged: (idx) => setState(() => _carouselIndex = idx),
              itemBuilder: (context, idx) {
                final ex = exercises[idx];
                return Padding(
                  padding: const EdgeInsets.only(right: 12, bottom: 8, top: 4),
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                          blurRadius: 22,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Badge: 01 - 05
                        Text(
                          ex['tag']!,
                          style: const TextStyle(
                            color: Color(0xFF3B82F6),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Title
                        Text(
                          ex['title']!,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            height: 1.15,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Tagline (blue)
                        Text(
                          ex['tagline']!,
                          style: const TextStyle(
                            color: Color(0xFF2563EB),
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Description
                        Text(
                          ex['desc']!,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            height: 1.35,
                          ),
                        ),
                        const Spacer(),

                        // Graphic Illustration (100% Crisp Native Vector Graphics)
                        Center(
                          child: _buildExerciseIllustration(ex['type']!),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Pagination Dots + "1 of 5 exercises"
          Center(
            child: Column(
              children: [
                _buildFiveDotsIndicator(
                  activeIndex: _carouselIndex,
                  totalDots: exercises.length,
                ),
                const SizedBox(height: 6),
                Text(
                  '${_carouselIndex + 1} of ${exercises.length} exercises',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ==========================================
  // PAGE 3: SEE HOW IT WORKS (media_1791376757890.png)
  // ==========================================
  Widget _buildSeeHowItWorksPage() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tag: EXAMPLE ACTIVITY
          const Text(
            'EXAMPLE ACTIVITY',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),

          // Headline
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'See how',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  height: 1.15,
                  letterSpacing: -0.8,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'it works.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2563EB),
                      height: 1.15,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Transform.translate(
                    offset: const Offset(0, -6),
                    child: const BlueAccentRays(size: 26),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Subheading
          const Text(
            'Try a short exercise and see the kind of feedback you\'ll receive.',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),

          // Single card, centred — this is its own swipe-screen (no scroll).
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: _buildPromptExerciseCard(),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ==========================================
  // PAGE 2: SEE YOUR FEEDBACK (own swipe-screen, no scroll)
  // ==========================================
  Widget _buildSeeFeedbackPage() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'EXAMPLE FEEDBACK',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'See your',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  height: 1.15,
                  letterSpacing: -0.8,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'feedback.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2563EB),
                      height: 1.15,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Transform.translate(
                    offset: const Offset(0, -6),
                    child: const BlueAccentRays(size: 26),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Clear, personalised feedback grounded in research.',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: _buildFeedbackResultCard(),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ==========================================
  // PAGE 4: TRUSTED BY PROFESSIONALS (media_1791378878108.png)
  // ==========================================
  Widget _buildTrustedByProfessionalsPage() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tag: WHY HAKKIRI?
          const Text(
            'WHY HAKKIRI?',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 6),

          // Headline
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Trusted by',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  height: 1.15,
                  letterSpacing: -0.8,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'professionals.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2563EB),
                      height: 1.15,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Transform.translate(
                    offset: const Offset(0, -6),
                    child: const BlueAccentRays(size: 26),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Subtitle
          const Text(
            'Used by professionals from top organisations and universities.',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),

          // 3 Testimonial Cards
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _buildTestimonialCard(
                    quote: '“It helps me organise my thoughts and get to the point faster.”',
                    author: 'Consultant, Big 4',
                    avatarAsset: 'assets/images/avatar_consultant.png',
                  ),
                  const SizedBox(height: 10),
                  _buildTestimonialCard(
                    quote: '“The feedback is specific, practical and easy to apply.”',
                    author: 'Professional, The Economist',
                    avatarAsset: 'assets/images/avatar_economist.png',
                  ),
                  const SizedBox(height: 10),
                  _buildTestimonialCard(
                    quote: '“A smart way to practise speaking with more clarity and confidence.”',
                    author: 'Student, Queen Mary University',
                    avatarAsset: 'assets/images/avatar_student.png',
                  ),
                  const SizedBox(height: 12),

                  // Organization Pills Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildOrgPill('Big 4'),
                      const SizedBox(width: 8),
                      _buildOrgPill('The Economist'),
                      const SizedBox(width: 8),
                      _buildOrgPill('Queen Mary University'),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ==========================================
  // PAGE 5: SUGGESTED PRACTICE PATH (media_1791378897108.png)
  // ==========================================
  Widget _buildSuggestedPracticePathPage() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tag: A SUGGESTED PRACTICE PATH
          const Text(
            'A SUGGESTED PRACTICE PATH',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.3,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),

          // Headline
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                height: 1.15,
                letterSpacing: -0.8,
              ),
              children: [
                TextSpan(text: 'Twelve months,\n'),
                TextSpan(
                  text: 'one step at a time.',
                  style: TextStyle(color: Color(0xFF2563EB)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // Subtitle
          const Text(
            'A starting point to help you build momentum.',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),

          // Winding Roadmap Graphic (100% Crisp Native Vector)
          const Expanded(
            child: Center(
              child: TwelveMonthsRoadmapView(),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildTestimonialCard({
    required String quote,
    required String author,
    required String avatarAsset,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Quote badge
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text(
              '“',
              style: TextStyle(
                color: Color(0xFF2563EB),
                fontSize: 22,
                fontWeight: FontWeight.w900,
                height: 1.0,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quote,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  author,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Portrait Avatar
          ClipOval(
            child: Image.asset(
              avatarAsset,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrgPill(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF475569),
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ==========================================
  // HELPER WIDGETS
  // ==========================================

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: _previousPage,
          child: const Padding(
            padding: EdgeInsets.all(4.0),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF0F172A),
              size: 20,
            ),
          ),
        ),
        GestureDetector(
          onTap: _goToAssessment,
          child: const Padding(
            padding: EdgeInsets.all(4.0),
            child: Text(
              'Skip',
              style: TextStyle(
                color: Color(0xFF2563EB),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDotsIndicator({
    required int activeIndex,
    required int totalDots,
    Color activeColor = const Color(0xFF0F172A),
    Color inactiveColor = const Color(0xFFCBD5E1),
    MainAxisAlignment alignment = MainAxisAlignment.center,
  }) {
    return Row(
      mainAxisAlignment: alignment,
      children: List.generate(totalDots, (index) {
        final isActive = index == activeIndex;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? activeColor : inactiveColor,
          ),
        );
      }),
    );
  }

  Widget _buildFiveDotsIndicator({required int activeIndex, int totalDots = 5}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalDots, (index) {
        final isActive = index == activeIndex;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }

  Widget _buildPromptExerciseCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Mic Icon, Title, "1 min" badge
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.mic_rounded, color: Color(0xFF2563EB), size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'Storytelling Gym',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.access_time_rounded, color: Color(0xFF2563EB), size: 13),
                    SizedBox(width: 4),
                    Text(
                      '1 min',
                      style: TextStyle(
                        color: Color(0xFF2563EB),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Subtitle
          const Text(
            'Speak for 1 minute on a real-life topic. We\'ll give you instant, personalised feedback.',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),

          // Quote box & Interactive Mic Target
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Quote Box
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Text(
                    '“ Tell us about a time you\nsolved a problem. ”',
                    style: TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Mic Button with Soundwaves, Rays, and "Tap to start"
              Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Left soundwave bars
                      Column(
                        children: [
                          Container(width: 2.5, height: 10, decoration: BoxDecoration(color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(2))),
                          const SizedBox(height: 3),
                          Container(width: 2.5, height: 16, decoration: BoxDecoration(color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(2))),
                          const SizedBox(height: 3),
                          Container(width: 2.5, height: 8, decoration: BoxDecoration(color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(2))),
                        ],
                      ),
                      const SizedBox(width: 6),

                      // Glowing Mic Circle with Top-Right Radiating Rays
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: const RadialGradient(
                                center: Alignment(-0.2, -0.3),
                                radius: 0.9,
                                colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF2563EB).withValues(alpha: 0.45),
                                  blurRadius: 14,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: const Icon(Icons.mic_rounded, color: Colors.white, size: 26),
                          ),
                          // Top-right radiating accent rays
                          Positioned(
                            top: -6,
                            right: -8,
                            child: Transform.rotate(
                              angle: 0.25,
                              child: const BlueAccentRays(size: 14),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 6),

                      // Right soundwave bars
                      Column(
                        children: [
                          Container(width: 2.5, height: 8, decoration: BoxDecoration(color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(2))),
                          const SizedBox(height: 3),
                          Container(width: 2.5, height: 16, decoration: BoxDecoration(color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(2))),
                          const SizedBox(height: 3),
                          Container(width: 2.5, height: 10, decoration: BoxDecoration(color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(2))),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tap to start',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackResultCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Bar icon, "Your feedback", "✓ Instant results"
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.bar_chart_rounded, color: Color(0xFF2563EB), size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'Your feedback',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_rounded, color: Color(0xFF16A34A), size: 13),
                    SizedBox(width: 4),
                    Text(
                      'Instant results',
                      style: TextStyle(
                        color: Color(0xFF16A34A),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Subtitle
          const Text(
            'Get clear, data-backed insights based on proven research.',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),

          // 4 Score Metrics
          _buildMetricRow(Icons.chat_bubble_outline_rounded, 'Clarity', 4),
          const SizedBox(height: 8),
          _buildMetricRow(Icons.track_changes_rounded, 'Structure', 3),
          const SizedBox(height: 8),
          _buildMetricRow(Icons.groups_2_outlined, 'Confidence', 4),
          const SizedBox(height: 8),
          _buildMetricRow(Icons.lightbulb_outline_rounded, 'Engagement', 3),
          const SizedBox(height: 12),

          // Summary Chips Row: "What went well" & "Next time"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.auto_awesome_rounded, color: Color(0xFF2563EB), size: 14),
                            const SizedBox(width: 4),
                            const Text(
                              'What went well',
                              style: TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Clear structure and confident tone.',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 10.5,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    color: const Color(0xFFE2E8F0),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.lightbulb_rounded, color: Color(0xFFEAB308), size: 14),
                            const SizedBox(width: 4),
                            const Text(
                              'Next time',
                              style: TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Try to add more detail and personal examples.',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 10.5,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(IconData icon, String label, int score) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF64748B), size: 16),
        const SizedBox(width: 8),
        SizedBox(
          width: 85,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        // 5 Pill segments
        Expanded(
          child: Row(
            children: List.generate(5, (idx) {
              final isFilled = idx < score;
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  height: 9,
                  decoration: BoxDecoration(
                    color: isFilled ? const Color(0xFF3B82F6) : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$score/5',
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  /// Dispatches to the right exercise illustration for the onboarding carousel.
  Widget _buildExerciseIllustration(String type) {
    switch (type) {
      case 'storytelling':
        return _buildStorytellingIllustration();
      case 'stopwatch':
        return _buildStopwatchIllustration();
      case 'debate':
        return _buildDebateIllustration();
      case 'cut_it_in_half':
        return _buildCutInHalfIllustration();
      case 'connect_dots':
        return _buildConnectDotsIllustration();
      case 'explain':
        return _buildExplainIllustration();
      case 'think_fast':
      default:
        return _buildThinkFastIllustration();
    }
  }

  /// "Connect the Dots" — three linked nodes (molecule) in blue tints.
  Widget _buildConnectDotsIllustration() {
    return const SizedBox(
      width: 130,
      height: 100,
      child: CustomPaint(painter: _ConnectDotsPainter()),
    );
  }

  /// "Explain It Simply" — a glowing lightbulb with a soft blue halo.
  Widget _buildExplainIllustration() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Container(
        width: 58,
        height: 58,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
          ),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.lightbulb_rounded, color: Colors.white, size: 32),
      ),
    );
  }

  Widget _buildStopwatchIllustration() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF93C5FD), width: 3),
      ),
      child: const Center(
        child: Icon(Icons.timer_outlined, color: Color(0xFF2563EB), size: 48),
      ),
    );
  }

  Widget _buildDebateIllustration() {
    return SizedBox(
      width: 110,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 10,
            top: 15,
            child: Container(
              width: 50,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 22),
            ),
          ),
          Positioned(
            right: 10,
            bottom: 15,
            child: Container(
              width: 50,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFDBEAFE),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.chat_bubble_outline, color: Color(0xFF2563EB), size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorytellingIllustration() {
    return const SizedBox(
      width: 140,
      height: 100,
      child: CustomPaint(
        painter: _Storytelling3dPathPainter(),
      ),
    );
  }

  Widget _buildCutInHalfIllustration() {
    return SizedBox(
      width: 120,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 6,
            top: 16,
            child: Container(
              width: 88,
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 3.5,
                    width: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF94A3B8),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 3.5,
                    width: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 6,
            bottom: 16,
            child: Container(
              width: 66,
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 3.5,
                    width: 45,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 3.5,
                    width: 26,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.content_cut_rounded, color: Colors.white, size: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildThinkFastIllustration() {
    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF93C5FD), width: 2.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Container(
        width: 58,
        height: 58,
        decoration: const BoxDecoration(
          color: Color(0xFF2563EB),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 34),
      ),
    );
  }
}

/// "Connect the Dots" — three nodes joined by soft links, like a molecule.
class _ConnectDotsPainter extends CustomPainter {
  const _ConnectDotsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final nodes = [
      Offset(w * 0.20, h * 0.68),
      Offset(w * 0.52, h * 0.30),
      Offset(w * 0.82, h * 0.62),
    ];
    const radii = [16.0, 22.0, 13.0];

    // Links between the nodes.
    final linkPaint = Paint()
      ..color = const Color(0xFF93C5FD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(nodes[0], nodes[1], linkPaint);
    canvas.drawLine(nodes[1], nodes[2], linkPaint);

    // Soft glow behind the nodes.
    for (int i = 0; i < nodes.length; i++) {
      final glow = Paint()
        ..color = const Color(0xFF2563EB).withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(nodes[i], radii[i] + 4, glow);
    }

    // Node spheres with a top-left highlight for a 3D feel.
    for (int i = 0; i < nodes.length; i++) {
      final sphere = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.5),
          colors: const [Color(0xFF60A5FA), Color(0xFF1D4ED8)],
        ).createShader(Rect.fromCircle(center: nodes[i], radius: radii[i]));
      canvas.drawCircle(nodes[i], radii[i], sphere);

      final highlight = Paint()..color = Colors.white.withValues(alpha: 0.55);
      canvas.drawCircle(
        nodes[i].translate(-radii[i] * 0.3, -radii[i] * 0.35),
        radii[i] * 0.28,
        highlight,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 100% Crisp 3D Isometric Vector Painter for Storytelling Gym
class _Storytelling3dPathPainter extends CustomPainter {
  const _Storytelling3dPathPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Soft Ambient glow under the path
    final glowPaint = Paint()
      ..color = const Color(0xFF60A5FA).withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.72), width: w * 0.85, height: h * 0.35),
      glowPaint,
    );

    // 2. Curving 3D Perspective Ribbon / Path
    final path = Path();
    path.moveTo(w * 0.1, h * 0.78);
    path.cubicTo(w * 0.35, h * 0.85, w * 0.65, h * 0.75, w * 0.95, h * 0.52);
    path.lineTo(w * 0.93, h * 0.44);
    path.cubicTo(w * 0.65, h * 0.66, w * 0.35, h * 0.75, w * 0.1, h * 0.68);
    path.close();

    final ribbonPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0xFF2563EB),
          Color(0xFF60A5FA),
          Color(0xFFBAE6FD),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(path, ribbonPaint);

    // 3. Card 3 (Back / Top Right)
    _draw3dCard(
      canvas,
      rect: Rect.fromLTWH(w * 0.68, h * 0.28, w * 0.20, h * 0.32),
      color: const Color(0xFFDBEAFE),
      borderColor: const Color(0xFF93C5FD),
      lineColor: const Color(0xFF60A5FA),
    );

    // 4. Card 2 (Middle)
    _draw3dCard(
      canvas,
      rect: Rect.fromLTWH(w * 0.42, h * 0.36, w * 0.24, h * 0.38),
      color: const Color(0xFF38BDF8),
      borderColor: const Color(0xFF0284C7),
      lineColor: Colors.white,
    );

    // 5. Card 1 (Front / Left)
    _draw3dCard(
      canvas,
      rect: Rect.fromLTWH(w * 0.12, h * 0.45, w * 0.28, h * 0.46),
      color: const Color(0xFF1D4ED8),
      borderColor: const Color(0xFF1E40AF),
      lineColor: Colors.white,
      isFront: true,
    );
  }

  void _draw3dCard(
    Canvas canvas, {
    required Rect rect,
    required Color color,
    required Color borderColor,
    required Color lineColor,
    bool isFront = false,
  }) {
    // Drop shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: isFront ? 0.15 : 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.translate(2, 4), const Radius.circular(8)),
      shadowPaint,
    );

    // Card Body
    final cardRRect = RRect.fromRectAndRadius(rect, const Radius.circular(8));
    final cardPaint = Paint()..color = color;
    canvas.drawRRect(cardRRect, cardPaint);

    // Card Border
    final borderPaint = Paint()
      ..color = borderColor.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRRect(cardRRect, borderPaint);

    // Card Text Lines
    final linePaint = Paint()
      ..color = lineColor.withValues(alpha: isFront ? 0.9 : 0.75)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = isFront ? 2.2 : 1.8;

    final lineX = rect.left + rect.width * 0.18;
    final lineW1 = rect.width * 0.64;
    final lineW2 = rect.width * 0.45;
    final lineW3 = rect.width * 0.55;

    final topOffset = rect.top + rect.height * 0.28;
    final gap = rect.height * 0.18;

    canvas.drawLine(Offset(lineX, topOffset), Offset(lineX + lineW1, topOffset), linePaint);
    canvas.drawLine(Offset(lineX, topOffset + gap), Offset(lineX + lineW2, topOffset + gap), linePaint);
    if (isFront) {
      canvas.drawLine(Offset(lineX, topOffset + gap * 2), Offset(lineX + lineW3, topOffset + gap * 2), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Clean, professional ambient pastel surrounds for welcome page matching Image 2
class _FluidAmbientBlobsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.5);

    // 1. Soft organic backdrop shape in the upper-right / behind mark
    final organicPath = Path()
      ..moveTo(size.width * 0.45, 0)
      ..cubicTo(
        size.width * 0.80, size.height * 0.04,
        size.width * 1.05, size.height * 0.22,
        size.width * 0.98, size.height * 0.52,
      )
      ..cubicTo(
        size.width * 0.92, size.height * 0.80,
        size.width * 0.72, size.height * 0.96,
        size.width * 0.50, size.height * 0.95,
      )
      ..cubicTo(
        size.width * 0.28, size.height * 0.94,
        size.width * 0.12, size.height * 0.78,
        size.width * 0.14, size.height * 0.58,
      )
      ..cubicTo(
        size.width * 0.16, size.height * 0.36,
        size.width * 0.25, size.height * 0.12,
        size.width * 0.45, 0,
      )
      ..close();

    final organicPaint = Paint()
      ..color = const Color(0xFFEFF6FF).withValues(alpha: 0.75)
      ..style = PaintingStyle.fill;
    canvas.drawPath(organicPath, organicPaint);

    // 2. Soft ambient circular glow - Fading to pure transparent white (0x00FFFFFF)
    // to prevent ANY dirty grey radial banding
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFE2EFFF).withValues(alpha: 0.80),
          const Color(0xFFEFF6FF).withValues(alpha: 0.50),
          const Color(0x00FFFFFF), // Pure white transparent, no grey artifacts
        ],
        stops: const [0.0, 0.60, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.48));

    canvas.drawCircle(center, size.width * 0.48, glowPaint);

    // 3. Clean crisp central circular base behind mark
    final baseDiscPaint = Paint()
      ..color = const Color(0xFFF3F8FE)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 78.0, baseDiscPaint);

    // 4. Floating pastel accent bubbles (1:1 with Image 2)
    final bubblePaint = Paint()..style = PaintingStyle.fill;

    // Bubble 1: Top-Right
    bubblePaint.color = const Color(0xFFDBEAFE).withValues(alpha: 0.85);
    canvas.drawCircle(Offset(center.dx + 84, center.dy - 68), 10.5, bubblePaint);

    // Bubble 2: Mid-Right
    bubblePaint.color = const Color(0xFFBFDBFE).withValues(alpha: 0.75);
    canvas.drawCircle(Offset(center.dx + 110, center.dy + 24), 8.0, bubblePaint);

    // Bubble 3: Lower-Right
    bubblePaint.color = const Color(0xFF93C5FD).withValues(alpha: 0.70);
    canvas.drawCircle(Offset(center.dx + 78, center.dy + 96), 6.0, bubblePaint);

    // Bubble 4: Lower-Left (soft larger accent bubble)
    bubblePaint.color = const Color(0xFFEFF6FF);
    canvas.drawCircle(Offset(center.dx - 96, center.dy + 78), 15.0, bubblePaint);
    final bubbleBorder = Paint()
      ..color = const Color(0xFFDBEAFE).withValues(alpha: 0.60)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(Offset(center.dx - 96, center.dy + 78), 15.0, bubbleBorder);

    // Bubble 5: Far-Left small dot
    bubblePaint.color = const Color(0xFFDBEAFE).withValues(alpha: 0.65);
    canvas.drawCircle(Offset(center.dx - 106, center.dy - 20), 5.0, bubblePaint);

    // Bubble 6: Top Center-Right
    bubblePaint.color = const Color(0xFFDBEAFE).withValues(alpha: 0.60);
    canvas.drawCircle(Offset(center.dx + 26, center.dy - 104), 5.5, bubblePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
