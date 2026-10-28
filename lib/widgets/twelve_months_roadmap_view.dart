import 'package:flutter/material.dart';
import 'blue_accent_rays.dart';

/// Clean vertical timeline roadmap for "Twelve months, one step at a time."
/// Matching Image 1 (media_1793096761211_9f314ea4.png) with top mountain graphic,
/// 5 milestone cards with straight timeline, and bottom summary pillars.
class TwelveMonthsRoadmapView extends StatelessWidget {
  const TwelveMonthsRoadmapView({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Mountain Background Image on Top-Right (Matching design)
        Positioned(
          top: -10,
          right: -10,
          width: 240,
          height: 330,
          child: IgnorePointer(
            child: Image.asset(
              'assets/images/journey_mountain_bg.png',
              fit: BoxFit.contain,
              alignment: Alignment.topRight,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        ),

        // Scrollable Content
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header
              _buildHeader(),
              const SizedBox(height: 14),

              // 2. Vertical Timeline with 5 Milestone Cards
              _buildMilestoneTimeline(),
              const SizedBox(height: 18),

              // 3. Bottom 3 Summary Feature Pillars
              _buildSummaryPillars(),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 1. HEADER (TAG + HEADLINE + SUBTITLE)
  // ==========================================
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tag: YOUR 12 MONTH JOURNEY
        const Text(
          'YOUR 12 MONTH JOURNEY',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 4),

        // Headline
        const Text(
          'Twelve months,',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 27,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
            height: 1.15,
            letterSpacing: -0.8,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'one step at a time.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 27,
                fontWeight: FontWeight.w900,
                color: Color(0xFF2563EB),
                height: 1.15,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(width: 4),
            Transform.translate(
              offset: const Offset(0, -5),
              child: const BlueAccentRays(size: 22),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Subtitle
        SizedBox(
          width: 235,
          child: const Text(
            'A clear, guided path to help you think and speak more confidently in real life.',
            style: TextStyle(
              fontFamily: 'Inter',
              color: Color(0xFF64748B),
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 2. VERTICAL TIMELINE WITH 5 CARDS
  // ==========================================
  Widget _buildMilestoneTimeline() {
    final items = [
      _MilestoneData(
        step: 1,
        tag: 'MONTH 1–2',
        title: 'Build the habit.',
        subtitle: 'Practise little and often.',
        icon: _buildTargetIcon(),
      ),
      _MilestoneData(
        step: 2,
        tag: 'MONTH 3–4',
        title: 'Add structure.',
        subtitle: 'Organise your thoughts more clearly.',
        icon: _buildListIcon(),
      ),
      _MilestoneData(
        step: 3,
        tag: 'MONTH 5–8',
        title: 'Speak with clarity.',
        subtitle: 'Say more with less and make your point.',
        icon: _buildSpeechIcon(),
      ),
      _MilestoneData(
        step: 4,
        tag: 'MONTH 9–10',
        title: 'Handle pressure.',
        subtitle: 'Respond confidently in the moment.',
        icon: _buildLightningIcon(),
      ),
      _MilestoneData(
        step: 5,
        tag: 'MONTH 11–12',
        title: 'Find your own style.',
        subtitle: 'Communicate naturally and confidently.',
        icon: _buildBarChartIcon(),
      ),
    ];

    return Column(
      children: [
        for (int i = 0; i < items.length; i++)
          _buildTimelineRow(
            data: items[i],
            isLast: i == items.length - 1,
          ),
      ],
    );
  }

  Widget _buildTimelineRow({
    required _MilestoneData data,
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline Node & Vertical Connector Line
          SizedBox(
            width: 26,
            child: Column(
              children: [
                // Solid Blue Circle Badge
                Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2563EB),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${data.step}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                // Connecting line to next circle
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: const Color(0xFFE2E8F0),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Milestone Card
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0).withValues(alpha: 0.9),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.035),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Text Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            data.tag,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              color: Color(0xFF2563EB),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            data.title,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              color: Color(0xFF0F172A),
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            data.subtitle,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              color: Color(0xFF64748B),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Right Icon
                    data.icon,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 3. ICONS MATCHING DESIGN
  // ==========================================
  Widget _buildTargetIcon() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.adjust_rounded,
        color: Color(0xFF2563EB),
        size: 24,
      ),
    );
  }

  Widget _buildListIcon() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.format_list_bulleted_rounded,
        color: Color(0xFF2563EB),
        size: 24,
      ),
    );
  }

  Widget _buildSpeechIcon() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFFAF5FF),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.chat_bubble_outline_rounded,
        color: Color(0xFF8B5CF6),
        size: 22,
      ),
    );
  }

  Widget _buildLightningIcon() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.bolt_rounded,
        color: Color(0xFFF97316),
        size: 24,
      ),
    );
  }

  Widget _buildBarChartIcon() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.bar_chart_rounded,
        color: Color(0xFF10B981),
        size: 24,
      ),
    );
  }

  // ==========================================
  // 4. BOTTOM 3 SUMMARY PILLARS
  // ==========================================
  Widget _buildSummaryPillars() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pillar 1: Calendar
          Expanded(
            child: _buildPillarItem(
              icon: Icons.calendar_today_rounded,
              label: 'Short, focused\nexercises',
            ),
          ),
          // Vertical Divider
          Container(
            width: 1,
            height: 38,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            color: const Color(0xFFE2E8F0),
          ),
          // Pillar 2: Track progress
          Expanded(
            child: _buildPillarItem(
              icon: Icons.bar_chart_rounded,
              label: 'Track your\nprogress',
            ),
          ),
          // Vertical Divider
          Container(
            width: 1,
            height: 38,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            color: const Color(0xFFE2E8F0),
          ),
          // Pillar 3: Real confidence
          Expanded(
            child: _buildPillarItem(
              icon: Icons.emoji_events_outlined,
              label: 'Real confidence\nin real life',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillarItem({
    required IconData icon,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: const Color(0xFF2563EB),
            size: 19,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Inter',
            color: Color(0xFF334155),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            height: 1.25,
          ),
        ),
      ],
    );
  }
}

class _MilestoneData {
  final int step;
  final String tag;
  final String title;
  final String subtitle;
  final Widget icon;

  _MilestoneData({
    required this.step,
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}
