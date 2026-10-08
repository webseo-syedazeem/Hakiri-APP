function activityJson(doc) {
  return {
    slug: doc.slug,
    name: doc.name,
    is_mvp: doc.isMvp,
    tagline: doc.tagline,
    description: doc.description,
    cognitive_mechanism: doc.cognitiveMechanism,
    prep_duration_seconds: doc.prepDurationSeconds,
    default_duration_seconds: doc.defaultDurationSeconds,
    benefits: doc.benefits,
    success_measures: doc.successMeasures,
    rubrics: (doc.rubrics || []).map((r) => ({
      key: r.key,
      name: r.name,
      beginner: r.beginner,
      intermediary: r.intermediary,
      professional: r.professional,
    })),
  };
}

function promptJson(doc) {
  return {
    id: doc.code,
    activity_slug: doc.activitySlug,
    difficulty: doc.difficulty,
    title: doc.title,
    prompt_text: doc.promptText,
    secondary_text: doc.secondaryText,
    objective: doc.objective,
    exemplar_response: doc.exemplarResponse,
    tags: doc.tags,
    industries: doc.industries,
    duration_seconds: doc.durationSeconds,
    prep_seconds: doc.prepSeconds,
    learn_more_url: doc.learnMoreUrl,
    learn_more_label: doc.learnMoreLabel,
  };
}

function planJson(plan) {
  if (!plan) return null;
  return {
    headline: plan.headline,
    summary: plan.summary,
    recommended_track: plan.recommendedTrack,
    primary_roadblock: plan.primaryRoadblock,
    focus_line: plan.focusLine,
    initial_drills: plan.initialDrills || [],
    milestones: (plan.milestones || []).map((m) => ({
      week: m.week,
      title: m.title,
      focus: m.focus,
    })),
  };
}

function profileJson(profile) {
  if (!profile) return null;
  return {
    voice_profile: profile.voiceProfile,
    career_stage: profile.careerStage,
    career_type: profile.careerType,
    speaking_confidence: profile.speakingConfidence,
    primary_roadblock: profile.primaryRoadblock,
    primary_goal: profile.primaryGoal,
    onboarding_complete: profile.onboardingComplete,
    personalized_plan: planJson(profile.plan),
  };
}

function userJson(user) {
  return {
    id: user._id,
    full_name: user.fullName,
    email: user.email,
    created_at: user.createdAt,
  };
}

function subscriptionJson(sub) {
  if (!sub) return null;
  const now = new Date();
  let status = sub.status;
  if (status === "trialing" && sub.trialEnd && sub.trialEnd < now) status = "expired";
  if (status === "active" && sub.currentPeriodEnd && sub.currentPeriodEnd < now) status = "expired";
  const price =
    sub.tier === "annual_pro" ? "£69.99/yr" : sub.tier === "monthly_pro" ? "£9.99/mo" : "7-day trial";
  return {
    tier: sub.tier,
    status,
    price_gbp: sub.priceGbp,
    price_label: price,
    trial_end: sub.trialEnd,
    current_period_end: sub.currentPeriodEnd,
    can_practise: status === "trialing" || status === "active",
  };
}

function streakJson(streak) {
  if (!streak) return null;
  return {
    current_streak: streak.currentStreak,
    longest_streak: streak.longestStreak,
    streak_freeze_count: streak.streakFreezeCount,
    total_xp: streak.totalXp,
    completed_sessions: streak.completedSessions,
    last_practice_date: streak.lastPracticeDate,
    note: "Streaks and XP are separate from skill scores.",
  };
}

function settingsJson(settings) {
  if (!settings) return null;
  return {
    industry_track: settings.industryTrack,
    voice_profile: settings.voiceProfile,
    daily_anchor_minutes: settings.dailyAnchorMinutes,
    audio_privacy: settings.audioPrivacy,
  };
}

function sessionJson(doc) {
  return {
    id: doc._id,
    activity_slug: doc.activitySlug,
    activity_name: doc.activityName,
    prompt_id: doc.promptCode,
    prompt_title: doc.promptTitle,
    difficulty: doc.difficulty,
    transcript: doc.transcript,
    duration_seconds: doc.durationSeconds,
    is_coached_retry: doc.isCoachedRetry,
    withhold_judgement: doc.withholdJudgement,
    timestamp: doc.createdAt,
    feedback: doc.feedback,
  };
}

module.exports = {
  activityJson,
  promptJson,
  planJson,
  profileJson,
  userJson,
  subscriptionJson,
  streakJson,
  settingsJson,
  sessionJson,
};
