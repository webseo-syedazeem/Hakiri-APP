const Profile = require("../models/Profile");
const PracticeSession = require("../models/PracticeSession");
const { success, error } = require("../helpers/response");
const {
  buildJourneySnapshot,
  countPracticeDaysInWeek,
  resolveJourneyStart,
  CHAPTERS,
} = require("../services/journey");
const {
  syncChapterCompletionAndNotify,
} = require("../services/journeyCompletion");
const { rollingPillarAverage, ROLLING_OBSERVATIONS } = require("../services/scoringEngine");

async function ensureJourneyStart(profile, firstSessionAt) {
  if (profile?.journey?.startedAt) return profile;
  const startedAt = resolveJourneyStart(profile, firstSessionAt);
  profile.journey = {
    ...(profile.journey && typeof profile.journey === "object" ? profile.journey : {}),
    startedAt,
    completedChapterIds: Array.isArray(profile?.journey?.completedChapterIds)
      ? profile.journey.completedChapterIds
      : [],
    benchmarks: Array.isArray(profile?.journey?.benchmarks)
      ? profile.journey.benchmarks
      : [],
  };
  await profile.save();
  return profile;
}

function pillarDelta(sessions, pillarKey) {
  const recent = rollingPillarAverage(sessions, pillarKey, ROLLING_OBSERVATIONS);
  const olderPool = sessions.slice(ROLLING_OBSERVATIONS, ROLLING_OBSERVATIONS * 2);
  const older = rollingPillarAverage(olderPool, pillarKey, ROLLING_OBSERVATIONS);
  if (recent.average == null) return null;
  return {
    pillar: pillarKey,
    from: older.average,
    to: recent.average,
    label:
      older.average != null
        ? `${older.average.toFixed(1)} → ${recent.average.toFixed(1)}`
        : recent.average.toFixed(1),
  };
}

function canonicalMeasureLabel(key, rawLabel) {
  const normKey = (key || "").toLowerCase();
  const normLabel = (rawLabel || "").toLowerCase();
  if (normKey.includes("compression") || normLabel.includes("compression")) return "Message Compression";
  if (normKey.includes("point_first") || normLabel.includes("point first")) return "Point First";
  if (normKey.includes("paraphras") || normLabel.includes("paraphras")) return "Paraphrasing";
  if (normKey.includes("audience") || normLabel.includes("audience")) return "Audience Fit";
  if (normKey.includes("time_control") || normLabel.includes("time control")) return "Time Control";
  if (normKey.includes("opening_impact") || normLabel.includes("opening impact")) return "Opening Impact";
  if (normKey.includes("filler") || normLabel.includes("filler")) return "Filler Control";
  if (normKey.includes("structure") || normLabel.includes("structure")) return "Answer Structure";
  if (normKey.includes("argument") || normLabel.includes("argument")) return "Argument Quality";
  if (normKey.includes("confidence") || normLabel.includes("confidence")) return "Perceived Confidence";
  if (normKey.includes("connection") || normLabel.includes("connection")) return "Connection Logic";
  if (normKey.includes("takeaway") || normLabel.includes("takeaway")) return "Clear Takeaway";
  return rawLabel || key;
}

async function journeyPayload(userId) {
  let profile = await Profile.findOne({ user: userId });
  if (!profile) return null;

  const sessions = await PracticeSession.find({
    user: userId,
    withholdJudgement: false,
  })
    .sort({ createdAt: -1 })
    .limit(120)
    .select("createdAt feedback isCoachedRetry activitySlug activityName");

  const first = await PracticeSession.findOne({ user: userId })
    .sort({ createdAt: 1 })
    .select("createdAt");

  profile = await ensureJourneyStart(profile, first?.createdAt);
  // Elapsed chapter months → mark complete + one FCM (journey screen on tap).
  try {
    await syncChapterCompletionAndNotify(userId);
    profile = (await Profile.findOne({ user: userId })) || profile;
  } catch (err) {
    console.error("[journey] completion notify skipped:", err.message);
  }

  const fresh = sessions.filter((s) => !s.isCoachedRetry);
  const practiceDays = countPracticeDaysInWeek(sessions);

  // Emphasise the chapter's primary pillar for weekly movement copy.
  const snapPreview = buildJourneySnapshot({ profile, firstSessionAt: first?.createdAt });
  const primary =
    snapPreview.chapter.scoring_emphasis?.[0] || "structure";
  const movement = practiceDays > 0 ? pillarDelta(fresh, primary) : null;

  let strongestMeasure = null;
  let keepWorkingOn = null;
  for (const row of fresh.slice(0, 12)) {
    const measures = row.feedback?.activity_measures;
    if (!Array.isArray(measures)) continue;
    for (const m of measures) {
      if (m?.score == null || m.included === false || m.diagnostic) continue;
      const cLabel = canonicalMeasureLabel(m.key, m.label);
      if (!strongestMeasure || Number(m.score) > Number(strongestMeasure.score)) {
        strongestMeasure = {
          key: m.key,
          label: cLabel,
          score: Number(m.score),
        };
      }
      if (!keepWorkingOn || Number(m.score) < Number(keepWorkingOn.score)) {
        keepWorkingOn = {
          key: m.key,
          label: cLabel,
          score: Number(m.score),
        };
      }
    }
  }

  return buildJourneySnapshot({
    profile,
    firstSessionAt: first?.createdAt,
    practiceDaysThisWeek: practiceDays,
    pillarMovement: movement,
    strongestMeasure: strongestMeasure
      ? `${strongestMeasure.label} (${strongestMeasure.score.toFixed(1)})`
      : null,
    keepWorkingOn: keepWorkingOn
      ? keepWorkingOn.label
      : null,
  });
}

const getJourney = async (req, res) => {
  try {
    const data = await journeyPayload(req.user._id);
    if (!data) return error(res, "Complete assessment first.", 404);
    return success(res, "Journey.", { journey: data });
  } catch (err) {
    console.error("getJourney failed:", err.message);
    return error(res, err.message || "Could not load journey.", 500);
  }
};

const weeklyReview = async (req, res) => {
  try {
    const data = await journeyPayload(req.user._id);
    if (!data) return error(res, "Complete assessment first.", 404);
    return success(res, "Weekly review.", {
      weekly_review: data.weekly_review,
      chapter: data.chapter,
      weekly_focus: data.weekly_focus,
    });
  } catch (err) {
    return error(res, err.message || "Could not load weekly review.", 500);
  }
};

const chapterReview = async (req, res) => {
  try {
    const data = await journeyPayload(req.user._id);
    if (!data) return error(res, "Complete assessment first.", 404);

    const sessions = await PracticeSession.find({
      user: req.user._id,
      isCoachedRetry: false,
      withholdJudgement: false,
    })
      .sort({ createdAt: -1 })
      .limit(80);

    const pillars = ["clarity", "structure", "engagement", "conciseness"].map(
      (key) => {
        const recent = rollingPillarAverage(sessions, key, ROLLING_OBSERVATIONS);
        return {
          key,
          label:
            key === "engagement"
              ? "Engagement & Tone"
              : key.charAt(0).toUpperCase() + key.slice(1),
          score: recent.average,
          samples: recent.samples,
        };
      }
    );

    const scores = pillars.map((p) => p.score).filter((n) => n != null);
    const overall =
      scores.length > 0
        ? Math.round((scores.reduce((a, b) => a + b, 0) / scores.length) * 10) / 10
        : null;

    const ranked = pillars
      .filter((p) => p.score != null)
      .slice()
      .sort((a, b) => b.score - a.score);
    const strongest = ranked[0]
      ? { label: ranked[0].label, score: ranked[0].score, key: ranked[0].key }
      : null;
    const needsWork =
      ranked.length > 1
        ? {
            label: ranked[ranked.length - 1].label,
            score: ranked[ranked.length - 1].score,
            key: ranked[ranked.length - 1].key,
          }
        : null;

    return success(res, "Chapter review.", {
      chapter: data.chapter,
      chapter_review: {
        ...data.chapter_review,
        pillars,
        overall,
        strongest,
        needs_work: needsWork,
        biggest_improvement:
          data.weekly_review.strongest_measure ||
          (strongest
            ? `${strongest.label} is your strongest signal so far.`
            : "Keep practising — improvement shows across the same four scores."),
        keep_working_on:
          data.weekly_review.keep_working_on ||
          (needsWork ? `${needsWork.label} is the area to grow next.` : null),
        practised_label: data.weekly_review.practised_label,
        weekly_focus: data.weekly_focus || data.weekly_review.focus,
        next_week_focus:
          data.next_week_focus || data.weekly_review.next_week_focus,
        message:
          data.chapter_review?.message ||
          "This is a check-in, not a pass/fail exam. The same four Hakkiri scores track your progress through the chapter.",
        benchmarks: (await Profile.findOne({ user: req.user._id }))?.journey
          ?.benchmarks || [],
      },
    });
  } catch (err) {
    return error(res, err.message || "Could not load chapter review.", 500);
  }
};

/** Store a short benchmark note / transcript pointer (recording stays on device). */
const saveBenchmark = async (req, res) => {
  try {
    const profile = await Profile.findOne({ user: req.user._id });
    if (!profile) return error(res, "Profile not found.", 404);

    const body = req.body || {};
    const chapterId = String(body.chapter_id || "").trim();
    const phase = String(body.phase || "start").trim(); // start | end
    const promptText =
      String(body.prompt_text || "").trim() ||
      "In one minute, tell me what you do and why it matters.";
    const transcript = String(body.transcript || "").trim().slice(0, 8000);
    const localNote = String(body.local_note || "").trim().slice(0, 500);

    if (!CHAPTERS.some((c) => c.id === chapterId)) {
      return error(res, "Unknown chapter.");
    }
    if (phase !== "start" && phase !== "end") {
      return error(res, "phase must be start or end.");
    }

    const journey = {
      ...(profile.journey && typeof profile.journey === "object" ? profile.journey : {}),
      startedAt: profile.journey?.startedAt || new Date(),
      completedChapterIds: Array.isArray(profile.journey?.completedChapterIds)
        ? profile.journey.completedChapterIds
        : [],
      benchmarks: Array.isArray(profile.journey?.benchmarks)
        ? [...profile.journey.benchmarks]
        : [],
    };

    journey.benchmarks = journey.benchmarks.filter(
      (b) => !(b.chapterId === chapterId && b.phase === phase)
    );
    journey.benchmarks.push({
      chapterId,
      phase,
      promptText,
      transcript,
      localNote,
      createdAt: new Date(),
    });
    // Keep last 20
    journey.benchmarks = journey.benchmarks.slice(-20);
    profile.journey = journey;
    await profile.save();

    return success(res, "Benchmark saved.", {
      benchmark: journey.benchmarks[journey.benchmarks.length - 1],
    });
  } catch (err) {
    return error(res, err.message || "Could not save benchmark.", 500);
  }
};

const completeChapter = async (req, res) => {
  try {
    const profile = await Profile.findOne({ user: req.user._id });
    if (!profile) return error(res, "Profile not found.", 404);
    const chapterId = String(req.body?.chapter_id || "").trim();
    if (!CHAPTERS.some((c) => c.id === chapterId)) {
      return error(res, "Unknown chapter.");
    }
    await syncChapterCompletionAndNotify(req.user._id, {
      forceChapterId: chapterId,
    });
    const data = await journeyPayload(req.user._id);
    return success(res, "Chapter marked complete.", { journey: data });
  } catch (err) {
    return error(res, err.message || "Could not complete chapter.", 500);
  }
};

module.exports = {
  getJourney,
  weeklyReview,
  chapterReview,
  saveBenchmark,
  completeChapter,
  journeyPayload,
};
