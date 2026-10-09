package expo.modules.crashsimulator

import android.os.Handler
import android.os.Looper
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition

class CrashSimulatorModule : Module() {
  override fun definition() = ModuleDefinition {
    Name("CrashSimulator")

    // Posted to the main thread so the exception escapes Expo Modules' call-wrapping
    // (which would otherwise turn it into a rejected JS promise) and reaches the
    // uncaught exception handler Splunk's crash module installs.
    Function("triggerNativeCrash") {
      Handler(Looper.getMainLooper()).post {
        throw RuntimeException("Simulated native crash from Settings")
      }
    }

    // Blocks the UI thread long enough to trip Android's ANR watchdog
    // (~5s default threshold for input dispatch).
    Function("triggerAnr") {
      Handler(Looper.getMainLooper()).post {
        Thread.sleep(6000)
      }
    }
  }
}
