/**
 * Hakkiri scoring (12-month plan source of truth):
 * 1) Score activity-specific measures first
 * 2) Map only relevant measures → Clarity / Structure / Engagement / Conciseness
 * 3) Diagnostic measures stay out of headline pillars
 * 4) Same-pillar measures in one session → one averaged observation
 * 5) Activity overall = weighted measures (cap rules)
 *
 * API field mapping (stable keys for the Flutter app):
 *   clarity_score      → Clarity
 *   executive_score    → Structure
 *   engagement_score   → Engagement & Tone
 *   impact_score       → Conciseness
 */

const ACTIVITY_WEIGHTS = {
  think_fast: [
    { key: "response_readiness", label: "Response Readiness", weight: 0.35 },
    { key: "text_structure", label: "Answer Structure", weight: 0.4, heaviest: true },
    { key: "filler_control", label: "Filler Control", weight: 0.25 },
  ],
  cut_it_in_half: [
    { key: "message_compression", label: "Message Compression", weight: 0.4, heaviest: true },
    { key: "point_first", label: "Point First", weight: 0.35 },
    { key: "paraphrasing", label: "Paraphrasing", weight: 0.25 },
  ],
  one_minute_expert: [
    { key: "content_structure", label: "Content Structure", weight: 0.4, heaviest: true },
    { key: "opening_impact", label: "Opening Impact", weight: 0.3 },
    { key: "time_control", label: "Time Control", weight: 0.3 },
  ],
  explain_it_simply: [
    { key: "audience_fit", label: "Audience Fit", weight: 0.35, heaviest: true },
    { key: "opening_impact", label: "Opening Impact", weight: 0.2 },
    { key: "time_control", label: "Time Control", weight: 0.2 },
    { key: "language_simplicity", label: "Language Simplicity", weight: 0.25 },
  ],
  storytelling_gym: [
    { key: "story_structure", label: "Story Structure", weight: 0.3, heaviest: true },
    { key: "tension_and_stakes", label: "Tension & Stakes", weight: 0.25 },
    { key: "clear_takeaway", label: "Clear Takeaway", weight: 0.25 },
    { key: "delivery_control", label: "Delivery Control", weight: 0.2 },
  ],
  connect_the_dots: [
    { key: "connection_logic", label: "Connection Logic", weight: 0.35, heaviest: true },
    { key: "idea_structure", label: "Idea Structure", weight: 0.3 },
    { key: "transition_timing", label: "Transition Timing", weight: 0.2 },
    { key: "delivery_control", label: "Delivery Control", weight: 0.15 },
  ],
  debate_me: [
    { key: "argument_quality", label: "Argument Quality", weight: 0.4, heaviest: true },
    { key: "delivery_control", label: "Delivery Control", weight: 0.3 },
    { key: "perceived_confidence", label: "Perceived Confidence", weight: 0.3 },
  ],
};

/** Client plan: measure → permanent pillar | diagnostic */
const MEASURE_PILLAR = {
  response_readiness: "diagnostic",
  transition_timing: "diagnostic",
  text_structure: "structure",
  answer_structure: "structure",
  filler_control: "engagement",
  message_compression: "conciseness",
  point_first: "conciseness",
  paraphrasing: "clarity",
  opening_impact: "engagement",
  content_structure: "structure",
  time_control: "conciseness",
  audience_fit: "clarity",
  language_simplicity: "clarity",
  story_structure: "structure",
  tension_and_stakes: "engagement",
  clear_takeaway: "clarity",
  delivery_control: "engagement",
  idea_structure: "structure",
  connection_logic: "clarity",
  argument_quality: "structure",
  perceived_confidence: "engagement",
};

const PILLAR_API_KEYS = {
  clarity: "clarity_score",
  structure: "executive_score",
  engagement: "engagement_score",
  conciseness: "impact_score",
};

const PILLAR_LABELS = {
  clarity: "Clarity",
  structure: "Structure",
  engagement: "Engagement & Tone",
  conciseness: "Conciseness",
};

const KEY_ALIASES = {
  response_readiness: ["response_readiness", "latency", "latency_and_stall_tactics", "latency and stall tactics", "readiness"],
  text_structure: ["text_structure", "answer_structure", "structure", "structural_coherence", "structural coherence", "answer structure", "text structure"],
  filler_control: ["filler_control", "fillers", "composition_fillers", "composition and fillers", "filler control"],
  message_compression: ["message_compression", "compression", "rate_compression"],
  point_first: ["point_first", "time_to_value"],
  paraphrasing: ["paraphrasing", "jargon_mimicry"],
  opening_impact: ["opening_impact", "hook", "immediate_engagement"],
  content_structure: ["content_structure", "information_depth"],
  time_control: ["time_control", "time_management", "time_optimisation"],
  audience_fit: ["audience_fit", "audience_alignment", "persona_calibration"],
  language_simplicity: ["language_simplicity", "linguistic_fit"],
  story_structure: ["story_structure", "structural_architecture"],
  tension_and_stakes: ["tension_and_stakes", "tension", "tension_and_conflict", "stakes"],
  clear_takeaway: ["clear_takeaway", "significance", "significance_check", "takeaway"],
  delivery_control: ["delivery_control", "delivery", "speech_delivery", "speech"],
  idea_structure: ["idea_structure", "integration", "conceptual_integration"],
  connection_logic: ["connection_logic", "bridge_logic"],
  transition_timing: ["transition_timing", "pivot_placement"],
  argument_quality: ["argument_quality", "answers_objection", "reasoning", "rhetorical_integrity"],
  perceived_confidence: ["perceived_confidence"],
};

const CAP_MAX_WHEN_HEAVIEST_LOW = 3;
const HEAVIEST_LOW_THRESHOLD = 2;
const MIN_VALID_MEASURES = 2;
const ROLLING_OBSERVATIONS = 8;

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
  if (n < 0.5 || n > 5.5) return null;
  return Math.min(5, Math.max(1, Math.round(n * 10) / 10));
}

function resolveMeasureScore(key, measureScores = {}) {
  if (!measureScores || typeof measureScores !== "object") return null;

  if (measureScores[key] != null) return parseMeasureScore(measureScores[key]);

  const norm = (s) => String(s || "").toLowerCase().replace(/[^a-z0-9]/g, "");
  const targetNorm = norm(key);
  const aliases = (KEY_ALIASES[key] || []).map(norm);
  aliases.push(targetNorm);

  for (const [k, v] of Object.entries(measureScores)) {
    if (v != null && aliases.includes(norm(k))) {
      const parsed = parseMeasureScore(v);
      if (parsed != null) return parsed;
    }
  }
  return null;
}

function round1(n) {
  return Math.round(Number(n) * 10) / 10;
}

function computeActivityScore(activitySlug, measureScores = {}) {
  const defs = getWeights(activitySlug);
  const heaviest = defs.find((d) => d.heaviest) || defs[0];
  const heaviestRaw = resolveMeasureScore(heaviest.key, measureScores);

  const rows = defs.map((d) => {
    const score = resolveMeasureScore(d.key, measureScores);
    return {
      key: d.key,
      label: d.label,
      weight: d.weight,
      score,
      included: score != null,
      effective_weight: 0,
      is_heaviest: d.key === heaviest.key,
      pillar: MEASURE_PILLAR[d.key] || null,
      diagnostic: MEASURE_PILLAR[d.key] === "diagnostic",
    };
  });

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
  overall = round1(overall);

  let capped = false;
  if (heaviestRaw <= HEAVIEST_LOW_THRESHOLD && overall > CAP_MAX_WHEN_HEAVIEST_LOW) {
    overall = CAP_MAX_WHEN_HEAVIEST_LOW;
    capped = true;
  }

  const overallOneDp = Math.min(5, Math.max(1, round1(overall)));

  return {
    ok: true,
    overall_score: overallOneDp,
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

/**
 * Build session pillar contributions from activity measures.
 * Only pillars with real evidence are returned (no invented scores).
 */
function sessionPillarContributions(activitySlug, measureScores = {}) {
  const defs = getWeights(activitySlug);
  const buckets = {
    clarity: [],
    structure: [],
    engagement: [],
    conciseness: [],
  };
  const diagnostic = [];

  for (const d of defs) {
    const score = resolveMeasureScore(d.key, measureScores);
    if (score == null) continue;
    const pillar = MEASURE_PILLAR[d.key];
    if (!pillar) continue;
    if (pillar === "diagnostic") {
      diagnostic.push({
        key: d.key,
        label: d.label,
        score,
      });
      continue;
    }
    if (buckets[pillar]) {
      buckets[pillar].push({ key: d.key, label: d.label, score });
    }
  }

  const contributions = {};
  const detail = {};
  for (const [pillar, rows] of Object.entries(buckets)) {
    if (!rows.length) continue;
    const avg = round1(rows.reduce((s, r) => s + r.score, 0) / rows.length);
    contributions[pillar] = avg;
    detail[pillar] = {
      score: avg,
      label: PILLAR_LABELS[pillar],
      measures: rows,
    };
  }

  return { contributions, detail, diagnostic };
}

/**
 * Map contributions onto API pillar keys.
 * Unmeasured pillars are null (do not invent).
 */
function measuresToPillars(activitySlug, measureScores /*, fallbackPillars ignored */) {
  const { contributions, detail, diagnostic } = sessionPillarContributions(
    activitySlug,
    measureScores
  );

  return {
    executive_score: contributions.structure ?? null, // Structure
    clarity_score: contributions.clarity ?? null,
    impact_score: contributions.conciseness ?? null, // Conciseness
    engagement_score: contributions.engagement ?? null,
    pillar_contributions: contributions,
    pillar_detail: detail,
    diagnostic_measures: diagnostic,
  };
}

/** Equal average of the pillars that have evidence; null if none. */
function overallFromPillars(pillars = {}) {
  const vals = [
    pillars.clarity_score,
    pillars.executive_score,
    pillars.engagement_score,
    pillars.impact_score,
  ]
    .map((v) => (v == null || v === "" ? null : Number(v)))
    .filter((v) => Number.isFinite(v));
  if (!vals.length) return null;
  return round1(vals.reduce((a, b) => a + b, 0) / vals.length);
}

/**
 * Rolling pillar average from recent fresh-prompt sessions.
 * Uses pillar_contributions when present; falls back to pillars keys.
 */
function rollingPillarAverage(sessions = [], pillarKey, limit = ROLLING_OBSERVATIONS) {
  const apiKey = PILLAR_API_KEYS[pillarKey] || pillarKey;
  const contribKey =
    pillarKey === "structure"
      ? "structure"
      : pillarKey === "conciseness"
        ? "conciseness"
        : pillarKey === "engagement"
          ? "engagement"
          : pillarKey === "clarity"
            ? "clarity"
            : null;

  const values = [];
  for (const row of sessions) {
    if (row?.isCoachedRetry) continue;
    if (row?.withholdJudgement) continue;
    const fb = row.feedback || {};
    const contrib = fb.pillar_contributions || fb.scoring?.pillar_contributions;
    let v = null;
    if (contrib && contribKey && contrib[contribKey] != null) {
      v = Number(contrib[contribKey]);
    } else if (fb.pillars && fb.pillars[apiKey] != null) {
      v = Number(fb.pillars[apiKey]);
    }
    if (!Number.isFinite(v)) continue;
    values.push(v);
    if (values.length >= limit) break;
  }

  if (!values.length) {
    return { average: null, samples: 0, status: "need_more" };
  }
  const average = round1(values.reduce((a, b) => a + b, 0) / values.length);
  return {
    average,
    samples: values.length,
    status: values.length < 3 ? "need_more" : "ready",
  };
}

function measurePromptForActivity(activitySlug) {
  const defs = getWeights(activitySlug);
  return defs.map((d) => ({
    key: d.key,
    label: d.label,
    weight: d.weight,
    heaviest: Boolean(d.heaviest),
    pillar: MEASURE_PILLAR[d.key] || null,
    diagnostic: MEASURE_PILLAR[d.key] === "diagnostic",
    score_hint:
      "Number 1.0–5.0 to one decimal place, or null if not_assessed (poor audio / cannot judge).",
  }));
}

module.exports = {
  ACTIVITY_WEIGHTS,
  MEASURE_PILLAR,
  PILLAR_API_KEYS,
  PILLAR_LABELS,
  ROLLING_OBSERVATIONS,
  getWeights,
  computeActivityScore,
  measuresToPillars,
  sessionPillarContributions,
  overallFromPillars,
  rollingPillarAverage,
  measurePromptForActivity,
  parseMeasureScore,
  resolveMeasureScore,
};
