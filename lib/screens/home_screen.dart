import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../models/session_model.dart';
import '../providers/app_state_provider.dart';
import '../widgets/empty_history_widget.dart';
import '../widgets/hakkiri_logo.dart';
import '../widgets/week_calendar_strip.dart';
import 'activity_detail_screen.dart';
import 'feedback_screen.dart';
import 'main_tab_scaffold.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainTabScaffold(initialIndex: 0);
  }
}

class HomeScreenContent extends StatefulWidget {
  const HomeScreenContent({super.key});

  @override
  State<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent> {
  int _selectedDayIndex = 3; // THU 4 as in Page 5

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const HakkiriLogo(
                  variant: HakkiriLogoVariant.compactMark,
                  size: 20,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.surfaceBorder, width: 1.0),
                  ),
                  child: const Text(
                    'DAY  4  STREAK',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Subtag
            const Text(
              'DAILY ANCHOR  ·  MONDAY',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 6),

            // Heading
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textPrimary,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.0,
                  height: 1.15,
                ),
                children: [
                  TextSpan(text: 'Five minutes.\n'),
                  TextSpan(
                    text: 'Then go speak.',
                    style: TextStyle(color: AppColors.royalBlue),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Calendar Row
            WeekCalendarStrip(
              selectedDayIndex: _selectedDayIndex,
              onDaySelected: (idx) => setState(() => _selectedDayIndex = idx),
            ),
            const SizedBox(height: 20),

            // Featured Anchor Card (Dark Navy Card)
            GestureDetector(
              onTap: () {
                state.selectActivity('think_fast');
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ActivityDetailScreen()),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF141522),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'TODAY  ·  BEGINNER  ·  SALES',
                            style: TextStyle(
                              color: Color(0xFFA3A6B8),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Think First',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Answer a surprise client question.',
                            style: TextStyle(
                              color: Color(0xFF8E91A6),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.royalBlue,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Secondary Activities
            _buildSecondaryActivityRow('02', 'Cut it in Half', '~2 min', () {
              state.selectActivity('cut_it_in_half');
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ActivityDetailScreen()),
              );
            }),
            const SizedBox(height: 14),
            _buildSecondaryActivityRow('03', 'Debate Me', '60 sec', () {
              state.selectActivity('debate_me');
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ActivityDetailScreen()),
              );
            }),

            const SizedBox(height: 24),

            // DRILL & DEBATE HISTORY SECTION
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'DEBATE & DRILL HISTORY',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                if (state.sessionHistory.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.royalBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${state.sessionHistory.length} COMPLETED',
                      style: const TextStyle(
                        color: AppColors.royalBlue,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Show Empty State SVG / Vector or History List
            if (state.sessionHistory.isEmpty)
              EmptyHistoryWidget(
                title: 'No Debate History Yet',
                subtitle:
                    'You haven\'t completed any debate or speaking drills yet. Challenge your agility under fire to start building your history.',
                buttonText: 'Start Debate Drill',
                onButtonPressed: () {
                  state.selectActivity('debate_me');
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ActivityDetailScreen()),
                  );
                },
              )
            else
              Column(
                children: state.sessionHistory
                    .map((item) => _buildHistoryCard(context, state, item))
                    .toList(),
              ),

            const SizedBox(height: 24),

            // YOUR FOCUS Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.surfaceBorder, width: 1.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'YOUR FOCUS',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Go blank less, land the point sooner.',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(
      BuildContext context, AppStateProvider state, PracticeSessionRecord item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141522),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.activityName.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${item.durationSeconds}s drill',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.royalBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, color: AppColors.royalBlue, size: 14),
                    const SizedBox(width: 3),
                    Text(
                      '${item.feedback.overallScore}/5',
                      style: const TextStyle(
                        color: AppColors.royalBlue,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.promptTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatTimeAgo(item.timestamp),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: () {
                  state.latestFeedback = item.feedback;
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FeedbackScreen()),
                  );
                },
                child: Row(
                  children: const [
                    Text(
                      'View Review',
                      style: TextStyle(
                        color: AppColors.royalBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.royalBlue,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Widget _buildSecondaryActivityRow(String num, String title, String time, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 26,
              child: Text(
                num,
                style: const TextStyle(
                  color: AppColors.royalBlue,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              time,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
