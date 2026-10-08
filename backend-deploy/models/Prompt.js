const mongoose = require("mongoose");

const promptSchema = new mongoose.Schema(
  {
    code: { type: String, unique: true, required: true },
    activitySlug: { type: String, required: true, index: true },
    difficulty: {
      type: String,
      enum: ["beginner", "intermediary", "professional"],
      required: true,
    },
    title: { type: String, default: null },
    promptText: { type: String, required: true },
    secondaryText: { type: String, default: null },
    objective: { type: String, required: true },
    exemplarResponse: { type: String, required: true },
    tags: { type: [String], default: [] },
    industries: { type: [String], default: ["general"] },
    durationSeconds: { type: Number, default: 60 },
    prepSeconds: { type: Number, default: 3 },
    learnMoreUrl: { type: String, default: null },
    learnMoreLabel: { type: String, default: null },
  },
  { timestamps: true }
);

module.exports = mongoose.model("Prompt", promptSchema);
