const mongoose = require("mongoose");

const subscriptionSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: "User", unique: true, required: true },
    tier: {
      type: String,
      enum: ["free_trial", "monthly_pro", "annual_pro"],
      default: "free_trial",
    },
    status: {
      type: String,
      enum: ["trialing", "active", "expired", "canceled"],
      default: "trialing",
    },
    priceGbp: { type: Number, default: 0 },
    trialEnd: Date,
    currentPeriodEnd: Date,
    /**
     * Complimentary Pro (testers / partners / App Review).
     * REVERT: drop these three fields + related serializer/admin route if unused.
     * Paid IAP / choosePlan logic is unchanged.
     */
    complimentary: { type: Boolean, default: false, index: true },
    complimentaryUntil: { type: Date, default: null },
    complimentaryNote: { type: String, default: "", trim: true },
    /** One 7-day intro trial per account (yearly plan only). */
    yearlyTrialConsumed: { type: Boolean, default: false },
  },
  { timestamps: true }
);

module.exports = mongoose.model("Subscription", subscriptionSchema);
