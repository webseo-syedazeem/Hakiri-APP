import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../widgets/connect_the_dots_icon.dart';
import '../widgets/practice_orbital_accent.dart';
import 'activity_detail_screen.dart';
import 'debate_me_screen.dart';
import 'main_tab_scaffold.dart';
import 'reflect_and_grow_screen.dart';

class PracticeScreen extends StatelessWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainTabScaffold(initialIndex: 2);
  }
}

class PracticeScreenContent extends StatefulWidget {
  const PracticeScreenContent({super.key});

  @override
  State<PracticeScreenContent> createState() => _PracticeScreenContentState();
}

class _PracticeScreenContentState extends State<PracticeScreenContent> {
  bool _showReflectAndGrow = false;

  void _openActivity(AppStateProvider state, String slug) {
    state.selectActivity(slug);
    if (slug == 'debate_me') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DebateMeScreen()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ActivityDetailScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);

    if (_showReflectAndGrow) {
      return ReflectAndGrowContent(
        onBack: () => setState(() => _showReflectAndGrow = false),
      );
    }

    return Stack(
      children: [
        const PracticeOrbitalAccent(topOffset: 0, rightOffset: 0),
        SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Text
                const Text(
                  'PRACTICE',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: Color(0xFF0F172A),
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                      height: 1.15,
                    ),
                    children: [
                      TextSpan(text: 'Choose\n'),
                      TextSpan(
                        text: 'what to work on',
                        style: TextStyle(color: Color(0xFF2563EB)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Hero Dark Card (Recommended for you)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF071228),
                        Color(0xFF0F2552),
                        Color(0xFF1D4ED8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1D4ED8).withValues(alpha: 0.22),
                        blurRadius: 16,
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
                              fontFamily: 'Inter',
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: Color(0xFF2563EB),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.bolt_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Based on your assessment and recent performance.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Horizontal Row of 3 White Sub-Cards —
                      // driven by the user's real plan so it matches Today.
                      _buildRecommendedRow(state),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Category 1: Think on your feet
                _buildCategoryHeader(
                  title: 'Think on your feet',
                  subtitle: 'Stay clear, calm and confident in the moment.',
                  onTap: () {},
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _buildVerticalCard(
                        iconWidget: const Icon(
                          Icons.bolt_rounded,
                          color: Color(0xFF2563EB),
                          size: 24,
                        ),
                        iconBgColor: const Color(0xFFEFF6FF),
                        title: 'Think Fast',
                        description: 'Think clearly\nunder pressure',
                        onTap: () => _openActivity(state, 'think_fast'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildVerticalCard(
                        iconWidget: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: Color(0xFF2563EB),
                          size: 24,
                        ),
                        iconBgColor: const Color(0xFFEFF6FF),
                        title: 'Debate Me',
                        description: 'Build and defend\nyour ideas',
                        onTap: () => _openActivity(state, 'debate_me'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildVerticalCard(
                        iconWidget: const ConnectTheDotsIcon(
                          color: Color(0xFF9333EA),
                          size: 24,
                        ),
                        iconBgColor: const Color(0xFFF5F3FF),
                        title: 'Connect the Dots',
                        description: 'Find the big picture\nand make links',
                        onTap: () => _openActivity(state, 'connect_the_dots'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Category 2: Be clear & concise
                _buildCategoryHeader(
                  title: 'Be clear & concise',
                  subtitle: 'Get to the point and make your message land.',
                  onTap: () {},
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildHorizontalCard(
                        icon: Icons.content_cut_rounded,
                        iconColor: const Color(0xFFD97706),
                        iconBgColor: const Color(0xFFF8FAFC),
                        title: 'Cut it in Half',
                        description: 'Get to the point faster',
                        onTap: () => _openActivity(state, 'cut_it_in_half'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildHorizontalCard(
                        icon: Icons.timer_outlined,
                        iconColor: const Color(0xFFEA580C),
                        iconBgColor: const Color(0xFFFEE2E2),
                        title: 'One Minute Expert',
                        description: 'Explain complex ideas simply',
                        onTap: () => _openActivity(state, 'one_minute_expert'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Category 3: Engage people
                _buildCategoryHeader(
                  title: 'Engage people',
                  subtitle: 'Make your ideas more engaging and memorable.',
                  onTap: () {},
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildHorizontalCard(
                        icon: Icons.menu_book_rounded,
                        iconColor: const Color(0xFF9333EA),
                        iconBgColor: const Color(0xFFF3E8FF),
                        title: 'Storytelling Gym',
                        description: 'Make your answers more engaging',
                        onTap: () => _openActivity(state, 'storytelling_gym'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildHorizontalCard(
                        icon: Icons.campaign_outlined,
                        iconColor: const Color(0xFFF97316),
                        iconBgColor: const Color(0xFFF8FAFC),
                        title: 'Explain It Simply',
                        description: 'Make complex ideas easy to understand',
                        onTap: () => _openActivity(state, 'explain_it_simply'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Category 4: Reflect and grow
                _buildCategoryHeader(
                  title: 'Reflect and grow',
                  subtitle: 'Look back, learn and build on your progress.',
                  onTap: () => setState(() => _showReflectAndGrow = true),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => setState(() => _showReflectAndGrow = true),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF1F5F9), width: 1.0),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.bar_chart_rounded,
                            color: Color(0xFF10B981),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Notes to Future Self',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  color: Color(0xFF0F172A),
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Capture what you’ve learned and set a focus for next time',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  color: Color(0xFF64748B),
                                  fontSize: 12,
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: Color(0xFF94A3B8),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 36),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryHeader({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF0F172A),
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: Color(0xFF2563EB),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(
            fontFamily: 'Inter',
            color: Color(0xFF64748B),
            fontSize: 12.5,
          ),
        ),
      ],
    );
  }

  /// Visual (icon, icon colour, icon background) for a given activity slug.
  static (IconData, Color, Color) _recVisual(String slug) {
    switch (slug) {
      case 'cut_it_in_half':
        return (Icons.content_cut_rounded, const Color(0xFFD97706), const Color(0xFFF8FAFC));
      case 'storytelling_gym':
        return (Icons.menu_book_rounded, const Color(0xFF9333EA), const Color(0xFFF3E8FF));
      case 'debate_me':
        return (Icons.chat_bubble_outline_rounded, const Color(0xFF2563EB), const Color(0xFFEFF6FF));
      case 'connect_the_dots':
        return (Icons.hub_outlined, const Color(0xFF9333EA), const Color(0xFFF5F3FF));
      case 'explain_it_simply':
        return (Icons.lightbulb_outline_rounded, const Color(0xFF10B981), const Color(0xFFECFDF5));
      case 'one_minute_expert':
        return (Icons.timer_outlined, const Color(0xFFEA580C), const Color(0xFFFEE2E2));
      case 'think_fast':
      default:
        return (Icons.bolt_rounded, const Color(0xFF2563EB), const Color(0xFFEFF6FF));
    }
  }

  /// The 3 "Recommended for you" cards — taken from the same personalised
  /// plan the Today tab uses, so the two screens always agree.
  Widget _buildRecommendedRow(AppStateProvider state) {
    final slugs = state.todayDrillSlugs
        .map(AppStateProvider.normalizeActivitySlug)
        .take(3)
        .toList();
    while (slugs.length < 3) {
      for (final fallback in const ['think_fast', 'cut_it_in_half', 'storytelling_gym']) {
        if (!slugs.contains(fallback)) {
          slugs.add(fallback);
          if (slugs.length == 3) break;
        }
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Builder(
              builder: (_) {
                final slug = slugs[i];
                final activity = state.activities.firstWhere(
                  (a) => a.slug == slug,
                  orElse: () => state.activities.first,
                );
                final v = _recVisual(slug);
                return _buildHeroSubCard(
                  icon: v.$1,
                  iconColor: v.$2,
                  iconBgColor: v.$3,
                  title: activity.name,
                  description: activity.tagline,
                  onTap: () => _openActivity(state, slug),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHeroSubCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: Color(0xFF94A3B8),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF0F172A),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              description,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF64748B),
                fontSize: 10,
                height: 1.15,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalCard({
    required Widget iconWidget,
    required Color iconBgColor,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
                  ),
                  alignment: Alignment.center,
                  child: iconWidget,
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: Color(0xFF94A3B8),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF0F172A),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              description,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF64748B),
                fontSize: 10,
                height: 1.15,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 74,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: iconColor, size: 26),
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
                      fontFamily: 'Inter',
                      color: Color(0xFF0F172A),
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
                      fontFamily: 'Inter',
                      color: Color(0xFF64748B),
                      fontSize: 10,
                      height: 1.15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }
}
