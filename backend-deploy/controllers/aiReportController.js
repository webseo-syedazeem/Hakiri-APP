const AiContentReport = require("../models/AiContentReport");
const { success, error } = require("../helpers/response");

const ALLOWED_TYPES = new Set([
  "suggested_answer",
  "coaching_feedback",
  "debate_pushback",
  "other",
]);
const ALLOWED_REASONS = new Set([
  "inaccurate",
  "offensive",
  "harmful",
  "spam",
  "other",
]);

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

/** Fixed admin login for the AI reports web page (overridable via env). */
function adminLoginOk(req) {
  const expectedEmail = String(
    process.env.ADMIN_EMAIL || "admin@gmail.com"
  )
    .trim()
    .toLowerCase();
  const expectedPassword = String(
    process.env.ADMIN_PASSWORD || "admin123@"
  );
  const email = String(req.headers["x-admin-email"] || "")
    .trim()
    .toLowerCase();
  const password = String(req.headers["x-admin-password"] || "");
  return (
    email &&
    password &&
    email === expectedEmail &&
    password === expectedPassword
  );
}

function requireAdmin(req, res) {
  if (adminLoginOk(req) || adminSecretOk(req)) return true;
  error(res, "Invalid admin email or password.", 401);
  return false;
}

function reportJson(doc) {
  return {
    id: String(doc._id),
    reporter_name: doc.reporterName || "Guest",
    reporter_email: doc.reporterEmail || doc.guestEmail || "",
    content_type: doc.contentType,
    reason: doc.reason,
    detail: doc.detail || "",
    content_snippet: doc.contentSnippet || "",
    activity_slug: doc.activitySlug || "",
    session_id: doc.sessionId || "",
    created_at: doc.createdAt
      ? new Date(doc.createdAt).toISOString()
      : null,
  };
}

/**
 * POST /ai/report-content
 * Optional auth — guests can report free-try AI text too.
 * Stores reporter name + email + timestamp for the admin review page.
 */
const reportContent = async (req, res) => {
  try {
    const reason = String(req.body.reason || "").trim().toLowerCase();
    const contentType = String(req.body.content_type || req.body.contentType || "other")
      .trim()
      .toLowerCase();
    const detail = String(req.body.detail || "").trim().slice(0, 2000);
    const contentSnippet = String(
      req.body.content_snippet || req.body.contentSnippet || ""
    )
      .trim()
      .slice(0, 4000);
    const activitySlug = String(req.body.activity_slug || req.body.activitySlug || "")
      .trim()
      .slice(0, 80);
    const sessionId = String(req.body.session_id || req.body.sessionId || "")
      .trim()
      .slice(0, 120);

    const bodyName = String(
      req.body.reporter_name || req.body.reporterName || req.body.full_name || ""
    )
      .trim()
      .slice(0, 120);
    const bodyEmail = String(
      req.body.reporter_email ||
        req.body.reporterEmail ||
        req.body.guest_email ||
        req.body.email ||
        ""
    )
      .trim()
      .toLowerCase()
      .slice(0, 160);

    if (!ALLOWED_REASONS.has(reason)) {
      return error(res, "Pick a valid reason for this report.");
    }
    if (!ALLOWED_TYPES.has(contentType)) {
      return error(res, "Unknown content type.");
    }
    if (!contentSnippet) {
      return error(res, "Nothing to report — content was empty.");
    }

    const reporterName =
      (req.user?.fullName && String(req.user.fullName).trim()) ||
      bodyName ||
      "Guest";
    const reporterEmail =
      (req.user?.email && String(req.user.email).trim().toLowerCase()) ||
      bodyEmail ||
      "";

    await AiContentReport.create({
      user: req.user?._id || null,
      reporterName,
      reporterEmail,
      guestEmail: req.user ? "" : reporterEmail,
      contentType,
      reason,
      detail,
      contentSnippet,
      activitySlug,
      sessionId,
    });

    return success(res, "Thanks — we received your report.", { reported: true }, 201);
  } catch (err) {
    console.error("AI content report failed:", err.message);
    return error(res, "Could not submit the report. Try again.", 500);
  }
};

/**
 * GET /admin/ai-reports
 * Auth: x-admin-secret or Bearer ADMIN_SECRET
 */
const listReports = async (req, res) => {
  if (!requireAdmin(req, res)) return;
  try {
    const limit = Math.min(
      Math.max(parseInt(String(req.query.limit || "100"), 10) || 100, 1),
      300
    );
    const docs = await AiContentReport.find({})
      .sort({ createdAt: -1 })
      .limit(limit)
      .lean();
    return success(res, "OK", {
      reports: docs.map(reportJson),
      count: docs.length,
    });
  } catch (err) {
    console.error("list AI reports failed:", err.message);
    return error(res, "Could not load reports.", 500);
  }
};

/**
 * DELETE /admin/ai-reports/:id
 */
const deleteReport = async (req, res) => {
  if (!requireAdmin(req, res)) return;
  try {
    const id = String(req.params.id || "").trim();
    if (!id) return error(res, "Report id required.");
    const deleted = await AiContentReport.findByIdAndDelete(id);
    if (!deleted) return error(res, "Report not found.", 404);
    return success(res, "Report deleted.", { deleted: true, id });
  } catch (err) {
    console.error("delete AI report failed:", err.message);
    return error(res, "Could not delete report.", 500);
  }
};

module.exports = { reportContent, listReports, deleteReport };
