package com.hakkiri.app

import android.Manifest
import android.content.pm.PackageManager
import android.media.AudioAttributes
import android.media.AudioFormat
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

    fun start(wsUrl: String, model: String, systemInstruction: String, result: MethodChannel.Result) {
        // Permission is requested/awaited in MainActivity before this is called.
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

        stopInternal()
        running.set(true)

        try {
            val req = Request.Builder().url(wsUrl).build()
            webSocket = client.newWebSocket(req, object : WebSocketListener() {
                override fun onOpen(webSocket: WebSocket, response: Response) {
                    emit(mapOf("type" to "status", "message" to "Connected", "listening" to true))
                    val setup = JSONObject()
                        .put(
                            "setup",
                            JSONObject()
                                .put("model", "models/$model")
                                .put("responseModalities", JSONArray().put("AUDIO"))
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
                    webSocket.send(setup.toString())
                    startMic(webSocket)
                    mainHandler.post { result.success(true) }
                }

                override fun onMessage(webSocket: WebSocket, text: String) {
                    handleServerMessage(text)
                }

                override fun onMessage(webSocket: WebSocket, bytes: ByteString) {
                    handleServerMessage(bytes.utf8())
                }

                override fun onFailure(webSocket: WebSocket, t: Throwable, response: Response?) {
                    Log.e(TAG, "WebSocket failure", t)
                    emit(mapOf("type" to "error", "message" to (t.message ?: "Live connection failed")))
                    stopInternal()
                }

                override fun onClosed(webSocket: WebSocket, code: Int, reason: String) {
                    emit(mapOf("type" to "closed", "message" to reason))
                    stopInternal()
                }
            })
        } catch (e: Exception) {
            result.error("start_failed", e.message, null)
        }
    }

    fun stop() {
        stopInternal()
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
                    val chunk = buf.copyOf(read)
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

    private fun ensurePlayer() {
        if (player != null) return
        val minBuf = AudioTrack.getMinBufferSize(
            OUTPUT_RATE,
            AudioFormat.CHANNEL_OUT_MONO,
            AudioFormat.ENCODING_PCM_16BIT,
        )
        player = AudioTrack.Builder()
            .setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_VOICE_COMMUNICATION)
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
            .setBufferSizeInBytes(minBuf.coerceAtLeast(OUTPUT_RATE))
            .setTransferMode(AudioTrack.MODE_STREAM)
            .build()
        player?.play()
    }

    private fun handleServerMessage(text: String) {
        try {
            val root = JSONObject(text)
            val serverContent = root.optJSONObject("serverContent") ?: return
            val input = serverContent.optJSONObject("inputTranscription")
            if (input != null) {
                val t = input.optString("text")
                if (t.isNotBlank()) emit(mapOf("type" to "user_transcript", "text" to t))
            }
            val output = serverContent.optJSONObject("outputTranscription")
            if (output != null) {
                val t = output.optString("text")
                if (t.isNotBlank()) emit(mapOf("type" to "model_transcript", "text" to t))
            }
            val modelTurn = serverContent.optJSONObject("modelTurn")
            val parts = modelTurn?.optJSONArray("parts")
            if (parts != null) {
                for (i in 0 until parts.length()) {
                    val part = parts.optJSONObject(i) ?: continue
                    val inline = part.optJSONObject("inlineData") ?: continue
                    val data = inline.optString("data")
                    if (data.isNotBlank()) {
                        val pcm = Base64.decode(data, Base64.DEFAULT)
                        ensurePlayer()
                        player?.write(pcm, 0, pcm.size)
                    }
                }
            }
        } catch (e: Exception) {
            Log.w(TAG, "Bad server message", e)
        }
    }

    private fun stopInternal() {
        running.set(false)
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
        try {
            player?.stop()
            player?.release()
        } catch (_: Exception) {
        }
        player = null
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
