import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../models/session_model.dart';
import '../providers/app_state_provider.dart';
import '../widgets/custom_sparkline.dart';
import '../widgets/hakkiri_logo.dart';
import 'activity_detail_screen.dart';
import 'all_sessions_screen.dart';
import 'feedback_screen.dart';
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

    final filterDuration = _selectedFilter == 0
        ? const Duration(days: 7)
        : _selectedFilter == 1
            ? const Duration(days: 30)
            : const Duration(days: 90);
    final filterLabel = _selectedFilter == 0
        ? '7 days'
        : _selectedFilter == 1
            ? '30 days'
            : '3 months';

    final cutoff = DateTime.now().subtract(filterDuration);
    final filteredSessions = state.sessionHistory
        .where((s) => s.timestamp.isAfter(cutoff))
        .toList();

    // Design labels: Clarity / Structure / Engagement / Conciseness
    final claritySkill =
        _periodPillarStat(filteredSessions, state, 'executive_presence');
    final structureSkill =
        _periodPillarStat(filteredSessions, state, 'clarity');
    final engagement =
        _periodPillarStat(filteredSessions, state, 'engagement');
    final impact = _periodPillarStat(filteredSessions, state, 'impact');
    final recentSessions = filteredSessions;
    final totalSessions = recentSessions.length;
    final previewCount = totalSessions.clamp(0, 3);

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const HakkiriLogo(
                  variant: HakkiriLogoVariant.compactMark,
                  size: 22,
                ),
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: AppColors.surfaceBorder, width: 1.0),
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
            const SizedBox(height: 18),

            const Text(
              'Your skills',
              style: TextStyle(
                fontFamily: 'Inter',
                color: AppColors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.6,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'See how you’re progressing across key areas.',
              style: TextStyle(
                fontFamily: 'Inter',
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildSkillCard(
                    icon: Icons.chat_bubble_rounded,
                    iconColor: const Color(0xFF3B82F6),
                    iconBgColor: const Color(0xFFEFF6FF),
                    title: 'Clarity',
                    scoreText: claritySkill.$1,
                    deltaText: claritySkill.$3,
                    isDeltaPositive: claritySkill.$4,
                    description: 'Steadier pace, fewer hesitations.',
                    sparklinePoints: claritySkill.$5,
                    sparklineColor: const Color(0xFF3B82F6),
                    isLocked: claritySkill.$2,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSkillCard(
                    icon: Icons.bar_chart_rounded,
                    iconColor: const Color(0xFF10B981),
                    iconBgColor: const Color(0xFFECFDF5),
                    title: 'Structure',
                    scoreText: structureSkill.$1,
                    deltaText: structureSkill.$3,
                    isDeltaPositive: structureSkill.$4,
                    description: 'Your main points are easier to follow.',
                    sparklinePoints: structureSkill.$5,
                    sparklineColor: const Color(0xFF10B981),
                    isLocked: structureSkill.$2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSkillCard(
                    icon: Icons.groups_rounded,
                    iconColor: const Color(0xFFEC4899),
                    iconBgColor: const Color(0xFFFDF2F8),
                    title: 'Engagement & tone',
                    scoreText: engagement.$1,
                    deltaText: engagement.$3,
                    isDeltaPositive: engagement.$4,
                    description: engagement.$2
                        ? 'Complete more sessions to unlock this score.'
                        : 'Keep people with you.',
                    sparklinePoints: engagement.$5,
                    sparklineColor: const Color(0xFFEC4899),
                    isLocked: engagement.$2,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSkillCard(
                    icon: Icons.content_cut_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    iconBgColor: const Color(0xFFFFFBEB),
                    title: 'Conciseness',
                    scoreText: impact.$1,
                    deltaText: impact.$3,
                    isDeltaPositive: impact.$4,
                    description: 'Get to the point faster.',
                    sparklinePoints: impact.$5,
                    sparklineColor: const Color(0xFFF59E0B),
                    isLocked: impact.$2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Recommended next
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFFEF3C7)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'RECOMMENDED NEXT  ·  ~2 MIN',
                    style: TextStyle(
                      color: Color(0xFFD97706),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.7,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.content_cut_rounded,
                          color: Color(0xFFD97706),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cut It in Half',
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
                                fontSize: 12,
                                height: 1.3,
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
                            MaterialPageRoute(
                              builder: (_) => const ActivityDetailScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.royalBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Start',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_rounded, size: 15),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent practice',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  totalSessions == 0
                      ? 'No sessions yet'
                      : '$previewCount of $totalSessions sessions',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (recentSessions.isEmpty)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: AppColors.surfaceBorder, width: 1.0),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.history_toggle_off_rounded,
                      size: 34,
                      color: AppColors.textMuted.withValues(alpha: 0.6),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No sessions in the last $filterLabel',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Complete a drill to see your progress here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              ...recentSessions.take(3).map((session) {
                final score = session.feedback.overallScore;
                final minutes =
                    (session.durationSeconds / 60).ceil().clamp(1, 99);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildRecentSessionCard(
                    scoreFraction: '$score/5',
                    scoreFractionValue: score / 5,
                    ringColor: score >= 4
                        ? const Color(0xFF10B981)
                        : score >= 3
                            ? const Color(0xFF3B82F6)
                            : const Color(0xFFF59E0B),
                    title: session.activityName,
                    dateDuration:
                        '${_formatSessionDay(session.timestamp)} · $minutes min',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FeedbackScreen(
                            session: session,
                            fromHistory: true,
                          ),
                        ),
                      );
                    },
                  ),
                );
              }),
              if (totalSessions > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AllSessionsScreen(
                              initialFilterIndex: _selectedFilter,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.royalBlue.withValues(alpha: 0.28),
                            width: 1.2,
                          ),
                          color: AppColors.royalBlue.withValues(alpha: 0.04),
                        ),
                        child: Text(
                          'View all $totalSessions practice sessions →',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: AppColors.royalBlue,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],

            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDBEAFE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.bar_chart_rounded,
                      color: Color(0xFF2563EB),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hakkiri grows with you',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Your level is reviewed weekly. Your recommended exercises update every two weeks based on your progress.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12.5,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  /// Calculates dynamic pillar statistics based on the active filtered sessions
  (String, bool, String?, bool?, List<double>) _periodPillarStat(
    List<PracticeSessionRecord> filtered,
    AppStateProvider state,
    String key,
  ) {
    if (filtered.isNotEmpty) {
      final scores = filtered.map((s) {
        switch (key) {
          case 'executive_presence':
            return s.feedback.pillars.executiveScore.toDouble();
          case 'clarity':
            return s.feedback.pillars.clarityScore.toDouble();
          case 'engagement':
            return s.feedback.pillars.engagementScore.toDouble();
          case 'impact':
          default:
            return s.feedback.pillars.impactScore.toDouble();
        }
      }).toList();
      final avg = scores.reduce((a, b) => a + b) / scores.length;
      // Only plot real session scores — never invent a trend.
      final points = scores.reversed.take(6).toList();
      return (
        avg.toStringAsFixed(1),
        false,
        '${scores.length} ${scores.length == 1 ? 'drill' : 'drills'}',
        true,
        points,
      );
    }
    // Fall back to general server or baseline pillar stats
    return _pillarAverage(state, key);
  }

  /// score text, locked, delta text, delta positive?, sparkline
  (String, bool, String?, bool?, List<double>) _pillarAverage(
    AppStateProvider state,
    String key,
  ) {
    final raw = state.pillarStats[key];
    if (raw is! Map) {
      return ('Locked', true, '3 drills needed', null, const <double>[]);
    }
    final map = Map<String, dynamic>.from(raw);
    final average = map['average'];
    final samples = (map['samples'] as num?)?.round() ?? 0;
    final locked = map['status'] == 'need_more' || average == null || samples < 3;
    if (locked) {
      final needed = (3 - samples).clamp(1, 3);
      final msg = '$needed more drill${needed == 1 ? '' : 's'} needed';
      return ('Locked', true, msg, null, const <double>[]);
    }
    final value = (average as num).toDouble();
    // Server average only — no fabricated sparkline deltas.
    return (
      value.toStringAsFixed(1),
      false,
      '$samples samples',
      true,
      <double>[value],
    );
  }

  void _showScoreExplainer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: const [
                  Icon(Icons.insights_rounded, color: AppColors.royalBlue, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'How Scores Work',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Hakkiri evaluates your speaking across a 1.0 to 5.0 scale using 4 foundational communication pillars:',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              _buildScorePrincipleRow(
                icon: Icons.mic_rounded,
                color: const Color(0xFF3B82F6),
                title: 'Fluency & Presence',
                desc: 'Steadier pace, optimal power pauses, and fewer filler words (crutches).',
              ),
              const SizedBox(height: 10),
              _buildScorePrincipleRow(
                icon: Icons.visibility_rounded,
                color: const Color(0xFF10B981),
                title: 'Clarity',
                desc: 'High intelligibility, logical structuring, and clear main takeaways.',
              ),
              const SizedBox(height: 10),
              _buildScorePrincipleRow(
                icon: Icons.auto_awesome_rounded,
                color: const Color(0xFFEF4444),
                title: 'Engagement & Tone',
                desc: 'Dynamic vocal energy, action verbs, and captivating delivery.',
              ),
              const SizedBox(height: 10),
              _buildScorePrincipleRow(
                icon: Icons.content_cut_rounded,
                color: const Color(0xFFF59E0B),
                title: 'Conciseness (Impact)',
                desc: 'High information density — get straight to the point without rambling.',
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.royalBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Got it', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScorePrincipleRow({
    required IconData icon,
    required Color color,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(9),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11.5,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatSessionDay(DateTime stamp) {
    return '${stamp.day} ${_month(stamp.month)} ${stamp.year}';
  }

  String _month(int month) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return names[(month - 1).clamp(0, 11)];
  }

  Widget _buildFilterPill(int index, String label) {
    final isSelected = _selectedFilter == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.royalBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.royalBlue.withValues(alpha: 0.28),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
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
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          if (isLocked)
            Row(
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 14,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    deltaText ?? 'Locked',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  'Level $scoreText',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (deltaText != null) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      deltaText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: isDeltaPositive == true
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
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
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                    child: const Text(
                    'Feedback',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: Color(0xFF3B82F6),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
