const Reflection = require("../models/Reflection");
const PracticeSession = require("../models/PracticeSession");
const Streak = require("../models/Streak");
const { success, error } = require("../helpers/response");

function reflectionJson(doc) {
  return {
    id: String(doc._id),
    title: doc.title || "",
    learnings: doc.learnings || "",
    focus_area: doc.focusArea || "",
    created_at: doc.createdAt,
  };
}

function rangeDays(raw) {
  const key = String(raw || "28").toLowerCase();
  if (key === "7" || key === "7d" || key === "week") return 7;
  if (key === "90" || key === "3m" || key === "90d") return 90;
  return 28;
}

async function buildStats(userId, since) {
  const [sessionCount, notes, streak] = await Promise.all([
    PracticeSession.countDocuments({
      user: userId,
      createdAt: { $gte: since },
      withholdJudgement: { $ne: true },
    }),
    Reflection.find({ user: userId, createdAt: { $gte: since } })
      .select("focusArea")
      .lean(),
    Streak.findOne({ user: userId }).lean(),
  ]);
  const focuses = new Set(
    notes.map((n) => String(n.focusArea || "").trim()).filter(Boolean)
  );
  return {
    practice_sessions: sessionCount,
    focus_areas_completed: focuses.size,
    day_streak: streak?.currentStreak || 0,
  };
}

const list = async (req, res) => {
  try {
    const days = rangeDays(req.query.days || req.query.range);
    const since = new Date(Date.now() - days * 24 * 60 * 60 * 1000);
    const [rows, stats] = await Promise.all([
      Reflection.find({ user: req.user._id }).sort({ createdAt: -1 }).limit(100).lean(),
      buildStats(req.user._id, since),
    ]);
    return success(res, "Reflections.", {
      days,
      stats,
      reflections: rows.map(reflectionJson),
    });
  } catch (err) {
    console.error("reflections.list failed:", err.message);
    return error(res, err.message || "Could not load reflections.", 502);
  }
};

const create = async (req, res) => {
  try {
    const learnings = String(req.body?.learnings || req.body?.body || "").trim();
    let focusArea = String(req.body?.focus_area || req.body?.focusArea || "").trim();
    let title = String(req.body?.title || "").trim();
    if (!learnings && !focusArea) {
      return error(res, "Write a reflection or pick a focus first.", 400);
    }
    if (!focusArea) focusArea = "General growth";
    if (!title) {
      const first = (learnings || focusArea).split("\n")[0];
      title = first.length > 48 ? `${first.slice(0, 48)}…` : first;
    }
    const doc = await Reflection.create({
      user: req.user._id,
      title: title.slice(0, 120),
      learnings: learnings.slice(0, 2000) || `Focused on ${focusArea} today.`,
      focusArea: focusArea.slice(0, 80),
    });
    return success(res, "Reflection saved.", { reflection: reflectionJson(doc) }, 201);
  } catch (err) {
    console.error("reflections.create failed:", err.message);
    return error(res, err.message || "Could not save reflection.", 502);
  }
};

module.exports = { list, create, reflectionJson, buildStats };
