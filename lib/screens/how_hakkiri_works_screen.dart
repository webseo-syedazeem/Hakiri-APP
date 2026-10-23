import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/services/analytics_service.dart';

class HowHakkiriWorksScreen extends StatelessWidget {
  const HowHakkiriWorksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService.instance.logScreenView(screenName: 'HowHakkiriWorksScreen');
    });

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBF9),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Icon(
                        Icons.chevron_left_rounded,
                        color: Color(0xFF0F172A),
                        size: 26,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'How Hakkiri Works',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Personalised feedback, deliberate practice & scoring',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  // Hero Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.royalBlue.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'THE HAKKIRI METHOD',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF93C5FD),
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Communication is a muscle, not a personality trait.',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Reading tips won’t make you persuasive in meetings. Hakkiri uses high-repetition, low-stakes spoken micro-drills to turn executive communication into muscle memory.',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.5,
                            color: Color(0xFF94A3B8),
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Section 1: The 3-Step Practice Loop
                  _buildSectionHeader('THE 3-STEP PRACTICE LOOP'),
                  _buildCard([
                    _buildStepRow(
                      stepNumber: '1',
                      title: 'Workplace Scenario & Micro-Pressure',
                      description:
                          'You get realistic prompts (e.g. executive pushback, stakeholder briefings, client negotiations) with an instant 3-second quick start.',
                      icon: Icons.timer_outlined,
                      iconColor: const Color(0xFF2563EB),
                      showDivider: true,
                    ),
                    _buildStepRow(
                      stepNumber: '2',
                      title: 'Spoken Response Recording',
                      description:
                          'You speak aloud under time constraints. We capture verbal structure, pacing, latency, and hesitation patterns in real time.',
                      icon: Icons.mic_rounded,
                      iconColor: const Color(0xFF059669),
                      showDivider: true,
                    ),
                    _buildStepRow(
                      stepNumber: '3',
                      title: 'Instant Scoring & Exemplar Playback',
                      description:
                          'Get objective pillar scores, specific strengths, weaknesses, and listen to how a professional executive coach would deliver the answer.',
                      icon: Icons.insights_rounded,
                      iconColor: const Color(0xFF7C3AED),
                      showDivider: false,
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // Section 2: The 4 Evaluation Pillars
                  _buildSectionHeader('THE 4 EVALUATION PILLARS'),
                  _buildCard([
                    _buildPillarRow(
                      title: 'Content & Impact',
                      weight: 'Substance',
                      color: const Color(0xFF2563EB),
                      icon: Icons.bolt_rounded,
                      description:
                          'Did you answer the actual question? Does your point deliver immediate value without wandering?',
                      showDivider: true,
                    ),
                    _buildPillarRow(
                      title: 'Structure',
                      weight: 'Architecture',
                      color: const Color(0xFF059669),
                      icon: Icons.account_tree_rounded,
                      description:
                          'Bottom-Line Upfront (BLUF), clean categorization, transition words, and a strong, definitive conclusion.',
                      showDivider: true,
                    ),
                    _buildPillarRow(
                      title: 'Fluency & Cadence',
                      weight: 'Speech Hygiene',
                      color: const Color(0xFFD97706),
                      icon: Icons.speed_rounded,
                      description:
                          'Pacing between 130–160 WPM, smooth rhythm, and active reduction of crutch words (um, uh, like, you know).',
                      showDivider: true,
                    ),
                    _buildPillarRow(
                      title: 'Delivery',
                      weight: 'Executive Poise',
                      color: const Color(0xFFE11D48),
                      icon: Icons.record_voice_over_rounded,
                      description:
                          'Vocal authority, sentence energy, ending on downward inflection rather than question tones.',
                      showDivider: false,
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // Section 3: The 7 Core Drills
                  _buildSectionHeader('THE 7 CORE ACTIVITIES'),
                  _buildCard([
                    _buildDrillRow(
                      title: 'Think Fast',
                      tag: 'Latency & Reflexes',
                      description: 'Deliver structured 3-part answers in 30 seconds with zero preparation time.',
                      showDivider: true,
                    ),
                    _buildDrillRow(
                      title: 'Cut It In Half',
                      tag: 'Conciseness',
                      description: 'Squeeze a 60-second explanation down to 30 seconds while keeping 100% of the core value.',
                      showDivider: true,
                    ),
                    _buildDrillRow(
                      title: 'Storytelling Gym',
                      tag: 'Influence',
                      description: 'Master structure, narrative tension, significance, and emotional delivery.',
                      showDivider: true,
                    ),
                    _buildDrillRow(
                      title: 'Debate Me',
                      tag: 'Pushback Handling',
                      description: 'Answer sharp executive objections with poise, counter-evidence, and calm logic.',
                      showDivider: true,
                    ),
                    _buildDrillRow(
                      title: 'Explain It Simply',
                      tag: 'Clarity',
                      description: 'Break down complex technical concepts so anyone can immediately understand them.',
                      showDivider: true,
                    ),
                    _buildDrillRow(
                      title: 'Connect The Dots',
                      tag: 'Lateral Logic',
                      description: 'Seamlessly bridge unrelated ideas with persuasive conversational pivots.',
                      showDivider: true,
                    ),
                    _buildDrillRow(
                      title: 'One-Minute Expert',
                      tag: 'Executive Briefing',
                      description: 'Deliver a commanding overview of any domain in under 60 focused seconds.',
                      showDivider: false,
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // Zero Accent Bias Footer Callout
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.balance_rounded,
                          color: Color(0xFF2563EB),
                          size: 22,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Fair Scoring Guarantee',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E3A8A),
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Hakkiri celebrates international and regional accents. You are judged strictly on structural rigor and communication effectiveness, never your native accent.',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  color: Color(0xFF1E40AF),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Inter',
          color: Color(0xFF64748B),
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildStepRow({
    required String stepNumber,
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required bool showDivider,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    stepNumber,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: iconColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
      ],
    );
  }

  Widget _buildPillarRow({
    required String title,
    required String weight,
    required Color color,
    required IconData icon,
    required String description,
    required bool showDivider,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          weight,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
      ],
    );
  }

  Widget _buildDrillRow({
    required String title,
    required String tag,
    required String description,
    required bool showDivider,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11.5,
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
        if (showDivider)
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
      ],
    );
  }
}
