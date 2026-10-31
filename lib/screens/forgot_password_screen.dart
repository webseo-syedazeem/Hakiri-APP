import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants/app_colors.dart';
import '../core/services/analytics_service.dart';
import '../core/services/hakkiri_api_service.dart';
import '../widgets/action_pill_button.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/auth_waveform_watermark.dart';
import '../widgets/hakkiri_logo.dart';

/// Forgot password: email → Gmail OTP → new password.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  /// 0 = email, 1 = OTP, 2 = new password
  int _step = 0;
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _resetToken;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenView(screenName: 'ForgotPasswordScreen');
    if (widget.initialEmail.isNotEmpty) {
      _emailController.text = widget.initialEmail;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
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

  Future<void> _sendOtp() async {
    if (_isSubmitting) return;
    final email = _emailController.text.trim();
    if (!email.contains('@')) {
      _showMessage('Enter a valid email.', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await HakkiriApiService.instance.forgotPassword(email: email);
      if (!mounted) return;
      setState(() => _step = 1);
      _showMessage('Check your Gmail for a 6-digit code.');
    } on HakkiriApiException catch (e) {
      _showMessage(e.message, isError: true);
    } catch (_) {
      _showMessage('Could not send the code. Check your connection.', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_isSubmitting) return;
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
      _showMessage('Enter the 6-digit code from your email.', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final token = await HakkiriApiService.instance.verifyResetOtp(
        email: email,
        otp: otp,
      );
      if (!mounted) return;
      setState(() {
        _resetToken = token;
        _step = 2;
      });
    } on HakkiriApiException catch (e) {
      _showMessage(e.message, isError: true);
    } catch (_) {
      _showMessage('Could not verify the code. Try again.', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _resetPassword() async {
    if (_isSubmitting) return;
    final password = _passwordController.text;
    final confirm = _confirmController.text;
    final token = _resetToken;

    if (token == null || token.isEmpty) {
      _showMessage('Session expired. Request a new code.', isError: true);
      setState(() => _step = 0);
      return;
    }
    if (password.length < 6) {
      _showMessage('Password must be at least 6 characters.', isError: true);
      return;
    }
    if (password != confirm) {
      _showMessage('Passwords do not match.', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await HakkiriApiService.instance.resetPassword(
        resetToken: token,
        password: password,
      );
      if (!mounted) return;
      AppSnackBar.showSuccess(context, 'Password updated. You can log in now.');
      Navigator.pop(context);
    } on HakkiriApiException catch (e) {
      _showMessage(e.message, isError: true);
    } catch (_) {
      _showMessage('Could not update the password. Try again.', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String get _headlinePrimary {
    switch (_step) {
      case 1:
        return 'Enter the';
      case 2:
        return 'Choose a';
      default:
        return 'Forgot';
    }
  }

  String get _headlineAccent {
    switch (_step) {
      case 1:
        return 'code.';
      case 2:
        return 'password.';
      default:
        return 'password?';
    }
  }

  String get _subtitle {
    switch (_step) {
      case 1:
        return 'We sent a 6-digit code to ${_emailController.text.trim()}.';
      case 2:
        return 'Pick something you’ll remember — at least 6 characters.';
      default:
        return 'We’ll email a one-time code to your Gmail.';
    }
  }

  String get _ctaLabel {
    if (_isSubmitting) {
      switch (_step) {
        case 1:
          return 'Verifying…';
        case 2:
          return 'Saving…';
        default:
          return 'Sending…';
      }
    }
    switch (_step) {
      case 1:
        return 'Verify code';
      case 2:
        return 'Update password';
      default:
        return 'Send code';
    }
  }

  VoidCallback? get _ctaAction {
    if (_isSubmitting) return null;
    switch (_step) {
      case 1:
        return _verifyOtp;
      case 2:
        return _resetPassword;
      default:
        return _sendOtp;
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
                        onTap: () {
                          if (_step > 0 && !_isSubmitting) {
                            setState(() => _step -= 1);
                          } else {
                            Navigator.pop(context);
                          }
                        },
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
                    text: TextSpan(
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        height: 1.15,
                        letterSpacing: -1.0,
                      ),
                      children: [
                        TextSpan(text: '$_headlinePrimary\n'),
                        TextSpan(
                          text: _headlineAccent,
                          style: const TextStyle(color: AppColors.royalBlue),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (_step == 0) ...[
                    _buildInputField(
                      controller: _emailController,
                      hintText: 'Email',
                      prefixIcon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ] else if (_step == 1) ...[
                    _buildInputField(
                      controller: _otpController,
                      hintText: '6-digit code',
                      prefixIcon: Icons.pin_outlined,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isSubmitting
                            ? null
                            : () {
                                _otpController.clear();
                                _sendOtp();
                              },
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
                  ] else ...[
                    _buildInputField(
                      controller: _passwordController,
                      hintText: 'New password',
                      prefixIcon: Icons.lock_outline_rounded,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.textMuted,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      controller: _confirmController,
                      hintText: 'Confirm password',
                      prefixIcon: Icons.lock_outline_rounded,
                      obscureText: _obscureConfirm,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.textMuted,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() => _obscureConfirm = !_obscureConfirm);
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  ActionPillButton(
                    label: _ctaLabel,
                    onTap: _ctaAction,
                  ),
                  if (_step == 1) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => setState(() {
                                  _step = 0;
                                  _otpController.clear();
                                }),
                        child: const Text(
                          'Use a different email',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAE9E2), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color(0xFF9E9EA7),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(prefixIcon, color: const Color(0xFF8E8E93), size: 20),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
