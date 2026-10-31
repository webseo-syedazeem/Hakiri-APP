const Subscription = require("../models/Subscription");
const { success, error } = require("../helpers/response");
const { subscriptionJson } = require("../services/serializers");

const YEARLY_TRIAL_DAYS = 7;

const PLANS = {
  monthly_pro: { priceGbp: 9.99, days: 30, label: "£9.99 per month" },
  annual_pro: { priceGbp: 69.99, days: 365, label: "£69.99 per year" },
};

const getSubscription = async (req, res) => {
  const subscription = await Subscription.findOne({ user: req.user._id });
  const json = subscriptionJson(subscription);
  const trialEligible = !(subscription && subscription.yearlyTrialConsumed);
  return success(res, "Subscription.", {
    subscription: json,
    offers: [
      {
        tier: "monthly_pro",
        price_gbp: 9.99,
        label: "£9.99 per month",
        trial_days: 0,
        trial_eligible: false,
      },
      {
        tier: "annual_pro",
        price_gbp: 69.99,
        label: "£69.99 per year",
        trial_days: YEARLY_TRIAL_DAYS,
        trial_eligible: trialEligible,
      },
    ],
  });
};

/**
 * Activate a plan after store purchase / restore.
 * Yearly: first time gets 7-day trialing window (yearlyTrialConsumed).
 * Monthly: charged from day one (active).
 * Complimentary accounts are left alone if already complimentary-active.
 */
const choosePlan = async (req, res) => {
  const tier = req.body.tier;
  const plan = PLANS[tier];
  if (!plan) return error(res, "Choose monthly_pro or annual_pro.");

  const existing = await Subscription.findOne({ user: req.user._id });
  if (existing?.complimentary) {
    const untilOk =
      !existing.complimentaryUntil ||
      new Date(existing.complimentaryUntil) >= new Date();
    if (untilOk) {
      return success(res, "Complimentary Pro already active.", {
        subscription: subscriptionJson(existing),
      });
    }
  }

  const wantTrial =
    tier === "annual_pro" &&
    (req.body.start_trial === true ||
      req.body.start_trial === "true" ||
      req.body.startTrial === true) &&
    !(existing && existing.yearlyTrialConsumed);

  const now = Date.now();
  let status = "active";
  let trialEnd = null;
  let currentPeriodEnd = new Date(now + plan.days * 24 * 60 * 60 * 1000);
  let yearlyTrialConsumed = Boolean(existing?.yearlyTrialConsumed);

  if (wantTrial) {
    status = "trialing";
    trialEnd = new Date(now + YEARLY_TRIAL_DAYS * 24 * 60 * 60 * 1000);
    currentPeriodEnd = trialEnd;
    yearlyTrialConsumed = true;
  }

  const subscription = await Subscription.findOneAndUpdate(
    { user: req.user._id },
    {
      tier,
      status,
      priceGbp: wantTrial ? 0 : plan.priceGbp,
      trialEnd,
      currentPeriodEnd,
      yearlyTrialConsumed,
      // Don't clear complimentary flags here — grant/revoke owns those.
    },
    { new: true, upsert: true }
  );

  const msg = wantTrial
    ? `Yearly plan started with a ${YEARLY_TRIAL_DAYS}-day free trial.`
    : `Plan set to ${plan.label}.`;

  return success(res, msg, {
    subscription: subscriptionJson(subscription),
  });
};

module.exports = { getSubscription, choosePlan };
