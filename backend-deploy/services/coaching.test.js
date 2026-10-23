const assert = require("assert");
const {
  triesNeeded,
  startingLevel,
  pickTodayPrompt,
  applyDecision,
  defaultCoaching,
  WEEK_MS,
  TWO_WEEKS_MS,
} = require("./coaching");

const NOW = new Date("2026-10-21T10:00:00.000Z");

function session({ slug, score, difficulty, daysAgo, fillers = 2 }) {
  return {
    activitySlug: slug,
    difficulty,
    isCoachedRetry: false,
    withholdJudgement: false,
    createdAt: new Date(NOW.getTime() - daysAgo * 24 * 60 * 60 * 1000),
    feedback: {
      overall_score: score,
      pillars: {
        executive_score: score,
        clarity_score: score,
        engagement_score: score,
        impact_score: score,
        crutch_count: fillers,
      },
    },
  };
}

function coaching(extra = {}) {
  return {
    ...defaultCoaching({
      confidence: "not_very",
      drills: ["think_fast", "cut_it_in_half", "debate_me"],
      now: extra.startedAt || NOW,
    }),
    ...extra,
  };
}

function DAY_PAD() {
  return 24 * 60 * 60 * 1000;
}

assert.strictEqual(triesNeeded(NOW, NOW), 2);
assert.strictEqual(triesNeeded(new Date(NOW.getTime() - 8 * 24 * 60 * 60 * 1000), NOW), 3);
assert.strictEqual(startingLevel("not_very"), "beginner");
assert.strictEqual(startingLevel("very"), "intermediary");

// Mid-week: two 4+ scores do not level up. Review is weekly.
{
  const state = coaching({
    startedAt: new Date(NOW.getTime() - 2 * 24 * 60 * 60 * 1000),
    defaultLevel: "beginner",
  });
  const sessions = [
    session({ slug: "think_fast", score: 4.1, difficulty: "beginner", daysAgo: 1 }),
    session({ slug: "think_fast", score: 4.3, difficulty: "beginner", daysAgo: 0 }),
  ];
  const prompt = pickTodayPrompt({ sessions, coaching: state, now: NOW });
  assert.notStrictEqual(prompt?.type, "level_up");
}

// After a week at the level: two 4+ scores this week → level up. Apply only on accept.
{
  const state = coaching({
    startedAt: new Date(NOW.getTime() - WEEK_MS - DAY_PAD()),
    defaultLevel: "beginner",
  });
  const sessions = [
    session({ slug: "think_fast", score: 4.1, difficulty: "beginner", daysAgo: 1 }),
    session({ slug: "think_fast", score: 4.3, difficulty: "beginner", daysAgo: 0 }),
  ];
  const prompt = pickTodayPrompt({ sessions, coaching: state, now: NOW });
  assert.ok(prompt, "expected level_up");
  assert.strictEqual(prompt.type, "level_up");
  assert.strictEqual(prompt.activity_slug, "think_fast");
  assert.strictEqual(prompt.next_level, "intermediary");
  const declined = applyDecision(state, prompt, "decline", { now: NOW });
  assert.strictEqual(declined.activityLevels.think_fast, undefined);
  const accepted = applyDecision(state, prompt, "accept", { now: NOW });
  assert.strictEqual(accepted.activityLevels.think_fast, "intermediary");
}

// Same week: after a level decision, no second level prompt.
{
  const state = coaching({
    startedAt: new Date(NOW.getTime() - WEEK_MS - DAY_PAD()),
    defaultLevel: "beginner",
  });
  const sessions = [
    session({ slug: "think_fast", score: 4.1, difficulty: "beginner", daysAgo: 1 }),
    session({ slug: "think_fast", score: 4.3, difficulty: "beginner", daysAgo: 0 }),
  ];
  const prompt = pickTodayPrompt({ sessions, coaching: state, now: NOW });
  const after = applyDecision(state, prompt, "accept", { now: NOW });
  const nextDay = new Date(NOW.getTime() + DAY_PAD());
  const again = pickTodayPrompt({ sessions, coaching: after, now: nextDay });
  assert.notStrictEqual(again?.type, "level_up");
  assert.notStrictEqual(again?.type, "step_down");
}

// One decision per day. An unanswered offer is returned again.
{
  const offered = {
    type: "level_up",
    activity_slug: "think_fast",
    next_level: "intermediary",
  };
  const unanswered = coaching({
    lastPopupDate: "2026-10-21",
    lastOfferedPrompt: offered,
  });
  assert.strictEqual(
    pickTodayPrompt({ sessions: [], coaching: unanswered, now: NOW }).type,
    "level_up"
  );
  const decided = coaching({ lastDecidedDate: "2026-10-21" });
  const sessions = [
    session({ slug: "think_fast", score: 4.1, difficulty: "beginner", daysAgo: 1 }),
    session({ slug: "think_fast", score: 4.3, difficulty: "beginner", daysAgo: 0 }),
  ];
  assert.strictEqual(pickTodayPrompt({ sessions, coaching: decided, now: NOW }), null);
}

// Two-week plan change when clarity is weakest.
{
  const state = coaching({
    startedAt: new Date(NOW.getTime() - TWO_WEEKS_MS - DAY_PAD()),
    planSetAt: new Date(NOW.getTime() - TWO_WEEKS_MS - DAY_PAD()),
    planDrills: ["think_fast", "debate_me", "cut_it_in_half"],
    defaultLevel: "beginner",
  });
  const sessions = [];
  for (let i = 0; i < 6; i += 1) {
    sessions.push({
      activitySlug: "think_fast",
      difficulty: "beginner",
      createdAt: new Date(NOW.getTime() - i * DAY_PAD()),
      feedback: {
        overall_score: 3.6,
        pillars: {
          executive_score: 3.6,
          clarity_score: 2.8,
          engagement_score: 3.2,
          impact_score: 3.4,
          crutch_count: 2,
        },
      },
    });
  }
  const prompt = pickTodayPrompt({ sessions, coaching: state, now: NOW });
  assert.strictEqual(prompt?.type, "plan_change");
  assert.strictEqual(prompt.to_activity_slug, "explain_it_simply");
  const kept = applyDecision(state, prompt, "decline", { now: NOW });
  assert.deepStrictEqual(kept.planDrills, state.planDrills);
  const swapped = applyDecision(state, prompt, "accept", { now: NOW });
  assert.strictEqual(swapped.planDrills[0], "explain_it_simply");
  assert.strictEqual(swapped.planDrills[1], "one_minute_expert");
}

// Progress check when scores rise but level did not change.
{
  const state = coaching({
    startedAt: new Date(NOW.getTime() - TWO_WEEKS_MS - DAY_PAD()),
    planSetAt: NOW, // block plan_change
    planDrills: ["cut_it_in_half", "think_fast", "debate_me"],
    defaultLevel: "beginner",
    lastLevelChangeAt: {},
    lastLevelReviewAt: NOW, // block weekly level this week
  });
  const sessions = [
    session({ slug: "cut_it_in_half", score: 2.9, difficulty: "beginner", daysAgo: 12, fillers: 5 }),
    session({ slug: "cut_it_in_half", score: 3.2, difficulty: "beginner", daysAgo: 8, fillers: 3 }),
    session({ slug: "cut_it_in_half", score: 3.6, difficulty: "beginner", daysAgo: 1, fillers: 2 }),
  ];
  const prompt = pickTodayPrompt({ sessions, coaching: state, now: NOW });
  assert.strictEqual(prompt?.type, "progress_check");
  assert.strictEqual(prompt.mode, "growth");
  assert.ok(!/stayed/i.test(JSON.stringify(prompt)));
}

// Weekly step-down after a week of weak scores at Intermediate.
{
  const state = coaching({
    startedAt: new Date(NOW.getTime() - WEEK_MS - DAY_PAD()),
    defaultLevel: "intermediary",
    activityLevels: { think_fast: "intermediary" },
    planDrills: ["think_fast", "cut_it_in_half", "debate_me"],
  });
  const sessions = [
    session({ slug: "think_fast", score: 2.0, difficulty: "intermediary", daysAgo: 2 }),
    session({ slug: "think_fast", score: 2.1, difficulty: "intermediary", daysAgo: 1 }),
  ];
  const prompt = pickTodayPrompt({ sessions, coaching: state, now: NOW });
  assert.strictEqual(prompt?.type, "step_down");
  const accepted = applyDecision(state, prompt, "accept", { now: NOW });
  assert.strictEqual(accepted.activityLevels.think_fast, "beginner");
}

console.log("coaching.test.js ok");
