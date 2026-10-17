import AVFoundation
import Flutter
import Foundation

final class LiveVoicePlugin: NSObject, FlutterStreamHandler {
  private let methodChannel: FlutterMethodChannel
  private let eventChannel: FlutterEventChannel
  private var eventSink: FlutterEventSink?

  private var webSocketTask: URLSessionWebSocketTask?
  private var urlSession: URLSession?
  private var engine: AVAudioEngine?
  private var playerNode: AVAudioPlayerNode?
  private var isRunning = false
  private var setupComplete = false
  private var pendingStartResult: FlutterResult?
  private var setupTimeoutWork: DispatchWorkItem?
  private var kickoffText: String = ""
  private var lastSpeakingEmitMs: TimeInterval = 0
  private var lastSpeakingState: Bool?
  /// False while coach audio plays — stops speaker echo becoming "user" text.
  private var micOpen = false
  private var openMicWork: DispatchWorkItem?
  private var audioIdleWork: DispatchWorkItem?
  /// Scheduled coach PCM buffers still in the player queue (iOS plays ahead of network).
  private var pendingCoachBuffers = 0
  private var scheduledAudioMs: Double = 0
  private var playedAudioMs: Double = 0
  private let bufferLock = NSLock()
  /// Gemini said the model turn is done — wait for playback drain before opening mic.
  private var coachTurnComplete = false
  private let audioQueue = DispatchQueue(label: "com.hakkiri.app.livevoice.audio")

  private func bumpPendingBuffers(_ delta: Int) -> Int {
    bufferLock.lock()
    pendingCoachBuffers = max(0, pendingCoachBuffers + delta)
    let value = pendingCoachBuffers
    bufferLock.unlock()
    return value
  }

  private func pendingBuffers() -> Int {
    bufferLock.lock()
    let value = pendingCoachBuffers
    bufferLock.unlock()
    return value
  }

  private func resetPendingBuffers() {
    bufferLock.lock()
    pendingCoachBuffers = 0
    scheduledAudioMs = 0
    playedAudioMs = 0
    bufferLock.unlock()
  }

  private func noteAudioScheduled(ms: Double) {
    bufferLock.lock()
    scheduledAudioMs += ms
    let played = playedAudioMs
    let scheduled = scheduledAudioMs
    bufferLock.unlock()
    emitCoachPlayback(played: played, scheduled: scheduled)
  }

  private func noteAudioPlayed(ms: Double) {
    bufferLock.lock()
    playedAudioMs += ms
    let played = playedAudioMs
    let scheduled = scheduledAudioMs
    bufferLock.unlock()
    emitCoachPlayback(played: played, scheduled: scheduled)
  }

  private func emitCoachPlayback(played: Double, scheduled: Double) {
    emit([
      "type": "coach_playback",
      "played_ms": played,
      "scheduled_ms": scheduled,
    ])
  }

  private func succeedPending() {
    guard let pendingStartResult else { return }
    self.pendingStartResult = nil
    DispatchQueue.main.async { pendingStartResult(true) }
  }

  private func failPending(code: String, message: String) {
    guard let pendingStartResult else { return }
    self.pendingStartResult = nil
    DispatchQueue.main.async {
      pendingStartResult(FlutterError(code: code, message: message, details: nil))
    }
  }

  init(messenger: FlutterBinaryMessenger) {
    methodChannel = FlutterMethodChannel(name: "com.hakkiri.app/live_voice", binaryMessenger: messenger)
    eventChannel = FlutterEventChannel(name: "com.hakkiri.app/live_voice_events", binaryMessenger: messenger)
    super.init()
    eventChannel.setStreamHandler(self)
    methodChannel.setMethodCallHandler { [weak self] call, result in
      guard let self else { return }
      switch call.method {
      case "start":
        guard
          let args = call.arguments as? [String: Any],
          let wsUrl = args["ws_url"] as? String,
          !wsUrl.isEmpty
        else {
          result(FlutterError(code: "bad_args", message: "ws_url is required", details: nil))
          return
        }
        let model = (args["model"] as? String) ?? "gemini-3.8-live"
        let instruction = (args["system_instruction"] as? String) ?? ""
        let authHeader = args["auth_header"] as? String
        let kickoff = args["kickoff"] as? String
        self.start(
          wsUrl: wsUrl,
          model: model,
          systemInstruction: instruction,
          authHeader: authHeader,
          kickoff: kickoff,
          result: result
        )
      case "stop":
        self.stop(failIfPending: true)
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }

  private func emit(_ payload: [String: Any]) {
    DispatchQueue.main.async { [weak self] in
      self?.eventSink?(payload)
    }
  }

  private func start(
    wsUrl: String,
    model: String,
    systemInstruction: String,
    authHeader: String?,
    kickoff: String?,
    result: @escaping FlutterResult
  ) {
    stop(failIfPending: true)
    requestMic { [weak self] granted in
      guard let self else { return }
      guard granted else {
        result(FlutterError(code: "mic_permission", message: "Microphone permission is required.", details: nil))
        return
      }
      guard let url = URL(string: wsUrl) else {
        result(FlutterError(code: "bad_args", message: "Invalid ws_url", details: nil))
        return
      }

      var request = URLRequest(url: url)
      if let authHeader, !authHeader.isEmpty {
        request.setValue(authHeader, forHTTPHeaderField: "Authorization")
      }

      let session = URLSession(configuration: .default)
      self.urlSession = session
      let task = session.webSocketTask(with: request)
      self.webSocketTask = task
      self.isRunning = true
      self.micOpen = false
      self.kickoffText = (kickoff ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
      task.resume()

      // Start receive loop first — mic starts only after setupComplete from Gemini.
      self.pendingStartResult = result
      self.setupComplete = false
      self.receiveLoop()
      let setup: [String: Any] = [
        "setup": [
          "model": "models/\(model)",
          "generationConfig": [
            "responseModalities": ["AUDIO"],
          ],
          // Wait through natural pauses — don't cut the user off mid-answer.
          "realtimeInputConfig": [
            "automaticActivityDetection": [
              "disabled": false,
              "startOfSpeechSensitivity": "START_SENSITIVITY_LOW",
              "endOfSpeechSensitivity": "END_SENSITIVITY_LOW",
              "prefixPaddingMs": 40,
              "silenceDurationMs": 900,
            ],
          ],
          "inputAudioTranscription": [:] as [String: Any],
          "outputAudioTranscription": [:] as [String: Any],
          "systemInstruction": [
            "parts": [["text": systemInstruction]],
          ],
        ],
      ]
      self.emit(["type": "status", "message": "Connecting…", "listening": false])
      self.sendJSON(setup)

      let timeout = DispatchWorkItem { [weak self] in
        guard let self, self.isRunning, !self.setupComplete else { return }
        self.failPending(
          code: "setup_timeout",
          message: "Live coach did not finish setup. Try again."
        )
        self.stop(failIfPending: false)
      }
      self.setupTimeoutWork = timeout
      DispatchQueue.main.asyncAfter(deadline: .now() + 12, execute: timeout)
    }
  }

  private func requestMic(completion: @escaping (Bool) -> Void) {
    switch AVAudioSession.sharedInstance().recordPermission {
    case .granted:
      completion(true)
    case .denied:
      completion(false)
    case .undetermined:
      AVAudioSession.sharedInstance().requestRecordPermission { granted in
        DispatchQueue.main.async { completion(granted) }
      }
    @unknown default:
      completion(false)
    }
  }

  private func startMic() {
    do {
      let session = AVAudioSession.sharedInstance()
      // voiceChat enables hardware echo cancellation so coach speaker audio
      // is not transcribed as the user. defaultToSpeaker keeps it loud enough.
      try session.setCategory(
        .playAndRecord,
        mode: .voiceChat,
        options: [.defaultToSpeaker, .allowBluetooth]
      )
      try session.overrideOutputAudioPort(.speaker)
      try session.setActive(true)
      try? session.setPreferredIOBufferDuration(0.02)

      let engine = AVAudioEngine()
      let player = AVAudioPlayerNode()
      engine.attach(player)
      let main = engine.mainMixerNode
      main.outputVolume = 1.0
      player.volume = 1.0
      let outFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 24000, channels: 1, interleaved: true)!
      engine.connect(player, to: main, format: outFormat)

      let input = engine.inputNode
      let inputFormat = input.outputFormat(forBus: 0)
      let targetFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 16000, channels: 1, interleaved: true)!
      let converter = AVAudioConverter(from: inputFormat, to: targetFormat)

      input.installTap(onBus: 0, bufferSize: 2048, format: inputFormat) { [weak self] buffer, _ in
        guard let self, self.isRunning, let converter else { return }
        let capacity = AVAudioFrameCount(Double(buffer.frameLength) * 16000.0 / inputFormat.sampleRate) + 32
        guard let outBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: capacity) else { return }
        var error: NSError?
        let status = converter.convert(to: outBuffer, error: &error) { _, outStatus in
          outStatus.pointee = .haveData
          return buffer
        }
        if status == .error || outBuffer.frameLength == 0 { return }
        // Drain converter always; only stream while it's the user's turn.
        guard self.micOpen else { return }
        let byteCount = Int(outBuffer.frameLength) * MemoryLayout<Int16>.size
        let data = Data(bytes: outBuffer.int16ChannelData![0], count: byteCount)
        self.maybeEmitSpeaking(pcm: data)
        let b64 = data.base64EncodedString()
        let payload: [String: Any] = [
          "realtimeInput": [
            "audio": [
              "data": b64,
              "mimeType": "audio/pcm;rate=16000",
            ],
          ],
        ]
        self.sendJSON(payload)
      }

      try engine.start()
      player.play()
      self.engine = engine
      self.playerNode = player
    } catch {
      emit(["type": "error", "message": error.localizedDescription])
    }
  }

  private func receiveLoop() {
    webSocketTask?.receive { [weak self] result in
      guard let self, self.isRunning else { return }
      switch result {
      case .failure(let error):
        self.emit(["type": "error", "message": error.localizedDescription])
        self.failPending(code: "ws_failed", message: error.localizedDescription)
        self.stop(failIfPending: false)
      case .success(let message):
        switch message {
        case .string(let text):
          self.handleServerMessage(text)
        case .data(let data):
          if let text = String(data: data, encoding: .utf8) {
            self.handleServerMessage(text)
          }
        @unknown default:
          break
        }
        self.receiveLoop()
      }
    }
  }

  private func handleServerMessage(_ text: String) {
    guard isRunning else { return }
    guard
      let data = text.data(using: .utf8),
      let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    else { return }

    if root["setupComplete"] != nil {
      setupComplete = true
      setupTimeoutWork?.cancel()
      succeedPending()
      coachTurnComplete = false
      resetPendingBuffers()
      muteMicForCoach()
      emit(["type": "status", "message": "Coach is speaking…", "listening": true])
      sendKickoff()
      if engine == nil {
        startMic()
      }
      return
    }

    if let err = root["error"] as? [String: Any] {
      let msg = (err["message"] as? String)
        ?? (err["status"] as? String)
        ?? "Live voice failed."
      emit(["type": "error", "message": msg])
      failPending(code: "gemini_error", message: msg)
      stop(failIfPending: false)
      return
    }

    guard let serverContent = root["serverContent"] as? [String: Any] else { return }

    if let output = serverContent["outputTranscription"] as? [String: Any],
       let t = output["text"] as? String, !t.isEmpty {
      if micOpen {
        coachTurnComplete = false
      }
      muteMicForCoach()
      emit(["type": "model_transcript", "text": t])
    }
    if let modelTurn = serverContent["modelTurn"] as? [String: Any],
       let parts = modelTurn["parts"] as? [[String: Any]] {
      for part in parts {
        let inline = (part["inlineData"] as? [String: Any])
          ?? (part["inline_data"] as? [String: Any])
        guard
          isRunning,
          let inline,
          let b64 = inline["data"] as? String,
          let pcm = Data(base64Encoded: b64)
        else { continue }
        onCoachAudioPlaying()
        playPCM(pcm)
      }
    }
    // Never surface "user" text while coach audio is still playing / queued —
    // iOS speaker echo otherwise lands in the user bubble.
    if let input = serverContent["inputTranscription"] as? [String: Any],
       let t = input["text"] as? String,
       !t.isEmpty,
       micOpen,
       coachTurnComplete,
       pendingBuffers() <= 0 {
      emit(["type": "user_transcript", "text": t])
    }
    if let turnComplete = serverContent["turnComplete"] as? Bool, turnComplete {
      coachTurnComplete = true
      emit(["type": "turn_complete"])
      // Do NOT open mic yet — wait until scheduled PCM actually finishes playing.
      maybeOpenMicAfterCoachDrain()
    }
  }

  private func muteMicForCoach() {
    let wasOpen = micOpen
    micOpen = false
    openMicWork?.cancel()
    openMicWork = nil
    audioIdleWork?.cancel()
    audioIdleWork = nil
    if wasOpen {
      lastSpeakingState = false
      emit(["type": "user_speaking", "speaking": false, "level": 0])
    }
  }

  private func onCoachAudioPlaying() {
    // New coach reply after the user was listening — wait for a fresh turnComplete.
    // Trailing PCM after turnComplete must NOT clear the flag (or mic never reopens).
    if micOpen {
      coachTurnComplete = false
      resetPendingBuffers()
    }
    muteMicForCoach()
    // iOS schedules PCM ahead of real speaker playback — never open mic on
    // network-idle gaps (that was causing echo → fake user transcripts).
    audioIdleWork?.cancel()
    audioIdleWork = nil
  }

  /// Open mic only after Gemini turnComplete AND player queue has drained.
  private func maybeOpenMicAfterCoachDrain() {
    guard isRunning, coachTurnComplete, pendingBuffers() <= 0 else { return }
    // Extra tail so room echo / Bluetooth latency does not hit the STT.
    scheduleMicForUser(delay: 0.55)
  }

  private func scheduleMicForUser(delay: TimeInterval = 0.55) {
    openMicWork?.cancel()
    audioIdleWork?.cancel()
    audioIdleWork = nil
    let work = DispatchWorkItem { [weak self] in
      guard let self, self.isRunning else { return }
      // Re-check drain in case more audio arrived while waiting.
      guard self.coachTurnComplete, self.pendingBuffers() <= 0 else { return }
      self.micOpen = true
      self.emit([
        "type": "status",
        "message": "Your turn — speak naturally",
        "listening": true,
      ])
    }
    openMicWork = work
    DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
  }

  // voiceChat AEC is a bit quieter than spokenAudio — keep a stronger boost.
  private func boostPCM(_ data: Data, gain: Float = 2.15) -> Data {
    var samples = [Int16](repeating: 0, count: data.count / MemoryLayout<Int16>.size)
    _ = samples.withUnsafeMutableBytes { dst in
      data.copyBytes(to: dst)
    }
    for i in 0..<samples.count {
      let v = Float(samples[i]) * gain
      samples[i] = Int16(max(Float(Int16.min), min(Float(Int16.max), v.rounded())))
    }
    return samples.withUnsafeBufferPointer { Data(buffer: $0) }
  }

  private func playPCM(_ data: Data) {
    audioQueue.async { [weak self] in
      guard let self, self.isRunning, let player = self.playerNode else { return }
      let boosted = self.boostPCM(data)
      let frameCount = boosted.count / MemoryLayout<Int16>.size
      guard frameCount > 0 else { return }
      guard let format = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 24000, channels: 1, interleaved: true),
            let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount))
      else { return }
      buffer.frameLength = AVAudioFrameCount(frameCount)
      boosted.withUnsafeBytes { raw in
        if let base = raw.bindMemory(to: Int16.self).baseAddress {
          buffer.int16ChannelData![0].update(from: base, count: frameCount)
        }
      }
      guard self.isRunning else { return }
      // 24 kHz mono PCM → duration the speaker will actually take.
      let durationMs = Double(frameCount) / 24.0
      _ = self.bumpPendingBuffers(1)
      self.noteAudioScheduled(ms: durationMs)
      player.volume = 1.0
      player.scheduleBuffer(buffer) { [weak self] in
        guard let self else { return }
        _ = self.bumpPendingBuffers(-1)
        self.noteAudioPlayed(ms: durationMs)
        DispatchQueue.main.async {
          self.maybeOpenMicAfterCoachDrain()
        }
      }
      if !player.isPlaying { player.play() }
    }
  }

  private func maybeEmitSpeaking(pcm: Data) {
    let sampleCount = pcm.count / MemoryLayout<Int16>.size
    guard sampleCount > 0 else { return }
    var sum: Double = 0
    pcm.withUnsafeBytes { raw in
      let samples = raw.bindMemory(to: Int16.self)
      for i in 0..<sampleCount {
        let v = Double(samples[i])
        sum += v * v
      }
    }
    let rms = (sum / Double(sampleCount)).squareRoot()
    // Lower threshold so the "You …" dots appear as soon as you start talking.
    let speaking = rms > 480
    let now = Date().timeIntervalSince1970 * 1000
    let stateChanged = lastSpeakingState != speaking
    // Fire immediately when speech starts; throttle only while holding state.
    let minGap: TimeInterval
    if stateChanged && speaking {
      minGap = 0
    } else if stateChanged {
      minGap = 80
    } else {
      minGap = 280
    }
    guard now - lastSpeakingEmitMs >= minGap else { return }
    lastSpeakingEmitMs = now
    lastSpeakingState = speaking
    emit(["type": "user_speaking", "speaking": speaking, "level": rms])
  }

  private func sendKickoff() {
    let text = kickoffText.isEmpty
      ? "Please greet me briefly as Hakkiri Live Coach, then ask the practice question and wait for my spoken answer."
      : kickoffText
    let payload: [String: Any] = [
      "clientContent": [
        "turns": [
          [
            "role": "user",
            "parts": [["text": text]],
          ],
        ],
        "turnComplete": true,
      ],
    ]
    sendJSON(payload)
  }

  private func sendJSON(_ object: [String: Any], completion: (() -> Void)? = nil) {
    guard
      let data = try? JSONSerialization.data(withJSONObject: object),
      let text = String(data: data, encoding: .utf8)
    else { return }
    webSocketTask?.send(.string(text)) { _ in
      completion?()
    }
  }

  private func stop(failIfPending: Bool) {
    // Flip first so in-flight receive / playPCM cannot keep scheduling audio.
    isRunning = false
    micOpen = false
    coachTurnComplete = false
    resetPendingBuffers()
    setupTimeoutWork?.cancel()
    setupTimeoutWork = nil
    openMicWork?.cancel()
    openMicWork = nil
    audioIdleWork?.cancel()
    audioIdleWork = nil
    if failIfPending && !setupComplete {
      failPending(code: "stopped", message: "Live session stopped before setup finished.")
    } else {
      pendingStartResult = nil
    }
    webSocketTask?.cancel(with: .goingAway, reason: nil)
    webSocketTask = nil
    urlSession?.invalidateAndCancel()
    urlSession = nil
    // Kill playback on the same queue that schedules buffers (instant silence).
    audioQueue.sync {
      self.playerNode?.volume = 0
      self.playerNode?.stop()
      self.playerNode?.reset()
      self.engine?.inputNode.removeTap(onBus: 0)
      self.engine?.stop()
      self.playerNode = nil
      self.engine = nil
    }
    try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    emit(["type": "closed", "message": "stopped"])
  }
}
