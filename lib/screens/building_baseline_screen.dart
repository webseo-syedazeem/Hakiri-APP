import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../providers/app_state_provider.dart';
import '../widgets/hakkiri_logo.dart';
import 'activity_detail_screen.dart';
import 'journey_screen.dart';

/// Screen displayed when user is establishing their baseline in a chapter,
/// exactly matching the top screen of media_1794890958539_8475d434.jpg
class BuildingBaselineScreen extends StatelessWidget {
  final Map<String, dynamic>? data;

  const BuildingBaselineScreen({
    super.key,
    this.data,
  });

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final chapter = data?['chapter'] is Map
        ? Map<String, dynamic>.from(data!['chapter'] as Map)
        : <String, dynamic>{};

    final int number = (chapter['number'] as num?)?.round() ?? 2;
    final String title =
        (chapter['title'] ?? 'Add structure').toString().trim().toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Ambient background wash + 3D sphere
          const Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: ChapterBackgroundPainter(),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                        color: const Color(0xFF0F172A),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 4),
                      const HakkiriLogo(
                        variant: HakkiriLogoVariant.compactMark,
                        size: 26,
                      ),
                    ],
                  ),
                ),

                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Kicker
                        Text(
                          'CHAPTER $number · $title',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Title with blue quotes
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1.0,
                              color: Color(0xFF0F172A),
                            ),
                            children: [
                              TextSpan(text: 'Building your '),
                              TextSpan(
                                text: "''",
                                style: TextStyle(color: Color(0xFF2563EB)),
                              ),
                            ],
                          ),
                        ),
                        const Text(
                          'baseline.',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.0,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Subtitle
                        const Text(
                          'Keep practising so we can build a reliable baseline across all four Hakkiri scores.',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13.5,
                            height: 1.4,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Card: Your Hakkiri scores
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                              width: 1.0,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Your Hakkiri scores',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                "We're building your scores as you complete more scored practice.",
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12.5,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // 2x2 Grid of Building Baseline Tiles
                              Row(
                                children: [
                                  Expanded(
                                    child: _BaselinePillarCard(
                                      icon: Icons.track_changes_rounded,
                                      title: 'Clarity',
                                      statusText: 'Not enough scored\nanswers yet.',
                                      isDotsMode: true,
                                      dotsFilled: 2,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _BaselinePillarCard(
                                      icon: Icons.layers_outlined,
                                      title: 'Structure',
                                      statusText: 'Building your score...',
                                      isDotsMode: false,
                                      progress: 0.35,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: _BaselinePillarCard(
                                      icon: Icons.chat_bubble_outline_rounded,
                                      title: 'Engagement\n& tone',
                                      statusText: 'Not enough scored\nanswers yet.',
                                      isDotsMode: true,
                                      dotsFilled: 2,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _BaselinePillarCard(
                                      icon: Icons.bolt_rounded,
                                      title: 'Conciseness',
                                      statusText: 'Building your score...',
                                      isDotsMode: false,
                                      progress: 0.35,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // What this means banner
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 26,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFF2563EB),
                                          width: 1.8,
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: const Text(
                                        'i',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF2563EB),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: const [
                                          Text(
                                            'What this means',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                          SizedBox(height: 3),
                                          Text(
                                            'One or more pillars need more scored answers before we can show a stable score.',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 12,
                                              color: Color(0xFF64748B),
                                              height: 1.35,
                                              fontWeight: FontWeight.w500,
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
                        const SizedBox(height: 28),

                        // Bottom Button: Keep practising
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              final activity = state.activities.firstWhere(
                                (a) => a.slug == 'rapid_fire' || a.slug == 'think_fast',
                                orElse: () => state.activities.first,
                              );
                              state.selectActivity(activity.slug);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ActivityDetailScreen(
                                    activitySlug: activity.slug,
                                  ),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(28),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(28),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Spacer(),
                                  const Text(
                                    'Keep practising',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF2563EB),
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BaselinePillarCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String statusText;
  final bool isDotsMode;
  final int dotsFilled;
  final double progress;

  const _BaselinePillarCard({
    required this.icon,
    required this.title,
    required this.statusText,
    required this.isDotsMode,
    this.dotsFilled = 2,
    this.progress = 0.35,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: const Color(0xFF2563EB), size: 17),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    height: 1.15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            statusText,
            maxLines: 2,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: Color(0xFF64748B),
              height: 1.25,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          if (isDotsMode)
            Row(
              children: List.generate(4, (index) {
                final isFilled = index < dotsFilled;
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: isFilled
                        ? const Color(0xFF93C5FD)
                        : const Color(0xFFE2E8F0),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF2563EB),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
