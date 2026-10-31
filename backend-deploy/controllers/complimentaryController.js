const User = require("../models/User");
const Subscription = require("../models/Subscription");
const { success, error } = require("../helpers/response");
const { subscriptionJson } = require("../services/serializers");

/**
 * Admin-only complimentary Pro grants.
 * Auth: header `x-admin-secret` or `Authorization: Bearer <ADMIN_SECRET>`
 * must match process.env.ADMIN_SECRET (or COMPLIMENTARY_ADMIN_SECRET).
 *
 * REVERT: remove this file + routes `/admin/complimentary/*`.
 * Does not change paid choosePlan / IAP paths.
 */

function adminSecretOk(req) {
  const expected = String(
    process.env.ADMIN_SECRET || process.env.COMPLIMENTARY_ADMIN_SECRET || ""
  ).trim();
  if (!expected) return false;
  const header =
    String(req.headers["x-admin-secret"] || "").trim() ||
    String(req.headers.authorization || "")
      .replace(/^Bearer\s+/i, "")
      .trim();
  return header && header === expected;
}

function requireAdmin(req, res) {
  if (adminSecretOk(req)) return true;
  error(res, "Admin secret missing or invalid.", 401);
  return false;
}

/** POST /admin/complimentary/grant  { email, until?, note? } */
const grant = async (req, res) => {
  if (!requireAdmin(req, res)) return;
  try {
    const email = String(req.body.email || "")
      .trim()
      .toLowerCase();
    if (!email || !email.includes("@")) {
      return error(res, "A valid email is required.");
    }

    const untilRaw = req.body.until || req.body.complimentary_until || null;
    let complimentaryUntil = null;
    if (untilRaw) {
      complimentaryUntil = new Date(untilRaw);
      if (Number.isNaN(complimentaryUntil.getTime())) {
        return error(res, "until must be a valid date (ISO string).");
      }
    }

    const note = String(req.body.note || "").trim().slice(0, 200);
    const user = await User.findOne({ email, isDeleted: false });
    if (!user) {
      return error(res, "No Hakkiri account found for that email.", 404);
    }

    const subscription = await Subscription.findOneAndUpdate(
      { user: user._id },
      {
        complimentary: true,
        complimentaryUntil,
        complimentaryNote: note,
        // Keep practise unlocked without inventing a store purchase.
        status: "active",
        tier: "annual_pro",
        priceGbp: 0,
        currentPeriodEnd: complimentaryUntil || null,
      },
      { new: true, upsert: true }
    );

    return success(res, `Complimentary Pro granted to ${email}.`, {
      email,
      user_id: String(user._id),
      subscription: subscriptionJson(subscription),
    });
  } catch (err) {
    console.error("complimentary grant failed:", err.message);
    return error(res, "Could not grant complimentary access.", 500);
  }
};

/** POST /admin/complimentary/revoke  { email } */
const revoke = async (req, res) => {
  if (!requireAdmin(req, res)) return;
  try {
    const email = String(req.body.email || "")
      .trim()
      .toLowerCase();
    if (!email || !email.includes("@")) {
      return error(res, "A valid email is required.");
    }

    const user = await User.findOne({ email, isDeleted: false });
    if (!user) {
      return error(res, "No Hakkiri account found for that email.", 404);
    }

    const subscription = await Subscription.findOneAndUpdate(
      { user: user._id },
      {
        complimentary: false,
        complimentaryUntil: null,
        complimentaryNote: "",
        status: "expired",
        tier: "free_trial",
        priceGbp: 0,
        currentPeriodEnd: null,
      },
      { new: true }
    );

    if (!subscription) {
      return error(res, "No subscription row for that user.", 404);
    }

    return success(res, `Complimentary Pro revoked for ${email}.`, {
      email,
      subscription: subscriptionJson(subscription),
    });
  } catch (err) {
    console.error("complimentary revoke failed:", err.message);
    return error(res, "Could not revoke complimentary access.", 500);
  }
};

module.exports = { grant, revoke };
