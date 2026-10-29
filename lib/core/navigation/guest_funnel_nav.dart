import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state_provider.dart';
import '../../screens/assessment_screen.dart';
import '../../screens/landing_screen.dart';
import '../../screens/paywall_screen.dart';
import '../../screens/personalized_plan_screen.dart';
import '../../screens/signup_screen.dart';

/// Where the user is in the guest funnel (for back when the stack was lost
/// after app kill / splash restore).
enum GuestFunnelStep {
  assessment,
  plan,
  paywall,
  signup,
}

/// Back through Get started → assessment → plan → IAP → create account.
///
/// Prefer [Navigator.pop] when a previous route exists. If this screen is the
/// root (e.g. restored from splash), step one screen back in the funnel
/// instead of jumping straight to Get started.
Future<void> goBackInGuestFunnel(
  BuildContext context, {
  required GuestFunnelStep from,
}) async {
  if (Navigator.of(context).canPop()) {
    Navigator.pop(context);
    return;
  }

  final state = context.read<AppStateProvider>();

  // Logged-in users are not in the guest funnel — leave safely.
  if (state.isLoggedIn) {
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LandingScreen()),
      (_) => false,
    );
    return;
  }

  if (!context.mounted) return;

  switch (from) {
    case GuestFunnelStep.signup:
      // Create account → Paywall (keep awaiting_account / iap state coherent).
      await state.markGuestReachedPaywall();
      if (!context.mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PaywallScreen()),
      );
      return;

    case GuestFunnelStep.paywall:
      // Paywall → Plan
      await state.markGuestAwaitingIap();
      if (!context.mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PersonalizedPlanScreen()),
      );
      return;

    case GuestFunnelStep.plan:
      // Plan → Assessment (answers still in memory / pending local).
      if (!context.mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AssessmentScreen()),
      );
      return;

    case GuestFunnelStep.assessment:
      // Assessment step 0 → Get started
      await state.clearGuestFunnel();
      if (!context.mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LandingScreen()),
        (_) => false,
      );
      return;
  }
}

/// After splash, rebuild a poppable stack so Create account → Paywall → Plan
/// back works without jumping to Get started.
class GuestFunnelRestoreShell extends StatefulWidget {
  final GuestFunnelStep resumeAt;

  const GuestFunnelRestoreShell({super.key, required this.resumeAt});

  @override
  State<GuestFunnelRestoreShell> createState() =>
      _GuestFunnelRestoreShellState();
}

class _GuestFunnelRestoreShellState extends State<GuestFunnelRestoreShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _pushRestOfStack());
  }

  void _pushRestOfStack() {
    if (!mounted) return;
    final nav = Navigator.of(context);

    // Do not await push — await waits until the route is popped.
    // Base route is Plan; stack Paywall (and Signup) on top in the same frame.
    if (widget.resumeAt == GuestFunnelStep.paywall ||
        widget.resumeAt == GuestFunnelStep.signup) {
      nav.push(MaterialPageRoute(builder: (_) => const PaywallScreen()));
    }
    if (widget.resumeAt == GuestFunnelStep.signup) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SignupScreen()),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Bottom of restored stack — back from here goes to assessment / landing.
    return const PersonalizedPlanScreen();
  }
}
