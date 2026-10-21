import AVFoundation
import Flutter
import Foundation

/// Native AVSpeechSynthesizer karaoke — progress fires from willSpeakRange
/// (the range about to be spoken), not a Dart clock estimate.
final class KaraokeTtsPlugin: NSObject, FlutterPlugin, AVSpeechSynthesizerDelegate {
  private let channel: FlutterMethodChannel
  private let synthesizer = AVSpeechSynthesizer()
  private var speaking = false
  private var pendingResult: FlutterResult?

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(
      name: "com.hakkiri.app/karaoke_tts",
      binaryMessenger: messenger
    )
    super.init()
    synthesizer.delegate = self
    channel.setMethodCallHandler(handle)
  }

  static func register(with registrar: FlutterPluginRegistrar) {
    _ = KaraokeTtsPlugin(messenger: registrar.messenger())
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "speak":
      guard let args = call.arguments as? [String: Any],
            let text = args["text"] as? String,
            !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      else {
        result(FlutterError(code: "bad_args", message: "text required", details: nil))
        return
      }
      let rate = (args["rate"] as? NSNumber)?.floatValue ?? 0.44
      let pitch = (args["pitch"] as? NSNumber)?.floatValue ?? 1.0
      speak(text: text, rate: rate, pitch: pitch, result: result)
    case "stop":
      stopSpeaking()
      result(true)
    case "isSpeaking":
      result(speaking || synthesizer.isSpeaking)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func speak(text: String, rate: Float, pitch: Float, result: @escaping FlutterResult) {
    stopSpeaking()
    prepareAudioSession()

    let utterance = AVSpeechUtterance(string: text)
    // flutter_tts-style rate ~0.5 ≈ AVSpeechUtteranceDefaultSpeechRate.
    let clamped = max(0.35, min(0.55, rate))
    utterance.rate = AVSpeechUtteranceDefaultSpeechRate * (clamped / 0.5)
    utterance.pitchMultiplier = max(0.5, min(2.0, pitch))
    utterance.volume = 1.0
    utterance.preUtteranceDelay = 0
    utterance.postUtteranceDelay = 0

    if let voice = preferredEnglishVoice() {
      utterance.voice = voice
    }

    pendingResult = result
    speaking = true
    synthesizer.speak(utterance)
  }

  private func stopSpeaking() {
    if synthesizer.isSpeaking {
      synthesizer.stopSpeaking(at: .immediate)
    }
    speaking = false
    if let r = pendingResult {
      pendingResult = nil
      r(true)
    }
  }

  private func prepareAudioSession() {
    let session = AVAudioSession.sharedInstance()
    try? session.setCategory(
      .playback,
      mode: .spokenAudio,
      options: [.duckOthers, .defaultToSpeaker]
    )
    try? session.setActive(true, options: [])
  }

  private func preferredEnglishVoice() -> AVSpeechSynthesisVoice? {
    let voices = AVSpeechSynthesisVoice.speechVoices().filter {
      $0.language.lowercased().hasPrefix("en")
    }
    // Prefer enhanced / premium when installed.
    if let premium = voices.first(where: { $0.quality == .premium }) {
      return premium
    }
    if let enhanced = voices.first(where: { $0.quality == .enhanced }) {
      return enhanced
    }
    return AVSpeechSynthesisVoice(language: "en-US") ?? voices.first
  }

  // MARK: - AVSpeechSynthesizerDelegate

  func speechSynthesizer(
    _ synthesizer: AVSpeechSynthesizer,
    willSpeakRangeOfSpeechString characterRange: NSRange,
    utterance: AVSpeechUtterance
  ) {
    let ns = utterance.speechString as NSString
    guard characterRange.location != NSNotFound,
          characterRange.location + characterRange.length <= ns.length
    else { return }
    let word = ns.substring(with: characterRange)
    let payload: [String: Any] = [
      "start": characterRange.location,
      "end": characterRange.location + characterRange.length,
      "word": word,
      "text": utterance.speechString,
    ]
    DispatchQueue.main.async { [weak self] in
      self?.channel.invokeMethod("onProgress", arguments: payload)
    }
  }

  func speechSynthesizer(
    _ synthesizer: AVSpeechSynthesizer,
    didStart utterance: AVSpeechUtterance
  ) {
    DispatchQueue.main.async { [weak self] in
      self?.channel.invokeMethod("onStart", arguments: nil)
    }
  }

  func speechSynthesizer(
    _ synthesizer: AVSpeechSynthesizer,
    didFinish utterance: AVSpeechUtterance
  ) {
    speaking = false
    DispatchQueue.main.async { [weak self] in
      guard let self else { return }
      self.channel.invokeMethod("onComplete", arguments: nil)
      if let r = self.pendingResult {
        self.pendingResult = nil
        r(true)
      }
    }
  }

  func speechSynthesizer(
    _ synthesizer: AVSpeechSynthesizer,
    didCancel utterance: AVSpeechUtterance
  ) {
    speaking = false
    DispatchQueue.main.async { [weak self] in
      guard let self else { return }
      self.channel.invokeMethod("onCancel", arguments: nil)
      if let r = self.pendingResult {
        self.pendingResult = nil
        r(true)
      }
    }
  }
}
