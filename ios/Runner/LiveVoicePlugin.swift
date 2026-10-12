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
  private let audioQueue = DispatchQueue(label: "com.hakkiri.app.livevoice.audio")

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
        self.start(wsUrl: wsUrl, model: model, systemInstruction: instruction, result: result)
      case "stop":
        self.stop()
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

  private func start(wsUrl: String, model: String, systemInstruction: String, result: @escaping FlutterResult) {
    stop()
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

      let session = URLSession(configuration: .default)
      self.urlSession = session
      let task = session.webSocketTask(with: url)
      self.webSocketTask = task
      self.isRunning = true
      task.resume()

      let setup: [String: Any] = [
        "setup": [
          "model": "models/\(model)",
          "responseModalities": ["AUDIO"],
          "inputAudioTranscription": [:] as [String: Any],
          "outputAudioTranscription": [:] as [String: Any],
          "systemInstruction": [
            "parts": [["text": systemInstruction]],
          ],
        ],
      ]
      self.sendJSON(setup) {
        self.emit(["type": "status", "message": "Connected", "listening": true])
        self.startMic()
        self.receiveLoop()
        DispatchQueue.main.async { result(true) }
      }
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
      try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetooth])
      try session.setActive(true)

      let engine = AVAudioEngine()
      let player = AVAudioPlayerNode()
      engine.attach(player)
      let main = engine.mainMixerNode
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
        let byteCount = Int(outBuffer.frameLength) * MemoryLayout<Int16>.size
        let data = Data(bytes: outBuffer.int16ChannelData![0], count: byteCount)
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
        self.stop()
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
    guard
      let data = text.data(using: .utf8),
      let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
      let serverContent = root["serverContent"] as? [String: Any]
    else { return }

    if let input = serverContent["inputTranscription"] as? [String: Any],
       let t = input["text"] as? String, !t.isEmpty {
      emit(["type": "user_transcript", "text": t])
    }
    if let output = serverContent["outputTranscription"] as? [String: Any],
       let t = output["text"] as? String, !t.isEmpty {
      emit(["type": "model_transcript", "text": t])
    }
    if let modelTurn = serverContent["modelTurn"] as? [String: Any],
       let parts = modelTurn["parts"] as? [[String: Any]] {
      for part in parts {
        guard
          let inline = part["inlineData"] as? [String: Any],
          let b64 = inline["data"] as? String,
          let pcm = Data(base64Encoded: b64)
        else { continue }
        playPCM(pcm)
      }
    }
  }

  private func playPCM(_ data: Data) {
    audioQueue.async { [weak self] in
      guard let self, let player = self.playerNode else { return }
      let frameCount = data.count / MemoryLayout<Int16>.size
      guard frameCount > 0 else { return }
      guard let format = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 24000, channels: 1, interleaved: true),
            let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount))
      else { return }
      buffer.frameLength = AVAudioFrameCount(frameCount)
      data.withUnsafeBytes { raw in
        if let base = raw.bindMemory(to: Int16.self).baseAddress {
          buffer.int16ChannelData![0].update(from: base, count: frameCount)
        }
      }
      player.scheduleBuffer(buffer, completionHandler: nil)
      if !player.isPlaying { player.play() }
    }
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

  private func stop() {
    isRunning = false
    engine?.inputNode.removeTap(onBus: 0)
    engine?.stop()
    playerNode?.stop()
    engine = nil
    playerNode = nil
    webSocketTask?.cancel(with: .goingAway, reason: nil)
    webSocketTask = nil
    urlSession?.invalidateAndCancel()
    urlSession = nil
    try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    emit(["type": "closed", "message": "stopped"])
  }
}
