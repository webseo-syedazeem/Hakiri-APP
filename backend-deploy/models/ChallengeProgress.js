const mongoose = require("mongoose");

const challengeProgressSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
    slug: { type: String, required: true },
    completedCount: { type: Number, default: 0 },
    countedDates: { type: [String], default: [] },
    joined: { type: Boolean, default: true },
  },
  { timestamps: true }
);

challengeProgressSchema.index({ user: 1, slug: 1 }, { unique: true });

module.exports = mongoose.model("ChallengeProgress", challengeProgressSchema);
