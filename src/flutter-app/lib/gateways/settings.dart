import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The frontend's reverse-proxy port, as configured for the demo's
/// `frontend-proxy` service (matches `EXPO_PUBLIC_FRONTEND_PROXY_PORT` in the
/// react-native-app's `.env`).
const _frontendProxyPort = 8080;

const _frontendProxyUrlKey = 'frontend_proxy_url';

/// Resolves "localhost" for the current platform/device, accounting for the
/// well-known Android-emulator loopback quirk (`10.0.2.2` instead of
/// `localhost`). iOS simulators and physical devices use `localhost` as-is -
/// on a physical device this is intentionally wrong, which is exactly why the
/// Settings screen exists to override it.
Future<String> _resolveLocalhost() async {
  if (!Platform.isAndroid) {
    return 'localhost';
  }

  final androidInfo = await DeviceInfoPlugin().androidInfo;
  return androidInfo.isPhysicalDevice ? 'localhost' : '10.0.2.2';
}

/// Gets the configured "Frontend Proxy URL", defaulting to the local demo
/// stack's frontend-proxy if the user hasn't overridden it in Settings.
Future<String> getFrontendProxyUrl() async {
  final prefs = await SharedPreferences.getInstance();
  final override = prefs.getString(_frontendProxyUrlKey);
  if (override != null && override.isNotEmpty) {
    return override;
  }

  final localhost = await _resolveLocalhost();
  return 'http://$localhost:$_frontendProxyPort';
}

Future<void> setFrontendProxyUrl(String url) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_frontendProxyUrlKey, url);
}
