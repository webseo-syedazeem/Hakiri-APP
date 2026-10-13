import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../core/services/analytics_service.dart';
import '../providers/app_state_provider.dart';
import '../widgets/hakkiri_logo.dart';
import 'main_tab_scaffold.dart';
import 'paywall_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
              ),
              _buildSettingTile(
                title: 'Voice Resonance Profile',
                value: state.voiceProfileLabel,
                icon: Icons.mic_none_outlined,
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
              ),

              const SizedBox(height: 20),
              _buildSectionHeader('TRUST & TRANSPARENCY'),
              _buildSettingTile(
                title: 'Fair Scoring Principles',
                value: 'Zero accent penalty',
                icon: Icons.balance_outlined,
                onTap: () => _showFairScoringDialog(context),
              ),
              _buildSettingTile(
                title: 'Audio Privacy & Telemetry',
                value: state.audioPrivacy.replaceAll('_', ' '),
                icon: Icons.security_outlined,
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
