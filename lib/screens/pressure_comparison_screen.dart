import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../providers/app_state_provider.dart';
import '../widgets/hakkiri_logo.dart';
import 'activity_detail_screen.dart';
import 'journey_screen.dart';

/// Screen comparing Normal Context vs Pressure Context performance,
/// matching media_1794890984108_75cc7861.jpg
class PressureComparisonScreen extends StatelessWidget {
  final Map<String, dynamic>? data;

  const PressureComparisonScreen({
    super.key,
    this.data,
  });

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);

    // Rows for comparison table
    final rows = [
      {
        'label': 'Clarity',
        'icon': Icons.track_changes_rounded,
        'normal': 3.8,
        'pressure': 3.3,
        'change': '-0.5',
      },
      {
        'label': 'Structure',
        'icon': Icons.format_list_bulleted_rounded,
        'normal': 3.6,
        'pressure': 3.2,
        'change': '-0.4',
      },
      {
        'label': 'Engagement\n& tone',
        'icon': Icons.chat_bubble_outline_rounded,
        'normal': 3.5,
        'pressure': 3.1,
        'change': '-0.4',
      },
      {
        'label': 'Conciseness',
        'icon': Icons.layers_outlined,
        'normal': 3.2,
        'pressure': 2.9,
        'change': '-0.3',
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Ambient background wash + 3D glowing sphere
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
                // Top App Bar
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

                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Kicker
                        const Text(
                          'CHAPTER 4 · PRESSURE COMPARISON',
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
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1.0,
                              color: Color(0xFF0F172A),
                            ),
                            children: [
                              TextSpan(text: 'Normal vs '),
                              TextSpan(
                                text: "''",
                                style: TextStyle(color: Color(0xFF2563EB)),
                              ),
                            ],
                          ),
                        ),
                        const Text(
                          'pressure.',
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
                          'See how your core scores hold up when the stakes rise.',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13.5,
                            height: 1.4,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Top 2 Graph Cards (Side by side)
                        Row(
                          children: const [
                            Expanded(
                              child: _PressureContextGraphCard(
                                icon: Icons.person_outline_rounded,
                                title: 'Normal context',
                                points: [3.8, 3.6, 3.5, 3.2],
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _PressureContextGraphCard(
                                icon: Icons.bolt_rounded,
                                title: 'Pressure context',
                                points: [3.3, 3.2, 3.1, 2.9],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Comparison Table Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                              width: 1.0,
                            ),
                          ),
                          child: Column(
                            children: [
                              // Column Headers Row
                              Row(
                                children: [
                                  const SizedBox(width: 82), // Spacing for label column
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: const [
                                          Icon(
                                            Icons.person_outline_rounded,
                                            size: 14,
                                            color: Color(0xFF2563EB),
                                          ),
                                          SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              'Normal\ncontext',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF0F172A),
                                                height: 1.1,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: const [
                                          Icon(
                                            Icons.bolt_rounded,
                                            size: 14,
                                            color: Color(0xFF2563EB),
                                          ),
                                          SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              'Pressure\ncontext',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF0F172A),
                                                height: 1.1,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const SizedBox(
                                    width: 42,
                                    child: Text(
                                      'Change',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Table Rows
                              ...rows.map((r) {
                                final label = r['label'] as String;
                                final icon = r['icon'] as IconData;
                                final normal = r['normal'] as double;
                                final pressure = r['pressure'] as double;
                                final change = r['change'] as String;

                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      // Icon + Label
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: const Color(0xFFE2E8F0),
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: Icon(
                                          icon,
                                          color: const Color(0xFF2563EB),
                                          size: 15,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      SizedBox(
                                        width: 48,
                                        child: Text(
                                          label,
                                          maxLines: 2,
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF0F172A),
                                            height: 1.15,
                                          ),
                                        ),
                                      ),

                                      // Normal context column
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            RichText(
                                              text: TextSpan(
                                                style: const TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w800,
                                                  color: Color(0xFF0F172A),
                                                ),
                                                children: [
                                                  TextSpan(text: normal.toStringAsFixed(1)),
                                                  const TextSpan(
                                                    text: ' / 5',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w500,
                                                      color: Color(0xFF94A3B8),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(3),
                                              child: LinearProgressIndicator(
                                                value: (normal / 5.0).clamp(0.0, 1.0),
                                                minHeight: 5,
                                                backgroundColor: const Color(0xFFE2E8F0),
                                                valueColor: const AlwaysStoppedAnimation<Color>(
                                                  Color(0xFF2563EB),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),

                                      // Pressure context column
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            RichText(
                                              text: TextSpan(
                                                style: const TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w800,
                                                  color: Color(0xFF0F172A),
                                                ),
                                                children: [
                                                  TextSpan(text: pressure.toStringAsFixed(1)),
                                                  const TextSpan(
                                                    text: ' / 5',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w500,
                                                      color: Color(0xFF94A3B8),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(3),
                                              child: LinearProgressIndicator(
                                                value: (pressure / 5.0).clamp(0.0, 1.0),
                                                minHeight: 5,
                                                backgroundColor: const Color(0xFFE2E8F0),
                                                valueColor: const AlwaysStoppedAnimation<Color>(
                                                  Color(0xFF2563EB),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),

                                      // Change Delta Pill
                                      Container(
                                        width: 42,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEF2F2),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          change,
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFFEF4444),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Insight Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
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
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.lightbulb_outline_rounded,
                                  color: Color(0xFF2563EB),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Your biggest drop is conciseness under pushback.',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Disclaimer
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 15,
                              color: Color(0xFF64748B),
                            ),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Where evidence is limited, we leave the field empty rather than estimating.',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11.5,
                                  color: Color(0xFF64748B),
                                  height: 1.3,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Bottom Button: Keep building under pressure
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              final activity = state.activities.firstWhere(
                                (a) =>
                                    a.slug == 'debate_me' ||
                                    a.slug == 'rapid_fire' ||
                                    a.slug == 'think_fast',
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
                                    'Keep building under pressure',
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

/// Mini Graph Card for Normal Context and Pressure Context
class _PressureContextGraphCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<double> points;

  const _PressureContextGraphCard({
    required this.icon,
    required this.title,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
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
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: const Color(0xFF2563EB), size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Chart with Y-Axis numbers
          SizedBox(
            height: 90,
            child: Row(
              children: [
                // Y-Axis labels
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      '5.0',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 9,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '4.0',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 9,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '3.0',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 9,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '2.0',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 9,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '1.0',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 9,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 6),

                // Custom Painter Chart
                Expanded(
                  child: CustomPaint(
                    size: const Size(double.infinity, 90),
                    painter: _ContextLineChartPainter(points: points),
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

class _ContextLineChartPainter extends CustomPainter {
  final List<double> points;

  _ContextLineChartPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    // Draw horizontal dashed grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 1.0;

    for (int i = 0; i <= 4; i++) {
      final y = size.height * (i / 4.0);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final double minVal = 1.0;
    final double maxVal = 5.0;

    final List<Offset> offsets = [];
    final double stepX = size.width / (points.length - 1);

    for (int i = 0; i < points.length; i++) {
      final x = i * stepX;
      final normalized = (points[i] - minVal) / (maxVal - minVal);
      final y = size.height - (normalized * size.height);
      offsets.add(Offset(x, y));
    }

    // Path for line and gradient fill
    final linePath = Path();
    linePath.moveTo(offsets.first.dx, offsets.first.dy);
    for (int i = 1; i < offsets.length; i++) {
      linePath.lineTo(offsets[i].dx, offsets[i].dy);
    }

    final fillPath = Path.from(linePath);
    fillPath.lineTo(offsets.last.dx, size.height);
    fillPath.lineTo(offsets.first.dx, size.height);
    fillPath.close();

    // Fill with gradient
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF3B82F6).withValues(alpha: 0.25),
          const Color(0xFF3B82F6).withValues(alpha: 0.02),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Draw line
    final linePaint = Paint()
      ..color = const Color(0xFF2563EB)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(linePath, linePaint);

    // Draw points (circular white dots with blue border)
    final dotFill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final dotBorder = Paint()
      ..color = const Color(0xFF2563EB)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (final p in offsets) {
      canvas.drawCircle(p, 3.5, dotFill);
      canvas.drawCircle(p, 3.5, dotBorder);
    }
  }

  @override
  bool shouldRepaint(covariant _ContextLineChartPainter oldDelegate) => true;
}
