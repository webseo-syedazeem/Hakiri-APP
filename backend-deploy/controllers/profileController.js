const Profile = require("../models/Profile");
const Settings = require("../models/Settings");
const User = require("../models/User");
const { success, error } = require("../helpers/response");
const { canonical, buildPlan, TRACK_LABEL } = require("../services/plan");
const { profileJson, planJson, settingsJson } = require("../services/serializers");
const { ASSESSMENT_QUESTIONS, SCORING_PRINCIPLES } = require("../data/catalog");

const questions = async (_req, res) => {
  return success(res, "Assessment questions.", { questions: ASSESSMENT_QUESTIONS });
};

const principles = async (_req, res) => {
  return success(res, "Fair scoring principles. The Flutter app applies these when it scores speech.", {
    principles: SCORING_PRINCIPLES,
    scale: {
      min: 1,
      max: 5,
      labels: {
        1: "Not demonstrated",
        2: "Limited",
        3: "Partly demonstrated",
        4: "Effective",
        5: "Strongly demonstrated",
      },
    },
    pillars: [
      { key: "executive_score", label: "Fluency and presence" },
      { key: "clarity_score", label: "Clarity and articulation" },
      { key: "engagement_score", label: "Engagement and tone" },
      { key: "impact_score", label: "Conciseness and impact" },
    ],
  });
};

function readAnswers(body) {
  const source = body.answers && typeof body.answers === "object" ? { ...body, ...body.answers } : body;
  return {
    voiceProfile: canonical("voice_profile", source.voice_profile || source.voiceProfile || source.gender),
    careerStage: canonical("career_stage", source.career_stage || source.careerStage),
    careerType: canonical("career_type", source.career_type || source.careerType),
    speakingConfidence: canonical(
      "speaking_confidence",
      source.speaking_confidence || source.speakingConfidence || source.confidence
    ),
    primaryRoadblock: canonical(
      "primary_roadblock",
      source.primary_roadblock || source.primaryRoadblock || source.roadblock || source.problem
    ),
    primaryGoal: canonical("primary_goal", source.primary_goal || source.primaryGoal || source.goal),
  };
}

function readFullName(body) {
  const raw = body.name || body.full_name || body.fullName;
  if (raw == null) return "";
  return String(raw).trim();
}

const submitAssessment = async (req, res) => {
  const answers = readAnswers(req.body || {});
  const missing = Object.entries({
    voice_profile: answers.voiceProfile,
    career_stage: answers.careerStage,
    career_type: answers.careerType,
    speaking_confidence: answers.speakingConfidence,
    primary_roadblock: answers.primaryRoadblock,
    primary_goal: answers.primaryGoal,
  })
    .filter(([, value]) => !value)
    .map(([key]) => key);

  if (missing.length) {
    return error(res, `Missing or unknown answers: ${missing.join(", ")}.`);
  }

  const fullName = readFullName(req.body || {});
  if (fullName && fullName.length < 2) return error(res, "Enter your name.");

  const plan = buildPlan(answers);
  const writes = [
    Profile.findOneAndUpdate(
      { user: req.user._id },
      { ...answers, onboardingComplete: true, plan },
      { new: true, upsert: true }
    ),
    Settings.findOneAndUpdate(
      { user: req.user._id },
      {
        industryTrack: answers.careerType,
        voiceProfile: answers.voiceProfile,
        dailyAnchorMinutes: 5,
      },
      { upsert: true }
    ),
  ];
  if (fullName) {
    writes.push(User.updateOne({ _id: req.user._id }, { fullName }));
    req.user.fullName = fullName;
  }

  const [profile] = await Promise.all(writes);

  return success(res, "Assessment saved. Plan is ready.", {
    profile: profileJson(profile),
    full_name: req.user.fullName,
    track_label: TRACK_LABEL[answers.careerType] || answers.careerType,
  });
};

const getProfile = async (req, res) => {
  const profile = await Profile.findOne({ user: req.user._id });
  return success(res, "Profile.", { profile: profileJson(profile) });
};

const updateProfile = async (req, res) => {
  const answers = readAnswers(req.body || {});
  const patch = {};
  for (const [key, value] of Object.entries(answers)) {
    if (value) patch[key] = value;
  }
  const fullName = readFullName(req.body || {});
  if (fullName) {
    await User.updateOne({ _id: req.user._id }, { fullName });
    req.user.fullName = fullName;
  }

  const existing = await Profile.findOne({ user: req.user._id });
  const merged = {
    voiceProfile: patch.voiceProfile || existing?.voiceProfile,
    careerStage: patch.careerStage || existing?.careerStage,
    careerType: patch.careerType || existing?.careerType,
    speakingConfidence: patch.speakingConfidence || existing?.speakingConfidence,
    primaryRoadblock: patch.primaryRoadblock || existing?.primaryRoadblock,
    primaryGoal: patch.primaryGoal || existing?.primaryGoal,
  };
  if (Object.values(merged).every(Boolean)) {
    patch.plan = buildPlan(merged);
    patch.onboardingComplete = true;
  }

  const profile = await Profile.findOneAndUpdate({ user: req.user._id }, patch, {
    new: true,
    upsert: true,
  });
  if (patch.careerType || patch.voiceProfile) {
    await Settings.findOneAndUpdate(
      { user: req.user._id },
      {
        ...(patch.careerType ? { industryTrack: patch.careerType } : {}),
        ...(patch.voiceProfile ? { voiceProfile: patch.voiceProfile } : {}),
      },
      { upsert: true }
    );
  }
  return success(res, "Profile updated.", {
    profile: profileJson(profile),
    full_name: req.user.fullName,
  });
};

const getPlan = async (req, res) => {
  const profile = await Profile.findOne({ user: req.user._id });
  if (!profile?.onboardingComplete) return error(res, "Complete the assessment first.", 404);
  return success(res, "Personalised plan.", { plan: planJson(profile.plan) });
};

const updatePlan = async (req, res) => {
  const profile = await Profile.findOne({ user: req.user._id });
  if (!profile?.plan) return error(res, "Complete the assessment first.", 404);

  const extra = req.body.additional_drills || req.body.initial_drills;
  if (Array.isArray(extra)) {
    const Activity = require("../models/Activity");
    const known = new Set((await Activity.find().select("slug")).map((a) => a.slug));
    const merged = [...profile.plan.initialDrills];
    for (const slug of extra) {
      if (!known.has(slug)) return error(res, `Unknown activity: ${slug}`);
      if (!merged.includes(slug)) merged.push(slug);
    }
    profile.plan.initialDrills = merged;
  }
  if (typeof req.body.headline === "string") profile.plan.headline = req.body.headline;
  if (typeof req.body.summary === "string") profile.plan.summary = req.body.summary;
  if (typeof req.body.focus_line === "string") profile.plan.focusLine = req.body.focus_line;
  profile.markModified("plan");
  await profile.save();
  return success(res, "Plan updated.", { plan: planJson(profile.plan) });
};

const getSettings = async (req, res) => {
  const settings = await Settings.findOne({ user: req.user._id });
  return success(res, "Settings.", { settings: settingsJson(settings) });
};

const updateSettings = async (req, res) => {
  const patch = {};
  if (req.body.industry_track) {
    const track = canonical("career_type", req.body.industry_track);
    if (!track) return error(res, "Unknown industry track.");
    patch.industryTrack = track;
  }
  if (req.body.voice_profile) {
    const voice = canonical("voice_profile", req.body.voice_profile);
    if (!voice) return error(res, "Unknown voice profile.");
    patch.voiceProfile = voice;
  }
  if (req.body.daily_anchor_minutes != null) {
    const minutes = Number(req.body.daily_anchor_minutes);
    if (![5, 10, 15].includes(minutes)) return error(res, "Daily anchor must be 5, 10, or 15 minutes.");
    patch.dailyAnchorMinutes = minutes;
  }
  if (req.body.audio_privacy) patch.audioPrivacy = String(req.body.audio_privacy);

  const settings = await Settings.findOneAndUpdate({ user: req.user._id }, patch, { new: true, upsert: true });
  if (patch.industryTrack || patch.voiceProfile) {
    await Profile.findOneAndUpdate(
      { user: req.user._id },
      {
        ...(patch.industryTrack ? { careerType: patch.industryTrack } : {}),
        ...(patch.voiceProfile ? { voiceProfile: patch.voiceProfile } : {}),
      }
    );
  }
  return success(res, "Settings updated.", { settings: settingsJson(settings) });
};

module.exports = {
  questions,
  principles,
  submitAssessment,
  getProfile,
  updateProfile,
  getPlan,
  updatePlan,
  getSettings,
  updateSettings,
};
