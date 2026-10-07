import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/assessment_model.dart';
import '../models/activity_model.dart';
import '../models/session_model.dart';
import '../core/services/speech_evaluator_service.dart';
import '../core/services/supabase_service.dart';

class AppStateProvider extends ChangeNotifier {
  final SupabaseService _supabase = SupabaseService.instance;
  final Uuid _uuid = const Uuid();

  String userId = 'usr_hakkiri_demo_user';
  bool isOnboarded = false;

  // Assessment State
  final AssessmentAnswers answers = AssessmentAnswers();
  PersonalizedPlanModel? personalizedPlan;

  // Subscription State
  String subscriptionTier = 'free_trial';
  String subscriptionPriceFormatted = '£69.99/yr (7-Day Trial)';
  bool isSubscribed = true;

  // Gamification (Enforcing fair scoring: XP & streaks separate from skill scores)
  int currentStreak = 3;
  int totalXp = 450;
  int completedSessions = 8;

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

  AppStateProvider() {
    _initCatalog();
    selectedActivity = activities.first;
    _updateSelectedPrompt();
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
    personalizedPlan = PersonalizedPlanModel(
      headline: 'Filler Elimination & Executive Authority Program',
      summary: 'A curated daily routine engineered to transition you from hesitant thinking to commanding executive clarity.',
      recommendedTrack: track,
      primaryRoadblock: answers.roadblock ?? 'excessive_filler_words',
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
    _supabase.updateSubscription(
      userId: userId,
      tier: tier,
      priceGbp: isAnnual ? 69.99 : 9.99,
    );
    notifyListeners();
  }

  void selectActivity(String slug) {
    selectedActivity = activities.firstWhere((a) => a.slug == slug, orElse: () => activities.first);
    _updateSelectedPrompt();
    notifyListeners();
  }

  void setDifficulty(String diff) {
    selectedDifficulty = diff;
    _updateSelectedPrompt();
    notifyListeners();
  }

  void _updateSelectedPrompt() {
    if (selectedActivity == null) return;

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

    // Default to the flagship client prompt for think_fast
    if (selectedActivity!.slug == 'think_fast') {
      final stakeholderPrompt = promptBank.where((p) => p.id == 'tf_stakeholder').toList();
      if (stakeholderPrompt.isNotEmpty) {
        selectedPrompt = stakeholderPrompt.first;
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

  EvaluationFeedback evaluateCurrentSession({
    required String transcript,
    required int durationSeconds,
    bool isRetry = false,
  }) {
    final prompt = selectedPrompt ?? promptBank.first;
    final feedback = SpeechEvaluatorService.evaluateSpeech(
      prompt: prompt,
      transcript: transcript,
      durationSeconds: durationSeconds,
      isRetry: isRetry,
    );

    latestFeedback = feedback;

    // Create and save local session history record
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

    // Save session in Supabase backend
    _supabase.recordPracticeSession(
      userId: userId,
      activitySlug: prompt.activitySlug,
      promptId: prompt.id,
      transcript: transcript,
      feedback: feedback,
    );

    notifyListeners();
    return feedback;
  }

  void finishDrillAndIncrementStreak() {
    currentStreak += 1;
    totalXp += 50; // XP kept separate from skill scores
    completedSessions += 1;
    notifyListeners();
  }
}
