import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/services/analytics_service.dart';

class PrivacyPermissionsScreen extends StatelessWidget {
  const PrivacyPermissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService.instance.logScreenView(screenName: 'PrivacyPermissionsScreen');
    });

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
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Icon(
                        Icons.chevron_left_rounded,
                        color: Color(0xFF0F172A),
                        size: 26,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Privacy & Permissions',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Your data privacy and device access controls',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  // Top Summary Banner
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.royalBlue.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.shield_rounded,
                            color: Color(0xFF60A5FA),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Private & Secure by Design',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'Hakkiri is designed for executive practice. Recordings and transcripts are sent to Google Gemini for scoring and coaching, stay confidential, and are never used for public AI training.',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  color: Color(0xFF94A3B8),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Section 1: Device Permissions
                  _buildSectionHeader('DEVICE PERMISSIONS'),
                  _buildCard([
                    _buildPermissionItem(
                      icon: Icons.mic_rounded,
                      iconColor: const Color(0xFF10B981),
                      iconBg: const Color(0xFFECFDF5),
                      title: 'Microphone Access',
                      badge: 'Active for Drills',
                      badgeColor: const Color(0xFF059669),
                      badgeBg: const Color(0xFFECFDF5),
                      description:
                          'Used strictly while you are actively recording a practice response. The microphone is never accessed in the background.',
                      showDivider: true,
                    ),
                    _buildPermissionItem(
                      icon: Icons.graphic_eq_rounded,
                      iconColor: const Color(0xFF2563EB),
                      iconBg: const Color(0xFFEFF6FF),
                      title: 'Speech Recognition',
                      badge: 'On-Device',
                      badgeColor: const Color(0xFF2563EB),
                      badgeBg: const Color(0xFFEFF6FF),
                      description:
                          'Converts your spoken answers into text to evaluate clarity, pace, structure, and eliminate filler words.',
                      showDivider: true,
                    ),
                    _buildPermissionItem(
                      icon: Icons.notifications_active_rounded,
                      iconColor: const Color(0xFFF59E0B),
                      iconBg: const Color(0xFFFEF3C7),
                      title: 'Notifications',
                      badge: 'Optional',
                      badgeColor: const Color(0xFFB45309),
                      badgeBg: const Color(0xFFFEF3C7),
                      description:
                          'Sends daily practice habit nudges at your chosen anchor time to help maintain your speaking streak.',
                      showDivider: false,
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // Section 2: Data Privacy & Security
                  _buildSectionHeader('DATA PRIVACY & INTEGRITY'),
                  _buildCard([
                    _buildPrivacyItem(
                      icon: Icons.lock_outline_rounded,
                      iconColor: const Color(0xFF6366F1),
                      iconBg: const Color(0xFFEEF2FF),
                      title: 'Sandboxed Local Storage',
                      description:
                          'Audio recordings are kept in the app’s isolated local sandbox directory. Other apps cannot read or access your recordings.',
                      showDivider: true,
                    ),
                    _buildPrivacyItem(
                      icon: Icons.cloud_outlined,
                      iconColor: const Color(0xFF2563EB),
                      iconBg: const Color(0xFFEFF6FF),
                      title: 'Google Gemini for scoring',
                      description:
                          'When you finish a drill, your audio and/or transcript is sent securely to Google’s Gemini models to score clarity, structure, and delivery, and to generate coaching feedback. We do not use your recordings to train public AI models.',
                      showDivider: true,
                    ),
                    _buildPrivacyItem(
                      icon: Icons.balance_rounded,
                      iconColor: const Color(0xFF059669),
                      iconBg: const Color(0xFFECFDF5),
                      title: 'Zero Accent Discrimination',
                      description:
                          'Our AI evaluates logic, structure, and substance — never your accent. Regional, international, and non-native accents receive equal scoring.',
                      showDivider: true,
                    ),
                    _buildPrivacyItem(
                      icon: Icons.no_accounts_rounded,
                      iconColor: const Color(0xFFEC4899),
                      iconBg: const Color(0xFFFDF2F8),
                      title: 'No Data Broker Sharing',
                      description:
                          'We do not sell personal data, transcripts, or audio samples to data brokers, advertisers, or third-party marketing networks.',
                      showDivider: true,
                    ),
                    _buildPrivacyItem(
                      icon: Icons.delete_forever_rounded,
                      iconColor: const Color(0xFFEF4444),
                      iconBg: const Color(0xFFFEF2F2),
                      title: 'Complete Deletion Control',
                      description:
                          'You can delete any single practice session from its detail screen anytime, or permanently purge your account data.',
                      showDivider: false,
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // Trust Badges Footer
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.verified_user_rounded,
                          color: Color(0xFF059669),
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'End-to-End Encrypted in Transit (TLS 1.3) • GDPR & CCPA Compliant',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Inter',
          color: Color(0xFF64748B),
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildPermissionItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String badge,
    required Color badgeColor,
    required Color badgeBg,
    required String description,
    required bool showDivider,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: badgeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
      ],
    );
  }

  Widget _buildPrivacyItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String description,
    required bool showDivider,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
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
                        fontFamily: 'Inter',
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
      ],
    );
  }
}
