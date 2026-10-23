const Profile = require("../models/Profile");
const PracticeSession = require("../models/PracticeSession");
const { success, error } = require("../helpers/response");
const {
  hydrateCoaching,
  defaultCoaching,
  pickTodayPrompt,
  markOffered,
  applyDecision,
  setActivityLevel,
  activityLevel,
  normalizeLevel,
  ACTIVITY_NAMES,
} = require("../services/coaching");

async function loadSessions(userId) {
  const since = new Date(Date.now() - 60 * 24 * 60 * 60 * 1000);
  return PracticeSession.find({
    user: userId,
    createdAt: { $gte: since },
  })
    .sort({ createdAt: -1 })
    .limit(200)
    .lean();
}

function drillsFromProfile(profile) {
  const fromCoach = profile?.coaching?.planDrills;
  if (Array.isArray(fromCoach) && fromCoach.length) return fromCoach;
  return profile?.plan?.initialDrills || [];
}

async function hydrateAndSave(profile, { confidence } = {}) {
  const next = hydrateCoaching(profile.coaching, {
    confidence: confidence || profile.speakingConfidence,
    drills: drillsFromProfile(profile),
    now: profile.createdAt || new Date(),
  });
  const before = JSON.stringify(profile.coaching || {});
  const after = JSON.stringify(next);
  if (before !== after) {
    profile.coaching = next;
    await profile.save();
  }
  return next;
}

async function coachingPromptFor(userId, profile) {
  const sessions = await loadSessions(userId);
  const coaching = hydrateCoaching(profile.coaching, {
    confidence: profile.speakingConfidence,
    drills: drillsFromProfile(profile),
    now: profile.createdAt || new Date(),
  });
  const prompt = pickTodayPrompt({ sessions, coaching });
  if (!prompt) {
    if (JSON.stringify(profile.coaching || {}) !== JSON.stringify(coaching)) {
      profile.coaching = coaching;
      await profile.save();
    }
    return { prompt: null, coaching, levels: levelsMap(coaching) };
  }
  const marked = markOffered(coaching, prompt);
  profile.coaching = marked;
  await profile.save();
  return { prompt, coaching: marked, levels: levelsMap(marked) };
}

function levelsMap(coaching) {
  const out = {};
  for (const slug of Object.keys(ACTIVITY_NAMES)) {
    out[slug] = activityLevel(coaching, slug);
  }
  return out;
}

const decide = async (req, res) => {
  try {
    const choice = String(req.body?.choice || "").trim().toLowerCase();
    if (!choice) return error(res, "choice is required.", 400);

    const profile = await Profile.findOne({ user: req.user._id });
    if (!profile) return error(res, "Complete assessment first.", 400);

    const coaching = await hydrateAndSave(profile);
    const prompt = coaching.lastOfferedPrompt || req.body?.prompt || null;
    if (!prompt || !prompt.type) {
      return error(res, "No coaching prompt is waiting.", 400);
    }

    profile.coaching = applyDecision(coaching, prompt, choice);
    await profile.save();

    return success(res, "Choice saved.", {
      coaching_prompt: null,
      activity_levels: levelsMap(profile.coaching),
      plan_drills: profile.coaching.planDrills,
    });
  } catch (err) {
    console.error("coaching.decide failed:", err.message);
    return error(res, err.message || "Could not save choice.", 502);
  }
};

const setLevel = async (req, res) => {
  try {
    const slug = String(req.body?.activity_slug || req.body?.slug || "").trim();
    const level = normalizeLevel(req.body?.difficulty || req.body?.level);
    if (!ACTIVITY_NAMES[slug]) return error(res, "Unknown activity.", 400);

    const profile = await Profile.findOne({ user: req.user._id });
    if (!profile) return error(res, "Complete assessment first.", 400);

    const coaching = await hydrateAndSave(profile);
    profile.coaching = setActivityLevel(coaching, slug, level);
    await profile.save();

    return success(res, "Level updated.", {
      activity_slug: slug,
      difficulty: activityLevel(profile.coaching, slug),
      activity_levels: levelsMap(profile.coaching),
    });
  } catch (err) {
    console.error("coaching.setLevel failed:", err.message);
    return error(res, err.message || "Could not update level.", 502);
  }
};

module.exports = {
  coachingPromptFor,
  levelsMap,
  drillsFromProfile,
  defaultCoaching,
  hydrateAndSave,
  decide,
  setLevel,
};
