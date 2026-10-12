const Activity = require("../models/Activity");
const Prompt = require("../models/Prompt");
const { success, error } = require("../helpers/response");
const {
  geminiStatus,
  createLiveSessionToken,
  isGeminiConfigured,
  analyzeSpeechWithGemini,
} = require("../config/ai");

const status = async (_req, res) => {
  return success(res, "AI status.", { ai: geminiStatus() });
};

const liveToken = async (req, res) => {
  try {
    if (!isGeminiConfigured()) {
      return error(res, "Live voice is not configured. Set GEMINI_API_KEY on the server.", 503);
    }

    const systemInstruction =
      req.body?.system_instruction ||
      req.body?.systemInstruction ||
      undefined;

    const session = await createLiveSessionToken({ systemInstruction });
    return success(res, "Live voice token ready.", {
      live: session,
    });
  } catch (err) {
    console.error("liveToken failed:", err.message);
    return error(res, err.message || "Could not start live voice.", err.statusCode || 502);
  }
};

/**
 * POST /ai/analyze-speech
 * Body: transcript, duration_seconds, activity_slug, prompt_id?, prompt_text?, ...
 * Returns Gemini Flash feedback matching the app's EvaluationFeedback shape.
 */
const analyzeSpeech = async (req, res) => {
  try {
    if (!isGeminiConfigured()) {
      return error(
        res,
        "Speech analysis is not configured. Set GEMINI_API_KEY on the server.",
        503
      );
    }

    const body = req.body || {};
    if (body.audio || body.audio_base64 || body.audio_file || body.recording) {
      return error(res, "Send the transcript from on-device speech-to-text, not the audio file.");
    }

    const transcript = String(body.transcript || "").slice(0, 20000);
    const durationSeconds = Number(body.duration_seconds || 0);
    const activitySlug = String(body.activity_slug || "").trim();
    const isRetry = Boolean(body.is_coached_retry || body.is_retry);

    let activity = null;
    if (activitySlug) {
      activity = await Activity.findOne({ slug: activitySlug });
      if (!activity) return error(res, "Unknown activity.");
      if (!activity.isMvp) return error(res, "This activity is not open yet.");
    }

    let prompt = null;
    if (body.prompt_id) {
      prompt = await Prompt.findOne({ code: String(body.prompt_id) });
    }

    const promptText =
      String(body.prompt_text || prompt?.promptText || "").trim() ||
      "Answer the communication prompt clearly.";
    const objective = String(body.objective || prompt?.objective || "").trim();
    const exemplarResponse = String(
      body.exemplar_response || prompt?.exemplarResponse || ""
    ).trim();
    const difficulty = String(
      body.difficulty || prompt?.difficulty || "intermediary"
    ).trim();

    const result = await analyzeSpeechWithGemini({
      transcript,
      durationSeconds,
      activitySlug: activity?.slug || activitySlug || "think_fast",
      activityName: activity?.name || body.activity_name || "Practice",
      promptText,
      objective,
      exemplarResponse,
      difficulty,
      isRetry,
    });

    return success(res, "AI analysis ready.", {
      model: result.model,
      feedback: result.feedback,
      transcript,
      duration_seconds: durationSeconds,
      activity_slug: activity?.slug || activitySlug || null,
      prompt_id: prompt?.code || body.prompt_id || null,
    });
  } catch (err) {
    console.error("analyzeSpeech failed:", err.message);
    return error(res, err.message || "Could not analyse speech.", err.statusCode || 502);
  }
};

module.exports = { status, liveToken, analyzeSpeech };
