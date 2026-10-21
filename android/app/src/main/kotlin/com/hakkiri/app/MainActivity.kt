package com.hakkiri.app

import android.Manifest
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var eventSink: EventChannel.EventSink? = null
    private var session: LiveVoiceSession? = null
    private var karaokeTts: KaraokeTtsPlugin? = null

    private var pendingResult: MethodChannel.Result? = null
    private var pendingWsUrl: String? = null
    private var pendingModel: String? = null
    private var pendingInstruction: String? = null
    private var pendingAuthHeader: String? = null
    private var pendingKickoff: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        karaokeTts = KaraokeTtsPlugin(
            context = this,
            messenger = flutterEngine.dartExecutor.binaryMessenger,
        )

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            })

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> {
                        val wsUrl = call.argument<String>("ws_url").orEmpty()
                        val model = call.argument<String>("model") ?: "gemini-3.8-live"
                        val instruction = call.argument<String>("system_instruction").orEmpty()
                        val authHeader = call.argument<String>("auth_header")
                        val kickoff = call.argument<String>("kickoff")
                        if (wsUrl.isEmpty()) {
                            result.error("bad_args", "ws_url is required", null)
                            return@setMethodCallHandler
                        }
                        beginLiveSession(wsUrl, model, instruction, authHeader, kickoff, result)
                    }
                    "stop" -> {
                        clearPendingStart()
                        session?.stop()
                        session = null
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun beginLiveSession(
        wsUrl: String,
        model: String,
        instruction: String,
        authHeader: String?,
        kickoff: String?,
        result: MethodChannel.Result,
    ) {
        if (hasMicPermission()) {
            startSessionNow(wsUrl, model, instruction, authHeader, kickoff, result)
            return
        }

        // Wait for the system permission dialog — do NOT fail immediately.
        pendingResult = result
        pendingWsUrl = wsUrl
        pendingModel = model
        pendingInstruction = instruction
        pendingAuthHeader = authHeader
        pendingKickoff = kickoff
        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.RECORD_AUDIO),
            LiveVoiceSession.REQ_MIC,
        )
    }

    private fun startSessionNow(
        wsUrl: String,
        model: String,
        instruction: String,
        authHeader: String?,
        kickoff: String?,
        result: MethodChannel.Result,
    ) {
        session?.stop()
        session = LiveVoiceSession(this, eventSink)
        session?.start(wsUrl, model, instruction, authHeader, kickoff, result)
    }

    private fun hasMicPermission(): Boolean {
        return ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) ==
            PackageManager.PERMISSION_GRANTED
    }

    private fun clearPendingStart() {
        pendingResult = null
        pendingWsUrl = null
        pendingModel = null
        pendingInstruction = null
        pendingAuthHeader = null
        pendingKickoff = null
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != LiveVoiceSession.REQ_MIC) return

        val result = pendingResult
        val wsUrl = pendingWsUrl
        val model = pendingModel
        val instruction = pendingInstruction
        val authHeader = pendingAuthHeader
        val kickoff = pendingKickoff
        clearPendingStart()

        if (result == null || wsUrl == null || model == null || instruction == null) return

        val granted = grantResults.isNotEmpty() &&
            grantResults[0] == PackageManager.PERMISSION_GRANTED
        if (granted) {
            startSessionNow(wsUrl, model, instruction, authHeader, kickoff, result)
        } else {
            result.error(
                "mic_permission",
                "Microphone permission is required. Enable it in Settings and try again.",
                null,
            )
        }
    }

    override fun onDestroy() {
        clearPendingStart()
        session?.stop()
        session = null
        super.onDestroy()
    }

    companion object {
        private const val METHOD_CHANNEL = "com.hakkiri.app/live_voice"
        private const val EVENT_CHANNEL = "com.hakkiri.app/live_voice_events"
    }
}
