package io.opentelemetry.flutter_app

import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

private const val CRASH_SIMULATOR_CHANNEL = "crash_simulator"

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CRASH_SIMULATOR_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "triggerNativeCrash" -> {
                        result.success(null)
                        // Posted to the main thread so the exception escapes this method
                        // call's own try/catch (the Flutter engine would otherwise turn
                        // it into a caught platform-channel error) and reaches the
                        // uncaught exception handler Splunk's crash module installs.
                        Handler(Looper.getMainLooper()).post {
                            throw RuntimeException("Simulated native crash from Settings")
                        }
                    }
                    "triggerAnr" -> {
                        result.success(null)
                        // Blocks the UI thread long enough to trip Android's ANR watchdog
                        // (~5s default threshold for input dispatch).
                        Handler(Looper.getMainLooper()).post {
                            Thread.sleep(6000)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
