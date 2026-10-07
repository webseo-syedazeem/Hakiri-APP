import 'package:flutter/material.dart';
import '../widgets/hakkiri_logo.dart';
import '../widgets/action_pill_button.dart';
import '../widgets/blue_accent_rays.dart';
import '../widgets/who_its_for_roadmap_view.dart';
import 'assessment_intro_screen.dart';
import 'login_screen.dart';

/// Complete Professional Onboarding Experience matching user's target designs:
/// - Page 0: Welcome ("Think clearly. Speak with purpose.")
/// - Page 1: Who it's for ("Built for meetings, interviews and everyday conversations.")
/// - Page 2: Train carousel ("Train the way you think and speak.")
/// - Page 3: See how it works ("Storytelling Gym" prompt & "Your feedback" card)
class LandingScreen extends StatefulWidget {
  final int initialPage;

  const LandingScreen({super.key, this.initialPage = 0});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  late final PageController _pageController;
  late final PageController _trainCardController;
  int _currentPage = 0;
  int _carouselIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _pageController = PageController(initialPage: widget.initialPage);
    _trainCardController = PageController(viewportFraction: 0.76);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _trainCardController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 5) {
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
      MaterialPageRoute(builder: (_) => const AssessmentIntroScreen()),
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const BouncingScrollPhysics(),
          onPageChanged: (idx) => setState(() => _currentPage = idx),
          children: [
            _buildWelcomePage(),
            _buildWhoItsForPage(),
            _buildTrainCarouselPage(),
            _buildSeeHowItWorksPage(),
            _buildTrustedByProfessionalsPage(),
            _buildSuggestedPracticePathPage(),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // PAGE 0: WELCOME (media_1791376750433.png)
  // ==========================================
  Widget _buildWelcomePage() {
    return Padding(
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

          // Center Logo & Fluid Ambient Background
          Expanded(
            child: Center(
              child: SizedBox(
                width: double.infinity,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Soft fluid pastel background blobs
                    CustomPaint(
                      size: const Size(280, 280),
                      painter: _FluidAmbientBlobsPainter(),
                    ),
                    // Master Logo
                    const HakkiriLogo(
                      variant: HakkiriLogoVariant.fullImage,
                      size: 160,
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
          const SizedBox(height: 20),

          // CTA Button: Get started ->
          ActionPillButton(
            label: 'Get started',
            onTap: _nextPage,
          ),
          const SizedBox(height: 14),

          // Secondary Link: I already have an account. Log in
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
          const SizedBox(height: 16),

          // 3 Bottom Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDot(isActive: true, activeColor: const Color(0xFF0F172A)),
              _buildDot(isActive: false),
              _buildDot(isActive: false),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ==========================================
  // PAGE 1: WHO IT'S FOR (media_1791376777628.png)
  // ==========================================
  Widget _buildWhoItsForPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Bar (< back, Skip)
          _buildTopBar(),
          const SizedBox(height: 10),

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
          const SizedBox(height: 14),

          // 5 Pagination Dots (Index 0 active in blue)
          _buildFiveDotsIndicator(activeIndex: 0),
          const SizedBox(height: 14),

          // CTA: Why Hakkiri? ->
          ActionPillButton(
            label: 'Why Hakkiri?',
            onTap: _nextPage,
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
        'tag': '01 - 05',
        'title': 'Storytelling\nGym',
        'desc': 'Make people lean in. Shape everyday moments into compelling stories.',
        'image': 'assets/images/storytelling_graphic_clean.png',
        'type': 'image',
      },
      {
        'tag': '02 - 05',
        'title': 'One\nMinute\nExpert',
        'desc': 'Know it. Explain it. Give a confident one minute explanation.',
        'type': 'stopwatch',
      },
      {
        'tag': '03 - 05',
        'title': 'Debate\nMe',
        'desc': 'Hold your ground under pressure. Rebut surprise arguments with confidence.',
        'type': 'debate',
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Bar (< back, Skip)
          _buildTopBar(),
          const SizedBox(height: 10),

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

                        // Graphic Illustration
                        Center(
                          child: ex['type'] == 'image'
                              ? Image.asset(
                                  ex['image']!,
                                  height: 110,
                                  fit: BoxFit.contain,
                                )
                              : ex['type'] == 'stopwatch'
                                  ? _buildStopwatchIllustration()
                                  : _buildDebateIllustration(),
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

          // Pagination Dots + "1 of 12 exercises"
          Center(
            child: Column(
              children: [
                _buildFiveDotsIndicator(activeIndex: _carouselIndex),
                const SizedBox(height: 6),
                Text(
                  '${_carouselIndex + 1} of 12 exercises',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // CTA: Is Hakkiri for me? ->
          ActionPillButton(
            label: 'Is Hakkiri for me?',
            onTap: _nextPage,
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Bar (< back, Skip)
          _buildTopBar(),
          const SizedBox(height: 8),

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

          // Scrollable area for Card 1 + Chevron + Card 2
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // CARD 1: Storytelling Gym Prompt Card
                  _buildPromptExerciseCard(),

                  // Down Arrow Connector
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF2563EB),
                      size: 26,
                    ),
                  ),

                  // CARD 2: "Your feedback" Card
                  _buildFeedbackResultCard(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          const SizedBox(height: 8),

          // 5 Pagination Dots (Index 2 active in blue)
          _buildFiveDotsIndicator(activeIndex: 2),
          const SizedBox(height: 12),

          // CTA: Explore exercises ->
          ActionPillButton(
            label: 'Explore exercises',
            onTap: _nextPage,
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopBar(),
          const SizedBox(height: 10),

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

          // 5 Dots Indicator (Index 3 active)
          _buildFiveDotsIndicator(activeIndex: 3),
          const SizedBox(height: 12),

          // CTA: Explore your learning path ->
          ActionPillButton(
            label: 'Explore your learning path',
            onTap: _nextPage,
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopBar(),
          const SizedBox(height: 8),

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

          // Winding Roadmap Graphic
          Expanded(
            child: Center(
              child: Image.asset(
                'assets/images/twelve_months_roadmap_hd.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // 5 Dots Indicator (Last dot active)
          _buildFiveDotsIndicator(activeIndex: 4),
          const SizedBox(height: 12),

          // CTA: Start assessment ->
          ActionPillButton(
            label: 'Start assessment',
            onTap: _goToAssessment,
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

  Widget _buildDot({required bool isActive, Color activeColor = const Color(0xFF2563EB)}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      width: isActive ? 20 : 6,
      height: 6,
      decoration: BoxDecoration(
        color: isActive ? activeColor : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _buildFiveDotsIndicator({required int activeIndex}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
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
}

/// Ambient soft fluid background bubbles for welcome page
class _FluidAmbientBlobsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.5);

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFDBEAFE).withValues(alpha: 0.65),
          const Color(0xFFEFF6FF).withValues(alpha: 0.45),
          Colors.transparent,
        ],
        stops: const [0.0, 0.65, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.5));

    canvas.drawCircle(center, size.width * 0.5, glowPaint);

    final blobPaint1 = Paint()
      ..color = const Color(0xFFEFF6FF)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, size.width * 0.38, blobPaint1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
