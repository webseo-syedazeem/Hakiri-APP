const Activity = require("../models/Activity");
const Prompt = require("../models/Prompt");
const PracticeSession = require("../models/PracticeSession");
const Subscription = require("../models/Subscription");
const Streak = require("../models/Streak");
const { success, error } = require("../helpers/response");
const { sessionJson, streakJson } = require("../services/serializers");
const { applyPractice, bumpChallenges } = require("../services/progress");
const { subscriptionJson } = require("../services/serializers");

function integerScore(value, label, { required }) {
  if (value == null || value === "") {
    if (required) return `${label} is required.`;
    return null;
  }
  const number = Number(value);
  if (!Number.isInteger(number) || number < 1 || number > 5) {
    return `${label} must be a whole number from 1 to 5.`;
  }
  return null;
}

const createSession = async (req, res) => {
  const body = req.body || {};
  if (body.audio || body.audio_base64 || body.audio_file || body.recording) {
    return error(res, "Keep the recording on the device. Send the score from the app, not the audio.");
  }

  const subscription = await Subscription.findOne({ user: req.user._id });
  const access = subscriptionJson(subscription);
  if (!access?.can_practise) {
    return error(res, "Your trial has ended. Choose monthly or yearly to keep practising.", 402);
  }

  const activity = await Activity.findOne({ slug: body.activity_slug });
  if (!activity) return error(res, "Unknown activity.");
  if (!activity.isMvp) return error(res, "This activity is not open yet.");

  let prompt = null;
  if (body.prompt_id) {
    prompt = await Prompt.findOne({ code: body.prompt_id });
    if (!prompt) return error(res, "Unknown prompt.");
    if (prompt.activitySlug !== activity.slug) return error(res, "That prompt does not belong to this activity.");
  }

  const withhold = Boolean(body.withhold_judgement || body.feedback?.withhold_judgement);
  const feedback = body.feedback;
  if (!feedback || typeof feedback !== "object") return error(res, "feedback is required.");

  if (!withhold) {
    const problems = [
      integerScore(feedback.overall_score, "overall_score", { required: true }),
      integerScore(feedback.pillars?.executive_score, "executive_score", { required: true }),
      integerScore(feedback.pillars?.clarity_score, "clarity_score", { required: true }),
      integerScore(feedback.pillars?.impact_score, "impact_score", { required: true }),
      integerScore(feedback.pillars?.engagement_score, "engagement_score", { required: true }),
    ].filter(Boolean);
    if (feedback.activity_measures && typeof feedback.activity_measures === "object") {
      for (const [key, value] of Object.entries(feedback.activity_measures)) {
        const problem = integerScore(value, key, { required: true });
        if (problem) problems.push(problem);
      }
    }
    if (!feedback.one_strength || !feedback.one_specific_improvement || !feedback.retry_instruction) {
      problems.push("Feedback needs one strength, one improvement, and a retry instruction.");
    }
    if (problems.length) return error(res, problems[0]);
  }

  const isCoachedRetry = Boolean(body.is_coached_retry || feedback.is_coached_retry);
  const session = await PracticeSession.create({
    user: req.user._id,
    activitySlug: activity.slug,
    activityName: activity.name,
    promptCode: prompt?.code || null,
    promptTitle: body.prompt_title || prompt?.title || prompt?.promptText?.slice(0, 80) || activity.name,
    difficulty: body.difficulty || prompt?.difficulty || "beginner",
    transcript: String(body.transcript || "").slice(0, 20000),
    durationSeconds: Number(body.duration_seconds || 0),
    isCoachedRetry,
    withholdJudgement: withhold,
    feedback: {
      ...feedback,
      is_coached_retry: isCoachedRetry,
      withhold_judgement: withhold,
    },
  });

  const streak = await Streak.findOne({ user: req.user._id });
  applyPractice(streak, { isCoachedRetry });
  await streak.save();
  await bumpChallenges(req.user._id, session);

  return success(
    res,
    "Session stored. Skill scores are separate from streak and XP.",
    { session: sessionJson(session), streak: streakJson(streak) },
    201
  );
};

const listSessions = async (req, res) => {
  const filter = { user: req.user._id };
  if (req.query.activity) filter.activitySlug = req.query.activity;
  const limit = Math.min(Number(req.query.limit) || 20, 50);
  const offset = Number(req.query.offset) || 0;
  const [sessions, total] = await Promise.all([
    PracticeSession.find(filter).sort({ createdAt: -1 }).skip(offset).limit(limit),
    PracticeSession.countDocuments(filter),
  ]);
  return success(res, "Practice history.", {
    total,
    sessions: sessions.map(sessionJson),
  });
};

const getSession = async (req, res) => {
  const session = await PracticeSession.findOne({ _id: req.params.id, user: req.user._id });
  if (!session) return error(res, "Session not found.", 404);
  return success(res, "Session.", { session: sessionJson(session) });
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

const dashboard = async (req, res) => {
  const since = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
  const fresh = await PracticeSession.find({
    user: req.user._id,
    createdAt: { $gte: since },
    isCoachedRetry: false,
    withholdJudgement: false,
  });
  const streak = await Streak.findOne({ user: req.user._id });
  const recent = await PracticeSession.find({ user: req.user._id }).sort({ createdAt: -1 }).limit(8);

  const pillar = (key) => average(fresh, (row) => Number(row.feedback?.pillars?.[key]));
  const fluency = pillar("executive_score");
  const clarity = pillar("clarity_score");
  const engagement = pillar("engagement_score");
  const impact = pillar("impact_score");
  const overall = average(fresh, (row) => Number(row.feedback?.overall_score));

  const byActivity = new Map();
  for (const row of fresh) {
    if (!byActivity.has(row.activitySlug)) byActivity.set(row.activitySlug, []);
    byActivity.get(row.activitySlug).push(row);
  }
  const activityBreakdown = [...byActivity.entries()].map(([slug, rows]) => ({
    slug,
    name: rows[0].activityName,
    sessions: rows.length,
    overall: average(rows, (row) => Number(row.feedback?.overall_score)),
  }));

  return success(res, "Analytics for fresh prompts in the last 30 days.", {
    window_days: 30,
    fresh_prompts_only: true,
    overall,
    pillars: {
      executive_presence: { ...fluency, label: "Fluency and presence" },
      clarity: { ...clarity, label: "Clarity and articulation" },
      engagement: { ...engagement, label: "Engagement and tone" },
      impact: { ...impact, label: "Conciseness and impact" },
    },
    activity_breakdown: activityBreakdown,
    gamification: streakJson(streak),
    recent_sessions: recent.map(sessionJson),
  });
};

module.exports = { createSession, listSessions, getSession, dashboard };
