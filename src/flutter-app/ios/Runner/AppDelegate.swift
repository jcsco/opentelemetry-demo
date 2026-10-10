import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let crashSimulatorChannel = FlutterMethodChannel(
      name: "crash_simulator",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    crashSimulatorChannel.setMethodCallHandler { call, result in
      switch call.method {
      case "triggerNativeCrash":
        result(nil)
        // Unconditional, unrecoverable trap - a real crash for testing Splunk's
        // native crash reporter, not a throwable error Flutter could catch and
        // turn into a platform-channel error.
        fatalError("Simulated native crash from Settings")
      default:
        // iOS has no ANR concept, so "triggerAnr" is intentionally unimplemented
        // here; the Settings screen only shows that control on Android.
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
