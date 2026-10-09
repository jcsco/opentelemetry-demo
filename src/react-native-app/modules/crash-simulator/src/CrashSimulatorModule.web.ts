import { registerWebModule, NativeModule } from 'expo';

// CrashSimulatorModule is not available on the web platform.
class CrashSimulatorModule extends NativeModule<{}> {}

export default registerWebModule(CrashSimulatorModule, 'CrashSimulatorModule');
