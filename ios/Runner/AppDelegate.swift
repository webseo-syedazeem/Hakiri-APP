import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var liveVoicePlugin: LiveVoicePlugin?
  private var karaokeTtsPlugin: KaraokeTtsPlugin?
  private var drillRecorderPlugin: DrillRecorderPlugin?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Call super first so Firebase / Flutter method swizzling is ready,
    // then register for APNs (required before FCM getToken on iOS).
    let ok = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    application.registerForRemoteNotifications()
    return ok
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    let hex = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    NSLog("APNs device token registered (%d bytes): %@…", deviceToken.count, String(hex.prefix(16)))
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
    NSLog("APNs registration FAILED: %@", error.localizedDescription)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "LiveVoicePlugin") {
      liveVoicePlugin = LiveVoicePlugin(messenger: registrar.messenger())
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "KaraokeTtsPlugin") {
      karaokeTtsPlugin = KaraokeTtsPlugin(messenger: registrar.messenger())
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "DrillRecorderPlugin") {
      drillRecorderPlugin = DrillRecorderPlugin(messenger: registrar.messenger())
    }
  }
}
