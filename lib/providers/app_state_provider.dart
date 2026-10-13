import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/assessment_model.dart';
import '../models/activity_model.dart';
import '../models/session_model.dart';
import '../core/services/google_auth_service.dart';
import '../core/services/hakkiri_api_service.dart';
import '../core/services/speech_evaluator_service.dart';
import '../core/services/supabase_service.dart';

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

  // Assessment State
  final AssessmentAnswers answers = AssessmentAnswers();
  PersonalizedPlanModel? personalizedPlan;

  // Subscription State
  String subscriptionTier = 'free_trial';
  String subscriptionStatus = 'trialing';
  String subscriptionPriceFormatted = '7-day trial';
  String subscriptionRenewalLabel = '';
  bool isSubscribed = false;

  // Settings
  int dailyAnchorMinutes = 5;
  String audioPrivacy = 'encrypted_on_device';
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
  };

  static const voiceLabels = {
    'male': 'Male',
    'female': 'Female',
    'non_binary': 'Non-binary / Vocal alignment',
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

  int completedTodayDrills() {
    final today = DateTime.now();
    final key = '${today.year}-${today.month}-${today.day}';
    final done = sessionHistory.where((s) {
      final stamp = '${s.timestamp.year}-${s.timestamp.month}-${s.timestamp.day}';
      return stamp == key && todayDrillSlugs.contains(s.activitySlug);
    }).map((s) => s.activitySlug).toSet();
    return done.length;
  }

  Future<void>? _sessionReady;

  AppStateProvider() {
    _initCatalog();
    selectedActivity = activities.first;
    _updateSelectedPrompt();
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
    // Signup always starts the assessment funnel.
    isOnboarded = false;
    await _api.persistOnboarded(false);
    notifyListeners();
  }

  Future<Map<String, dynamic>> loginAccount({
    required String email,
    required String password,
  }) async {
    _resetAssessmentLocalState();
    final data = await _api.login(email: email, password: password);
    _applyAuthPayload(data);
    // Login always resumes on Home — mark session ready locally.
    isOnboarded = true;
    await _api.persistOnboarded(true);
    unawaited(refreshFromApi());
    return data;
  }

  Future<Map<String, dynamic>> continueWithGoogle() async {
    final google = await GoogleAuthService.signIn();
    _resetAssessmentLocalState();
    final data = await _api.loginWithGoogle(idToken: google.idToken);
    _applyAuthPayload(data);
    final created = data['created'] == true;
    final profile = (data['profile'] as Map<String, dynamic>?) ?? {};
    final done = !created && profile['onboarding_complete'] == true;
    isOnboarded = done;
    await _api.persistOnboarded(done);
    if (!created) {
      unawaited(refreshFromApi());
    }
    return data;
  }

  void _resetAssessmentLocalState() {
    answers.voiceProfile = null;
    answers.careerStage = null;
    answers.careerType = null;
    answers.confidence = null;
    answers.roadblock = null;
    answers.primaryGoal = null;
    personalizedPlan = null;
    isOnboarded = false;
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

  Future<void> logout() async {
    try {
      await GoogleAuthService.signOut();
    } catch (_) {}
    await _api.clearSession();
    userId = '';
    fullName = '';
    email = '';
    isLoggedIn = false;
    isOnboarded = false;
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
    if (settings['industry_track'] != null) {
      answers.careerType = settings['industry_track'].toString();
    }
    if (settings['voice_profile'] != null) {
      answers.voiceProfile = settings['voice_profile'].toString();
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
    isBootstrapping = true;
    notifyListeners();
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

      challenges = ((data['challenges'] as List?) ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      final sessionData = (data['sessions'] as Map<String, dynamic>?) ?? {};
      final rows = ((sessionData['sessions'] as List?) ?? [])
          .whereType<Map>()
          .map((e) => PracticeSessionRecord.fromApi(Map<String, dynamic>.from(e)))
          .toList();
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
      isBootstrapping = false;
      notifyListeners();
    }
  }

  Future<void> freezeStreakFromApi() async {
    final data = await _api.freezeStreak();
    _applyStreak(data['streak'] as Map<String, dynamic>?);
    notifyListeners();
  }

  Future<void> joinChallengeFromApi(String slug) async {
    await _api.joinChallenge(slug);
    await refreshFromApi();
  }

  Future<void> choosePlanFromApi(String tier) async {
    final data = await _api.chooseSubscription(tier);
    _applySubscription((data['subscription'] as Map<String, dynamic>?) ?? {});
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
        name: '1 Minute Expert',
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

    // Logic determined by assessment:
    // 1. Level of activities:
    if (careerStage == 'early' || confidence == 'not_very') {
      selectedDifficulty = 'beginner';
    } else if (careerStage == 'exec' || confidence == 'very') {
      selectedDifficulty = 'pro';
    } else {
      selectedDifficulty = 'intermediary';
    }

    _updateSelectedPrompt();
    completeAssessment();
  }

  void completeAssessment() {
    final track = answers.careerType ?? 'corporate_finance';
    personalizedPlan ??= PersonalizedPlanModel(
      headline: 'Filler Elimination & Executive Authority Program',
      summary: 'A curated daily routine engineered to transition you from hesitant thinking to commanding executive clarity.',
      recommendedTrack: track,
      primaryRoadblock: answers.roadblock ?? 'excessive_filler_words',
      focusLine: focusLine,
      initialDrills: const ['think_fast', 'cut_it_in_half', 'debate_me'],
      milestones: const [
        MilestoneItem(week: 1, title: 'Cognitive Agility & Crutch Decoupling', focus: 'Eliminating instinctive "um" and "basically" in 60s drills.'),
        MilestoneItem(week: 2, title: 'Brevity & Bottom-Line-Up-Front (BLUF)', focus: 'Compressing ideas by 50% within first 5 seconds.'),
        MilestoneItem(week: 3, title: 'Executive Presence & Power Silence', focus: 'Commanding meetings with 1–2s power pauses.'),
        MilestoneItem(week: 4, title: 'High-Stakes Debate Mastery', focus: 'Reframing hostile pushback with steady pitch.'),
      ],
    );

    isOnboarded = true;
    _supabase.saveUserProfile(
      userId: userId,
      answers: answers,
      plan: personalizedPlan!,
    );
    notifyListeners();
  }

  void selectSubscription(String tier) {
    subscriptionTier = tier;
    final isAnnual = tier == 'annual_pro';
    subscriptionPriceFormatted = isAnnual ? '£69.99/yr' : '£9.99/mo';
    isSubscribed = true;
    _supabase.updateSubscription(
      userId: userId,
      tier: tier,
      priceGbp: isAnnual ? 69.99 : 9.99,
    );
    notifyListeners();
    if (isLoggedIn) {
      choosePlanFromApi(tier);
    }
  }

  void selectActivity(String slug) {
    selectedActivity = activities.firstWhere((a) => a.slug == slug, orElse: () => activities.first);
    _updateSelectedPrompt();
    notifyListeners();
    if (isLoggedIn) {
      unawaited(fetchNextPromptFromApi());
    }
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
  Future<void> fetchNextPromptFromApi() async {
    final activity = selectedActivity;
    if (!_api.isLoggedIn || activity == null) return;
    try {
      final difficulty = selectedDifficulty == 'pro'
          ? 'professional'
          : selectedDifficulty == 'i_dont_know'
              ? 'intermediary'
              : selectedDifficulty;
      final data = await _api.nextPrompt(
        activitySlug: activity.slug,
        difficulty: difficulty,
        careerType: answers.careerType,
      );
      final promptMap = data['prompt'];
      if (promptMap is Map) {
        selectedPrompt =
            PromptModel.fromJson(Map<String, dynamic>.from(promptMap));
        notifyListeners();
      }
    } catch (_) {
      // Keep local promptBank selection if the network call fails.
    }
  }

  void _updateSelectedPrompt() {
    if (selectedActivity == null) return;

    // If we already hold a catalog prompt for this activity (from /prompts/next),
    // do not overwrite it with the local stakeholder default.
    if (selectedPrompt != null &&
        selectedPrompt!.activitySlug == selectedActivity!.slug &&
        _looksLikeCatalogPromptId(selectedPrompt!.id)) {
      return;
    }

    // Career specific prompt matching based on assessment:
    final career = answers.careerType;
    if (career != null && career.isNotEmpty) {
      final careerMatches = promptBank.where((p) =>
          p.activitySlug == selectedActivity!.slug &&
          p.tags.contains(career)).toList();
      if (careerMatches.isNotEmpty) {
        selectedPrompt = careerMatches.first;
        return;
      }
    }

    final targetDiff = selectedDifficulty == 'i_dont_know' ? 'intermediary' : selectedDifficulty;
    final matches = promptBank.where((p) => p.activitySlug == selectedActivity!.slug && p.difficulty == targetDiff).toList();
    if (matches.isNotEmpty) {
      selectedPrompt = matches.first;
    } else {
      final actMatches = promptBank.where((p) => p.activitySlug == selectedActivity!.slug).toList();
      selectedPrompt = actMatches.isNotEmpty ? actMatches.first : promptBank.first;
    }
  }

  Future<EvaluationFeedback> evaluateCurrentSession({
    required String transcript,
    required int durationSeconds,
    bool isRetry = false,
  }) async {
    final prompt = selectedPrompt ?? promptBank.first;

    // Prefer Gemini Flash analysis via API (doc requirement).
    // Fall back to on-device heuristic only if the AI call fails / offline.
    EvaluationFeedback feedback;
    try {
      feedback = await _analyzeSpeechViaApi(
        prompt: prompt,
        transcript: transcript,
        durationSeconds: durationSeconds,
        isRetry: isRetry,
      );
    } catch (_) {
      feedback = SpeechEvaluatorService.evaluateSpeech(
        prompt: prompt,
        transcript: transcript,
        durationSeconds: durationSeconds,
        isRetry: isRetry,
      );
    }

    latestFeedback = feedback;

    // Create and save local session history record immediately
    final record = PracticeSessionRecord(
      id: _uuid.v4(),
      activitySlug: prompt.activitySlug,
      activityName: selectedActivity?.name ?? 'Drill Session',
      promptTitle: prompt.title ?? (prompt.promptText.length > 40 ? '${prompt.promptText.substring(0, 40)}...' : prompt.promptText),
      timestamp: DateTime.now(),
      durationSeconds: durationSeconds,
      feedback: feedback,
    );
    sessionHistory.insert(0, record);

    // Save session in Supabase backend (best-effort / legacy)
    _supabase.recordPracticeSession(
      userId: userId,
      activitySlug: prompt.activitySlug,
      promptId: prompt.id,
      transcript: transcript,
      feedback: feedback,
    );

    if (isLoggedIn) {
      await _persistSessionToApi(
        prompt: prompt,
        transcript: transcript,
        durationSeconds: durationSeconds,
        feedback: feedback,
        isRetry: isRetry,
        localRecordId: record.id,
      );
    } else {
      finishDrillAndIncrementStreak();
    }

    notifyListeners();
    return feedback;
  }

  Future<EvaluationFeedback> _analyzeSpeechViaApi({
    required PromptModel prompt,
    required String transcript,
    required int durationSeconds,
    required bool isRetry,
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
    });

    final feedbackMap = data['feedback'];
    if (feedbackMap is! Map) {
      throw HakkiriApiException('AI analysis returned no feedback.');
    }
    return EvaluationFeedback.fromJson(Map<String, dynamic>.from(feedbackMap));
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
  }) async {
    try {
      final data = await _api.createSession({
        'activity_slug': prompt.activitySlug,
        if (_looksLikeCatalogPromptId(prompt.id)) 'prompt_id': prompt.id,
        'prompt_title': prompt.title ?? prompt.promptText,
        'difficulty': selectedDifficulty == 'pro'
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
        'feedback': feedback.toJson(),
      });
      _applyStreak(data['streak'] as Map<String, dynamic>?);

      // Keep the local row until refresh replaces it with the server copy.
      final session = data['session'];
      if (session is Map) {
        final apiRecord =
            PracticeSessionRecord.fromApi(Map<String, dynamic>.from(session));
        final idx = sessionHistory.indexWhere((s) => s.id == localRecordId);
        if (idx >= 0) {
          sessionHistory[idx] = apiRecord;
        }
      }
      await refreshFromApi();
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
}
