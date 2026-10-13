import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/services/analytics_service.dart';
import '../widgets/action_pill_button.dart';
import '../widgets/blue_accent_rays.dart';
import '../widgets/exercise_illustrations.dart';
import '../widgets/onboarding_bubble_background.dart';
import '../widgets/who_its_for_roadmap_view.dart';
import '../widgets/twelve_months_roadmap_view.dart';
import 'assessment_screen.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

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
  DateTime? _lastBackPress;

  /// After signup/Google, onboarding starts at page 1 — never go below it.
  int get _minPage => widget.postSignup ? 1 : 0;

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
      AnalyticsService.instance.logOnboardingStarted();
      AnalyticsService.instance.logScreenView(screenName: 'LandingScreen_Page$start');
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
    if (_currentPage > _minPage) {
      _pageController.animateToPage(
        _currentPage - 1,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _handleDoubleBackToExit() {
    final now = DateTime.now();
    if (_lastBackPress != null &&
        now.difference(_lastBackPress!) < const Duration(seconds: 2)) {
      SystemNavigator.pop();
      return;
    }
    _lastBackPress = now;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Press back again to exit'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleSystemBack() {
    if (_currentPage > _minPage) {
      _previousPage();
      return;
    }
    // First post-signup onboarding page: double-back exits the app.
    if (widget.postSignup) {
      _handleDoubleBackToExit();
    }
  }

  void _goToAssessment() {
    AnalyticsService.instance.logOnboardingCompleted();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AssessmentScreen()),
    );
  }

  /// Get started → Signup (new accounts). Design unchanged.
  void _goToSignup() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SignupScreen()),
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

    // Post-signup first page: no route pop — double Android back exits app.
    // Mid pages: system back = previous onboarding page.
    return PopScope(
      canPop: !widget.postSignup && _currentPage <= 0,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleSystemBack();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
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
              // After signup: first onboarding page has Skip only (no back).
              if (_currentPage > 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 6, 24, 0),
                  child: _buildTopBar(showBack: _currentPage > _minPage),
                ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (idx) {
                    // Don't swipe back to welcome after signup/Google.
                    if (widget.postSignup && idx < 1) {
                      _pageController.jumpToPage(1);
                      return;
                    }
                    setState(() => _currentPage = idx);
                    final label = (idx >= 0 && idx < _sectionLabels.length)
                        ? _sectionLabels[idx]
                        : 'Page$idx';
                    AnalyticsService.instance.logOnboardingPage(
                      pageIndex: idx,
                      pageName: label,
                    );
                    AnalyticsService.instance.logScreenView(
                      screenName: 'Onboarding_$label',
                    );
                  },
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
                    if (_currentPage == 4) ...[
                      // Who it's for: step 1 of 3
                      _buildDotsIndicator(activeIndex: 0, totalDots: 3),
                      const SizedBox(height: 12),
                    ] else if (_currentPage == 5) ...[
                      // Why Hakkiri: step 2 of 3
                      _buildDotsIndicator(activeIndex: 1, totalDots: 3),
                      const SizedBox(height: 12),
                    ] else if (_currentPage == 6) ...[
                      // A guided practice path: step 3 of 3 (final step before assessment)
                      _buildDotsIndicator(
                        activeIndex: 2,
                        totalDots: 3,
                        alignment: MainAxisAlignment.center,
                      ),
                      const SizedBox(height: 12),
                    ],

                    ActionPillButton(
                      // Funnel: Get started → Signup → onboarding → Assessment.
                      // After signup, postSignup skips welcome and walks pages.
                      label: _sectionLabels[_currentPage],
                      onTap: _currentPage == 0 && !widget.postSignup
                          ? _goToSignup
                          : (_currentPage >= _sectionLabels.length - 1
                              ? _goToAssessment
                              : _nextPage),
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
    )),
    );
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
              'Use it whenever you need to think and speak\nmore clearly.',
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
        'tag': '01 • 07',
        'title': 'Think Fast.',
        'tagline': 'Think clearly under pressure.',
        'desc': 'Answer an unexpected question with a few seconds to prepare, then speak for 60 seconds.',
        'type': 'think_fast',
      },
      {
        'tag': '02 • 07',
        'title': 'Connect\nthe Dots.',
        'tagline': 'Make unexpected connections.',
        'desc': 'Link two random ideas into a clear, compelling story.',
        'type': 'connect_dots',
      },
      {
        'tag': '03 • 07',
        'title': 'Explain\nIt Simply.',
        'tagline': 'Make complex ideas easy to understand.',
        'desc': 'Take a complex topic and explain it in clear, simple language.',
        'type': 'explain',
      },
      {
        'tag': '04 • 07',
        'title': 'Cut It\nin Half.',
        'tagline': 'Get to the point faster.',
        'desc': 'Read a longer message and make it shorter, clearer and more impactful.',
        'type': 'cut_it_in_half',
      },
      {
        'tag': '05 • 07',
        'title': 'Storytelling\nGym.',
        'tagline': 'Make people lean in.',
        'desc': 'Turn information into a structured, memorable story with a clear point.',
        'type': 'storytelling',
      },
      {
        'tag': '06 • 07',
        'title': 'One Minute\nExpert.',
        'tagline': 'Know it. Explain it.',
        'desc': 'Choose a topic and explain it clearly, confidently and coherently in 60 seconds.',
        'type': 'stopwatch',
      },
      {
        'tag': '07 • 07',
        'title': 'Debate\nMe.',
        'tagline': 'Hold your ground.',
        'desc': 'Respond to a challenging position with a clear, confident rebuttal under pressure.',
        'type': 'debate',
      },
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Headline
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Train the way you',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  height: 1.15,
                  letterSpacing: -0.7,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'think and speak.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2563EB),
                      height: 1.15,
                      letterSpacing: -0.7,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Transform.translate(
                    offset: const Offset(0, -5),
                    child: const BlueAccentRays(size: 24),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Subtitle
          const Text(
            'Short guided exercises for clearer, quicker, more confident communication.',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),

          // Exercise Carousel Cards
          Expanded(
            child: PageView.builder(
              itemCount: exercises.length,
              controller: _trainCardController,
              onPageChanged: (idx) => setState(() => _carouselIndex = idx),
              itemBuilder: (context, idx) {
                final ex = exercises[idx];
                return Padding(
                  padding: const EdgeInsets.only(right: 12, bottom: 6, top: 2),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
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
                        // Badge: 01 • 07
                        Text(
                          ex['tag']!,
                          style: const TextStyle(
                            color: Color(0xFF3B82F6),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Title
                        Text(
                          ex['title']!,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            height: 1.15,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Tagline (blue)
                        Text(
                          ex['tagline']!,
                          style: const TextStyle(
                            color: Color(0xFF2563EB),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Description
                        Text(
                          ex['desc']!,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Large 3D illustration anchored to the lower part of
                        // the card (fills the card width, like the design doc).
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final s = constraints.maxWidth.clamp(180.0, 320.0);
                                  return ExerciseIllustration(
                                    type: ex['type']!,
                                    size: s,
                                  );
                                },
                              ),
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
          const SizedBox(height: 6),

          // Pagination Dots + "1 of 7 exercises"
          Center(
            child: Column(
              children: [
                _buildCarouselDotsIndicator(
                  activeIndex: _carouselIndex,
                  totalDots: exercises.length,
                ),
                const SizedBox(height: 5),
                Text(
                  '${_carouselIndex + 1} of ${exercises.length} exercises',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
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
                    author: 'Director, BCG',
                    avatarAsset: 'assets/images/avatar_consultant.png',
                  ),
                  const SizedBox(height: 10),
                  _buildTestimonialCard(
                    quote: '“This feedback is specific, practical and easy to apply.”',
                    author: 'Professor, The Economist',
                    avatarAsset: 'assets/images/avatar_economist.png',
                  ),
                  const SizedBox(height: 10),
                  _buildTestimonialCard(
                    quote: '“A smart way to practise speaking with more clarity and confidence.”',
                    author: 'Student, Cambridge University',
                    avatarAsset: 'assets/images/avatar_student.png',
                  ),
                  const SizedBox(height: 12),

                  // Organization Pills Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildOrgPill('BCG'),
                      const SizedBox(width: 8),
                      _buildOrgPill('The Economist'),
                      const SizedBox(width: 8),
                      _buildOrgPill('Cambridge University'),
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
          // Tag: A GUIDED PRACTICE PATH
          const Text(
            'A GUIDED PRACTICE PATH',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.3,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),

          // Headline
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Twelve months,',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 30,
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
                    'one step at a time.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2563EB),
                      height: 1.15,
                      letterSpacing: -0.8,
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

  Widget _buildTopBar({bool showBack = true}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (showBack)
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
          )
        else
          const SizedBox(width: 28),
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
    Color activeColor = const Color(0xFF2563EB),
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

  Widget _buildCarouselDotsIndicator({required int activeIndex, int totalDots = 7}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalDots, (index) {
        final isActive = index == activeIndex;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 8 : 6,
          height: isActive ? 8 : 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
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
          // Header: Book Icon, Title, "1 min" badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.menu_book_rounded, color: Color(0xFF2563EB), size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Storytelling Gym',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Speak for 1 minute on a real-life topic. It builds your structure, presence and clarity.',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
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
          const SizedBox(height: 12),

          // Quote box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '“ ',
                  style: TextStyle(
                    color: Color(0xFF2563EB),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Tell us about a time you solved a problem.',
                    style: TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ),
                Text(
                  ' ”',
                  style: TextStyle(
                    color: Color(0xFF2563EB),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Interactive Recording / Starts in preview area
          Stack(
            alignment: Alignment.center,
            children: [
              // Starts-in Countdown Circle in Top Right
              Positioned(
                right: 20,
                top: 0,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFF2563EB), width: 2.2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '3',
                            style: TextStyle(
                              color: Color(0xFF2563EB),
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              height: 1.0,
                            ),
                          ),
                          SizedBox(height: 1),
                          Text(
                            'Starts in',
                            style: TextStyle(
                              color: Color(0xFF2563EB),
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: -6,
                      right: -8,
                      child: Transform.rotate(
                        angle: 0.25,
                        child: const BlueAccentRays(size: 15),
                      ),
                    ),
                  ],
                ),
              ),

              // Mic button with waveform bars in center
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Left soundwave bars
                        _buildSoundwaveBarGroup(),
                        const SizedBox(width: 10),

                        // Glowing Mic Circle
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: const RadialGradient(
                              center: Alignment(-0.2, -0.3),
                              radius: 0.9,
                              colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2563EB).withValues(alpha: 0.40),
                                blurRadius: 14,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.mic_rounded, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 10),

                        // Right soundwave bars
                        _buildSoundwaveBarGroup(),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'Recording...',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSoundwaveBarGroup() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildWaveBar(8),
        const SizedBox(width: 3),
        _buildWaveBar(14),
        const SizedBox(width: 3),
        _buildWaveBar(22),
        const SizedBox(width: 3),
        _buildWaveBar(16),
        const SizedBox(width: 3),
        _buildWaveBar(10),
      ],
    );
  }

  Widget _buildWaveBar(double height) {
    return Container(
      width: 2.8,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6),
        borderRadius: BorderRadius.circular(2),
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
          // Header: Bar icon, "Your feedback", "★ AI-powered"
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your feedback',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'See where you did well and what to improve next.',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, color: Color(0xFF16A34A), size: 13),
                    SizedBox(width: 3),
                    Text(
                      'AI-powered',
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
          const SizedBox(height: 14),

          // 4 Score Metrics
          _buildMetricRow(Icons.track_changes_rounded, 'Clarity', 4.5),
          const SizedBox(height: 8),
          _buildMetricRow(Icons.format_list_bulleted_rounded, 'Structure', 3.5),
          const SizedBox(height: 8),
          _buildMetricRow(Icons.settings_outlined, 'Confidence', 4.5),
          const SizedBox(height: 8),
          _buildMetricRow(Icons.favorite_outline_rounded, 'Engagement', 3.5),
          const SizedBox(height: 14),

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
                          'Try to add more real-world examples next.',
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

  Widget _buildMetricRow(IconData icon, String label, double score) {
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
              final val = score - idx;
              Color segmentColor;
              if (val >= 1.0) {
                segmentColor = const Color(0xFF2563EB); // full blue
              } else if (val >= 0.5) {
                segmentColor = const Color(0xFF93C5FD); // half/light blue
              } else {
                segmentColor = const Color(0xFFE2E8F0); // empty grey
              }

              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  height: 9,
                  decoration: BoxDecoration(
                    color: segmentColor,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          score.toStringAsFixed(1),
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

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
