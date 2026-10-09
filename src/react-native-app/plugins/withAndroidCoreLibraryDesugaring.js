// Copyright The OpenTelemetry Authors
// SPDX-License-Identifier: Apache-2.0
/**
 * @splunk/otel-react-native requires core library desugaring on Android
 * (https://github.com/signalfx/splunk-otel-react-native#android-setup), which its own
 * Expo config plugin does not configure. This plugin adds the required `compileOptions`,
 * `kotlinOptions`, and `coreLibraryDesugaring` dependency to android/app/build.gradle.
 */
const { withAppBuildGradle } = require("@expo/config-plugins");

const withAndroidCoreLibraryDesugaring = (config) => {
  return withAppBuildGradle(config, (modConfig) => {
    if (modConfig.modResults.language !== "groovy") {
      throw new Error(
        "Cannot configure core library desugaring because app/build.gradle is not in Groovy",
      );
    }

    let contents = modConfig.modResults.contents;

    if (!contents.includes("coreLibraryDesugaringEnabled")) {
      // Match the project's actual Java/Kotlin target (17) rather than the 1.8
      // shown in @splunk/otel-react-native's README, which would otherwise
      // conflict with the sourceCompatibility Expo/RN already configure elsewhere.
      contents = contents.replace(
        /android \{/,
        `android {
    compileOptions {
        coreLibraryDesugaringEnabled = true
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }`,
      );
    }

    if (!contents.includes("desugar_jdk_libs")) {
      contents = contents.replace(
        /dependencies \{/,
        `dependencies {
    coreLibraryDesugaring "com.android.tools:desugar_jdk_libs:2.1.5"`,
      );
    }

    modConfig.modResults.contents = contents;
    return modConfig;
  });
};

module.exports = withAndroidCoreLibraryDesugaring;
