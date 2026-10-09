import { NativeModule, requireNativeModule } from 'expo';

declare class CrashSimulatorModule extends NativeModule<{}> {
  // Android and iOS. Terminates the process with a real native stack trace.
  triggerNativeCrash(): void;
  // Android only -- blocks the UI thread to trigger a real ANR. Callers must
  // guard with Platform.OS === 'android'; there is no native implementation on iOS.
  triggerAnr(): void;
}

export default requireNativeModule<CrashSimulatorModule>('CrashSimulator');
