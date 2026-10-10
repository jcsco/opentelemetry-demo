import 'package:flutter/services.dart';

/// Bridges to a native crash/ANR trigger, ported from the react-native-app's
/// `modules/crash-simulator` Expo module. Backed by a `MethodChannel` handled
/// natively in `android/.../MainActivity.kt` and `ios/Runner/AppDelegate.swift`
/// rather than a Dart-only implementation, since both triggers need to
/// escape Flutter's own error handling and genuinely crash/hang the host
/// platform thread the same way the original native module does.
class CrashSimulator {
  static const _channel = MethodChannel('crash_simulator');

  /// Terminates the app with a real native crash (Android: throws on the
  /// main thread; iOS: calls `fatalError`).
  static Future<void> triggerNativeCrash() async {
    await _channel.invokeMethod<void>('triggerNativeCrash');
  }

  /// **Android only.** Blocks the UI thread for ~6 seconds to trip Android's
  /// ANR watchdog. iOS has no ANR concept, so this is not implemented there.
  static Future<void> triggerAnr() async {
    await _channel.invokeMethod<void>('triggerAnr');
  }
}
