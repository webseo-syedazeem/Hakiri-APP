import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  factory ReflectionNote.fromApi(Map<String, dynamic> json) {
    final rawDate = json['created_at'] ?? json['date'];
    DateTime date = DateTime.now();
    if (rawDate is String) {
      date = DateTime.tryParse(rawDate) ?? date;
    } else if (rawDate is DateTime) {
      date = rawDate;
    }
    return ReflectionNote(
      id: (json['id'] ?? '').toString(),
      date: date.toLocal(),
      title: (json['title'] ?? '').toString(),
      learnings: (json['learnings'] ?? '').toString(),
      focusArea: (json['focus_area'] ?? json['focusArea'] ?? '').toString(),
    );
  }
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
  /// Guest finished assessment before Create account — sync after signup.
  bool hasPendingLocalAssessment = false;
  /// Name typed in assessment — kept across existing-account login (server
  /// full_name must not wipe it before sync).
  String? pendingAssessmentName;

  /// Guest funnel (no login yet):
  /// - [guestStageAwaitingIap] → plan (trial) or paywall after trial/Continue
  /// - [guestStageAwaitingAccount] → splash opens Create account (after plan purchase)
  static const guestStageAwaitingIap = 'awaiting_iap';
  static const guestStageAwaitingAccount = 'awaiting_account';
  static const _guestFunnelStageKey = 'hakkiri_guest_funnel_stage';
  static const _guestAssessmentKey = 'hakkiri_guest_assessment';
  static const _guestTierKey = 'hakkiri_guest_pending_tier';
  static const _guestTrialUsedKey = 'hakkiri_guest_trial_used';
  static const _guestPaywallReachedKey = 'hakkiri_guest_paywall_reached';

  String guestFunnelStage = '';
  String? pendingGuestTier;
  /// One free Think Fast try on the plan screen — not saved.
  bool guestTrialUsed = false;
  /// After trial back/finish or Continue → always resume at IAP.
  bool guestPaywallReached = false;

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
  Map<String, String> activityLevels = {};
  Map<String, dynamic>? coachingPrompt;

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

  /// Simple Male / Female label for Settings + Feedback coach TTS.
  String get coachVoiceGender {
    final id = CoachTtsService.normalizeCoachId(answers.voiceProfile);
    if (id == 'david' || id == 'marcus' || id == 'male') return 'male';
    return 'female';
  }

  String get coachVoiceGenderLabel =>
      coachVoiceGender == 'male' ? 'Male' : 'Female';

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return 'H';
    final list = parts.toList();
    if (list.length == 1) return list.first.substring(0, 1).toUpperCase();
    return '${list.first.substring(0, 1)}${list.last.substring(0, 1)}'.toUpperCase();
  }

  String get subscriptionTitle {
    if (subscriptionStatus == 'trialing' &&
        (subscriptionTier == 'annual_pro' || subscriptionTier == 'annual')) {
      return 'HAKKIRI PRO · 7-DAY TRIAL';
    }
    switch (subscriptionTier) {
      case 'annual_pro':
      case 'annual':
        return 'HAKKIRI PRO · YEARLY';
      case 'monthly_pro':
      case 'monthly':
        return 'HAKKIRI PRO · MONTHLY';
      default:
        // Not subscribed — never show "Free trial" as a fake plan name.
        return 'HAKKIRI · NO PLAN';
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

  final List<ReflectionNote> _reflectionNotes = [];
  int reflectionPracticeSessions = 0;
  int reflectionFocusAreasCompleted = 0;
  int _reflectionRangeDays = 28;

  List<ReflectionNote> get reflectionNotes => List.unmodifiable(_reflectionNotes);

  void _applyReflections(Map<String, dynamic> data) {
    final rows = <ReflectionNote>[];
    for (final raw in ((data['reflections'] as List?) ?? [])) {
      if (raw is! Map) continue;
      rows.add(ReflectionNote.fromApi(Map<String, dynamic>.from(raw)));
    }
    _reflectionNotes
      ..clear()
      ..addAll(rows);
    final stats = data['stats'];
    if (stats is Map) {
      reflectionPracticeSessions =
          (stats['practice_sessions'] as num?)?.round() ?? 0;
      reflectionFocusAreasCompleted =
          (stats['focus_areas_completed'] as num?)?.round() ?? 0;
      final streak = (stats['day_streak'] as num?)?.round();
      if (streak != null) currentStreak = streak;
    }
  }

  Future<void> loadReflections({int days = 28}) async {
    if (!_api.isLoggedIn) return;
    _reflectionRangeDays = days;
    try {
      final data = await _api.listReflections(days: days);
      _applyReflections(data);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> addReflectionNote({
    required String title,
    required String learnings,
    required String focusArea,
  }) async {
    final optimistic = ReflectionNote(
      id: 'ref-${DateTime.now().millisecondsSinceEpoch}',
      date: DateTime.now(),
      title: title.trim().isEmpty ? 'Daily Reflection' : title.trim(),
      learnings: learnings.trim(),
      focusArea: focusArea.trim(),
    );
    _reflectionNotes.insert(0, optimistic);
    notifyListeners();
    try {
      await _api.createReflection(
        title: optimistic.title,
        learnings: optimistic.learnings,
        focusArea: optimistic.focusArea,
      );
      await loadReflections(days: _reflectionRangeDays);
    } catch (e) {
      _reflectionNotes.removeWhere((n) => n.id == optimistic.id);
      notifyListeners();
      rethrow;
    }
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

  bool get isCorePlanComplete => completedTodayDrills() >= 3;

  bool get isFullPlanComplete {
    if (todayPlanPhase == 'complete' &&
        completedTotalActivitiesToday() >= totalTodayActivitiesCount()) {
      return true;
    }
    return completedTotalActivitiesToday() >= totalTodayActivitiesCount();
  }

  bool get shouldOfferPlanExtras =>
      isCorePlanComplete &&
      dailyAnchorMinutes >= 10 &&
      !isFullPlanComplete;

  bool isCoreSlugDoneToday(String slug) {
    final resolved = normalizeActivitySlug(slug);
    final today = DateTime.now();
    return sessionHistory.any((s) {
      return s.activitySlug == resolved &&
          !s.feedback.isCoachedRetry &&
          s.timestamp.year == today.year &&
          s.timestamp.month == today.month &&
          s.timestamp.day == today.day;
    });
  }

  /// First core drill not yet done today — any order is allowed.
  String? firstIncompleteCoreSlug() {
    for (final slug in todayDrillSlugs.take(3)) {
      if (!isCoreSlugDoneToday(slug)) return slug;
    }
    return null;
  }

  /// Local count from sessions already on device (immediate after a take).
  int _localCompletedTodayDrills() {
    final today = DateTime.now();
    final core = todayDrillSlugs.take(3).map(normalizeActivitySlug).toSet();
    final done = <String>{};
    for (final s in sessionHistory) {
      if (s.feedback.isCoachedRetry) continue;
      if (s.timestamp.year != today.year ||
          s.timestamp.month != today.month ||
          s.timestamp.day != today.day) {
        continue;
      }
      final slug = normalizeActivitySlug(s.activitySlug);
      if (core.contains(slug)) done.add(slug);
    }
    return done.length.clamp(0, 3);
  }

  int completedTodayDrills() {
    final local = _localCompletedTodayDrills();
    final fromApi = (todayPlan['core_completed'] as num?)?.round();
    // Never let a stale plan block unlock after the 3rd checkmark lands.
    if (fromApi == null) return local;
    return (fromApi > local ? fromApi : local).clamp(0, 3);
  }

  int totalTodayActivitiesCount() {
    final fromApi = (todayPlan['total_count'] as num?)?.round();
    if (fromApi != null) return fromApi;
    if (dailyAnchorMinutes == 10) return 4;
    if (dailyAnchorMinutes == 15) return 5;
    return 3;
  }

  int _localCompletedTotalActivitiesToday() {
    final coreDone = _localCompletedTodayDrills();
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

  int completedTotalActivitiesToday() {
    final local = _localCompletedTotalActivitiesToday();
    final fromApi = (todayPlan['completed_total'] as num?)?.round();
    if (fromApi == null) return local;
    return fromApi > local ? fromApi : local;
  }

  /// Keep Today plan counters in sync the moment a core take is saved locally,
  /// so Targeted retry unlocks without waiting for bootstrap refresh.
  void _syncTodayPlanAfterLocalSession({
    required String activitySlug,
    required bool isRetry,
    String? planExtra,
  }) {
    if (isRetry) return;
    final core = todayDrillSlugs.take(3).toSet();
    final resolved = normalizeActivitySlug(activitySlug);
    final nextCore = completedTodayDrills();
    todayPlan = Map<String, dynamic>.from(todayPlan);
    if (core.contains(resolved)) {
      todayPlan['core_completed'] = nextCore;
    }
    if (planExtra == 'targeted_retry') {
      isTargetedRetryCompletedToday = true;
      final extras = Map<String, dynamic>.from(
        (todayPlan['extras_completed'] as Map?) ?? {},
      );
      extras['targeted_retry'] = true;
      todayPlan['extras_completed'] = extras;
    } else if (planExtra == 'tougher_challenge') {
      isTougherChallengeCompletedToday = true;
      final extras = Map<String, dynamic>.from(
        (todayPlan['extras_completed'] as Map?) ?? {},
      );
      extras['tougher_challenge'] = true;
      todayPlan['extras_completed'] = extras;
    }
    todayPlan['completed_total'] = _localCompletedTotalActivitiesToday();
    if (nextCore >= 3) {
      if (dailyAnchorMinutes == 5) {
        todayPlan['phase'] = 'complete';
      } else if (dailyAnchorMinutes == 10) {
        todayPlan['phase'] =
            isTargetedRetryCompletedToday ? 'complete' : 'retry_offer';
      } else if (dailyAnchorMinutes == 15) {
        todayPlan['phase'] =
            (isTargetedRetryCompletedToday && isTougherChallengeCompletedToday)
                ? 'complete'
                : 'extras_offer';
      }
    }
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
      // No invented score — callers should handle missing weakest data.
      return {
        'slug': todayDrillSlugs.isNotEmpty
            ? todayDrillSlugs.first
            : 'cut_it_in_half',
        'name': 'Today’s first drill',
        'weakestArea': 'Practice',
        'score': null,
        'feedback': 'Complete a drill today to see your weakest area.',
        'stretchSlug': 'debate_me',
        'stretchName': 'Debate Me',
        'stretchArea': 'Response to pushback',
        'stretchFeedback':
            'Finish today’s core drills to unlock a stretch suggestion.',
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
    await loadGuestFunnelFromDisk();
    if (!_api.isLoggedIn) {
      notifyListeners();
      return;
    }
    userId = _api.userId?.isNotEmpty == true ? _api.userId! : userId;
    // Do not wipe the quiz name with a stale session cache — sync on signup
    // must still see pendingAssessmentName / local fullName.
    final quizName = pendingAssessmentName?.trim();
    if (quizName == null || quizName.length < 2) {
      fullName = _api.fullName ?? fullName;
    }
    email = _api.email ?? email;
    isLoggedIn = true;
    if (!hasPendingLocalAssessment) {
      isOnboarded = _api.isOnboardedCached || isOnboarded;
    }
    if (userId.isNotEmpty) {
      unawaited(AnalyticsService.instance.syncUserProfile(
        userId: userId,
        email: email,
      ));
    }
    unawaited(PushNotificationService.instance.syncTokenToApi());
    // Only recover a sync that was interrupted after login/signup — never
    // invent a push before the user hits Create account / Login.
    if (hasPendingLocalAssessment && isLoggedIn) {
      unawaited(syncPendingAssessmentIfNeeded().catchError((e) {
        debugPrint('[Hakkiri] splash pending assessment sync failed: $e');
        return false;
      }));
    }
    notifyListeners();
  }

  Future<void> loadGuestFunnelFromDisk() async {
    final prefs = await SharedPreferences.getInstance();
    guestFunnelStage = prefs.getString(_guestFunnelStageKey) ?? '';
    pendingGuestTier = prefs.getString(_guestTierKey);
    guestTrialUsed = prefs.getBool(_guestTrialUsedKey) ?? false;
    guestPaywallReached = prefs.getBool(_guestPaywallReachedKey) ?? false;
    final raw = prefs.getString(_guestAssessmentKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final hasAnswers = map['career_stage'] != null || map['primary_goal'] != null;

      // Already signed in: only keep pending if onboarding still needs a sync.
      // Stale guest flags were blocking profile updates (goal / challenge).
      if (_api.isLoggedIn) {
        final needsSync = hasAnswers && !_api.isOnboardedCached;
        if (needsSync) {
          final savedName = (map['full_name'] as String?)?.trim();
          if (savedName != null && savedName.length >= 2) {
            fullName = savedName;
            pendingAssessmentName = savedName;
          }
          answers.voiceProfile = map['voice_profile'] as String?;
          answers.careerStage = map['career_stage'] as String?;
          answers.careerType = map['career_type'] as String?;
          answers.confidence = map['confidence'] as String?;
          answers.roadblock = map['roadblock'] as String?;
          answers.primaryGoal = map['primary_goal'] as String?;
          selectedDifficulty =
              (map['difficulty'] as String?) ?? selectedDifficulty;
          computeAssessmentPlan();
          hasPendingLocalAssessment = true;
        } else {
          hasPendingLocalAssessment = false;
          pendingAssessmentName = null;
          await prefs.remove(_guestAssessmentKey);
          await prefs.remove(_guestFunnelStageKey);
          await prefs.remove(_guestTierKey);
          await prefs.remove(_guestTrialUsedKey);
          await prefs.remove(_guestPaywallReachedKey);
          guestFunnelStage = '';
          pendingGuestTier = null;
        }
        return;
      }

      final savedName = (map['full_name'] as String?)?.trim();
      if (savedName != null && savedName.length >= 2) {
        fullName = savedName;
        pendingAssessmentName = savedName;
      }
      answers.voiceProfile = map['voice_profile'] as String?;
      answers.careerStage = map['career_stage'] as String?;
      answers.careerType = map['career_type'] as String?;
      answers.confidence = map['confidence'] as String?;
      answers.roadblock = map['roadblock'] as String?;
      answers.primaryGoal = map['primary_goal'] as String?;
      selectedDifficulty =
          (map['difficulty'] as String?) ?? selectedDifficulty;
      if (hasAnswers) {
        computeAssessmentPlan();
        hasPendingLocalAssessment = true;
      }
      if (guestFunnelStage == guestStageAwaitingAccount &&
          pendingGuestTier != null) {
        subscriptionTier = pendingGuestTier!;
        subscriptionStatus = 'active';
        isSubscribed = true;
      }
    } catch (e) {
      debugPrint('[Hakkiri] guest funnel restore failed: $e');
    }
  }

  Future<void> persistGuestFunnelToDisk() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_guestFunnelStageKey, guestFunnelStage);
    await prefs.setBool(_guestTrialUsedKey, guestTrialUsed);
    await prefs.setBool(_guestPaywallReachedKey, guestPaywallReached);
    if (pendingGuestTier != null) {
      await prefs.setString(_guestTierKey, pendingGuestTier!);
    } else {
      await prefs.remove(_guestTierKey);
    }
    await prefs.setString(
      _guestAssessmentKey,
      jsonEncode({
        'full_name': (pendingAssessmentName ?? fullName).trim(),
        'voice_profile': answers.voiceProfile,
        'career_stage': answers.careerStage,
        'career_type': answers.careerType,
        'confidence': answers.confidence,
        'roadblock': answers.roadblock,
        'primary_goal': answers.primaryGoal,
        'difficulty': selectedDifficulty,
      }),
    );
  }

  Future<void> clearGuestFunnel() async {
    guestFunnelStage = '';
    pendingGuestTier = null;
    hasPendingLocalAssessment = false;
    pendingAssessmentName = null;
    guestTrialUsed = false;
    guestPaywallReached = false;
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_guestFunnelStageKey),
      prefs.remove(_guestAssessmentKey),
      prefs.remove(_guestTierKey),
      prefs.remove(_guestTrialUsedKey),
      prefs.remove(_guestPaywallReachedKey),
    ]);
  }

  Future<void> markGuestAwaitingIap() async {
    guestFunnelStage = guestStageAwaitingIap;
    hasPendingLocalAssessment = true;
    await persistGuestFunnelToDisk();
    notifyListeners();
  }

  Future<void> markGuestReachedPaywall() async {
    guestFunnelStage = guestStageAwaitingIap;
    guestPaywallReached = true;
    hasPendingLocalAssessment = true;
    await persistGuestFunnelToDisk();
    notifyListeners();
  }

  /// One free guest try for any drill — catalog prompt from API, not saved.
  /// Returns false if already used or logged in.
  Future<bool> prepareGuestTrial(String activitySlug) async {
    if (isLoggedIn || guestTrialUsed) return false;
    final slug = normalizeActivitySlug(activitySlug);
    ensureActivitySelected(slug);
    syncDifficultyForActivity(slug);
    await fetchNextPromptFromApi(excludeCurrent: true);
    // Do not burn the free try until a scored take completes.
    guestFunnelStage = guestStageAwaitingIap;
    hasPendingLocalAssessment = true;
    await persistGuestFunnelToDisk();
    notifyListeners();
    return true;
  }

  Future<void> markGuestTrialConsumed() async {
    if (isLoggedIn || guestTrialUsed) return;
    guestTrialUsed = true;
    guestFunnelStage = guestStageAwaitingIap;
    await persistGuestFunnelToDisk();
    notifyListeners();
  }

  /// Legacy alias — free try is no longer Think Fast only.
  Future<bool> prepareGuestThinkFastTrial() => prepareGuestTrial('think_fast');

  Future<void> markGuestAwaitingAccount({String? tier}) async {
    guestFunnelStage = guestStageAwaitingAccount;
    if (tier != null) {
      pendingGuestTier = tier;
      subscriptionTier = tier;
      subscriptionStatus = 'active';
      isSubscribed = true;
    }
    hasPendingLocalAssessment = true;
    await persistGuestFunnelToDisk();
    notifyListeners();
  }

  Future<void> sendSignupOtp({
    required String name,
    required String email,
  }) async {
    await _api.sendSignupOtp(fullName: name, email: email);
  }

  Future<void> registerAccount({
    required String name,
    required String email,
    required String password,
    required String otp,
  }) async {
    // Keep guest assessment answers so we can sync after Create account.
    if (!hasPendingLocalAssessment) {
      _resetAssessmentLocalState();
    }
    final data = await _api.register(
      fullName: name,
      email: email,
      password: password,
      otp: otp,
    );
    _applyAuthPayload(data);
    unawaited(AnalyticsService.instance.logSignUp(method: 'email'));
    if (!hasPendingLocalAssessment) {
      isOnboarded = false;
      await _api.persistOnboarded(false);
    }
    unawaited(PushNotificationService.instance.syncTokenToApi());
    notifyListeners();
  }

  Future<Map<String, dynamic>> loginAccount({
    required String email,
    required String password,
  }) async {
    // Keep quiz answers if guest just finished assessment then logged in.
    final keepPending = hasPendingLocalAssessment;
    if (!keepPending) {
      _resetAssessmentLocalState();
    }
    final data = await _api.login(email: email, password: password);
    _applyAuthPayload(data);
    unawaited(AnalyticsService.instance.logLogin(method: 'email'));
    if (!keepPending) {
      // Login always resumes on Home — mark session ready locally.
      isOnboarded = true;
      await _api.persistOnboarded(true);
      unawaited(refreshFromApi());
    }
    // If keepPending: caller must syncPendingAssessmentIfNeeded() before refresh.
    unawaited(PushNotificationService.instance.syncTokenToApi());
    notifyListeners();
    return data;
  }

  Future<Map<String, dynamic>> continueWithGoogle() async {
    final google = await GoogleAuthService.signIn();
    // Keep guest assessment when Create account / login comes after the quiz.
    final keepPending = hasPendingLocalAssessment;
    if (!keepPending) {
      _resetAssessmentLocalState(clearOnboardedFlag: false);
    }
    final data = await _api.loginWithGoogle(idToken: google.idToken);
    _applyAuthPayload(data);
    final created = data['created'] == true;
    if (created) {
      unawaited(AnalyticsService.instance.logSignUp(method: 'google'));
    } else {
      unawaited(AnalyticsService.instance.logLogin(method: 'google'));
    }
    // API-level routing: existing + assessment done → Home (skip onboarding).
    // If guest quiz is pending, leave onboarded false until sync writes the new answers.
    final profile = (data['profile'] as Map<String, dynamic>?) ?? {};
    final apiSaysNeedsOnboarding = data['needs_onboarding'] == true;
    final apiSaysComplete = data['onboarding_complete'] == true ||
        profile['onboarding_complete'] == true;
    if (!keepPending) {
      final done = data.containsKey('needs_onboarding')
          ? !apiSaysNeedsOnboarding
          : (!created && apiSaysComplete);
      isOnboarded = done;
      await _api.persistOnboarded(done);
      if (!created) {
        unawaited(refreshFromApi());
      }
    }
    unawaited(PushNotificationService.instance.syncTokenToApi());
    notifyListeners();
    return data;
  }

  Future<Map<String, dynamic>> continueWithApple() async {
    final apple = await AppleAuthService.signIn();
    final keepPending = hasPendingLocalAssessment;
    if (!keepPending) {
      _resetAssessmentLocalState(clearOnboardedFlag: false);
    }
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
    if (!keepPending) {
      final done = data.containsKey('needs_onboarding')
          ? !apiSaysNeedsOnboarding
          : (!created && apiSaysComplete);
      isOnboarded = done;
      await _api.persistOnboarded(done);
      if (!created) {
        unawaited(refreshFromApi());
      }
    }
    unawaited(PushNotificationService.instance.syncTokenToApi());
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
    hasPendingLocalAssessment = false;
    pendingAssessmentName = null;
    guestFunnelStage = '';
    pendingGuestTier = null;
    guestTrialUsed = false;
    guestPaywallReached = false;
    if (clearOnboardedFlag) {
      isOnboarded = false;
    }
  }

  /// Assessment → local plan → IAP → Create account. Persist for splash resume.
  Future<void> completeAssessmentLocally({
    required String name,
    required String gender,
    required String careerStage,
    required String careerType,
    required String confidence,
    required String problem,
    required String goal,
  }) async {
    final trimmed = name.trim();
    if (trimmed.length >= 2) {
      fullName = trimmed;
      pendingAssessmentName = trimmed;
    }
    answers.voiceProfile = gender;
    answers.careerStage = careerStage;
    answers.careerType = careerType;
    answers.confidence = confidence;
    answers.roadblock = problem;
    answers.primaryGoal = goal;
    computeAssessmentPlan();
    hasPendingLocalAssessment = true;
    guestFunnelStage = guestStageAwaitingIap;
    await persistGuestFunnelToDisk();
    unawaited(AnalyticsService.instance.logAssessmentCompleted(
      careerType: careerType,
      confidence: confidence,
      primaryRoadblock: problem,
    ));
    notifyListeners();
  }

  String _mapConfidenceForApi(String id) {
    switch (id) {
      case 'not_at_all':
      case 'slightly':
      case 'not_very':
        return 'not_very';
      case 'confident':
        return 'fairly';
      case 'fairly':
      case 'very':
        return id;
      default:
        return 'fairly';
    }
  }

  String _mapGoalForApi(String id) {
    switch (id) {
      case 'keep_engaged':
        return 'persuasive_arguments';
      case 'other':
        return 'clear_daily';
      default:
        return id;
    }
  }

  /// Profile API still uses male/female/non_binary; coach ids map into those.
  String _mapVoiceForApi(String id) {
    switch (id.trim().toLowerCase()) {
      case 'male':
      case 'david':
      case 'marcus':
        return 'male';
      case 'non_binary':
      case 'alex':
        return 'non_binary';
      case 'female':
      case 'sarah':
      case 'elena':
      default:
        return 'female';
    }
  }

  /// After Create account: push guest assessment (+ local IAP tier) to the server.
  Future<bool> syncPendingAssessmentIfNeeded() async {
    if (!isLoggedIn || !hasPendingLocalAssessment) return false;
    try {
      final quizName = (pendingAssessmentName ?? fullName).trim();
      await submitAssessmentToApi(
        name: quizName.length >= 2 ? quizName : 'Member',
        gender: _mapVoiceForApi(answers.voiceProfile ?? 'female'),
        careerStage: answers.careerStage ?? 'mid_level',
        careerType: answers.careerType ?? 'tech_product',
        confidence: _mapConfidenceForApi(answers.confidence ?? 'fairly'),
        problem: answers.roadblock ?? 'filler_rush',
        goal: _mapGoalForApi(answers.primaryGoal ?? 'calmer_confident'),
      );
      pendingAssessmentName = null;
      final tier = pendingGuestTier ??
          (isSubscribed ? subscriptionTier : null);
      if (tier != null &&
          (tier == 'monthly_pro' ||
              tier == 'annual_pro' ||
              tier == 'monthly' ||
              tier == 'annual')) {
        try {
          await choosePlanFromApi(
            tier == 'annual' || tier == 'annual_pro'
                ? 'annual_pro'
                : 'monthly_pro',
          );
          isSubscribed = true;
        } catch (e) {
          debugPrint('[Hakkiri] guest plan sync after signup failed: $e');
        }
      }
      hasPendingLocalAssessment = false;
      await clearGuestFunnel();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[Hakkiri] pending assessment sync failed: $e');
      // Keep pending so signup can retry; do not leave a stuck silent flag
      // that blocks later profile edits without a clear error.
      rethrow;
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
    final mappedVoice = _mapVoiceForApi(voiceProfile);
    final mappedConfidence = _mapConfidenceForApi(confidence);
    final mappedGoal = _mapGoalForApi(goal);
    final data = await _api.updateProfile({
      'full_name': name.trim(),
      'voice_profile': mappedVoice,
      'career_stage': careerStage,
      'career_type': careerType,
      'speaking_confidence': mappedConfidence,
      'primary_roadblock': roadblock,
      'primary_goal': mappedGoal,
    });
    if (name.trim().length >= 2) {
      fullName = name.trim();
      await _api.persistSessionFields(fullName: fullName);
    }
    // Always mirror what we just saved so UI updates even if a stale
    // guest-pending flag would skip _applyProfile.
    final careerChanged = answers.careerType != careerType;
    final focusChanged = answers.roadblock != roadblock ||
        answers.primaryGoal != mappedGoal;
    answers.careerStage = careerStage;
    answers.careerType = careerType;
    answers.confidence = mappedConfidence;
    answers.roadblock = roadblock;
    answers.primaryGoal = mappedGoal;
    // Keep coach id locally if user had one; otherwise store API voice bucket.
    final coachLike = voiceProfile.trim().toLowerCase();
    if (voiceLabels.containsKey(coachLike)) {
      answers.voiceProfile = coachLike;
    } else {
      answers.voiceProfile = mappedVoice;
    }
    computeAssessmentPlan();
    final profile = (data['profile'] as Map<String, dynamic>?) ?? {};
    _applyProfile(profile, force: true);
    // Goal / challenge change → recompute drills and refresh Today queue.
    if (focusChanged) {
      computeAssessmentPlan();
      _syncTodayQueueFromPersonalizedPlan();
      try {
        await refreshFromApi();
        // Keep the vote-based set if bootstrap still returns a stale queue.
        final refreshed = todayDrillSlugs;
        final expected = personalizedPlan?.initialDrills ?? const <String>[];
        if (expected.isNotEmpty &&
            (refreshed.isEmpty || refreshed.first != expected.first)) {
          _syncTodayQueueFromPersonalizedPlan();
        }
      } catch (_) {
        _syncTodayQueueFromPersonalizedPlan();
      }
    }
    // Career change → drop the old track's prompt so the next drill refetches.
    if (careerChanged) {
      selectedPrompt = null;
      unawaited(fetchNextPromptFromApi(excludeCurrent: false));
    }
    notifyListeners();
  }

  /// Rebuild home Today cards from [personalizedPlan] when focus changes.
  void _syncTodayQueueFromPersonalizedPlan() {
    final drills = personalizedPlan?.initialDrills ?? const <String>[];
    if (drills.isEmpty) return;

    Map<String, dynamic> cardFor(String slug, String order) {
      ActivityModel? match;
      for (final a in activities) {
        if (a.slug == slug) {
          match = a;
          break;
        }
      }
      return {
        'order': order,
        'activity': {
          'slug': slug,
          'name': match?.name ?? slug,
          'tagline': match?.tagline ?? '',
        },
        'duration_label': '~2 min',
      };
    }

    todayPrimary = cardFor(drills.first, '01');
    todayQueue = [
      for (var i = 1; i < drills.length && i < 3; i++)
        cardFor(drills[i], (i + 1).toString().padLeft(2, '0')),
    ];
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
    await clearGuestFunnel();
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
    _reflectionNotes.clear();
    reflectionPracticeSessions = 0;
    reflectionFocusAreasCompleted = 0;
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

  Future<void> deleteAccount() async {
    try {
      await GoogleAuthService.signOut();
    } catch (_) {}
    await _api.deleteAccount();
    await clearGuestFunnel();
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
    _reflectionNotes.clear();
    reflectionPracticeSessions = 0;
    reflectionFocusAreasCompleted = 0;
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
      await _api.persistSessionFields(fullName: fullName);
    }
    final profile = (data['profile'] as Map<String, dynamic>?) ?? {};
    _applyProfile(profile, force: true);
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
    // Keep assessment name when guest is about to sync onto an existing account.
    final quizName = (pendingAssessmentName ??
            (hasPendingLocalAssessment ? fullName : null))
        ?.trim();
    if (quizName != null && quizName.length >= 2) {
      fullName = quizName;
      pendingAssessmentName = quizName;
    } else {
      fullName = (user['full_name'] ?? fullName).toString();
    }
    email = (user['email'] ?? email).toString();
    isLoggedIn = true;
    if (email.isNotEmpty || fullName.trim().isNotEmpty) {
      unawaited(_api.persistSessionFields(
        email: email.isNotEmpty ? email : null,
        fullName: fullName.trim().isNotEmpty ? fullName.trim() : null,
      ));
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

  void _applyProfile(Map<String, dynamic> profile, {bool force = false}) {
    if (profile.isEmpty) return;
    // Pending guest assessment must win until syncPendingAssessmentIfNeeded
    // pushes it — otherwise an existing account's old profile wipes the quiz.
    final applyAnswers = force || !hasPendingLocalAssessment;
    if (applyAnswers) {
      if (profile.containsKey('voice_profile')) {
        final v = profile['voice_profile'];
        if (v != null) answers.voiceProfile = v.toString();
      }
      if (profile.containsKey('career_stage')) {
        final v = profile['career_stage'];
        if (v != null) answers.careerStage = v.toString();
      }
      if (profile.containsKey('career_type')) {
        final v = profile['career_type'];
        if (v != null) answers.careerType = v.toString();
      }
      if (profile.containsKey('speaking_confidence')) {
        final v = profile['speaking_confidence'];
        if (v != null) answers.confidence = v.toString();
      }
      if (profile.containsKey('primary_roadblock')) {
        final v = profile['primary_roadblock'];
        if (v != null) answers.roadblock = v.toString();
      }
      if (profile.containsKey('primary_goal')) {
        final v = profile['primary_goal'];
        if (v != null) answers.primaryGoal = v.toString();
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
    }
    // Server is source of truth — do NOT infer from leftover local answers.
    if (profile.containsKey('onboarding_complete') && applyAnswers) {
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

      final reflectionsBlock = data['reflections'];
      if (reflectionsBlock is Map<String, dynamic>) {
        _applyReflections(reflectionsBlock);
      }

      _applyActivityLevels(
        (data['activity_levels'] as Map?)?.map(
              (k, v) => MapEntry(k.toString(), v.toString()),
            ) ??
            const {},
      );
      final promptRaw = data['coaching_prompt'];
      coachingPrompt = promptRaw is Map
          ? Map<String, dynamic>.from(promptRaw)
          : null;
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

  Future<void> choosePlanFromApi(
    String tier, {
    bool startTrial = false,
  }) async {
    final data = await _api.chooseSubscription(
      tier,
      startTrial: startTrial,
    );
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
        description: 'A random high-stakes question flashes on screen with a 5-second delay. You speak for 60 seconds using bottom-line-up-front structure.',
        cognitiveMechanism: 'Rapid lexical retrieval and on-the-spot framing under stress',
        prepDurationSeconds: 5,
        defaultDurationSeconds: 60,
        benefits: ['High cognitive agility under stress', 'Higher perceived authority', 'Eliminates meeting waffle'],
        successMeasures: ['Latency & stall tactics', 'Structural coherence', 'Composition & fillers'],
      ),
      const ActivityModel(
        slug: 'cut_it_in_half',
        name: 'Cut It In Half',
        isMvp: true,
        tagline: 'Extreme information synthesis and brevity',
        description:
            'You get a longer passage and 60 seconds to summarise it out loud — keep the key points, cut the fluff.',
        cognitiveMechanism: 'Information distillation, compression, and high-density verbalization',
        prepDurationSeconds: 60,
        defaultDurationSeconds: 60,
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
        prepDurationSeconds: 5,
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
        industries: ['corporate_finance', 'general'],
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
        industries: ['sales_marketing'],
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
        industries: ['tech_product'],
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
        industries: ['healthcare_edu'],
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
        industries: ['general'],
        durationSeconds: 60,
        prepSeconds: 5,
      ),
      const PromptModel(
        id: 'tf_02',
        activitySlug: 'think_fast',
        difficulty: 'intermediary',
        promptText: 'Your team has missed a major project deadline due to a miscommunication. How do you explain this to your client without blaming your team?',
        objective: 'Take immediate accountability, outline corrective sprint, and maintain trust.',
        exemplarResponse: 'We take full responsibility for the milestone delay. A breakdown in internal review caused an unexpected bottleneck. Here is our recovery plan: senior engineers are reallocated, and we deliver by Thursday 2 PM.',
        tags: ['client_management', 'accountability'],
        industries: ['general', 'corporate_finance', 'tech_product', 'sales_marketing'],
        durationSeconds: 60,
        prepSeconds: 5,
      ),
      const PromptModel(
        id: 'tf_03',
        activitySlug: 'think_fast',
        difficulty: 'professional',
        promptText: 'Our company’s core software platform just went offline globally, and clients are panicking on social media. Give an immediate 60-second update to the board of directors.',
        objective: 'Command total authority, communicate triage status (BLUF), and outline communication protocol.',
        exemplarResponse: 'Board members: at 14:10 UTC, European and US data centers experienced an unexpected cascade. Triage is active; DNS rollback is at 60% completion. Recovery target is 35 minutes. Public status page has been updated.',
        tags: ['crisis', 'boardroom'],
        industries: ['tech_product', 'corporate_finance'],
        durationSeconds: 60,
        prepSeconds: 5,
      ),

      // Cut It In Half — promptText = passage; exemplar = short "must keep" brief
      const PromptModel(
        id: 'cih_b_fire_alarm',
        activitySlug: 'cut_it_in_half',
        difficulty: 'beginner',
        title: 'Office closed Friday',
        promptText:
            'Hi all, just a quick reminder that the office will be closed on Friday afternoon for the fire alarm upgrade. The contractors will be on site from 1pm, so everyone needs to leave the building by then. Please make sure you take your laptop home with you on Friday morning, because you won\'t be able to get back in until Monday. Thanks for your patience.',
        objective: 'Cut this to the facts. Lead with what people must do.',
        exemplarResponse:
            'Office closed Friday from 1pm; take your laptop home; no access until Monday.',
        tags: ['brevity'],
        durationSeconds: 60,
        prepSeconds: 60,
      ),
      const PromptModel(
        id: 'cih_01',
        activitySlug: 'cut_it_in_half',
        difficulty: 'beginner',
        title: 'Slack After-Hours Communication Policy',
        promptText:
            'Hey team, I just wanted to jump on here and let everyone know that we\'ve been looking at how we manage our internal communications lately. It turns out that a lot of people are feeling pretty overwhelmed by the sheer volume of Slack messages flying around every day, especially after hours. Because of that, leadership has decided that starting next Monday, we are going to implement a new policy where no one is expected to reply to any Slack messages after 6:00 PM. We really want everyone to get some proper downtime so we can keep our productivity high during normal working hours.',
        objective: 'Cut this message roughly in half. Lead with the policy.',
        exemplarResponse:
            'From Monday, nobody is expected to reply to Slack after 6pm. The aim is real downtime so daytime work stays focused.',
        tags: ['internal_comms', 'brevity'],
        durationSeconds: 60,
        prepSeconds: 60,
      ),
      const PromptModel(
        id: 'cih_i_ward_report',
        activitySlug: 'cut_it_in_half',
        difficulty: 'intermediary',
        title: 'Ward handoff note',
        promptText:
            'So basically overnight the patient was a bit unsettled and we tried a few things and the observations were mostly okay but then towards morning the oxygen crept up a little and we called the doctor who said to continue and review later. Family were anxious at the bedside and we explained that stable does not mean going home today. Pain was managed with the usual dose and she took some breakfast. Please make sure the allergy note from last shift is still on the chart before the ward round.',
        objective: 'Cut this handoff to status, change, and action.',
        exemplarResponse:
            'Overnight: restless, obs mostly stable; oxygen need rose toward morning — doctor said continue and review later. Allergy note must stay on the chart before ward round.',
        tags: ['healthcare'],
        industries: ['healthcare_edu'],
        durationSeconds: 60,
        prepSeconds: 60,
      ),

      // 1 Minute Expert — corporate / finance local fallbacks
      const PromptModel(
        id: 'ome_cf_01',
        activitySlug: 'one_minute_expert',
        difficulty: 'intermediary',
        title: 'Working capital',
        promptText:
            'Explain working capital to a non-finance stakeholder and why it can kill a profitable company.',
        objective: 'Define it, then one concrete risk.',
        exemplarResponse:
            'Working capital is the cash tied up in day-to-day operations — stock, unpaid invoices, and bills you still owe. A company can show profit on paper and still run out of cash if customers pay late while suppliers demand cash now.',
        tags: ['corporate_finance', 'cash'],
        industries: ['corporate_finance'],
        durationSeconds: 60,
        prepSeconds: 5,
      ),
      const PromptModel(
        id: 'ome_cf_02',
        activitySlug: 'one_minute_expert',
        difficulty: 'beginner',
        title: 'EBITDA in plain English',
        promptText:
            'Explain what EBITDA means to a smart colleague who is not in finance.',
        objective: 'One clear definition, then why leaders still look at it.',
        exemplarResponse:
            'EBITDA is a rough view of operating profit before interest, tax, and the accounting for assets wearing out. Leaders use it to compare how the core business is performing without financing or tax noise.',
        tags: ['corporate_finance'],
        industries: ['corporate_finance'],
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
        exemplarResponse:
            'Chef, think of Google as the person on the corner giving directions. SEO is making your bakery the clearest answer — right name, right street, and proof people like what you bake — so that guide points hungry customers to your door.',
        tags: ['marketing', 'local_business'],
        durationSeconds: 60,
        prepSeconds: 5,
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
  /// Yearly starts a 7-day trial on the server the first time; monthly is paid from day one.
  Future<void> activatePaidPlan(String tier) async {
    final normalized =
        tier == 'annual_pro' || tier == 'annual' ? 'annual_pro' : 'monthly_pro';
    final isAnnual = normalized == 'annual_pro';
    subscriptionTier = normalized;
    subscriptionStatus = isAnnual ? 'trialing' : 'active';
    subscriptionPriceFormatted =
        isAnnual ? '7-day free trial' : '£9.99/mo';
    isSubscribed = true;
    _supabase.updateSubscription(
      userId: userId,
      tier: normalized,
      priceGbp: isAnnual ? 0 : 9.99,
    );
    // Guest bought before Create account — keep local, upload after signup.
    if (!isLoggedIn) {
      await markGuestAwaitingAccount(tier: normalized);
      notifyListeners();
      return;
    }
    try {
      await choosePlanFromApi(normalized, startTrial: isAnnual);
    } catch (e) {
      debugPrint('[Hakkiri] Warning syncing subscription to API: $e');
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

  void _applyActivityLevels(Map<String, String> levels) {
    if (levels.isEmpty) return;
    activityLevels = {...activityLevels, ...levels};
    final slug = selectedActivity?.slug;
    if (slug != null && activityLevels[slug] != null) {
      selectedDifficulty = activityLevels[slug]!;
    }
  }

  String levelForActivity(String slug) {
    return activityLevels[normalizeActivitySlug(slug)] ?? selectedDifficulty;
  }

  void selectActivity(String slug) {
    final resolved = normalizeActivitySlug(slug);
    final match = activities.where((a) => a.slug == resolved);
    if (match.isEmpty) {
      debugPrint('[Hakkiri] selectActivity: unknown slug "$resolved"');
      return;
    }
    selectedActivity = match.first;
    if (activityLevels[resolved] != null) {
      selectedDifficulty = activityLevels[resolved]!;
    }
    // Drop a prompt that belongs to a different drill (e.g. leftover Think Fast).
    if (selectedPrompt != null &&
        selectedPrompt!.activitySlug != resolved) {
      selectedPrompt = null;
    }
    _updateSelectedPrompt();
    notifyListeners();
    if (isLoggedIn) {
      unawaited(fetchNextPromptFromApi());
    }
  }

  Future<void> decideCoachingPrompt(String choice) async {
    if (!_api.isLoggedIn) {
      coachingPrompt = null;
      notifyListeners();
      return;
    }
    try {
      final data = await _api.decideCoaching(choice);
      coachingPrompt = null;
      final levels = data['activity_levels'];
      if (levels is Map) {
        _applyActivityLevels(
          levels.map((k, v) => MapEntry(k.toString(), v.toString())),
        );
      }
      notifyListeners();
      await refreshFromApi();
    } catch (_) {
      coachingPrompt = null;
      notifyListeners();
    }
  }

  Future<void> setActivityLevel(String slug, String difficulty) async {
    final resolved = normalizeActivitySlug(slug);
    activityLevels[resolved] = difficulty;
    if (selectedActivity?.slug == resolved) {
      selectedDifficulty = difficulty;
    }
    notifyListeners();
    if (!_api.isLoggedIn) return;
    try {
      await _api.setCoachingLevel(
        activitySlug: resolved,
        difficulty: difficulty,
      );
      await fetchNextPromptFromApi();
    } catch (_) {}
  }

  /// Keep [selectedActivity] aligned with the drill UI the user is viewing.
  void ensureActivitySelected(String slug) {
    final resolved = normalizeActivitySlug(slug);
    if (selectedActivity?.slug == resolved) {
      syncDifficultyForActivity(resolved);
      return;
    }
    selectActivity(resolved);
  }

  /// Questions always follow the assigned activity level, not a session picker.
  void syncDifficultyForActivity(String slug) {
    final assigned = levelForActivity(slug);
    if (selectedDifficulty == assigned) return;
    selectedDifficulty = assigned;
    notifyListeners();
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
  /// Guests use the same public `/prompts/next` catalog (no JWT).
  Future<bool> fetchNextPromptFromApi({bool excludeCurrent = true}) async {
    final activity = selectedActivity;
    if (activity == null) return false;
    final requestSlug = activity.slug;
    try {
      selectedDifficulty = levelForActivity(requestSlug);
      final difficulty = selectedDifficulty == 'pro'
          ? 'professional'
          : selectedDifficulty == 'i_dont_know'
              ? 'intermediary'
              : selectedDifficulty;
      final excludeId = excludeCurrent &&
              selectedPrompt != null &&
              selectedPrompt!.activitySlug == requestSlug &&
              _looksLikeCatalogPromptId(selectedPrompt!.id)
          ? selectedPrompt!.id
          : null;
      final data = await _api.nextPrompt(
        activitySlug: requestSlug,
        difficulty: difficulty,
        careerType: answers.careerType,
        excludePromptId: excludeId,
        requireAuth: _api.isLoggedIn,
      );
      // Ignore stale responses if the user switched drills mid-flight.
      if (selectedActivity?.slug != requestSlug) {
        debugPrint(
          '[Hakkiri] drop stale prompt for $requestSlug '
          '(now ${selectedActivity?.slug})',
        );
        return false;
      }
      final promptMap = data['prompt'];
      if (promptMap is Map) {
        final next =
            PromptModel.fromJson(Map<String, dynamic>.from(promptMap));
        final nextSlug = normalizeActivitySlug(next.activitySlug);
        if (nextSlug.isNotEmpty && nextSlug != requestSlug) {
          debugPrint(
            '[Hakkiri] API prompt activity mismatch: '
            'wanted $requestSlug got $nextSlug — rotating local',
          );
          rotateLocalPrompt();
          return true;
        }
        selectedPrompt = next;
        notifyListeners();
        return true;
      }
    } catch (_) {
      if (selectedActivity?.slug != requestSlug) return false;
      // Network failed — still rotate locally so the same question does not stick.
      rotateLocalPrompt();
      return true;
    }
    if (selectedActivity?.slug != requestSlug) return false;
    rotateLocalPrompt();
    return true;
  }

  /// True when [selectedPrompt] belongs to [slug] (or current activity).
  bool promptMatchesActivity([String? slug]) {
    final want = normalizeActivitySlug(slug ?? selectedActivity?.slug ?? '');
    if (want.isEmpty || selectedPrompt == null) return false;
    return normalizeActivitySlug(selectedPrompt!.activitySlug) == want;
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

    // Hard industry filter: never serve another track's exclusive prompt.
    final hasCareer = career != null &&
        career.isNotEmpty &&
        career != 'general' &&
        career != 'other';
    if (hasCareer) {
      final safe = pool
          .where((p) => p.matchesCareer(career) || p.isGeneralIndustry)
          .toList();
      final specific = safe.where((p) => p.matchesCareer(career)).toList();
      final general = safe.where((p) => p.isGeneralIndustry).toList();
      if (specific.isNotEmpty) {
        pool = specific;
      } else if (general.isNotEmpty) {
        pool = general;
      } else {
        pool = safe;
      }
    } else {
      final general = pool.where((p) => p.isGeneralIndustry).toList();
      if (general.isNotEmpty) pool = general;
    }

    // Stay on this activity — never fall back to an unrelated bank prompt.
    if (pool.isEmpty) {
      final sameActivity = promptBank
          .where((p) => p.activitySlug == selectedActivity!.slug)
          .where(
            (p) =>
                !hasCareer ||
                p.matchesCareer(career) ||
                p.isGeneralIndustry,
          )
          .toList();
      if (sameActivity.isEmpty) return;
      sameActivity.shuffle();
      selectedPrompt = sameActivity.first;
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
    /// Debate Me: opening take (persisted separately from rebuttal).
    String? localOpeningAudioTempPath,
    String? audioBase64,
    String audioMimeType = 'audio/mp4',
    bool consumeGuestTrial = false,
  }) async {
    final prompt = selectedPrompt ?? promptBank.first;
    final mode =
        conversationMode == 'back_and_forth' ? 'back_and_forth' : 'single';
    final resolvedPlanExtra = planExtra ?? pendingPlanExtra;
    final resolvedIsRetry =
        isRetry || resolvedPlanExtra == 'targeted_retry';

    if ((audioBase64 == null || audioBase64.isEmpty) &&
        transcript.trim().isEmpty) {
      throw Exception(
        'No audio to score. Check microphone permission and try again.',
      );
    }

    // Persist local audio in parallel with Gemini so the overlay feels faster.
    final localId = _uuid.v4();
    final persistFuture =
        (localAudioTempPath != null && localAudioTempPath.isNotEmpty)
            ? SessionAudioStore.instance.persist(
                sessionId: localId,
                tempPath: localAudioTempPath,
              )
            : Future<String?>.value(null);
    final persistOpeningFuture =
        (localOpeningAudioTempPath != null &&
                localOpeningAudioTempPath.isNotEmpty)
            ? SessionAudioStore.instance.persist(
                sessionId: '${localId}_opening',
                tempPath: localOpeningAudioTempPath,
              )
            : Future<String?>.value(null);

    // Prefer Gemini Flash analysis via API — never invent a placeholder score.
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
      final msg = err is HakkiriApiException
          ? err.message
          : 'We could not score this take. Check your connection and try again.';
      throw Exception(msg);
    }

    latestFeedback = feedback;
    final audioPath = await persistFuture;
    final openingAudioPath = await persistOpeningFuture;

    var turns = List<ConversationTurn>.from(conversationTurns);
    if (prompt.activitySlug == 'debate_me' ||
        prompt.activitySlug == 'debate') {
      turns = PracticeSessionRecord.debateTurnsFrom(
        transcript: resolvedTranscript,
        fallback: turns,
      );
      if (turns.length >= 2) {
        resolvedTranscript = PracticeSessionRecord.formatDebateTranscript(
          opening: turns[0].text,
          pushback: turns.length > 1 && turns[1].role == 'coach'
              ? turns[1].text
              : PracticeSessionRecord.extractPushback(resolvedTranscript),
          rebuttal: turns.length > 2
              ? turns[2].text
              : PracticeSessionRecord.extractRebuttal(resolvedTranscript),
        );
      }
    }

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
      conversationTurns: turns,
      timestamp: DateTime.now(),
      durationSeconds: durationSeconds,
      feedback: feedback,
      localAudioPath: audioPath,
      localOpeningAudioPath: openingAudioPath,
    );
    latestSession = record;
    sessionHistory.insert(0, record);
    if (consumeGuestTrial) {
      unawaited(markGuestTrialConsumed());
    }
    _syncTodayPlanAfterLocalSession(
      activitySlug: prompt.activitySlug,
      isRetry: resolvedIsRetry,
      planExtra: resolvedPlanExtra,
    );

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
        conversationTurns: turns,
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
    // Guests use the same Gemini path for the one free try (no JWT), then IAP.
    selectedDifficulty = levelForActivity(prompt.activitySlug);
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
        await SessionAudioStore.instance.rekey(
          fromId: '${localRecordId}_opening',
          toId: '${apiRecord.id}_opening',
        );
        final audio = localAudioPath ??
            await SessionAudioStore.instance.pathFor(apiRecord.id);
        final openingAudio =
            await SessionAudioStore.instance.pathFor('${apiRecord.id}_opening');
        final merged = apiRecord.copyWith(
          localAudioPath: audio,
          localOpeningAudioPath: openingAudio,
          // Preserve full prompt/transcript if API omitted older fields.
          promptText: apiRecord.promptText.isNotEmpty
              ? apiRecord.promptText
              : prompt.promptText,
          transcript: apiRecord.transcript.isNotEmpty
              ? apiRecord.transcript
              : transcript,
          // Keep guided Debate / voice-practice chat if API echo is empty.
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
