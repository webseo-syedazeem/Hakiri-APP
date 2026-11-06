/**
 * Hakkiri activity scoring (spreadsheet model):
 * - Activity score = sum(measure_score × weight) for valid measures
 * - Cap: if heaviest measure ≤ 2, activity score cannot exceed 3
 * - Missing: drop measure, redistribute its weight; no score if heaviest
 *   missing or fewer than 2 valid measures
 */

const ACTIVITY_WEIGHTS = {
  think_fast: [
    { key: "response_readiness", label: "Response Readiness", weight: 0.35 },
    { key: "text_structure", label: "Text Structure", weight: 0.4, heaviest: true },
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

const KEY_ALIASES = {
  response_readiness: ["response_readiness", "latency", "latency_and_stall_tactics", "latency and stall tactics", "readiness"],
  text_structure: ["text_structure", "answer_structure", "structure", "structural_coherence", "structural coherence", "answer structure", "text structure"],
  filler_control: ["filler_control", "fillers", "composition_fillers", "composition and fillers", "filler control"],
  message_compression: ["message_compression", "compression", "rate_compression"],
  point_first: ["point_first", "time_to_value"],
  paraphrasing: ["paraphrasing", "jargon_mimicry"],
  opening_impact: ["opening_impact", "hook", "immediate_engagement"],
  content_structure: ["content_structure", "information_depth", "structure"],
  time_control: ["time_control", "time_management", "time_optimisation"],
  audience_fit: ["audience_fit", "audience_alignment", "persona_calibration"],
  language_simplicity: ["language_simplicity", "linguistic_fit"],
  story_structure: ["story_structure", "structural_architecture", "structure"],
  tension_and_stakes: ["tension_and_stakes", "tension", "tension_and_conflict", "stakes"],
  clear_takeaway: ["clear_takeaway", "significance", "significance_check", "takeaway"],
  delivery_control: ["delivery_control", "delivery", "speech_delivery", "speech"],
  idea_structure: ["idea_structure", "integration", "conceptual_integration"],
  connection_logic: ["connection_logic", "bridge_logic"],
  transition_timing: ["transition_timing", "pivot_placement"],
  argument_quality: ["argument_quality", "answers_objection", "reasoning", "rhetorical_integrity"],
  perceived_confidence: ["perceived_confidence"],
};

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
  // Keep one decimal (2.6, 3.0) — whole-number rounding misled users vs overall avg.
  if (n < 0.5 || n > 5.5) return null;
  return Math.min(5, Math.max(1, Math.round(n * 10) / 10));
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

  // One decimal place 1.0–5.0 (same precision as measure cards / overall ring).
  const overallOneDp = Math.min(5, Math.max(1, Math.round(overall * 10) / 10));

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

/** Map activity measures onto the 4 dashboard pillars (best-effort). */
function measuresToPillars(activitySlug, measureScores, fallbackPillars = {}) {
  const get = (...keys) => {
    for (const k of keys) {
      const v = resolveMeasureScore(k, measureScores);
      if (v != null) return v;
    }
    const fbKey = keys[0];
    return Number(fallbackPillars[fbKey]) || 3;
  };
  const slug = String(activitySlug || "");

  if (slug === "think_fast") {
    return {
      executive_score: get("filler_control", "fillers"),
      clarity_score: get("text_structure", "answer_structure", "structure"),
      impact_score: get("text_structure", "answer_structure", "structure"),
      engagement_score: get("response_readiness", "latency"),
    };
  }
  if (slug === "cut_it_in_half") {
    return {
      executive_score: get("paraphrasing"),
      clarity_score: get("message_compression", "compression"),
      impact_score: get("point_first", "time_to_value"),
      engagement_score: get("paraphrasing"),
    };
  }
  if (slug === "debate_me") {
    return {
      executive_score: get("delivery_control", "delivery"),
      clarity_score: get("argument_quality", "reasoning", "answers_objection"),
      impact_score: get("argument_quality", "answers_objection"),
      engagement_score: get("perceived_confidence"),
    };
  }
  if (slug === "one_minute_expert") {
    return {
      executive_score: get("time_control", "time_management"),
      clarity_score: get("content_structure", "information_depth"),
      impact_score: get("opening_impact", "hook"),
      engagement_score: get("time_control", "time_management"),
    };
  }
  if (slug === "explain_it_simply") {
    return {
      executive_score: get("time_control", "time_to_value"),
      clarity_score: get("language_simplicity", "linguistic_fit"),
      impact_score: get("audience_fit"),
      engagement_score: get("opening_impact", "immediate_engagement"),
    };
  }
  if (slug === "storytelling_gym") {
    return {
      executive_score: get("delivery_control", "delivery"),
      clarity_score: get("story_structure", "structure"),
      impact_score: get("clear_takeaway", "significance"),
      engagement_score: get("tension_and_stakes", "tension"),
    };
  }
  if (slug === "connect_the_dots") {
    return {
      executive_score: get("delivery_control", "speech"),
      clarity_score: get("idea_structure", "integration"),
      impact_score: get("connection_logic", "bridge_logic"),
      engagement_score: get("transition_timing", "pivot_placement"),
    };
  }
  // Generic fallback from whatever keys exist
  const vals = Object.values(measureScores)
    .map(parseMeasureScore)
    .filter((v) => v != null);
  const avg = vals.length
    ? Math.round(
        (vals.reduce((a, b) => a + b, 0) / vals.length) * 10
      ) / 10
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
      "Number 1.0–5.0 to one decimal place, or null if not_assessed (poor audio / cannot judge).",
  }));
}

module.exports = {
  ACTIVITY_WEIGHTS,
  getWeights,
  computeActivityScore,
  measuresToPillars,
  measurePromptForActivity,
  parseMeasureScore,
  resolveMeasureScore,
};
