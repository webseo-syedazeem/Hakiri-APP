const DEFAULT_LIVE_MODEL = "gemini-3.8-live";
const DEFAULT_FLASH_MODEL = "gemini-2.5-flash";

const DEFAULT_COACH_INSTRUCTION =
  "You are Hakkiri Live Coach. Help the user practise clear professional speech. " +
  "Keep replies short, spoken, and practical. Ask one follow-up question at a time. " +
  "Do not penalise accents. Coach structure, clarity, calm pace, and confidence.";

function geminiApiKey() {
  return String(process.env.GEMINI_API_KEY || "").trim();
}

function isGeminiConfigured() {
  return geminiApiKey().length > 0;
}

function liveModel() {
  return String(process.env.GEMINI_LIVE_MODEL || DEFAULT_LIVE_MODEL).trim() || DEFAULT_LIVE_MODEL;
}

function flashModel() {
  return String(process.env.GEMINI_FLASH_MODEL || DEFAULT_FLASH_MODEL).trim() || DEFAULT_FLASH_MODEL;
}

function geminiStatus() {
  return {
    provider: "gemini",
    configured: isGeminiConfigured(),
    env: "GEMINI_API_KEY",
    live_model: liveModel(),
    flash_model: flashModel(),
    live_ready: isGeminiConfigured(),
    analysis_ready: isGeminiConfigured(),
    note: "Key stays on the server. The app uses short-lived live tokens only. Drill scoring uses Gemini Flash.",
  };
}

function clampScore(value, fallback = 2) {
  const n = Number(value);
  if (!Number.isFinite(n)) return fallback;
  return Math.min(5, Math.max(1, Math.round(n)));
}

function extractJsonObject(text) {
  const raw = String(text || "").trim();
  if (!raw) return null;
  try {
    return JSON.parse(raw);
  } catch (_) {
    const start = raw.indexOf("{");
    const end = raw.lastIndexOf("}");
    if (start >= 0 && end > start) {
      try {
        return JSON.parse(raw.slice(start, end + 1));
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}

function normalizeFeedback(parsed, { transcript, durationSeconds, isRetry, exemplarFallback }) {
  const pillarsIn = parsed?.pillars || {};
  const highlightIn = parsed?.highlighted_phrase || {};
  const words = String(transcript || "")
    .trim()
    .split(/\s+/)
    .filter(Boolean);
  const minutes = Math.max((Number(durationSeconds) || 60) / 60, 1 / 60);
  const wpm = words.length ? Math.round(words.length / minutes) : 0;

  const executive = clampScore(pillarsIn.executive_score, 2);
  const clarity = clampScore(pillarsIn.clarity_score, 2);
  const impact = clampScore(pillarsIn.impact_score, 2);
  const engagement = clampScore(pillarsIn.engagement_score, 2);
  const overall = clampScore(
    parsed?.overall_score,
    Math.round((executive + clarity + impact + engagement) / 4)
  );

  const snippet =
    words.length === 0
      ? "(no clear speech captured)"
      : `...${words.slice(0, 12).join(" ")}${words.length > 12 ? "…" : ""}...`;

  return {
    overall_score: overall,
    pillars: {
      executive_score: executive,
      clarity_score: clarity,
      impact_score: impact,
      engagement_score: engagement,
      crutch_count: Number(pillarsIn.crutch_count) || 0,
      power_pause_count: Number(pillarsIn.power_pause_count) || 0,
      pacing_wpm: Number(pillarsIn.pacing_wpm) || wpm,
      intelligibility_pct: Number(pillarsIn.intelligibility_pct) || (words.length < 8 ? 45 : 85),
      action_verb_pct: Number(pillarsIn.action_verb_pct) || 50,
      is_monotone: Boolean(pillarsIn.is_monotone) || words.length < 20,
    },
    one_strength: String(parsed?.one_strength || "").trim() ||
      (words.length < 12
        ? "Mic captured speech — now turn it into a real answer to the prompt."
        : "You got words on record under time pressure."),
    one_specific_improvement: String(parsed?.one_specific_improvement || "").trim() ||
      "Lead with the conclusion in the first sentence, then add one concrete reason.",
    highlighted_phrase: {
      timestamp_range: String(highlightIn.timestamp_range || "00:05 - 00:15"),
      phrase: String(highlightIn.phrase || snippet),
      critique: String(highlightIn.critique || "").trim() ||
        (words.length < 12
          ? "Too little speech to show executive presence — answer the prompt fully."
          : "Tighten the opening so the decision lands first."),
    },
    retry_instruction: String(parsed?.retry_instruction || "").trim() ||
      "Open with your bottom-line answer in under 5 seconds, then support it with one example.",
    exemplar_response: String(parsed?.exemplar_response || exemplarFallback || "").trim(),
    is_coached_retry: Boolean(isRetry),
  };
}

/**
 * Score a practice transcript with Gemini Flash (doc Week 3 AI analysis).
 */
async function analyzeSpeechWithGemini({
  transcript,
  durationSeconds,
  activitySlug,
  activityName,
  promptText,
  objective,
  exemplarResponse,
  difficulty,
  isRetry = false,
} = {}) {
  const key = geminiApiKey();
  if (!key) {
    const err = new Error("GEMINI_API_KEY is not configured on the server.");
    err.statusCode = 503;
    throw err;
  }

  const model = flashModel();
  const spoken = String(transcript || "").trim();
  const system = [
    "You are Hakkiri, an executive communication coach.",
    "Score ONLY from the user's spoken transcript against the practice prompt.",
    "Do NOT invent that they said things they did not say.",
    "Do NOT penalise accents. Focus on clarity, structure, relevance, conciseness, fillers, pace, and time-to-main-point.",
    "If the transcript is empty, filler-only (hello/test/um), off-topic, or under ~12 meaningful words, scores must be 1–2.",
    "Return ONLY valid JSON with this exact shape:",
    JSON.stringify({
      overall_score: 1,
      pillars: {
        executive_score: 1,
        clarity_score: 1,
        impact_score: 1,
        engagement_score: 1,
        crutch_count: 0,
        power_pause_count: 0,
        pacing_wpm: 0,
        intelligibility_pct: 0,
        action_verb_pct: 0,
        is_monotone: true,
      },
      one_strength: "string",
      one_specific_improvement: "string",
      highlighted_phrase: {
        timestamp_range: "00:00 - 00:00",
        phrase: "quote from transcript",
        critique: "string",
      },
      retry_instruction: "string",
      exemplar_response: "strong model answer for THIS prompt",
    }),
  ].join("\n");

  const user = [
    `Activity: ${activityName || activitySlug || "drill"} (${activitySlug || "unknown"})`,
    `Difficulty: ${difficulty || "intermediary"}`,
    `Prompt / question: ${promptText || "(missing)"}`,
    `Objective: ${objective || "(none)"}`,
    `Catalog exemplar (optional guidance): ${exemplarResponse || "(none)"}`,
    `Duration spoken (seconds): ${Number(durationSeconds) || 0}`,
    `Coached retry: ${isRetry ? "yes" : "no"}`,
    `User transcript:"""`,
    spoken || "(empty — user did not produce usable speech)",
    `"""`,
    "Analyse fillers/false starts, pace, pauses, latency/time-to-main-point, clarity, structure, relevance, conciseness.",
    "Write one_strength, one_specific_improvement, retry_instruction, and a fresh exemplar_response tailored to this prompt.",
    "highlighted_phrase.phrase must quote or paraphrase from the actual transcript (or note empty).",
  ].join("\n");

  const url = `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:generateContent?key=${encodeURIComponent(key)}`;
  const response = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      contents: [{ role: "user", parts: [{ text: `${system}\n\n${user}` }] }],
      generationConfig: {
        temperature: 0.3,
        responseMimeType: "application/json",
      },
    }),
  });

  const data = await response.json().catch(() => ({}));
  if (!response.ok) {
    const err = new Error(data?.error?.message || "Gemini analysis failed.");
    err.statusCode = response.status >= 400 ? response.status : 502;
    throw err;
  }

  const text =
    data?.candidates?.[0]?.content?.parts?.map((p) => p.text || "").join("") ||
    data?.candidates?.[0]?.content?.parts?.[0]?.text ||
    "";
  const parsed = extractJsonObject(text);
  if (!parsed) {
    const err = new Error("Gemini returned an unreadable analysis payload.");
    err.statusCode = 502;
    throw err;
  }

  return {
    model,
    feedback: normalizeFeedback(parsed, {
      transcript: spoken,
      durationSeconds,
      isRetry,
      exemplarFallback: exemplarResponse,
    }),
  };
}

async function createLiveSessionToken({ systemInstruction } = {}) {
  const key = geminiApiKey();
  if (!key) {
    const err = new Error("GEMINI_API_KEY is not configured on the server.");
    err.statusCode = 503;
    throw err;
  }

  const model = liveModel();
  const expireTime = new Date(Date.now() + 30 * 60 * 1000).toISOString();
  const newSessionExpireTime = new Date(Date.now() + 2 * 60 * 1000).toISOString();
  const instruction = String(systemInstruction || DEFAULT_COACH_INSTRUCTION).slice(0, 4000);

  const payload = {
    uses: 1,
    expireTime,
    newSessionExpireTime,
    bidiGenerateContentSetup: {
      model: `models/${model}`,
      generationConfig: {
        responseModalities: ["AUDIO"],
      },
      systemInstruction: {
        parts: [{ text: instruction }],
      },
      inputAudioTranscription: {},
      outputAudioTranscription: {},
    },
  };

  const response = await fetch("https://generativelanguage.googleapis.com/v1alpha/auth_tokens", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-goog-api-key": key,
    },
    body: JSON.stringify(payload),
  });

  const data = await response.json().catch(() => ({}));
  if (!response.ok) {
    const err = new Error(data?.error?.message || "Could not create a live voice token.");
    err.statusCode = response.status >= 400 ? response.status : 502;
    throw err;
  }

  const accessToken = data.name || data.token || data.accessToken || data.access_token;
  if (!accessToken) {
    const err = new Error("Live token response did not include an access token.");
    err.statusCode = 502;
    throw err;
  }

  const wsUrl =
    "wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContentConstrained" +
    `?access_token=${encodeURIComponent(accessToken)}`;

  return {
    access_token: accessToken,
    model,
    ws_url: wsUrl,
    expire_time: expireTime,
    new_session_expire_time: newSessionExpireTime,
    response_modalities: ["AUDIO"],
    input_mime_type: "audio/pcm;rate=16000",
    output_sample_rate_hz: 24000,
    system_instruction: instruction,
  };
}

module.exports = {
  geminiApiKey,
  isGeminiConfigured,
  geminiStatus,
  liveModel,
  flashModel,
  analyzeSpeechWithGemini,
  createLiveSessionToken,
  DEFAULT_COACH_INSTRUCTION,
};
