# Example Flutter app

This is a Flutter replica of [`src/react-native-app`](../react-native-app),
providing the same functionality (browse products, add to cart, checkout) as
a native iOS and Android app, instrumented with the
[Splunk Distribution of OpenTelemetry for Flutter](https://github.com/signalfx/splunk-otel-flutter)
RUM agent instead of the raw OpenTelemetry JS/Dart SDKs.

Content was taken from the web app example in `src/frontend` (and the
`src/react-native-app` port of it) and adapted to a Flutter environment.

## Get started

Start the OpenTelemetry demo from the root of this repo:

```bash
cd ../..
make start # or start-minimal
```

Then, from this directory, install Flutter and fetch dependencies:

```bash
cd src/flutter-app
flutter doctor   # confirms your Xcode/Android Studio toolchains are set up
flutter pub get
```

Like `src/react-native-app`, this app must be built and run on a mobile
simulator/emulator or a physical device - it does not run inside the demo's
Docker Compose stack.

## Running on iOS

Requires Xcode, iOS 15.0+, and Swift Package Manager enabled for Flutter
(already configured for this project; re-run if you reset your Flutter
config):

```bash
flutter config --enable-swift-package-manager
```

1. List available simulators and boot one (skip if you already have one running):

   ```bash
   flutter emulators
   flutter emulators --launch apple_ios_simulator
   ```

2. Find its device id:

   ```bash
   flutter devices
   ```

3. Run the app on it:

   ```bash
   flutter run -d <device-id-or-name>
   # e.g. flutter run -d "iPhone 18 Pro"
   ```

You can also open `ios/Runner.xcworkspace` in Xcode and run from there.

## Running on Android

Requires `minSdkVersion` 24+ (already configured in
`android/app/build.gradle.kts`).

1. List available emulators and boot one (skip if you already have a device/emulator running):

   ```bash
   flutter emulators
   flutter emulators --launch <emulator-id>
   # e.g. flutter emulators --launch Pixel_8_API_36
   ```

   No emulator listed? Create one in Android Studio's Device Manager, or via
   `flutter emulators --create`.

2. Confirm it's visible to Flutter (it can take 30-60s to finish booting):

   ```bash
   flutter devices
   ```

3. Run the app on it:

   ```bash
   flutter run -d <device-id>
   # e.g. flutter run -d emulator-5554
   ```

Note: `flutter run -d android` / `-d ios` do **not** work as generic platform
selectors - you need the specific device id or name from `flutter devices`.

The very first build on a given machine also installs the Android NDK
(required by the Splunk RUM plugin's native module) on top of the normal
first Gradle build, which together can take several minutes. If the app
flashes and closes before that finishes, it was likely caught mid-build/
mid-install - just retry once it completes; subsequent builds are fast since
the NDK and Gradle caches are then warm.

## Pointing to another demo environment

By default, the app points at `localhost:8080` (or `10.0.2.2:8080` on the
Android emulator) to reach the demo's `frontend-proxy`. This can be changed
in the Settings tab when running the app to point to a demo environment
running on a different server - API calls and trace export are both
re-pointed at the new URL immediately.

On a **physical device**, `localhost` won't resolve to your development
machine - use the Settings tab to set the Frontend Proxy URL to
`http://<your-machine's-LAN-IP>:8080` instead.

## Telemetry

The app installs the Splunk RUM agent at startup (see `lib/telemetry.dart`),
sending traces to `<Frontend Proxy URL>/otlp-http/v1/traces` - the same OTLP/
HTTP collector endpoint used by the web frontend and `src/react-native-app`.
A placeholder `auth` query parameter is included on that URL because the
Android agent otherwise assumes a Splunk Observability Cloud realm/token pair
was intended and silently disables export instead of sending; the demo's
collector doesn't check this value, so it's safe to leave as-is for a
self-hosted/unauthenticated collector.

Automatic instrumentation covers app lifecycle, crashes, ANRs (Android), slow
rendering, and screen navigation; a `session.id` global attribute tags every
signal with this install's anonymous user id, the same id sent to the backend
as `sessionId`/`userId` on cart and checkout calls.

## Troubleshooting

### "No supported devices found with name or id matching '...'"

`flutter run -d <platform>` only works with a real device id/name, not a
generic platform keyword. Run `flutter devices` first and copy the exact id.

### App closes right after launching (first run only)

See the NDK/Gradle note under "Running on Android" above - wait for the first
build to fully complete rather than retrying mid-build.

### Products screen says the backend isn't running

Confirm the demo stack is up and `frontend-proxy` is healthy:

```bash
cd ../.. && docker compose ps
```

If a backend service (e.g. `product-catalog`) shows `unhealthy`, restart it:

```bash
docker restart product-catalog
```

The Products screen shows the actual error message when a request fails, so
you can distinguish "backend unreachable/timed out" from "catalog is
genuinely empty".
