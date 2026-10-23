const PracticeSession = require("../models/PracticeSession");
const DailyPlanProgress = require("../models/DailyPlanProgress");

const DEFAULT_DRILLS = ["think_fast", "cut_it_in_half", "debate_me"];

function dateStamp(d = new Date()) {
  return d.toISOString().slice(0, 10);
}

function startOfUtcDay(dateStr) {
  return new Date(`${dateStr}T00:00:00.000Z`);
}

function endOfUtcDay(dateStr) {
  return new Date(`${dateStr}T23:59:59.999Z`);
}

function headlineForMinutes(minutes) {
  if (minutes === 15) return "Fifteen minutes.";
  if (minutes === 10) return "Ten minutes.";
  return "Five minutes.";
}

function subheadlineForMinutes(minutes) {
  if (minutes === 15) return "More time, deeper practice.";
  if (minutes === 10) return "Balanced practice with a smart retry.";
  return "Then go speak.";
}

function totalCountForMinutes(minutes) {
  if (minutes === 15) return 5;
  if (minutes === 10) return 4;
  return 3;
}

function areaLabelForSlug(slug) {
  if (slug === "think_fast") return "Thinking on the spot";
  if (slug === "debate_me" || slug === "debate") return "Response to pushback";
  if (slug === "cut_it_in_half") return "Conciseness";
  return "Clarity";
}

function coreDrillsFromProfile(profile) {
  const fromCoach = profile?.coaching?.planDrills;
  const drills = (Array.isArray(fromCoach) && fromCoach.length
    ? fromCoach
    : profile?.plan?.initialDrills?.length
      ? profile.plan.initialDrills
      : DEFAULT_DRILLS
  ).map(String);
  // Keep first 3 unique MVP drills.
  const out = [];
  for (const slug of drills) {
    if (!out.includes(slug)) out.push(slug);
    if (out.length >= 3) break;
  }
  while (out.length < 3) {
    for (const slug of DEFAULT_DRILLS) {
      if (!out.includes(slug)) out.push(slug);
      if (out.length >= 3) break;
    }
  }
  return out;
}

async function getOrCreateProgress(userId, date) {
  let row = await DailyPlanProgress.findOne({ user: userId, date });
  if (!row) {
    row = await DailyPlanProgress.create({
      user: userId,
      date,
      targetedRetryDone: false,
      tougherChallengeDone: false,
    });
  }
  return row;
}

async function markPlanExtra(userId, planExtra) {
  if (planExtra !== "targeted_retry" && planExtra !== "tougher_challenge") {
    return null;
  }
  const date = dateStamp();
  const patch =
    planExtra === "targeted_retry"
      ? { targetedRetryDone: true }
      : { tougherChallengeDone: true };
  return DailyPlanProgress.findOneAndUpdate(
    { user: userId, date },
    { $set: patch },
    { upsert: true, new: true }
  );
}

/**
 * Build the plan block for daily_anchor / bootstrap.
 * Core = first 3 drills. Extras unlock after 3 core scored sessions today.
 */
async function buildPlanBlock({ userId, profile, settings }) {
  const minutes = Number(settings?.dailyAnchorMinutes || 5);
  const date = dateStamp();
  const coreSlugs = coreDrillsFromProfile(profile);
  const progress = await getOrCreateProgress(userId, date);

  const from = startOfUtcDay(date);
  const to = endOfUtcDay(date);
  const todaySessions = await PracticeSession.find({
    user: userId,
    createdAt: { $gte: from, $lte: to },
    withholdJudgement: { $ne: true },
  })
    .sort({ createdAt: 1 })
    .lean();

  // Core = first non-retry attempt per core slug today.
  const coreSessions = todaySessions.filter(
    (s) => coreSlugs.includes(s.activitySlug) && !s.isCoachedRetry
  );
  const coreDoneSlugs = [...new Set(coreSessions.map((s) => s.activitySlug))];
  const coreCompleted = Math.min(coreDoneSlugs.length, 3);

  // Weakest among today's core (by overall_score).
  let weakest = null;
  if (coreSessions.length) {
    const scored = coreSessions
      .map((s) => ({
        slug: s.activitySlug,
        score: Number(s.feedback?.overall_score) || 0,
        feedback:
          s.feedback?.one_specific_improvement ||
          s.feedback?.retry_instruction ||
          "",
        session_id: String(s._id),
      }))
      .filter((s) => s.score > 0);
    scored.sort((a, b) => a.score - b.score);
    if (scored.length) {
      const low = scored[0];
      weakest = {
        slug: low.slug,
        score: low.score,
        weakest_area: areaLabelForSlug(low.slug),
        feedback_snippet: low.feedback || "Try again with a sharper main point.",
        session_id: low.session_id,
      };
    }
  }

  // Tougher = a different core drill (prefer debate_me).
  let tougherSlug = "debate_me";
  if (weakest?.slug === "debate_me") {
    tougherSlug = coreSlugs.find((s) => s !== "debate_me") || "think_fast";
  } else if (coreSlugs.includes("debate_me")) {
    tougherSlug = "debate_me";
  } else {
    tougherSlug = coreSlugs.find((s) => s !== weakest?.slug) || coreSlugs[0];
  }

  const retryDone = Boolean(progress.targetedRetryDone);
  const tougherDone = Boolean(progress.tougherChallengeDone);
  const totalCount = totalCountForMinutes(minutes);
  const extrasDone =
    (retryDone ? 1 : 0) + (minutes === 15 && tougherDone ? 1 : 0);
  const completedTotal = Math.min(coreCompleted + extrasDone, totalCount);

  let phase = "core";
  if (coreCompleted >= 3) {
    if (minutes === 5) {
      phase = "complete";
    } else if (minutes === 10) {
      phase = retryDone ? "complete" : "retry_offer";
    } else if (minutes === 15) {
      if (retryDone && tougherDone) phase = "complete";
      else phase = "extras_offer";
    }
  }

  return {
    date,
    minutes,
    headline: headlineForMinutes(minutes),
    subheadline: subheadlineForMinutes(minutes),
    core_slugs: coreSlugs,
    core_count: 3,
    total_count: totalCount,
    core_completed: coreCompleted,
    completed_total: completedTotal,
    phase,
    extras_completed: {
      targeted_retry: retryDone,
      tougher_challenge: tougherDone,
    },
    weakest_core: weakest,
    tougher_challenge: {
      slug: tougherSlug,
      label: "Tougher challenge",
      difficulty_boost: "professional",
      weakest_area: areaLabelForSlug(tougherSlug),
      feedback_snippet:
        "A stretch round with more pressure — keep your structure tight.",
    },
  };
}

module.exports = {
  dateStamp,
  coreDrillsFromProfile,
  buildPlanBlock,
  markPlanExtra,
  headlineForMinutes,
  subheadlineForMinutes,
  DEFAULT_DRILLS,
};
