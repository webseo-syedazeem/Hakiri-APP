const Activity = require("../models/Activity");
const Prompt = require("../models/Prompt");
const Profile = require("../models/Profile");
const Settings = require("../models/Settings");
const PracticeSession = require("../models/PracticeSession");
const { success, error } = require("../helpers/response");
const { canonical, TRACK_LABEL } = require("../services/plan");
const { activityJson, promptJson } = require("../services/serializers");
const {
  buildPlanBlock,
  coreDrillsFromProfile,
  headlineForMinutes,
  subheadlineForMinutes,
} = require("../services/dailyPlan");

function hashSeed(value) {
  let hash = 0;
  const text = String(value);
  for (let i = 0; i < text.length; i += 1) hash = (hash * 31 + text.charCodeAt(i)) >>> 0;
  return hash;
}

function dedupePrompts(list) {
  const seen = new Set();
  const out = [];
  for (const item of list) {
    const code = String(item.code || "");
    if (!code || seen.has(code)) continue;
    seen.add(code);
    out.push(item);
  }
  return out;
}

async function choosePrompt({ activitySlug, difficulty, careerType, excludeCodes = [], seed }) {
  const requested = canonical("difficulty", difficulty) || "beginner";
  const storedDifficulty = requested === "i_dont_know" ? "intermediary" : requested;
  let pool = await Prompt.find({ activitySlug, difficulty: storedDifficulty });
  if (!pool.length) pool = await Prompt.find({ activitySlug });

  const specific =
    careerType && careerType !== "general" && careerType !== "other"
      ? pool.filter((item) => (item.industries || []).includes(careerType))
      : [];
  const general = pool.filter(
    (item) => (item.industries || []).includes("general") || !(item.industries || []).length
  );

  // Never trap users in a 1–2 prompt industry niche (e.g. always "project deadline").
  // Use the full difficulty pool for variety; soft-prefer career matches when plenty exist.
  const ranked = dedupePrompts([...specific, ...general, ...pool]);
  const exclude = new Set((excludeCodes || []).filter(Boolean).map(String));
  const fresh = ranked.filter((item) => !exclude.has(item.code));
  let list = fresh.length ? fresh : ranked;
  if (!list.length) return null;

  const careerFresh = list.filter((item) => specific.some((s) => s.code === item.code));
  // Soft bias only when career pool itself has real variety.
  if (
    careerFresh.length >= 3 &&
    !(seed && String(seed).includes(":stable:")) &&
    Math.random() < 0.4
  ) {
    list = careerFresh;
  }

  const index =
    seed && String(seed).includes(":stable:")
      ? hashSeed(seed) % list.length
      : Math.floor(Math.random() * list.length);
  return { prompt: list[index], inferLevel: requested === "i_dont_know", servedDifficulty: storedDifficulty };
}

const listActivities = async (req, res) => {
  const mvpOnly = req.query.mvp === "true";
  const filter = mvpOnly ? { isMvp: true } : {};
  const activities = await Activity.find(filter).sort({ isMvp: -1, name: 1 });
  return success(res, "Activities.", { activities: activities.map(activityJson) });
};

const getActivity = async (req, res) => {
  const activity = await Activity.findOne({ slug: req.params.slug });
  if (!activity) return error(res, "Activity not found.", 404);
  const prompts = await Prompt.find({ activitySlug: activity.slug }).sort({ difficulty: 1, code: 1 });
  return success(res, "Activity.", {
    activity: activityJson(activity),
    prompts: prompts.map(promptJson),
  });
};

const listPrompts = async (req, res) => {
  const filter = {};
  if (req.query.activity) filter.activitySlug = req.query.activity;
  if (req.query.difficulty) {
    const difficulty = canonical("difficulty", req.query.difficulty);
    if (difficulty && difficulty !== "i_dont_know") filter.difficulty = difficulty;
  }
  let prompts = await Prompt.find(filter).sort({ code: 1 });
  if (req.query.career_type) {
    const career = canonical("career_type", req.query.career_type);
    if (career && career !== "general") {
      const specific = prompts.filter((item) => (item.industries || []).includes(career));
      if (specific.length) prompts = specific;
    }
  }
  return success(res, "Prompts.", { prompts: prompts.map(promptJson) });
};

const getPrompt = async (req, res) => {
  const prompt = await Prompt.findOne({ code: req.params.id });
  if (!prompt) return error(res, "Prompt not found.", 404);
  return success(res, "Prompt.", { prompt: promptJson(prompt) });
};

const nextPrompt = async (req, res) => {
  const activitySlug = req.query.activity || req.query.activity_slug;
  if (!activitySlug) return error(res, "activity is required.");
  const activity = await Activity.findOne({ slug: activitySlug });
  if (!activity) return error(res, "Activity not found.", 404);
  if (!activity.isMvp) return error(res, "This activity is not in the MVP yet.", 404);

  const profile = await Profile.findOne({ user: req.user._id });
  const career = canonical("career_type", req.query.career_type) || profile?.careerType || "general";
  const { activityLevel, hydrateCoaching } = require("../services/coaching");
  const coaching = hydrateCoaching(profile?.coaching, {
    confidence: profile?.speakingConfidence,
    drills: profile?.plan?.initialDrills,
  });
  const difficulty = activityLevel(coaching, activitySlug);
  const recent = await PracticeSession.find({
    user: req.user._id,
    activitySlug,
    isCoachedRetry: false,
  })
    .sort({ createdAt: -1 })
    .limit(20)
    .select("promptCode");

  const excludeParam = String(req.query.exclude || req.query.exclude_codes || "")
    .split(",")
    .map((s) => s.trim())
    .filter(Boolean);
  const excludeCodes = [
    ...new Set([
      ...recent.map((row) => row.promptCode).filter(Boolean),
      ...excludeParam,
    ]),
  ];

  const chosen = await choosePrompt({
    activitySlug,
    difficulty,
    careerType: career,
    excludeCodes,
    // Random rotation each Begin exercise (daily-anchor still uses stable seed).
    seed: `${req.user._id}:${activitySlug}:${difficulty}:${Date.now()}`,
  });
  if (!chosen) return error(res, "No prompt is available for this activity.", 404);

  return success(res, "Next prompt.", {
    activity: activityJson(activity),
    prompt: promptJson(chosen.prompt),
    infer_level: chosen.inferLevel,
    note: chosen.inferLevel
      ? "The member chose I don't know. The Flutter app should judge their level from the recording."
      : null,
  });
};

function confidenceToDifficulty(confidence) {
  if (confidence === "not_very" || confidence === "anxious") return "beginner";
  if (confidence === "very" || confidence === "high") return "professional";
  return "intermediary";
}

const dailyAnchor = async (req, res) => {
  const Streak = require("../models/Streak");
  const profile = await Profile.findOne({ user: req.user._id });
  const settings = await Settings.findOne({ user: req.user._id });
  const streak = await Streak.findOne({ user: req.user._id });
  const drills = coreDrillsFromProfile(profile);
  const primarySlug = drills[0];
  const queueSlugs = drills.slice(1, 3);
  const career = profile?.careerType || "general";
  const { activityLevel, hydrateCoaching } = require("../services/coaching");
  const coaching = hydrateCoaching(profile?.coaching, {
    confidence: profile?.speakingConfidence,
    drills,
  });
  const minutes = settings?.dailyAnchorMinutes || 5;
  const plan = await buildPlanBlock({
    userId: req.user._id,
    profile,
    settings,
  });

  async function card(slug, order) {
    const activity = await Activity.findOne({ slug });
    if (!activity) return null;
    const difficulty = activityLevel(coaching, slug);
    const chosen = await choosePrompt({
      activitySlug: slug,
      difficulty,
      careerType: career,
      seed: `${req.user._id}:${slug}:stable:${dateStamp()}`,
    });
    return {
      order,
      activity: activityJson(activity),
      prompt: chosen ? promptJson(chosen.prompt) : null,
      difficulty,
      career_type: career,
      career_label: TRACK_LABEL[career] || career,
      duration_label: `${Math.max(1, Math.round((activity.defaultDurationSeconds || 60) / 60))} min`,
    };
  }

  const primary = await card(primarySlug, "01");
  const queue = [];
  let n = 2;
  for (const slug of queueSlugs) {
    const item = await card(slug, String(n).padStart(2, "0"));
    if (item) queue.push(item);
    n += 1;
  }

  return success(res, "Daily anchor.", {
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
  });
};

function dateStamp() {
  return new Date().toISOString().slice(0, 10);
}

module.exports = {
  listActivities,
  getActivity,
  listPrompts,
  getPrompt,
  nextPrompt,
  dailyAnchor,
};
