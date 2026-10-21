package com.hakkiri.app

import android.content.Context
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.util.Locale
import java.util.UUID

/**
 * Native TextToSpeech karaoke — [onRangeStart] reports the range currently
 * being spoken (API 26+). Dart maps start offset → word highlight.
 */
class KaraokeTtsPlugin(
    private val context: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {
    private val channel = MethodChannel(messenger, CHANNEL)
    private val mainHandler = Handler(Looper.getMainLooper())
    private var tts: TextToSpeech? = null
    private var ready = false
    private var speaking = false
    private var pendingResult: MethodChannel.Result? = null
    private var currentText: String = ""

    init {
        channel.setMethodCallHandler(this)
        tts = TextToSpeech(context) { status ->
            ready = status == TextToSpeech.SUCCESS
            if (ready) {
                tts?.language = Locale.US
                tts?.setOnUtteranceProgressListener(listener)
            }
        }
    }

    override fun onMethodCall(call: io.flutter.plugin.common.MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "speak" -> {
                val text = call.argument<String>("text")?.trim().orEmpty()
                if (text.isEmpty()) {
                    result.error("bad_args", "text required", null)
                    return
                }
                val rate = (call.argument<Double>("rate") ?: 0.44).toFloat()
                val pitch = (call.argument<Double>("pitch") ?: 1.0).toFloat()
                speak(text, rate, pitch, result)
            }
            "stop" -> {
                stopSpeaking()
                result.success(true)
            }
            "isSpeaking" -> result.success(speaking)
            else -> result.notImplemented()
        }
    }

    private fun speak(text: String, rate: Float, pitch: Float, result: MethodChannel.Result) {
        val engine = tts
        if (engine == null || !ready) {
            result.error("not_ready", "TextToSpeech not ready", null)
            return
        }
        stopSpeaking()
        currentText = text
        pendingResult = result
        speaking = true

        // flutter_tts rate ~0.5 ≈ Android 1.0
        val clamped = rate.coerceIn(0.35f, 0.55f)
        engine.setSpeechRate((clamped / 0.5f).coerceIn(0.5f, 1.5f))
        engine.setPitch(pitch.coerceIn(0.5f, 2.0f))

        val id = UUID.randomUUID().toString()
        val params = Bundle()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            engine.speak(text, TextToSpeech.QUEUE_FLUSH, params, id)
        } else {
            @Suppress("DEPRECATION")
            engine.speak(text, TextToSpeech.QUEUE_FLUSH, hashMapOf(TextToSpeech.Engine.KEY_PARAM_UTTERANCE_ID to id))
        }
    }

    private fun stopSpeaking() {
        tts?.stop()
        speaking = false
        pendingResult?.success(true)
        pendingResult = null
    }

    private fun emit(method: String, args: Any?) {
        mainHandler.post { channel.invokeMethod(method, args) }
    }

    private fun completeSpeak() {
        speaking = false
        emit("onComplete", null)
        pendingResult?.success(true)
        pendingResult = null
    }

    private val listener = object : UtteranceProgressListener() {
        override fun onStart(utteranceId: String?) {
            emit("onStart", null)
        }

        override fun onDone(utteranceId: String?) {
            mainHandler.post { completeSpeak() }
        }

        @Deprecated("Deprecated in Java")
        override fun onError(utteranceId: String?) {
            mainHandler.post {
                speaking = false
                emit("onCancel", null)
                pendingResult?.success(true)
                pendingResult = null
            }
        }

        override fun onRangeStart(utteranceId: String?, start: Int, end: Int, frame: Int) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
            val text = currentText
            if (start < 0 || end > text.length || start >= end) return
            val word = text.substring(start, end)
            emit(
                "onProgress",
                mapOf(
                    "start" to start,
                    "end" to end,
                    "word" to word,
                    "text" to text,
                ),
            )
        }
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        tts?.stop()
        tts?.shutdown()
        tts = null
    }

    companion object {
        const val CHANNEL = "com.hakkiri.app/karaoke_tts"
    }
}
