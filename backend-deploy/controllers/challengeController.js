const ChallengeProgress = require("../models/ChallengeProgress");
const Streak = require("../models/Streak");
const { CHALLENGES } = require("../data/catalog");
const { success, error } = require("../helpers/response");
const { challengeView, dateKey, yesterdayKey } = require("../services/progress");
const { streakJson } = require("../services/serializers");

const listChallenges = async (req, res) => {
  const rows = await ChallengeProgress.find({ user: req.user._id });
  const bySlug = new Map(rows.map((row) => [row.slug, row]));
  return success(res, "Challenges.", {
    challenges: CHALLENGES.map((item) => challengeView(item, bySlug.get(item.slug))),
  });
};

const joinChallenge = async (req, res) => {
  const definition = CHALLENGES.find((item) => item.slug === req.params.slug);
  if (!definition) return error(res, "Challenge not found.", 404);
  const row = await ChallengeProgress.findOneAndUpdate(
    { user: req.user._id, slug: definition.slug },
    { joined: true },
    { new: true, upsert: true, setDefaultsOnInsert: true }
  );
  return success(res, "Challenge joined.", { challenge: challengeView(definition, row) });
};

const freezeStreak = async (req, res) => {
  const streak = await Streak.findOne({ user: req.user._id });
  if (!streak) return error(res, "Streak record missing.", 404);
  if (streak.streakFreezeCount < 1) return error(res, "No streak freezes left.", 400);

  const today = dateKey();
  const yesterday = yesterdayKey();
  if (streak.lastPracticeDate === today || streak.lastPracticeDate === yesterday || !streak.lastPracticeDate) {
    return error(res, "A freeze is only needed after a missed day.", 400);
  }

  streak.streakFreezeCount -= 1;
  streak.lastPracticeDate = yesterday;
  await streak.save();
  return success(res, "Streak freeze used. Skill scores are unchanged.", { streak: streakJson(streak) });
};

module.exports = { listChallenges, joinChallenge, freezeStreak };
