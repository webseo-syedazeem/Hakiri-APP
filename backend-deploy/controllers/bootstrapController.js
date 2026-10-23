const Profile = require("../models/Profile");
const Subscription = require("../models/Subscription");
const Streak = require("../models/Streak");
const Settings = require("../models/Settings");
const PracticeSession = require("../models/PracticeSession");
const ChallengeProgress = require("../models/ChallengeProgress");
const Activity = require("../models/Activity");
const Reflection = require("../models/Reflection");
const { reflectionJson, buildStats } = require("./reflectionController");
const { CHALLENGES } = require("../data/catalog");
const { success } = require("../helpers/response");
const {
  userJson,
  profileJson,
  subscriptionJson,
  streakJson,
  settingsJson,
  sessionJson,
  activityJson,
} = require("../services/serializers");
const { challengeView } = require("../services/progress");

const TRACK_LABEL = {
  corporate_finance: "Corporate & Finance",
  tech_product: "Tech, Engineering & Product",
  sales_marketing: "Sales & Marketing",
  healthcare_edu: "Healthcare & Education",
  other: "Other",
  general: "General",
};

function average(rows, picker) {
  const values = rows.map(picker).filter((value) => Number.isFinite(value));
  if (!values.length) return { average: null, samples: 0, status: "need_more" };
  const mean = values.reduce((sum, value) => sum + value, 0) / values.length;
  return {
    average: Math.round(mean * 10) / 10,
    samples: values.length,
    status: values.length < 3 ? "need_more" : "ready",
  };
}

function buildDashboard(fresh, recent, streak) {
  const pillar = (key) => average(fresh, (row) => Number(row.feedback?.pillars?.[key]));
  const byActivity = new Map();
  for (const row of fresh) {
    if (!byActivity.has(row.activitySlug)) byActivity.set(row.activitySlug, []);
    byActivity.get(row.activitySlug).push(row);
  }
  return {
    window_days: 30,
    fresh_prompts_only: true,
    overall: average(fresh, (row) => Number(row.feedback?.overall_score)),
    pillars: {
      executive_presence: { ...pillar("executive_score"), label: "Fluency and presence" },
      clarity: { ...pillar("clarity_score"), label: "Clarity and articulation" },
      engagement: { ...pillar("engagement_score"), label: "Engagement and tone" },
      impact: { ...pillar("impact_score"), label: "Conciseness and impact" },
    },
    activity_breakdown: [...byActivity.entries()].map(([slug, rows]) => ({
      slug,
      name: rows[0].activityName,
      sessions: rows.length,
      overall: average(rows, (row) => Number(row.feedback?.overall_score)),
    })),
    gamification: streakJson(streak),
    recent_sessions: recent.map(sessionJson),
  };
}

async function buildDailyAnchorLite(userId, profile, settings, streak) {
  const {
    buildPlanBlock,
    coreDrillsFromProfile,
    headlineForMinutes,
    subheadlineForMinutes,
  } = require("../services/dailyPlan");

  const drills = coreDrillsFromProfile(profile);
  const primarySlug = drills[0];
  const queueSlugs = drills.slice(1, 3);
  const career = profile?.careerType || "general";
  const minutes = settings?.dailyAnchorMinutes || 5;
  const needed = [primarySlug, ...queueSlugs];
  const activities = await Activity.find({ slug: { $in: needed } }).lean();
  const bySlug = new Map(activities.map((row) => [row.slug, row]));
  const plan = await buildPlanBlock({ userId, profile, settings });

  const { activityLevel, hydrateCoaching } = require("../services/coaching");
  const coaching = hydrateCoaching(profile?.coaching, {
    confidence: profile?.speakingConfidence,
    drills,
  });
  const card = (slug, order) => {
    const activity = bySlug.get(slug);
    if (!activity) return null;
    return {
      order,
      activity: activityJson(activity),
      prompt: null,
      difficulty: activityLevel(coaching, slug),
      career_type: career,
      career_label: TRACK_LABEL[career] || career,
      duration_label: `${Math.max(1, Math.round((activity.defaultDurationSeconds || 60) / 60))} min`,
    };
  };

  const primary = card(primarySlug, "01");
  const queue = queueSlugs
    .map((slug, index) => card(slug, String(index + 2).padStart(2, "0")))
    .filter(Boolean);

  return {
    date: plan.date,
    minutes,
    headline: headlineForMinutes(minutes),
    subheadline: subheadlineForMinutes(minutes),
    focus_line: profile?.plan?.focusLine || "Go blank less, land the point sooner.",
    streak_day: streak?.currentStreak || 0,
    streak_freeze_count: streak?.streakFreezeCount || 0,
    primary,
    queue,
    plan,
  };
}

/** One round-trip for home/login refresh instead of 5 separate API calls. */
const bootstrap = async (req, res) => {
  const userId = req.user._id;
  const since = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
  const sessionLimit = Math.min(Number(req.query.limit) || 30, 50);

  const since28 = new Date(Date.now() - 28 * 24 * 60 * 60 * 1000);
  const [profile, subscription, streak, settings, challengeRows, recentSessions, reflectionRows, reflectionStats] =
    await Promise.all([
      Profile.findOne({ user: userId }).lean(),
      Subscription.findOne({ user: userId }).lean(),
      Streak.findOne({ user: userId }).lean(),
      Settings.findOne({ user: userId }).lean(),
      ChallengeProgress.find({ user: userId }).lean(),
      PracticeSession.find({ user: userId }).sort({ createdAt: -1 }).limit(sessionLimit).lean(),
      Reflection.find({ user: userId }).sort({ createdAt: -1 }).limit(100).lean(),
      buildStats(userId, since28),
    ]);

  const fresh = recentSessions.filter(
    (row) =>
      row.createdAt >= since &&
      row.isCoachedRetry !== true &&
      row.withholdJudgement !== true
  );
  const bySlug = new Map(challengeRows.map((row) => [row.slug, row]));
  const dailyAnchor = await buildDailyAnchorLite(userId, profile, settings, streak);

  let coachingPrompt = null;
  let activityLevels = {};
  try {
    const coachingCtl = require("./coachingController");
    const Profile = require("../models/Profile");
    const profileDoc = await Profile.findOne({ user: userId });
    if (profileDoc) {
      const offered = await coachingCtl.coachingPromptFor(userId, profileDoc);
      coachingPrompt = offered.prompt;
      activityLevels = offered.levels || {};
    }
  } catch (err) {
    console.error("coaching prompt skipped:", err.message);
  }

  return success(res, "Bootstrap.", {
    user: userJson(req.user),
    profile: profileJson(profile),
    subscription: subscriptionJson(subscription),
    streak: streakJson(streak),
    settings: settingsJson(settings),
    dashboard: buildDashboard(fresh, recentSessions.slice(0, 8), streak),
    daily_anchor: dailyAnchor,
    coaching_prompt: coachingPrompt,
    activity_levels: activityLevels,
    challenges: CHALLENGES.map((item) => challengeView(item, bySlug.get(item.slug))),
    sessions: {
      total: recentSessions.length,
      sessions: recentSessions.map(sessionJson),
    },
    reflections: {
      days: 28,
      stats: reflectionStats,
      reflections: reflectionRows.map(reflectionJson),
    },
  });
};

module.exports = { bootstrap };
