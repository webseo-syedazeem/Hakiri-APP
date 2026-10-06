import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../widgets/action_pill_button.dart';
import '../widgets/auth_waveform_watermark.dart';
import '../widgets/hakkiri_logo.dart';
import 'assessment_intro_screen.dart';
import 'login_screen.dart';

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

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSignup() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AssessmentIntroScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBF9),
      body: SafeArea(
        child: Stack(
          children: [
            // Ambient Top-Right Soundwave Watermark
            Positioned(
              top: 30,
              right: 16,
              child: const AuthWaveformWatermark(width: 140, height: 160),
            ),

            // Main Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Centered Official Hakkiri Brand Mark
                  Center(
                    child: const HakkiriLogo(
                      variant: HakkiriLogoVariant.fullImage,
                      size: 96,
                    ),
                  ),
                  const SizedBox(height: 28),

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
                    label: 'Create account',
                    onTap: _handleSignup,
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

                  // Social Auth Buttons (Apple & Google)
                  Row(
                    children: [
                      Expanded(
                        child: _buildSocialButton(
                          label: 'Apple',
                          icon: Icons.apple_rounded,
                          onTap: _handleSignup,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildSocialButton(
                          label: 'Google',
                          isGoogle: true,
                          onTap: _handleSignup,
                        ),
                      ),
                    ],
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
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEAE9E2), width: 1.2),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isGoogle)
                const Text(
                  'G',
                  style: TextStyle(
                    color: Color(0xFF4285F4),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                )
              else if (icon != null)
                Icon(icon, color: Colors.black, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
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
