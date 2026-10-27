import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../widgets/action_pill_button.dart';
import '../widgets/hakkiri_logo.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

/// After guest dismisses IAP — Create account or Log in.
class GuestAuthScreen extends StatelessWidget {
  const GuestAuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final bottomGap = isIOS ? (safeBottom > 0 ? 20.0 : 12.0) : 14.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        bottom: !isIOS,
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 28, 24, bottomGap),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const HakkiriLogo(
                variant: HakkiriLogoVariant.headerPlanLockup,
                size: 28,
              ),
              const Spacer(),
              const Text(
                'Save your plan',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.6,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Create an account or log in to keep your assessment and continue.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              const Spacer(),
              ActionPillButton(
                label: 'Create account',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SignupScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                child: const Text(
                  'Log in',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.royalBlue,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
