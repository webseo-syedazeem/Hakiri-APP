const Activity = require("../models/Activity");
const Prompt = require("../models/Prompt");
const { success, error } = require("../helpers/response");
const {
  geminiStatus,
  createLiveSessionToken,
  isGeminiConfigured,
  isCoachTtsConfigured,
  analyzeSpeechWithGemini,
  generateDebatePushback,
  synthesizeCoachSpeech,
} = require("../config/ai");

const status = async (_req, res) => {
  return success(res, "AI status.", { ai: geminiStatus() });
};

const liveToken = async (req, res) => {
  try {
    if (!isGeminiConfigured()) {
      return error(res, "Voice practice is not configured. Set GEMINI_API_KEY on the server.", 503);
    }

    const systemInstruction =
      req.body?.system_instruction ||
      req.body?.systemInstruction ||
      undefined;

    const session = await createLiveSessionToken({ systemInstruction });
    return success(res, "Voice practice token ready.", {
      live: session,
    });
  } catch (err) {
    console.error("liveToken failed:", err.message);
    return error(res, err.message || "Could not start voice practice.", err.statusCode || 502);
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
    // Optional on-device m4a (base64) — app records file-only to avoid mic thrash with STT.
    // Cap ~2.5MB raw → keeps Live scoring payloads reasonable.
    let audioBase64 = String(body.audio_base64 || body.audio || "").trim();
    if (audioBase64.includes(",")) {
      audioBase64 = audioBase64.split(",").pop() || "";
    }
    audioBase64 = audioBase64.replace(/\s/g, "");
    if (audioBase64.length > 3_500_000) {
      return error(res, "Audio clip is too large. Keep answers under ~90 seconds.");
    }
    const audioMimeType = String(body.audio_mime_type || body.mime_type || "audio/mp4").trim() ||
      "audio/mp4";

    const transcript = String(body.transcript || "").slice(0, 20000);
    const durationSeconds = Number(body.duration_seconds || 0);
    const activitySlug = String(body.activity_slug || "").trim();
    const isRetry = Boolean(body.is_coached_retry || body.is_retry);

    // App already sends prompt_text + exemplar — skip Prompt DB when complete.
    const bodyHasPrompt =
      String(body.prompt_text || "").trim().length >= 8 &&
      String(body.exemplar_response || "").trim().length >= 8;
    const [activity, prompt] = await Promise.all([
      activitySlug
        ? Activity.findOne({ slug: activitySlug })
            .select("slug name isMvp")
            .lean()
        : Promise.resolve(null),
      body.prompt_id && !bodyHasPrompt
        ? Prompt.findOne({ code: String(body.prompt_id) })
            .select("code promptText objective exemplarResponse difficulty")
            .lean()
        : Promise.resolve(null),
    ]);
    if (activitySlug) {
      if (!activity) return error(res, "Unknown activity.");
      if (!activity.isMvp) return error(res, "This activity is not open yet.");
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
      audioBase64: audioBase64 || undefined,
      audioMimeType,
    });

    return success(res, "AI analysis ready.", {
      model: result.model,
      feedback: result.feedback,
      transcript: result.transcript || transcript,
      duration_seconds: durationSeconds,
      activity_slug: activity?.slug || activitySlug || null,
      prompt_id: prompt?.code || body.prompt_id || null,
    });
  } catch (err) {
    console.error("analyzeSpeech failed:", err.message);
    return error(res, err.message || "Could not analyse speech.", err.statusCode || 502);
  }
};

/**
 * POST /ai/debate-pushback
 * Body: topic, opening_transcript?, audio_base64?, audio_mime_type?, career_context?
 * Returns Flash pushback + opening transcript for guided Debate Me.
 */
const debatePushback = async (req, res) => {
  try {
    if (!isGeminiConfigured()) {
      return error(
        res,
        "Debate coach is not configured. Set GEMINI_API_KEY on the server.",
        503
      );
    }

    const body = req.body || {};
    let audioBase64 = String(body.audio_base64 || body.audio || "").trim();
    if (audioBase64.includes(",")) {
      audioBase64 = audioBase64.split(",").pop() || "";
    }
    audioBase64 = audioBase64.replace(/\s/g, "");
    if (audioBase64.length > 3_500_000) {
      return error(res, "Audio clip is too large. Keep answers under ~90 seconds.");
    }
    const audioMimeType =
      String(body.audio_mime_type || body.mime_type || "audio/mp4").trim() ||
      "audio/mp4";

    const topic = String(body.topic || body.prompt_text || "").trim();
    if (!topic) {
      return error(res, "Debate topic is required.");
    }

    const result = await generateDebatePushback({
      topic,
      openingTranscript: String(body.opening_transcript || body.transcript || ""),
      audioBase64: audioBase64 || undefined,
      audioMimeType,
      careerContext: String(body.career_context || body.career || ""),
    });

    return success(res, "Debate pushback ready.", {
      model: result.model,
      transcript: result.transcript,
      pushback: result.pushback,
      topic,
    });
  } catch (err) {
    console.error("debatePushback failed:", err.message);
    return error(res, err.message || "Could not craft pushback.", err.statusCode || 502);
  }
};

/**
 * POST /ai/coach-speak
 * Body: { text, voice_profile?, rate? }
 * Returns WAV audio + word timings so the app can karaoke in lockstep.
 */
const coachSpeak = async (req, res) => {
  try {
    if (!isCoachTtsConfigured()) {
      return error(
        res,
        "Coach speech is not configured. Set GEMINI_API_KEY on the server.",
        503
      );
    }

    const body = req.body || {};
    const text = String(body.text || body.prompt || "").trim();
    if (!text) {
      return error(res, "text is required.", 400);
    }

    const result = await synthesizeCoachSpeech({
      text,
      voiceProfile: body.voice_profile || body.voiceProfile || body.voice || "sarah",
      rate: Number(body.rate || 1) || 1,
    });

    return success(res, "Coach speech ready.", {
      model: result.model,
      voice: result.voice,
      mime_type: result.mime_type,
      audio_base64: result.audio_base64,
      duration_ms: result.duration_ms,
      sample_rate: result.sample_rate,
      text: result.text,
      words: result.words,
    });
  } catch (err) {
    console.error("coachSpeak failed:", err.message);
    return error(
      res,
      err.message || "Could not synthesize coach speech.",
      err.statusCode || 502
    );
  }
};

module.exports = {
  status,
  liveToken,
  analyzeSpeech,
  debatePushback,
  coachSpeak,
};
