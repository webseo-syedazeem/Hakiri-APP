/**
 * When a journey chapter's months/weeks elapse (or user marks complete),
 * persist completion and send one FCM per chapter.
 */

const User = require("../models/User");
const Profile = require("../models/Profile");
const PracticeSession = require("../models/PracticeSession");
const {
  CHAPTERS,
  absoluteWeekFromStart,
  resolveJourneyStart,
} = require("./journey");
const { isFirebaseConfigured, sendToTokens } = require("../config/firebase");

function hydrateJourney(profile) {
  const raw =
    profile?.journey && typeof profile.journey === "object"
      ? profile.journey
      : {};
  return {
    startedAt: raw.startedAt || null,
    completedChapterIds: Array.isArray(raw.completedChapterIds)
      ? [...raw.completedChapterIds].map(String)
      : [],
    notifiedChapterCompleteIds: Array.isArray(raw.notifiedChapterCompleteIds)
      ? [...raw.notifiedChapterCompleteIds].map(String)
      : [],
    benchmarks: Array.isArray(raw.benchmarks) ? [...raw.benchmarks] : [],
  };
}

/**
 * Mark chapters whose week window has passed, and notify once per chapter.
 * @param {string|object} userId
 * @param {{ forceChapterId?: string }} [opts] — also treat this id as complete (API mark)
 */
async function syncChapterCompletionAndNotify(userId, opts = {}) {
  const profile = await Profile.findOne({ user: userId });
  if (!profile) return { newlyCompleted: [], notified: [] };

  const first = await PracticeSession.findOne({ user: userId })
    .sort({ createdAt: 1 })
    .select("createdAt");

  const journey = hydrateJourney(profile);
  if (!journey.startedAt) {
    journey.startedAt = resolveJourneyStart(profile, first?.createdAt);
  }

  const absoluteWeek = absoluteWeekFromStart(journey.startedAt);
  const completed = new Set(journey.completedChapterIds);
  const notified = new Set(journey.notifiedChapterCompleteIds);
  const newlyCompleted = [];

  for (const chapter of CHAPTERS) {
    const elapsed = absoluteWeek > chapter.endWeek;
    const forced =
      opts.forceChapterId && String(opts.forceChapterId) === chapter.id;
    if ((elapsed || forced) && !completed.has(chapter.id)) {
      completed.add(chapter.id);
      newlyCompleted.push(chapter);
    }
  }

  const pendingNotify = CHAPTERS.filter(
    (c) => completed.has(c.id) && !notified.has(c.id)
  );

  journey.completedChapterIds = [...completed];
  profile.journey = journey;

  const notifiedNow = [];
  if (pendingNotify.length && isFirebaseConfigured()) {
    const user = await User.findById(userId).select("fullName fcmTokens");
    const tokens = Array.isArray(user?.fcmTokens) ? user.fcmTokens : [];
    const firstName = String(user?.fullName || "there").split(/\s+/)[0];

    for (const chapter of pendingNotify) {
      if (!tokens.length) {
        notified.add(chapter.id);
        notifiedNow.push(chapter.id);
        continue;
      }
      try {
        const result = await sendToTokens({
          tokens,
          title: `Chapter ${chapter.number} complete`,
          body: `Nice work, ${firstName}. "${chapter.title}" (Months ${chapter.months}) is done — open your chapter review.`,
          data: {
            type: "chapter_complete",
            screen: "journey",
            open_review: "true",
            chapter_id: chapter.id,
            chapter_number: String(chapter.number),
            chapter_title: chapter.title,
            months: chapter.months,
          },
        });
        if (result.invalidTokens?.length && user) {
          user.fcmTokens = user.fcmTokens.filter(
            (t) => !result.invalidTokens.includes(t)
          );
          await user.save();
        }
      } catch (err) {
        console.error(
          `[journeyCompletion] FCM failed for ${chapter.id}:`,
          err.message
        );
      }
      notified.add(chapter.id);
      notifiedNow.push(chapter.id);
    }
  } else if (pendingNotify.length) {
    // Firebase not configured — still mark notified so we don't retry forever.
    for (const chapter of pendingNotify) {
      notified.add(chapter.id);
      notifiedNow.push(chapter.id);
    }
  }

  journey.notifiedChapterCompleteIds = [...notified];
  profile.journey = journey;
  await profile.save();

  return {
    absoluteWeek,
    newlyCompleted: newlyCompleted.map((c) => c.id),
    notified: notifiedNow,
  };
}

module.exports = {
  syncChapterCompletionAndNotify,
  hydrateJourney,
};
