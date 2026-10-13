const User = require("../models/User");
const Settings = require("../models/Settings");
const PracticeSession = require("../models/PracticeSession");
const { success, error } = require("../helpers/response");
const { isFirebaseConfigured, sendToTokens } = require("../config/firebase");

function startOfUtcDay(date = new Date()) {
  return new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()));
}

const registerToken = async (req, res) => {
  const token = String(req.body.token || req.body.fcm_token || "").trim();
  const platform = String(req.body.platform || "").trim().toLowerCase();
  if (!token || token.length < 20) {
    return error(res, "A valid FCM device token is required.");
  }

  // Respect in-app Reminder toggle — do not re-register while opted out.
  const settings = await Settings.findOne({ user: req.user._id });
  if (settings && settings.remindersEnabled === false) {
    return success(res, "Reminders are off; token not saved.", {
      token_saved: false,
      reminders_enabled: false,
    });
  }

  const user = await User.findById(req.user._id);
  if (!user) return error(res, "User not found.", 404);

  const tokens = Array.isArray(user.fcmTokens) ? user.fcmTokens : [];
  if (!tokens.includes(token)) {
    tokens.push(token);
    // Keep the newest handful of devices.
    user.fcmTokens = tokens.slice(-8);
  }
  if (platform === "ios" || platform === "android") {
    user.fcmPlatform = platform;
  }
  user.fcmUpdatedAt = new Date();
  await user.save();

  return success(res, "Device token saved.", {
    token_saved: true,
    token_count: user.fcmTokens.length,
  });
};

/** Clear FCM tokens (Reminder off or OS notification permission revoked). */
const clearTokens = async (req, res) => {
  const user = await User.findById(req.user._id);
  if (!user) return error(res, "User not found.", 404);
  user.fcmTokens = [];
  user.fcmUpdatedAt = new Date();
  await user.save();
  return success(res, "Device tokens cleared.", { token_count: 0 });
};

/**
 * Daily reminder for users who set e.g. 5/10/15 min practice
 * but have not completed that many minutes today.
 * Protect with CRON_SECRET (Vercel Cron / external scheduler). No Cloud Functions.
 */
const sendDailyReminders = async (req, res) => {
  try {
    if (!isFirebaseConfigured()) {
      return error(res, "Firebase Admin is not configured on the server.", 503);
    }

    const secret = String(process.env.CRON_SECRET || "").trim();
    const auth = String(req.headers.authorization || "");
    const bearer = auth.toLowerCase().startsWith("bearer ")
      ? auth.slice(7).trim()
      : "";
    const header =
      String(req.headers["x-cron-secret"] || "").trim() ||
      bearer ||
      String(req.query.secret || "").trim();
    if (secret && header !== secret) {
      return error(res, "Unauthorized cron call.", 401);
    }

    const dayStart = startOfUtcDay();
    const users = await User.find({
      isDeleted: false,
      fcmTokens: { $exists: true, $ne: [] },
    }).select("_id fullName fcmTokens");

    let checked = 0;
    let sent = 0;
    let skippedComplete = 0;
    let skippedNoGoal = 0;
    let skippedOptOut = 0;
    const invalidAll = [];

    for (const user of users) {
      checked += 1;
      const settings = await Settings.findOne({ user: user._id });
      // Profile Reminder toggle (or OS-off sync that cleared preference).
      if (settings && settings.remindersEnabled === false) {
        skippedOptOut += 1;
        continue;
      }
      const goalMinutes = Number(settings?.dailyAnchorMinutes || 5);
      if (![5, 10, 15].includes(goalMinutes)) {
        skippedNoGoal += 1;
        continue;
      }

      const sessions = await PracticeSession.find({
        user: user._id,
        createdAt: { $gte: dayStart },
      }).select("durationSeconds");

      const practicedSeconds = sessions.reduce(
        (sum, row) => sum + (Number(row.durationSeconds) || 0),
        0
      );
      const practicedMinutes = Math.floor(practicedSeconds / 60);
      if (practicedMinutes >= goalMinutes) {
        skippedComplete += 1;
        continue;
      }

      const remaining = Math.max(goalMinutes - practicedMinutes, 1);
      const firstName = String(user.fullName || "there").split(/\s+/)[0];
      const result = await sendToTokens({
        tokens: user.fcmTokens,
        title: "Hakkiri daily practice",
        body:
          practicedMinutes <= 0
            ? `Hey ${firstName}, your ${goalMinutes}-minute practice is waiting.`
            : `Hey ${firstName}, ${remaining} min left to finish today's ${goalMinutes}-minute goal.`,
        data: {
          type: "daily_practice",
          goal_minutes: String(goalMinutes),
          practiced_minutes: String(practicedMinutes),
        },
      });

      sent += result.successCount;
      if (result.invalidTokens.length) {
        invalidAll.push(...result.invalidTokens);
        user.fcmTokens = user.fcmTokens.filter((t) => !result.invalidTokens.includes(t));
        await user.save();
      }
    }

    return success(res, "Daily FCM reminders processed.", {
      checked,
      sent,
      skipped_complete: skippedComplete,
      skipped_no_goal: skippedNoGoal,
      skipped_opt_out: skippedOptOut,
      pruned_tokens: invalidAll.length,
      day_start_utc: dayStart.toISOString(),
    });
  } catch (err) {
    console.error("sendDailyReminders failed:", err.message);
    return error(res, err.message || "Could not send reminders.", err.statusCode || 502);
  }
};

module.exports = { registerToken, clearTokens, sendDailyReminders };
