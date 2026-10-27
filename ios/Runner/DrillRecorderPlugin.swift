import AVFoundation
import Flutter
import Foundation

/// Native AVAudioRecorder for Think Fast / drills.
/// Avoids Flutter `record` + path_provider FFI issues that produce silent iOS clips.
final class DrillRecorderPlugin: NSObject, FlutterStreamHandler {
  private let methodChannel: FlutterMethodChannel
  private let amplitudeChannel: FlutterEventChannel
  private var amplitudeSink: FlutterEventSink?

  private var recorder: AVAudioRecorder?
  private var meterTimer: Timer?
  private var outputURL: URL?

  init(messenger: FlutterBinaryMessenger) {
    methodChannel = FlutterMethodChannel(
      name: "com.hakkiri.app/drill_recorder",
      binaryMessenger: messenger
    )
    amplitudeChannel = FlutterEventChannel(
      name: "com.hakkiri.app/drill_recorder/amplitude",
      binaryMessenger: messenger
    )
    super.init()
    methodChannel.setMethodCallHandler(handle)
    amplitudeChannel.setStreamHandler(self)
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    amplitudeSink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    amplitudeSink = nil
    return nil
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "hasPermission":
      requestMic { granted in result(granted) }
    case "start":
      start(result: result)
    case "stop":
      stop(result: result)
    case "isRecording":
      result(recorder?.isRecording == true)
    case "cancel":
      cancel(result: result)
    default:
      result(FlutterMethodNotImplemented)
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

  private func configureSession() throws {
    let session = AVAudioSession.sharedInstance()
    // PlayAndRecord so prior TTS/playback category does not leave us in
    // playback-only (which yields silent m4a files).
    try session.setCategory(
      .playAndRecord,
      mode: .spokenAudio,
      options: [.defaultToSpeaker, .allowBluetooth, .mixWithOthers]
    )
    try session.overrideOutputAudioPort(.speaker)
    try session.setActive(true, options: [])
  }

  private func start(result: @escaping FlutterResult) {
    requestMic { [weak self] granted in
      guard let self else { return }
      guard granted else {
        result(FlutterError(code: "mic_denied", message: "Microphone permission denied", details: nil))
        return
      }
      do {
        try self.configureSession()

        let dir = FileManager.default.temporaryDirectory
        let name = "hakkiri_drill_\(Int(Date().timeIntervalSince1970 * 1000)).m4a"
        let url = dir.appendingPathComponent(name)
        self.outputURL = url

        // Do NOT set AVEncoderBitRateKey — known to create empty AAC files on iOS.
        let settings: [String: Any] = [
          AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
          AVSampleRateKey: 16_000,
          AVNumberOfChannelsKey: 1,
          AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        ]

        let rec = try AVAudioRecorder(url: url, settings: settings)
        rec.isMeteringEnabled = true
        rec.prepareToRecord()
        guard rec.record() else {
          result(FlutterError(code: "start_failed", message: "AVAudioRecorder.record() returned false", details: nil))
          return
        }
        self.recorder = rec
        self.startMetering()
        NSLog("[DrillRecorder] started → %@", url.path)
        result(["path": url.path])
      } catch {
        NSLog("[DrillRecorder] start error: %@", error.localizedDescription)
        result(FlutterError(code: "start_failed", message: error.localizedDescription, details: nil))
      }
    }
  }

  private func startMetering() {
    meterTimer?.invalidate()
    meterTimer = Timer.scheduledTimer(withTimeInterval: 0.055, repeats: true) { [weak self] _ in
      guard let self, let rec = self.recorder, rec.isRecording else { return }
      rec.updateMeters()
      // averagePower is ~ -160…0 dB
      let db = Double(rec.averagePower(forChannel: 0))
      let normalized = max(0.0, min(1.0, (db + 50.0) / 50.0))
      self.amplitudeSink?(normalized)
    }
  }

  private func stopMetering() {
    meterTimer?.invalidate()
    meterTimer = nil
  }

  private func stop(result: @escaping FlutterResult) {
    stopMetering()
    guard let rec = recorder else {
      result(["path": outputURL?.path as Any, "bytes": 0])
      return
    }
    let path = rec.url.path
    rec.stop()
    recorder = nil

    var bytes = 0
    if let attrs = try? FileManager.default.attributesOfItem(atPath: path),
       let size = attrs[.size] as? NSNumber {
      bytes = size.intValue
    }
    NSLog("[DrillRecorder] stopped path=%@ bytes=%d", path, bytes)
    result(["path": path, "bytes": bytes])
  }

  private func cancel(result: @escaping FlutterResult) {
    stopMetering()
    if let rec = recorder {
      let path = rec.url.path
      rec.stop()
      recorder = nil
      try? FileManager.default.removeItem(atPath: path)
    } else if let url = outputURL {
      try? FileManager.default.removeItem(at: url)
    }
    outputURL = nil
    result(nil)
  }
}
