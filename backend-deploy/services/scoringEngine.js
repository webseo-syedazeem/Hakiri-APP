/**
 * Hakkiri activity scoring (spreadsheet model):
 * - Activity score = sum(measure_score × weight) for valid measures
 * - Cap: if heaviest measure ≤ 2, activity score cannot exceed 3
 * - Missing: drop measure, redistribute its weight; no score if heaviest
 *   missing or fewer than 2 valid measures
 */

const ACTIVITY_WEIGHTS = {
  think_fast: [
    { key: "structure", label: "Structure", weight: 0.4, heaviest: true },
    { key: "latency", label: "Latency", weight: 0.3 },
    { key: "fillers", label: "Fillers", weight: 0.3 },
  ],
  cut_it_in_half: [
    { key: "compression", label: "Compression with meaning kept", weight: 0.4, heaviest: true },
    { key: "time_to_value", label: "Time to value", weight: 0.35 },
    { key: "paraphrasing", label: "Paraphrasing", weight: 0.25 },
  ],
  one_minute_expert: [
    { key: "information_depth", label: "Information depth", weight: 0.4, heaviest: true },
    { key: "hook", label: "Hook", weight: 0.3 },
    { key: "time_management", label: "Time management", weight: 0.3 },
  ],
  explain_it_simply: [
    { key: "audience_fit", label: "Audience fit", weight: 0.35, heaviest: true },
    { key: "linguistic_fit", label: "Linguistic fit", weight: 0.25 },
    { key: "time_to_value", label: "Time to value", weight: 0.2 },
    { key: "structure", label: "Structure", weight: 0.2 },
  ],
  storytelling_gym: [
    { key: "structure", label: "Structure", weight: 0.3, heaviest: true },
    { key: "tension", label: "Tension", weight: 0.25 },
    { key: "significance", label: "Significance", weight: 0.25 },
    { key: "delivery", label: "Delivery", weight: 0.2 },
  ],
  connect_the_dots: [
    { key: "bridge_logic", label: "Bridge logic", weight: 0.35, heaviest: true },
    { key: "integration", label: "Integration", weight: 0.3 },
    { key: "pivot_placement", label: "Pivot placement", weight: 0.2 },
    { key: "speech", label: "Speech", weight: 0.15 },
  ],
  debate_me: [
    { key: "answers_objection", label: "Answers the objection", weight: 0.4, heaviest: true },
    { key: "reasoning", label: "Reasoning", weight: 0.3 },
    { key: "delivery", label: "Delivery", weight: 0.3 },
  ],
};

const CAP_MAX_WHEN_HEAVIEST_LOW = 3;
const HEAVIEST_LOW_THRESHOLD = 2;
const MIN_VALID_MEASURES = 2;

function getWeights(activitySlug) {
  const slug = String(activitySlug || "think_fast").trim();
  return ACTIVITY_WEIGHTS[slug] || ACTIVITY_WEIGHTS.think_fast;
}

function parseMeasureScore(raw) {
  if (raw == null || raw === "" || raw === "not_assessed" || raw === "not assessed") {
    return null;
  }
  const n = Number(raw);
  if (!Number.isFinite(n)) return null;
  const rounded = Math.round(n);
  if (rounded < 1 || rounded > 5) return null;
  return rounded;
}

/**
 * @param {string} activitySlug
 * @param {Record<string, number|null|string>} measureScores - key → 1-5 or null/not_assessed
 * @returns {{
 *   ok: boolean,
 *   overall_score: number|null,
 *   capped: boolean,
 *   withhold_judgement: boolean,
 *   reason: string|null,
 *   measures: Array<{key,label,weight,score,included,effective_weight}>,
 *   heaviest_key: string,
 * }}
 */
function computeActivityScore(activitySlug, measureScores = {}) {
  const defs = getWeights(activitySlug);
  const heaviest = defs.find((d) => d.heaviest) || defs[0];
  const heaviestRaw = parseMeasureScore(measureScores[heaviest.key]);

  const rows = defs.map((d) => {
    const score = parseMeasureScore(measureScores[d.key]);
    return {
      key: d.key,
      label: d.label,
      weight: d.weight,
      score,
      included: score != null,
      effective_weight: 0,
      is_heaviest: d.key === heaviest.key,
    };
  });

  // Heaviest missing → no score
  if (heaviestRaw == null) {
    return {
      ok: false,
      overall_score: null,
      capped: false,
      withhold_judgement: true,
      reason: `Heaviest measure (${heaviest.label}) could not be assessed.`,
      measures: rows,
      heaviest_key: heaviest.key,
    };
  }

  const valid = rows.filter((r) => r.included);
  if (valid.length < MIN_VALID_MEASURES) {
    return {
      ok: false,
      overall_score: null,
      capped: false,
      withhold_judgement: true,
      reason: `Fewer than ${MIN_VALID_MEASURES} valid measures.`,
      measures: rows,
      heaviest_key: heaviest.key,
    };
  }

  // Redistribute weights of missing measures across valid ones
  const validWeightSum = valid.reduce((s, r) => s + r.weight, 0);
  for (const row of rows) {
    if (!row.included) {
      row.effective_weight = 0;
      continue;
    }
    row.effective_weight =
      validWeightSum > 0 ? row.weight / validWeightSum : 1 / valid.length;
  }

  let overall = valid.reduce(
    (s, r) => s + r.score * (r.weight / validWeightSum),
    0
  );
  overall = Math.round(overall * 10) / 10;

  let capped = false;
  if (heaviestRaw <= HEAVIEST_LOW_THRESHOLD && overall > CAP_MAX_WHEN_HEAVIEST_LOW) {
    overall = CAP_MAX_WHEN_HEAVIEST_LOW;
    capped = true;
  }

  // Store as whole number 1-5 for app compatibility, keep decimal in meta
  const overallInt = Math.min(5, Math.max(1, Math.round(overall)));

  return {
    ok: true,
    overall_score: overallInt,
    overall_score_raw: overall,
    capped,
    withhold_judgement: false,
    reason: capped
      ? `Capped at ${CAP_MAX_WHEN_HEAVIEST_LOW} because ${heaviest.label} scored ${heaviestRaw}.`
      : null,
    measures: rows,
    heaviest_key: heaviest.key,
  };
}

/** Map activity measures onto the 4 dashboard pillars (best-effort). */
function measuresToPillars(activitySlug, measureScores, fallbackPillars = {}) {
  const get = (key, fb = 3) => {
    const v = parseMeasureScore(measureScores[key]);
    return v != null ? v : Number(fallbackPillars[key]) || fb;
  };
  const slug = String(activitySlug || "");

  if (slug === "think_fast") {
    return {
      executive_score: get("fillers", 3),
      clarity_score: get("structure", 3),
      impact_score: get("structure", 3),
      engagement_score: get("latency", 3),
    };
  }
  if (slug === "cut_it_in_half") {
    return {
      executive_score: get("paraphrasing", 3),
      clarity_score: get("compression", 3),
      impact_score: get("time_to_value", 3),
      engagement_score: get("paraphrasing", 3),
    };
  }
  if (slug === "debate_me") {
    return {
      executive_score: get("delivery", 3),
      clarity_score: get("reasoning", 3),
      impact_score: get("answers_objection", 3),
      engagement_score: get("delivery", 3),
    };
  }
  // Generic fallback from whatever keys exist
  const vals = Object.values(measureScores)
    .map(parseMeasureScore)
    .filter((v) => v != null);
  const avg = vals.length
    ? Math.round(vals.reduce((a, b) => a + b, 0) / vals.length)
    : 3;
  return {
    executive_score: avg,
    clarity_score: avg,
    impact_score: avg,
    engagement_score: avg,
  };
}

function measurePromptForActivity(activitySlug) {
  const defs = getWeights(activitySlug);
  return defs.map((d) => ({
    key: d.key,
    label: d.label,
    weight: d.weight,
    heaviest: Boolean(d.heaviest),
    score_hint:
      "Integer 1-5, or null if not_assessed (poor audio / cannot judge).",
  }));
}

module.exports = {
  ACTIVITY_WEIGHTS,
  getWeights,
  computeActivityScore,
  measuresToPillars,
  measurePromptForActivity,
  parseMeasureScore,
};
