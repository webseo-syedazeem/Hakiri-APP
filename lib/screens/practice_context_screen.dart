import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/services/hakkiri_api_service.dart';
import '../providers/app_state_provider.dart';
import '../widgets/action_pill_button.dart';
import '../widgets/hakkiri_loading_overlay.dart';

/// Dedicated screen for Settings/Profile → Practice context.
/// Shows exclusively the Work Environment options in onboarding-card style,
/// without tabs, sliders, or step numbers.
class PracticeContextScreen extends StatefulWidget {
  const PracticeContextScreen({super.key});

  @override
  State<PracticeContextScreen> createState() => _PracticeContextScreenState();
}

class _PracticeContextScreenState extends State<PracticeContextScreen> {
  late String _careerType;
  bool _saving = false;

  static const _workOptions = [
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
  ];

  @override
  void initState() {
    super.initState();
    final state = context.read<AppStateProvider>();
    _careerType = state.answers.careerType ?? 'tech_product';
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final state = context.read<AppStateProvider>();
    try {
      await HakkiriLoadingOverlay.run(
        context,
        message: 'Saving…',
        detail: 'Updating your practice context.',
        action: () async {
          await state.updateProfileFromApi(
            name: state.fullName.trim().isEmpty ? 'Member' : state.fullName.trim(),
            voiceProfile: state.answers.voiceProfile ?? 'female',
            careerStage: state.answers.careerStage ?? 'mid_level',
            careerType: _careerType,
            confidence: state.answers.confidence ?? 'fairly',
            roadblock: state.answers.roadblock ?? 'filler_rush',
            goal: state.answers.primaryGoal ?? 'calmer_confident',
          );
        },
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Practice context updated.'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBF9),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.chevron_left_rounded, size: 28),
                  ),
                  const Expanded(
                    child: Text(
                      'Practice context',
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

            // Content List
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main Title
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          height: 1.15,
                          letterSpacing: -0.8,
                        ),
                        children: [
                          TextSpan(text: "What's your main\n"),
                          TextSpan(
                            text: 'work environment?',
                            style: TextStyle(color: AppColors.royalBlue),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtitle
                    const Text(
                      'Choose the option that best matches your day-to-day.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Work Environment Option Cards
                    ..._workOptions.map((opt) {
                      final id = opt['id'] as String;
                      final isSelected = id == _careerType;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildOptionCard(
                          title: opt['title'] as String,
                          subtitle: opt['subtitle'] as String,
                          icon: opt['icon'] as IconData,
                          isSelected: isSelected,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _careerType = id);
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Bottom Save Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
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

  Widget _buildOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
}
