import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants/app_colors.dart';
import '../providers/app_state_provider.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/hakkiri_logo.dart';
import '../widgets/orbital_background_painter.dart';
import 'edit_profile_screen.dart';
import 'how_hakkiri_works_screen.dart';
import 'landing_screen.dart';
import 'main_tab_scaffold.dart';
import 'paywall_screen.dart';
import 'practice_context_screen.dart';
import 'privacy_permissions_screen.dart';
import 'profile_section_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainTabScaffold(initialIndex: 3);
  }
}

class ProfileScreenContent extends StatefulWidget {
  const ProfileScreenContent({super.key});

  @override
  State<ProfileScreenContent> createState() => _ProfileScreenContentState();
}

class _ProfileScreenContentState extends State<ProfileScreenContent> {
  bool _loggingOut = false;
  bool _reminderSaving = false;

  Future<void> _openProfileEditor() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    );
  }

  Future<void> _openGoals() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ProfileSectionScreen(
          focus: ProfileSectionFocus.goals,
        ),
      ),
    );
  }

  Future<void> _openPracticeContext() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PracticeContextScreen(),
      ),
    );
  }

  Future<void> _openDailyPractice() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ProfileSectionScreen(
          focus: ProfileSectionFocus.dailyPractice,
        ),
      ),
    );
  }

  Future<void> _openHowHakkiriWorks() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HowHakkiriWorksScreen()),
    );
  }

  Future<void> _openPrivacyPermissions() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PrivacyPermissionsScreen()),
    );
  }

  Future<void> _openHelpAndFeedback() async {
    final state = Provider.of<AppStateProvider>(context, listen: false);
    final subject = Uri.encodeComponent('Hakkiri App Support & Feedback');
    final body = Uri.encodeComponent(
      'Hi Hakkiri Team,\n\n'
      'I would like to share feedback / need help with:\n\n'
      '---\n'
      'User: ${state.fullName.isNotEmpty ? state.fullName : "User"}\n'
      'Email: ${state.email}\n'
      'App: Hakkiri Gym v1.0.0\n',
    );
    final emailUri = Uri.parse('mailto:support@hakkiri.com?subject=$subject&body=$body');

    try {
      final launched = await launchUrl(
        emailUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        _showEmailFallbackSheet();
      }
    } catch (_) {
      if (mounted) {
        _showEmailFallbackSheet();
      }
    }
  }

  void _showEmailFallbackSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
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
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Contact Support',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Email our team directly for feedback, feature requests, or help with your drills.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.email_outlined, color: AppColors.royalBlue, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: SelectableText(
                      'support@hakkiri.com',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.royalBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  Clipboard.setData(const ClipboardData(text: 'support@hakkiri.com'));
                  Navigator.pop(ctx);
                  AppSnackBar.showSuccess(
                    context,
                    'Support email copied to clipboard! (support@hakkiri.com)',
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text(
                  'Copy Email Address',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    if (_loggingOut) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You can sign back in anytime with the same account.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _loggingOut = true);
    try {
      await context.read<AppStateProvider>().logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LandingScreen()),
        (route) => false,
      );
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final displayName = state.fullName.isNotEmpty ? state.fullName : 'Your profile';
    final displayEmail = state.email.isNotEmpty ? state.email : 'Tap to complete your details';

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row with Orbital Graphic in Background
            Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  right: -30,
                  top: -20,
                  width: 160,
                  height: 120,
                  child: const CustomPaint(painter: OrbitalBackgroundPainter()),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const HakkiriLogo(
                      variant: HakkiriLogoVariant.compactMark,
                      size: 22,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'SETTINGS',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: AppColors.textPrimary,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.8,
                          height: 1.15,
                        ),
                        children: [
                          TextSpan(text: 'Tailored '),
                          TextSpan(
                            text: 'for you.',
                            style: TextStyle(color: AppColors.royalBlue),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Openable profile section
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                onTap: _openProfileEditor,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: const BoxDecoration(
                          color: Color(0xFFDBEAFE),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          state.initials,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.royalBlue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              displayEmail,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'View & edit assessment details',
                              style: TextStyle(
                                color: AppColors.royalBlue.withValues(alpha: 0.9),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Hero Dark Card: Hakkiri Pro Subscription
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E1B4B).withValues(alpha: 0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // HD white vector Hakkiri mark
                  const HakkiriLogo(
                    variant: HakkiriLogoVariant.iconOnly,
                    isDark: true,
                    size: 48,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.subscriptionTitle,
                          style: const TextStyle(
                            color: Color(0xFF93C5FD),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          state.subscriptionPriceFormatted.isNotEmpty
                              ? state.subscriptionPriceFormatted
                              : 'No active plan',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          state.subscriptionRenewalLabel.isNotEmpty
                              ? state.subscriptionRenewalLabel
                              : (state.isSubscribed
                                  ? 'Manage your plan anytime'
                                  : 'Subscribe to unlock practice'),
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PaywallScreen()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text(
                      'Manage',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Group 1: YOUR TRAINING
            const Text(
              'YOUR TRAINING',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.surfaceBorder, width: 1.0),
              ),
              child: Column(
                children: [
                  _buildSettingRow(
                    icon: Icons.track_changes_rounded,
                    iconColor: const Color(0xFF3B82F6),
                    iconBgColor: const Color(0xFFEFF6FF),
                    title: 'Your Focus',
                    subtitle: state.primaryGoalLabel,
                    showDivider: true,
                    onTap: _openGoals,
                  ),
                  _buildSettingRow(
                    icon: Icons.business_center_outlined,
                    iconColor: const Color(0xFF10B981),
                    iconBgColor: const Color(0xFFECFDF5),
                    title: 'Practice context',
                    subtitle: state.careerTypeLabel,
                    showDivider: true,
                    onTap: _openPracticeContext,
                  ),
                  _buildSettingRow(
                    icon: Icons.calendar_today_outlined,
                    iconColor: const Color(0xFF8B5CF6),
                    iconBgColor: const Color(0xFFF5F3FF),
                    title: 'Daily practice',
                    subtitle: '${state.dailyAnchorMinutes} minutes a day',
                    showDivider: true,
                    onTap: _openDailyPractice,
                  ),
                  _buildSettingSwitchRow(
                    icon: Icons.notifications_none_rounded,
                    iconColor: const Color(0xFFF97316),
                    iconBgColor: const Color(0xFFFFF7ED),
                    title: 'Reminder',
                    subtitle: 'Daily practice push when you miss your goal',
                    value: state.remindersEnabled,
                    onChanged: _reminderSaving
                        ? null
                        : (val) async {
                            setState(() => _reminderSaving = true);
                            try {
                              await state.updateRemindersEnabled(val);
                            } catch (e) {
                              if (context.mounted) {
                                AppSnackBar.showError(context, e.toString());
                              }
                            } finally {
                              if (mounted) {
                                setState(() => _reminderSaving = false);
                              }
                            }
                          },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Group 2: APP PREFERENCES
            const Text(
              'APP PREFERENCES',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.surfaceBorder, width: 1.0),
              ),
              child: Column(
                children: [
                  _buildSettingRow(
                    icon: Icons.bar_chart_rounded,
                    iconColor: const Color(0xFF3B82F6),
                    iconBgColor: const Color(0xFFEFF6FF),
                    title: 'Progress & insights',
                    subtitle: 'Track your improvement and view your stats',
                    showDivider: false,
                    onTap: () => MainTabScaffold.switchTab(context, 1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Group 3: TRUST & SUPPORT
            const Text(
              'TRUST & SUPPORT',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.surfaceBorder, width: 1.0),
              ),
              child: Column(
                children: [
                  _buildSettingRow(
                    icon: Icons.shield_outlined,
                    iconColor: const Color(0xFF8B5CF6),
                    iconBgColor: const Color(0xFFF5F3FF),
                    title: 'How Hakkiri works',
                    subtitle: 'AI, feedback and scoring explained',
                    showDivider: true,
                    onTap: _openHowHakkiriWorks,
                  ),
                  _buildSettingRow(
                    icon: Icons.lock_outline_rounded,
                    iconColor: const Color(0xFFEF4444),
                    iconBgColor: const Color(0xFFFEF2F2),
                    title: 'Privacy & permissions',
                    subtitle: 'Manage your data and microphone access',
                    showDivider: true,
                    onTap: _openPrivacyPermissions,
                  ),
                  _buildSettingRow(
                    icon: Icons.help_outline_rounded,
                    iconColor: const Color(0xFF8B5CF6),
                    iconBgColor: const Color(0xFFF5F3FF),
                    title: 'Help & feedback',
                    subtitle: 'Get support or share feedback',
                    showDivider: false,
                    onTap: _openHelpAndFeedback,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Log out
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: _loggingOut ? null : _logout,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                  side: const BorderSide(color: Color(0xFFFECACA), width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  backgroundColor: const Color(0xFFFEF2F2),
                ),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: Text(
                  _loggingOut ? 'Logging out…' : 'Log out',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  static Widget _buildSettingRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required bool showDivider,
    VoidCallback? onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap ?? () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: iconColor, size: 20),
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
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(height: 1, indent: 64, endIndent: 16, color: AppColors.surfaceBorderLight),
      ],
    );
  }

  static Widget _buildSettingSwitchRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required bool value,
    ValueChanged<bool>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: iconColor, size: 20),
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
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.royalBlue,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFE2E8F0),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
