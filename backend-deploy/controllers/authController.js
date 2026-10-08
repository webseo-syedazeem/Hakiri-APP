const jwt = require("jsonwebtoken");
const User = require("../models/User");
const Profile = require("../models/Profile");
const Subscription = require("../models/Subscription");
const Streak = require("../models/Streak");
const Settings = require("../models/Settings");
const { success, error } = require("../helpers/response");
const { userJson, profileJson, subscriptionJson, streakJson, settingsJson } = require("../services/serializers");

const generateToken = (id) => jwt.sign({ id }, process.env.JWT_SECRET, { expiresIn: "30d" });

async function createAccountShell(userId) {
  const trialEnd = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
  await Promise.all([
    Profile.create({ user: userId }),
    Settings.create({ user: userId, dailyAnchorMinutes: 5, audioPrivacy: "encrypted_on_device" }),
    Subscription.create({
      user: userId,
      tier: "free_trial",
      status: "trialing",
      priceGbp: 0,
      trialEnd,
      currentPeriodEnd: trialEnd,
    }),
    Streak.create({ user: userId }),
  ]);
}

const register = async (req, res) => {
  try {
    const fullName = String(req.body.full_name || req.body.fullName || "").trim();
    const email = String(req.body.email || "").trim().toLowerCase();
    const password = String(req.body.password || "");

    if (!fullName) return error(res, "Full name is required.");
    if (!email || !email.includes("@")) return error(res, "A valid email is required.");
    if (password.length < 6) return error(res, "Password must be at least 6 characters.");

    const existing = await User.findOne({ email, isDeleted: false });
    if (existing) return error(res, "An account with this email already exists.", 400);
    await User.deleteMany({ email, isDeleted: true });

    const user = await User.create({ fullName, email, password });
    await createAccountShell(user._id);

    const [profile, subscription, streak, settings] = await Promise.all([
      Profile.findOne({ user: user._id }),
      Subscription.findOne({ user: user._id }),
      Streak.findOne({ user: user._id }),
      Settings.findOne({ user: user._id }),
    ]);

    return success(
      res,
      "Account created. Complete the assessment next.",
      {
        token: generateToken(user._id),
        user: userJson(user),
        profile: profileJson(profile),
        subscription: subscriptionJson(subscription),
        streak: streakJson(streak),
        settings: settingsJson(settings),
      },
      201
    );
  } catch (err) {
    console.error(err);
    return error(res, "Could not create the account.", 500);
  }
};

const login = async (req, res) => {
  try {
    const email = String(req.body.email || "").trim().toLowerCase();
    const password = String(req.body.password || "");
    if (!email || !password) return error(res, "Email and password are required.");

    const user = await User.findOne({ email, isDeleted: false });
    if (!user || !(await user.matchPassword(password))) {
      return error(res, "Email or password is incorrect.", 401);
    }

    const [profile, subscription, streak, settings] = await Promise.all([
      Profile.findOne({ user: user._id }),
      Subscription.findOne({ user: user._id }),
      Streak.findOne({ user: user._id }),
      Settings.findOne({ user: user._id }),
    ]);

    return success(res, "Logged in.", {
      token: generateToken(user._id),
      user: userJson(user),
      profile: profileJson(profile),
      subscription: subscriptionJson(subscription),
      streak: streakJson(streak),
      settings: settingsJson(settings),
    });
  } catch (err) {
    console.error(err);
    return error(res, "Could not log in.", 500);
  }
};

const me = async (req, res) => {
  const [profile, subscription, streak, settings] = await Promise.all([
    Profile.findOne({ user: req.user._id }),
    Subscription.findOne({ user: req.user._id }),
    Streak.findOne({ user: req.user._id }),
    Settings.findOne({ user: req.user._id }),
  ]);
  return success(res, "Current member.", {
    user: userJson(req.user),
    profile: profileJson(profile),
    subscription: subscriptionJson(subscription),
    streak: streakJson(streak),
    settings: settingsJson(settings),
  });
};

module.exports = { register, login, me };
