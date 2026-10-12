import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/services/hakkiri_api_service.dart';
import '../providers/app_state_provider.dart';
import '../widgets/action_pill_button.dart';
import '../widgets/hakkiri_loading_overlay.dart';

enum ProfileSectionFocus { goals, practiceContext, dailyPractice }

/// Focused editors for Profile → Your goals / Practice context / Daily practice.
class ProfileSectionScreen extends StatefulWidget {
  const ProfileSectionScreen({super.key, required this.focus});

  final ProfileSectionFocus focus;

  @override
  State<ProfileSectionScreen> createState() => _ProfileSectionScreenState();
}

class _ProfileSectionScreenState extends State<ProfileSectionScreen> {
  static const _dailyOptions = <int, String>{
    5: '5 minutes a day',
    10: '10 minutes a day',
    15: '15 minutes a day',
  };

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
                  confidence: _confidence,
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save. Check your connection.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickOption({
    required String title,
    required Map<String, String> options,
    required String current,
    required ValueChanged<String> onPicked,
  }) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: options.entries.map((entry) {
                      final isSelected = entry.key == current;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          entry.value,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight:
                                isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: AppColors.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.royalBlue,
                              )
                            : null,
                        onTap: () => Navigator.pop(ctx, entry.key),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (selected != null) onPicked(selected);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBF9),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
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
                    if (_isDaily)
                      _buildDailyOptions()
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.surfaceBorder),
                        ),
                        child: Column(
                          children: _isGoals
                              ? [
                                  _selectableRow(
                                    title: 'Main goal',
                                    value:
                                        AppStateProvider.goalLabels[_goal] ??
                                            _goal,
                                    onTap: () => _pickOption(
                                      title: 'Main goal',
                                      options: AppStateProvider.goalLabels,
                                      current: _goal,
                                      onPicked: (v) =>
                                          setState(() => _goal = v),
                                    ),
                                  ),
                                  _selectableRow(
                                    title: 'Biggest challenge',
                                    value: AppStateProvider
                                            .roadblockLabels[_roadblock] ??
                                        _roadblock,
                                    onTap: () => _pickOption(
                                      title: 'Biggest challenge',
                                      options:
                                          AppStateProvider.roadblockLabels,
                                      current: _roadblock,
                                      onPicked: (v) =>
                                          setState(() => _roadblock = v),
                                    ),
                                    showDivider: false,
                                  ),
                                ]
                              : [
                                  _selectableRow(
                                    title: 'Work environment',
                                    value: AppStateProvider
                                            .careerLabels[_careerType] ??
                                        _careerType,
                                    onTap: () => _pickOption(
                                      title: 'Work environment',
                                      options: AppStateProvider.careerLabels,
                                      current: _careerType,
                                      onPicked: (v) =>
                                          setState(() => _careerType = v),
                                    ),
                                  ),
                                  _selectableRow(
                                    title: 'Career stage',
                                    value: AppStateProvider
                                            .careerStageLabels[_careerStage] ??
                                        _careerStage,
                                    onTap: () => _pickOption(
                                      title: 'Career stage',
                                      options:
                                          AppStateProvider.careerStageLabels,
                                      current: _careerStage,
                                      onPicked: (v) =>
                                          setState(() => _careerStage = v),
                                    ),
                                  ),
                                  _selectableRow(
                                    title: 'Speaking confidence',
                                    value: AppStateProvider
                                            .confidenceLabels[_confidence] ??
                                        _confidence,
                                    onTap: () => _pickOption(
                                      title: 'Speaking confidence',
                                      options:
                                          AppStateProvider.confidenceLabels,
                                      current: _confidence,
                                      onPicked: (v) =>
                                          setState(() => _confidence = v),
                                    ),
                                    showDivider: false,
                                  ),
                                ],
                        ),
                      ),
                    const SizedBox(height: 24),
                    ActionPillButton(
                      label: _saving ? 'Saving…' : 'Save changes',
                      onTap: _saving ? null : _save,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyOptions() {
    return Column(
      children: _dailyOptions.entries.map((entry) {
        final selected = entry.key == _dailyMinutes;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => setState(() => _dailyMinutes = entry.key),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected
                        ? AppColors.royalBlue
                        : AppColors.surfaceBorder,
                    width: selected ? 1.6 : 1.0,
                  ),
                  color: selected
                      ? const Color(0xFFEFF6FF)
                      : Colors.white,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      color: selected
                          ? AppColors.royalBlue
                          : AppColors.textMuted,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight:
                              selected ? FontWeight.w800 : FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (selected)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.royalBlue,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _selectableRow({
    required String title,
    required String value,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: AppColors.surfaceBorderLight,
          ),
      ],
    );
  }
}
