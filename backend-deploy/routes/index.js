const express = require("express");
const { verifyJWT } = require("../middleware/authMiddleware");
const auth = require("../controllers/authController");
const profile = require("../controllers/profileController");
const catalog = require("../controllers/catalogController");
const session = require("../controllers/sessionController");
const challenge = require("../controllers/challengeController");
const subscription = require("../controllers/subscriptionController");
const ai = require("../controllers/aiController");
const bootstrap = require("../controllers/bootstrapController");
const push = require("../controllers/pushController");

const router = express.Router();

router.post("/auth/register", auth.register);
router.post("/auth/login", auth.login);
router.post("/auth/google", auth.googleAuth);
router.post("/auth/apple", auth.appleAuth);
router.get("/auth/me", verifyJWT, auth.me);
router.get("/bootstrap", verifyJWT, bootstrap.bootstrap);
router.get("/ai/status", ai.status);
router.post("/ai/live-token", verifyJWT, ai.liveToken);
router.post("/ai/analyze-speech", verifyJWT, ai.analyzeSpeech);

// FCM device token (app start / after login). No Cloud Functions.
router.post("/device-token", verifyJWT, push.registerToken);
router.delete("/device-token", verifyJWT, push.clearTokens);
// Daily incomplete-practice reminders — call via Vercel Cron / scheduler.
router.get("/cron/daily-reminders", push.sendDailyReminders);
router.post("/cron/daily-reminders", push.sendDailyReminders);

router.get("/assessment/questions", profile.questions);
router.get("/scoring-principles", profile.principles);
router.post("/assessment", verifyJWT, profile.submitAssessment);
router.get("/profile", verifyJWT, profile.getProfile);
router.put("/profile", verifyJWT, profile.updateProfile);
router.get("/plan", verifyJWT, profile.getPlan);
router.put("/plan", verifyJWT, profile.updatePlan);
router.get("/settings", verifyJWT, profile.getSettings);
router.put("/settings", verifyJWT, profile.updateSettings);

router.get("/activities", catalog.listActivities);
router.get("/activities/:slug", catalog.getActivity);
router.get("/prompts", catalog.listPrompts);
router.get("/prompts/next", verifyJWT, catalog.nextPrompt);
router.get("/prompts/:id", catalog.getPrompt);
router.get("/daily-anchor", verifyJWT, catalog.dailyAnchor);

router.post("/sessions", verifyJWT, session.createSession);
router.get("/sessions", verifyJWT, session.listSessions);
router.get("/sessions/:id", verifyJWT, session.getSession);
router.delete("/sessions/:id", verifyJWT, session.deleteSession);
router.get("/dashboard", verifyJWT, session.dashboard);

router.get("/challenges", verifyJWT, challenge.listChallenges);
router.post("/challenges/:slug/join", verifyJWT, challenge.joinChallenge);
router.post("/streaks/freeze", verifyJWT, challenge.freezeStreak);

router.get("/subscription", verifyJWT, subscription.getSubscription);
router.post("/subscription", verifyJWT, subscription.choosePlan);

module.exports = router;
