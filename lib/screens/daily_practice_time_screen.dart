import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/services/analytics_service.dart';
import '../providers/app_state_provider.dart';
import '../widgets/hakkiri_loading_overlay.dart';

/// Screen matching media_1792409612602_be4a37ae.png
/// "Daily practice: How much time do you have?"
class DailyPracticeTimeScreen extends StatefulWidget {
  const DailyPracticeTimeScreen({super.key});

  @override
  State<DailyPracticeTimeScreen> createState() => _DailyPracticeTimeScreenState();
}

class _DailyPracticeTimeScreenState extends State<DailyPracticeTimeScreen> {
  late int _selectedMinutes;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final state = Provider.of<AppStateProvider>(context, listen: false);
    final current = state.dailyAnchorMinutes;
    _selectedMinutes = [5, 10, 15].contains(current) ? current : 10;
    AnalyticsService.instance.logScreenView(screenName: 'DailyPracticeTimeScreen');
  }

  Future<void> _saveChanges() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final state = Provider.of<AppStateProvider>(context, listen: false);
      await HakkiriLoadingOverlay.run(
        context,
        message: 'Updating plan…',
        detail: 'Setting your daily plan to $_selectedMinutes minutes.',
        action: () async {
          await state.updateDailyAnchorMinutes(_selectedMinutes);
        },
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      // Fallback: apply locally in provider even if offline
      Provider.of<AppStateProvider>(context, listen: false).setDailyMinutesLocal(_selectedMinutes);
      Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBF9),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar: Back chevron on left, "Daily practice" centered
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(
                        Icons.chevron_left_rounded,
                        color: Color(0xFF0F172A),
                        size: 32,
                      ),
                      onPressed: () => Navigator.pop(context),
                      splashRadius: 24,
                    ),
                  ),
                  const Text(
                    'Daily practice',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero Section: Stopwatch Squircle + Headline
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Squircle Icon Badge with Radiating Blue Rays
                        Container(
                          width: 62,
                          height: 62,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: const Color(0xFFDBEAFE),
                              width: 1.2,
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            clipBehavior: Clip.none,
                            children: [
                              const Icon(
                                Icons.timer_outlined,
                                color: Color(0xFF2563EB),
                                size: 30,
                              ),
                              Positioned(
                                top: 7,
                                right: 7,
                                child: CustomPaint(
                                  size: const Size(14, 14),
                                  painter: _RaysPainter(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Title: "How much time\ndo you have?"
                        Expanded(
                          child: RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 27,
                                fontWeight: FontWeight.w900,
                                height: 1.15,
                                letterSpacing: -0.6,
                              ),
                              children: [
                                TextSpan(
                                  text: 'How much time\n',
                                  style: TextStyle(color: Color(0xFF0F172A)),
                                ),
                                TextSpan(
                                  text: 'do you have?',
                                  style: TextStyle(color: Color(0xFF2563EB)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Subtitle
                    const Text(
                      'Choose how much time you have today. Hakkiri will build your Today plan around it, with at least 3 exercises. You\'ll receive personalised feedback after every exercise.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13.5,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF64748B),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Option 1: 5 minutes (Quick practice)
                    _buildDurationOptionCard(
                      minutes: 5,
                      title: '5 minutes',
                      subtitle1: 'Quick practice',
                      subtitle2: '3 focused exercises',
                      iconBgColor: const Color(0xFFDCFCE7),
                      iconColor: const Color(0xFF16A34A),
                      icon: Icons.speed_rounded,
                    ),
                    const SizedBox(height: 14),

                    // Option 2: 10 minutes (Balanced practice)
                    _buildDurationOptionCard(
                      minutes: 10,
                      title: '10 minutes',
                      subtitle1: 'Balanced practice',
                      subtitle2: '3+ exercises with targeted retries',
                      iconBgColor: const Color(0xFFEFF6FF),
                      iconColor: const Color(0xFF2563EB),
                      icon: Icons.timer_outlined,
                      showRays: true,
                    ),
                    const SizedBox(height: 14),

                    // Option 3: 15 minutes (Deeper practice)
                    _buildDurationOptionCard(
                      minutes: 15,
                      title: '15 minutes',
                      subtitle1: 'Deeper practice',
                      subtitle2: 'More exercises, retries and\ntougher challenges',
                      iconBgColor: const Color(0xFFFFEDE8),
                      iconColor: const Color(0xFFF95B3D),
                      icon: Icons.auto_graph_rounded,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Bottom Save Changes Pill Button matching media_1792409612602_be4a37ae.png
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
              child: GestureDetector(
                onTap: _saving ? null : _saveChanges,
                child: Container(
                  height: 56,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(),
                      Text(
                        _saving ? 'Saving…' : 'Save changes',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const Spacer(),
                      // Blue Circular Arrow Button on Right
                      Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2563EB),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationOptionCard({
    required int minutes,
    required String title,
    required String subtitle1,
    required String subtitle2,
    required Color iconBgColor,
    required Color iconColor,
    required IconData icon,
    bool showRays = false,
  }) {
    final isSelected = _selectedMinutes == minutes;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMinutes = minutes;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF8FAFF) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF2563EB).withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: isSelected ? 10 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left Squircle Icon
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, color: iconColor, size: 28),
                  if (showRays)
                    Positioned(
                      top: 7,
                      right: 7,
                      child: CustomPaint(
                        size: const Size(12, 12),
                        painter: _RaysPainter(),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 14),

            // Text Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle1,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle2,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Right Radio Circle
            if (isSelected)
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  color: Color(0xFF2563EB),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 17,
                ),
              )
            else
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFCBD5E1),
                    width: 2.0,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RaysPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2563EB)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // Ray 1
    canvas.drawLine(const Offset(2, 6), const Offset(6, 2), paint);
    // Ray 2
    canvas.drawLine(const Offset(6, 9), const Offset(11, 7), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
