import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/services/analytics_service.dart';
import '../providers/app_state_provider.dart';

class ChallengesScreen extends StatelessWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService.instance.logScreenView(screenName: 'ChallengesScreen');
    });

    final state = Provider.of<AppStateProvider>(context);
    final challenges = state.challenges;
    final featured = challenges.isNotEmpty ? challenges.first : null;
    final rest = challenges.length > 1 ? challenges.skip(1).toList() : const <Map<String, dynamic>>[];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => state.refreshFromApi(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'COMMUNICATION GYM  ·  WEEKLY SPRINTS',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.textPrimary,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.0,
                      height: 1.15,
                    ),
                    children: [
                      TextSpan(text: 'Challenges\n'),
                      TextSpan(
                        text: 'Build the reflex.',
                        style: TextStyle(color: AppColors.royalBlue),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                if (featured != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141522),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.royalBlue,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                (featured['tag'] ?? 'CHALLENGE').toString().toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            Text(
                              (featured['progress_label'] ?? '').toString().toUpperCase(),
                              style: const TextStyle(
                                color: Color(0xFFA0A3B5),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          (featured['title'] ?? '').toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          (featured['description'] ?? '').toString(),
                          style: const TextStyle(
                            color: Color(0xFF8E91A6),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: ((featured['progress_ratio'] as num?)?.toDouble() ?? 0)
                                .clamp(0.0, 1.0),
                            minHeight: 6,
                            backgroundColor: const Color(0xFF26283D),
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.royalBlue),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => state.joinChallengeFromApi(
                              (featured['slug'] ?? '').toString(),
                            ),
                            child: const Text(
                              'Join',
                              style: TextStyle(
                                color: Color(0xFF7A89FF),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  const Text(
                    'Challenges will appear after your account loads.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(height: 16),

                ...rest.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildChallengeCard(
                      title: (item['title'] ?? '').toString(),
                      tag: (item['tag'] ?? '').toString(),
                      description: (item['description'] ?? '').toString(),
                      progress: (item['progress_label'] ?? 'Ready to Start').toString(),
                      onJoin: () => state.joinChallengeFromApi((item['slug'] ?? '').toString()),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChallengeCard({
    required String title,
    required String tag,
    required String description,
    required String progress,
    required VoidCallback onJoin,
  }) {
    // Faizan card chrome (radius 16, tag/progress header) + Join for API.
    return Material(
      color: AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onJoin,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tag.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.royalBlue,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Text(
                    progress,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
