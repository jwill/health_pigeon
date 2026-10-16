# Convert Permissions Plugin to Pigeon FFI (Android)

Create a new Flutter project `permissions_plugin_pigeon` alongside `permissions_plugin`, migrating direct `jnigen`/`ffigen` calls to type-safe **Pigeon FFI (`useJni: true`)** for Android.

## User Review Required

> [!NOTE]
> The new project `permissions_plugin_pigeon` will be created at `../permissions_plugin_pigeon` targeting Android with Pigeon Native Interop (JNI), mirroring the architecture in `batterylevel_pigeon_ffi`.

## Proposed Changes

### 1. New Project Setup (`permissions_plugin_pigeon`)

- Create new Android Flutter project: `flutter create --platforms=android permissions_plugin_pigeon`
- Configure `pubspec.yaml`:
  - `dependencies`: `flutter`, `jni: ^1.0.3`, `jni_flutter: ^1.0.3`, `pigeon: ^29.0.1`
  - `dev_dependencies`: `jnigen: ^1.0.0`, `flutter_lints: ^6.0.0`
- Configure `analysis_options.yaml`:
  - Exclude `**/*.g.dart` and `**/*.g.*.dart` from static analysis.

### 2. Android Build Configuration

- **`android/settings.gradle.kts`**: Lock Kotlin Gradle plugin to `2.1.0` for JNIgen bytecode analyzer compatibility:
  ```kotlin
  id("org.jetbrains.kotlin.android") version "2.1.0" apply false
  ```
- **`android/app/build.gradle.kts`**:
  - Set `sourceCompatibility` and `targetCompatibility` to `JavaVersion.VERSION_17`
  - Set `jvmTarget` to `JvmTarget.JVM_17`
- **`android/app/src/main/AndroidManifest.xml`**:
  - Add demo permissions (e.g., `android.permission.CAMERA`).

### 3. Pigeon API Definition (`pigeons/messages.dart`)

- Create Pigeon schema:
  - `@ConfigurePigeon` with `useJni: true`, `appDirectory: './'`
  - Host API `PermissionsApi`:
    - `String getPlatformVersion()`
    - `bool checkPermission(String permission)`
    - `int checkAndRequestPermission(String permission)`

### 4. Kotlin Native Implementation (`MainActivity.kt`)

- Implement `PermissionsApi` on `MainActivity`:
  - Register API in `onCreate` via `PermissionsApiRegistrar().register(this)`
  - Implement `getPlatformVersion()` returning Android OS release info
  - Implement `checkPermission(permission: String): Boolean` via `ContextCompat.checkSelfPermission`
  - Implement `checkAndRequestPermission(permission: String): Long` handling `PERMISSION_GRANTED`, `shouldShowRequestPermissionRationale`, and `ActivityCompat.requestPermissions`

### 5. Multi-Pass Pigeon FFI Code Generation

- Run pass 1: `dart run pigeon --input pigeons/messages.dart`
- Compile Kotlin: `cd android && ./gradlew compileReleaseKotlin && cd ..`
- Run pass 2: `dart run pigeon --input pigeons/messages.dart` (generates `lib/src/messages.g.jni.dart` and `lib/src/messages.g.dart`)

### 6. Flutter UI & Application Logic (`lib/main.dart`)

- Instantiate `PermissionsApi.createWithNativeInteropApi()`
- Provide interactive UI to:
  - Display platform version
  - Check status of camera permission (`android.permission.CAMERA`)
  - Request camera permission and handle rationale responses
  - Display real-time status feedback

### 7. Documentation

- Create `README.md` in `permissions_plugin_pigeon` documenting architecture, comparison with direct JNIgen/platform channels, and setup instructions.
- Create `PIGEON_FFI_GUIDE.md` documenting step-by-step notes on how the app was created.

---

## Verification Plan

### Automated Tests & Code Verification
- Run `flutter pub get`
- Run `dart analyze` to ensure 0 lint errors
- Run `cd android && ./gradlew compileReleaseKotlin` to ensure clean native compilation
- Run `flutter test`
