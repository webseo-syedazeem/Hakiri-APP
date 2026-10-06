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
  String _selectedTier = 'annual_pro'; // 'annual_pro' or 'monthly'

  void _onContinue() {
    final state = Provider.of<AppStateProvider>(context, listen: false);
    state.selectSubscription(_selectedTier);

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090A10),
      body: Stack(
        children: [
          // Ambient Dark Waves Background matching Figma
          const Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _PaywallWaveBackgroundPainter(),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const HakkiriLogo(
                        variant: HakkiriLogoVariant.paywallDarkLockup,
                        size: 28,
                      ),
                      GestureDetector(
                        onTap: _onContinue,
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

                  // Scrollable Content
                  Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tag
                      const Text(
                        'HAKKIRI PRO',
                        style: TextStyle(
                          color: Color(0xFF5B6BFF),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Headline: "Keep improving every day."
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.0,
                            height: 1.15,
                          ),
                          children: [
                            TextSpan(text: 'Keep improving\n'),
                            TextSpan(
                              text: 'every day.',
                              style: TextStyle(color: Color(0xFF4E75FF)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 5 Feature Points with circular icons
                      _buildFeatureRow(
                        icon: Icons.article_outlined,
                        title: 'New prompts every day',
                        subtitle: 'Matched to your goals and challenges',
                      ),
                      const SizedBox(height: 14),

                      _buildFeatureRow(
                        icon: Icons.chat_bubble_outline_rounded,
                        title: 'Specific feedback after every answer',
                        subtitle: "Understand what's working and how to improve",
                      ),
                      const SizedBox(height: 14),

                      _buildFeatureRow(
                        icon: Icons.tune_rounded,
                        title: 'A plan that adapts each week',
                        subtitle: 'Personalised to your progress',
                      ),
                      const SizedBox(height: 14),

                      _buildFeatureRow(
                        icon: Icons.bar_chart_rounded,
                        title: 'More exercises, every level',
                        subtitle: 'From everyday conversations to high-stakes moments',
                      ),
                      const SizedBox(height: 14),

                      _buildFeatureRow(
                        icon: Icons.track_changes_rounded,
                        title: 'Progress tracking and streaks',
                        subtitle: 'Stay consistent and see real improvement',
                      ),
                      const SizedBox(height: 24),

                      // Pricing Options
                      // 1. Yearly Card
                      _buildPlanCard(
                        id: 'annual_pro',
                        title: 'Yearly',
                        subtitle: '£5.83 per month',
                        priceText: '£69.99/yr',
                        badgeText: 'SAVE 41%',
                        isSelected: _selectedTier == 'annual_pro',
                      ),
                      const SizedBox(height: 12),

                      // 2. Monthly Card
                      _buildPlanCard(
                        id: 'monthly',
                        title: 'Monthly',
                        subtitle: '£9.99 per month',
                        priceText: '£9.99/mo',
                        isSelected: _selectedTier == 'monthly',
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // Bottom Continue to Pro Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: Material(
                  color: AppColors.royalBlue,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: _onContinue,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Spacer(),
                          Text(
                            'Continue to Pro',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Spacer(),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Footer Links
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildFooterLink('Restore purchase'),
                  const Text('  ·  ', style: TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                  _buildFooterLink('Terms'),
                  const Text('  ·  ', style: TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                  _buildFooterLink('Privacy'),
                ],
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    ],
  ),
);
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF161928),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: const Color(0xFF8B95B8), size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF8B92A8),
                  fontSize: 12,
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
  }) {
    return GestureDetector(
      onTap: () => setState(() => _selectedTier = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF141624),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF23263B),
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          children: [
            // Radio Circle
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.royalBlue : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppColors.royalBlue : const Color(0xFF4B5563),
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: isSelected
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: 14),

            // Plan Info
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
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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

            // Price Text
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

  Widget _buildFooterLink(String text) {
    return GestureDetector(
      onTap: () {},
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

class _PaywallWaveBackgroundPainter extends CustomPainter {
  const _PaywallWaveBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Deep midnight base background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF090A10),
    );

    // 2. Ambient radial glow in top right
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.70, -0.75),
        radius: 0.95,
        colors: [
          const Color(0xFF2B4EA6).withValues(alpha: 0.35),
          const Color(0xFF1B326E).withValues(alpha: 0.16),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.55));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height * 0.55), glowPaint);

    // 3. Layer 1: Upper Dark-Blue Wave Swoosh behind close button
    final wave1Paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          const Color(0xFF223A74).withValues(alpha: 0.88),
          const Color(0xFF142244).withValues(alpha: 0.65),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.30));

    final path1 = Path();
    path1.moveTo(size.width * 0.36, 0);
    path1.cubicTo(
      size.width * 0.32,
      size.height * 0.08,
      size.width * 0.58,
      size.height * 0.16,
      size.width,
      size.height * 0.18,
    );
    path1.lineTo(size.width, 0);
    path1.close();
    canvas.drawPath(path1, wave1Paint);

    // 4. Layer 2: Concentric Lower Dark-Navy Wave Swoosh behind headline
    final wave2Paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          const Color(0xFF182952).withValues(alpha: 0.75),
          const Color(0xFF0E1730).withValues(alpha: 0.55),
        ],
      ).createShader(Rect.fromLTWH(0, size.height * 0.10, size.width, size.height * 0.32));

    final path2 = Path();
    path2.moveTo(size.width * 0.48, size.height * 0.12);
    path2.cubicTo(
      size.width * 0.32,
      size.height * 0.20,
      size.width * 0.44,
      size.height * 0.30,
      size.width,
      size.height * 0.34,
    );
    path2.lineTo(size.width, size.height * 0.18);
    path2.cubicTo(
      size.width * 0.58,
      size.height * 0.16,
      size.width * 0.32,
      size.height * 0.08,
      size.width * 0.36,
      0,
    );
    path2.lineTo(size.width, 0);
    path2.close();
    canvas.drawPath(path2, wave2Paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

