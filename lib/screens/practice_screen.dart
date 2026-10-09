import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/app_state_provider.dart';
import '../widgets/hakkiri_logo.dart';
import '../widgets/orbital_background_painter.dart';
import 'activity_detail_screen.dart';
import 'main_tab_scaffold.dart';

class PracticeScreen extends StatelessWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainTabScaffold(initialIndex: 2);
  }
}

class PracticeScreenContent extends StatelessWidget {
  const PracticeScreenContent({super.key});

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
            // Top Row with Orbital Accent in Background
            Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  right: -30,
                  top: -20,
                  width: 160,
                  height: 120,
                  child: const CustomPaint(painter: OrbitalBackgroundPainter()),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const HakkiriLogo(
                      variant: HakkiriLogoVariant.compactMark,
                      size: 22,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'PRACTICE',
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
                          TextSpan(text: 'Choose\n'),
                          TextSpan(
                            text: 'what to work on',
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

            // Hero Dark Card (Recommended for you)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recommended for you',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.bolt_rounded, color: Color(0xFF60A5FA), size: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Based on your assessment and recent performance.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Horizontal row of 3 cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildHeroSubCard(
                          icon: Icons.bolt_rounded,
                          iconColor: const Color(0xFF3B82F6),
                          iconBgColor: const Color(0xFFEFF6FF),
                          title: 'Think Fast',
                          description: 'Think clearly under pressure',
                          onTap: () {
                            state.selectActivity('think_fast');
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ActivityDetailScreen()),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildHeroSubCard(
                          icon: Icons.content_cut_rounded,
                          iconColor: const Color(0xFF10B981),
                          iconBgColor: const Color(0xFFECFDF5),
                          title: 'Cut it in Half',
                          description: 'Get to the point faster',
                          onTap: () {
                            state.selectActivity('cut_it_in_half');
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ActivityDetailScreen()),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildHeroSubCard(
                          icon: Icons.menu_book_rounded,
                          iconColor: const Color(0xFF8B5CF6),
                          iconBgColor: const Color(0xFFF5F3FF),
                          title: 'Storytelling Gym',
                          description: 'Make your answers more engaging',
                          onTap: () {
                            state.selectActivity('storytelling_gym');
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ActivityDetailScreen()),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Category 1: Think on your feet
            _buildCategoryHeader('Think on your feet', () {}),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildVerticalCard(
                    icon: Icons.bolt_rounded,
                    iconColor: const Color(0xFF3B82F6),
                    iconBgColor: const Color(0xFFEFF6FF),
                    title: 'Think Fast',
                    description: 'Think clearly under pressure',
                    onTap: () {
                      state.selectActivity('think_fast');
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ActivityDetailScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildVerticalCard(
                    icon: Icons.chat_bubble_outline_rounded,
                    iconColor: const Color(0xFF3B82F6),
                    iconBgColor: const Color(0xFFEFF6FF),
                    title: 'Debate Me',
                    description: 'Build and defend your ideas',
                    onTap: () {
                      state.selectActivity('debate_me');
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ActivityDetailScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildVerticalCard(
                    icon: Icons.hub_rounded,
                    iconColor: const Color(0xFF8B5CF6),
                    iconBgColor: const Color(0xFFF5F3FF),
                    title: 'Connect the Dots',
                    description: 'Find the big picture and make links',
                    onTap: () {
                      state.selectActivity('connect_the_dots');
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ActivityDetailScreen()),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Category 2: Be clear & concise
            _buildCategoryHeader('Be clear & concise', () {}),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildHorizontalCard(
                    icon: Icons.content_cut_rounded,
                    iconColor: const Color(0xFF10B981),
                    iconBgColor: const Color(0xFFECFDF5),
                    title: 'Cut it in Half',
                    description: 'Get to the point faster',
                    onTap: () {
                      state.selectActivity('cut_it_in_half');
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ActivityDetailScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildHorizontalCard(
                    icon: Icons.timer_outlined,
                    iconColor: const Color(0xFFF97316),
                    iconBgColor: const Color(0xFFFFF7ED),
                    title: 'One Minute Expert',
                    description: 'Explain complex ideas simply',
                    onTap: () {
                      state.selectActivity('one_minute_expert');
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ActivityDetailScreen()),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Category 3: Engage people
            _buildCategoryHeader('Engage people', () {}),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildHorizontalCard(
                    icon: Icons.menu_book_rounded,
                    iconColor: const Color(0xFF8B5CF6),
                    iconBgColor: const Color(0xFFF5F3FF),
                    title: 'Storytelling Gym',
                    description: 'Make your answers more engaging',
                    onTap: () {
                      state.selectActivity('storytelling_gym');
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ActivityDetailScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildHorizontalCard(
                    icon: Icons.campaign_outlined,
                    iconColor: const Color(0xFFEF4444),
                    iconBgColor: const Color(0xFFFEF2F2),
                    title: 'Persuade',
                    description: 'Build a compelling case',
                    onTap: () {
                      state.selectActivity('persuade');
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ActivityDetailScreen()),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  static Widget _buildCategoryHeader(String title, VoidCallback onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.surfaceBorderLight,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  static Widget _buildHeroSubCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 135,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textMuted),
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              description,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10.5,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildVerticalCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 140,
        padding: const EdgeInsets.all(12),
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
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textMuted),
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              description,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10.5,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildHorizontalCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 80,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceBorder, width: 1.0),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      height: 1.15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
