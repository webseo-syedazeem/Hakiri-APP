import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../models/assessment_model.dart';
import '../providers/app_state_provider.dart';
import 'personalized_plan_screen.dart';

class AssessmentScreen extends StatefulWidget {
  const AssessmentScreen({super.key});

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  int _currentIndex = 0;

  final List<AssessmentQuestion> _questions = const [
    AssessmentQuestion(
      id: 'voiceProfile',
      title: 'Voice Profile & Biological Resonance',
      subtitle: 'Which voice profile best aligns with your biological vocal structure and personalized training goals?',
      options: [
        AssessmentOption(
          id: 'male',
          label: 'Male Voice Resonance',
          description: 'Focused on deep chest resonance, diaphragmatic support, and steady projection.',
        ),
        AssessmentOption(
          id: 'female',
          label: 'Female Voice Resonance',
          description: 'Focused on pitch clarity, throat-to-chest transitions, and authoritative resonance.',
        ),
        AssessmentOption(
          id: 'non_binary_vocal_alignment',
          label: 'Non-Binary / Vocal Alignment',
          description: 'Focused on customizable pitch matching, vocal stamina, and healthy vocal boundary training.',
        ),
      ],
    ),
    AssessmentQuestion(
      id: 'careerStage',
      title: 'Career Stage',
      subtitle: 'Where are you currently at in your professional journey?',
      options: [
        AssessmentOption(
          id: 'student_early_career',
          label: 'Student / Early Career',
          description: 'Preparing for interviews, assessment centers, and entry-level team entries.',
        ),
        AssessmentOption(
          id: 'mid_level_professional',
          label: 'Mid-Level Professional',
          description: 'Leading team meetings, cross-functional projects, reviews, and cross-team alignment.',
        ),
        AssessmentOption(
          id: 'senior_executive_founder',
          label: 'Senior Executive / Founder',
          description: 'Delivering investor pitches, speaking to media, steering all-hands, or board keynotes.',
        ),
        AssessmentOption(
          id: 'general_self_learner',
          label: 'General Self-Learner',
          description: 'Focused on personal charisma, casual conversational agility, and everyday communication.',
        ),
      ],
    ),
    AssessmentQuestion(
      id: 'careerType',
      title: 'Career Environment',
      subtitle: 'Which field best describes your primary work environment?',
      options: [
        AssessmentOption(
          id: 'corporate_finance',
          label: 'Corporate & Finance',
          description: 'Structured meetings, data reviews, forecasting, and formal boardroom presentations.',
        ),
        AssessmentOption(
          id: 'tech_engineering_product',
          label: 'Tech, Engineering & Product',
          description: 'Translating complex architecture into simple terms, backlog alignment, and technical roadmaps.',
        ),
        AssessmentOption(
          id: 'sales_marketing_creator',
          label: 'Sales, Marketing & Content Creator',
          description: 'High-energy persuasion, commercial negotiation, and audience engagement.',
        ),
        AssessmentOption(
          id: 'healthcare_education',
          label: 'Healthcare & Education',
          description: 'Clear, patient, empathetic, structured, and emotionally calibrated speaking.',
        ),
      ],
    ),
    AssessmentQuestion(
      id: 'confidence',
      title: 'Verbal Speaking Confidence',
      subtitle: 'How do you honestly feel when you have to speak or present under pressure?',
      options: [
        AssessmentOption(
          id: 'anxious_shaky',
          label: 'Anxious & Shaky',
          description: 'Throat tightens, speaking speed runs away, and struggle to find words on the spot.',
        ),
        AssessmentOption(
          id: 'moderately_confident',
          label: 'Moderately Confident',
          description: 'I can get my point across, but I default to filler words like "um" and "like".',
        ),
        AssessmentOption(
          id: 'highly_confident',
          label: 'Highly Confident',
          description: 'I control the room well, but I want to master advanced tactics like strategic power pausing.',
        ),
      ],
    ),
    AssessmentQuestion(
      id: 'roadblock',
      title: 'The Roadblock to Solve',
      subtitle: 'What is the biggest roadblock holding your voice back right now?',
      options: [
        AssessmentOption(
          id: 'fast_talking_mumbling',
          label: 'Fast Talking & Mumbling',
          description: 'Losing breath control and pacing when put on the spot; trailing off at sentence ends.',
        ),
        AssessmentOption(
          id: 'excessive_filler_words',
          label: 'Excessive Filler Words',
          description: 'Relying on "uh", "um", "sort of", "basically", and "does that make sense?" while thinking.',
        ),
        AssessmentOption(
          id: 'monotone_flat_delivery',
          label: 'Monotone / Flat Delivery',
          description: 'Sounding unengaging or like reading directly from a script without dynamic pitch.',
        ),
        AssessmentOption(
          id: 'accent_barriers_clarity',
          label: 'Accent Barriers / Intelligibility',
          description: 'Struggling with consonant clarity or feeling misunderstood in global/virtual meetings.',
        ),
      ],
    ),
    AssessmentQuestion(
      id: 'primaryGoal',
      title: 'Primary Goal',
      subtitle: 'If you could fix one thing by using this app daily, what would it be?',
      options: [
        AssessmentOption(
          id: 'executive_presence_authority',
          label: 'Executive Presence & Authority',
          description: 'Speak with authority, project calm competence, and eliminate upward inflections.',
        ),
        AssessmentOption(
          id: 'reduce_anxiety_freeze',
          label: 'Reduce Anxiety & Conversational Freeze',
          description: 'Stop freezing when put on the spot in unpredictable meetings.',
        ),
        AssessmentOption(
          id: 'sharp_arguments_debate',
          label: 'Sharp On-The-Fly Arguments',
          description: 'Build persuasive structured rebuttals and counter-proposals in real time.',
        ),
        AssessmentOption(
          id: 'diction_clarity_stamina',
          label: 'Diction, Clarity & Stamina',
          description: 'Improve daily consonant crispness, projection, and vocal endurance.',
        ),
      ],
    ),
  ];

  void _onSelectOption(String optionId) {
    final state = Provider.of<AppStateProvider>(context, listen: false);
    final question = _questions[_currentIndex];
    state.setAssessmentAnswer(question.id, optionId);

    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex += 1;
      });
    } else {
      state.completeAssessment();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PersonalizedPlanScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top navigation & Progress
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      if (_currentIndex > 0) {
                        setState(() => _currentIndex -= 1);
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
                  ),
                  Text(
                    'Step ${_currentIndex + 1} of ${_questions.length}',
                    style: const TextStyle(
                      color: AppColors.accentCyan,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: AppColors.surfaceBorder,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentCyan),
                ),
              ),
              const SizedBox(height: 24),

              // Question Heading
              Text(
                question.title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                question.subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // Options List
              Expanded(
                child: ListView.separated(
                  itemCount: question.options.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final opt = question.options[index];
                    return InkWell(
                      onTap: () => _onSelectOption(opt.id),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.surfaceBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              opt.label,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              opt.description,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ],
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
    );
  }
}
