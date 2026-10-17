import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/services/analytics_service.dart';
import '../core/services/coach_tts_service.dart';
import '../providers/app_state_provider.dart';
import '../widgets/coach_character_svg.dart';

class CoachVoiceModel {
  final String id;
  final String name;
  final String title;
  final String description;
  final Color accentColor;
  final Color badgeBgColor;

  const CoachVoiceModel({
    required this.id,
    required this.name,
    required this.title,
    required this.description,
    required this.accentColor,
    required this.badgeBgColor,
  });
}

const List<CoachVoiceModel> kVoiceCoaches = [
  CoachVoiceModel(
    id: 'sarah',
    name: 'Sarah',
    title: 'Executive Clarity',
    description: 'Calm, poised and articulated with executive authority.',
    accentColor: Color(0xFF2563EB),
    badgeBgColor: Color(0xFFEFF6FF),
  ),
  CoachVoiceModel(
    id: 'david',
    name: 'David',
    title: 'Deep & Resonant',
    description: 'Strong, commanding presence that holds the room.',
    accentColor: Color(0xFF0F172A),
    badgeBgColor: Color(0xFFF1F5F9),
  ),
  CoachVoiceModel(
    id: 'elena',
    name: 'Elena',
    title: 'Warm & Inspiring',
    description: 'Expressive, engaging tone that connects emotionally.',
    accentColor: Color(0xFF059669),
    badgeBgColor: Color(0xFFECFDF5),
  ),
  CoachVoiceModel(
    id: 'marcus',
    name: 'Marcus',
    title: 'Dynamic & Sharp',
    description: 'Energetic, punchy cadence for high-impact communication.',
    accentColor: Color(0xFFDC2626),
    badgeBgColor: Color(0xFFFEF2F2),
  ),
  CoachVoiceModel(
    id: 'alex',
    name: 'Alex',
    title: 'Modern & Balanced',
    description: 'Contemporary, crisp delivery with natural rhythm.',
    accentColor: Color(0xFF7C3AED),
    badgeBgColor: Color(0xFFF5F3FF),
  ),
];

class VoiceCoachScreen extends StatefulWidget {
  const VoiceCoachScreen({super.key});

  @override
  State<VoiceCoachScreen> createState() => _VoiceCoachScreenState();
}

class _VoiceCoachScreenState extends State<VoiceCoachScreen> {
  String? _previewingId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService.instance.logScreenView(screenName: 'VoiceCoachScreen');
    });
  }

  @override
  void dispose() {
    CoachTtsService.instance.stop();
    super.dispose();
  }

  String _currentCoachId(AppStateProvider state) {
    final raw = (state.answers.voiceProfile ?? 'sarah').toLowerCase().trim();
    if (raw == 'female') return 'sarah';
    if (raw == 'male') return 'david';
    if (raw == 'non_binary') return 'alex';
    return raw;
  }

  Future<void> _playPreview(String coachId) async {
    setState(() => _previewingId = coachId);
    try {
      await CoachTtsService.instance.previewCoach(coachId);
    } finally {
      if (mounted) setState(() => _previewingId = null);
    }
  }

  void _showCoachSelectedToast(CoachVoiceModel coach) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        padding: EdgeInsets.zero,
        duration: const Duration(milliseconds: 2500),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: coach.accentColor.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: coach.accentColor.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Coach Avatar with check badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CoachCharacterAvatar(
                    coachId: coach.id,
                    size: 44,
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              // Coach Name, title badge, and description
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          coach.name,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: coach.badgeBgColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            coach.title,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: coach.accentColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Selected as your active voice coach',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Right check icon indicator
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFFECFDF5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Color(0xFF059669),
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectCoach(AppStateProvider state, String coachId) {
    final coach = kVoiceCoaches.firstWhere(
      (c) => c.id == coachId,
      orElse: () => kVoiceCoaches.first,
    );

    // Save active coach in CoachTtsService & local storage
    CoachTtsService.instance.setActiveCoach(coach.id);

    // 1. Immediately show beautiful toast with 0 delay
    _showCoachSelectedToast(coach);

    // 2. Play the coach's audio preview sample
    _playPreview(coachId);

    // 3. Update the provider in the background
    state.updateVoiceProfile(coachId).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final activeId = _currentCoachId(state);

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBF9),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Icon(
                        Icons.chevron_left_rounded,
                        color: Color(0xFF0F172A),
                        size: 26,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Voice Coach',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Select your personalized speaking guide',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // 5 Coach Cards Grid
            Expanded(
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                itemCount: kVoiceCoaches.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final coach = kVoiceCoaches[index];
                  final isSelected = coach.id == activeId;
                  final isPlaying = _previewingId == coach.id;

                  return _buildCoachCard(
                    coach: coach,
                    isSelected: isSelected,
                    isPlaying: isPlaying,
                    onSelect: () => _selectCoach(state, coach.id),
                    onPreview: () {
                      if (isPlaying) {
                        CoachTtsService.instance.stop();
                        setState(() => _previewingId = null);
                      } else {
                        _playPreview(coach.id);
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoachCard({
    required CoachVoiceModel coach,
    required bool isSelected,
    required bool isPlaying,
    required VoidCallback onSelect,
    required VoidCallback onPreview,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? AppColors.royalBlue : const Color(0xFFE2E8F0),
          width: isSelected ? 2.0 : 1.0,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.royalBlue.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onSelect,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Character SVG Avatar
                Stack(
                  children: [
                    CoachCharacterAvatar(
                      coachId: coach.id,
                      size: 72,
                    ),
                    if (isSelected)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: AppColors.royalBlue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 13,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),

                // Name, Title, and Description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            coach.name,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: coach.badgeBgColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              coach.title,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: coach.accentColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        coach.description,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Listen / Preview Button
                GestureDetector(
                  onTap: onPreview,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isPlaying
                          ? AppColors.royalBlue
                          : const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPlaying
                          ? Icons.stop_rounded
                          : Icons.volume_up_rounded,
                      color: isPlaying ? Colors.white : const Color(0xFF475569),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
