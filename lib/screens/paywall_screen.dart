import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/app_state_provider.dart';
import '../widgets/hakkiri_logo.dart';
import 'home_screen.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  String _selectedTier = 'annual_pro';

  void _onContinue() {
    final state = Provider.of<AppStateProvider>(context, listen: false);
    state.selectSubscription(_selectedTier);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF10111A), // Dark mode background as in Page 4
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const HakkiriLogo(
                    variant: HakkiriLogoVariant.compactMark,
                    size: 20,
                    isDark: true,
                  ),
                  GestureDetector(
                    onTap: _onContinue,
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ],
              ),

              // Content Area
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  // Title
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Colors.white,
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.0,
                        height: 1.15,
                      ),
                      children: [
                        TextSpan(text: 'Go all in on\n'),
                        TextSpan(
                          text: 'clarity.',
                          style: TextStyle(color: Color(0xFF5B6BFF)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Feature Points (01, 02, 03, 04)
                  _buildBenefitRow('01', 'Prompts written for Sales & Marketing'),
                  const SizedBox(height: 14),
                  _buildBenefitRow('02', 'Detailed feedback on every answer'),
                  const SizedBox(height: 14),
                  _buildBenefitRow('03', 'A plan that adapts each week'),
                  const SizedBox(height: 14),
                  _buildBenefitRow('04', 'Progress tracking and streaks'),

                  const SizedBox(height: 28),

                  // Pricing Options
                  // 1. Yearly Card (Selected)
                  GestureDetector(
                    onTap: () => setState(() => _selectedTier = 'annual_pro'),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161726),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _selectedTier == 'annual_pro'
                              ? const Color(0xFF4C5CFF)
                              : const Color(0xFF26283D),
                          width: _selectedTier == 'annual_pro' ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Yearly',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                '3 days free, then £69.99/yr',
                                style: TextStyle(
                                  color: Color(0xFFA0A3B5),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.coralBadge,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'SAVE 41%',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2. Monthly Card
                  GestureDetector(
                    onTap: () => setState(() => _selectedTier = 'monthly_pro'),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161726),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _selectedTier == 'monthly_pro'
                              ? const Color(0xFF4C5CFF)
                              : const Color(0xFF26283D),
                          width: _selectedTier == 'monthly_pro' ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Monthly',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                '£9.99/mo, cancel anytime',
                                style: TextStyle(
                                  color: Color(0xFFA0A3B5),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),
                  const Text(
                    'TRIAL INCLUDES 3 ACTIVITIES  ·  CANCEL BEFORE DAY 3',
                    style: TextStyle(
                      color: Color(0xFF787B8E),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),

              // Bottom Actions
              Column(
                children: [
                  // Light Button with Blue Arrow
                  SizedBox(
                    height: 56,
                    child: Material(
                      color: const Color(0xFFECEAE2),
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: _onContinue,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Start free trial',
                                style: TextStyle(
                                  color: Color(0xFF13141F),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: AppColors.royalBlue,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'No charge today',
                        style: TextStyle(color: Color(0xFF888B9E), fontSize: 12),
                      ),
                      const SizedBox(width: 14),
                      GestureDetector(
                        onTap: () {},
                        child: const Text(
                          'Restore purchase',
                          style: TextStyle(
                            color: Color(0xFFA5A9BF),
                            fontSize: 12,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      GestureDetector(
                        onTap: () {},
                        child: const Text(
                          'Terms',
                          style: TextStyle(
                            color: Color(0xFFA5A9BF),
                            fontSize: 12,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitRow(String num, String text) {
    return Row(
      children: [
        SizedBox(
          width: 28,
          child: Text(
            num,
            style: const TextStyle(
              color: Color(0xFF5B6BFF),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
