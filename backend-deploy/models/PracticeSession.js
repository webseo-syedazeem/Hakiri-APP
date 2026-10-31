const mongoose = require("mongoose");

const practiceSessionSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true, index: true },
    activitySlug: { type: String, required: true },
    activityName: { type: String, required: true },
    promptCode: { type: String, default: null },
    promptTitle: { type: String, default: "" },
    promptText: { type: String, default: "" },
    difficulty: { type: String, default: "beginner" },
    transcript: { type: String, default: "" },
    durationSeconds: { type: Number, default: 0 },
    isCoachedRetry: { type: Boolean, default: false },
    withholdJudgement: { type: Boolean, default: false },
    // single = one-shot drill; back_and_forth = voice practice / debate conversation
    conversationMode: {
      type: String,
      enum: ["single", "back_and_forth"],
      default: "single",
      index: true,
    },
    conversationTurns: {
      type: [
        {
          role: { type: String, enum: ["user", "coach"], default: "user" },
          text: { type: String, default: "" },
        },
      ],
      default: [],
    },
    feedback: { type: mongoose.Schema.Types.Mixed, required: true },
  },
  { timestamps: true }
);

module.exports = mongoose.model("PracticeSession", practiceSessionSchema);
