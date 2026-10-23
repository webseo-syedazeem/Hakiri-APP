import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/services/analytics_service.dart';
import '../models/session_model.dart';
import '../providers/app_state_provider.dart';
import 'feedback_screen.dart';

class AllSessionsScreen extends StatefulWidget {
  final int initialFilterIndex;

  const AllSessionsScreen({
    super.key,
    this.initialFilterIndex = 0, // 0: 7 days, 1: 30 days, 2: 3 months, 3: All
  });

  @override
  State<AllSessionsScreen> createState() => _AllSessionsScreenState();
}

class _AllSessionsScreenState extends State<AllSessionsScreen> {
  late int _selectedFilter;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilterIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService.instance.logScreenView(screenName: 'AllSessionsScreen');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<PracticeSessionRecord> _filterSessions(List<PracticeSessionRecord> allSessions) {
    final now = DateTime.now();
    List<PracticeSessionRecord> result;

    switch (_selectedFilter) {
      case 0: // 7 days
        final cutoff = now.subtract(const Duration(days: 7));
        result = allSessions.where((s) => s.timestamp.isAfter(cutoff)).toList();
        break;
      case 1: // 30 days
        final cutoff = now.subtract(const Duration(days: 30));
        result = allSessions.where((s) => s.timestamp.isAfter(cutoff)).toList();
        break;
      case 2: // 3 months
        final cutoff = now.subtract(const Duration(days: 90));
        result = allSessions.where((s) => s.timestamp.isAfter(cutoff)).toList();
        break;
      case 3: // All
      default:
        result = List.from(allSessions);
        break;
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      result = result.where((s) {
        final activity = s.activityName.toLowerCase();
        final prompt = s.promptTitle.toLowerCase();
        return activity.contains(q) || prompt.contains(q);
      }).toList();
    }

    // Sort newest first
    result.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return result;
  }

  String _formatSessionDay(DateTime stamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(stamp.year, stamp.month, stamp.day);
    if (day == today) {
      return 'Today, ${stamp.hour.toString().padLeft(2, '0')}:${stamp.minute.toString().padLeft(2, '0')}';
    }
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${stamp.day} ${names[(stamp.month - 1).clamp(0, 11)]} ${stamp.year}';
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final allSessions = state.sessionHistory;
    final filteredSessions = _filterSessions(allSessions);

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBF9),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Icon(
                        Icons.chevron_left_rounded,
                        color: Color(0xFF0F172A),
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Practice Sessions',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          '${allSessions.length} total completed',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.royalBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.royalBlue.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      '${filteredSessions.length} showing',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.royalBlue,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search sessions by drill name...',
                    hintStyle: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: Color(0xFF94A3B8),
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF94A3B8),
                      size: 20,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                            child: const Icon(
                              Icons.close_rounded,
                              color: Color(0xFF94A3B8),
                              size: 18,
                            ),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),

            // Filter Tabs (7 days, 30 days, 3 months, All)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  _buildFilterTab(0, '7 Days'),
                  const SizedBox(width: 8),
                  _buildFilterTab(1, '30 Days'),
                  const SizedBox(width: 8),
                  _buildFilterTab(2, '3 Months'),
                  const SizedBox(width: 8),
                  _buildFilterTab(3, 'All Time'),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // Sessions List
            Expanded(
              child: filteredSessions.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      color: AppColors.royalBlue,
                      onRefresh: () async {
                        await state.refreshFromApi();
                      },
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        itemCount: filteredSessions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final session = filteredSessions[index];
                          return _buildSessionCard(context, session);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(int index, String label) {
    final isSelected = _selectedFilter == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
            width: 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            color: isSelected ? Colors.white : const Color(0xFF64748B),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSessionCard(BuildContext context, PracticeSessionRecord session) {
    final score = session.feedback.overallScore;
    final minutes = (session.durationSeconds / 60).ceil().clamp(1, 99);
    final ringColor = score >= 4
        ? const Color(0xFF10B981)
        : score >= 3
            ? const Color(0xFF3B82F6)
            : const Color(0xFFF59E0B);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => FeedbackScreen(
                session: session,
                fromHistory: true,
              ),
            ),
          );
          if (result == true && mounted) {
            setState(() {});
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
          ),
          child: Row(
            children: [
              // Circular Score Avatar
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 38,
                      height: 38,
                      child: CustomPaint(
                        painter: _SessionScoreRingPainter(
                          scoreFraction: (score / 5.0).clamp(0.0, 1.0),
                          trackColor: Colors.white.withValues(alpha: 0.15),
                          activeColor: ringColor,
                          strokeWidth: 3.2,
                        ),
                      ),
                    ),
                    Text(
                      '$score/5',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Title and details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.activityName,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF0F172A),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_formatSessionDay(session.timestamp)} · 🕒 $minutes min',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF64748B),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (session.promptTitle.isNotEmpty &&
                        session.promptTitle != session.activityName) ...[
                      const SizedBox(height: 2),
                      Text(
                        session.promptTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: Color(0xFF94A3B8),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Feedback pill + chevron (row tap opens feedback)
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
                        color: Color(0xFF93C5FD),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: Color(0xFF94A3B8),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history_toggle_off_rounded,
                size: 32,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'No sessions found',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Complete a practice drill or adjust your search filter to see sessions here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionScoreRingPainter extends CustomPainter {
  final double scoreFraction;
  final Color trackColor;
  final Color activeColor;
  final double strokeWidth;

  const _SessionScoreRingPainter({
    required this.scoreFraction,
    required this.trackColor,
    required this.activeColor,
    this.strokeWidth = 3.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - (strokeWidth / 2);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * scoreFraction.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SessionScoreRingPainter oldDelegate) =>
      oldDelegate.scoreFraction != scoreFraction ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.activeColor != activeColor ||
      oldDelegate.strokeWidth != strokeWidth;
}
