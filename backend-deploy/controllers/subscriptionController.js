const Subscription = require("../models/Subscription");
const { success, error } = require("../helpers/response");
const { subscriptionJson } = require("../services/serializers");

const PLANS = {
  monthly_pro: { priceGbp: 9.99, days: 30, label: "£9.99 per month" },
  annual_pro: { priceGbp: 69.99, days: 365, label: "£69.99 per year" },
};

const getSubscription = async (req, res) => {
  const subscription = await Subscription.findOne({ user: req.user._id });
  return success(res, "Subscription.", {
    subscription: subscriptionJson(subscription),
    offers: [
      { tier: "monthly_pro", price_gbp: 9.99, label: "£9.99 per month" },
      { tier: "annual_pro", price_gbp: 69.99, label: "£69.99 per year" },
    ],
  });
};

const choosePlan = async (req, res) => {
  const tier = req.body.tier;
  const plan = PLANS[tier];
  if (!plan) return error(res, "Choose monthly_pro or annual_pro.");

  const periodEnd = new Date(Date.now() + plan.days * 24 * 60 * 60 * 1000);
  const subscription = await Subscription.findOneAndUpdate(
    { user: req.user._id },
    {
      tier,
      status: "active",
      priceGbp: plan.priceGbp,
      currentPeriodEnd: periodEnd,
    },
    { new: true, upsert: true }
  );

  return success(res, `Plan set to ${plan.label}. Payment capture is not part of this API yet.`, {
    subscription: subscriptionJson(subscription),
  });
};

module.exports = { getSubscription, choosePlan };
