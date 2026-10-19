import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/services/hakkiri_api_service.dart';
import '../providers/app_state_provider.dart';
import '../widgets/action_pill_button.dart';
import '../widgets/hakkiri_loading_overlay.dart';

enum ProfileSectionFocus { goals, practiceContext, dailyPractice }

/// Focused editors for Profile → Your goals / Practice context / Daily practice.
/// Matches the onboarding assessment screen design language.
class ProfileSectionScreen extends StatefulWidget {
  const ProfileSectionScreen({super.key, required this.focus});

  final ProfileSectionFocus focus;

  @override
  State<ProfileSectionScreen> createState() => _ProfileSectionScreenState();
}

class _ProfileSectionScreenState extends State<ProfileSectionScreen> {
  late final PageController _pageController;
  int _activeCategoryIndex = 0;

  late String _voice;
  late String _careerStage;
  late String _careerType;
  late String _confidence;
  late String _roadblock;
  late String _goal;
  late String _name;
  late int _dailyMinutes;
  bool _saving = false;

  bool get _isGoals => widget.focus == ProfileSectionFocus.goals;
  bool get _isContext => widget.focus == ProfileSectionFocus.practiceContext;
  bool get _isDaily => widget.focus == ProfileSectionFocus.dailyPractice;

  String get _title {
    if (_isGoals) return 'Your goals';
    if (_isContext) return 'Practice context';
    return 'Daily practice';
  }

  String get _subtitle {
    if (_isGoals) return 'What you want Hakkiri to help you improve.';
    if (_isContext) {
      return 'Where and how you practise — used to pick better drills.';
    }
    return 'Choose your daily practice length. Hakkiri uses this for your Today plan (5, 10, or 15 minutes).';
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    final state = context.read<AppStateProvider>();
    _name = state.fullName;
    _voice = state.answers.voiceProfile ?? 'female';
    _careerStage = state.answers.careerStage ?? 'mid_level';
    _careerType = state.answers.careerType ?? 'tech_product';
    _confidence = state.answers.confidence ?? 'fairly';
    _roadblock = state.answers.roadblock ?? 'filler_rush';
    _goal = state.answers.primaryGoal ?? 'calmer_confident';
    final current = state.dailyAnchorMinutes;
    _dailyMinutes = [5, 10, 15].contains(current) ? current : 5;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await HakkiriLoadingOverlay.run(
        context,
        message: 'Saving…',
        detail: _isDaily
            ? 'Updating your daily practice length.'
            : _isGoals
                ? 'Updating your goals.'
                : 'Updating your practice context.',
        action: () async {
          if (_isDaily) {
            await context
                .read<AppStateProvider>()
                .updateDailyAnchorMinutes(_dailyMinutes);
          } else {
            await context.read<AppStateProvider>().updateProfileFromApi(
                  name: _name.trim().isEmpty ? 'Member' : _name.trim(),
                  voiceProfile: _voice,
                  careerStage: _careerStage,
                  careerType: _careerType,
                  confidence: _mapConfidenceForApi(_confidence),
                  roadblock: _roadblock,
                  goal: _goal,
                );
          }
        },
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isDaily
                ? 'Daily practice set to $_dailyMinutes minutes.'
                : _isGoals
                    ? 'Goals updated.'
                    : 'Practice context updated.',
          ),
        ),
      );
    } on HakkiriApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save. Check your connection.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _mapConfidenceForApi(String id) {
    switch (id) {
      case 'not_at_all':
      case 'slightly':
        return 'not_very';
      case 'confident':
      case 'very':
        return 'very';
      case 'fairly':
      default:
        return 'fairly';
    }
  }

  void _onCategoryTabTapped(int index) {
    setState(() => _activeCategoryIndex = index);
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final contextTabs = ['Work environment', 'Career stage', 'Confidence'];
    final goalsTabs = ['Main goal', 'Biggest challenge'];
    final activeTabs = _isContext ? contextTabs : goalsTabs;

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBF9),
      body: SafeArea(
        child: Column(
          children: [
            // Header Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.chevron_left_rounded, size: 28),
                  ),
                  Expanded(
                    child: Text(
                      _title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            if (_isGoals) ...[
              const SizedBox(height: 6),
              _buildCategoryTabs(
                titles: activeTabs,
                activeIndex: _activeCategoryIndex,
                onSelect: _onCategoryTabTapped,
              ),
              const SizedBox(height: 8),
            ],

            // Content
            Expanded(
              child: _isDaily
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _subtitle,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 18),
                          _buildDailyOptions(),
                        ],
                      ),
                    )
                  : _isContext
                      ? _buildWorkEnvironmentPage()
                      : PageView(
                          controller: _pageController,
                          physics: const BouncingScrollPhysics(),
                          onPageChanged: (idx) {
                            setState(() => _activeCategoryIndex = idx);
                          },
                          children: [
                            _buildGoalPage(),
                            _buildRoadblockPage(),
                          ],
                        ),
            ),

            // Bottom Save Button
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
              child: ActionPillButton(
                label: _saving ? 'Saving…' : 'Save changes',
                onTap: _saving ? null : _save,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTabs({
    required List<String> titles,
    required int activeIndex,
    required ValueChanged<int> onSelect,
  }) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: titles.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isActive = index == activeIndex;
          return GestureDetector(
            onTap: () => onSelect(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF141522) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive
                      ? const Color(0xFF141522)
                      : const Color(0xFFEAE9E2),
                  width: 1.2,
                ),
                boxShadow: [
                  if (isActive)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Center(
                child: Text(
                  titles[index],
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                    color: isActive ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- PRACTICE CONTEXT PAGES (Onboarding Style) ---

  Widget _buildWorkEnvironmentPage() {
    return _buildQuestionPage(
      titleBlack: "What's your main\n",
      titleBlue: 'work environment?',
      subtitle: 'Choose the option that best matches your day-to-day.',
      currentSelectedId: _careerType,
      options: const [
        {
          'id': 'corporate_finance',
          'icon': Icons.apartment_rounded,
          'title': 'Corporate & Finance',
          'subtitle': 'Meetings, data reviews and formal presentations',
        },
        {
          'id': 'tech_product',
          'icon': Icons.laptop_chromebook_rounded,
          'title': 'Tech, Engineering & Product',
          'subtitle': 'Explaining complex ideas simply',
        },
        {
          'id': 'sales_marketing',
          'icon': Icons.campaign_outlined,
          'title': 'Sales, Marketing & Content',
          'subtitle': 'Persuasion, negotiation and audience engagement',
        },
        {
          'id': 'healthcare_edu',
          'icon': Icons.health_and_safety_outlined,
          'title': 'Healthcare & Education',
          'subtitle': 'Clear, empathetic communication',
        },
        {
          'id': 'other',
          'icon': Icons.more_horiz_rounded,
          'title': 'Other',
          'subtitle': 'Something else',
        },
      ],
      onSelected: (id) => setState(() => _careerType = id),
    );
  }

  // --- GOALS PAGES (Onboarding Style) ---

  Widget _buildGoalPage() {
    return _buildQuestionPage(
      titleBlack: "What's your\n",
      titleBlue: 'main goal?',
      subtitle: 'What would you most like Hakkiri to help you improve?',
      currentSelectedId: _goal,
      options: const [
        {
          'id': 'authority',
          'icon': Icons.signal_cellular_alt_rounded,
          'title': 'Speak with more authority and executive presence',
          'subtitle': 'Command respect and lead discussions',
        },
        {
          'id': 'calmer_confident',
          'icon': Icons.spa_outlined,
          'title': 'Feel calmer and more confident speaking under pressure',
          'subtitle': 'Stay grounded in high-stakes moments',
        },
        {
          'id': 'persuasive_arguments',
          'icon': Icons.chat_bubble_outline_rounded,
          'title': 'Build clear, persuasive arguments on the spot',
          'subtitle': 'Structure thoughts fast without freezing',
        },
        {
          'id': 'clear_daily',
          'icon': Icons.mic_none_rounded,
          'title': 'Speak more clearly and confidently every day',
          'subtitle': 'Everyday clarity in meetings and casual chats',
        },
        {
          'id': 'keep_engaged',
          'icon': Icons.groups_2_outlined,
          'title': 'Keep people engaged and make an impact',
          'subtitle': 'Hold attention and make your message stick',
        },
        {
          'id': 'other',
          'icon': Icons.gps_fixed_rounded,
          'title': 'Other',
          'subtitle': 'Personal communication goals',
        },
      ],
      onSelected: (id) => setState(() => _goal = id),
    );
  }

  Widget _buildRoadblockPage() {
    return _buildQuestionPage(
      titleBlack: 'What gets in your way\n',
      titleBlue: 'most when you speak?',
      subtitle: 'Pick your biggest challenge. You can work on the others later.',
      currentSelectedId: _roadblock,
      options: const [
        {
          'id': 'blank_pressure',
          'icon': Icons.psychology_outlined,
          'title': 'I go blank under pressure',
          'subtitle': 'I struggle to organise my thoughts quickly',
        },
        {
          'id': 'too_long',
          'icon': Icons.access_time_rounded,
          'title': 'I take too long to get to the point',
          'subtitle': 'I over-explain before getting to my message',
        },
        {
          'id': 'filler_rush',
          'icon': Icons.graphic_eq_rounded,
          'title': 'I rush or use too many filler words',
          'subtitle': "I use words like 'um' or 'so' while thinking",
        },
        {
          'id': 'explain_simple',
          'icon': Icons.description_outlined,
          'title': 'I struggle to explain things simply',
          'subtitle': 'I know what I mean, but make it sound complicated',
        },
        {
          'id': 'keep_engaged',
          'icon': Icons.groups_outlined,
          'title': 'I struggle to keep people engaged',
          'subtitle': "My message doesn't always land or stick",
        },
        {
          'id': 'lose_confidence',
          'icon': Icons.shield_outlined,
          'title': 'I lose confidence when challenged',
          'subtitle': 'I struggle to respond clearly when someone disagrees',
        },
      ],
      onSelected: (id) => setState(() => _roadblock = id),
    );
  }

  // --- GENERIC QUESTION PAGE BUILDER ---

  Widget _buildQuestionPage({
    required String titleBlack,
    required String titleBlue,
    required String subtitle,
    required List<Map<String, dynamic>> options,
    required String currentSelectedId,
    required ValueChanged<String> onSelected,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                height: 1.18,
                letterSpacing: -0.8,
              ),
              children: [
                TextSpan(text: titleBlack),
                TextSpan(
                  text: titleBlue,
                  style: const TextStyle(color: AppColors.royalBlue),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textSecondary,
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          ...options.map((opt) {
            final id = opt['id'] as String;
            final isSelected = id == currentSelectedId ||
                (id == 'not_very' && currentSelectedId == 'not_at_all') ||
                (id == 'not_at_all' && currentSelectedId == 'not_very');

            return Padding(
              padding: const EdgeInsets.only(bottom: 11),
              child: _buildOptionCard(
                id: id,
                title: opt['title'] as String,
                subtitle: (opt['subtitle'] as String?) ?? '',
                icon: opt['icon'] as IconData?,
                isSelected: isSelected,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onSelected(id);
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required String id,
    required String title,
    required String subtitle,
    IconData? icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final hasSubtitle = subtitle.trim().isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: hasSubtitle ? 14 : 16,
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF141522) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.transparent : const Color(0xFFEAE9E2),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isSelected ? 0.08 : 0.02),
              blurRadius: isSelected ? 12 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            if (icon != null)
              Container(
                width: 42,
                height: 42,
                margin: const EdgeInsets.only(right: 14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF222438)
                      : const Color(0xFFF3F4F6),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  size: 20,
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                  if (hasSubtitle) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: isSelected
                            ? const Color(0xFFA0A5B5)
                            : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.royalBlue : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? AppColors.royalBlue
                      : const Color(0xFFD1D5DB),
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyOptions() {
    final options = [
      {
        'minutes': 5,
        'title': '5 minutes',
        'sub1': 'Quick practice',
        'sub2': '3 focused exercises',
        'icon': Icons.speed_rounded,
        'iconBg': const Color(0xFFDCFCE7),
        'iconColor': const Color(0xFF16A34A),
      },
      {
        'minutes': 10,
        'title': '10 minutes',
        'sub1': 'Balanced practice',
        'sub2': '3+ exercises with targeted retries',
        'icon': Icons.timer_outlined,
        'iconBg': const Color(0xFFEFF6FF),
        'iconColor': const Color(0xFF2563EB),
      },
      {
        'minutes': 15,
        'title': '15 minutes',
        'sub1': 'Deeper practice',
        'sub2': 'More exercises, retries and\ntougher challenges',
        'icon': Icons.auto_graph_rounded,
        'iconBg': const Color(0xFFFFEDE8),
        'iconColor': const Color(0xFFF95B3D),
      },
    ];

    return Column(
      children: options.map((opt) {
        final minutes = opt['minutes'] as int;
        final selected = minutes == _dailyMinutes;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () => setState(() => _dailyMinutes = minutes),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFF8FAFF) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                  width: selected ? 1.8 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: selected
                        ? const Color(0xFF2563EB).withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.02),
                    blurRadius: selected ? 8 : 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: opt['iconBg'] as Color,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      opt['icon'] as IconData,
                      color: opt['iconColor'] as Color,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          opt['title'] as String,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          opt['sub1'] as String,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF334155),
                          ),
                        ),
                        Text(
                          opt['sub2'] as String,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (selected)
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2563EB),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    )
                  else
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFCBD5E1),
                          width: 2.0,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
