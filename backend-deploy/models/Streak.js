const mongoose = require("mongoose");

const streakSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: "User", unique: true, required: true },
    currentStreak: { type: Number, default: 0 },
    longestStreak: { type: Number, default: 0 },
    streakFreezeCount: { type: Number, default: 1 },
    totalXp: { type: Number, default: 0 },
    completedSessions: { type: Number, default: 0 },
    lastPracticeDate: { type: String, default: null },
  },
  { timestamps: true }
);

module.exports = mongoose.model("Streak", streakSchema);
