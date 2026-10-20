const mongoose = require("mongoose");

/** Per-user, per-calendar-day progress for 10/15-minute plan extras. */
const dailyPlanProgressSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    /** YYYY-MM-DD (UTC date stamp used by daily anchor). */
    date: { type: String, required: true, index: true },
    targetedRetryDone: { type: Boolean, default: false },
    tougherChallengeDone: { type: Boolean, default: false },
  },
  { timestamps: true }
);

dailyPlanProgressSchema.index({ user: 1, date: 1 }, { unique: true });

module.exports = mongoose.model("DailyPlanProgress", dailyPlanProgressSchema);
