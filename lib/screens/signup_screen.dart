import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/navigation/guest_funnel_nav.dart';
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
import 'login_screen.dart';
import 'signup_verify_otp_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenView(screenName: 'SignupScreen');
  }

  @override
  void dispose() {
    _nameController.dispose();
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

  Future<void> _handleSignup() async {
    if (_isSubmitting) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.length < 2) {
      _showMessage('Enter your full name.');
      return;
    }
    if (!email.contains('@')) {
      _showMessage('Enter a valid email.');
      return;
    }
    if (password.length < 6) {
      _showMessage('Password must be at least 6 characters.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final state = context.read<AppStateProvider>();
      await HakkiriLoadingOverlay.run(
        context,
        message: 'Sending code…',
        detail: 'Check your email for a verification code.',
        action: () async {
          await state.sendSignupOtp(name: name, email: email);
        },
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SignupVerifyOtpScreen(
            fullName: name,
            email: email,
            password: password,
          ),
        ),
      );
    } on HakkiriApiException catch (e) {
      _showMessage(e.message);
    } catch (_) {
      _showMessage('Could not send the code. Check your connection.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _handleGoogleSignup() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final state = context.read<AppStateProvider>();
      late final Map<String, dynamic> data;
      late final bool syncedPending;
      await HakkiriLoadingOverlay.run(
        context,
        message: 'Getting your information…',
        detail: 'Signing you in with Google.',
        action: () async {
          data = await state.continueWithGoogle();
          // New or existing account: push the quiz the guest just filled.
          syncedPending = await state.syncPendingAssessmentIfNeeded();
        },
      );
      if (!mounted) return;
      // API check: existing account + onboarding done → Home (no funnel).
      final created = data['created'] == true;
      final profile = (data['profile'] as Map<String, dynamic>?) ?? {};
      final needsOnboarding = data.containsKey('needs_onboarding')
          ? data['needs_onboarding'] == true
          : (created || profile['onboarding_complete'] != true);
      final Widget next;
      if (syncedPending) {
        next = state.isSubscribed
            ? const HomeScreen()
            : const LockedProfileScreen();
      } else if (needsOnboarding) {
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

  Future<void> _handleAppleSignup() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final state = context.read<AppStateProvider>();
      late final Map<String, dynamic> data;
      late final bool syncedPending;
      await HakkiriLoadingOverlay.run(
        context,
        message: 'Getting your information…',
        detail: 'Signing you in with Apple.',
        action: () async {
          data = await state.continueWithApple();
          // New or existing account: push the quiz the guest just filled.
          syncedPending = await state.syncPendingAssessmentIfNeeded();
        },
      );
      if (!mounted) return;
      final created = data['created'] == true;
      final profile = (data['profile'] as Map<String, dynamic>?) ?? {};
      final needsOnboarding = data.containsKey('needs_onboarding')
          ? data['needs_onboarding'] == true
          : (created || profile['onboarding_complete'] != true);
      final Widget next;
      if (syncedPending) {
        next = state.isSubscribed
            ? const HomeScreen()
            : const LockedProfileScreen();
      } else if (needsOnboarding) {
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
        _showMessage('Apple Sign-In needs an iPhone. Use Google or email on Android.');
      } else {
        _showMessage('Apple sign-in failed. Try again on a real iPhone.');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_isSubmitting) {
          goBackInGuestFunnel(context, from: GuestFunnelStep.signup);
        }
      },
      child: Scaffold(
      backgroundColor: const Color(0xFFFBFBF9),
      body: SafeArea(
        child: Stack(
          children: [
            // Ambient Organic Waves & Soundwave Background
            const AuthScreenBackground(showBottomWave: false),

            // Main Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back pinned to top-left (not vertically centered with logo).
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: _isSubmitting
                          ? null
                          : () => goBackInGuestFunnel(
                                context,
                                from: GuestFunnelStep.signup,
                              ),
                      child: const Padding(
                        padding: EdgeInsets.only(top: 2, bottom: 8, right: 8),
                        child: Icon(
                          Icons.arrow_back_ios,
                          color: Color(0xFFB8BFC9),
                          size: 15,
                        ),
                      ),
                    ),
                  ),
                  const Center(
                    child: HakkiriLogo(
                      variant: HakkiriLogoVariant.fullImage,
                      size: 96,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Headline: "Create account."
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
                        TextSpan(text: 'Create\n'),
                        TextSpan(
                          text: 'account.',
                          style: TextStyle(color: AppColors.royalBlue),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Full Name Field
                  _buildInputField(
                    controller: _nameController,
                    hintText: 'Full name',
                    prefixIcon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 14),

                  // Email Input Field
                  _buildInputField(
                    controller: _emailController,
                    hintText: 'Email',
                    prefixIcon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),

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
                  const SizedBox(height: 24),

                  // Create Account Action Button
                  ActionPillButton(
                    label: _isSubmitting ? 'Creating account...' : 'Create account',
                    onTap: _isSubmitting ? null : _handleSignup,
                  ),
                  const SizedBox(height: 22),

                  // Or continue with Divider
                  Row(
                    children: const [
                      Expanded(child: Divider(color: Color(0xFFE5E7EB), thickness: 1)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'or continue with',
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
                            onTap: _isSubmitting ? () {} : _handleGoogleSignup,
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
                                  _isSubmitting ? () {} : _handleAppleSignup,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildSocialButton(
                              label: 'Google',
                              isGoogle: true,
                              onTap:
                                  _isSubmitting ? () {} : _handleGoogleSignup,
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const Spacer(),

                  // Bottom Log In Prompt
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
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
                            TextSpan(text: 'Already have an account? '),
                            TextSpan(
                              text: 'Log in',
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
