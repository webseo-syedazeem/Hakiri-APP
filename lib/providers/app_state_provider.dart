import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/assessment_model.dart';
import '../models/activity_model.dart';
import '../models/session_model.dart';
import '../core/services/analytics_service.dart';
import '../core/services/apple_auth_service.dart';
import '../core/services/coach_tts_service.dart';
import '../core/services/google_auth_service.dart';
import '../core/services/hakkiri_api_service.dart';
import '../core/services/push_notification_service.dart';
import '../core/services/session_audio_store.dart';
import '../core/services/speech_evaluator_service.dart';
import '../core/services/supabase_service.dart';

class ReflectionNote {
  final String id;
  final DateTime date;
  final String title;
  final String learnings;
  final String focusArea;

  const ReflectionNote({
    required this.id,
    required this.date,
    required this.title,
    required this.learnings,
    required this.focusArea,
  });
}

class AppStateProvider extends ChangeNotifier {
  final SupabaseService _supabase = SupabaseService.instance;
  final HakkiriApiService _api = HakkiriApiService.instance;
  final Uuid _uuid = const Uuid();

  String userId = '';
  String fullName = '';
  String email = '';
  bool isOnboarded = false;
  bool isLoggedIn = false;
  bool isBootstrapping = false;
  /// False until the first home bootstrap finishes (shows shimmer, not placeholder data).
  bool hasBootstrapped = false;

  // Assessment State
  final AssessmentAnswers answers = AssessmentAnswers();
  PersonalizedPlanModel? personalizedPlan;

  // Subscription State
  String subscriptionTier = 'free_trial';
  String subscriptionStatus = 'expired';
  String subscriptionPriceFormatted = 'No active plan';
  String subscriptionRenewalLabel = '';
  bool isSubscribed = false;

  // Settings
  int dailyAnchorMinutes = 5;
  String audioPrivacy = 'encrypted_on_device';
  bool remindersEnabled = true;
  String focusLine = 'Go blank less, land the point sooner.';

  // Gamification (Enforcing fair scoring: XP & streaks separate from skill scores)
  int currentStreak = 0;
  int longestStreak = 0;
  int streakFreezeCount = 0;
  int totalXp = 0;
  int completedSessions = 0;
  String? lastPracticeDate;

  // Analytics snapshot from /dashboard
  double? overallAverage;
  int overallSamples = 0;
  Map<String, dynamic> pillarStats = {};
  List<Map<String, dynamic>> activityBreakdown = [];
  List<Map<String, dynamic>> challenges = [];
  List<Map<String, dynamic>> todayQueue = [];
  Map<String, dynamic>? todayPrimary;

  // Practice & Debate History
  final List<PracticeSessionRecord> sessionHistory = [];

  List<PracticeSessionRecord> get debateHistory =>
      sessionHistory.where((s) => s.activitySlug == 'debate_me').toList();

  // Activities Catalog (7 MVP activities)
  late List<ActivityModel> activities;
  late List<PromptModel> promptBank;

  ActivityModel? selectedActivity;
  PromptModel? selectedPrompt;
  String selectedDifficulty = 'beginner';

  // Last evaluation feedback
  EvaluationFeedback? latestFeedback;
  /// Most recent scored drill (for feedback playback + Progress reopen).
  PracticeSessionRecord? latestSession;

  static const careerLabels = {
    'corporate_finance': 'Corporate & Finance',
    'tech_product': 'Tech, Engineering & Product',
    'sales_marketing': 'Sales & Marketing',
    'healthcare_edu': 'Healthcare & Education',
    'other': 'Other',
    'general': 'General',
  };

  static const careerStageLabels = {
    'early': 'Student / Early career',
    'mid_level': 'Mid-level professional',
    'exec': 'Senior executive / Founder',
    'self_learner': 'General self-learner',
  };

  static const confidenceLabels = {
    'not_very': 'Not very confident',
    'fairly': 'Fairly confident',
    'very': 'Very confident',
  };

  static const roadblockLabels = {
    'blank_pressure': 'I go blank under pressure',
    'too_long': 'I take too long to get to the point',
    'filler_rush': 'I rush or use too many filler words',
    'explain_simple': 'I struggle to explain things simply',
    'keep_engaged': 'I struggle to keep people engaged',
    'lose_confidence': 'I lose confidence when challenged',
  };

  static const goalLabels = {
    'authority': 'Speak with more authority and executive presence',
    'calmer_confident': 'Feel calmer and more confident under pressure',
    'persuasive_arguments': 'Build clear, persuasive arguments on the spot',
    'clear_daily': 'Speak more clearly in everyday conversations',
    'keep_engaged': 'Keep people engaged and make an impact',
  };

  static const voiceLabels = {
    'sarah': 'Sarah',
    'david': 'David',
    'elena': 'Elena',
    'marcus': 'Marcus',
    'alex': 'Alex',
    // Backward compatibility aliases
    'female': 'Sarah',
    'male': 'David',
    'non_binary': 'Alex',
  };

  String get careerTypeLabel =>
      careerLabels[answers.careerType] ?? answers.careerType ?? 'Not set';

  String get careerStageLabel =>
      careerStageLabels[answers.careerStage] ?? answers.careerStage ?? 'Not set';

  String get confidenceLabel =>
      confidenceLabels[answers.confidence] ?? answers.confidence ?? 'Not set';

  String get roadblockLabel =>
      roadblockLabels[answers.roadblock] ?? answers.roadblock ?? 'Not set';

  String get primaryGoalLabel =>
      goalLabels[answers.primaryGoal] ?? answers.primaryGoal ?? 'Not set';

  String get voiceProfileLabel =>
      voiceLabels[answers.voiceProfile] ?? answers.voiceProfile ?? 'Not set';

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return 'H';
    final list = parts.toList();
    if (list.length == 1) return list.first.substring(0, 1).toUpperCase();
    return '${list.first.substring(0, 1)}${list.last.substring(0, 1)}'.toUpperCase();
  }

  String get subscriptionTitle {
    switch (subscriptionTier) {
      case 'annual_pro':
        return 'HAKKIRI PRO · YEARLY';
      case 'monthly_pro':
        return 'HAKKIRI PRO · MONTHLY';
      default:
        return 'HAKKIRI · FREE TRIAL';
    }
  }

  int get practiceDaysThisWeek {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final days = <String>{};
    for (final session in sessionHistory) {
      final day = DateTime(
        session.timestamp.year,
        session.timestamp.month,
        session.timestamp.day,
      );
      if (!day.isBefore(monday)) {
        days.add('${day.year}-${day.month}-${day.day}');
      }
    }
    if (days.isEmpty && currentStreak > 0) {
      return currentStreak.clamp(0, 7);
    }
    return days.length.clamp(0, 7);
  }

  List<String> get todayDrillSlugs {
    final slugs = <String>[];
    final primarySlug = todayPrimary?['activity'] is Map
        ? (todayPrimary!['activity']['slug'] ?? '').toString()
        : '';
    if (primarySlug.isNotEmpty) slugs.add(primarySlug);
    for (final item in todayQueue) {
      final activity = item['activity'];
      final slug = activity is Map ? (activity['slug'] ?? '').toString() : '';
      if (slug.isNotEmpty && !slugs.contains(slug)) slugs.add(slug);
    }
    if (slugs.isEmpty) {
      return personalizedPlan?.initialDrills ??
          const ['think_fast', 'cut_it_in_half', 'debate_me'];
    }
    return slugs;
  }

  final List<ReflectionNote> _reflectionNotes = [
    ReflectionNote(
      id: 'ref-1',
      date: DateTime(2026, 10, 18),
      title: 'I was more confident',
      learnings: 'I communicated my ideas more clearly today.',
      focusArea: 'Build my confidence',
    ),
    ReflectionNote(
      id: 'ref-2',
      date: DateTime(2026, 10, 10),
      title: 'Focus on structure',
      learnings: 'Next time I want to slow down and organise my points.',
      focusArea: 'Be more concise',
    ),
    ReflectionNote(
      id: 'ref-3',
      date: DateTime(2026, 10, 3),
      title: 'More engaging',
      learnings: 'I kept people with me and used better examples.',
      focusArea: 'Tell better stories',
    ),
  ];

  List<ReflectionNote> get reflectionNotes => List.unmodifiable(_reflectionNotes);

  void addReflectionNote({
    required String title,
    required String learnings,
    required String focusArea,
  }) {
    final note = ReflectionNote(
      id: 'ref-${DateTime.now().millisecondsSinceEpoch}',
      date: DateTime.now(),
      title: title.trim().isEmpty ? 'Daily Reflection' : title.trim(),
      learnings: learnings.trim(),
      focusArea: focusArea.trim(),
    );
    _reflectionNotes.insert(0, note);
    notifyListeners();
  }

  bool isTargetedRetryCompletedToday = false;
  bool isTougherChallengeCompletedToday = false;
  /// Server daily_anchor.plan (phase, weakest, totals).
  Map<String, dynamic> todayPlan = {};
  /// Set before launching a 10/15 bonus exercise: targeted_retry | tougher_challenge.
  String? pendingPlanExtra;

  void setDailyMinutesLocal(int minutes) {
    if ([5, 10, 15].contains(minutes)) {
      dailyAnchorMinutes = minutes;
      notifyListeners();
    }
  }

  void setPendingPlanExtra(String? extra) {
    pendingPlanExtra = extra;
    notifyListeners();
  }

  void _applyDailyPlan(Map<String, dynamic>? plan) {
    todayPlan = plan == null ? {} : Map<String, dynamic>.from(plan);
    if (todayPlan.isEmpty) return;
    final minutes = (todayPlan['minutes'] as num?)?.round();
    if (minutes != null && [5, 10, 15].contains(minutes)) {
      dailyAnchorMinutes = minutes;
    }
    final extras = (todayPlan['extras_completed'] as Map?) ?? {};
    isTargetedRetryCompletedToday = extras['targeted_retry'] == true;
    isTougherChallengeCompletedToday = extras['tougher_challenge'] == true;
  }

  String get todayPlanPhase =>
      (todayPlan['phase'] ?? 'core').toString();

  bool get isCorePlanComplete {
    final fromApi = (todayPlan['core_completed'] as num?)?.round();
    if (fromApi != null) return fromApi >= 3;
    return completedTodayDrills() >= 3;
  }

  bool get isFullPlanComplete {
    if (todayPlanPhase == 'complete') return true;
    return completedTotalActivitiesToday() >= totalTodayActivitiesCount();
  }

  bool get shouldOfferPlanExtras =>
      isCorePlanComplete &&
      dailyAnchorMinutes >= 10 &&
      !isFullPlanComplete;

  int completedTodayDrills() {
    final fromApi = (todayPlan['core_completed'] as num?)?.round();
    if (fromApi != null) return fromApi.clamp(0, 3);
    final today = DateTime.now();
    final core = todayDrillSlugs.take(3).toSet();
    final done = sessionHistory.where((s) {
      return s.timestamp.year == today.year &&
          s.timestamp.month == today.month &&
          s.timestamp.day == today.day &&
          core.contains(s.activitySlug) &&
          !s.feedback.isCoachedRetry;
    }).map((s) => s.activitySlug).toSet();
    return done.length;
  }

  int totalTodayActivitiesCount() {
    final fromApi = (todayPlan['total_count'] as num?)?.round();
    if (fromApi != null) return fromApi;
    if (dailyAnchorMinutes == 10) return 4;
    if (dailyAnchorMinutes == 15) return 5;
    return 3;
  }

  int completedTotalActivitiesToday() {
    final fromApi = (todayPlan['completed_total'] as num?)?.round();
    if (fromApi != null) return fromApi;
    final coreDone = completedTodayDrills().clamp(0, 3);
    if (dailyAnchorMinutes == 5) return coreDone;
    if (dailyAnchorMinutes == 10) {
      return coreDone + (isTargetedRetryCompletedToday ? 1 : 0);
    }
    if (dailyAnchorMinutes == 15) {
      return coreDone +
          (isTargetedRetryCompletedToday ? 1 : 0) +
          (isTougherChallengeCompletedToday ? 1 : 0);
    }
    return coreDone;
  }

  Map<String, dynamic> getWeakestExerciseToday() {
    final weakest = todayPlan['weakest_core'];
    final tougher = todayPlan['tougher_challenge'];
    if (weakest is Map && weakest['slug'] != null) {
      final slug = weakest['slug'].toString();
      final activity = activities.firstWhere(
        (a) => a.slug == slug,
        orElse: () => activities.first,
      );
      final stretchSlug = tougher is Map && tougher['slug'] != null
          ? tougher['slug'].toString()
          : (slug == 'debate_me' ? 'think_fast' : 'debate_me');
      final stretchActivity = activities.firstWhere(
        (a) => a.slug == stretchSlug,
        orElse: () => activities.first,
      );
      return {
        'slug': slug,
        'name': activity.name,
        'weakestArea': (weakest['weakest_area'] ?? 'Clarity').toString(),
        'score': (weakest['score'] as num?)?.toDouble() ?? 3.0,
        'feedback': (weakest['feedback_snippet'] ?? '').toString(),
        'stretchSlug': stretchSlug,
        'stretchName': stretchActivity.name,
        'stretchArea': tougher is Map
            ? (tougher['weakest_area'] ?? 'Pushback').toString()
            : 'Response to pushback',
        'stretchFeedback': tougher is Map
            ? (tougher['feedback_snippet'] ?? 'A tougher stretch round.')
                .toString()
            : 'A tougher round with stronger pushback.',
      };
    }

    final today = DateTime.now();
    final core = todayDrillSlugs.take(3).toSet();
    final todaySessions = sessionHistory.where((s) {
      return s.timestamp.year == today.year &&
          s.timestamp.month == today.month &&
          s.timestamp.day == today.day &&
          core.contains(s.activitySlug) &&
          !s.feedback.isCoachedRetry;
    }).toList();

    if (todaySessions.isEmpty) {
      return {
        'slug': 'cut_it_in_half',
        'name': 'Cut It in Half',
        'weakestArea': 'Conciseness',
        'score': 3.1,
        'feedback':
            'Your answers were clear, but you took too long to land the point.',
        'stretchSlug': 'debate_me',
        'stretchName': 'Debate Me',
        'stretchArea': 'Response to pushback',
        'stretchFeedback':
            'You held your position well, but your rebuttal could be sharper under pressure.',
      };
    }

    todaySessions.sort(
      (a, b) => a.feedback.overallScore.compareTo(b.feedback.overallScore),
    );
    final lowest = todaySessions.first;
    final slug = lowest.activitySlug;
    final activity = activities.firstWhere(
      (a) => a.slug == slug,
      orElse: () => activities.first,
    );

    String weakestArea = 'Conciseness';
    String feedback =
        'Your answers were clear, but you took too long to land the point.';
    if (slug == 'think_fast') {
      weakestArea = 'Thinking on the spot';
      feedback =
          'Good thoughts, but you hesitated before landing your primary thesis.';
    } else if (slug == 'debate_me' || slug == 'debate') {
      weakestArea = 'Response to pushback';
      feedback =
          'You held your position well, but your rebuttal could be sharper under pressure.';
    }

    return {
      'slug': slug,
      'name': activity.name,
      'weakestArea': weakestArea,
      'score': lowest.feedback.overallScore > 0
          ? lowest.feedback.overallScore.toDouble()
          : 3.1,
      'feedback': lowest.feedback.oneSpecificImprovement.isNotEmpty
          ? lowest.feedback.oneSpecificImprovement
          : feedback,
      'stretchSlug': slug == 'debate_me' ? 'think_fast' : 'debate_me',
      'stretchName': slug == 'debate_me' ? 'Think Fast' : 'Debate Me',
      'stretchArea':
          slug == 'debate_me' ? 'Rapid thesis delivery' : 'Response to pushback',
      'stretchFeedback': 'A tougher round with stronger pushback.',
    };
  }

  Future<void>? _sessionReady;

  AppStateProvider() {
    _initCatalog();
    selectedActivity = activities.first;
    _updateSelectedPrompt();
    answers.voiceProfile = CoachTtsService.instance.activeCoachId;
    _sessionReady = _restoreSession();
  }

  /// Await before splash/routing so a cold start does not drop a saved login.
  Future<void> ensureSessionReady() => _sessionReady ??= _restoreSession();

  Future<void> _restoreSession() async {
    if (!_api.sessionLoaded) {
      await _api.loadSession();
    }
    if (!_api.isLoggedIn) return;
    userId = _api.userId?.isNotEmpty == true ? _api.userId! : userId;
    fullName = _api.fullName ?? '';
    isLoggedIn = true;
    isOnboarded = _api.isOnboardedCached || isOnboarded;
    notifyListeners();
    // Refresh in background — routing must not wait on slow/cold API.
    unawaited(refreshFromApi());
  }

  /// Fast path for splash: local prefs only (no network).
  Future<void> restoreLocalSessionOnly() async {
    if (!_api.sessionLoaded) {
      await _api.loadSession();
    }
    if (!_api.isLoggedIn) return;
    userId = _api.userId?.isNotEmpty == true ? _api.userId! : userId;
    fullName = _api.fullName ?? '';
    email = _api.email ?? email;
    isLoggedIn = true;
    isOnboarded = _api.isOnboardedCached || isOnboarded;
    if (userId.isNotEmpty) {
      unawaited(AnalyticsService.instance.syncUserProfile(
        userId: userId,
        email: email,
      ));
    }
    unawaited(PushNotificationService.instance.syncTokenToApi());
    notifyListeners();
  }

  Future<void> registerAccount({
    required String name,
    required String email,
    required String password,
  }) async {
    // Wipe previous member's assessment so a fresh account never looks "done".
    _resetAssessmentLocalState();
    final data = await _api.register(
      fullName: name,
      email: email,
      password: password,
    );
    _applyAuthPayload(data);
    unawaited(AnalyticsService.instance.logSignUp(method: 'email'));
    // Signup always starts the assessment funnel.
    isOnboarded = false;
    await _api.persistOnboarded(false);
    unawaited(PushNotificationService.instance.syncTokenToApi());
    notifyListeners();
  }

  Future<Map<String, dynamic>> loginAccount({
    required String email,
    required String password,
  }) async {
    _resetAssessmentLocalState();
    final data = await _api.login(email: email, password: password);
    _applyAuthPayload(data);
    unawaited(AnalyticsService.instance.logLogin(method: 'email'));
    // Login always resumes on Home — mark session ready locally.
    isOnboarded = true;
    await _api.persistOnboarded(true);
    unawaited(PushNotificationService.instance.syncTokenToApi());
    unawaited(refreshFromApi());
    return data;
  }

  Future<Map<String, dynamic>> continueWithGoogle() async {
    final google = await GoogleAuthService.signIn();
    // Clear local answers only — onboarding flag comes from the API below.
    _resetAssessmentLocalState(clearOnboardedFlag: false);
    final data = await _api.loginWithGoogle(idToken: google.idToken);
    _applyAuthPayload(data);
    final created = data['created'] == true;
    if (created) {
      unawaited(AnalyticsService.instance.logSignUp(method: 'google'));
    } else {
      unawaited(AnalyticsService.instance.logLogin(method: 'google'));
    }
    // API-level routing: existing + assessment done → Home (skip onboarding).
    final profile = (data['profile'] as Map<String, dynamic>?) ?? {};
    final apiSaysNeedsOnboarding = data['needs_onboarding'] == true;
    final apiSaysComplete = data['onboarding_complete'] == true ||
        profile['onboarding_complete'] == true;
    final done = data.containsKey('needs_onboarding')
        ? !apiSaysNeedsOnboarding
        : (!created && apiSaysComplete);
    isOnboarded = done;
    await _api.persistOnboarded(done);
    unawaited(PushNotificationService.instance.syncTokenToApi());
    if (!created) {
      unawaited(refreshFromApi());
    }
    notifyListeners();
    return data;
  }

  Future<Map<String, dynamic>> continueWithApple() async {
    final apple = await AppleAuthService.signIn();
    _resetAssessmentLocalState(clearOnboardedFlag: false);
    final data = await _api.loginWithApple(
      idToken: apple.idToken,
      fullName: apple.displayName,
    );
    _applyAuthPayload(data);
    final created = data['created'] == true;
    if (created) {
      unawaited(AnalyticsService.instance.logSignUp(method: 'apple'));
    } else {
      unawaited(AnalyticsService.instance.logLogin(method: 'apple'));
    }
    final profile = (data['profile'] as Map<String, dynamic>?) ?? {};
    final apiSaysNeedsOnboarding = data['needs_onboarding'] == true;
    final apiSaysComplete = data['onboarding_complete'] == true ||
        profile['onboarding_complete'] == true;
    final done = data.containsKey('needs_onboarding')
        ? !apiSaysNeedsOnboarding
        : (!created && apiSaysComplete);
    isOnboarded = done;
    await _api.persistOnboarded(done);
    unawaited(PushNotificationService.instance.syncTokenToApi());
    if (!created) {
      unawaited(refreshFromApi());
    }
    notifyListeners();
    return data;
  }

  void _resetAssessmentLocalState({bool clearOnboardedFlag = true}) {
    answers.voiceProfile = null;
    answers.careerStage = null;
    answers.careerType = null;
    answers.confidence = null;
    answers.roadblock = null;
    answers.primaryGoal = null;
    personalizedPlan = null;
    if (clearOnboardedFlag) {
      isOnboarded = false;
    }
  }

  Future<void> markOnboardedComplete() async {
    isOnboarded = true;
    isLoggedIn = true;
    await _api.persistOnboarded(true);
    notifyListeners();
  }

  Future<void> updateProfileFromApi({
    required String name,
    required String voiceProfile,
    required String careerStage,
    required String careerType,
    required String confidence,
    required String roadblock,
    required String goal,
  }) async {
    final data = await _api.updateProfile({
      'full_name': name.trim(),
      'voice_profile': voiceProfile,
      'career_stage': careerStage,
      'career_type': careerType,
      'speaking_confidence': confidence,
      'primary_roadblock': roadblock,
      'primary_goal': goal,
    });
    if (name.trim().length >= 2) {
      fullName = name.trim();
      await _api.persistSessionFields(fullName: fullName);
    }
    final profile = (data['profile'] as Map<String, dynamic>?) ?? {};
    _applyProfile(profile);
    notifyListeners();
  }

  /// Coach voice used for suggested-answer TTS (male / female / non_binary).
  Future<void> updateVoiceProfile(String voiceProfile) async {
    final key = voiceProfile.trim();
    if (!voiceLabels.containsKey(key)) {
      throw HakkiriApiException('Pick a valid coach voice.');
    }
    answers.voiceProfile = key;
    CoachTtsService.instance.setActiveCoach(key);
    notifyListeners();
    if (!isLoggedIn) return;
    try {
      final data = await _api.updateSettings({'voice_profile': key});
      final settings = (data['settings'] as Map<String, dynamic>?) ?? {};
      _applySettings(settings);
      notifyListeners();
    } catch (_) {
      // Keep local selection even if sync fails.
    }
  }

  /// Backend allows only 5, 10, or 15 minutes for the daily practice anchor.
  Future<void> updateDailyAnchorMinutes(int minutes) async {
    if (![5, 10, 15].contains(minutes)) {
      throw HakkiriApiException('Daily practice must be 5, 10, or 15 minutes.');
    }
    final data = await _api.updateSettings({
      'daily_anchor_minutes': minutes,
    });
    final settings = (data['settings'] as Map<String, dynamic>?) ?? {};
    _applySettings(settings);
    dailyAnchorMinutes = minutes;
    notifyListeners();
  }

  /// Profile Reminder toggle — off means no daily FCM from the server.
  Future<void> updateRemindersEnabled(bool enabled) async {
    remindersEnabled = enabled;
    notifyListeners();
    try {
      final data = await _api.updateSettings({
        'reminders_enabled': enabled,
      });
      final settings = (data['settings'] as Map<String, dynamic>?) ?? {};
      _applySettings(settings);
      if (enabled) {
        await PushNotificationService.instance.enableAndSync();
      } else {
        await PushNotificationService.instance.clearTokenFromApi();
      }
      notifyListeners();
    } catch (e) {
      remindersEnabled = !enabled;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await GoogleAuthService.signOut();
    } catch (_) {}
    await _api.clearSession();
    unawaited(AnalyticsService.instance.logLogout());
    userId = '';
    fullName = '';
    email = '';
    isLoggedIn = false;
    isOnboarded = false;
    isBootstrapping = false;
    hasBootstrapped = false;
    answers.voiceProfile = null;
    answers.careerStage = null;
    answers.careerType = null;
    answers.confidence = null;
    answers.roadblock = null;
    answers.primaryGoal = null;
    personalizedPlan = null;
    sessionHistory.clear();
    challenges = [];
    todayQueue = [];
    todayPrimary = null;
    currentStreak = 0;
    longestStreak = 0;
    totalXp = 0;
    completedSessions = 0;
    overallAverage = null;
    overallSamples = 0;
    pillarStats = {};
    activityBreakdown = [];
    notifyListeners();
  }

  Future<void> submitAssessmentToApi({
    required String name,
    required String gender,
    required String careerStage,
    required String careerType,
    required String confidence,
    required String problem,
    required String goal,
  }) async {
    final data = await _api.submitAssessment(
      name: name,
      voiceProfile: gender,
      careerStage: careerStage,
      careerType: careerType,
      speakingConfidence: confidence,
      primaryRoadblock: problem,
      primaryGoal: goal,
    );

    updateAssessment(
      gender: gender,
      careerStage: careerStage,
      careerType: careerType,
      confidence: confidence,
      problem: problem,
      goal: goal,
    );

    if (name.trim().length >= 2) {
      fullName = name.trim();
    }
    final profile = (data['profile'] as Map<String, dynamic>?) ?? {};
    _applyProfile(profile);
    await markOnboardedComplete();
    unawaited(AnalyticsService.instance.logAssessmentCompleted(
      careerType: careerType,
      confidence: confidence,
      primaryRoadblock: problem,
    ));
    unawaited(refreshFromApi());
  }

  void _applyAuthPayload(Map<String, dynamic> data) {
    final user = (data['user'] as Map<String, dynamic>?) ?? {};
    final profile = (data['profile'] as Map<String, dynamic>?) ?? {};
    final subscription = (data['subscription'] as Map<String, dynamic>?) ?? {};
    final streak = (data['streak'] as Map<String, dynamic>?) ?? {};
    final settings = (data['settings'] as Map<String, dynamic>?) ?? {};

    userId = (user['id'] ?? _api.userId ?? userId).toString();
    fullName = (user['full_name'] ?? fullName).toString();
    email = (user['email'] ?? email).toString();
    isLoggedIn = true;
    if (email.isNotEmpty) {
      unawaited(_api.persistSessionFields(email: email));
    }
    _applyProfile(profile);
    _applySubscription(subscription);
    _applyStreak(streak);
    _applySettings(settings);

    if (userId.isNotEmpty) {
      unawaited(AnalyticsService.instance.syncUserProfile(
        userId: userId,
        email: email,
        careerType: answers.careerType,
        subscriptionTier: subscriptionTier,
        streak: currentStreak,
        xp: totalXp,
      ));
    }
  }

  void _applyProfile(Map<String, dynamic> profile) {
    if (profile.isEmpty) return;
    // Only overwrite fields that the API actually sent (null = not set yet).
    if (profile.containsKey('voice_profile')) {
      final v = profile['voice_profile'];
      answers.voiceProfile = v?.toString();
    }
    if (profile.containsKey('career_stage')) {
      final v = profile['career_stage'];
      answers.careerStage = v?.toString();
    }
    if (profile.containsKey('career_type')) {
      final v = profile['career_type'];
      answers.careerType = v?.toString();
    }
    if (profile.containsKey('speaking_confidence')) {
      final v = profile['speaking_confidence'];
      answers.confidence = v?.toString();
    }
    if (profile.containsKey('primary_roadblock')) {
      final v = profile['primary_roadblock'];
      answers.roadblock = v?.toString();
    }
    if (profile.containsKey('primary_goal')) {
      final v = profile['primary_goal'];
      answers.primaryGoal = v?.toString();
    }
    final plan = profile['personalized_plan'];
    if (plan is Map<String, dynamic>) {
      personalizedPlan = PersonalizedPlanModel.fromJson(plan);
      if (personalizedPlan!.focusLine.isNotEmpty) {
        focusLine = personalizedPlan!.focusLine;
      }
    } else if (profile.containsKey('personalized_plan') && plan == null) {
      personalizedPlan = null;
    }
    // Server is source of truth — do NOT infer from leftover local answers.
    if (profile.containsKey('onboarding_complete')) {
      final done = profile['onboarding_complete'] == true;
      isOnboarded = done;
      unawaited(_api.persistOnboarded(done));
    }
  }

  void _applySubscription(Map<String, dynamic> subscription) {
    if (subscription.isEmpty) return;
    subscriptionTier = (subscription['tier'] ?? subscriptionTier).toString();
    subscriptionStatus = (subscription['status'] ?? subscriptionStatus).toString();
    subscriptionPriceFormatted =
        (subscription['price_label'] ?? subscriptionPriceFormatted).toString();
    isSubscribed = subscription['can_practise'] == true;
    final end = subscription['current_period_end'] ?? subscription['trial_end'];
    if (end != null) {
      final date = DateTime.tryParse(end.toString());
      if (date != null) {
        subscriptionRenewalLabel =
            'Renews ${date.day} ${_monthName(date.month)} ${date.year}';
      }
    } else {
      subscriptionRenewalLabel = '';
    }
  }

  void _applyStreak(Map<String, dynamic>? streak) {
    if (streak == null || streak.isEmpty) return;
    currentStreak = (streak['current_streak'] as num?)?.round() ?? currentStreak;
    longestStreak = (streak['longest_streak'] as num?)?.round() ?? longestStreak;
    streakFreezeCount =
        (streak['streak_freeze_count'] as num?)?.round() ?? streakFreezeCount;
    totalXp = (streak['total_xp'] as num?)?.round() ?? totalXp;
    completedSessions =
        (streak['completed_sessions'] as num?)?.round() ?? completedSessions;
    lastPracticeDate = streak['last_practice_date']?.toString();
  }

  void _applySettings(Map<String, dynamic> settings) {
    if (settings.isEmpty) return;
    dailyAnchorMinutes =
        (settings['daily_anchor_minutes'] as num?)?.round() ?? dailyAnchorMinutes;
    audioPrivacy = (settings['audio_privacy'] ?? audioPrivacy).toString();
    if (settings.containsKey('reminders_enabled')) {
      remindersEnabled = settings['reminders_enabled'] != false;
      PushNotificationService.instance.allowSync = remindersEnabled;
    }
    if (settings['industry_track'] != null) {
      answers.careerType = settings['industry_track'].toString();
    }
    if (settings['voice_profile'] != null) {
      answers.voiceProfile = settings['voice_profile'].toString();
      CoachTtsService.instance.setActiveCoach(answers.voiceProfile!);
    }
  }

  String _monthName(int month) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return names[(month - 1).clamp(0, 11)];
  }

  Future<void> refreshFromApi() async {
    if (!_api.isLoggedIn) return;
    // Only block the home UI with shimmer on the first load — later refreshes
    // update quietly so the screen doesn't flash placeholders again.
    final showHomeShimmer = !hasBootstrapped;
    if (showHomeShimmer) {
      isBootstrapping = true;
      notifyListeners();
    }
    try {
      final data = await _api.bootstrap(limit: 30);

      final user = (data['user'] as Map<String, dynamic>?) ?? {};
      userId = (user['id'] ?? userId).toString();
      fullName = (user['full_name'] ?? fullName).toString();
      email = (user['email'] ?? email).toString();
      _applyProfile((data['profile'] as Map<String, dynamic>?) ?? {});
      _applySubscription((data['subscription'] as Map<String, dynamic>?) ?? {});
      _applyStreak(data['streak'] as Map<String, dynamic>?);
      _applySettings((data['settings'] as Map<String, dynamic>?) ?? {});

      final dash = (data['dashboard'] as Map<String, dynamic>?) ?? {};
      final overall = dash['overall'];
      if (overall is Map<String, dynamic>) {
        overallAverage = (overall['average'] as num?)?.toDouble();
        overallSamples = (overall['samples'] as num?)?.round() ?? 0;
      }
      pillarStats = (dash['pillars'] as Map<String, dynamic>?) ?? {};
      activityBreakdown = ((dash['activity_breakdown'] as List?) ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      _applyStreak(dash['gamification'] as Map<String, dynamic>?);

      final anchor = (data['daily_anchor'] as Map<String, dynamic>?) ?? {};
      todayPrimary = anchor['primary'] is Map
          ? Map<String, dynamic>.from(anchor['primary'] as Map)
          : null;
      todayQueue = ((anchor['queue'] as List?) ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      dailyAnchorMinutes =
          (anchor['minutes'] as num?)?.round() ?? dailyAnchorMinutes;
      focusLine = (anchor['focus_line'] ?? focusLine).toString();
      _applyDailyPlan(
        anchor['plan'] is Map
            ? Map<String, dynamic>.from(anchor['plan'] as Map)
            : null,
      );

      challenges = ((data['challenges'] as List?) ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      final sessionData = (data['sessions'] as Map<String, dynamic>?) ?? {};
      final rows = <PracticeSessionRecord>[];
      for (final raw in ((sessionData['sessions'] as List?) ?? [])) {
        if (raw is! Map) continue;
        final base =
            PracticeSessionRecord.fromApi(Map<String, dynamic>.from(raw));
        final audio = await SessionAudioStore.instance.pathFor(base.id);
        rows.add(audio == null ? base : base.copyWith(localAudioPath: audio));
      }
      sessionHistory
        ..clear()
        ..addAll(rows);

      if (answers.careerType != null) {
        selectedDifficulty = answers.confidence == 'not_very'
            ? 'beginner'
            : answers.confidence == 'very'
                ? 'pro'
                : 'intermediary';
      }
      _updateSelectedPrompt();
    } catch (_) {
      // Keep last good local snapshot if a refresh fails.
    } finally {
      hasBootstrapped = true;
      isBootstrapping = false;
      notifyListeners();
    }
  }

  Future<void> freezeStreakFromApi() async {
    final data = await _api.freezeStreak();
    _applyStreak(data['streak'] as Map<String, dynamic>?);
    unawaited(AnalyticsService.instance.logStreakFreezeUsed(
      remainingFreezes: streakFreezeCount,
    ));
    notifyListeners();
  }

  Future<void> joinChallengeFromApi(String slug) async {
    await _api.joinChallenge(slug);
    unawaited(AnalyticsService.instance.logChallengeJoined(challengeSlug: slug));
    await refreshFromApi();
  }

  Future<void> choosePlanFromApi(String tier) async {
    final data = await _api.chooseSubscription(tier);
    _applySubscription((data['subscription'] as Map<String, dynamic>?) ?? {});
    unawaited(AnalyticsService.instance.logSelectPlan(
      planId: tier,
      price: subscriptionPriceFormatted,
    ));
    notifyListeners();
  }

  void _initCatalog() {
    activities = [
      const ActivityModel(
        slug: 'think_fast',
        name: 'Think Fast',
        isMvp: true,
        tagline: 'Instant cognitive agility under time pressure',
        description: 'A random high-stakes question flashes on screen with a 3-second delay. You speak for 60 seconds using bottom-line-up-front structure.',
        cognitiveMechanism: 'Rapid lexical retrieval and on-the-spot framing under stress',
        prepDurationSeconds: 3,
        defaultDurationSeconds: 60,
        benefits: ['High cognitive agility under stress', 'Higher perceived authority', 'Eliminates meeting waffle'],
        successMeasures: ['Latency & stall tactics', 'Structural coherence', 'Composition & fillers'],
      ),
      const ActivityModel(
        slug: 'cut_it_in_half',
        name: 'Cut It In Half',
        isMvp: true,
        tagline: 'Extreme information synthesis and brevity',
        description: 'Review a lengthy corporate brief in 45 seconds, then summarize the core thesis with at least 50% rate compression.',
        cognitiveMechanism: 'Information distillation, compression, and high-density verbalization',
        prepDurationSeconds: 45,
        defaultDurationSeconds: 45,
        benefits: ['Forces deep information synthesis', 'Commands respect through brevity', 'Increases stakeholder retention'],
        successMeasures: ['Rate compression (50%+ reduction)', 'Time to value (BLUF)', 'Jargon translation'],
      ),
      const ActivityModel(
        slug: 'one_minute_expert',
        name: 'One Minute Expert',
        isMvp: true,
        tagline: 'Thematic chunking and spontaneous authority',
        description: 'Select a broad concept and speak authoritatively for exactly 60 seconds with an attention hook, 2 structured points, and a punchy wrap-up.',
        cognitiveMechanism: 'Categorical frameworks and executive thesis construction',
        prepDurationSeconds: 5,
        defaultDurationSeconds: 60,
        benefits: ['Trains the brain to chunk complex topics instantly', 'Builds spontaneous executive presence', 'Eliminates rambling'],
        successMeasures: ['The Hook', 'Categorical Depth', 'Time Management'],
      ),
      const ActivityModel(
        slug: 'explain_it_simply',
        name: 'Explain It Simply',
        isMvp: true,
        tagline: 'Demystifying complexity for non-experts',
        description: 'Translate a complex domain concept into crystal-clear language for a designated non-expert persona without jargon.',
        cognitiveMechanism: 'Analogical reasoning and demographic persona calibration',
        prepDurationSeconds: 10,
        defaultDurationSeconds: 60,
        benefits: ['Unlocks cross-functional leadership credibility', 'Forces conceptual mastery', 'Reduces meeting friction'],
        successMeasures: ['Persona Calibration', 'Time to Value', 'Linguistic Fit'],
      ),
      const ActivityModel(
        slug: 'storytelling_gym',
        name: 'Storytelling Gym',
        isMvp: true,
        tagline: 'Transform data dumps into compelling narratives',
        description: 'Deliver a powerful 3-part narrative (Context/Tension, Turning Point, Strategic Lesson) in 60 seconds.',
        cognitiveMechanism: 'Narrative arc pacing, conflict elevation, and strategic lesson landing',
        prepDurationSeconds: 10,
        defaultDurationSeconds: 60,
        benefits: ['Higher message retention', 'Drives alignment and persuasion', 'Projects relatable executive presence'],
        successMeasures: ['3-Part Narrative Arc', 'Tension density', 'Strategic significance'],
      ),
      const ActivityModel(
        slug: 'connect_the_dots',
        name: 'Connect the Dots',
        isMvp: true,
        tagline: 'Lateral thinking and the seamless pivot',
        description: 'Connect two completely random concepts with a seamless logical bridge within 60 seconds without stammering.',
        cognitiveMechanism: 'Associative retrieval and metaphorical bridge building',
        prepDurationSeconds: 5,
        defaultDurationSeconds: 60,
        benefits: ['Accelerates neural plasticity', 'Mastery of spontaneous pivots', 'Unlocks creative problem solving'],
        successMeasures: ['Bridge Logic', 'Pivot Placement', 'Speech Mechanics'],
      ),
      const ActivityModel(
        slug: 'debate_me',
        name: 'Debate Me',
        isMvp: true,
        tagline: 'Grace under fire and adversarial pushback',
        description: 'Defend your position against an assertive stakeholder objection, maintaining calm chest resonance and eliminating uptalk.',
        cognitiveMechanism: 'Emotional de-escalation, power pauses, and counter-framing',
        prepDurationSeconds: 5,
        defaultDurationSeconds: 60,
        benefits: ['Builds neuromuscular resilience against stage fright', 'Commands psychological control with silence', 'Eliminates defensive pitch'],
        successMeasures: ['Delivery & Biometrics', 'Rhetorical Integrity', 'Perceived Confidence'],
      ),
    ];

    promptBank = [
      // Think Fast - Career Specific Prompts (Client Design Requirements)
      const PromptModel(
        id: 'tf_stakeholder',
        activitySlug: 'think_fast',
        difficulty: 'beginner',
        promptText: 'How would you handle a difficult stakeholder?',
        objective: 'Acknowledge concerns calmly, state your boundary with poise, and align on shared objectives.',
        exemplarResponse: 'I would start by listening to understand their concerns, acknowledge their perspective, and then align on shared objectives.',
        tags: ['corporate_finance', 'stakeholder_management'],
        durationSeconds: 60,
        prepSeconds: 5,
      ),
      const PromptModel(
        id: 'tf_sales',
        activitySlug: 'think_fast',
        difficulty: 'intermediary',
        promptText: 'How would you respond to a client pushing back aggressively on your pricing?',
        objective: 'Validate their budget constraint, reframe around ROI, and avoid defensive tone.',
        exemplarResponse: 'I understand budget sensitivity is top of mind. Rather than cutting core scope, let us review the business outcomes and identify the highest ROI phases first.',
        tags: ['sales_marketing', 'negotiation'],
        durationSeconds: 60,
        prepSeconds: 5,
      ),
      const PromptModel(
        id: 'tf_tech',
        activitySlug: 'think_fast',
        difficulty: 'intermediary',
        promptText: 'How would you explain the necessity of technical refactoring to a non-technical stakeholder?',
        objective: 'Translate technical debt into commercial speed and reliability without jargon.',
        exemplarResponse: 'Think of our codebase like an office building. Over time, extra wiring slows down renovations. Refactoring clears the foundation so our next feature ships in half the time.',
        tags: ['tech_product', 'engineering'],
        durationSeconds: 60,
        prepSeconds: 5,
      ),
      const PromptModel(
        id: 'tf_healthcare_edu',
        activitySlug: 'think_fast',
        difficulty: 'intermediary',
        promptText: 'How would you deliver critical feedback to an anxious team member?',
        objective: 'Lead with empathy, separate behavior from character, and co-design a concrete next step.',
        exemplarResponse: 'I appreciate your dedication to the team. To help you thrive on this project, I want to address one specific area of clarity in communication, and discuss how we can support you.',
        tags: ['healthcare_edu', 'people_management'],
        durationSeconds: 60,
        prepSeconds: 5,
      ),
      const PromptModel(
        id: 'tf_01',
        activitySlug: 'think_fast',
        difficulty: 'beginner',
        promptText: 'Should companies completely ban video calls on Fridays? Why or why not?',
        objective: 'Fill the silence and survive the 60-second clock with a clear perspective.',
        exemplarResponse: 'I strongly believe companies should ban video calls on Fridays. First, screen fatigue degrades deep analytical focus. Second, uninterrupted quiet blocks allow employees to close key deliverables before the weekend.',
        tags: ['workplace', 'remote_work'],
        durationSeconds: 60,
        prepSeconds: 3,
      ),
      const PromptModel(
        id: 'tf_02',
        activitySlug: 'think_fast',
        difficulty: 'intermediary',
        promptText: 'Your team has missed a major project deadline due to a miscommunication. How do you explain this to your client without blaming your team?',
        objective: 'Take immediate accountability, outline corrective sprint, and maintain trust.',
        exemplarResponse: 'We take full responsibility for the milestone delay. A breakdown in internal review caused an unexpected bottleneck. Here is our recovery plan: senior engineers are reallocated, and we deliver by Thursday 2 PM.',
        tags: ['client_management', 'accountability'],
        durationSeconds: 60,
        prepSeconds: 3,
      ),
      const PromptModel(
        id: 'tf_03',
        activitySlug: 'think_fast',
        difficulty: 'professional',
        promptText: 'Our company’s core software platform just went offline globally, and clients are panicking on social media. Give an immediate 60-second update to the board of directors.',
        objective: 'Command total authority, communicate triage status (BLUF), and outline communication protocol.',
        exemplarResponse: 'Board members: at 14:10 UTC, European and US data centers experienced an unexpected cascade. Triage is active; DNS rollback is at 60% completion. Recovery target is 35 minutes. Public status page has been updated.',
        tags: ['crisis', 'boardroom'],
        durationSeconds: 60,
        prepSeconds: 3,
      ),

      // Cut It In Half
      const PromptModel(
        id: 'cih_01',
        activitySlug: 'cut_it_in_half',
        difficulty: 'beginner',
        title: 'Slack After-Hours Communication Policy',
        promptText: 'Summarize the core policy announcement with at least 50% rate compression within 30 seconds.',
        secondaryText: 'Hey team, I just wanted to jump on here and let everyone know that we’ve been looking at how we manage our internal communications lately. It turns out that a lot of people are feeling pretty overwhelmed by the sheer volume of Slack messages flying around every day, especially after hours. Because of that, leadership has decided that starting next Monday, we are going to implement a new policy where no one is expected to reply to any Slack messages after 6:00 PM. We really want everyone to get some proper downtime so we can keep our productivity high during normal working hours.',
        objective: 'State the policy immediately, eliminate fluff, speak steadily.',
        exemplarResponse: 'Starting Monday, to protect personal downtime and sustain daytime focus, team members are not required to respond to Slack messages after 6:00 PM.',
        tags: ['internal_comms', 'brevity'],
        durationSeconds: 45,
        prepSeconds: 45,
      ),

      // 1 Minute Expert
      const PromptModel(
        id: 'ome_01',
        activitySlug: 'one_minute_expert',
        difficulty: 'intermediary',
        title: 'Artificial Intelligence: Automation vs Augmentation',
        promptText: 'Explain the critical difference between automation (replacing tasks) and augmentation (helping humans).',
        objective: 'Use a categorical two-part framework with a clear concluding takeaway.',
        exemplarResponse: 'To understand AI workplace impact, we must separate automation from augmentation. Automation eliminates repetitive tasks like data entry. Augmentation supercharges human cognition—acting as a sparring partner that helps doctors diagnose faster or writers synthesize ideas.',
        tags: ['tech', 'ai'],
        durationSeconds: 60,
        prepSeconds: 5,
      ),

      // Explain It Simply
      const PromptModel(
        id: 'eis_01',
        activitySlug: 'explain_it_simply',
        difficulty: 'intermediary',
        title: 'SEO to a Traditional Pastry Chef',
        promptText: 'Explain Search Engine Optimization (SEO) to a traditional pastry chef who wants more foot traffic into their local bakery.',
        objective: 'Use baking and street signage metaphors without digital jargon.',
        exemplarResponse: 'Chef, think of Google as the town crier standing on the busiest street corner. When hungry tourists ask for the freshest croissant, the crier recommends the shop with the clearest sign, the best aroma drifting onto the street, and the most locals raving outside. SEO is simply polishing your sign so the town crier points customers straight into your bakery.',
        tags: ['marketing', 'local_business'],
        durationSeconds: 60,
        prepSeconds: 10,
      ),

      // Storytelling Gym
      const PromptModel(
        id: 'stg_01',
        activitySlug: 'storytelling_gym',
        difficulty: 'beginner',
        title: 'The Morning Disaster & Recovery',
        promptText: 'Tell a 60-second story about a time an unexpected morning disaster derailed your schedule, and how you recovered.',
        objective: 'Execute a clean 3-part timeline (Setup 20s, Obstacle 20s, Recovery & Lesson 20s).',
        exemplarResponse: 'Last November, I had our biggest client pitch scheduled at 9 AM. At 8:15, my espresso machine exploded across my suit while my train was canceled. Instead of spiraling, I bought a fresh shirt at the nearest retail shop and dialed into the audio bridge from the taxi. We closed the deal, and I learned that composure under friction is the real differentiator in any crisis.',
        tags: ['resilience', 'leadership'],
        durationSeconds: 60,
        prepSeconds: 10,
      ),

      // Connect the Dots
      const PromptModel(
        id: 'ctd_01',
        activitySlug: 'connect_the_dots',
        difficulty: 'intermediary',
        title: 'Winter Gardening 🔗 Venture Capital',
        promptText: 'Build a seamless metaphorical bridge between [Gardening in winter] and [Venture Capital (VC) investing].',
        secondaryText: 'Concept A: Gardening in winter | Concept B: Venture Capital investing',
        objective: 'Introduce transition around the 30s mark; avoid jarring non-sequiturs.',
        exemplarResponse: 'To an untrained observer, winter gardening looks lifeless—the soil is frozen and trees appear bare. Yet beneath the frost, roots are deepening and preparing nutrient reserves for spring. Venture capital investing operates on the exact same paradox. During macroeconomic downturns and funding winters, the most resilient founders build foundational infrastructure quietly. True venture capital isn’t about chasing the summer bloom; it’s about investing in the roots that survive the frost.',
        tags: ['lateral_thinking', 'metaphor'],
        durationSeconds: 60,
        prepSeconds: 5,
      ),

      // Debate Me
      const PromptModel(
        id: 'deb_01',
        activitySlug: 'debate_me',
        difficulty: 'beginner',
        title: 'Office Mandate Pushback',
        promptText: 'Act as a friendly colleague. Debate me on why working from the office five days a week is better than working from home. Push back when I give my reasons.',
        objective: 'Maintain lung support, avoid defensive pitch spikes, and deliver a composed counter-perspective.',
        exemplarResponse: 'I understand the value of spontaneous hallway chats and face-to-face camaraderie. However, forcing five days in the office conflates physical presence with actual productivity. By allowing hybrid autonomy, we retain top talent, eliminate exhausting commutes, and preserve focused deep-work time while still gathering intentionally for collaborative sprint planning.',
        tags: ['workplace', 'hybrid_work'],
        durationSeconds: 60,
        prepSeconds: 5,
      ),
    ];
  }

  void setAssessmentAnswer(String key, String value) {
    switch (key) {
      case 'voiceProfile':
        answers.voiceProfile = value;
        break;
      case 'careerStage':
        answers.careerStage = value;
        break;
      case 'careerType':
        answers.careerType = value;
        break;
      case 'confidence':
        answers.confidence = value;
        break;
      case 'roadblock':
        answers.roadblock = value;
        break;
      case 'primaryGoal':
        answers.primaryGoal = value;
        break;
    }
    notifyListeners();
  }

  void updateAssessment({
    String? gender,
    String? careerStage,
    String? careerType,
    String? confidence,
    String? problem,
    String? goal,
  }) {
    if (gender != null) answers.voiceProfile = gender;
    if (careerStage != null) answers.careerStage = careerStage;
    if (careerType != null) answers.careerType = careerType;
    if (confidence != null) answers.confidence = confidence;
    if (problem != null) answers.roadblock = problem;
    if (goal != null) answers.primaryGoal = goal;

    // Logic from Google Doc: "Hakkiri - Assessment - Level and Activity logic"
    // Step 1: Votes from Goal & Challenge determine the primary activities
    // Step 2: Career stage and confidence set starting level (Beginner vs Intermediary). No one starts at Pro.
    computeAssessmentPlan();

    _updateSelectedPrompt();
    completeAssessment();
  }

  /// Calculates personalized plan, starting difficulty, and initial drills based on
  /// official Google Doc logic.
  void computeAssessmentPlan() {
    final goal = answers.primaryGoal ?? 'calmer_confident';
    final challenge = answers.roadblock ?? 'blank_pressure';
    final careerStage = answers.careerStage ?? 'mid_level';
    final confidence = answers.confidence ?? 'fairly';
    final careerType = answers.careerType ?? 'corporate_finance';

    // 1. Tally votes from Goal & Challenge (Question 6 & 7)
    final Map<String, int> votes = {
      'think_fast': 0,
      'connect_the_dots': 0,
      'explain_it_simply': 0,
      'cut_it_in_half': 0,
      'storytelling_gym': 0,
      'one_minute_expert': 0,
      'debate_me': 0,
    };

    void addVote(String slug) {
      votes[slug] = (votes[slug] ?? 0) + 1;
    }

    // Goal votes (Question 7)
    switch (goal) {
      case 'authority':
        addVote('cut_it_in_half');
        addVote('debate_me');
        break;
      case 'calmer_confident':
        addVote('think_fast');
        addVote('connect_the_dots');
        break;
      case 'persuasive_arguments':
        addVote('debate_me');
        addVote('connect_the_dots');
        break;
      case 'clear_daily':
        addVote('explain_it_simply');
        addVote('cut_it_in_half');
        break;
      case 'keep_engaged':
        addVote('storytelling_gym');
        addVote('one_minute_expert');
        break;
      default:
        addVote('think_fast');
        addVote('cut_it_in_half');
    }

    // Challenge votes (Question 6)
    switch (challenge) {
      case 'blank_pressure':
        addVote('think_fast');
        addVote('connect_the_dots');
        break;
      case 'too_long':
        addVote('cut_it_in_half');
        addVote('think_fast');
        break;
      case 'filler_rush':
        addVote('think_fast');
        addVote('one_minute_expert');
        break;
      case 'explain_simple':
        addVote('explain_it_simply');
        addVote('one_minute_expert');
        break;
      case 'keep_engaged':
        addVote('storytelling_gym');
        addVote('one_minute_expert');
        break;
      case 'lose_confidence':
        addVote('debate_me');
        addVote('connect_the_dots');
        break;
      default:
        addVote('think_fast');
        addVote('connect_the_dots');
    }

    // Top activities become primary focus
    final sortedEntries = votes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topDrills = sortedEntries.take(3).map((e) => e.key).toList();

    // 2. Starting Level from Career & Confidence Grid (Step 2)
    final isLowConfidence = confidence == 'not_at_all' || confidence == 'slightly';
    final isHighConfidence = confidence == 'confident' || confidence == 'very';

    String startingLevel = 'beginner';
    if (careerStage == 'early' || careerStage == 'self_learner') {
      startingLevel = isHighConfidence ? 'intermediary' : 'beginner';
    } else {
      // mid_level or senior exec
      startingLevel = isLowConfidence ? 'beginner' : 'intermediary';
    }
    // Rule from Doc: No one starts at Pro! Pro is earned through results.
    selectedDifficulty = startingLevel;

    final activityNames = {
      'think_fast': 'Think Fast',
      'connect_the_dots': 'Connect the Dots',
      'explain_it_simply': 'Explain it Simply',
      'cut_it_in_half': 'Cut it in Half',
      'storytelling_gym': 'Storytelling Gym',
      'one_minute_expert': 'One Minute Expert',
      'debate_me': 'Debate Me',
    };

    final primaryName = activityNames[topDrills[0]] ?? 'Think Fast';
    final secondaryName = activityNames[topDrills[1]] ?? 'Cut it in Half';

    personalizedPlan = PersonalizedPlanModel(
      headline: '$primaryName & $secondaryName Focus Program',
      summary: 'A curated daily routine tailored for ${careerStageLabels[careerStage] ?? 'your career'} to speak with clarity and confidence.',
      recommendedTrack: careerType,
      primaryRoadblock: challenge,
      focusLine: focusLine,
      initialDrills: topDrills,
      milestones: const [
        MilestoneItem(week: 1, title: 'Cognitive Agility & Crutch Decoupling', focus: 'Quick 60s reps to build cognitive agility.'),
        MilestoneItem(week: 2, title: 'Brevity & Bottom-Line-Up-Front (BLUF)', focus: 'Compressing ideas by 50% within first 5 seconds.'),
        MilestoneItem(week: 3, title: 'Executive Presence & Power Silence', focus: 'Commanding meetings with 1–2s power pauses.'),
        MilestoneItem(week: 4, title: 'High-Stakes Mastery', focus: 'Handling unexpected questions under real pressure.'),
      ],
    );
  }

  void completeAssessment() {
    if (personalizedPlan == null) {
      computeAssessmentPlan();
    }

    isOnboarded = true;
    _supabase.saveUserProfile(
      userId: userId,
      answers: answers,
      plan: personalizedPlan!,
    );
    notifyListeners();
  }

  /// Call only after a verified Play/App Store purchase (or restore).
  Future<void> activatePaidPlan(String tier) async {
    final normalized =
        tier == 'annual_pro' || tier == 'annual' ? 'annual_pro' : 'monthly_pro';
    final isAnnual = normalized == 'annual_pro';
    subscriptionTier = normalized;
    subscriptionStatus = 'active';
    subscriptionPriceFormatted = isAnnual ? '£69.99/yr' : '£9.99/mo';
    isSubscribed = true;
    _supabase.updateSubscription(
      userId: userId,
      tier: normalized,
      priceGbp: isAnnual ? 69.99 : 9.99,
    );
    if (isLoggedIn) {
      try {
        await choosePlanFromApi(normalized);
      } catch (e) {
        debugPrint('[Hakkiri] Warning syncing subscription to API: $e');
      }
    }
    await markOnboardedComplete();
    notifyListeners();
  }

  @Deprecated('Use activatePaidPlan after a real IAP purchase')
  void selectSubscription(String tier) {
    unawaited(activatePaidPlan(tier));
  }

  /// Map landing/legacy aliases → catalog slugs.
  static String normalizeActivitySlug(String raw) {
    final slug = raw.trim();
    switch (slug) {
      case 'connect_dots':
        return 'connect_the_dots';
      case 'explain':
        return 'explain_it_simply';
      case 'stopwatch':
      case 'one_monitor_expert':
        return 'one_minute_expert';
      case 'storytelling':
        return 'storytelling_gym';
      case 'debate':
        return 'debate_me';
      default:
        return slug;
    }
  }

  void selectActivity(String slug) {
    final resolved = normalizeActivitySlug(slug);
    selectedActivity = activities.firstWhere(
      (a) => a.slug == resolved,
      orElse: () => activities.first,
    );
    _updateSelectedPrompt();
    notifyListeners();
    if (isLoggedIn) {
      unawaited(fetchNextPromptFromApi());
    }
  }

  /// Keep [selectedActivity] aligned with the drill UI the user is viewing.
  void ensureActivitySelected(String slug) {
    final resolved = normalizeActivitySlug(slug);
    if (selectedActivity?.slug == resolved) return;
    selectActivity(resolved);
  }

  void setDifficulty(String diff) {
    selectedDifficulty = diff;
    _updateSelectedPrompt();
    notifyListeners();
    if (isLoggedIn) {
      unawaited(fetchNextPromptFromApi());
    }
  }

  /// Pull the next practice question from the API catalog (Mongo prompts).
  /// Pass [excludeCurrent] so Begin exercise does not repeat the last question.
  Future<bool> fetchNextPromptFromApi({bool excludeCurrent = true}) async {
    final activity = selectedActivity;
    if (activity == null) return false;
    if (!_api.isLoggedIn) {
      rotateLocalPrompt();
      return true;
    }
    try {
      final difficulty = selectedDifficulty == 'pro'
          ? 'professional'
          : selectedDifficulty == 'i_dont_know'
              ? 'intermediary'
              : selectedDifficulty;
      final excludeId = excludeCurrent &&
              selectedPrompt != null &&
              selectedPrompt!.activitySlug == activity.slug &&
              _looksLikeCatalogPromptId(selectedPrompt!.id)
          ? selectedPrompt!.id
          : null;
      final data = await _api.nextPrompt(
        activitySlug: activity.slug,
        difficulty: difficulty,
        careerType: answers.careerType,
        excludePromptId: excludeId,
      );
      final promptMap = data['prompt'];
      if (promptMap is Map) {
        selectedPrompt =
            PromptModel.fromJson(Map<String, dynamic>.from(promptMap));
        notifyListeners();
        return true;
      }
    } catch (_) {
      // Network failed — still rotate locally so the same question does not stick.
      rotateLocalPrompt();
      return true;
    }
    rotateLocalPrompt();
    return true;
  }

  void _updateSelectedPrompt({bool forceRotate = false}) {
    if (selectedActivity == null) return;

    // Keep a fresh API catalog prompt unless we explicitly rotate.
    if (!forceRotate &&
        selectedPrompt != null &&
        selectedPrompt!.activitySlug == selectedActivity!.slug &&
        _looksLikeCatalogPromptId(selectedPrompt!.id)) {
      return;
    }

    final currentId = selectedPrompt?.id;
    final career = answers.careerType;
    List<PromptModel> pool = promptBank
        .where((p) => p.activitySlug == selectedActivity!.slug)
        .toList();

    final targetDiff = selectedDifficulty == 'i_dont_know'
        ? 'intermediary'
        : selectedDifficulty;
    final byDiff =
        pool.where((p) => p.difficulty == targetDiff).toList();
    if (byDiff.isNotEmpty) pool = byDiff;

    if (career != null && career.isNotEmpty) {
      final careerMatches =
          pool.where((p) => p.tags.contains(career)).toList();
      // Soft prefer career tags only when there is real variety.
      if (careerMatches.length >= 3) {
        pool = careerMatches;
      }
    }

    if (pool.isEmpty) {
      selectedPrompt = promptBank.first;
      return;
    }

    final fresh = pool.where((p) => p.id != currentId).toList();
    final pickFrom = fresh.isNotEmpty ? fresh : pool;
    pickFrom.shuffle();
    selectedPrompt = pickFrom.first;
  }

  /// Offline / API-fail fallback: rotate to a different local prompt.
  void rotateLocalPrompt() {
    _updateSelectedPrompt(forceRotate: true);
    notifyListeners();
  }

  Future<EvaluationFeedback> evaluateCurrentSession({
    required String transcript,
    required int durationSeconds,
    bool isRetry = false,
    String? planExtra,
    String conversationMode = 'single',
    List<ConversationTurn> conversationTurns = const [],
    String? localAudioTempPath,
    String? audioBase64,
    String audioMimeType = 'audio/mp4',
  }) async {
    final prompt = selectedPrompt ?? promptBank.first;
    final mode =
        conversationMode == 'back_and_forth' ? 'back_and_forth' : 'single';
    final resolvedPlanExtra = planExtra ?? pendingPlanExtra;
    final resolvedIsRetry =
        isRetry || resolvedPlanExtra == 'targeted_retry';

    // Persist local audio in parallel with Gemini so the overlay feels faster.
    final localId = _uuid.v4();
    final persistFuture =
        (localAudioTempPath != null && localAudioTempPath.isNotEmpty)
            ? SessionAudioStore.instance.persist(
                sessionId: localId,
                tempPath: localAudioTempPath,
              )
            : Future<String?>.value(null);

    // Prefer Gemini Flash analysis via API (doc requirement).
    // Fall back to on-device heuristic only if the AI call fails / offline.
    EvaluationFeedback feedback;
    var resolvedTranscript = transcript.trim();
    try {
      final analyzed = await _analyzeSpeechViaApi(
        prompt: prompt,
        transcript: resolvedTranscript,
        durationSeconds: durationSeconds,
        isRetry: resolvedIsRetry,
        audioBase64: audioBase64,
        audioMimeType: audioMimeType,
      );
      feedback = analyzed.feedback;
      if (analyzed.transcript.trim().isNotEmpty) {
        resolvedTranscript = analyzed.transcript.trim();
      }
    } catch (err) {
      // If we have a recording but scoring failed, do NOT pretend the user
      // said nothing ("no clear speech") — that was a false local fallback.
      if ((audioBase64 ?? '').isNotEmpty && resolvedTranscript.isEmpty) {
        // Never surface raw AI/model errors in the coach UI.
        feedback = EvaluationFeedback(
          overallScore: 2,
          pillars: const FourPillarsScore(
            executiveScore: 2,
            clarityScore: 2,
            impactScore: 2,
            engagementScore: 2,
            crutchCount: 0,
            powerPauseCount: 0,
            pacingWpm: 0,
            intelligibilityPercentage: 50,
            actionVerbPercentage: 40,
            isMonotoneWarning: false,
          ),
          oneStrength: 'Your voice recording was saved on this device.',
          oneSpecificImprovement:
              'We could not score this take yet. Tap Try again in a moment.',
          highlightedPhrase: const HighlightedPhrase(
            timestampRange: '00:00 - 00:05',
            phrase: 'Your answer was recorded.',
            critique:
                'Scoring is temporarily unavailable. Please try once more.',
          ),
          retryInstruction:
              'Tap Try again. Keep the answer under ~60 seconds.',
          exemplarResponse: prompt.exemplarResponse,
          isCoachedRetry: resolvedIsRetry,
          withholdJudgement: true,
        );
      } else {
        feedback = SpeechEvaluatorService.evaluateSpeech(
          prompt: prompt,
          transcript: resolvedTranscript,
          durationSeconds: durationSeconds,
          isRetry: resolvedIsRetry,
        );
      }
    }

    latestFeedback = feedback;
    final audioPath = await persistFuture;

    // Create and save local session history record immediately
    final record = PracticeSessionRecord(
      id: localId,
      activitySlug: prompt.activitySlug,
      activityName: selectedActivity?.name ?? 'Drill Session',
      promptTitle: prompt.title ??
          (prompt.promptText.length > 40
              ? '${prompt.promptText.substring(0, 40)}...'
              : prompt.promptText),
      promptText: prompt.promptText,
      transcript: resolvedTranscript,
      conversationMode: mode,
      conversationTurns: conversationTurns,
      timestamp: DateTime.now(),
      durationSeconds: durationSeconds,
      feedback: feedback,
      localAudioPath: audioPath,
    );
    latestSession = record;
    sessionHistory.insert(0, record);

    // Save session in Supabase backend (best-effort / legacy)
    _supabase.recordPracticeSession(
      userId: userId,
      activitySlug: prompt.activitySlug,
      promptId: prompt.id,
      transcript: resolvedTranscript,
      feedback: feedback,
    );

    unawaited(AnalyticsService.instance.logPracticeCompleted(
      activitySlug: prompt.activitySlug,
      activityName: selectedActivity?.name ?? 'Drill Session',
      durationSeconds: durationSeconds,
      overallScore: feedback.overallScore,
      executiveScore: feedback.pillars.executiveScore,
      clarityScore: feedback.pillars.clarityScore,
      impactScore: feedback.pillars.impactScore,
      engagementScore: feedback.pillars.engagementScore,
      isRetry: resolvedIsRetry,
    ));
    if (resolvedIsRetry) {
      unawaited(AnalyticsService.instance.logPracticeRetry(
        activitySlug: prompt.activitySlug,
      ));
    }

    if (isLoggedIn) {
      // Don't block the "Transcribing…" overlay on session sync.
      pendingPlanExtra = null;
      unawaited(_persistSessionToApi(
        prompt: prompt,
        transcript: resolvedTranscript,
        durationSeconds: durationSeconds,
        feedback: feedback,
        isRetry: resolvedIsRetry,
        planExtra: resolvedPlanExtra,
        localRecordId: record.id,
        conversationMode: mode,
        conversationTurns: conversationTurns,
        localAudioPath: audioPath,
      ).then((_) => refreshFromApi()));
    } else {
      if (resolvedPlanExtra == 'targeted_retry') {
        isTargetedRetryCompletedToday = true;
      } else if (resolvedPlanExtra == 'tougher_challenge') {
        isTougherChallengeCompletedToday = true;
      }
      pendingPlanExtra = null;
      finishDrillAndIncrementStreak();
    }

    notifyListeners();
    return feedback;
  }

  Future<({EvaluationFeedback feedback, String transcript})> _analyzeSpeechViaApi({
    required PromptModel prompt,
    required String transcript,
    required int durationSeconds,
    required bool isRetry,
    String? audioBase64,
    String audioMimeType = 'audio/mp4',
  }) async {
    if (!_api.isLoggedIn) {
      throw HakkiriApiException('Sign in required for AI scoring.');
    }
    final difficulty = selectedDifficulty == 'pro'
        ? 'professional'
        : selectedDifficulty == 'i_dont_know'
            ? 'intermediary'
            : (selectedDifficulty == 'beginner' ||
                    selectedDifficulty == 'intermediary' ||
                    selectedDifficulty == 'professional')
                ? selectedDifficulty
                : 'intermediary';

    final data = await _api.analyzeSpeech({
      'activity_slug': prompt.activitySlug,
      'activity_name': selectedActivity?.name ?? prompt.activitySlug,
      // Only send Mongo catalog codes (local bank ids like tf_stakeholder fail lookup).
      if (_looksLikeCatalogPromptId(prompt.id)) 'prompt_id': prompt.id,
      'prompt_text': prompt.promptText,
      'prompt_title': prompt.title ?? prompt.promptText,
      'objective': prompt.objective,
      'exemplar_response': prompt.exemplarResponse,
      'difficulty': difficulty,
      'transcript': transcript,
      'duration_seconds': durationSeconds,
      'is_coached_retry': isRetry,
      if (audioBase64 != null && audioBase64.isNotEmpty) ...{
        'audio_base64': audioBase64,
        'audio_mime_type': audioMimeType,
      },
    });

    final feedbackMap = data['feedback'];
    if (feedbackMap is! Map) {
      throw HakkiriApiException('AI analysis returned no feedback.');
    }
    final fromApi = (data['transcript'] ?? transcript).toString();
    return (
      feedback: EvaluationFeedback.fromJson(
        Map<String, dynamic>.from(feedbackMap),
      ),
      transcript: fromApi,
    );
  }

  bool _looksLikeCatalogPromptId(String id) {
    // Catalog codes look like tf_b_friday_calls / cih_i_cac — not tf_stakeholder.
    if (id.isEmpty) return false;
    final localOnly = {
      'tf_stakeholder',
      'tf_sales',
      'tf_tech',
      'tf_healthcare_edu',
      'tf_01',
      'tf_02',
      'tf_03',
      'cih_01',
      'ome_01',
      'eis_01',
      'stg_01',
      'ctd_01',
      'deb_01',
    };
    return !localOnly.contains(id);
  }

  Future<void> _persistSessionToApi({
    required PromptModel prompt,
    required String transcript,
    required int durationSeconds,
    required EvaluationFeedback feedback,
    required bool isRetry,
    required String localRecordId,
    String? planExtra,
    String conversationMode = 'single',
    List<ConversationTurn> conversationTurns = const [],
    String? localAudioPath,
  }) async {
    try {
      final data = await _api.createSession({
        'activity_slug': prompt.activitySlug,
        if (_looksLikeCatalogPromptId(prompt.id)) 'prompt_id': prompt.id,
        'prompt_title': prompt.title ?? prompt.promptText,
        'prompt_text': prompt.promptText,
        'difficulty': planExtra == 'tougher_challenge'
            ? 'professional'
            : selectedDifficulty == 'pro'
                ? 'professional'
                : selectedDifficulty == 'i_dont_know'
                    ? 'intermediary'
                    : (selectedDifficulty == 'beginner' ||
                            selectedDifficulty == 'intermediary' ||
                            selectedDifficulty == 'professional')
                        ? selectedDifficulty
                        : 'intermediary',
        'transcript': transcript,
        'duration_seconds': durationSeconds,
        'is_coached_retry': isRetry,
        if (planExtra != null) 'plan_extra': planExtra,
        'conversation_mode': conversationMode,
        'conversation_turns':
            conversationTurns.map((t) => t.toJson()).toList(),
        'feedback': feedback.toJson(),
      });
      _applyStreak(data['streak'] as Map<String, dynamic>?);

      // Keep the local row until refresh replaces it with the server copy.
      final session = data['session'];
      if (session is Map) {
        final apiRecord =
            PracticeSessionRecord.fromApi(Map<String, dynamic>.from(session));
        await SessionAudioStore.instance.rekey(
          fromId: localRecordId,
          toId: apiRecord.id,
        );
        final audio = localAudioPath ??
            await SessionAudioStore.instance.pathFor(apiRecord.id);
        final merged = apiRecord.copyWith(
          localAudioPath: audio,
          // Preserve full prompt/transcript if API omitted older fields.
          promptText: apiRecord.promptText.isNotEmpty
              ? apiRecord.promptText
              : prompt.promptText,
          transcript: apiRecord.transcript.isNotEmpty
              ? apiRecord.transcript
              : transcript,
          // Keep guided Debate / live coach chat if API echo is empty.
          conversationMode: apiRecord.isBackAndForth
              ? apiRecord.conversationMode
              : (conversationMode == 'back_and_forth'
                  ? 'back_and_forth'
                  : apiRecord.conversationMode),
          conversationTurns: apiRecord.conversationTurns.isNotEmpty
              ? apiRecord.conversationTurns
              : conversationTurns,
        );
        final idx = sessionHistory.indexWhere((s) => s.id == localRecordId);
        if (idx >= 0) {
          sessionHistory[idx] = merged;
        }
        if (latestSession?.id == localRecordId) {
          latestSession = merged;
        }
      }
      await refreshFromApi();
      // refresh replaces history; keep conversation on the open feedback session.
      if (latestSession != null &&
          latestSession!.conversationTurns.isNotEmpty &&
          sessionHistory.isNotEmpty) {
        final i = sessionHistory.indexWhere((s) => s.id == latestSession!.id);
        if (i >= 0 && sessionHistory[i].conversationTurns.isEmpty) {
          sessionHistory[i] = sessionHistory[i].copyWith(
            conversationMode: latestSession!.conversationMode,
            conversationTurns: latestSession!.conversationTurns,
          );
        } else if (i < 0) {
          // Id swapped by server — prefer newest row, preserve turns if missing.
          final top = sessionHistory.first;
          if (top.conversationTurns.isEmpty) {
            sessionHistory[0] = top.copyWith(
              conversationMode: latestSession!.conversationMode,
              conversationTurns: latestSession!.conversationTurns,
            );
          }
          latestSession = sessionHistory.first;
        }
      } else if (latestSession == null && sessionHistory.isNotEmpty) {
        latestSession = sessionHistory.first;
      }
    } catch (_) {
      // Keep the local history row so Progress/Home still show this drill.
      finishDrillAndIncrementStreak();
      notifyListeners();
    }
  }

  void finishDrillAndIncrementStreak() {
    currentStreak += 1;
    totalXp += 50; // XP kept separate from skill scores
    completedSessions += 1;
    notifyListeners();
  }

  Future<bool> deleteSession(String sessionId) async {
    try {
      if (isLoggedIn) {
        try {
          await _api.deleteSession(sessionId);
        } catch (_) {}
      }
      await SessionAudioStore.instance.remove(sessionId);
      sessionHistory.removeWhere((s) => s.id == sessionId);
      if (latestSession?.id == sessionId) {
        latestSession = sessionHistory.isNotEmpty ? sessionHistory.first : null;
      }
      if (completedSessions > 0) {
        completedSessions -= 1;
      }
      notifyListeners();
      return true;
    } catch (_) {
      sessionHistory.removeWhere((s) => s.id == sessionId);
      if (latestSession?.id == sessionId) {
        latestSession = sessionHistory.isNotEmpty ? sessionHistory.first : null;
      }
      notifyListeners();
      return false;
    }
  }
}
