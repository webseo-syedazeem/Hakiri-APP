const ChallengeProgress = require("../models/ChallengeProgress");
const { CHALLENGES } = require("../data/catalog");

function dateKey(date = new Date()) {
  return date.toISOString().slice(0, 10);
}

function yesterdayKey() {
  const d = new Date();
  d.setUTCDate(d.getUTCDate() - 1);
  return dateKey(d);
}

function applyPractice(streak, { isCoachedRetry }) {
  const today = dateKey();
  if (streak.lastPracticeDate !== today) {
    if (streak.lastPracticeDate === yesterdayKey()) {
      streak.currentStreak += 1;
    } else if (!streak.lastPracticeDate) {
      streak.currentStreak = 1;
    } else {
      streak.currentStreak = 1;
    }
    streak.longestStreak = Math.max(streak.longestStreak, streak.currentStreak);
    streak.lastPracticeDate = today;
  }
  streak.totalXp += isCoachedRetry ? 25 : 50;
  streak.completedSessions += 1;
}

async function bumpChallenges(userId, session) {
  const today = dateKey();
  const progressRows = await ChallengeProgress.find({ user: userId, joined: true });
  const bySlug = new Map(progressRows.map((row) => [row.slug, row]));

  for (const challenge of CHALLENGES) {
    if (!challenge.activitySlugs.includes(session.activitySlug)) continue;
    if (session.withholdJudgement) continue;
    let row = bySlug.get(challenge.slug);
    if (!row) {
      row = await ChallengeProgress.create({ user: userId, slug: challenge.slug, joined: true });
    }
    if (challenge.slug === "silent_power_pause") {
      const pauses = Number(session.feedback?.pillars?.power_pause_count || 0);
      if (pauses < 1) continue;
    }
    if (challenge.oncePerDay && row.countedDates.includes(today)) continue;
    row.completedCount += 1;
    if (!row.countedDates.includes(today)) row.countedDates.push(today);
    await row.save();
  }
}

function challengeView(definition, row) {
  const completed = row ? row.completedCount : 0;
  const target = definition.targetCount;
  const capped = Math.min(completed, target);
  return {
    slug: definition.slug,
    title: definition.title,
    tag: definition.tag,
    description: definition.description,
    target_count: target,
    completed_count: completed,
    progress_label: completed === 0 ? "Ready to start" : `${capped}/${target} completed`,
    progress_ratio: target === 0 ? 0 : Math.min(completed / target, 1),
    status: completed >= target ? "completed" : completed > 0 ? "active" : "ready",
    activity_slugs: definition.activitySlugs,
  };
}

module.exports = { applyPractice, bumpChallenges, challengeView, dateKey, yesterdayKey };
