// Copyright The OpenTelemetry Authors
// SPDX-License-Identifier: Apache-2.0
import { useQueryClient } from '@tanstack/react-query'
import { ThemedView } from "@/components/ThemedView";
import { ThemedText } from "@/components/ThemedText";
import { Platform, StyleSheet } from "react-native";
import { getFrontendProxyURL, setFrontendProxyURL } from "@/utils/Settings";
import { Setting } from "@/components/Setting";
import { ActionButton } from "@/components/ActionButton";
import { SplunkRum } from "@splunk/otel-react-native";
import CrashSimulator from "@/modules/crash-simulator/src/CrashSimulatorModule";

// React Native's global error reporter. Not part of the public react-native
// type exports, so it's declared here rather than imported from an internal path.
declare const global: {
  ErrorUtils: { reportFatalError: (error: unknown) => void };
};

export default function Settings() {
  const queryClient = useQueryClient()

  const onSetFrontendProxyURL = async (value: string) => {
    await setFrontendProxyURL(value);

    // Clear any cached queries since we now have a new endpoint to hit for everything
    await queryClient.invalidateQueries();
  };

  return (
    <ThemedView style={styles.container}>
      <Setting name="Frontend Proxy URL" get={getFrontendProxyURL} set={onSetFrontendProxyURL} />

      <ThemedText type="subtitle">Crash &amp; ANR Testing</ThemedText>
      <ThemedView style={styles.actions}>
        <ActionButton
          label="Simulate Handled Error"
          onPress={() =>
            SplunkRum.instance.customTracking.trackError(
              new Error("Simulated handled error from Settings"),
              { handled: true },
            )
          }
        />
        <ActionButton
          label="Simulate Fatal JS Error"
          confirmMessage="This throws an unhandled JS error. In a release build this crashes the app; in the dev client it may just show a RedBox."
          onPress={() =>
            global.ErrorUtils.reportFatalError(
              new Error("Simulated fatal JS error from Settings"),
            )
          }
        />
        <ActionButton
          label="Simulate Native Crash"
          confirmMessage="This terminates the app with a real native crash."
          onPress={() => CrashSimulator.triggerNativeCrash()}
        />
        {Platform.OS === "android" && (
          <ActionButton
            label="Simulate ANR"
            confirmMessage="This blocks the UI thread for ~6 seconds to trigger a real ANR."
            onPress={() => CrashSimulator.triggerAnr()}
          />
        )}
      </ThemedView>
    </ThemedView>
  );
}

const styles = StyleSheet.create({
  container: {
    display: "flex",
    gap: 20,
    paddingLeft: 20,
    height: "100%",
  },
  actions: {
    display: "flex",
    gap: 10,
    alignItems: "flex-start",
  },
});
