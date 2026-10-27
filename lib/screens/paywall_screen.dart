import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants/app_colors.dart';
import '../core/services/analytics_service.dart';
import '../core/services/hakkiri_api_service.dart';
import '../core/services/iap_service.dart';
import '../providers/app_state_provider.dart';
import '../widgets/hakkiri_logo.dart';
import '../widgets/paywall_wave_background.dart';
import 'guest_auth_screen.dart';
import 'home_screen.dart';
import 'locked_profile_screen.dart';
import 'signup_screen.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  /// API tiers: monthly_pro | annual_pro
  String _selectedTier = 'annual_pro';
  bool _purchasing = false;
  bool _loadingProducts = true;
  String? _statusMessage;
  StreamSubscription<PurchaseDetails>? _purchaseSub;

  final _iap = IapService.instance;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logViewPaywall();
    AnalyticsService.instance.logScreenView(screenName: 'PaywallScreen');
    _purchaseSub = _iap.purchaseUpdates.listen(_onPurchaseUpdate);
    _bootstrap();
  }

  @override
  void dispose() {
    _purchaseSub?.cancel();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loadingProducts = true;
      _statusMessage = null;
    });
    await _iap.init();
    if (!mounted) return;
    // Don't show red "plan not found" on load — only snackbar if user taps buy.
    setState(() => _loadingProducts = false);
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _priceForTier(String tier, String fallback) {
    final p = _iap.productForTier(tier);
    return p?.price ?? fallback;
  }

  void _dismissWithoutPurchase() {
    final state = context.read<AppStateProvider>();
    if (!state.isLoggedIn) {
      unawaited(state.markGuestAwaitingAccount());
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SignupScreen()),
        (route) => false,
      );
      return;
    }
    // Settings / Profile "Manage" pushed this screen — return there.
    if (Navigator.of(context).canPop()) {
      Navigator.pop(context);
      return;
    }
    // Root paywall (onboarding). Subscribed users go home; others stay locked.
    if (state.isSubscribed) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
      return;
    }
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LockedProfileScreen()),
      (route) => false,
    );
  }

  void _goAfterGuestPurchase() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SignupScreen()),
      (route) => false,
    );
  }

  Future<void> _onContinue() async {
    if (_purchasing) return;
    setState(() {
      _purchasing = true;
      _statusMessage = null;
    });

    AnalyticsService.instance.logSelectPlan(
      planId: _selectedTier,
      price: _priceForTier(
        _selectedTier,
        _selectedTier == 'annual_pro' ? 'annual' : 'monthly',
      ),
    );

    final started = await _iap.buyTier(_selectedTier);
    if (!mounted) return;
    if (!started) {
      if (kDebugMode) {
        try {
          final state = context.read<AppStateProvider>();
          await state.activatePaidPlan(_selectedTier);
          if (!mounted) return;
          _showSnack('Debug mode: Plan activated (Store IAP bypassed).');
          if (!state.isLoggedIn) {
            _goAfterGuestPurchase();
          } else {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            );
          }
          return;
        } catch (e) {
          debugPrint('Debug mode activatePaidPlan failed: $e');
        }
      }

      setState(() {
        _purchasing = false;
        _statusMessage = null;
      });
      _showSnack(
        _iap.lastError ??
            'This plan is not available right now. Please try again later.',
      );
    }
    // Success path continues in _onPurchaseUpdate.
  }

  Future<void> _onPurchaseUpdate(PurchaseDetails purchase) async {
    if (purchase.status == PurchaseStatus.pending) {
      if (mounted) {
        setState(() {
          _purchasing = true;
          _statusMessage = 'Confirming purchase…';
        });
      }
      return;
    }

    if (purchase.status == PurchaseStatus.error) {
      await _iap.complete(purchase);
      if (!mounted) return;
      setState(() {
        _purchasing = false;
        _statusMessage = null;
      });
      _showSnack(
        purchase.error?.message ?? 'Purchase failed. Please try again.',
      );
      return;
    }

    if (purchase.status == PurchaseStatus.canceled) {
      await _iap.complete(purchase);
      if (!mounted) return;
      setState(() {
        _purchasing = false;
        _statusMessage = null;
      });
      return;
    }

    if (purchase.status == PurchaseStatus.purchased ||
        purchase.status == PurchaseStatus.restored) {
      final tier = IapProducts.tierForProductId(purchase.productID);
      if (tier == null) {
        await _iap.complete(purchase);
        if (!mounted) return;
        setState(() {
          _purchasing = false;
          _statusMessage = null;
        });
        _showSnack('Unknown product. Contact support.');
        return;
      }

      try {
        final state = context.read<AppStateProvider>();
        await state.activatePaidPlan(tier);
        await _iap.complete(purchase);
        if (!mounted) return;
        if (!state.isLoggedIn) {
          _goAfterGuestPurchase();
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        }
      } on HakkiriApiException catch (e) {
        await _iap.complete(purchase);
        if (!mounted) return;
        setState(() {
          _purchasing = false;
          _statusMessage = null;
        });
        _showSnack(e.message);
      } catch (e) {
        await _iap.complete(purchase);
        if (!mounted) return;
        setState(() {
          _purchasing = false;
          _statusMessage = null;
        });
        _showSnack('Purchase succeeded but plan sync failed. Try Restore.');
      }
    }
  }

  Future<void> _restore() async {
    if (_purchasing) return;
    setState(() {
      _purchasing = true;
      _statusMessage = 'Restoring purchases…';
    });
    try {
      await _iap.restore();
      // Restored items arrive on purchase stream.
      await Future<void>.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      final state = context.read<AppStateProvider>();
      if (state.isSubscribed) {
        if (!state.isLoggedIn) {
          _goAfterGuestPurchase();
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        }
        return;
      }
      if (kDebugMode) {
        await state.activatePaidPlan(_selectedTier);
        if (!mounted) return;
        _showSnack('Debug mode: Plan restored.');
        if (!state.isLoggedIn) {
          _goAfterGuestPurchase();
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        }
        return;
      }
      setState(() {
        _purchasing = false;
        _statusMessage = null;
      });
      _showSnack('No active subscription found to restore.');
    } catch (_) {
      if (!mounted) return;
      if (kDebugMode) {
        final state = context.read<AppStateProvider>();
        await state.activatePaidPlan(_selectedTier);
        if (!mounted) return;
        _showSnack('Debug mode: Plan restored.');
        if (!state.isLoggedIn) {
          _goAfterGuestPurchase();
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        }
        return;
      }
      setState(() {
        _purchasing = false;
        _statusMessage = null;
      });
      _showSnack('Could not restore purchases. Try again.');
    }
  }

  Future<void> _openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      try {
        final uri = Uri.parse(url);
        await launchUrl(uri, mode: LaunchMode.inAppWebView);
      } catch (_) {
        _showSnack('Could not open link: $url');
      }
    }
  }

  void _showCancelAnytimeDialog() {
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF1E293B)),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.event_repeat_rounded,
                  color: Color(0xFF60A5FA),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Cancel Anytime',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'You have total freedom. Your subscription will not be charged if cancelled at least 24 hours before the renewal date. Follow these steps to manage or cancel:',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                if (isIOS)
                  _buildCancelPlatformGuide(
                    title: 'Apple App Store (iOS)',
                    steps: const [
                      'Open Settings on your iPhone.',
                      'Tap your Apple ID / Name at the top.',
                      'Tap "Subscriptions".',
                      'Select "Hakkiri" and tap "Cancel Subscription".',
                    ],
                  )
                else
                  _buildCancelPlatformGuide(
                    title: 'Google Play Store (Android)',
                    steps: const [
                      'Open the Google Play Store app.',
                      'Tap your Profile icon at the top right.',
                      'Tap "Payments & subscriptions" -> "Subscriptions".',
                      'Select "Hakkiri" and tap "Cancel subscription".',
                    ],
                  ),
              ],
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.royalBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Got it',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCancelPlatformGuide({
    required String title,
    required List<String> steps,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF131B2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF3B82F6),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF60A5FA),
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${i + 1}. ',
                    style: const TextStyle(
                      color: Color(0xFF60A5FA),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      steps[i],
                      style: const TextStyle(
                        color: Color(0xFFCBD5E1),
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _activePlanHeadline(AppStateProvider state) {
    switch (state.subscriptionTier) {
      case 'annual_pro':
        return 'Your yearly plan is active';
      case 'monthly_pro':
        return 'Your monthly plan is active';
      default:
        return 'Your Pro plan is active';
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final hasActivePlan = state.isSubscribed;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _dismissWithoutPurchase();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF020617),
        body: Stack(
          children: [
            const PaywallWaveBackground(),
            SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const HakkiriLogo(
                          variant: HakkiriLogoVariant.paywallDarkLockup,
                          size: 28,
                        ),
                        GestureDetector(
                          onTap: _purchasing ? null : _dismissWithoutPurchase,
                          child: const Padding(
                            padding: EdgeInsets.all(4.0),
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hasActivePlan ? 'YOUR PLAN' : 'HAKKIRI PRO',
                              style: const TextStyle(
                                color: Color(0xFF5B6BFF),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (hasActivePlan) ...[
                              Text(
                                _activePlanHeadline(state),
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  color: Colors.white,
                                  fontSize: 34,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1.0,
                                  height: 1.15,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                state.subscriptionRenewalLabel.isNotEmpty
                                    ? state.subscriptionRenewalLabel
                                    : 'Full access to practice, coach, and feedback.',
                                style: const TextStyle(
                                  color: Color(0xFF9AA3BD),
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w500,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 28),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 18,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF141624),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFF3B82F6),
                                    width: 1.8,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF1E3A5F),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check_rounded,
                                        color: Color(0xFF60A5FA),
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            state.subscriptionTitle,
                                            style: const TextStyle(
                                              color: Color(0xFF93C5FD),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            state.subscriptionPriceFormatted,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else ...[
                              RichText(
                                text: const TextSpan(
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    color: Colors.white,
                                    fontSize: 40,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -1.2,
                                    height: 1.12,
                                  ),
                                  children: [
                                    TextSpan(text: 'Be a more\n'),
                                    TextSpan(
                                      text: 'confident you.',
                                      style:
                                          TextStyle(color: Color(0xFF4E75FF)),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'Unlock your personalised plan and keep making real progress.',
                                style: TextStyle(
                                  color: Color(0xFF9AA3BD),
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w500,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 30),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _buildFeatureTile(
                                      icon: Icons.bar_chart_rounded,
                                      iconColor: const Color(0xFF3B82F6),
                                      bgColor: const Color(0xFF111A33),
                                      label: 'Daily\npractice',
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _buildFeatureTile(
                                      icon: Icons.psychology_rounded,
                                      iconColor: const Color(0xFFA78BFA),
                                      bgColor: const Color(0xFF1B1733),
                                      label: 'Personalised\nfeedback',
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _buildFeatureTile(
                                      icon: Icons.track_changes_rounded,
                                      iconColor: const Color(0xFF34D399),
                                      bgColor: const Color(0xFF0E2320),
                                      label: 'Real\nprogress',
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _buildFeatureTile(
                                      icon:
                                          Icons.local_fire_department_rounded,
                                      iconColor: const Color(0xFFFB923C),
                                      bgColor: const Color(0xFF241A12),
                                      label: 'Build\nconfidence',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (_loadingProducts)
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 12),
                                  child: LinearProgressIndicator(
                                    minHeight: 2,
                                    color: Color(0xFF3B82F6),
                                    backgroundColor: Color(0xFF23263B),
                                  ),
                                ),
                              _buildPlanCard(
                                id: 'annual_pro',
                                title: 'Yearly',
                                subtitle: '£0.19 per day · billed yearly',
                                priceText: _priceForTier(
                                  'annual_pro',
                                  '£69.99',
                                ),
                                badgeText: 'BEST VALUE',
                                isSelected: _selectedTier == 'annual_pro',
                              ),
                              const SizedBox(height: 12),
                              _buildPlanCard(
                                id: 'monthly_pro',
                                title: 'Monthly',
                                subtitle: '£0.33 per day · billed monthly',
                                priceText: _priceForTier(
                                  'monthly_pro',
                                  '£9.99',
                                ),
                                isSelected: _selectedTier == 'monthly_pro',
                              ),
                              if (_statusMessage != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  _statusMessage!,
                                  style: const TextStyle(
                                    color: Color(0xFF93C5FD),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ],
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                    // Fixed at bottom: CTA, then Cancel anytime / Terms / Privacy.
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: Material(
                        color: hasActivePlan
                            ? const Color(0xFF1E293B)
                            : (_purchasing
                                ? AppColors.royalBlue.withValues(alpha: 0.6)
                                : AppColors.royalBlue),
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          onTap: hasActivePlan
                              ? _dismissWithoutPurchase
                              : (_purchasing ? null : _onContinue),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (!hasActivePlan && _purchasing) ...[
                                  const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Processing…',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ] else if (hasActivePlan) ...[
                                  const Text(
                                    'Done',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ] else ...[
                                  const Spacer(),
                                  const Text(
                                    'Unlock Hakkiri Pro',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const Spacer(),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _buildFooterLink(
                            'Cancel anytime',
                            _showCancelAnytimeDialog,
                          ),
                          const Text(
                            '  ·  ',
                            style: TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 11,
                            ),
                          ),
                          _buildFooterLink(
                            'Terms and condition',
                            () =>
                                _openUrl('https://hakkiriapp.vercel.app/terms'),
                          ),
                          const Text(
                            '  ·  ',
                            style: TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 11,
                            ),
                          ),
                          _buildFooterLink(
                            'Privacy policy',
                            () => _openUrl(
                                'https://hakkiriapp.vercel.app/privacy'),
                          ),
                        ],
                      ),
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

  Widget _buildFeatureTile({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String label,
  }) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.06),
              width: 1.0,
            ),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: iconColor, size: 30),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildPlanCard({
    required String id,
    required String title,
    required String subtitle,
    required String priceText,
    String? badgeText,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: _purchasing ? null : () => setState(() => _selectedTier = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF141624),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF3B82F6)
                : const Color(0xFF23263B),
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.royalBlue : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? AppColors.royalBlue
                      : const Color(0xFF4B5563),
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: isSelected
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 16)
                  : null,
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
                          color: Colors.white,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (badgeText != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badgeText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF8B92A8),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              priceText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF8B92A8),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterLink(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: _purchasing ? null : onTap,
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF8B92A8),
          fontSize: 12,
          fontWeight: FontWeight.w500,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}
