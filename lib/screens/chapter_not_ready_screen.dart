import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../providers/app_state_provider.dart';
import '../widgets/hakkiri_logo.dart';
import 'activity_detail_screen.dart';
import 'journey_screen.dart';

/// Screen displayed when chapter calendar time is finished but required practice sessions
/// are incomplete, exactly matching the bottom screen of media_1794890958539_8475d434.jpg
class ChapterNotReadyScreen extends StatelessWidget {
  final Map<String, dynamic>? data;

  const ChapterNotReadyScreen({
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

    const int completedSessions = 5;
    const int totalRequiredSessions = 8;
    const int remainingSessions = totalRequiredSessions - completedSessions;

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

                        // Title with blue accent
                        const Text(
                          'Chapter not ready',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.0,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1.0,
                              color: Color(0xFF2563EB),
                            ),
                            children: [
                              TextSpan(text: 'to close. '),
                              TextSpan(
                                text: "''",
                                style: TextStyle(color: Color(0xFF2563EB)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Subtitle
                        const Text(
                          'The calendar time is complete, but you still need more practice evidence to close this chapter.',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13.5,
                            height: 1.4,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Main Card: Calendar vs Practice Evidence
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
                              // 2 Status boxes row
                              Row(
                                children: [
                                  // Calendar time box
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: const Color(0xFFE2E8F0),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEFF6FF),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            alignment: Alignment.center,
                                            child: const Icon(
                                              Icons.calendar_today_outlined,
                                              color: Color(0xFF2563EB),
                                              size: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          const Text(
                                            'Calendar time',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFDCFCE7),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Text(
                                              '✓ Complete',
                                              style: TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF15803D),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // Practice evidence box
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: const Color(0xFFE2E8F0),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEFF6FF),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            alignment: Alignment.center,
                                            child: const Icon(
                                              Icons.layers_outlined,
                                              color: Color(0xFF2563EB),
                                              size: 17,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          const Text(
                                            'Practice evidence',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEFF6FF),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Text(
                                              '○ In progress',
                                              style: TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF2563EB),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),

                              // Scored sessions progress row
                              Row(
                                children: const [
                                  Icon(
                                    Icons.track_changes_rounded,
                                    color: Color(0xFF2563EB),
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    '$completedSessions of $totalRequiredSessions scored sessions complete',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: LinearProgressIndicator(
                                  value: completedSessions / totalRequiredSessions,
                                  minHeight: 6,
                                  backgroundColor: const Color(0xFFEFF6FF),
                                  valueColor: const AlwaysStoppedAnimation<Color>(
                                    Color(0xFF2563EB),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Info notice banner
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
                                            'This chapter stays open until you complete $remainingSessions more scored sessions.',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF0F172A),
                                              height: 1.25,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'This gives us enough recent evidence to produce stable, reliable scores for all four pillars.',
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
                        const SizedBox(height: 22),

                        // What to do next
                        const Text(
                          'What to do next',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 10),

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
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                  width: 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.bolt_rounded,
                                      color: Color(0xFF2563EB),
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: const [
                                        Text(
                                          'Keep practising',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                        SizedBox(height: 3),
                                        Text(
                                          'Complete $remainingSessions more scored sessions to close this chapter.',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 12.5,
                                            color: Color(0xFF64748B),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: Color(0xFF94A3B8),
                                    size: 22,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Bottom Button: Continue practising
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
                                    'Continue practising',
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
