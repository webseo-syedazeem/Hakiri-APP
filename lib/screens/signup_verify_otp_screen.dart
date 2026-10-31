import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/services/analytics_service.dart';
import '../core/services/hakkiri_api_service.dart';
import '../providers/app_state_provider.dart';
import '../widgets/action_pill_button.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/auth_waveform_watermark.dart';
import '../widgets/hakkiri_loading_overlay.dart';
import '../widgets/hakkiri_logo.dart';
import 'assessment_screen.dart';
import 'home_screen.dart';
import 'locked_profile_screen.dart';

/// After signup form: verify the 6-digit email OTP, then create the account.
class SignupVerifyOtpScreen extends StatefulWidget {
  const SignupVerifyOtpScreen({
    super.key,
    required this.fullName,
    required this.email,
    required this.password,
  });

  final String fullName;
  final String email;
  final String password;

  @override
  State<SignupVerifyOtpScreen> createState() => _SignupVerifyOtpScreenState();
}

class _SignupVerifyOtpScreenState extends State<SignupVerifyOtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenView(screenName: 'SignupVerifyOtpScreen');
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    if (isError) {
      AppSnackBar.showError(context, message);
    } else {
      AppSnackBar.showInfo(context, message);
    }
  }

  Future<void> _resend() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await HakkiriApiService.instance.sendSignupOtp(
        fullName: widget.fullName,
        email: widget.email,
      );
      if (!mounted) return;
      _showMessage('New code sent to ${widget.email}.');
    } on HakkiriApiException catch (e) {
      _showMessage(e.message, isError: true);
    } catch (_) {
      _showMessage('Could not resend the code.', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _verifyAndCreate() async {
    if (_isSubmitting) return;
    final otp = _otpController.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
      _showMessage('Enter the 6-digit code from your email.', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final state = context.read<AppStateProvider>();
      late final bool syncedPending;
      await HakkiriLoadingOverlay.run(
        context,
        message: 'Verifying…',
        detail: 'Creating your Hakkiri account.',
        action: () async {
          await state.registerAccount(
            name: widget.fullName,
            email: widget.email,
            password: widget.password,
            otp: otp,
          );
          syncedPending = await state.syncPendingAssessmentIfNeeded();
        },
      );
      if (!mounted) return;
      final Widget next;
      if (syncedPending) {
        next = state.isSubscribed
            ? const HomeScreen()
            : const LockedProfileScreen();
      } else {
        next = const AssessmentScreen();
      }
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => next),
        (route) => false,
      );
    } on HakkiriApiException catch (e) {
      _showMessage(e.message, isError: true);
    } catch (_) {
      _showMessage('Could not verify. Check your connection.', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBF9),
      body: SafeArea(
        child: Stack(
          children: [
            const AuthScreenBackground(showBottomWave: true),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const HakkiriLogo(
                        variant: HakkiriLogoVariant.compactMark,
                        size: 38,
                        brandText: 'Hakkiri',
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.close_rounded,
                            color: AppColors.textSecondary,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 38),
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        height: 1.15,
                        letterSpacing: -1.0,
                      ),
                      children: [
                        TextSpan(text: 'Verify\n'),
                        TextSpan(
                          text: 'your email.',
                          style: TextStyle(color: AppColors.royalBlue),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'We sent a 6-digit code to ${widget.email}.',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFEAE9E2),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: const InputDecoration(
                        hintText: '6-digit code',
                        hintStyle: TextStyle(
                          color: Color(0xFF9E9EA7),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        prefixIcon: Icon(
                          Icons.pin_outlined,
                          color: Color(0xFF8E8E93),
                          size: 20,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isSubmitting ? null : _resend,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Resend code',
                        style: TextStyle(
                          color: AppColors.royalBlue,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  ActionPillButton(
                    label: _isSubmitting ? 'Verifying…' : 'Verify & continue',
                    onTap: _isSubmitting ? null : _verifyAndCreate,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
