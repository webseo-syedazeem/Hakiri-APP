const crypto = require("crypto");
const jwt = require("jsonwebtoken");
const User = require("../models/User");
const Profile = require("../models/Profile");
const Subscription = require("../models/Subscription");
const Streak = require("../models/Streak");
const Settings = require("../models/Settings");
const PracticeSession = require("../models/PracticeSession");
const Reflection = require("../models/Reflection");
const DailyPlanProgress = require("../models/DailyPlanProgress");
const ChallengeProgress = require("../models/ChallengeProgress");
const { success, error } = require("../helpers/response");
const { userJson, profileJson, subscriptionJson, streakJson, settingsJson } = require("../services/serializers");

const generateToken = (id) => jwt.sign({ id }, process.env.JWT_SECRET, { expiresIn: "30d" });

/** Native iOS aud = bundle id. Optional Services ID via env for Android/web. */
const APPLE_AUDIENCES = [
  "com.hakkiri.app",
  ...(process.env.APPLE_CLIENT_IDS
    ? String(process.env.APPLE_CLIENT_IDS)
        .split(",")
        .map((s) => s.trim())
        .filter(Boolean)
    : []),
];

let _appleKeysCache = { fetchedAt: 0, keys: [] };

async function getApplePublicKey(kid) {
  const fresh = Date.now() - _appleKeysCache.fetchedAt < 60 * 60 * 1000;
  if (!fresh || !_appleKeysCache.keys.length) {
    const res = await fetch("https://appleid.apple.com/auth/keys");
    const data = await res.json();
    if (!res.ok || !Array.isArray(data.keys)) {
      throw new Error("Could not load Apple public keys");
    }
    _appleKeysCache = { fetchedAt: Date.now(), keys: data.keys };
  }
  const jwk = _appleKeysCache.keys.find((k) => k.kid === kid);
  if (!jwk) throw new Error("Apple signing key not found");
  return crypto.createPublicKey({ key: jwk, format: "jwk" });
}

async function verifyAppleIdToken(idToken) {
  const decoded = jwt.decode(idToken, { complete: true });
  if (!decoded?.header?.kid || !decoded.payload) {
    throw new Error("Invalid Apple identity token");
  }
  const key = await getApplePublicKey(decoded.header.kid);
  const payload = jwt.verify(idToken, key, {
    algorithms: ["RS256"],
    issuer: "https://appleid.apple.com",
  });
  const aud = String(payload.aud || "");
  if (!APPLE_AUDIENCES.includes(aud)) {
    throw new Error(`Unexpected Apple token audience: ${aud}`);
  }
  const appleId = String(payload.sub || "").trim();
  if (!appleId) throw new Error("Apple account id is missing");

  const email = String(payload.email || "")
    .trim()
    .toLowerCase();
  return {
    appleId,
    email: email || `apple_${appleId}@privaterelay.appleid.com`,
    emailVerified: payload.email_verified === true || payload.email_verified === "true",
    fullName: "",
  };
}

/** Web OAuth client from Firebase google-services.json (serverClientId). */
const GOOGLE_ALLOWED_CLIENT_IDS = [
  "536954543355-0gacrbhba0pinid2v15n5f9b8t18apfv.apps.googleusercontent.com",
  ...(process.env.GOOGLE_OAUTH_CLIENT_IDS
    ? String(process.env.GOOGLE_OAUTH_CLIENT_IDS)
        .split(",")
        .map((s) => s.trim())
        .filter(Boolean)
    : []),
];

async function verifyGoogleIdToken(idToken) {
  const url = `https://oauth2.googleapis.com/tokeninfo?id_token=${encodeURIComponent(idToken)}`;
  const res = await fetch(url);
  const data = await res.json();
  if (!res.ok || data.error) {
    throw new Error(data.error_description || data.error || "Invalid Google token");
  }

  const audienceOk =
    GOOGLE_ALLOWED_CLIENT_IDS.includes(data.aud) ||
    GOOGLE_ALLOWED_CLIENT_IDS.includes(data.azp);
  if (!audienceOk) {
    throw new Error("Unexpected Google token audience");
  }

  const email = String(data.email || "")
    .trim()
    .toLowerCase();
  if (!email) {
    throw new Error("Google account has no email");
  }

  const verified = data.email_verified === true || data.email_verified === "true";
  if (!verified) {
    throw new Error("Google email is not verified");
  }

  return {
    googleId: String(data.sub || ""),
    email,
    fullName: String(data.name || email.split("@")[0] || "Hakkiri Member").trim(),
    picture: String(data.picture || ""),
  };
}

async function loadAuthBundle(user) {
  const [profile, subscription, streak, settings] = await Promise.all([
    Profile.findOne({ user: user._id }),
    Subscription.findOne({ user: user._id }),
    Streak.findOne({ user: user._id }),
    Settings.findOne({ user: user._id }),
  ]);
  return {
    token: generateToken(user._id),
    user: userJson(user),
    profile: profileJson(profile),
    subscription: subscriptionJson(subscription),
    streak: streakJson(streak),
    settings: settingsJson(settings),
  };
}

async function createAccountShell(userId) {
  // No free trial — practise unlocks only after a paid monthly/yearly IAP.
  const [profile, settings, subscription, streak] = await Promise.all([
    Profile.create({ user: userId }),
    Settings.create({ user: userId, dailyAnchorMinutes: 5, audioPrivacy: "encrypted_on_device" }),
    Subscription.create({
      user: userId,
      tier: "free_trial",
      status: "expired",
      priceGbp: 0,
      trialEnd: null,
      currentPeriodEnd: null,
    }),
    Streak.create({ user: userId }),
  ]);
  return { profile, settings, subscription, streak };
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
    const shell = await createAccountShell(user._id);

    return success(
      res,
      "Account created. Complete the assessment next.",
      {
        token: generateToken(user._id),
        user: userJson(user),
        profile: profileJson(shell.profile),
        subscription: subscriptionJson(shell.subscription),
        streak: streakJson(shell.streak),
        settings: settingsJson(shell.settings),
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

    return success(res, "Logged in.", await loadAuthBundle(user));
  } catch (err) {
    console.error(err);
    return error(res, "Could not log in.", 500);
  }
};

const googleAuth = async (req, res) => {
  try {
    const idToken = String(req.body.id_token || req.body.idToken || "").trim();
    if (!idToken) return error(res, "Google ID token is required.");

    let googleUser;
    try {
      googleUser = await verifyGoogleIdToken(idToken);
    } catch (err) {
      console.error("Google token verify failed:", err.message);
      return error(res, "Could not verify Google sign-in.", 401);
    }

    if (!googleUser.googleId) {
      return error(res, "Google account id is missing.", 400);
    }

    let user = await User.findOne({
      $or: [
        { googleId: googleUser.googleId, isDeleted: false },
        { email: googleUser.email, isDeleted: false },
      ],
    });

    let created = false;
    if (!user) {
      await User.deleteMany({ email: googleUser.email, isDeleted: true });
      user = await User.create({
        fullName: googleUser.fullName,
        email: googleUser.email,
        googleId: googleUser.googleId,
        authProvider: "google",
        avatarUrl: googleUser.picture || "",
      });
      await createAccountShell(user._id);
      created = true;
    } else {
      let dirty = false;
      if (!user.googleId) {
        user.googleId = googleUser.googleId;
        dirty = true;
      }
      if (user.authProvider !== "google" && !user.password) {
        user.authProvider = "google";
        dirty = true;
      }
      if (googleUser.picture && user.avatarUrl !== googleUser.picture) {
        user.avatarUrl = googleUser.picture;
        dirty = true;
      }
      if (googleUser.fullName && (!user.fullName || user.fullName.length < 2)) {
        user.fullName = googleUser.fullName;
        dirty = true;
      }
      if (dirty) await user.save();
    }

    const bundle = await loadAuthBundle(user);
    // API source of truth for client routing (Get started → Google).
    const onboardingComplete = Boolean(bundle.profile?.onboarding_complete);
    const needsOnboarding = created || !onboardingComplete;
    return success(
      res,
      created ? "Account created with Google." : "Logged in with Google.",
      {
        ...bundle,
        created,
        onboarding_complete: onboardingComplete,
        needs_onboarding: needsOnboarding,
      },
      created ? 201 : 200
    );
  } catch (err) {
    console.error(err);
    return error(res, "Could not complete Google sign-in.", 500);
  }
};

const appleAuth = async (req, res) => {
  try {
    const idToken = String(req.body.id_token || req.body.idToken || "").trim();
    const fullNameHint = String(req.body.full_name || req.body.fullName || "").trim();
    if (!idToken) return error(res, "Apple ID token is required.");

    let appleUser;
    try {
      appleUser = await verifyAppleIdToken(idToken);
    } catch (err) {
      console.error("Apple token verify failed:", err.message);
      return error(res, "Could not verify Apple sign-in.", 401);
    }

    if (fullNameHint.length >= 2) {
      appleUser.fullName = fullNameHint;
    }

    let user = await User.findOne({
      $or: [
        { appleId: appleUser.appleId, isDeleted: false },
        { email: appleUser.email, isDeleted: false },
      ],
    });

    let created = false;
    if (!user) {
      await User.deleteMany({ email: appleUser.email, isDeleted: true });
      user = await User.create({
        fullName: appleUser.fullName || appleUser.email.split("@")[0] || "Hakkiri member",
        email: appleUser.email,
        appleId: appleUser.appleId,
        authProvider: "apple",
      });
      await createAccountShell(user._id);
      created = true;
    } else {
      let dirty = false;
      if (!user.appleId) {
        user.appleId = appleUser.appleId;
        dirty = true;
      }
      if (user.authProvider !== "apple" && !user.password) {
        user.authProvider = "apple";
        dirty = true;
      }
      if (appleUser.fullName && (!user.fullName || user.fullName.length < 2)) {
        user.fullName = appleUser.fullName;
        dirty = true;
      }
      if (dirty) await user.save();
    }

    const bundle = await loadAuthBundle(user);
    const onboardingComplete = Boolean(bundle.profile?.onboarding_complete);
    const needsOnboarding = created || !onboardingComplete;
    return success(
      res,
      created ? "Account created with Apple." : "Logged in with Apple.",
      {
        ...bundle,
        created,
        onboarding_complete: onboardingComplete,
        needs_onboarding: needsOnboarding,
      },
      created ? 201 : 200
    );
  } catch (err) {
    console.error(err);
    return error(res, "Could not complete Apple sign-in.", 500);
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

const deleteAccount = async (req, res) => {
  try {
    const userId = req.user._id;
    await Promise.all([
      User.findByIdAndDelete(userId),
      Profile.deleteMany({ user: userId }),
      Streak.deleteMany({ user: userId }),
      Settings.deleteMany({ user: userId }),
      Subscription.deleteMany({ user: userId }),
      PracticeSession.deleteMany({ user: userId }),
      Reflection.deleteMany({ user: userId }),
      DailyPlanProgress.deleteMany({ user: userId }),
      ChallengeProgress.deleteMany({ user: userId }),
    ]);
    return success(res, "Account and all associated data permanently deleted.");
  } catch (err) {
    console.error("Delete account error:", err);
    return error(res, "Could not delete account. Please try again.", 500);
  }
};

module.exports = { register, login, googleAuth, appleAuth, me, deleteAccount };
