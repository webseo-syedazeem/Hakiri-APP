import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'crashlytics_service.dart';

/// Centralized Firebase Analytics Service for Hakkiri.
/// Tracks navigation, user lifecycle, onboarding, assessment,
/// practice drills, debate sessions, subscriptions, and gamification events.
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  FirebaseAnalytics? _analytics;
  FirebaseAnalyticsObserver? _observer;
  bool _initialized = false;

  bool get isReady => _initialized && _analytics != null;

  /// Returns the navigation observer for MaterialApp.
  FirebaseAnalyticsObserver get observer {
    _observer ??= FirebaseAnalyticsObserver(
      analytics: _analytics ?? FirebaseAnalytics.instance,
    );
    return _observer!;
  }

  /// Initializes Firebase Analytics and enables collection.
  Future<void> init() async {
    try {
      _analytics = FirebaseAnalytics.instance;
      await _analytics!.setAnalyticsCollectionEnabled(true);
      _observer = FirebaseAnalyticsObserver(analytics: _analytics!);
      _initialized = true;
      debugPrint('[Analytics] Firebase Analytics initialized.');
    } catch (e, st) {
      debugPrint('[Analytics] Initialization error: $e\n$st');
    }
  }

  /// Logs a screen view.
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    if (!_initialized || _analytics == null) return;
    try {
      await _analytics!.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
      );
      CrashlyticsService.instance.log('ScreenView: $screenName');
      CrashlyticsService.instance.setCustomKey('last_screen', screenName);
    } catch (e) {
      debugPrint('[Analytics] logScreenView error: $e');
    }
  }

  /// Sets the user identifier across Analytics and Crashlytics.
  Future<void> setUserId(String? userId) async {
    if (!_initialized || _analytics == null) return;
    try {
      await _analytics!.setUserId(id: userId);
      await CrashlyticsService.instance.setUserId(userId);
    } catch (e) {
      debugPrint('[Analytics] setUserId error: $e');
    }
  }

  /// Sets a user property.
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    if (!_initialized || _analytics == null) return;
    try {
      await _analytics!.setUserProperty(name: name, value: value);
      if (value != null) {
        CrashlyticsService.instance.setCustomKey(name, value);
      }
    } catch (e) {
      debugPrint('[Analytics] setUserProperty error: $e');
    }
  }

  /// Syncs core user attributes upon login or session restore.
  Future<void> syncUserProfile({
    required String userId,
    String? email,
    String? careerType,
    String? subscriptionTier,
    int? streak,
    int? xp,
  }) async {
    await setUserId(userId);
    if (careerType != null && careerType.isNotEmpty) {
      await setUserProperty(name: 'career_type', value: careerType);
    }
    if (subscriptionTier != null && subscriptionTier.isNotEmpty) {
      await setUserProperty(name: 'subscription_tier', value: subscriptionTier);
    }
    if (streak != null) {
      await setUserProperty(name: 'streak_days', value: streak.toString());
    }
    if (xp != null) {
      await setUserProperty(name: 'total_xp', value: xp.toString());
    }
  }

  // ---------------- AUTH EVENTS ----------------

  Future<void> logLogin({required String method}) async {
    if (!_initialized || _analytics == null) return;
    try {
      await _analytics!.logLogin(loginMethod: method);
      CrashlyticsService.instance.log('Auth: Logged in via $method');
    } catch (e) {
      debugPrint('[Analytics] logLogin error: $e');
    }
  }

  Future<void> logSignUp({required String method}) async {
    if (!_initialized || _analytics == null) return;
    try {
      await _analytics!.logSignUp(signUpMethod: method);
      CrashlyticsService.instance.log('Auth: Signed up via $method');
    } catch (e) {
      debugPrint('[Analytics] logSignUp error: $e');
    }
  }

  Future<void> logLogout() async {
    if (!_initialized || _analytics == null) return;
    try {
      await logEvent(name: 'user_logout');
      await setUserId(null);
      CrashlyticsService.instance.log('Auth: User logged out');
    } catch (e) {
      debugPrint('[Analytics] logLogout error: $e');
    }
  }

  // ---------------- ONBOARDING & TUTORIAL ----------------

  Future<void> logOnboardingStarted() async {
    await logEvent(name: 'onboarding_started');
  }

  Future<void> logOnboardingPage({
    required int pageIndex,
    required String pageName,
  }) async {
    await logEvent(
      name: 'onboarding_step',
      parameters: {
        'page_index': pageIndex,
        'page_name': pageName,
      },
    );
  }

  Future<void> logOnboardingCompleted() async {
    await logEvent(name: 'onboarding_completed');
  }

  // ---------------- ASSESSMENT ----------------

  Future<void> logAssessmentStarted() async {
    await logEvent(name: 'assessment_started');
  }

  Future<void> logAssessmentStep({
    required int step,
    required String questionKey,
    required String answer,
  }) async {
    await logEvent(
      name: 'assessment_step',
      parameters: {
        'step': step,
        'question_key': questionKey,
        'answer': answer,
      },
    );
  }

  Future<void> logAssessmentCompleted({
    required String careerType,
    required String confidence,
    String? primaryRoadblock,
  }) async {
    await logEvent(
      name: 'assessment_completed',
      parameters: {
        'career_type': careerType,
        'confidence': confidence,
        if (primaryRoadblock != null) 'roadblock': primaryRoadblock,
      },
    );
  }

  // ---------------- PRACTICE & DRILL SESSIONS ----------------

  Future<void> logPracticeStarted({
    required String activitySlug,
    required String activityName,
    String? promptTitle,
    String? difficulty,
  }) async {
    await logEvent(
      name: 'practice_drill_started',
      parameters: {
        'activity_slug': activitySlug,
        'activity_name': activityName,
        if (promptTitle != null) 'prompt_title': promptTitle,
        if (difficulty != null) 'difficulty': difficulty,
      },
    );
    CrashlyticsService.instance.log('DrillStarted: $activitySlug ($difficulty)');
  }

  Future<void> logPracticeCompleted({
    required String activitySlug,
    required String activityName,
    required int durationSeconds,
    required int overallScore,
    int? executiveScore,
    int? clarityScore,
    int? impactScore,
    int? engagementScore,
    bool isRetry = false,
  }) async {
    await logEvent(
      name: 'practice_drill_completed',
      parameters: {
        'activity_slug': activitySlug,
        'activity_name': activityName,
        'duration_seconds': durationSeconds,
        'overall_score': overallScore,
        if (executiveScore != null) 'executive_score': executiveScore,
        if (clarityScore != null) 'clarity_score': clarityScore,
        if (impactScore != null) 'impact_score': impactScore,
        if (engagementScore != null) 'engagement_score': engagementScore,
        'is_retry': isRetry ? 1 : 0,
      },
    );
    CrashlyticsService.instance.log(
      'DrillCompleted: $activitySlug, Score: $overallScore/5, Duration: ${durationSeconds}s',
    );
  }

  Future<void> logPracticeRetry({required String activitySlug}) async {
    await logEvent(
      name: 'practice_drill_retry',
      parameters: {'activity_slug': activitySlug},
    );
  }

  // ---------------- VOICE PRACTICE / DEBATE ----------------

  Future<void> logLiveVoiceStarted() async {
    await logEvent(name: 'live_voice_started');
    CrashlyticsService.instance.log('LiveVoice: Started live session');
  }

  Future<void> logLiveVoiceEnded({
    required int durationSeconds,
    int messageCount = 0,
  }) async {
    await logEvent(
      name: 'live_voice_ended',
      parameters: {
        'duration_seconds': durationSeconds,
        'message_count': messageCount,
      },
    );
    CrashlyticsService.instance.log(
      'LiveVoice: Ended (${durationSeconds}s, $messageCount msgs)',
    );
  }

  // ---------------- GAMIFICATION & NAVIGATION ----------------

  Future<void> logTabSelected({
    required int tabIndex,
    required String tabName,
  }) async {
    await logEvent(
      name: 'tab_nav_click',
      parameters: {
        'tab_index': tabIndex,
        'tab_name': tabName,
      },
    );
    CrashlyticsService.instance.setCustomKey('active_tab', tabName);
  }

  Future<void> logStreakFreezeUsed({required int remainingFreezes}) async {
    await logEvent(
      name: 'streak_freeze_used',
      parameters: {'remaining_freezes': remainingFreezes},
    );
  }

  Future<void> logChallengeJoined({required String challengeSlug}) async {
    await logEvent(
      name: 'challenge_joined',
      parameters: {'challenge_slug': challengeSlug},
    );
  }

  Future<void> logDailyAnchorCompleted({required int minutes}) async {
    await logEvent(
      name: 'daily_anchor_completed',
      parameters: {'minutes': minutes},
    );
  }

  // ---------------- SUBSCRIPTION / PAYWALL ----------------

  Future<void> logViewPaywall({String source = 'app'}) async {
    await logEvent(
      name: 'view_paywall',
      parameters: {'source': source},
    );
    CrashlyticsService.instance.log('Paywall: Viewed from $source');
  }

  Future<void> logSelectPlan({
    required String planId,
    required String price,
  }) async {
    await logEvent(
      name: 'select_subscription_plan',
      parameters: {
        'plan_id': planId,
        'price': price,
      },
    );
    CrashlyticsService.instance.log('Paywall: Selected plan $planId ($price)');
  }

  // ---------------- SETTINGS & PROFILE ----------------

  Future<void> logProfileUpdated() async {
    await logEvent(name: 'profile_updated');
  }

  Future<void> logSettingChanged({
    required String settingName,
    required dynamic value,
  }) async {
    await logEvent(
      name: 'setting_changed',
      parameters: {
        'setting': settingName,
        'value': value.toString(),
      },
    );
  }

  // ---------------- GENERIC EVENT ----------------

  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    if (!_initialized || _analytics == null) return;
    try {
      await _analytics!.logEvent(
        name: name,
        parameters: parameters,
      );
    } catch (e) {
      debugPrint('[Analytics] logEvent ($name) error: $e');
    }
  }
}
