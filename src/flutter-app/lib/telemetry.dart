import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:splunk_otel_flutter/splunk_otel_flutter.dart';
import 'package:splunk_otel_flutter_session_replay/splunk_otel_flutter_session_replay.dart';

import 'gateways/session_gateway.dart';

/// Installs the Splunk RUM agent, configured from `.env` - mirroring the
/// react-native-app's `hooks/useTracer.ts`. An empty realm/token means the
/// agent buffers locally without uploading until both are configured.
Future<void> installTelemetry() async {
  await dotenv.load(
    overrideWithFiles: ['local_env/.env.local'],
    isOptional: true,
  );

  final appName = dotenv.get('SPLUNK_APP_NAME', fallback: 'flutter-app');
  final realm = dotenv.env['SPLUNK_REALM'] ?? '';
  final rumAccessToken = dotenv.env['SPLUNK_RUM_ACCESS_TOKEN'] ?? '';
  final userTrackingMode =
      dotenv.env['SPLUNK_USER_TRACKING_MODE'] == 'ANONYMOUS_TRACKING'
          ? UserTrackingMode.anonymousTracking
          : UserTrackingMode.noTracking;

  final globalAttributes = MutableAttributes(
    attributes: {
      'os.name': MutableAttributeString(value: Platform.operatingSystem),
      'os.version': MutableAttributeString(value: await _osVersion()),
      'device.id': MutableAttributeString(value: await _deviceId()),
    },
  );

  await SplunkRum.instance.install(
    agentConfiguration: AgentConfiguration(
      endpoint: realm.isNotEmpty && rumAccessToken.isNotEmpty
          ? EndpointConfiguration.forRum(
              realm: realm,
              rumAccessToken: rumAccessToken,
            )
          : null,
      appName: appName,
      deploymentEnvironment:
          dotenv.get('SPLUNK_DEPLOYMENT_ENVIRONMENT', fallback: 'local'),
      enableDebugLogging: false,
      user: UserConfiguration(trackingMode: userTrackingMode),
      globalAttributes: globalAttributes,
    ),
    moduleConfigurations: [
      CrashReportsModuleConfiguration(),
      ApplicationLifecycleModuleConfiguration(),
      NavigationModuleConfiguration(),
      InteractionsModuleConfiguration(),
      NetworkMonitorModuleConfiguration(),
      SlowRenderingModuleConfiguration(),
      // Full session capture for Digital Experience Analytics in this demo app.
      SessionReplayModuleConfiguration(samplingRate: 1.0),
      if (Platform.isAndroid) AnrModuleConfiguration(),
      // This app only ever makes network calls through Dart's `http` package
      // (see gateways/api_gateway.dart, which wraps every call in its own
      // workflow span), never through native HttpURLConnection/OkHttp/
      // URLSession directly, so native-layer HTTP instrumentation is disabled
      // to avoid double-counting the same request as both a Dart and a
      // native span.
      if (Platform.isAndroid) HttpUrlModuleConfiguration(isEnabled: false),
      if (Platform.isAndroid) OkHttp3AutoModuleConfiguration(isEnabled: false),
      if (Platform.isIOS)
        NetworkInstrumentationModuleConfiguration(isEnabled: false),
    ],
  );

  // The module configuration alone leaves replay "notStarted"; recording only
  // begins once start() is called.
  await SplunkSessionReplay.instance.start();

  // Tag every span with the app's own session id (shared concept with the web
  // frontend's session). Namespaced as `app.session.id` since `session.id` is
  // reserved by Splunk RUM for its own session id.
  final userId = await sessionGateway.getUserId();
  await SplunkRum.instance.globalAttributes.setString(
    key: 'app.session.id',
    value: userId,
  );
}

Future<String> _osVersion() async {
  final deviceInfo = DeviceInfoPlugin();
  if (Platform.isAndroid) {
    return (await deviceInfo.androidInfo).version.release;
  }
  if (Platform.isIOS) {
    return (await deviceInfo.iosInfo).systemVersion;
  }
  return Platform.operatingSystemVersion;
}

Future<String> _deviceId() async {
  final deviceInfo = DeviceInfoPlugin();
  if (Platform.isAndroid) {
    return (await deviceInfo.androidInfo).id;
  }
  if (Platform.isIOS) {
    return (await deviceInfo.iosInfo).identifierForVendor ?? '';
  }
  return '';
}
