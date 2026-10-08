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
  },
  { timestamps: true }
);

module.exports = mongoose.model("Subscription", subscriptionSchema);
