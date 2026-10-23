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
import '../widgets/app_snackbar.dart';
import '../widgets/hakkiri_logo.dart';
import '../widgets/paywall_wave_background.dart';
import 'home_screen.dart';
import 'locked_profile_screen.dart';

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
    AppSnackBar.showInfo(context, message);
  }

  String _priceForTier(String tier, String fallback) {
    final p = _iap.productForTier(tier);
    return p?.price ?? fallback;
  }

  String _subtitleForTier(String tier, String fallback) {
    final p = _iap.productForTier(tier);
    if (p == null) return fallback;
    if (tier == 'annual_pro') {
      return '${p.price} per year · billed yearly';
    }
    return '${p.price} per month · billed monthly';
  }

  void _dismissWithoutPurchase() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LockedProfileScreen()),
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
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
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
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
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
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
        return;
      }
      if (kDebugMode) {
        final state = context.read<AppStateProvider>();
        await state.activatePaidPlan(_selectedTier);
        if (!mounted) return;
        _showSnack('Debug mode: Plan restored.');
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
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
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
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
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final short = media.size.height < 780;
    final isIos = defaultTargetPlatform == TargetPlatform.iOS;
    final gap = short ? 8.0 : 14.0;
    final titleSize = short ? 28.0 : 36.0;
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
              bottom: !isIos,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  short ? 8 : 14,
                  24,
                  isIos ? 4 : (short ? 8 : 14),
                ),
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
                    SizedBox(height: short ? 8 : 16),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.topCenter,
                            child: SizedBox(
                              width: constraints.maxWidth,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'HAKKIRI PRO',
                                    style: TextStyle(
                                      color: Color(0xFF5B6BFF),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  RichText(
                                    text: TextSpan(
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        color: Colors.white,
                                        fontSize: titleSize,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -1.0,
                                        height: 1.12,
                                      ),
                                      children: const [
                                        TextSpan(text: 'Keep improving\n'),
                                        TextSpan(
                                          text: 'every day.',
                                          style: TextStyle(
                                            color: Color(0xFF4E75FF),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: short ? 12 : 20),
                                  _buildFeatureRow(
                                    icon: Icons.article_outlined,
                                    title: 'New prompts every day',
                                    subtitle:
                                        'Matched to your goals and challenges',
                                    compact: short,
                                  ),
                                  SizedBox(height: gap),
                                  _buildFeatureRow(
                                    icon: Icons.chat_bubble_outline_rounded,
                                    title:
                                        'Specific feedback after every answer',
                                    subtitle:
                                        "Understand what's working and how to improve",
                                    compact: short,
                                  ),
                                  SizedBox(height: gap),
                                  _buildFeatureRow(
                                    icon: Icons.tune_rounded,
                                    title: 'A plan that adapts each week',
                                    subtitle:
                                        'Personalised to your progress',
                                    compact: short,
                                  ),
                                  SizedBox(height: gap),
                                  _buildFeatureRow(
                                    icon: Icons.bar_chart_rounded,
                                    title: 'More exercises, every level',
                                    subtitle:
                                        'From everyday conversations to high-stakes moments',
                                    compact: short,
                                  ),
                                  SizedBox(height: gap),
                                  _buildFeatureRow(
                                    icon: Icons.track_changes_rounded,
                                    title: 'Progress tracking and streaks',
                                    subtitle:
                                        'Stay consistent and see real improvement',
                                    compact: short,
                                  ),
                                  SizedBox(height: short ? 12 : 20),
                                  if (_loadingProducts)
                                    const Padding(
                                      padding: EdgeInsets.only(bottom: 10),
                                      child: LinearProgressIndicator(
                                        minHeight: 2,
                                        color: Color(0xFF3B82F6),
                                        backgroundColor: Color(0xFF23263B),
                                      ),
                                    ),
                                  _buildPlanCard(
                                    id: 'annual_pro',
                                    title: 'Yearly',
                                    subtitle: _subtitleForTier(
                                      'annual_pro',
                                      '£69.99 per year · billed yearly',
                                    ),
                                    priceText: _priceForTier(
                                      'annual_pro',
                                      '£69.99/yr',
                                    ),
                                    badgeText: 'BEST VALUE',
                                    isSelected: _selectedTier == 'annual_pro',
                                    compact: short,
                                  ),
                                  SizedBox(height: short ? 8 : 12),
                                  _buildPlanCard(
                                    id: 'monthly_pro',
                                    title: 'Monthly',
                                    subtitle: _subtitleForTier(
                                      'monthly_pro',
                                      '£9.99 per month · billed monthly',
                                    ),
                                    priceText: _priceForTier(
                                      'monthly_pro',
                                      '£9.99/mo',
                                    ),
                                    isSelected: _selectedTier == 'monthly_pro',
                                    compact: short,
                                  ),
                                  if (_statusMessage != null) ...[
                                    const SizedBox(height: 10),
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
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: Material(
                        color: _purchasing
                            ? AppColors.royalBlue.withValues(alpha: 0.6)
                            : AppColors.royalBlue,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          onTap: _purchasing ? null : _onContinue,
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_purchasing) ...[
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
                                ] else ...[
                                  const Spacer(),
                                  const Text(
                                    'Continue to Pro',
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
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildFooterLink('Restore purchase', _restore),
                        const Text(
                          '  ·  ',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 12,
                          ),
                        ),
                        _buildFooterLink(
                          'Terms',
                          () => _openUrl('https://hakkiri.com/terms'),
                        ),
                        const Text(
                          '  ·  ',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 12,
                          ),
                        ),
                        _buildFooterLink(
                          'Privacy',
                          () => _openUrl('https://hakkiri.com/privacy'),
                        ),
                      ],
                    ),
                    SizedBox(height: isIos ? 2 : 6),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required String title,
    required String subtitle,
    bool compact = false,
  }) {
    final box = compact ? 32.0 : 40.0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: box,
          height: box,
          decoration: BoxDecoration(
            color: const Color(0xFF161928),
            borderRadius: BorderRadius.circular(compact ? 10 : 12),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: const Color(0xFF8B95B8), size: compact ? 16 : 20),
        ),
        SizedBox(width: compact ? 10 : 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 13 : 14.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: compact ? 1 : 3),
              Text(
                subtitle,
                style: TextStyle(
                  color: const Color(0xFF8B92A8),
                  fontSize: compact ? 11 : 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
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
    bool compact = false,
  }) {
    return GestureDetector(
      onTap: _purchasing ? null : () => setState(() => _selectedTier = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 14 : 18,
          vertical: compact ? 10 : 16,
        ),
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
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
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
