package com.hakkiri.app

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioRecord
import android.media.AudioTrack
import android.media.MediaRecorder
import android.os.Handler
import android.os.Looper
import android.util.Base64
import android.util.Log
import androidx.core.app.ActivityCompat
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.Response
import okhttp3.WebSocket
import okhttp3.WebSocketListener
import okio.ByteString
import org.json.JSONArray
import org.json.JSONObject
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean

class LiveVoiceSession(
    private val activity: MainActivity,
    private val events: EventChannel.EventSink?,
) {
    private val mainHandler = Handler(Looper.getMainLooper())
    private val audioExecutor = Executors.newSingleThreadExecutor()
    private val client = OkHttpClient.Builder()
        .readTimeout(0, TimeUnit.MILLISECONDS)
        .pingInterval(15, TimeUnit.SECONDS)
        .build()

    private var webSocket: WebSocket? = null
    private var recorder: AudioRecord? = null
    private var player: AudioTrack? = null
    private val running = AtomicBoolean(false)
    private var pendingResult: MethodChannel.Result? = null
    private var resultSent = false
    private var setupDone = false
    private var kickoffText: String = ""
    private var lastSpeakingEmitMs = 0L
    private var lastSpeakingState: Boolean? = null
    /** False while coach audio plays — stops speaker echo becoming "user" text. */
    private val micOpen = AtomicBoolean(false)
    private val openMicAfterCoach = Runnable {
        if (running.get()) {
            micOpen.set(true)
            emit(mapOf("type" to "status", "message" to "Your turn — speak naturally", "listening" to true))
        }
    }
    /** If coach audio stops (no new chunks) before turnComplete, open mic sooner. */
    private val audioIdleOpenMic = Runnable {
        if (running.get()) scheduleMicForUser(delayMs = 100)
    }
    private val setupTimeout = Runnable {
        if (!setupDone && running.get()) {
            failPending(
                "setup_timeout",
                "Live coach did not finish setup. Try again.",
            )
            stopInternal(failIfPending = false)
        }
    }

    fun start(
        wsUrl: String,
        model: String,
        systemInstruction: String,
        authHeader: String?,
        kickoff: String?,
        result: MethodChannel.Result,
    ) {
        if (ActivityCompat.checkSelfPermission(activity, Manifest.permission.RECORD_AUDIO)
            != PackageManager.PERMISSION_GRANTED
        ) {
            result.error(
                "mic_permission",
                "Microphone permission is required. Enable it in Settings and try again.",
                null,
            )
            return
        }

        stopInternal(failIfPending = true)
        running.set(true)
        pendingResult = result
        resultSent = false
        setupDone = false
        micOpen.set(false)
        kickoffText = kickoff?.trim().orEmpty()

        try {
            val builder = Request.Builder().url(wsUrl)
            if (!authHeader.isNullOrBlank()) {
                builder.header("Authorization", authHeader)
            }
            val req = builder.build()
            webSocket = client.newWebSocket(req, object : WebSocketListener() {
                override fun onOpen(webSocket: WebSocket, response: Response) {
                    Log.i(TAG, "WebSocket open code=${response.code}")
                    emit(mapOf("type" to "status", "message" to "Connecting…", "listening" to false))
                    val setup = buildSetup(model, systemInstruction)
                    Log.i(TAG, "Sending setup for model=$model")
                    webSocket.send(setup.toString())
                    mainHandler.removeCallbacks(setupTimeout)
                    mainHandler.postDelayed(setupTimeout, 12_000)
                }

                override fun onMessage(webSocket: WebSocket, text: String) {
                    if (!running.get()) return
                    Log.d(TAG, "WS message: ${text.take(240)}")
                    handleServerMessage(text, webSocket)
                }

                override fun onMessage(webSocket: WebSocket, bytes: ByteString) {
                    if (!running.get()) return
                    val text = bytes.utf8()
                    Log.d(TAG, "WS binary: ${text.take(240)}")
                    handleServerMessage(text, webSocket)
                }

                override fun onFailure(webSocket: WebSocket, t: Throwable, response: Response?) {
                    Log.e(TAG, "WebSocket failure code=${response?.code}", t)
                    emit(mapOf("type" to "error", "message" to (t.message ?: "Live connection failed")))
                    failPending("ws_failed", t.message ?: "Live connection failed")
                    stopInternal(failIfPending = false)
                }

                override fun onClosed(webSocket: WebSocket, code: Int, reason: String) {
                    Log.i(TAG, "WebSocket closed code=$code reason=$reason")
                    emit(mapOf("type" to "closed", "message" to reason))
                    if (!setupDone) {
                        failPending("ws_closed", reason.ifBlank { "Live connection closed" })
                    }
                    stopInternal(failIfPending = false)
                }
            })
        } catch (e: Exception) {
            result.error("start_failed", e.message, null)
            pendingResult = null
            resultSent = true
        }
    }

    fun stop() {
        stopInternal(failIfPending = true)
    }

    private fun buildSetup(model: String, systemInstruction: String): JSONObject {
        // Match Gemini Live WebSocket docs / get-started setup shape.
        val generation = JSONObject()
            .put("responseModalities", JSONArray().put("AUDIO"))
        // Wait longer through natural pauses so the coach does not jump in mid-answer.
        val activityDetection = JSONObject()
            .put("disabled", false)
            .put("startOfSpeechSensitivity", "START_SENSITIVITY_LOW")
            .put("endOfSpeechSensitivity", "END_SENSITIVITY_LOW")
            .put("prefixPaddingMs", 40)
            .put("silenceDurationMs", 900)
        val realtimeInput = JSONObject()
            .put("automaticActivityDetection", activityDetection)
        return JSONObject().put(
            "setup",
            JSONObject()
                .put("model", "models/$model")
                .put("generationConfig", generation)
                .put("realtimeInputConfig", realtimeInput)
                .put("inputAudioTranscription", JSONObject())
                .put("outputAudioTranscription", JSONObject())
                .put(
                    "systemInstruction",
                    JSONObject().put(
                        "parts",
                        JSONArray().put(JSONObject().put("text", systemInstruction)),
                    ),
                ),
        )
    }

    private fun sendKickoff(socket: WebSocket) {
        val text = kickoffText.ifBlank {
            "Please greet me briefly as Hakkiri Live Coach, then ask the practice question and wait for my spoken answer."
        }
        val parts = JSONArray().put(JSONObject().put("text", text))
        val turn = JSONObject()
            .put("role", "user")
            .put("parts", parts)
        val msg = JSONObject().put(
            "clientContent",
            JSONObject()
                .put("turns", JSONArray().put(turn))
                .put("turnComplete", true),
        )
        Log.i(TAG, "Sending kickoff so coach speaks first")
        socket.send(msg.toString())
    }

    private fun startMic(socket: WebSocket) {
        val minBuf = AudioRecord.getMinBufferSize(
            INPUT_RATE,
            AudioFormat.CHANNEL_IN_MONO,
            AudioFormat.ENCODING_PCM_16BIT,
        )
        val bufferSize = minBuf.coerceAtLeast(INPUT_RATE / 5 * 2)
        val localRecorder = AudioRecord(
            MediaRecorder.AudioSource.VOICE_COMMUNICATION,
            INPUT_RATE,
            AudioFormat.CHANNEL_IN_MONO,
            AudioFormat.ENCODING_PCM_16BIT,
            bufferSize,
        )
        recorder = localRecorder
        localRecorder.startRecording()

        ensurePlayer()

        audioExecutor.execute {
            val buf = ByteArray(bufferSize)
            while (running.get()) {
                val read = localRecorder.read(buf, 0, buf.size)
                if (read > 0 && running.get()) {
                    // Keep draining the recorder so the buffer never backs up,
                    // but only stream / emit while it's the user's turn.
                    if (!micOpen.get()) continue
                    val chunk = buf.copyOf(read)
                    maybeEmitSpeaking(chunk, read)
                    val encoded = Base64.encodeToString(chunk, Base64.NO_WRAP)
                    val msg = JSONObject()
                        .put(
                            "realtimeInput",
                            JSONObject().put(
                                "audio",
                                JSONObject()
                                    .put("data", encoded)
                                    .put("mimeType", "audio/pcm;rate=16000"),
                            ),
                        )
                    socket.send(msg.toString())
                }
            }
        }
    }

    private fun muteMicForCoach() {
        val wasOpen = micOpen.getAndSet(false)
        mainHandler.removeCallbacks(openMicAfterCoach)
        mainHandler.removeCallbacks(audioIdleOpenMic)
        if (wasOpen) {
            lastSpeakingState = false
            emit(mapOf("type" to "user_speaking", "speaking" to false, "level" to 0.0))
        }
    }

    private fun scheduleMicForUser(delayMs: Long = 280) {
        mainHandler.removeCallbacks(openMicAfterCoach)
        mainHandler.removeCallbacks(audioIdleOpenMic)
        mainHandler.postDelayed(openMicAfterCoach, delayMs)
    }

    private fun onCoachAudioPlaying() {
        muteMicForCoach()
        // Re-arm after coach audio stops — slight tail so we don't clip the last syllable.
        mainHandler.removeCallbacks(audioIdleOpenMic)
        mainHandler.postDelayed(audioIdleOpenMic, 420)
    }

    /** Louder coach playback — Gemini PCM is often quiet on phone speakers. */
    private fun boostPcm(pcm: ByteArray, gain: Float = 1.85f): ByteArray {
        val out = pcm.copyOf()
        var i = 0
        while (i + 1 < out.size) {
            val sample = ((out[i + 1].toInt() shl 8) or (out[i].toInt() and 0xff)).toShort().toInt()
            val boosted = (sample * gain).toInt()
                .coerceIn(Short.MIN_VALUE.toInt(), Short.MAX_VALUE.toInt())
            out[i] = (boosted and 0xff).toByte()
            out[i + 1] = ((boosted shr 8) and 0xff).toByte()
            i += 2
        }
        return out
    }

    private fun routeToSpeakerLoud() {
        try {
            val am = activity.getSystemService(Context.AUDIO_SERVICE) as AudioManager
            am.mode = AudioManager.MODE_IN_COMMUNICATION
            @Suppress("DEPRECATION")
            am.isSpeakerphoneOn = true
        } catch (_: Exception) {
        }
    }

    private fun pcmRms(buf: ByteArray, len: Int): Double {
        var sum = 0.0
        var samples = 0
        var i = 0
        while (i + 1 < len) {
            val sample = ((buf[i + 1].toInt() shl 8) or (buf[i].toInt() and 0xff)).toShort().toInt()
            sum += sample.toDouble() * sample.toDouble()
            samples++
            i += 2
        }
        if (samples == 0) return 0.0
        return kotlin.math.sqrt(sum / samples)
    }

    private fun maybeEmitSpeaking(buf: ByteArray, len: Int) {
        val rms = pcmRms(buf, len)
        val speaking = rms > 900.0
        val now = System.currentTimeMillis()
        val stateChanged = lastSpeakingState != speaking
        val due = now - lastSpeakingEmitMs >= if (stateChanged) 120L else 350L
        if (!due) return
        lastSpeakingEmitMs = now
        lastSpeakingState = speaking
        emit(mapOf("type" to "user_speaking", "speaking" to speaking, "level" to rms))
    }

    @Synchronized
    private fun ensurePlayer() {
        if (!running.get()) return
        if (player != null) return
        routeToSpeakerLoud()
        val minBuf = AudioTrack.getMinBufferSize(
            OUTPUT_RATE,
            AudioFormat.CHANNEL_OUT_MONO,
            AudioFormat.ENCODING_PCM_16BIT,
        )
        player = AudioTrack.Builder()
            .setAudioAttributes(
                AudioAttributes.Builder()
                    // MEDIA + speech keeps volume higher than VOICE_COMMUNICATION ducking.
                    .setUsage(AudioAttributes.USAGE_MEDIA)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                    .build(),
            )
            .setAudioFormat(
                AudioFormat.Builder()
                    .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                    .setSampleRate(OUTPUT_RATE)
                    .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                    .build(),
            )
            .setBufferSizeInBytes(minBuf.coerceAtLeast(OUTPUT_RATE * 2))
            .setTransferMode(AudioTrack.MODE_STREAM)
            .build()
        player?.setVolume(1.0f)
        player?.play()
    }

    /** Instant silence — flush buffered PCM so coach does not keep talking after leave. */
    @Synchronized
    private fun killPlayer() {
        val p = player ?: return
        player = null
        try {
            p.setVolume(0f)
        } catch (_: Exception) {
        }
        try {
            p.pause()
        } catch (_: Exception) {
        }
        try {
            p.flush()
        } catch (_: Exception) {
        }
        try {
            p.stop()
        } catch (_: Exception) {
        }
        try {
            p.release()
        } catch (_: Exception) {
        }
    }

    @Synchronized
    private fun writePcm(pcm: ByteArray) {
        if (!running.get()) return
        ensurePlayer()
        if (!running.get()) return
        try {
            player?.write(pcm, 0, pcm.size)
        } catch (_: Exception) {
        }
    }

    private fun handleServerMessage(text: String, socket: WebSocket? = null) {
        if (!running.get()) return
        try {
            val root = JSONObject(text)
            if (root.has("setupComplete")) {
                setupDone = true
                mainHandler.removeCallbacks(setupTimeout)
                succeedPending()
                muteMicForCoach()
                emit(
                    mapOf(
                        "type" to "status",
                        "message" to "Coach is speaking…",
                        "listening" to true,
                    ),
                )
                if (socket != null && running.get()) {
                    sendKickoff(socket)
                    if (recorder == null) {
                        startMic(socket)
                    }
                }
                return
            }
            val err = root.optJSONObject("error")
            if (err != null) {
                val msg = err.optString("message").ifBlank {
                    err.optString("status").ifBlank { "Live voice failed." }
                }
                emit(mapOf("type" to "error", "message" to msg))
                failPending("gemini_error", msg)
                stopInternal(failIfPending = false)
                return
            }

            val serverContent = root.optJSONObject("serverContent") ?: return
            val output = serverContent.optJSONObject("outputTranscription")
            if (output != null) {
                val t = output.optString("text")
                if (t.isNotBlank()) {
                    muteMicForCoach()
                    emit(mapOf("type" to "model_transcript", "text" to t))
                }
            }
            val modelTurn = serverContent.optJSONObject("modelTurn")
            val parts = modelTurn?.optJSONArray("parts")
            if (parts != null) {
                for (i in 0 until parts.length()) {
                    val part = parts.optJSONObject(i) ?: continue
                    val inline = part.optJSONObject("inlineData")
                        ?: part.optJSONObject("inline_data")
                        ?: continue
                    val data = inline.optString("data")
                    if (data.isNotBlank()) {
                        if (!running.get()) return
                        onCoachAudioPlaying()
                        val pcm = boostPcm(Base64.decode(data, Base64.DEFAULT))
                        writePcm(pcm)
                    }
                }
            }
            // Only surface user speech while mic is open (user's turn).
            val input = serverContent.optJSONObject("inputTranscription")
            if (input != null && micOpen.get()) {
                val t = input.optString("text")
                if (t.isNotBlank()) emit(mapOf("type" to "user_transcript", "text" to t))
            }
            if (serverContent.optBoolean("turnComplete", false)) {
                emit(mapOf("type" to "turn_complete"))
                scheduleMicForUser(delayMs = 280)
            }
        } catch (e: Exception) {
            Log.w(TAG, "Bad server message", e)
        }
    }

    private fun succeedPending() {
        if (resultSent) return
        resultSent = true
        val r = pendingResult
        pendingResult = null
        mainHandler.post { r?.success(true) }
    }

    private fun failPending(code: String, message: String) {
        if (resultSent) return
        resultSent = true
        val r = pendingResult
        pendingResult = null
        mainHandler.post { r?.error(code, message, null) }
    }

    private fun stopInternal(failIfPending: Boolean) {
        // Flip first so in-flight WS callbacks cannot recreate / write to the player.
        running.set(false)
        micOpen.set(false)
        mainHandler.removeCallbacks(setupTimeout)
        mainHandler.removeCallbacks(openMicAfterCoach)
        mainHandler.removeCallbacks(audioIdleOpenMic)
        killPlayer()
        if (failIfPending && !setupDone) {
            failPending("stopped", "Live session stopped before setup finished.")
        }
        try {
            webSocket?.close(1000, "bye")
        } catch (_: Exception) {
        }
        webSocket = null
        try {
            recorder?.stop()
            recorder?.release()
        } catch (_: Exception) {
        }
        recorder = null
        // Second pass in case a write raced before running=false was visible.
        killPlayer()
    }

    private fun emit(payload: Map<String, Any?>) {
        mainHandler.post {
            events?.success(payload)
        }
    }

    companion object {
        private const val TAG = "LiveVoiceSession"
        const val REQ_MIC = 4401
        private const val INPUT_RATE = 16000
        private const val OUTPUT_RATE = 24000
    }
}
