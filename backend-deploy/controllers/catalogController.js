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

function industriesOf(item) {
  const inds = item.industries || [];
  return Array.isArray(inds) ? inds.map(String) : [];
}

/**
 * Prompt is safe for any track only when it is purely general / untagged.
 * `["sales_marketing", "general"]` is NOT general — that was leaking brand/SEO
 * prompts into healthcare and other tracks.
 */
function isGeneralPrompt(item) {
  const inds = industriesOf(item);
  if (!inds.length) return true;
  const careers = inds.filter((i) => i !== "general");
  return careers.length === 0;
}

/** Prompt is tagged for this career track (may also list other tracks). */
function matchesCareer(item, career) {
  if (!career) return true;
  return industriesOf(item).includes(career);
}

/**
 * Never serve another track's prompt to this career.
 * Allowed = tagged for career OR purely general (or untagged).
 */
function allowedForCareer(item, career) {
  if (!career) return isGeneralPrompt(item);
  return matchesCareer(item, career) || isGeneralPrompt(item);
}

/**
 * Pick a prompt for an activity.
 * Industry rule: never serve another track's prompt
 * (e.g. sales brand copy when user selected healthcare).
 * Prefer career-tagged prompts, then pure general for variety.
 */
async function choosePrompt({ activitySlug, difficulty, careerType, excludeCodes = [], seed }) {
  const requested = canonical("difficulty", difficulty) || "beginner";
  const storedDifficulty = requested === "i_dont_know" ? "intermediary" : requested;
  let pool = await Prompt.find({ activitySlug, difficulty: storedDifficulty });
  if (!pool.length) pool = await Prompt.find({ activitySlug });

  const career =
    careerType && careerType !== "general" && careerType !== "other"
      ? String(careerType)
      : null;

  const pickForCareer = (source) => {
    const safe = career
      ? source.filter((item) => allowedForCareer(item, career))
      : source.filter(isGeneralPrompt);
    if (!career) {
      return dedupePrompts(safe.length ? safe : source.filter(isGeneralPrompt));
    }
    const specific = safe.filter((item) => matchesCareer(item, career));
    const general = safe.filter(isGeneralPrompt);
    if (specific.length) {
      return dedupePrompts(specific);
    }
    return dedupePrompts(general.length ? general : safe);
  };

  let ranked = [];
  const allDiff = await Prompt.find({ activitySlug });

  if (career) {
    // Prefer career-tagged prompts, but if the pool is tiny (e.g. only
    // "thunderstorm" for finance Connect the Dots) mix in general prompts
    // so Begin exercise does not repeat the same question every time.
    const diffSpecific = dedupePrompts(
      pool.filter((item) => matchesCareer(item, career))
    );
    const anySpecific = dedupePrompts(
      allDiff.filter((item) => matchesCareer(item, career))
    );
    const specific = diffSpecific.length ? diffSpecific : anySpecific;
    const generalSafe = dedupePrompts(
      [...pool, ...allDiff].filter((item) => isGeneralPrompt(item))
    );
    if (specific.length >= 4) {
      ranked = specific;
    } else if (specific.length) {
      ranked = dedupePrompts([...specific, ...generalSafe]);
    }
  }

  // Fallback to general/safe pool if no career-specific exists
  if (!ranked.length) {
    ranked = pickForCareer(pool);
  }
  if (!ranked.length) {
    ranked = pickForCareer(allDiff);
  }

  // Last resort: still never leak another track's exclusive prompts.
  if (!ranked.length) {
    ranked = dedupePrompts(
      allDiff.filter((item) => allowedForCareer(item, career))
    );
  }

  const exclude = new Set((excludeCodes || []).filter(Boolean).map(String));
  const fresh = ranked.filter((item) => !exclude.has(String(item.code || "")));
  const list = fresh.length ? fresh : ranked;
  if (!list.length) return null;

  // Stable seed for daily anchor; otherwise true shuffle so Begin exercise varies.
  let index;
  if (seed && String(seed).includes(":stable:")) {
    index = hashSeed(seed) % list.length;
  } else {
    for (let i = list.length - 1; i > 0; i -= 1) {
      const j = Math.floor(Math.random() * (i + 1));
      const tmp = list[i];
      list[i] = list[j];
      list[j] = tmp;
    }
    index = 0;
  }
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
    if (career && career !== "general" && career !== "other") {
      const specific = prompts.filter((item) => matchesCareer(item, career));
      const general = prompts.filter(isGeneralPrompt);
      // Career-only when available; pure general only as fallback.
      prompts = specific.length
        ? specific
        : general.length
          ? general
          : prompts;
    } else if (career === "general") {
      const general = prompts.filter(isGeneralPrompt);
      if (general.length) prompts = general;
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

  const userId = req.user?._id;
  const { activityLevel, hydrateCoaching } = require("../services/coaching");
  let career = canonical("career_type", req.query.career_type) || "general";
  // Prefer the level the app is showing (per-activity coaching). Fall back to profile.
  const queryDifficulty = canonical("difficulty", req.query.difficulty);
  let difficulty = queryDifficulty || "intermediary";

  let recent = [];
  if (userId) {
    const profile = await Profile.findOne({ user: userId });
    career =
      canonical("career_type", req.query.career_type) ||
      profile?.careerType ||
      "general";
    const coaching = hydrateCoaching(profile?.coaching, {
      confidence: profile?.speakingConfidence,
      drills: profile?.plan?.initialDrills,
    });
    // Client sends the activity level it is practicing — trust that when present.
    difficulty = queryDifficulty || activityLevel(coaching, activitySlug);
    recent = await PracticeSession.find({
      user: userId,
      activitySlug,
      isCoachedRetry: false,
    })
      .sort({ createdAt: -1 })
      .limit(20)
      .select("promptCode");
  }

  const excludeParam = String(req.query.exclude || req.query.exclude_codes || "")
    .split(",")
    .map((s) => s.trim())
    .filter(Boolean);
  const excludeTexts = String(
    req.query.exclude_text || req.query.excludeText || ""
  )
    .split("||")
    .map((s) => s.trim().toLowerCase())
    .filter((s) => s.length >= 8);
  const excludeCodes = [
    ...new Set([
      ...recent.map((row) => row.promptCode).filter(Boolean),
      ...excludeParam,
    ]),
  ];

  // Dynamically generate a fresh prompt via AI tailored to the career track & activity
  const { isGeminiConfigured, generateDynamicPromptWithGemini } = require("../config/ai");
  const forceStatic = req.query.static === "true";

  // Catalog loads in parallel with a short AI race — Begin exercise stays snappy
  // even when Gemini is slow (scoring path is unchanged / separate).
  const catalogPromise = choosePrompt({
    activitySlug,
    difficulty,
    careerType: career,
    excludeCodes,
    seed: `${userId || "guest"}:${activitySlug}:${difficulty}:${Date.now()}:${Math.random()}`,
  });

  let aiError = null;
  if (!forceStatic && isGeminiConfigured()) {
    try {
      const aiPrompt = await Promise.race([
        generateDynamicPromptWithGemini({
          activitySlug,
          careerType: career,
          difficulty,
          excludeTitles: [...excludeCodes, ...excludeTexts].slice(0, 12),
        }),
        new Promise((_, reject) =>
          setTimeout(
            () => reject(new Error("AI prompt timed out (fast path).")),
            7000
          )
        ),
      ]);
      if (aiPrompt?.promptText) {
        const toStore = { ...aiPrompt };
        delete toStore.isAiGenerated;
        delete toStore.model;
        Prompt.create(toStore).catch((err) =>
          console.warn("[nextPrompt] AI prompt persist skipped:", err.message)
        );
        return success(res, "Next prompt.", {
          activity: activityJson(activity),
          prompt: promptJson(aiPrompt),
          infer_level: false,
          note: "AI dynamic question generated for your career track.",
          source: "ai",
        });
      }
      aiError = "Gemini returned no prompt text.";
    } catch (aiErr) {
      aiError = String(aiErr?.message || aiErr).slice(0, 240);
      console.warn(
        "[nextPrompt] Gemini dynamic prompt generation failed, falling back to catalog:",
        aiError
      );
    }
  } else if (!isGeminiConfigured()) {
    aiError = "GEMINI_API_KEY missing on server.";
  }

  const chosen = await catalogPromise;
  if (!chosen) return error(res, "No prompt is available for this activity.", 404);

  // Avoid serving the exact same wording the client just showed.
  let promptDoc = chosen.prompt;
  if (excludeTexts.length) {
    const text = String(promptDoc.promptText || "").trim().toLowerCase();
    if (excludeTexts.some((t) => text.includes(t) || t.includes(text.slice(0, 40)))) {
      const retry = await choosePrompt({
        activitySlug,
        difficulty,
        careerType: career,
        excludeCodes: [...excludeCodes, promptDoc.code].filter(Boolean),
        seed: `${userId || "guest"}:${activitySlug}:retry:${Date.now()}:${Math.random()}`,
      });
      if (retry?.prompt) promptDoc = retry.prompt;
    }
  }

  return success(res, "Next prompt.", {
    activity: activityJson(activity),
    prompt: promptJson(promptDoc),
    infer_level: chosen.inferLevel,
    source: "catalog",
    ai_error: aiError,
    note: chosen.inferLevel
      ? "The member chose I don't know. The Flutter app should judge their level from the recording."
      : aiError
        ? `Catalog fallback — AI unavailable: ${aiError}`
        : "Catalog fallback (AI question unavailable).",
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
