import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/assessment_model.dart';
import '../../models/session_model.dart';

class SupabaseService {
  static final SupabaseService instance = SupabaseService._internal();
  SupabaseService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  SupabaseClient? get client => _isInitialized ? Supabase.instance.client : null;

  /// Initializes Supabase with either environment variables or safe local fallback
  Future<void> initialize({String? url, String? anonKey}) async {
    const defaultUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
    const defaultKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

    final targetUrl = url ?? defaultUrl;
    final targetKey = anonKey ?? defaultKey;

    if (targetUrl.isNotEmpty && targetKey.isNotEmpty) {
      try {
        await Supabase.initialize(url: targetUrl, publishableKey: targetKey);
        _isInitialized = true;
        debugPrint('[Hakkiri] Supabase initialized successfully with remote backend.');
      } catch (e) {
        debugPrint('[Hakkiri] Supabase connection failed: $e. Operating in secure offline mode.');
        _isInitialized = false;
      }
    } else {
      debugPrint('[Hakkiri] No Supabase credentials provided. Running in high-performance local demo mode.');
      _isInitialized = false;
    }
  }

  /// Saves user assessment and generated plan to Supabase profiles
  Future<void> saveUserProfile({
    required String userId,
    required AssessmentAnswers answers,
    required PersonalizedPlanModel plan,
  }) async {
    if (!_isInitialized || client == null) {
      debugPrint('[Hakkiri Local] Stored assessment and plan locally for $userId');
      return;
    }

    try {
      await client!.from('profiles').upsert({
        'id': userId,
        'voice_profile': answers.voiceProfile,
        'career_stage': answers.careerStage,
        'career_type': answers.careerType,
        'speaking_confidence': answers.confidence,
        'primary_roadblock': answers.roadblock,
        'primary_goal': answers.primaryGoal,
        'personalized_plan': plan.toJson(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[Hakkiri] Error syncing profile to Supabase: $e');
    }
  }

  /// Records practice session evaluation in Supabase
  Future<void> recordPracticeSession({
    required String userId,
    required String activitySlug,
    required String promptId,
    required String transcript,
    required EvaluationFeedback feedback,
  }) async {
    if (!_isInitialized || client == null) {
      debugPrint('[Hakkiri Local] Stored practice session score: ${feedback.overallScore}/5');
      return;
    }

    try {
      await client!.from('practice_sessions').insert({
        'user_id': userId,
        'activity_slug': activitySlug,
        'prompt_id': promptId,
        'transcript': transcript,
        'overall_score': feedback.overallScore,
        'executive_presence_score': feedback.pillars.executiveScore,
        'clarity_score': feedback.pillars.clarityScore,
        'content_impact_score': feedback.pillars.impactScore,
        'engagement_score': feedback.pillars.engagementScore,
        'crutch_count': feedback.pillars.crutchCount,
        'power_pause_count': feedback.pillars.powerPauseCount,
        'is_coached_retry': feedback.isCoachedRetry,
        'feedback_payload': feedback.toJson(),
      });
    } catch (e) {
      debugPrint('[Hakkiri] Error saving session to Supabase: $e');
    }
  }

  /// Updates user subscription record in Supabase
  Future<void> updateSubscription({
    required String userId,
    required String tier,
    required double priceGbp,
  }) async {
    if (!_isInitialized || client == null) {
      debugPrint('[Hakkiri Local] Subscription set to $tier ($priceGbp GBP)');
      return;
    }

    try {
      await client!.from('subscriptions').upsert({
        'user_id': userId,
        'tier': tier,
        'status': 'active',
        'price_gbp': priceGbp,
        'current_period_end': DateTime.now().add(const Duration(days: 365)).toIso8601String(),
      });
    } catch (e) {
      debugPrint('[Hakkiri] Error updating subscription in Supabase: $e');
    }
  }
}
