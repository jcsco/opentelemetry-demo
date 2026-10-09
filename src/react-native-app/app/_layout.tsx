// Copyright The OpenTelemetry Authors
// SPDX-License-Identifier: Apache-2.0
import { Stack, useNavigationContainerRef } from "expo-router";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import {
  DarkTheme,
  DefaultTheme,
  ThemeProvider,
} from "expo-router/react-navigation";
import { useColorScheme } from "react-native";
import Toast from "react-native-toast-message";
import { useFonts } from "expo-font";
import * as SplashScreen from "expo-splash-screen";
import { useEffect, useMemo } from "react";
import { reactNavigationIntegration } from "@splunk/otel-react-native/react-navigation";
import { useTracer } from "@/hooks/useTracer";
import CartProvider from "@/providers/Cart.provider";

const queryClient = new QueryClient();

// Reports expo-router screen transitions to Splunk RUM as `screen.name`
// (native automatic tracking is disabled in hooks/useTracer.ts).
const splunkNavigation = reactNavigationIntegration();

// Keep the native splash screen visible until fonts and the tracer have loaded.
SplashScreen.preventAutoHideAsync();

export default function RootLayout() {
  const colorScheme = useColorScheme();
  const [fontsLoaded] = useFonts({
    SpaceMono: require("../assets/fonts/SpaceMono-Regular.ttf"),
  });
  const { loaded: tracerLoaded } = useTracer();
  const navigationRef = useNavigationContainerRef();

  const loaded = useMemo<boolean>(
    () => fontsLoaded && tracerLoaded,
    [fontsLoaded, tracerLoaded],
  );
  useEffect(() => {
    if (loaded) {
      SplashScreen.hideAsync();
    }
  }, [loaded]);

  useEffect(() => {
    splunkNavigation.registerNavigationContainer(navigationRef);
  }, [navigationRef]);

  if (!loaded) {
    return null;
  }

  return (
    <ThemeProvider value={colorScheme === "dark" ? DarkTheme : DefaultTheme}>
      <QueryClientProvider client={queryClient}>
        <CartProvider>
          <Stack>
            <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
          </Stack>
        </CartProvider>
      </QueryClientProvider>
      <Toast />
    </ThemeProvider>
  );
}
