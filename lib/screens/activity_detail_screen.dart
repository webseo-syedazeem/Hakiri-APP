import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../widgets/action_pill_button.dart';
import '../widgets/blue_accent_rays.dart';
import 'recording_screen.dart';

/// Think Fast / Spontaneous Agility Activity Intro Screen
/// Matches authentic client design (reference-images/img_3.png).
/// Note: Beginner, intermediate, and pro levels removed as per client decision.
class ActivityDetailScreen extends StatelessWidget {
  const ActivityDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final activity = state.selectedActivity;

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
                      // Lightning Bolt Card Badge
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFDBEAFE),
                            width: 1.2,
                          ),
                        ),
                        child: const Icon(
                          Icons.bolt_rounded,
                          color: Color(0xFF2563EB),
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Tag: ON-THE-SPOT PRACTICE
                      const Text(
                        'ON-THE-SPOT PRACTICE',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Heading: Think Fast. with 2 Blue Accent Rays
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            activity?.name ?? 'Think Fast.',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                              letterSpacing: -1.0,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Transform.translate(
                            offset: const Offset(0, -6),
                            child: const BlueAccentRays(size: 24),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Subtitle
                      Text(
                        activity?.slug == 'debate_me'
                            ? 'Defend your position against assertive stakeholder pushback with confidence.'
                            : 'Answer a surprise question clearly, the way you would in a real meeting.',
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
                      _buildHowItWorksCard(),
                      const SizedBox(height: 16),

                      // CARD 2: USE YOUR 5 SECONDS
                      _buildUseYour5SecondsCard(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // Bottom CTA Button: Begin exercise ->
              ActionPillButton(
                label: 'Begin exercise',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RecordingScreen(),
                    ),
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

  /// CARD 1: HOW IT WORKS (Connected 4-Step Timeline)
  Widget _buildHowItWorksCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'HOW IT WORKS',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),

          // 4 Connected Step Icons Row
          Stack(
            alignment: Alignment.center,
            children: [
              // Connecting horizontal line
              Positioned(
                top: 22,
                left: 24,
                right: 24,
                child: Container(
                  height: 2,
                  color: const Color(0xFFDBEAFE),
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTimelineStep(
                    icon: Icons.format_list_bulleted_rounded,
                    title: '1. Question',
                    subtitle: 'A question\nappears.',
                  ),
                  _buildTimelineStep(
                    icon: Icons.timer_outlined,
                    title: '2. Think',
                    subtitle: 'You\'ll have\n5 seconds.',
                  ),
                  _buildTimelineStep(
                    icon: Icons.mic_none_rounded,
                    title: '3. Speak',
                    subtitle: 'The mic starts\nautomatically.',
                  ),
                  _buildTimelineStep(
                    icon: Icons.bar_chart_rounded,
                    title: '4. Feedback',
                    subtitle: 'Get custom\nfeedback.',
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
  }) {
    return SizedBox(
      width: 72,
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
            child: Icon(
              icon,
              color: const Color(0xFF2563EB),
              size: 21,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
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
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  /// CARD 2: USE YOUR 5 SECONDS (3 Mini Cards with Arrow Connectors)
  Widget _buildUseYour5SecondsCard() {
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
          const Text(
            'USE YOUR 5 SECONDS',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 14),

          // 3 Step Cards Row
          Row(
            children: [
              // Step 1: Pick your point
              Expanded(
                child: _buildMiniStepCard(
                  number: '1',
                  text: 'Pick\nyour point',
                  bgColor: const Color(0xFFEFF6FF),
                  numColor: const Color(0xFF2563EB),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFF94A3B8),
                  size: 15,
                ),
              ),

              // Step 2: Choose why
              Expanded(
                child: _buildMiniStepCard(
                  number: '2',
                  text: 'Choose\nwhy',
                  bgColor: const Color(0xFFFEF2F2),
                  numColor: const Color(0xFFEF4444),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFF94A3B8),
                  size: 15,
                ),
              ),

              // Step 3: Add one example
              Expanded(
                child: _buildMiniStepCard(
                  number: '3',
                  text: 'Add one\nexample',
                  bgColor: const Color(0xFFF0FDF4),
                  numColor: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: numColor,
              shape: BoxShape.circle,
            ),
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
              fontSize: 11.5,
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
