import 'dart:io';

import 'package:splunk_otel_flutter/splunk_otel_flutter.dart';

import 'gateways/session_gateway.dart';
import 'gateways/settings.dart';

/// Builds the OTLP/HTTP traces endpoint for the given frontend proxy base
/// URL. Traces are routed through the same proxy as all other API calls,
/// exactly like the react-native-app's `useTracer` hook.
///
/// The Android agent's `EndpointConfiguration` rejects a custom trace URL
/// with no `auth` query parameter (it otherwise assumes a Splunk Observability
/// Cloud realm/token pair was meant to be used) and silently disables export
/// instead of sending. The demo's collector doesn't check this value, so a
/// placeholder satisfies the native validation without requiring real auth.
Uri _traceEndpoint(String proxyUrl) =>
    Uri.parse('$proxyUrl/otlp-http/v1/traces?auth=unauthenticated');

/// Installs the Splunk RUM agent, pointed at whatever Frontend Proxy URL is
/// currently configured (see `gateways/settings.dart`). Stamps a `session.id`
/// global attribute with this install's anonymous user id, mirroring the
/// react-native-app's `SessionIdProcessor` (which tags every span with the
/// same id used to correlate the mobile session with backend traces).
Future<void> installTelemetry() async {
  final proxyUrl = await getFrontendProxyUrl();
  final userId = await sessionGateway.getUserId();

  await SplunkRum.instance.install(
    agentConfiguration: AgentConfiguration(
      endpoint: EndpointConfiguration.forTraces(
        traceEndpoint: _traceEndpoint(proxyUrl),
      ),
      appName: 'flutter-app',
      deploymentEnvironment: 'demo',
    ),
    moduleConfigurations: [
      CrashReportsModuleConfiguration(),
      NavigationModuleConfiguration(),
      NetworkMonitorModuleConfiguration(),
      SlowRenderingModuleConfiguration(),
      if (Platform.isAndroid) AnrModuleConfiguration(),
      if (Platform.isAndroid) OkHttp3AutoModuleConfiguration(),
      if (Platform.isIOS) NetworkInstrumentationModuleConfiguration(),
    ],
  );

  await SplunkRum.instance.globalAttributes.setString(
    key: 'session.id',
    value: userId,
  );
}

/// Re-points the already-installed agent at a new Frontend Proxy URL. Called
/// when the user applies a new value on the Settings screen, mirroring the
/// react-native-app's `trace.disable()` + rebuild flow, but using the agent's
/// own supported runtime override instead of tearing down the SDK.
Future<void> reconfigureTelemetry(String proxyUrl) async {
  await SplunkRum.instance.preferences.setEndpointConfiguration(
    endpoint: EndpointConfiguration.forTraces(
      traceEndpoint: _traceEndpoint(proxyUrl),
    ),
  );
}
