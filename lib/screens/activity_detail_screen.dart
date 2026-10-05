import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/app_state_provider.dart';
import '../widgets/action_pill_button.dart';
import 'recording_screen.dart';

class ActivityDetailScreen extends StatefulWidget {
  const ActivityDetailScreen({super.key});

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  String _selectedLevel = 'beginner';

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back Chevron
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(
                          Icons.chevron_left_rounded,
                          color: AppColors.textPrimary,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Category Tag
                      const Text(
                        'SPONTANEOUS AGILITY',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Heading with Royal Blue Accent
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: AppColors.textPrimary,
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.0,
                            height: 1.15,
                          ),
                          children: [
                            TextSpan(text: 'Think First\n'),
                            TextSpan(
                              text: 'Three seconds. Then\nspeak.',
                              style: TextStyle(color: AppColors.royalBlue),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Badges Row (3S PREP, 60S SPEAK)
                      Row(
                        children: [
                          _buildTimingBadge('3S PREP'),
                          const SizedBox(width: 8),
                          _buildTimingBadge('60S SPEAK'),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Choose Your Level
                      const Text(
                        'CHOOSE YOUR LEVEL',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 2x2 Level Grid
                      Row(
                        children: [
                          Expanded(child: _buildLevelCard('beginner', 'Beginner')),
                          const SizedBox(width: 10),
                          Expanded(child: _buildLevelCard('intermediary', 'Intermediary')),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: _buildLevelCard('pro', 'Pro')),
                          const SizedBox(width: 10),
                          Expanded(child: _buildLevelCard('i_dont_know', 'I don’t know')),
                        ],
                      ),
                      const SizedBox(height: 12),

                      const Text(
                        'Not sure? Pick “I don’t know” for a general question, and we’ll suggest a level.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // QUICK TIP Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceWhite,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.surfaceBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'QUICK TIP',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Answer → Reason → Example',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Say your answer first. A short pause is fine.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      const Center(
                        child: Text(
                          'We’ll ask for your microphone next. Recording starts after the countdown.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // Bottom Button
              ActionPillButton(
                label: 'I’m ready',
                onPressed: () {
                  state.setDifficulty(_selectedLevel);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RecordingScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimingBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildLevelCard(String id, String label) {
    final isSelected = _selectedLevel == id;

    return GestureDetector(
      onTap: () => setState(() => _selectedLevel = id),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF141522) : AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? null
              : Border.all(
                  color: const Color(0xFFD8D6CC),
                  width: 1.2,
                ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
