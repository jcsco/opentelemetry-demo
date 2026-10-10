// Copyright The OpenTelemetry Authors
// SPDX-License-Identifier: Apache-2.0
import { Alert, Pressable, StyleSheet } from "react-native";
import { ThemedText } from "@/components/ThemedText";
import { useCallback } from "react";

export type ActionButtonProps = {
  label: string;
  onPress: () => void | Promise<void>;
  /** Shown in a confirmation dialog before onPress runs. Omit for non-destructive actions. */
  confirmMessage?: string;
};

export function ActionButton({
  label,
  onPress,
  confirmMessage,
}: ActionButtonProps) {
  const run = useCallback(() => {
    void onPress();
  }, [onPress]);

  const onButtonPress = useCallback(() => {
    if (!confirmMessage) {
      run();
      return;
    }

    Alert.alert(label, confirmMessage, [
      { text: "Cancel", style: "cancel" },
      { text: "Continue", style: "destructive", onPress: run },
    ]);
  }, [confirmMessage, label, run]);

  return (
    <Pressable style={styles.button} onPress={onButtonPress}>
      <ThemedText style={styles.buttonText}>{label}</ThemedText>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  button: {
    borderRadius: 4,
    backgroundColor: "green",
    alignItems: "center",
    paddingVertical: 8,
    paddingHorizontal: 12,
  },
  buttonText: {
    color: "white",
  },
});
