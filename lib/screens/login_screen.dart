import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/services/analytics_service.dart';
import '../core/services/hakkiri_api_service.dart';
import '../providers/app_state_provider.dart';
import '../widgets/action_pill_button.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/auth_waveform_watermark.dart';
import '../widgets/google_logo.dart';
import '../widgets/hakkiri_loading_overlay.dart';
import '../widgets/hakkiri_logo.dart';
import 'assessment_screen.dart';
import 'home_screen.dart';
import 'locked_profile_screen.dart';
import 'forgot_password_screen.dart';
import 'landing_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenView(screenName: 'LoginScreen');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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

  Future<void> _handleLogin() async {
    if (_isSubmitting) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (!email.contains('@') || password.isEmpty) {
      _showMessage('Enter your email and password.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final state = context.read<AppStateProvider>();
      await HakkiriLoadingOverlay.run(
        context,
        message: 'Getting your information…',
        detail: 'Signing you back into Hakkiri.',
        action: () async {
          await state.loginAccount(email: email, password: password);
          // Assessment → existing account: overwrite profile with fresh quiz.
          await state.syncPendingAssessmentIfNeeded();
        },
      );
      if (!mounted) return;
      // Assessment → Pro gate → Home.
      final Widget next;
      if (!state.isOnboarded) {
        next = const AssessmentScreen();
      } else if (!state.isSubscribed) {
        next = const LockedProfileScreen();
      } else {
        next = const HomeScreen();
      }
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => next),
        (route) => false,
      );
    } on HakkiriApiException catch (e) {
      _showMessage(e.message);
    } catch (_) {
      _showMessage('Could not log in. Check your connection.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _handleGoogleLogin() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final state = context.read<AppStateProvider>();
      await HakkiriLoadingOverlay.run(
        context,
        message: 'Getting your information…',
        detail: 'Signing you in with Google.',
        action: () async {
          await state.continueWithGoogle();
          await state.syncPendingAssessmentIfNeeded();
        },
      );
      if (!mounted) return;
      final Widget next;
      if (!state.isOnboarded) {
        next = const AssessmentScreen();
      } else if (!state.isSubscribed) {
        next = const LockedProfileScreen();
      } else {
        next = const HomeScreen();
      }
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => next),
        (route) => false,
      );
    } on HakkiriApiException catch (e) {
      _showMessage(e.message);
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('canceled') || msg.contains('cancelled')) {
        _showMessage('Google sign-in was cancelled.');
      } else if (msg.contains('SHA-1')) {
        _showMessage('Add your Android SHA-1 fingerprint in Firebase Console.');
      } else {
        _showMessage('Google sign-in failed. Try again.');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _handleAppleLogin() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final state = context.read<AppStateProvider>();
      await HakkiriLoadingOverlay.run(
        context,
        message: 'Getting your information…',
        detail: 'Signing you in with Apple.',
        action: () async {
          await state.continueWithApple();
          await state.syncPendingAssessmentIfNeeded();
        },
      );
      if (!mounted) return;
      final Widget next;
      if (!state.isOnboarded) {
        next = const AssessmentScreen();
      } else if (!state.isSubscribed) {
        next = const LockedProfileScreen();
      } else {
        next = const HomeScreen();
      }
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => next),
        (route) => false,
      );
    } on HakkiriApiException catch (e) {
      _showMessage(e.message);
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('canceled') ||
          msg.contains('cancelled') ||
          msg.contains('AuthorizationErrorCode.canceled')) {
        _showMessage('Apple sign-in was cancelled.');
      } else if (msg.contains('not available')) {
        _showMessage(
          'Apple Sign-In needs an iPhone. Use Google or email on Android.',
        );
      } else {
        _showMessage('Apple sign-in failed. Try again on a real iPhone.');
      }
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
            // Ambient Organic Waves & Soundwave Background
            const AuthScreenBackground(showBottomWave: true),

            // Main Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Brand Header (Clean Horizontal Lockup)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const HakkiriLogo(
                        variant: HakkiriLogoVariant.compactMark,
                        size: 38,
                        brandText: 'Hakkiri',
                      ),
                      if (Navigator.canPop(context))
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

                  // Headline: "Welcome back."
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
                        TextSpan(text: 'Welcome\n'),
                        TextSpan(
                          text: 'back.',
                          style: TextStyle(color: AppColors.royalBlue),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Email Input Field
                  _buildInputField(
                    controller: _emailController,
                    hintText: 'Email',
                    prefixIcon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),

                  // Password Input Field
                  _buildInputField(
                    controller: _passwordController,
                    hintText: 'Password',
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
                  const SizedBox(height: 12),

                  // Forgot Password Link
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ForgotPasswordScreen(
                              initialEmail: _emailController.text.trim(),
                            ),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(
                          color: AppColors.royalBlue,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Log in Action Button
                  ActionPillButton(
                    label: _isSubmitting ? 'Logging in...' : 'Log in',
                    onTap: _isSubmitting ? null : _handleLogin,
                  ),
                  const SizedBox(height: 24),

                  // Or Divider
                  Row(
                    children: const [
                      Expanded(child: Divider(color: Color(0xFFE5E7EB), thickness: 1)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'or',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Color(0xFFE5E7EB), thickness: 1)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // iOS: Apple + Google. Android: Google full width (no Apple).
                  Builder(
                    builder: (context) {
                      final isIOS =
                          Theme.of(context).platform == TargetPlatform.iOS;
                      if (!isIOS) {
                        return SizedBox(
                          width: double.infinity,
                          child: _buildSocialButton(
                            label: 'Google',
                            isGoogle: true,
                            onTap: _isSubmitting ? () {} : _handleGoogleLogin,
                          ),
                        );
                      }
                      return Row(
                        children: [
                          Expanded(
                            child: _buildSocialButton(
                              label: 'Apple',
                              icon: Icons.apple_rounded,
                              onTap:
                                  _isSubmitting ? () {} : _handleAppleLogin,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildSocialButton(
                              label: 'Google',
                              isGoogle: true,
                              onTap:
                                  _isSubmitting ? () {} : _handleGoogleLogin,
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const Spacer(),

                  // Bottom Sign Up → same guest funnel as Get started
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LandingScreen(),
                          ),
                          (route) => false,
                        );
                      },
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          children: [
                            TextSpan(text: 'New to Hakkiri? '),
                            TextSpan(
                              text: 'Sign up',
                              style: TextStyle(
                                color: AppColors.royalBlue,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
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

  Widget _buildSocialButton({
    required String label,
    IconData? icon,
    bool isGoogle = false,
    required VoidCallback onTap,
  }) {
    final bgColor = isGoogle ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC);
    final borderColor = isGoogle ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0);

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.2),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isGoogle)
                const GoogleLogo(size: 20)
              else if (icon != null)
                Icon(icon, color: const Color(0xFF0F172A), size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
