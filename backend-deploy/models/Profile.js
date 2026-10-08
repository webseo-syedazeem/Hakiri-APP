const mongoose = require("mongoose");

const milestoneSchema = new mongoose.Schema(
  {
    week: Number,
    title: String,
    focus: String,
  },
  { _id: false }
);

const profileSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: "User", unique: true, required: true },
    voiceProfile: { type: String, default: null },
    careerStage: { type: String, default: null },
    careerType: { type: String, default: null },
    speakingConfidence: { type: String, default: null },
    primaryRoadblock: { type: String, default: null },
    primaryGoal: { type: String, default: null },
    onboardingComplete: { type: Boolean, default: false },
    plan: {
      headline: String,
      summary: String,
      recommendedTrack: String,
      primaryRoadblock: String,
      focusLine: String,
      initialDrills: { type: [String], default: [] },
      milestones: { type: [milestoneSchema], default: [] },
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model("Profile", profileSchema);
