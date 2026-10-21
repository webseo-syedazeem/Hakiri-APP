import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/services/hakkiri_api_service.dart';
import '../providers/app_state_provider.dart';
import '../widgets/action_pill_button.dart';
import '../widgets/hakkiri_loading_overlay.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController;
  late String _voice;
  late String _careerStage;
  late String _careerType;
  late String _confidence;
  late String _roadblock;
  late String _goal;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppStateProvider>();
    _nameController = TextEditingController(text: state.fullName);
    _voice = state.answers.voiceProfile ?? 'female';
    _careerStage = state.answers.careerStage ?? 'mid_level';
    _careerType = state.answers.careerType ?? 'tech_product';
    _confidence = state.answers.confidence ?? 'fairly';
    _roadblock = state.answers.roadblock ?? 'filler_rush';
    _goal = state.answers.primaryGoal ?? 'calmer_confident';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final name = _nameController.text.trim();
    if (name.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your full name.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await HakkiriLoadingOverlay.run(
        context,
        message: 'Saving your profile…',
        detail: 'Updating your assessment details.',
        action: () => context.read<AppStateProvider>().updateProfileFromApi(
              name: name,
              voiceProfile: _voice,
              careerStage: _careerStage,
              careerType: _careerType,
              confidence: _confidence,
              roadblock: _roadblock,
              goal: _goal,
            ),
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated.')),
      );
    } on HakkiriApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save profile. Check your connection.')),
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
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: AppColors.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded, color: AppColors.royalBlue)
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
    final state = context.watch<AppStateProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBF9),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.chevron_left_rounded, size: 28),
                  ),
                  const Expanded(
                    child: Text(
                      'Your profile',
                      textAlign: TextAlign.center,
                      style: TextStyle(
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
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          color: Color(0xFFDBEAFE),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          state.initials,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: AppColors.royalBlue,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'ACCOUNT',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _fieldCard(
                      label: 'Full name',
                      child: TextField(
                        controller: _nameController,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _infoRow('Email', state.email.isEmpty ? 'Not available' : state.email),
                    const SizedBox(height: 22),
                    const Text(
                      'ASSESSMENT DETAILS',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _selectableRow(
                      title: 'Career stage',
                      value: AppStateProvider.careerStageLabels[_careerStage] ?? _careerStage,
                      onTap: () => _pickOption(
                        title: 'Career stage',
                        options: AppStateProvider.careerStageLabels,
                        current: _careerStage,
                        onPicked: (v) => setState(() => _careerStage = v),
                      ),
                    ),
                    _selectableRow(
                      title: 'Work environment',
                      value: AppStateProvider.careerLabels[_careerType] ?? _careerType,
                      onTap: () => _pickOption(
                        title: 'Work environment',
                        options: AppStateProvider.careerLabels,
                        current: _careerType,
                        onPicked: (v) => setState(() => _careerType = v),
                      ),
                    ),
                    _selectableRow(
                      title: 'Speaking confidence',
                      value: AppStateProvider.confidenceLabels[_confidence] ?? _confidence,
                      onTap: () => _pickOption(
                        title: 'Speaking confidence',
                        options: AppStateProvider.confidenceLabels,
                        current: _confidence,
                        onPicked: (v) => setState(() => _confidence = v),
                      ),
                    ),
                    _selectableRow(
                      title: 'Biggest challenge',
                      value: AppStateProvider.roadblockLabels[_roadblock] ?? _roadblock,
                      onTap: () => _pickOption(
                        title: 'Biggest challenge',
                        options: AppStateProvider.roadblockLabels,
                        current: _roadblock,
                        onPicked: (v) => setState(() => _roadblock = v),
                      ),
                    ),
                    _selectableRow(
                      title: 'Main goal',
                      value: AppStateProvider.goalLabels[_goal] ?? _goal,
                      onTap: () => _pickOption(
                        title: 'Main goal',
                        options: AppStateProvider.goalLabels,
                        current: _goal,
                        onPicked: (v) => setState(() => _goal = v),
                      ),
                      showDivider: false,
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

  Widget _fieldCard({required String label, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
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
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
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
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(showDivider ? 0 : 16),
          child: InkWell(
            onTap: onTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.surfaceBorder),
                borderRadius: showDivider
                    ? null
                    : const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
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
                  const Icon(Icons.edit_outlined, size: 18, color: AppColors.textMuted),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          const Divider(height: 1, color: AppColors.surfaceBorderLight),
      ],
    );
  }
}
