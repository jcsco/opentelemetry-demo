// Copyright The OpenTelemetry Authors
// SPDX-License-Identifier: Apache-2.0
import {
  AnrModuleConfiguration,
  ApplicationLifecycleModuleConfiguration,
  CrashReportsModuleConfiguration,
  HttpURLModuleConfiguration,
  InteractionsModuleConfiguration,
  NavigationModuleConfiguration,
  NetworkInstrumentationModuleConfiguration,
  NetworkMonitorModuleConfiguration,
  OkHttp3AutoModuleConfiguration,
  SessionReplayModuleConfiguration,
  SlowRenderingModuleConfiguration,
  SplunkRum,
  StartupModuleConfiguration,
} from "@splunk/otel-react-native";
import type {
  AgentConfiguration,
  ModuleConfiguration,
} from "@splunk/otel-react-native";
import { useEffect, useState } from "react";
import { getSystemVersion, getUniqueIdSync } from "react-native-device-info";
import { Platform } from "react-native";
import SessionGateway from "@/gateways/Session.gateway";

const realm = process.env.EXPO_PUBLIC_SPLUNK_REALM;
const rumAccessToken = process.env.EXPO_PUBLIC_SPLUNK_RUM_ACCESS_TOKEN;
const userTrackingMode =
  process.env.EXPO_PUBLIC_SPLUNK_USER_TRACKING_MODE === "ANONYMOUS_TRACKING"
    ? "ANONYMOUS_TRACKING"
    : "NO_TRACKING";

const initSplunkRum = async () => {
  const config: AgentConfiguration = {
    appName: "react-native-app",
    deploymentEnvironment:
      process.env.EXPO_PUBLIC_SPLUNK_DEPLOYMENT_ENVIRONMENT || "local",
    enableDebugLogging: __DEV__,
    // Left undefined (buffering, no upload) until a realm/token is configured in .env.
    endpoint: realm && rumAccessToken ? { realm, rumAccessToken } : undefined,
    user: { trackingMode: userTrackingMode },
    globalAttributes: {
      "os.name": Platform.OS,
      "os.version": getSystemVersion(),
      "device.id": getUniqueIdSync(),
    },
  };

  const modules: ModuleConfiguration[] = [
    new CrashReportsModuleConfiguration(true),
    new ApplicationLifecycleModuleConfiguration(true),
    new StartupModuleConfiguration(true),
    new AnrModuleConfiguration(true),
    new SlowRenderingModuleConfiguration(true),
    new InteractionsModuleConfiguration(true),
    new NetworkMonitorModuleConfiguration(true),
    // Fetch/XMLHttpRequest instrumentation. This app only ever makes network
    // calls through JS (see utils/Request.ts), never through native
    // HttpURLConnection/OkHttp directly, so those native-layer HTTP modules are
    // explicitly disabled below to avoid double-counting the same request as
    // both a JS and a native span.
    new NetworkInstrumentationModuleConfiguration(true),
    new HttpURLModuleConfiguration(false),
    new OkHttp3AutoModuleConfiguration(false),
    // Screen names come from the expo-router integration wired up in app/_layout.tsx,
    // so native automatic tracking is disabled here to avoid reporting host view
    // controller/Activity names instead of JS routes.
    new NavigationModuleConfiguration(true, false),
    // Full session capture for Digital Experience Analytics in this sample app.
    new SessionReplayModuleConfiguration(true, 1.0),
  ];

  await SplunkRum.install(config, modules);

  // Tag every span with the app's own session id (shared concept with the web
  // frontend's session). Namespaced as `app.session.id` since `session.id` is
  // reserved by Splunk RUM for its own session id.
  const { userId } = await SessionGateway.getSession();
  await SplunkRum.instance.globalAttributes.setString("app.session.id", userId);
};

export interface TracerResult {
  loaded: boolean;
}

export const useTracer = (): TracerResult => {
  const [loaded, setLoaded] = useState<boolean>(false);

  useEffect(() => {
    if (!loaded) {
      initSplunkRum()
        .catch(() => console.warn("failed to setup Splunk RUM"))
        .finally(() => setLoaded(true));
    }
  }, [loaded]);

  return {
    loaded,
  };
};
