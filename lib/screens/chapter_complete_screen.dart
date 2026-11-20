import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../widgets/hakkiri_logo.dart';
import 'journey_screen.dart';

/// Screen displayed upon completing a chapter, exactly matching media_1794890811118_c048d99b.jpg
class ChapterCompleteScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const ChapterCompleteScreen({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final chapter = data['chapter'] is Map
        ? Map<String, dynamic>.from(data['chapter'] as Map)
        : <String, dynamic>{};
    final review = data['chapter_review'] is Map
        ? Map<String, dynamic>.from(data['chapter_review'] as Map)
        : <String, dynamic>{};

    final int number = (chapter['number'] as num?)?.round() ?? 2;
    final String title = (chapter['title'] ?? 'Add structure').toString().trim();

    // Default movements matching mockup image (Chapter 2 -> Chapter 3)
    final movementList = [
      {
        'key': 'clarity',
        'label': 'Clarity',
        'icon': Icons.track_changes_rounded,
        'start': 2.9,
        'end': 3.4,
        'delta': '+0.5',
      },
      {
        'key': 'structure',
        'label': 'Structure',
        'icon': Icons.layers_outlined,
        'start': 2.6,
        'end': 3.5,
        'delta': '+0.9',
      },
      {
        'key': 'engagement',
        'label': 'Engagement\n& Tone',
        'icon': Icons.chat_bubble_outline_rounded,
        'start': 2.8,
        'end': 3.1,
        'delta': '+0.3',
      },
      {
        'key': 'conciseness',
        'label': 'Conciseness',
        'icon': Icons.bolt_rounded,
        'start': 2.7,
        'end': 3.2,
        'delta': '+0.5',
      },
    ];

    final coachNote = (review['coach_note'] as String?) ??
        "You're getting to the point faster and your answers feel more organised.";

    final nextChInfo = _resolveNextChapter(number);

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
                        const Text(
                          'CHAPTER COMPLETE',
                          style: TextStyle(
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
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.8,
                              color: Color(0xFF0F172A),
                            ),
                            children: [
                              TextSpan(text: 'Chapter complete'),
                              TextSpan(
                                text: "''",
                                style: TextStyle(color: Color(0xFF2563EB)),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '$title.',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.8,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Here's a review of your progress in this chapter.",
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13.5,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Card 1: Chapter Movement Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.trending_up_rounded,
                                      color: Color(0xFF2563EB),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Chapter movement',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Table Column Headers
                              Padding(
                                padding: const EdgeInsets.only(left: 100, right: 48),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: const [
                                    Text(
                                      'Chapter start',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                    Text(
                                      'Chapter end',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),

                              // 4 Pillar rows
                              ...movementList.map((m) {
                                final label = m['label'] as String;
                                final icon = m['icon'] as IconData;
                                final start = m['start'] as double;
                                final end = m['end'] as double;
                                final delta = m['delta'] as String;

                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 9),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      // Icon + Name
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(color: const Color(0xFFE2E8F0)),
                                        ),
                                        alignment: Alignment.center,
                                        child: Icon(icon, color: const Color(0xFF2563EB), size: 15),
                                      ),
                                      const SizedBox(width: 8),
                                      SizedBox(
                                        width: 78,
                                        child: Text(
                                          label,
                                          maxLines: 2,
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF0F172A),
                                            height: 1.15,
                                          ),
                                        ),
                                      ),

                                      // Start Score
                                      SizedBox(
                                        width: 28,
                                        child: Text(
                                          start.toStringAsFixed(1),
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),

                                      // Progress Bar
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(3),
                                          child: LinearProgressIndicator(
                                            value: (end / 5.0).clamp(0.0, 1.0),
                                            minHeight: 6,
                                            backgroundColor: const Color(0xFFEFF6FF),
                                            valueColor: const AlwaysStoppedAnimation<Color>(
                                              Color(0xFF2563EB),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),

                                      // End Score
                                      SizedBox(
                                        width: 28,
                                        child: Text(
                                          end.toStringAsFixed(1),
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),

                                      // Delta Pill
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEFF6FF),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          delta,
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF2563EB),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              const SizedBox(height: 14),

                              // Overall score banner
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.layers_rounded,
                                      color: Color(0xFF2563EB),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    RichText(
                                      text: const TextSpan(
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF0F172A),
                                        ),
                                        children: [
                                          TextSpan(text: 'Overall score: '),
                                          TextSpan(text: '2.8/5 '),
                                          TextSpan(
                                            text: '→ ',
                                            style: TextStyle(color: Color(0xFF2563EB)),
                                          ),
                                          TextSpan(text: '3.3/5'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Card 2: Coach note
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.school_outlined,
                                  color: Color(0xFF2563EB),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Coach note',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      coachNote,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 13,
                                        color: Color(0xFF475569),
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
                        const SizedBox(height: 14),

                        // Card 3: Next chapter
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Next chapter',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                    width: 1.0,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        Icons.campaign_outlined,
                                        color: Color(0xFF2563EB),
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            nextChInfo.$1,
                                            style: const TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            nextChInfo.$2,
                                            style: const TextStyle(
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
                        const SizedBox(height: 24),

                        // Bottom CTA: Start next chapter
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            borderRadius: BorderRadius.circular(28),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(28),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Spacer(),
                                  const Text(
                                    'Start next chapter',
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

  static (String, String) _resolveNextChapter(int currentNumber) {
    switch (currentNumber) {
      case 1:
        return (
          'Add structure · 8 weeks',
          'Lead with your point, support it with clear reasons, and close with purpose.',
        );
      case 2:
        return (
          'Speak with clarity · 16 weeks',
          'Make your ideas easy to follow, so you can express yourself with confidence in any setting.',
        );
      case 3:
        return (
          'Handle pressure · 8 weeks',
          'Keep your clarity, structure, tone and conciseness steady when the stakes rise.',
        );
      case 4:
        return (
          'Find your own style · 8 weeks',
          'Sound more natural and engaging while staying clear and well structured.',
        );
      default:
        return (
          'Journey Complete · Master your skills',
          'Continue daily focused practice to keep your communication sharp.',
        );
    }
  }
}
