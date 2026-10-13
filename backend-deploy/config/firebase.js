const fs = require("fs");
const path = require("path");

let admin = null;
let app = null;

function loadServiceAccount() {
  const raw = String(process.env.FIREBASE_SERVICE_ACCOUNT_JSON || "").trim();
  if (raw) {
    return JSON.parse(raw);
  }
  const filePath = String(
    process.env.FIREBASE_SERVICE_ACCOUNT_PATH ||
      path.join(__dirname, "..", "secrets", "firebase-adminsdk.json")
  ).trim();
  if (fs.existsSync(filePath)) {
    return JSON.parse(fs.readFileSync(filePath, "utf8"));
  }
  return null;
}

function isFirebaseConfigured() {
  try {
    return Boolean(loadServiceAccount());
  } catch (_) {
    return false;
  }
}

function getAdmin() {
  if (app) return admin;
  const serviceAccount = loadServiceAccount();
  if (!serviceAccount) {
    const err = new Error(
      "Firebase Admin is not configured. Set FIREBASE_SERVICE_ACCOUNT_JSON or secrets/firebase-adminsdk.json."
    );
    err.statusCode = 503;
    throw err;
  }
  admin = require("firebase-admin");
  if (!admin.apps.length) {
    app = admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
  } else {
    app = admin.app();
  }
  return admin;
}

/**
 * Send one FCM notification to a list of device tokens.
 * Invalid tokens are returned so the caller can prune them.
 */
async function sendToTokens({ tokens, title, body, data = {} }) {
  const list = [...new Set((tokens || []).map((t) => String(t || "").trim()).filter(Boolean))];
  if (!list.length) {
    return { successCount: 0, failureCount: 0, invalidTokens: [] };
  }

  const fb = getAdmin();
  const response = await fb.messaging().sendEachForMulticast({
    tokens: list,
    notification: { title, body },
    data: Object.fromEntries(
      Object.entries(data).map(([k, v]) => [k, String(v ?? "")])
    ),
    android: {
      priority: "high",
      notification: { channelId: "hakkiri_daily", sound: "default" },
    },
    apns: {
      payload: {
        aps: { sound: "default", badge: 1 },
      },
    },
  });

  const invalidTokens = [];
  response.responses.forEach((res, index) => {
    if (res.success) return;
    const code = res.error?.code || "";
    if (
      code.includes("registration-token-not-registered") ||
      code.includes("invalid-registration-token") ||
      code.includes("invalid-argument")
    ) {
      invalidTokens.push(list[index]);
    }
  });

  return {
    successCount: response.successCount,
    failureCount: response.failureCount,
    invalidTokens,
  };
}

module.exports = {
  isFirebaseConfigured,
  getAdmin,
  sendToTokens,
};
