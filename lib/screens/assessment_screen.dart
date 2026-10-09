import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/app_state_provider.dart';
import '../widgets/action_pill_button.dart';
import '../widgets/confidence_gauge_widget.dart';
import '../widgets/hakkiri_logo.dart';
import 'personalized_plan_screen.dart';

class AssessmentScreen extends StatefulWidget {
  final int initialStep;
  const AssessmentScreen({super.key, this.initialStep = 0});

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  late int _currentStepIndex;
  late final PageController _pageController;
  final TextEditingController _nameController = TextEditingController(text: 'Alex Rivera');
  String _selectedOptionId = 'female';

  // Default selections matching the user's screenshots exactly
  final Map<int, String> _stepSelections = {
    2: 'female',
    3: 'mid_level',
    4: 'tech_product',
    5: 'fairly',
    6: 'filler_rush',
    7: 'calmer_confident',
  };

  @override
  void initState() {
    super.initState();
    _currentStepIndex = widget.initialStep;
    _selectedOptionId = _stepSelections[_currentStepIndex] ?? '';
    _pageController = PageController(initialPage: widget.initialStep);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> _steps = [
    {
      'tag': 'YOUR ASSESSMENT',
      'stepNum': '01/07',
      'titleBlack': "Let's personalise\n",
      'titleBlue': 'your plan',
      'subtitle':
          'Answer 7 quick questions to understand how you speak, where you get stuck, and what you want to improve.',
      'isIntro': true,
      'buttonLabel': 'Start assessment',
    },
    // Step 1 / 7 - YOUR PROFILE (Image media_1791301001009.jpg)
    {
      'tag': 'YOUR PROFILE',
      'stepNum': '1/7',
      'progress': 1 / 7,
      'titleBlack': "What's\n",
      'titleBlue': "your name?",
      'subtitle': "Let's personalise your speaking experience.",
      'isNameInput': true,
      'buttonLabel': 'Continue',
    },

    // Step 2 / 7 - YOUR VOICE (Image media_1791301001007.jpg)
    {
      'tag': 'YOUR VOICE',
      'stepNum': '2/7',
      'progress': 2 / 7,
      'titleBlack': "Which voice profile\n",
      'titleBlue': "fits you best?",
      'subtitle': "This helps us personalise your voice training.",
      'buttonLabel': 'Continue',
      'options': [
        {
          'id': 'male',
          'symbol': '♂',
          'title': 'Male',
          'subtitle': 'Build stronger resonance and steady projection',
        },
        {
          'id': 'female',
          'symbol': '♀',
          'title': 'Female',
          'subtitle': 'Develop pitch clarity and vocal control',
        },
        {
          'id': 'non_binary',
          'symbol': '⚧',
          'title': 'Non-binary / Vocal alignment',
          'subtitle': 'Personalise your pitch and vocal range',
        },
      ],
    },

    // Step 3 / 7 - YOUR CAREER (Image media_1791301375944.jpg)
    {
      'tag': 'YOUR CAREER',
      'stepNum': '3/7',
      'progress': 3 / 7,
      'titleBlack': "Where are you in\n",
      'titleBlue': "your career?",
      'subtitle': "We'll tailor your practice to situations you're likely to face.",
      'buttonLabel': 'Continue',
      'options': [
        {
          'id': 'early',
          'icon': Icons.school_outlined,
          'title': 'Student / Early career',
          'subtitle': 'Interviews, presentations and starting work',
        },
        {
          'id': 'mid_level',
          'icon': Icons.business_center_outlined,
          'title': 'Mid-level professional',
          'subtitle': 'Meetings, projects and performance conversations',
        },
        {
          'id': 'exec',
          'icon': Icons.groups_2_outlined,
          'title': 'Senior executive / Founder',
          'subtitle': 'Pitches, keynotes and high-stakes conversations',
        },
        {
          'id': 'self_learner',
          'icon': Icons.person_outline_rounded,
          'title': 'General self-learner',
          'subtitle': 'Everyday communication and personal development',
        },
      ],
    },

    // Step 4 / 7 - YOUR CONTEXT (Image media_1791301375954.jpg)
    {
      'tag': 'YOUR CONTEXT',
      'stepNum': '4/7',
      'progress': 4 / 7,
      'titleBlack': "What's your main\n",
      'titleBlue': "work environment?",
      'subtitle': "Choose the option that best matches your day-to-day.",
      'buttonLabel': 'Continue',
      'options': [
        {
          'id': 'corporate_finance',
          'icon': Icons.apartment_rounded,
          'title': 'Corporate & Finance',
          'subtitle': 'Meetings, data reviews and formal presentations',
        },
        {
          'id': 'tech_product',
          'icon': Icons.laptop_chromebook_rounded,
          'title': 'Tech, Engineering & Product',
          'subtitle': 'Explaining complex ideas simply',
        },
        {
          'id': 'sales_marketing',
          'icon': Icons.campaign_outlined,
          'title': 'Sales, Marketing & Content',
          'subtitle': 'Persuasion, negotiation and audience engagement',
        },
        {
          'id': 'healthcare_edu',
          'icon': Icons.health_and_safety_outlined,
          'title': 'Healthcare & Education',
          'subtitle': 'Clear, empathetic communication',
        },
        {
          'id': 'other',
          'icon': Icons.more_horiz_rounded,
          'title': 'Other',
          'subtitle': 'Something else',
        },
      ],
    },

    // Step 5 / 7 - YOUR CONFIDENCE (Image media_1791301375950.jpg)
    {
      'tag': 'YOUR CONFIDENCE',
      'stepNum': '5/7',
      'progress': 5 / 7,
      'titleBlack': "How confident do you feel\n",
      'titleBlue': "speaking under pressure?",
      'subtitle': "Choose the option that sounds most like you.",
      'hasGauge': true,
      'buttonLabel': 'Continue',
      'options': [
        {
          'id': 'not_very',
          'title': 'Not very confident',
          'subtitle': 'I get nervous, rush or struggle to find my words',
        },
        {
          'id': 'fairly',
          'title': 'Fairly confident',
          'subtitle': 'I communicate well but sometimes rely on filler words',
        },
        {
          'id': 'very',
          'title': 'Very confident',
          'subtitle': "I'm comfortable speaking, but want to sharpen my delivery",
        },
      ],
    },

    // Step 6 / 7 - YOUR CHALLENGE (Image media_1791301375939.jpg)
    {
      'tag': 'YOUR CHALLENGE',
      'stepNum': '6/7',
      'progress': 6 / 7,
      'titleBlack': "What gets in your way\n",
      'titleBlue': "most when you speak?",
      'subtitle': "Pick your biggest challenge. You can work on the others later.",
      'buttonLabel': 'Continue',
      'options': [
        {
          'id': 'blank_pressure',
          'icon': Icons.psychology_outlined,
          'title': 'I go blank under pressure',
          'subtitle': 'I struggle to organise my thoughts quickly',
        },
        {
          'id': 'too_long',
          'icon': Icons.access_time_rounded,
          'title': 'I take too long to get to the point',
          'subtitle': 'I over-explain before getting to my message',
        },
        {
          'id': 'filler_rush',
          'icon': Icons.graphic_eq_rounded,
          'title': 'I rush or use too many filler words',
          'subtitle': "I use words like 'um' or 'so' while thinking",
        },
        {
          'id': 'explain_simple',
          'icon': Icons.description_outlined,
          'title': 'I struggle to explain things simply',
          'subtitle': 'I know what I mean, but make it sound complicated',
        },
        {
          'id': 'keep_engaged',
          'icon': Icons.groups_outlined,
          'title': 'I struggle to keep people engaged',
          'subtitle': "My message doesn't always land or stick",
        },
        {
          'id': 'lose_confidence',
          'icon': Icons.shield_outlined,
          'title': 'I lose confidence when challenged',
          'subtitle': 'I struggle to respond clearly when someone disagrees',
        },
      ],
    },

    // Step 7 / 7 - YOUR GOAL (Image media_1791301375954.jpg / 933.jpg)
    {
      'tag': 'YOUR GOAL',
      'stepNum': '7/7',
      'progress': 1.0,
      'titleBlack': "What's your\n",
      'titleBlue': "main goal?",
      'subtitle': "What would you most like Hakkiri to help you improve?",
      'buttonLabel': 'Complete assessment',
      'options': [
        {
          'id': 'authority',
          'icon': Icons.signal_cellular_alt_rounded,
          'title': 'Speak with more authority and executive presence',
          'subtitle': '',
        },
        {
          'id': 'calmer_confident',
          'icon': Icons.spa_outlined,
          'title': 'Feel calmer and more confident speaking under pressure',
          'subtitle': '',
        },
        {
          'id': 'persuasive_arguments',
          'icon': Icons.chat_bubble_outline_rounded,
          'title': 'Build clear, persuasive arguments on the spot',
          'subtitle': '',
        },
        {
          'id': 'clear_daily',
          'icon': Icons.mic_none_rounded,
          'title': 'Speak more clearly and confidently every day',
          'subtitle': '',
        },
      ],
    },
  ];

  void _onOptionSelected(String optionId, {int? stepIndex}) {
    final index = stepIndex ?? _currentStepIndex;
    setState(() {
      _stepSelections[index] = optionId;
      if (index == _currentStepIndex) {
        _selectedOptionId = optionId;
      }
    });
  }

  void _nextStep() {
    if (_currentStepIndex < _steps.length - 1) {
      _pageController.animateToPage(
        _currentStepIndex + 1,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
      );
    } else {
      // Completed Assessment -> save to provider and navigate to plan
      final state = Provider.of<AppStateProvider>(context, listen: false);
      state.updateAssessment(
        gender: _stepSelections[2] ?? 'female',
        careerStage: _stepSelections[3] ?? 'mid_level',
        careerType: _stepSelections[4] ?? 'tech_product',
        confidence: _stepSelections[5] ?? 'fairly',
        problem: _stepSelections[6] ?? 'filler_rush',
        goal: _stepSelections[7] ?? 'calmer_confident',
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PersonalizedPlanScreen()),
      );
    }
  }

  void _prevStep() {
    if (_currentStepIndex > 0) {
      _pageController.animateToPage(
        _currentStepIndex - 1,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _onPageChanged(int index) {
    final options = (_steps[index]['options'] as List<dynamic>?) ?? [];
    final fallback = options.isNotEmpty ? options.first['id'] as String : '';
    setState(() {
      _currentStepIndex = index;
      _selectedOptionId = _stepSelections[index] ?? fallback;
    });
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStepIndex];
    final buttonLabel = (step['buttonLabel'] as String?) ?? 'Continue';
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final bottomGap = isIOS ? (safeBottom > 0 ? 20.0 : 12.0) : 14.0;

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBF9),
      body: SafeArea(
        bottom: !isIOS,
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 14, 24, bottomGap),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Centered Official Hakkiri Brand Mark
              Center(
                child: const HakkiriLogo(
                  variant: HakkiriLogoVariant.fullImage,
                  size: 78,
                ),
              ),
              const SizedBox(height: 20),

              // Category Tracker Row (with optional back arrow)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (_currentStepIndex > 0)
                        GestureDetector(
                          onTap: _prevStep,
                          child: const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: Icon(
                              Icons.chevron_left_rounded,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                          ),
                        ),
                      Text(
                        step['tag'] as String,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    step['stepNum'] as String,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Step Progress Line — moves with the page, same as onboarding
              AnimatedBuilder(
                animation: _pageController,
                builder: (context, _) {
                  final page = _pageController.hasClients
                      ? (_pageController.page ?? _currentStepIndex.toDouble())
                      : _currentStepIndex.toDouble();
                  final progress = ((page + 1) / _steps.length).clamp(0.0, 1.0);
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      return Container(
                        height: 3.5,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFECEBE4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: constraints.maxWidth * progress,
                          decoration: BoxDecoration(
                            color: AppColors.royalBlue,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 22),

              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: _onPageChanged,
                  itemCount: _steps.length,
                  itemBuilder: (context, index) => _buildStepPage(index),
                ),
              ),

              const SizedBox(height: 12),

              // Bottom Action Pill Button
              ActionPillButton(
                label: buttonLabel,
                onTap: _nextStep,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepPage(int index) {
    final step = _steps[index];
    if (step['isIntro'] == true) return _buildIntroPage(step);
    final isNameInput = step['isNameInput'] == true;
    final hasGauge = step['hasGauge'] == true;
    final options = (step['options'] as List<dynamic>?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              height: 1.15,
              letterSpacing: -1.0,
            ),
            children: [
              TextSpan(text: step['titleBlack'] as String),
              TextSpan(
                text: step['titleBlue'] as String,
                style: const TextStyle(color: AppColors.royalBlue),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          step['subtitle'] as String,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        if (hasGauge) ...[
          Center(
            child: ConfidenceGaugeWidget(
              level: _stepSelections[index] ?? _selectedOptionId,
            ),
          ),
          const SizedBox(height: 14),
        ],
        Expanded(
          child: isNameInput
              ? _buildNameInput()
              : ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: options.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 11),
                  itemBuilder: (context, optionIndex) {
                    final opt = options[optionIndex] as Map<String, dynamic>;
                    final selectedId = index == _currentStepIndex
                        ? _selectedOptionId
                        : _stepSelections[index];
                    final isSelected = opt['id'] == selectedId;

                    return _buildOptionCard(
                      id: opt['id'] as String,
                      title: opt['title'] as String,
                      subtitle: (opt['subtitle'] as String?) ?? '',
                      symbol: opt['symbol'] as String?,
                      icon: opt['icon'] as IconData?,
                      isSelected: isSelected,
                      onTap: () => _onOptionSelected(
                        opt['id'] as String,
                        stepIndex: index,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildIntroPage(Map<String, dynamic> step) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              height: 1.15,
              letterSpacing: -1.0,
            ),
            children: [
              TextSpan(text: step['titleBlack'] as String),
              TextSpan(
                text: step['titleBlue'] as String,
                style: const TextStyle(color: AppColors.royalBlue),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          step['subtitle'] as String,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.45,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 28),
        _buildBenefitCard(
          icon: Icons.bar_chart_rounded,
          title: 'Find your biggest speaking blockers',
          subtitle: "Identify what's holding you back.",
        ),
        const SizedBox(height: 12),
        _buildBenefitCard(
          icon: Icons.article_outlined,
          title: 'Get a personalised practice plan',
          subtitle: 'Tailored to your goals and needs.',
        ),
        const SizedBox(height: 12),
        _buildBenefitCard(
          icon: Icons.auto_awesome_outlined,
          title: 'Build more clarity, confidence and presence',
          subtitle: 'Speak with greater impact.',
        ),
        const Spacer(),
        const Row(
          children: [
            Icon(
              Icons.access_time_rounded,
              color: AppColors.textMuted,
              size: 16,
            ),
            SizedBox(width: 8),
            Text(
              'Takes less than 2 minutes.',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBenefitCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAE9E2), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: AppColors.textPrimary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Name Input matching Image 2
  Widget _buildNameInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEAE9E2), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: TextField(
                  controller: _nameController,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Your name',
                    hintStyle: TextStyle(
                      color: Color(0xFF9E9EA7),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Option Card matching the design system
  Widget _buildOptionCard({
    required String id,
    required String title,
    required String subtitle,
    String? symbol,
    IconData? icon,
    required bool isSelected,
    VoidCallback? onTap,
  }) {
    final hasSubtitle = subtitle.trim().isNotEmpty;

    return GestureDetector(
      onTap: onTap ?? () => _onOptionSelected(id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: hasSubtitle ? 14 : 16,
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF141522) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.transparent : const Color(0xFFEAE9E2),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isSelected ? 0.08 : 0.02),
              blurRadius: isSelected ? 12 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Leading Symbol / Icon (if present)
            if (symbol != null)
              Container(
                width: 42,
                height: 42,
                margin: const EdgeInsets.only(right: 14),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF222438) : const Color(0xFFF3F4F6),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  symbol,
                  style: TextStyle(
                    fontSize: 22,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else if (icon != null)
              Container(
                width: 42,
                height: 42,
                margin: const EdgeInsets.only(right: 14),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF222438) : const Color(0xFFF3F4F6),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  size: 20,
                ),
              ),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                  if (hasSubtitle) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: isSelected ? const Color(0xFFA0A5B5) : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Trailing Radio Indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.royalBlue : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppColors.royalBlue : const Color(0xFFD1D5DB),
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
