import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../core/services/analytics_service.dart';
import '../core/services/coach_tts_service.dart';
import '../providers/app_state_provider.dart';
import '../widgets/hakkiri_logo.dart';
import 'how_hakkiri_works_screen.dart';
import 'main_tab_scaffold.dart';
import 'paywall_screen.dart';
import 'practice_context_screen.dart';
import 'profile_section_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _privacyUrl = 'https://hakkiriapp.vercel.app/privacy';

  Future<void> _openPrivacyLink() async {
    final uri = Uri.parse(_privacyUrl);
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService.instance.logScreenView(screenName: 'SettingsScreen');
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ACCOUNT  ·  PREFERENCES',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
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
                    TextSpan(text: 'Settings\n'),
                    TextSpan(
                      text: 'Tailored for you.',
                      style: TextStyle(color: AppColors.royalBlue),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Membership Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF141522),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.subscriptionTitle,
                          style: const TextStyle(
                            color: Color(0xFF7A89FF),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          state.subscriptionPriceFormatted,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          state.fullName.isNotEmpty
                              ? state.fullName
                              : 'Unlimited drills & full 4-pillar analytics',
                          style: const TextStyle(color: Color(0xFF8E91A6), fontSize: 12),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PaywallScreen()),
                        );
                      },
                      child: const Text('Manage', style: TextStyle(color: Color(0xFF7A89FF), fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Profile Section
              _buildSectionHeader('TRAINING CALIBRATION'),
              _buildSettingTile(
                title: 'Industry Track',
                value: state.careerTypeLabel,
                icon: Icons.business_center_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PracticeContextScreen(),
                    ),
                  );
                },
              ),
              _buildSettingTile(
                title: 'Progress & Insights',
                value: 'View stats',
                icon: Icons.bar_chart_rounded,
                onTap: () => MainTabScaffold.switchTab(context, 1),
              ),
              _buildSettingTile(
                title: 'Daily Anchor Duration',
                value: '${state.dailyAnchorMinutes} Minutes / Day',
                icon: Icons.timer_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProfileSectionScreen(
                        focus: ProfileSectionFocus.dailyPractice,
                      ),
                    ),
                  );
                },
              ),
              _buildSettingTile(
                title: 'AI coach voice',
                value: state.coachVoiceGenderLabel,
                icon: Icons.record_voice_over_outlined,
                onTap: () => _showCoachVoicePicker(context),
              ),

              const SizedBox(height: 20),
              _buildSectionHeader('TRUST & TRANSPARENCY'),
              _buildSettingTile(
                title: 'How Hakkiri Works',
                value: 'AI & methodology',
                icon: Icons.shield_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HowHakkiriWorksScreen()),
                  );
                },
              ),
              _buildSettingTile(
                title: 'Fair Scoring Principles',
                value: 'Zero accent penalty',
                icon: Icons.balance_outlined,
                onTap: () => _showFairScoringDialog(context),
              ),
              _buildSettingTile(
                title: 'Privacy & Permissions',
                value: 'Manage your data',
                icon: Icons.lock_outline_rounded,
                onTap: _openPrivacyLink,
              ),

              const SizedBox(height: 32),
              Center(
                child: Column(
                  children: const [
                    HakkiriLogo(variant: HakkiriLogoVariant.fullImage, size: 96),
                    SizedBox(height: 12),
                    Text(
                      'Version 1.0.0 (Build 42) • Hakkiri Gym',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> _showCoachVoicePicker(BuildContext context) async {
    final state = Provider.of<AppStateProvider>(context, listen: false);
    final current = state.coachVoiceGender;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI coach voice',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Used for suggested answers on the feedback screen. Same AI voice engine — pick Male or Female.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.textMuted,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                _voiceOption(
                  sheetContext,
                  id: 'female',
                  title: 'Female',
                  subtitle: 'Warm coach voice (current default)',
                  selected: current == 'female',
                ),
                const SizedBox(height: 8),
                _voiceOption(
                  sheetContext,
                  id: 'male',
                  title: 'Male',
                  subtitle: 'Steady coach voice',
                  selected: current == 'male',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _voiceOption(
    BuildContext context, {
    required String id,
    required String title,
    required String subtitle,
    required bool selected,
  }) {
    return Material(
      color: selected
          ? AppColors.royalBlue.withValues(alpha: 0.08)
          : AppColors.background,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          final state = Provider.of<AppStateProvider>(context, listen: false);
          await CoachTtsService.instance.stop();
          await state.updateVoiceProfile(id);
          if (context.mounted) Navigator.pop(context);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.circle_outlined,
                color: selected ? AppColors.royalBlue : AppColors.textMuted,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _showFairScoringDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '⚖️ Fair Scoring Principles',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: AppStrings.fairScoringPrinciples
              .map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('• $p', style: const TextStyle(fontSize: 13, height: 1.4)),
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Understood', style: TextStyle(color: AppColors.royalBlue, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required String title,
    required String value,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBorderLight),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppColors.royalBlue, size: 22),
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
