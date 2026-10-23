/**
 * Level + two-week plan suggestions.
 * App only suggests; nothing changes until the user chooses.
 */

const DAY_MS = 24 * 60 * 60 * 1000;
const WEEK_MS = 7 * DAY_MS;
const TWO_WEEKS_MS = 14 * DAY_MS;

const LEVELS = ["beginner", "intermediary", "professional"];

const LEVEL_LABELS = {
  beginner: "Beginner",
  intermediary: "Intermediate",
  professional: "Pro",
};

const ACTIVITY_NAMES = {
  think_fast: "Think Fast",
  debate_me: "Debate Me",
  explain_it_simply: "Explain it Simply",
  one_minute_expert: "One Minute Expert",
  storytelling_gym: "Storytelling Gym",
  connect_the_dots: "Connect the Dots",
  cut_it_in_half: "Cut it in Half",
};

const SKILL_ROTATION = {
  fluency: {
    key: "fluency",
    label: "Fluency",
    main: "think_fast",
    support: "debate_me",
    pillar: "executive_score",
  },
  clarity: {
    key: "clarity",
    label: "Clarity",
    main: "explain_it_simply",
    support: "one_minute_expert",
    pillar: "clarity_score",
  },
  engagement: {
    key: "engagement",
    label: "Engagement",
    main: "storytelling_gym",
    support: "connect_the_dots",
    pillar: "engagement_score",
  },
  conciseness: {
    key: "conciseness",
    label: "Conciseness",
    main: "cut_it_in_half",
    support: "think_fast",
    pillar: "impact_score",
  },
};

const LEVEL_CHANGE_COPY = {
  think_fast:
    "Questions become real work moments, like a client asking why your price went up. Your answers carry over, and you can switch back anytime.",
  debate_me:
    "Pushback sounds more like a real stakeholder. Your scores carry over, and you can switch back anytime.",
  explain_it_simply:
    "You'll explain trickier ideas to someone outside your field. Scores carry over, and you can switch back anytime.",
  one_minute_expert:
    "You'll pack more into the minute, with less room to ramble. Scores carry over, and you can switch back anytime.",
  storytelling_gym:
    "Stories need a sharper hook and a clearer turn. Scores carry over, and you can switch back anytime.",
  connect_the_dots:
    "The two ideas sit further apart, so the bridge has to work harder. Scores carry over, and you can switch back anytime.",
  cut_it_in_half:
    "The source is denser, so the cut has to keep the point. Scores carry over, and you can switch back anytime.",
};

function dateStamp(d = new Date()) {
  return new Date(d).toISOString().slice(0, 10);
}

function normalizeLevel(raw) {
  const key = String(raw || "").trim().toLowerCase();
  if (key === "intermediate" || key === "intermediary") return "intermediary";
  if (key === "pro" || key === "professional") return "professional";
  if (key === "beginner") return "beginner";
  return "beginner";
}

function startingLevel(confidence) {
  const c = String(confidence || "").toLowerCase();
  if (c === "not_very" || c === "anxious" || c === "anxious_shaky") return "beginner";
  return "intermediary";
}

function nextLevel(level) {
  const i = LEVELS.indexOf(normalizeLevel(level));
  return i >= 0 && i < LEVELS.length - 1 ? LEVELS[i + 1] : null;
}

function prevLevel(level) {
  const i = LEVELS.indexOf(normalizeLevel(level));
  return i > 0 ? LEVELS[i - 1] : null;
}

function activityName(slug) {
  return ACTIVITY_NAMES[slug] || slug;
}

function triesNeeded(startedAt, now = new Date()) {
  const start = startedAt ? new Date(startedAt).getTime() : 0;
  if (!start) return 2;
  return now.getTime() - start < WEEK_MS ? 2 : 3;
}

function overallScore(session) {
  const n = Number(session?.feedback?.overall_score);
  return Number.isFinite(n) ? n : null;
}

function scoredSessions(sessions = []) {
  return (sessions || []).filter((row) => {
    if (row?.isCoachedRetry === true || row?.withholdJudgement === true) return false;
    return overallScore(row) != null;
  });
}

function activityLevel(coaching, slug) {
  const map = coaching?.activityLevels || {};
  if (map[slug]) return normalizeLevel(map[slug]);
  return normalizeLevel(coaching?.defaultLevel || "beginner");
}

function lastTriesAtLevel(sessions, slug, level, n) {
  const want = normalizeLevel(level);
  return scoredSessions(sessions)
    .filter((row) => row.activitySlug === slug && normalizeLevel(row.difficulty) === want)
    .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt))
    .slice(0, n);
}

function mean(values) {
  const nums = values.filter((v) => Number.isFinite(v));
  if (!nums.length) return null;
  return Math.round((nums.reduce((a, b) => a + b, 0) / nums.length) * 10) / 10;
}

function inWindow(sessions, from, to) {
  const a = from.getTime();
  const b = to.getTime();
  return scoredSessions(sessions).filter((row) => {
    const t = new Date(row.createdAt).getTime();
    return t >= a && t <= b;
  });
}

function pillarOf(session, key) {
  const n = Number(session?.feedback?.pillars?.[key]);
  return Number.isFinite(n) ? n : null;
}

function skillAverages(sessions) {
  const out = {};
  for (const [key, spec] of Object.entries(SKILL_ROTATION)) {
    out[key] = {
      ...spec,
      score: mean(sessions.map((s) => pillarOf(s, spec.pillar))),
    };
  }
  return out;
}

function weakestSkill(averages) {
  let best = null;
  for (const row of Object.values(averages)) {
    if (row.score == null) continue;
    if (!best || row.score < best.score) best = row;
  }
  return best;
}

function strongestGain(current, previous) {
  let best = null;
  for (const key of Object.keys(SKILL_ROTATION)) {
    const now = current[key]?.score;
    const was = previous[key]?.score;
    if (now == null || was == null) continue;
    const delta = Math.round((now - was) * 10) / 10;
    if (!best || delta > best.delta) {
      best = { key, label: SKILL_ROTATION[key].label, from: was, to: now, delta };
    }
  }
  return best;
}

function buildPlanDrills(main, support, current = []) {
  const out = [];
  for (const slug of [main, support, ...current]) {
    if (slug && !out.includes(slug)) out.push(slug);
    if (out.length >= 3) break;
  }
  const fallback = ["think_fast", "cut_it_in_half", "debate_me"];
  for (const slug of fallback) {
    if (!out.includes(slug)) out.push(slug);
    if (out.length >= 3) break;
  }
  return out.slice(0, 3);
}

function defaultCoaching({ confidence, drills, now = new Date() } = {}) {
  const level = startingLevel(confidence);
  const planDrills = (drills || []).filter(Boolean).slice(0, 3);
  return {
    startedAt: now,
    defaultLevel: level,
    activityLevels: {},
    planDrills: planDrills.length ? planDrills : ["think_fast", "cut_it_in_half", "debate_me"],
    planSetAt: now,
    lastPopupDate: null,
    lastPopupType: null,
    lastOfferedPrompt: null,
    lastDecidedDate: null,
    lastProgressCheckAt: null,
    lastLevelChangeAt: {},
    lastLevelReviewAt: null,
    declinedLevelUpUntil: {},
  };
}

function hydrateCoaching(raw, { confidence, drills, now = new Date() } = {}) {
  const fallback = defaultCoaching({ confidence, drills, now });
  if (!raw || typeof raw !== "object") return fallback;
  return {
    startedAt: raw.startedAt || fallback.startedAt,
    defaultLevel: normalizeLevel(raw.defaultLevel || fallback.defaultLevel),
    activityLevels: raw.activityLevels && typeof raw.activityLevels === "object"
      ? raw.activityLevels
      : {},
    planDrills:
      Array.isArray(raw.planDrills) && raw.planDrills.length
        ? raw.planDrills.map(String).slice(0, 3)
        : fallback.planDrills,
    planSetAt: raw.planSetAt || raw.startedAt || fallback.planSetAt,
    lastPopupDate: raw.lastPopupDate || null,
    lastPopupType: raw.lastPopupType || null,
    lastOfferedPrompt: raw.lastOfferedPrompt || null,
    lastDecidedDate: raw.lastDecidedDate || null,
    lastProgressCheckAt: raw.lastProgressCheckAt || null,
    lastLevelChangeAt:
      raw.lastLevelChangeAt && typeof raw.lastLevelChangeAt === "object"
        ? raw.lastLevelChangeAt
        : {},
    lastLevelReviewAt: raw.lastLevelReviewAt || null,
    declinedLevelUpUntil:
      raw.declinedLevelUpUntil && typeof raw.declinedLevelUpUntil === "object"
        ? raw.declinedLevelUpUntil
        : {},
  };
}

function alreadyDecidedToday(coaching, now = new Date()) {
  return String(coaching?.lastDecidedDate || "") === dateStamp(now);
}

function declinedRecently(coaching, slug, now = new Date()) {
  const until = coaching?.declinedLevelUpUntil?.[slug];
  if (!until) return false;
  return new Date(until).getTime() > now.getTime();
}

function lastLevelCadenceAt(coaching) {
  const times = [];
  if (coaching?.lastLevelReviewAt) {
    times.push(new Date(coaching.lastLevelReviewAt).getTime());
  }
  for (const value of Object.values(coaching?.lastLevelChangeAt || {})) {
    times.push(new Date(value).getTime());
  }
  if (
    (coaching?.lastPopupType === "level_up" || coaching?.lastPopupType === "step_down") &&
    coaching?.lastPopupDate
  ) {
    times.push(new Date(coaching.lastPopupDate).getTime());
  }
  if (coaching?.startedAt) times.push(new Date(coaching.startedAt).getTime());
  return times.filter((t) => Number.isFinite(t)).reduce((a, b) => Math.max(a, b), 0);
}

/** Level up/down at most once per week. */
function isWeeklyLevelDue(coaching, now = new Date()) {
  const last = lastLevelCadenceAt(coaching);
  if (!last) return true;
  return now.getTime() - last >= WEEK_MS;
}

function weekTriesAtLevel(sessions, slug, level, now = new Date()) {
  const from = new Date(now.getTime() - WEEK_MS);
  return scoredSessions(sessions)
    .filter((row) => {
      const t = new Date(row.createdAt).getTime();
      return (
        row.activitySlug === slug &&
        normalizeLevel(row.difficulty) === normalizeLevel(level) &&
        t >= from.getTime() &&
        t <= now.getTime()
      );
    })
    .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
}

function buildLevelPath(current) {
  const cur = normalizeLevel(current);
  return LEVELS.map((id, index) => ({
    id,
    label: LEVEL_LABELS[id],
    state: id === cur ? "current" : LEVELS.indexOf(cur) > index ? "done" : "locked",
    index: index + 1,
  }));
}

function pickLevelUp(sessions, coaching, now = new Date()) {
  if (!isWeeklyLevelDue(coaching, now)) return null;
  const slugs = Object.keys(ACTIVITY_NAMES);
  const candidates = [];
  for (const slug of slugs) {
    if (declinedRecently(coaching, slug, now)) continue;
    const current = activityLevel(coaching, slug);
    const bump = nextLevel(current);
    if (!bump) continue;
    const tries = weekTriesAtLevel(sessions, slug, current, now);
    if (tries.length < 2) continue;
    if (!tries.every((row) => overallScore(row) >= 4)) continue;
    candidates.push({
      slug,
      current,
      next: bump,
      scores: tries.map((row) => overallScore(row)).reverse(),
    });
  }
  if (!candidates.length) return null;
  const preferred = coaching.planDrills?.[0];
  candidates.sort((a, b) => {
    if (a.slug === preferred) return -1;
    if (b.slug === preferred) return 1;
    return 0;
  });
  const pick = candidates[0];
  return {
    type: "level_up",
    activity_slug: pick.slug,
    activity_name: activityName(pick.slug),
    eyebrow: `${activityName(pick.slug).toUpperCase()}  ·  LEVEL UP`,
    title: `You're ready for ${LEVEL_LABELS[pick.next]}.`,
    current_level: pick.current,
    next_level: pick.next,
    current_label: LEVEL_LABELS[pick.current],
    next_label: LEVEL_LABELS[pick.next],
    path: buildLevelPath(pick.next),
    last_scores: pick.scores,
    what_changes: LEVEL_CHANGE_COPY[pick.slug] || LEVEL_CHANGE_COPY.think_fast,
    primary_label: `Move up to ${LEVEL_LABELS[pick.next]}`,
    secondary_label: `Stay on ${LEVEL_LABELS[pick.current]} for now`,
    primary_choice: "accept",
    secondary_choice: "decline",
  };
}

function pickStepDown(sessions, coaching, now = new Date()) {
  if (!isWeeklyLevelDue(coaching, now)) return null;
  const slugs = coaching.planDrills?.length
    ? coaching.planDrills
    : Object.keys(ACTIVITY_NAMES);
  for (const slug of slugs) {
    const current = activityLevel(coaching, slug);
    const down = prevLevel(current);
    if (!down) continue;
    const tries = weekTriesAtLevel(sessions, slug, current, now);
    if (tries.length < 2) continue;
    const scores = tries.map(overallScore);
    const avg = mean(scores);
    if (avg == null || avg > 2.5) continue;
    if (scores.some((s) => s >= 3.5)) continue;
    return {
      type: "step_down",
      activity_slug: slug,
      activity_name: activityName(slug),
      eyebrow: `${activityName(slug).toUpperCase()}  ·  YOUR ADVICE`,
      title: "These questions are tough ones.",
      body:
        `${activityName(slug)} questions at ${LEVEL_LABELS[current]} are hard for most people. ` +
        `A few days of ${LEVEL_LABELS[down]} questions can build the habit faster, then you can move back up.`,
      current_level: current,
      next_level: down,
      current_label: LEVEL_LABELS[current],
      next_label: LEVEL_LABELS[down],
      build_up_title: "Build up first",
      build_up_body: `${LEVEL_LABELS[down]} for a few days. Your scores carry over.`,
      stay_title: "Stay and stretch",
      stay_body: `Keep ${LEVEL_LABELS[current]}, with extra tips each time.`,
      recognition: "You've answered every question so far. Showing up is the hard part.",
      primary_label: "Build up first",
      secondary_label: "Stay and stretch",
      primary_choice: "accept",
      secondary_choice: "decline",
    };
  }
  return null;
}

function pickPlanChange(sessions, coaching, now = new Date()) {
  const setAt = new Date(coaching.planSetAt || coaching.startedAt || now);
  if (now.getTime() - setAt.getTime() < TWO_WEEKS_MS) return null;
  const currentWindow = inWindow(sessions, new Date(now.getTime() - TWO_WEEKS_MS), now);
  if (currentWindow.length < 3) return null;
  const previousWindow = inWindow(
    sessions,
    new Date(now.getTime() - 2 * TWO_WEEKS_MS),
    new Date(now.getTime() - TWO_WEEKS_MS)
  );
  const currentSkills = skillAverages(currentWindow);
  const previousSkills = skillAverages(previousWindow);
  const weak = weakestSkill(currentSkills);
  if (!weak) return null;
  const nextDrills = buildPlanDrills(weak.main, weak.support, coaching.planDrills);
  const same =
    coaching.planDrills?.[0] === nextDrills[0] &&
    coaching.planDrills?.[1] === nextDrills[1];
  if (same) return null;
  const gain = strongestGain(currentSkills, previousSkills);
  const bars = Object.values(currentSkills).map((row) => ({
    key: row.key,
    label: row.label,
    score: row.score,
    weakest: row.key === weak.key,
  }));
  const leaving = (coaching.planDrills || []).find((s) => s !== nextDrills[0]) || coaching.planDrills?.[0];
  let insight = `${weak.label} is now your area to grow.`;
  if (gain && gain.delta > 0) {
    insight = `${gain.label} is up from ${gain.from}. ${weak.label} is now your area to grow.`;
  }
  return {
    type: "plan_change",
    eyebrow: "THE-WEEK CHECK-IN",
    title: "Your plan has a fresh focus.",
    insight,
    bars,
    weakest_key: weak.key,
    weakest_label: weak.label,
    from_activity_slug: leaving,
    from_activity_name: activityName(leaving),
    to_activity_slug: nextDrills[0],
    to_activity_name: activityName(nextDrills[0]),
    support_slug: nextDrills[1],
    support_name: activityName(nextDrills[1]),
    next_drills: nextDrills,
    reassurance:
      `${activityName(leaving)} still comes round every few days, and it's always in Practice.`,
    primary_label: "See my new plan",
    secondary_label: "Keep my current plan",
    primary_choice: "accept",
    secondary_choice: "decline",
  };
}

function pickProgressCheck(sessions, coaching, now = new Date()) {
  const slug = coaching.planDrills?.[0] || "think_fast";
  const lastChange = coaching.lastLevelChangeAt?.[slug];
  const lastCheck = coaching.lastProgressCheckAt;
  const lastTouch = [lastChange, lastCheck, coaching.startedAt]
    .filter(Boolean)
    .map((d) => new Date(d).getTime());
  const latest = lastTouch.length ? Math.max(...lastTouch) : 0;
  if (latest && now.getTime() - latest < TWO_WEEKS_MS) return null;

  const windowRows = inWindow(sessions, new Date(now.getTime() - TWO_WEEKS_MS), now)
    .filter((row) => row.activitySlug === slug)
    .sort((a, b) => new Date(a.createdAt) - new Date(b.createdAt));
  const allRecent = inWindow(sessions, new Date(now.getTime() - TWO_WEEKS_MS), now);
  if (allRecent.length < 2) return null;
  const current = activityLevel(coaching, slug);
  const bump = nextLevel(current);
  const n = triesNeeded(coaching.startedAt, now);
  const tries = lastTriesAtLevel(sessions, slug, current, n);
  const qualifying = tries.filter((row) => overallScore(row) >= 4).length;
  const scores = windowRows.map(overallScore).filter((v) => v != null);
  const startScore = scores[0] ?? null;
  const endScore = scores.length ? scores[scores.length - 1] : null;
  const rising = startScore != null && endScore != null && endScore > startScore;
  const personalBest = scores.length ? Math.max(...scores) : endScore;
  const fillersNow = mean(windowRows.map((s) => Number(s.feedback?.pillars?.crutch_count) || 0));
  const prevRows = inWindow(
    sessions,
    new Date(now.getTime() - 2 * TWO_WEEKS_MS),
    new Date(now.getTime() - TWO_WEEKS_MS)
  ).filter((row) => row.activitySlug === slug);
  const fillersThen = mean(prevRows.map((s) => Number(s.feedback?.pillars?.crutch_count) || 0));

  const wins = [];
  if (personalBest != null) {
    wins.push({ label: "Personal best", value: String(personalBest) });
  }
  if (fillersNow != null && fillersThen != null && fillersNow < fillersThen) {
    wins.push({
      label: "Fillers",
      value: `${Math.round(fillersThen)} → ${Math.round(fillersNow)}`,
    });
  }
  wins.push({ label: "Sessions", value: String(allRecent.length) });

  if (rising) {
    return {
      type: "progress_check",
      activity_slug: slug,
      activity_name: activityName(slug),
      eyebrow: `${activityName(slug).toUpperCase()}  ·  PROGRESS CHECK`,
      title: "You're getting sharper.",
      mode: "growth",
      from_score: startScore,
      to_score: endScore,
      trend_label: `▲ ${startScore} → ${endScore}`,
      points: scores.slice(-8),
      wins: wins.slice(0, 3),
      next_level: bump,
      next_label: bump ? LEVEL_LABELS[bump] : null,
      qualifying,
      needed: n,
      distance_label: bump
        ? `Nearly at ${LEVEL_LABELS[bump]}`
        : "You're at the top level",
      tip: bump
        ? `Keep this up. A strong week at ${LEVEL_LABELS[current]} unlocks ${LEVEL_LABELS[bump]}. Open with your point in the first few seconds.`
        : "Keep the same standard. Open with your point in the first few seconds.",
      primary_label: "Keep going",
      primary_choice: "dismiss",
    };
  }

  return {
    type: "progress_check",
    activity_slug: slug,
    activity_name: activityName(slug),
    eyebrow: `${activityName(slug).toUpperCase()}  ·  PROGRESS CHECK`,
    title: "You're showing up.",
    mode: "habit",
    from_score: startScore,
    to_score: endScore,
    trend_label: null,
    points: scores.slice(-8),
    wins: [
      { label: "Sessions", value: String(allRecent.length) },
      { label: "This fortnight", value: `${windowRows.length} on ${activityName(slug)}` },
    ],
    next_level: bump,
    next_label: bump ? LEVEL_LABELS[bump] : null,
    qualifying,
    needed: n,
    distance_label: null,
    tip: "Keep the next session under two minutes. Start with the point, then stop.",
    primary_label: "Keep going",
    primary_choice: "dismiss",
  };
}

/**
 * At most one prompt per calendar day.
 * Priority: plan_change (every 2 weeks) → weekly level_up → weekly step_down → progress_check.
 */
function pickTodayPrompt({ sessions, coaching, now = new Date() } = {}) {
  const state = hydrateCoaching(coaching);
  if (alreadyDecidedToday(state, now)) return null;
  const today = dateStamp(now);
  if (state.lastOfferedPrompt && state.lastPopupDate === today) {
    return state.lastOfferedPrompt;
  }
  return (
    pickPlanChange(sessions, state, now) ||
    pickLevelUp(sessions, state, now) ||
    pickStepDown(sessions, state, now) ||
    pickProgressCheck(sessions, state, now)
  );
}

function markOffered(coaching, prompt, { now = new Date() } = {}) {
  const next = hydrateCoaching(coaching, { now });
  if (!prompt) return next;
  next.lastPopupDate = dateStamp(now);
  next.lastPopupType = prompt.type;
  next.lastOfferedPrompt = prompt;
  return next;
}

function applyDecision(coaching, prompt, choice, { now = new Date() } = {}) {
  const next = hydrateCoaching(coaching, { now });
  next.lastPopupDate = dateStamp(now);
  next.lastDecidedDate = dateStamp(now);
  next.lastPopupType = prompt?.type || next.lastPopupType;
  next.lastOfferedPrompt = null;
  const decided = String(choice || "").toLowerCase();
  if (prompt?.type === "level_up" || prompt?.type === "step_down") {
    next.lastLevelReviewAt = now;
  }

  if (prompt?.type === "level_up") {
    const slug = prompt.activity_slug;
    if (decided === "accept" && prompt.next_level) {
      next.activityLevels = { ...next.activityLevels, [slug]: prompt.next_level };
      next.lastLevelChangeAt = { ...next.lastLevelChangeAt, [slug]: now };
    } else {
      next.declinedLevelUpUntil = {
        ...next.declinedLevelUpUntil,
        [slug]: new Date(now.getTime() + WEEK_MS),
      };
    }
  } else if (prompt?.type === "step_down") {
    const slug = prompt.activity_slug;
    if (decided === "accept" && prompt.next_level) {
      next.activityLevels = { ...next.activityLevels, [slug]: prompt.next_level };
      next.lastLevelChangeAt = { ...next.lastLevelChangeAt, [slug]: now };
    }
  } else if (prompt?.type === "plan_change") {
    if (decided === "accept" && Array.isArray(prompt.next_drills) && prompt.next_drills.length) {
      next.planDrills = prompt.next_drills.slice(0, 3);
      next.planSetAt = now;
    } else {
      next.planSetAt = now;
    }
  } else if (prompt?.type === "progress_check") {
    next.lastProgressCheckAt = now;
  }

  return next;
}

function setActivityLevel(coaching, slug, level, { now = new Date() } = {}) {
  const next = hydrateCoaching(coaching, { now });
  next.activityLevels = { ...next.activityLevels, [slug]: normalizeLevel(level) };
  next.lastLevelChangeAt = { ...next.lastLevelChangeAt, [slug]: now };
  return next;
}

module.exports = {
  DAY_MS,
  WEEK_MS,
  TWO_WEEKS_MS,
  LEVELS,
  LEVEL_LABELS,
  ACTIVITY_NAMES,
  SKILL_ROTATION,
  dateStamp,
  normalizeLevel,
  startingLevel,
  nextLevel,
  prevLevel,
  activityName,
  triesNeeded,
  activityLevel,
  lastTriesAtLevel,
  weekTriesAtLevel,
  isWeeklyLevelDue,
  buildPlanDrills,
  defaultCoaching,
  hydrateCoaching,
  pickTodayPrompt,
  markOffered,
  applyDecision,
  setActivityLevel,
};
