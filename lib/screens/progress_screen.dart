import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/app_state_provider.dart';
import '../widgets/custom_sparkline.dart';
import '../widgets/hakkiri_logo.dart';
import '../widgets/orbital_background_painter.dart';
import 'activity_detail_screen.dart';
import 'main_tab_scaffold.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainTabScaffold(initialIndex: 1);
  }
}

class ProgressScreenContent extends StatefulWidget {
  const ProgressScreenContent({super.key});

  @override
  State<ProgressScreenContent> createState() => _ProgressScreenContentState();
}

class _ProgressScreenContentState extends State<ProgressScreenContent> {
  int _selectedFilter = 0; // 0: 7 days, 1: 30 days, 2: 3 months

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Logo + Filter Tabs Pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const HakkiriLogo(
                  variant: HakkiriLogoVariant.compactMark,
                  size: 22,
                ),
                // Pill Selector: [ 7 days | 30 days | 3 months ]
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.surfaceBorder, width: 1.0),
                  ),
                  child: Row(
                    children: [
                      _buildFilterPill(0, '7 days'),
                      _buildFilterPill(1, '30 days'),
                      _buildFilterPill(2, '3 months'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Header Section with Wave Background
            Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  right: -10,
                  top: -10,
                  bottom: -10,
                  width: 140,
                  child: CustomPaint(painter: ProgressWavePainter()),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'YOUR PROGRESS',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: AppColors.textPrimary,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.8,
                          height: 1.15,
                        ),
                        children: [
                          TextSpan(text: "You're getting clearer.\n"),
                          TextSpan(
                            text: 'Keep it going.',
                            style: TextStyle(color: AppColors.royalBlue),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Hero Dark Card (Overall Score + Wavy Chart)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E1B4B).withValues(alpha: 0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Circular Score Ring
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF38BDF8),
                            width: 4.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF38BDF8).withValues(alpha: 0.3),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text(
                              'OVERALL',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                            SizedBox(height: 1),
                            Text(
                              '3.6',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              '/ 5',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.arrow_drop_up_rounded, color: Color(0xFF10B981), size: 18),
                                    Text(
                                      '0.4 vs 30d',
                                      style: TextStyle(
                                        color: Color(0xFF10B981),
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.info_outline_rounded, color: Colors.white70, size: 11),
                                      SizedBox(width: 3),
                                      Text(
                                        'How scores work',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Great progress.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '3 of 4 skills analysed.\nComplete 2 more Storytelling or Debate sessions to unlock Engagement & tone.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 11.5,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Glowing trendline with dots
                  CustomSparkline(
                    values: const [3.1, 3.2, 3.3, 3.25, 3.5, 3.6],
                    color: const Color(0xFF60A5FA),
                    strokeWidth: 2.5,
                    height: 28,
                    showDots: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // SKILL BREAKDOWN Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'SKILL BREAKDOWN',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                Row(
                  children: const [
                    Text(
                      'Tap a skill to see more details',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textMuted),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 2x2 Grid of Skill Cards
            Row(
              children: [
                Expanded(
                  child: _buildSkillCard(
                    icon: Icons.mic_rounded,
                    iconColor: const Color(0xFF3B82F6),
                    iconBgColor: const Color(0xFFEFF6FF),
                    title: 'Fluency & presence',
                    scoreText: '3.4',
                    deltaText: '▲ 0.6',
                    isDeltaPositive: true,
                    description: 'Steadier pace, fewer hesitations.',
                    sparklinePoints: const [2.8, 3.0, 2.9, 3.2, 3.4],
                    sparklineColor: const Color(0xFF3B82F6),
                    isLocked: false,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSkillCard(
                    icon: Icons.visibility_rounded,
                    iconColor: const Color(0xFF10B981),
                    iconBgColor: const Color(0xFFECFDF5),
                    title: 'Clarity',
                    scoreText: '3.8',
                    deltaText: '▲ 0.7',
                    isDeltaPositive: true,
                    description: 'Your main points are easier to follow.',
                    sparklinePoints: const [3.0, 3.2, 3.4, 3.6, 3.8],
                    sparklineColor: const Color(0xFF10B981),
                    isLocked: false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSkillCard(
                    icon: Icons.auto_awesome_rounded,
                    iconColor: const Color(0xFFEF4444),
                    iconBgColor: const Color(0xFFFEF2F2),
                    title: 'Engagement & tone',
                    scoreText: '--',
                    deltaText: null,
                    isDeltaPositive: null,
                    description: '2 more sessions to unlock this score.',
                    sparklinePoints: const [2.0, 2.0, 2.0],
                    sparklineColor: const Color(0xFFCBD5E1),
                    isLocked: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSkillCard(
                    icon: Icons.content_cut_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    iconBgColor: const Color(0xFFFFFBEB),
                    title: 'Conciseness',
                    scoreText: '3.1',
                    deltaText: '▼ 0.2',
                    isDeltaPositive: false,
                    description: 'Get to the point faster.',
                    sparklinePoints: const [3.4, 3.3, 3.2, 3.1],
                    sparklineColor: const Color(0xFFF59E0B),
                    isLocked: false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // RECOMMENDED NEXT Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFFEF3C7), width: 1.0),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.content_cut_rounded, color: Color(0xFFD97706), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Row(
                          children: [
                            Text(
                              'RECOMMENDED NEXT',
                              style: TextStyle(
                                color: Color(0xFFD97706),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                            SizedBox(width: 6),
                            Text(
                              '· ~2 min',
                              style: TextStyle(
                                color: Color(0xFFB45309),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Cut it in Half',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Build your conciseness with short, focused answers.',
                          style: TextStyle(
                            color: Color(0xFF92400E),
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      state.selectActivity('cut_it_in_half');
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ActivityDetailScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.royalBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'Start',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, size: 14),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // RECENT SESSIONS Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'RECENT SESSIONS',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                Row(
                  children: const [
                    Text(
                      'See all',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textMuted),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Session 1: Think Fast
            _buildRecentSessionCard(
              scoreFraction: '4/5',
              scoreFractionValue: 4 / 5,
              ringColor: const Color(0xFF10B981),
              title: 'Think Fast',
              dateDuration: 'Today, 10:24 · 🕒 2 min',
              scoreBadge: '3.7 ↗',
              onTap: () {
                state.selectActivity('think_fast');
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ActivityDetailScreen()),
                );
              },
            ),
            const SizedBox(height: 10),

            // Session 2: Debate Me
            _buildRecentSessionCard(
              scoreFraction: '3/5',
              scoreFractionValue: 3 / 5,
              ringColor: const Color(0xFF6366F1),
              title: 'Debate Me',
              dateDuration: '02 Oct 2024 · 🕒 3 min',
              scoreBadge: '3.2 ↗',
              onTap: () {
                state.selectActivity('debate_me');
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ActivityDetailScreen()),
                );
              },
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPill(int index, String label) {
    final isSelected = _selectedFilter == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.royalBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSkillCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String scoreText,
    required String? deltaText,
    required bool? isDeltaPositive,
    required String description,
    required List<double> sparklinePoints,
    required Color sparklineColor,
    required bool isLocked,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              if (isLocked) ...[
                const Icon(Icons.lock_outline_rounded, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 4),
              ],
              Text(
                scoreText,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (deltaText != null) ...[
                const SizedBox(width: 6),
                Text(
                  deltaText,
                  style: TextStyle(
                    color: isDeltaPositive == true
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          CustomSparkline(
            values: sparklinePoints,
            color: sparklineColor,
            strokeWidth: 2,
            height: 16,
            isDotted: isLocked,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSessionCard({
    required String scoreFraction,
    required double scoreFractionValue,
    required Color ringColor,
    required String title,
    required String dateDuration,
    required String scoreBadge,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceBorder, width: 1.0),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      value: scoreFractionValue,
                      strokeWidth: 3,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation<Color>(ringColor),
                    ),
                  ),
                  Text(
                    scoreFraction,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
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
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateDuration,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Text(
                  scoreBadge,
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
