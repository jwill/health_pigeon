# Walkthrough: Permissions Plugin to Pigeon FFI Migration

We created a new Android Flutter project [permissions_plugin_pigeon](file:///Users/jameswilli/Documents/GitHub/flutter-demos/native_interop_demos/permissions_plugin_pigeon) alongside `permissions_plugin` that uses **Pigeon FFI (`useJni: true`)** for native interop on Android.

---

## 1. Changes & Project Structure

### New Project Directory
- **Location**: [permissions_plugin_pigeon](file:///Users/jameswilli/Documents/GitHub/flutter-demos/native_interop_demos/permissions_plugin_pigeon)
- **Target Platform**: Android

### Key Files Created & Configured

| File | Purpose |
| :--- | :--- |
| [pubspec.yaml](file:///Users/jameswilli/Documents/GitHub/flutter-demos/native_interop_demos/permissions_plugin_pigeon/pubspec.yaml) | Configured dependencies (`jni`, `jni_flutter`, `pigeon`, `jnigen`). |
| [analysis_options.yaml](file:///Users/jameswilli/Documents/GitHub/flutter-demos/native_interop_demos/permissions_plugin_pigeon/analysis_options.yaml) | Configured to exclude generated files (`**/*.g.dart`, `**/*.g.*.dart`). |
| [android/settings.gradle.kts](file:///Users/jameswilli/Documents/GitHub/flutter-demos/native_interop_demos/permissions_plugin_pigeon/android/settings.gradle.kts) | Locked Kotlin Gradle Plugin to `2.1.0` for JNIgen bytecode compatibility. |
| [android/app/build.gradle.kts](file:///Users/jameswilli/Documents/GitHub/flutter-demos/native_interop_demos/permissions_plugin_pigeon/android/app/build.gradle.kts) | Configured Java 17 / JVM 17 compatibility. |
| [android/app/src/main/AndroidManifest.xml](file:///Users/jameswilli/Documents/GitHub/flutter-demos/native_interop_demos/permissions_plugin_pigeon/android/app/src/main/AndroidManifest.xml) | Added camera permissions declarations. |
| [pigeons/messages.dart](file:///Users/jameswilli/Documents/GitHub/flutter-demos/native_interop_demos/permissions_plugin_pigeon/pigeons/messages.dart) | Defined Pigeon Host API schema with `useJni: true`. |
| [MainActivity.kt](file:///Users/jameswilli/Documents/GitHub/flutter-demos/native_interop_demos/permissions_plugin_pigeon/android/app/src/main/kotlin/com/example/permissions_plugin_pigeon/MainActivity.kt) | Implemented `PermissionsApi` and registered via `PermissionsApiRegistrar().register(this)`. |
| [lib/main.dart](file:///Users/jameswilli/Documents/GitHub/flutter-demos/native_interop_demos/permissions_plugin_pigeon/lib/main.dart) | Interactive Flutter Material 3 UI demonstrating Pigeon FFI interop. |
| [README.md](file:///Users/jameswilli/Documents/GitHub/flutter-demos/native_interop_demos/permissions_plugin_pigeon/README.md) | Project overview, comparison table, architecture, and instructions. |
| [PIGEON_FFI_GUIDE.md](file:///Users/jameswilli/Documents/GitHub/flutter-demos/native_interop_demos/permissions_plugin_pigeon/PIGEON_FFI_GUIDE.md) | Complete step-by-step documentation and notes on how the project was built. |

---

## 2. Multi-Pass Generation Workflow Executed

1. **Initial Pigeon pass**: Generated Kotlin interface [Messages.g.kt](file:///Users/jameswilli/Documents/GitHub/flutter-demos/native_interop_demos/permissions_plugin_pigeon/android/app/src/main/kotlin/com/example/permissions_plugin_pigeon/Messages.g.kt).
2. **Kotlin compilation**: Compiled release Kotlin classes via Gradle (`./gradlew compileReleaseKotlin`).
3. **Pigeon + JNIgen pass**: Generated typed Dart JNI bindings [messages.g.jni.dart](file:///Users/jameswilli/Documents/GitHub/flutter-demos/native_interop_demos/permissions_plugin_pigeon/lib/src/messages.g.jni.dart) and [messages.g.dart](file:///Users/jameswilli/Documents/GitHub/flutter-demos/native_interop_demos/permissions_plugin_pigeon/lib/src/messages.g.dart).

---

## 3. Verification Results

- **`dart analyze`**: Passed with 0 errors/warnings.
- **`flutter test`**: Passed all tests.
- **Gradle Release Compilation**: Kotlin compilation succeeded with exit code 0.
