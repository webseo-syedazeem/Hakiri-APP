import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/app_state_provider.dart';
import '../widgets/action_pill_button.dart';
import 'personalized_plan_screen.dart';

class AssessmentScreen extends StatefulWidget {
  const AssessmentScreen({super.key});

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  int _currentStepIndex = 4; // Starts on Step 5 (05/06) as featured on Page 2, or 0
  String _selectedOptionId = 'blank_on_spot';

  final List<Map<String, dynamic>> _steps = [
    {
      'tag': 'VOICE PROFILE',
      'stepNum': '01/06',
      'title': 'Which voice profile best aligns with your vocal structure?',
      'subtitle': 'PICK YOUR BIOLOGICAL VOCAL RESONANCE',
      'options': [
        {
          'id': 'male',
          'title': 'Male Voice Resonance',
          'subtitle': 'Focused on deep chest resonance and steady projection',
        },
        {
          'id': 'female',
          'title': 'Female Voice Resonance',
          'subtitle': 'Focused on pitch clarity and head-to-chest transitions',
        },
        {
          'id': 'non_binary',
          'title': 'Non-Binary / Alignment',
          'subtitle': 'Customizable pitch matching and vocal safety',
        },
      ],
    },
    {
      'tag': 'CAREER STAGE',
      'stepNum': '02/06',
      'title': 'Where are you currently at in your career journey?',
      'subtitle': 'SELECT YOUR PROFESSIONAL LEVEL',
      'options': [
        {
          'id': 'early',
          'title': 'Student / Early Career',
          'subtitle': 'Preparing for interviews and first corporate roles',
        },
        {
          'id': 'mid_level',
          'title': 'Mid-Level Professional',
          'subtitle': 'Leading meetings, cross-functional projects and reviews',
        },
        {
          'id': 'exec',
          'title': 'Senior Executive / Founder',
          'subtitle': 'Delivering board pitches, keynotes and steering media',
        },
      ],
    },
    {
      'tag': 'YOUR FIELD',
      'stepNum': '03/06',
      'title': 'Which field best describes your primary work environment?',
      'subtitle': 'TAILORS YOUR INDUSTRY PROMPTS',
      'options': [
        {
          'id': 'sales_marketing',
          'title': 'Sales & Marketing',
          'subtitle': 'High-energy persuasion, objection handling, deals',
        },
        {
          'id': 'tech_product',
          'title': 'Tech, Engineering & Product',
          'subtitle': 'Translating complex architecture into simple terms',
        },
        {
          'id': 'corporate_finance',
          'title': 'Corporate & Finance',
          'subtitle': 'Structured data reviews, governance and forecasts',
        },
        {
          'id': 'healthcare_edu',
          'title': 'Healthcare & Education',
          'subtitle': 'Clear, patient, empathetic, structured delivery',
        },
      ],
    },
    {
      'tag': 'CONFIDENCE',
      'stepNum': '04/06',
      'title': 'How do you feel when you speak under pressure?',
      'subtitle': 'HONEST SELF-ASSESSMENT',
      'options': [
        {
          'id': 'anxious',
          'title': 'Anxious & Shaky',
          'subtitle': 'Throat tightens, I speak too fast, I struggle for words',
        },
        {
          'id': 'moderate',
          'title': 'Moderately Confident',
          'subtitle': 'I get my point across but default to fillers like "um"',
        },
        {
          'id': 'high',
          'title': 'Highly Confident',
          'subtitle': 'I control the room well, seeking advanced executive tactics',
        },
      ],
    },
    // STEP 05/06 - Exactly as seen in Page 2 screenshot!
    {
      'tag': 'YOUR GOALS',
      'stepNum': '05/06',
      'title': 'What gets in your way\nmost when you speak?',
      'subtitle': 'PICK THE ONE THAT MATTERS MOST',
      'options': [
        {
          'id': 'blank_on_spot',
          'title': 'I go blank when put on the spot',
          'subtitle': 'I need a few seconds and lose my train of thought',
        },
        {
          'id': 'too_long_point',
          'title': 'I take too long to get to the point',
          'subtitle': 'I add background first and people lose track',
        },
        {
          'id': 'rush_fill_gaps',
          'title': 'I rush or fill gaps with “um” and “so”',
          'subtitle': 'I speed up while working out what to say',
        },
        {
          'id': 'explain_simply',
          'title': 'I struggle to explain things simply',
          'subtitle': 'It comes out too complicated for the listener',
        },
        {
          'id': 'switch_off',
          'title': 'People switch off when I talk',
          'subtitle': 'Facts and updates don’t land or stick',
        },
        {
          'id': 'lose_footing',
          'title': 'I lose my footing when challenged',
          'subtitle': 'I get defensive or forget my argument',
        },
      ],
    },
    {
      'tag': 'PRIMARY GOAL',
      'stepNum': '06/06',
      'title': 'If you could fix one thing using this app, what would it be?',
      'subtitle': 'DEFINES YOUR DAILY ANCHOR FOCUS',
      'options': [
        {
          'id': 'exec_presence',
          'title': 'Speak with authority & executive presence',
          'subtitle': 'Eliminate tentative uptalk and project steady conviction',
        },
        {
          'id': 'reduce_freeze',
          'title': 'Reduce public speaking freeze & anxiety',
          'subtitle': 'Stay grounded and composed in unpredictable syncs',
        },
        {
          'id': 'sharp_debate',
          'title': 'Build sharp arguments on the fly',
          'subtitle': 'Spontaneous rebuttal and negotiation mastery',
        },
      ],
    },
  ];

  void _onContinue() {
    final state = Provider.of<AppStateProvider>(context, listen: false);

    if (_currentStepIndex < _steps.length - 1) {
      setState(() {
        _currentStepIndex += 1;
        _selectedOptionId = (_steps[_currentStepIndex]['options'] as List).first['id'];
      });
    } else {
      state.completeAssessment();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PersonalizedPlanScreen()),
      );
    }
  }

  void _onBack() {
    if (_currentStepIndex > 0) {
      setState(() {
        _currentStepIndex -= 1;
        _selectedOptionId = (_steps[_currentStepIndex]['options'] as List).first['id'];
      });
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStepIndex];
    final double progress = (_currentStepIndex + 1) / _steps.length;
    final List options = step['options'] as List;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar (< YOUR GOALS  05/06)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: _onBack,
                    child: const Icon(
                      Icons.chevron_left_rounded,
                      color: AppColors.textPrimary,
                      size: 28,
                    ),
                  ),
                  Text(
                    step['tag'] as String,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    step['stepNum'] as String,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Thin Royal Blue Progress Line
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 2.5,
                  backgroundColor: AppColors.surfaceBorder,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.royalBlue),
                ),
              ),
              const SizedBox(height: 28),

              // Question Heading
              Text(
                step['title'] as String,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 8),

              // Uppercase Subtitle
              Text(
                step['subtitle'] as String,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 20),

              // Options List
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: options.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final opt = options[index];
                    final isSelected = _selectedOptionId == opt['id'];

                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedOptionId = opt['id']);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF141522) : AppColors.surfaceWhite,
                          borderRadius: BorderRadius.circular(16),
                          border: isSelected
                              ? null
                              : Border.all(color: AppColors.surfaceBorder, width: 1.0),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    opt['title'] as String,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : AppColors.textPrimary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    opt['subtitle'] as String,
                                    style: TextStyle(
                                      color: isSelected ? const Color(0xFFA3A6B8) : AppColors.textMuted,
                                      fontSize: 12,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Selection Indicator
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.royalBlue : Colors.transparent,
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? null
                                    : Border.all(color: const Color(0xFFD4D2C8), width: 1.5),
                              ),
                              alignment: Alignment.center,
                              child: isSelected
                                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Bottom Continue Button
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: ActionPillButton(
                  label: 'Continue',
                  onPressed: _onContinue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
