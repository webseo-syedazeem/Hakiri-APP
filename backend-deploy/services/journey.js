/**
 * Hakkiri 12-month journey shell (chapters + weekly focus).
 * Scoring pillars stay permanent; chapters only change learning emphasis.
 */

const DAY_MS = 24 * 60 * 60 * 1000;
const WEEK_MS = 7 * DAY_MS;

const CHAPTERS = [
  {
    id: "build_the_habit",
    number: 1,
    title: "Build the habit",
    months: "1–2",
    startWeek: 1,
    endWeek: 8,
    scoringEmphasis: ["clarity", "structure", "engagement", "conciseness"],
    primaryFocus: "baseline",
    purpose:
      "Practise regularly and establish your communication baseline across all four scores.",
  },
  {
    id: "add_structure",
    number: 2,
    title: "Add structure",
    months: "3–4",
    startWeek: 9,
    endWeek: 16,
    scoringEmphasis: ["structure", "conciseness"],
    primaryFocus: "structure",
    purpose: "Organise answers clearly — point first, reasons, and a purposeful close.",
  },
  {
    id: "speak_with_clarity",
    number: 3,
    title: "Speak with clarity",
    months: "5–8",
    startWeek: 17,
    endWeek: 32,
    scoringEmphasis: ["clarity", "conciseness"],
    primaryFocus: "clarity",
    purpose: "Make messages easy to understand and get to the point sooner.",
  },
  {
    id: "handle_pressure",
    number: 4,
    title: "Handle pressure",
    months: "9–10",
    startWeek: 33,
    endWeek: 40,
    scoringEmphasis: ["structure", "engagement", "clarity", "conciseness"],
    primaryFocus: "pressure",
    purpose: "Keep the same four scores steady when the stakes or pushback rise.",
  },
  {
    id: "find_your_style",
    number: 5,
    title: "Find your own style",
    months: "11–12",
    startWeek: 41,
    endWeek: 52,
    scoringEmphasis: ["engagement", "structure", "clarity"],
    primaryFocus: "engagement",
    purpose: "Sound composed and engaging while staying clear and structured.",
  },
];

/** Weekly focuses rotate within each chapter (plan examples). */
const WEEKLY_FOCUSES = {
  build_the_habit: [
    "Show up and finish the exercise",
    "Speak a full answer, not a fragment",
    "Lead with one clear point",
    "Keep a steady pace",
    "Use one concrete example",
    "Cut one filler habit",
    "End with a clear next step",
    "Review what improved this week",
  ],
  add_structure: [
    "Lead with your point",
    "Support it with clear reasons",
    "Signpost your answer",
    "End with purpose",
    "Separate point from detail",
    "Use a simple three-part shape",
    "Close the loop in your last sentence",
    "Tighten the middle of your answer",
  ],
  speak_with_clarity: [
    "Use plain language",
    "Get to the point sooner",
    "Use one clear example",
    "Cut unnecessary setup",
    "Make your takeaway obvious",
    "Say more with fewer words",
    "Explain for a non-expert",
    "Replace jargon with a concrete picture",
  ],
  handle_pressure: [
    "Stay composed under pushback",
    "Answer the objection first",
    "Keep structure when rushed",
    "Pause before you respond",
    "Hold your position calmly",
    "Recover after a stumble",
    "Keep fillers down under pressure",
    "Finish cleanly when time is short",
  ],
  find_your_style: [
    "Open with energy",
    "Vary your pace with intent",
    "Sound confident without overclaiming",
    "Make the stakes feel real",
    "Keep warmth with authority",
    "Use delivery to support the point",
    "Leave a memorable takeaway",
    "Sound like yourself at your best",
  ],
};

function clampWeek(n) {
  const w = Math.max(1, Math.min(52, Math.floor(Number(n) || 1)));
  return w;
}

function chapterForWeek(weekNumber) {
  const w = clampWeek(weekNumber);
  return (
    CHAPTERS.find((c) => w >= c.startWeek && w <= c.endWeek) || CHAPTERS[0]
  );
}

function weekIndexInChapter(chapter, absoluteWeek) {
  const w = clampWeek(absoluteWeek);
  const total = chapter.endWeek - chapter.startWeek + 1;
  const idx = w - chapter.startWeek; // 0-based
  return {
    weekInChapter: idx + 1,
    weeksInChapter: total,
  };
}

function weeklyFocusFor(chapterId, weekInChapter) {
  const list = WEEKLY_FOCUSES[chapterId] || WEEKLY_FOCUSES.build_the_habit;
  const i = Math.max(0, (weekInChapter - 1) % list.length);
  return list[i];
}

function resolveJourneyStart(profile, firstSessionAt) {
  const stored = profile?.journey?.startedAt;
  if (stored) return new Date(stored);
  if (firstSessionAt) return new Date(firstSessionAt);
  if (profile?.createdAt) return new Date(profile.createdAt);
  return new Date();
}

function absoluteWeekFromStart(startedAt, now = new Date()) {
  const start = new Date(startedAt).getTime();
  const t = now.getTime();
  if (!Number.isFinite(start) || t < start) return 1;
  return clampWeek(Math.floor((t - start) / WEEK_MS) + 1);
}

/**
 * Build the journey snapshot for API / bootstrap.
 */
function buildJourneySnapshot({
  profile,
  firstSessionAt,
  now = new Date(),
  practiceDaysThisWeek = 0,
  pillarMovement = null,
  strongestMeasure = null,
  keepWorkingOn = null,
} = {}) {
  const startedAt = resolveJourneyStart(profile, firstSessionAt);
  const absoluteWeek = absoluteWeekFromStart(startedAt, now);
  const chapter = chapterForWeek(absoluteWeek);
  const { weekInChapter, weeksInChapter } = weekIndexInChapter(
    chapter,
    absoluteWeek
  );
  const weeklyFocus = weeklyFocusFor(chapter.id, weekInChapter);
  const completedIds = Array.isArray(profile?.journey?.completedChapterIds)
    ? profile.journey.completedChapterIds.map(String)
    : [];

  const chapters = CHAPTERS.map((c) => {
    let status = "upcoming";
    if (c.id === chapter.id) status = "current";
    else if (absoluteWeek > c.endWeek || completedIds.includes(c.id)) {
      status = "completed";
    }
    return {
      id: c.id,
      number: c.number,
      title: c.title,
      months: c.months,
      start_week: c.startWeek,
      end_week: c.endWeek,
      purpose: c.purpose,
      scoring_emphasis: c.scoringEmphasis,
      status,
    };
  });

  const nextFocus = weeklyFocusFor(
    chapter.id,
    Math.min(weekInChapter + 1, weeksInChapter)
  );

  return {
    started_at: startedAt.toISOString(),
    absolute_week: absoluteWeek,
    year_progress_pct: Math.round((absoluteWeek / 52) * 1000) / 10,
    chapter: {
      id: chapter.id,
      number: chapter.number,
      title: chapter.title,
      months: chapter.months,
      purpose: chapter.purpose,
      week_in_chapter: weekInChapter,
      weeks_in_chapter: weeksInChapter,
      scoring_emphasis: chapter.scoringEmphasis,
    },
    weekly_focus: weeklyFocus,
    next_week_focus: nextFocus,
    practice_days_this_week: practiceDaysThisWeek,
    chapters,
    weekly_review: {
      focus: weeklyFocus,
      practised_days: practiceDaysThisWeek,
      practised_label: `${practiceDaysThisWeek} of 7 days`,
      pillar_movement: pillarMovement,
      strongest_measure: strongestMeasure,
      keep_working_on: keepWorkingOn,
      next_week_focus: nextFocus,
    },
    chapter_review: {
      chapter_id: chapter.id,
      chapter_title: chapter.title,
      available: weekInChapter >= weeksInChapter || absoluteWeek >= chapter.endWeek,
      message:
        "Chapter reviews use the same four Hakkiri scores — not a separate pass/fail exam.",
    },
  };
}

function countPracticeDaysInWeek(sessions = [], now = new Date()) {
  const end = now.getTime();
  const start = end - 7 * DAY_MS;
  const days = new Set();
  for (const row of sessions) {
    const t = new Date(row.createdAt || row.timestamp).getTime();
    if (!Number.isFinite(t) || t < start || t > end) continue;
    days.add(new Date(t).toISOString().slice(0, 10));
  }
  return days.size;
}

module.exports = {
  CHAPTERS,
  WEEKLY_FOCUSES,
  buildJourneySnapshot,
  chapterForWeek,
  weeklyFocusFor,
  absoluteWeekFromStart,
  resolveJourneyStart,
  countPracticeDaysInWeek,
  clampWeek,
};
