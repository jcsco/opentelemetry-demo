import ExpoModulesCore

public class CrashSimulatorModule: Module {
  public func definition() -> ModuleDefinition {
    Name("CrashSimulator")

    // Unconditional, unrecoverable trap -- a real crash for testing Splunk's native
    // crash reporter, not a throwable Swift error Expo Modules could catch and turn
    // into a rejected JS promise.
    Function("triggerNativeCrash") {
      fatalError("Simulated native crash from Settings")
    }
  }
}
