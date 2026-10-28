const ALIASES = {
  voice_profile: {
    male: "male",
    female: "female",
    non_binary: "non_binary",
    non_binary_vocal_alignment: "non_binary",
    // Coach voice ids used in the app → assessment voice buckets
    david: "male",
    marcus: "male",
    sarah: "female",
    elena: "female",
    alex: "non_binary",
  },
  career_stage: {
    early: "early",
    student_early_career: "early",
    mid_level: "mid_level",
    mid_level_professional: "mid_level",
    exec: "exec",
    senior_executive_founder: "exec",
    self_learner: "self_learner",
    general_self_learner: "self_learner",
  },
  career_type: {
    corporate_finance: "corporate_finance",
    tech_product: "tech_product",
    tech_engineering_product: "tech_product",
    sales_marketing: "sales_marketing",
    sales_marketing_creator: "sales_marketing",
    healthcare_edu: "healthcare_edu",
    healthcare_education: "healthcare_edu",
    other: "other",
    general: "general",
  },
  speaking_confidence: {
    not_very: "not_very",
    not_at_all: "not_very",
    slightly: "not_very",
    anxious: "not_very",
    anxious_shaky: "not_very",
    fairly: "fairly",
    confident: "fairly",
    moderate: "fairly",
    moderately_confident: "fairly",
    very: "very",
    high: "very",
    highly_confident: "very",
  },
  primary_roadblock: {
    blank_pressure: "blank_pressure",
    blank_on_spot: "blank_pressure",
    too_long: "too_long",
    too_long_point: "too_long",
    filler_rush: "filler_rush",
    rush_fill_gaps: "filler_rush",
    fast_talking_mumbling: "filler_rush",
    excessive_filler_words: "filler_rush",
    explain_simple: "explain_simple",
    explain_simply: "explain_simple",
    keep_engaged: "keep_engaged",
    switch_off: "keep_engaged",
    monotone_flat_delivery: "keep_engaged",
    lose_confidence: "lose_confidence",
    lose_footing: "lose_confidence",
    accent_barriers_clarity: "accent_clarity",
  },
  primary_goal: {
    authority: "authority",
    exec_presence: "authority",
    executive_presence_authority: "authority",
    calmer_confident: "calmer_confident",
    reduce_freeze: "calmer_confident",
    reduce_anxiety_freeze: "calmer_confident",
    persuasive_arguments: "persuasive_arguments",
    sharp_debate: "persuasive_arguments",
    sharp_arguments_debate: "persuasive_arguments",
    clear_daily: "clear_daily",
    diction_clarity: "clear_daily",
    diction_clarity_stamina: "clear_daily",
    // UI extras on Profile / Assessment (map to nearest supported goal)
    keep_engaged: "persuasive_arguments",
    other: "clear_daily",
  },
  difficulty: {
    beginner: "beginner",
    intermediary: "intermediary",
    intermediate: "intermediary",
    professional: "professional",
    pro: "professional",
    i_dont_know: "i_dont_know",
  },
};

function canonical(group, value) {
  if (value == null || value === "") return null;
  const key = String(value).trim();
  const map = ALIASES[group] || {};
  return map[key] || null;
}

const DRILLS = {
  blank_pressure: ["think_fast", "one_minute_expert", "debate_me"],
  too_long: ["cut_it_in_half", "explain_it_simply", "think_fast"],
  filler_rush: ["debate_me", "storytelling_gym", "think_fast"],
  explain_simple: ["explain_it_simply", "one_minute_expert", "cut_it_in_half"],
  keep_engaged: ["storytelling_gym", "connect_the_dots", "one_minute_expert"],
  lose_confidence: ["debate_me", "think_fast", "connect_the_dots"],
  accent_clarity: ["explain_it_simply", "one_minute_expert", "cut_it_in_half"],
};

const FOCUS = {
  blank_pressure: "Go blank less, land the point sooner.",
  too_long: "Say the point first, then stop.",
  filler_rush: "Slow the rush. Leave the fillers behind.",
  explain_simple: "Make the complex feel obvious.",
  keep_engaged: "Make people stay with you.",
  lose_confidence: "Hold your ground when they push back.",
  accent_clarity: "Be distinct and well paced. Keep your accent.",
};

const TRACK_LABEL = {
  corporate_finance: "Corporate & Finance",
  tech_product: "Tech, Engineering & Product",
  sales_marketing: "Sales & Marketing",
  healthcare_edu: "Healthcare & Education",
  general: "General",
  other: "Other",
  early: "Early career",
  mid_level: "Mid-level",
  exec: "Executive",
  self_learner: "Self-learner",
  male: "Male voice resonance",
  female: "Female voice resonance",
  non_binary: "Custom vocal alignment",
  not_very: "Not very confident",
  fairly: "Fairly confident",
  very: "Very confident",
};

function buildPlan(answers) {
  const roadblock = answers.primaryRoadblock || "blank_pressure";
  const drills = DRILLS[roadblock] || DRILLS.blank_pressure;
  const track = answers.careerType || "general";
  return {
    headline: "Your first month of speaking practice",
    summary:
      "A daily set of drills chosen from your assessment. Skill scores stay separate from streaks and XP. The app scores the recording. This plan only decides what you practise.",
    recommendedTrack: track,
    primaryRoadblock: roadblock,
    focusLine: FOCUS[roadblock] || FOCUS.blank_pressure,
    initialDrills: drills,
    milestones: [
      {
        week: 1,
        title: "Survive the clock",
        focus: "Start speaking, keep a structure, and notice the stall.",
      },
      {
        week: 2,
        title: "Bottom line first",
        focus: "Put the point in the opening seconds.",
      },
      {
        week: 3,
        title: "Presence and pause",
        focus: "Use a short silence instead of a filler.",
      },
      {
        week: 4,
        title: "Pressure",
        focus: "Hold the point when someone pushes back.",
      },
    ],
  };
}

function allowedValues(group) {
  return Object.keys(ALIASES[group]);
}

module.exports = {
  canonical,
  buildPlan,
  allowedValues,
  TRACK_LABEL,
  DRILLS,
};
