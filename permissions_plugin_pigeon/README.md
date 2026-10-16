# Permissions Demo - Pigeon FFI (Native Interop / JNI)

This project demonstrates how to convert an Android permission handler from direct `jnigen`/`ffigen` or platform channels to direct **Native Interop (Pigeon FFI / JNI)** on Android.

---

## Why Migrate from Direct JNIgen / Platform Channels to Pigeon FFI?

| Aspect | Direct `jnigen` / `ffigen` | Pigeon FFI (`useJni: true`) |
| :--- | :--- | :--- |
| **API Contract** | Raw native Android classes (`ContextCompat`, `ActivityCompat`, `JObject`, `JArray`) exposed directly in Dart. | Clean, high-level Dart interface defined in `pigeons/messages.dart`. |
| **Native Logic Location** | Complex Android Activity/Context handling and callback bridging implemented manually in Dart. | Idiomatic Kotlin in `MainActivity.kt` with direct access to Android framework APIs and Activity lifecycle. |
| **Type Safety & Boilerplate** | Manual `JString` conversions, JNI type conversions, and manual pointer handling. | Fully automated type marshalling, error wrappers (`PlatformException`), and generated Dart JNI bridges. |
| **Performance** | Direct JNI execution. | Direct JNI execution (same zero-copy / low-overhead execution; bypasses platform channel message loops). |

---

## Architecture

```
┌────────────────────────────────────────────────────────────────────────┐
│                        Flutter App (Dart)                              │
│                                                                        │
│   final api = PermissionsApi.createWithNativeInteropApi();            │
│   final isGranted = await api.checkPermission('android.permission.CAMERA');
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼ Direct JNI Call
┌────────────────────────────────────────────────────────────────────────┐
│                        Native Android (Kotlin)                         │
│                                                                        │
│   class MainActivity : FlutterActivity(), PermissionsApi {            │
│     override fun checkPermission(permission: String): Boolean {        │
│       return ContextCompat.checkSelfPermission(this, permission) ==   │
│              PackageManager.PERMISSION_GRANTED                         │
│     }                                                                  │
│   }                                                                    │
└────────────────────────────────────────────────────────────────────────┘
```

---

## Project Setup & Workflow

### 1. Dependencies ([pubspec.yaml](file:///Users/jameswilli/Documents/GitHub/flutter-demos/native_interop_demos/permissions_plugin_pigeon/pubspec.yaml))

```yaml
dependencies:
  flutter:
    sdk: flutter
  jni: ^1.0.3
  jni_flutter: ^1.0.3
  pigeon: ^29.0.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  jnigen: ^1.0.0
```

### 2. Gradle Kotlin Version ([android/settings.gradle.kts](file:///Users/jameswilli/Documents/GitHub/flutter-demos/native_interop_demos/permissions_plugin_pigeon/android/settings.gradle.kts))

Lock Kotlin plugin version to `<= 2.1.0` (e.g. `2.1.0`) so JNIgen's JVM metadata parser can inspect the compiled Kotlin bytecode:

```kotlin
plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.0.1" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}
```

### 3. Pigeon Schema ([pigeons/messages.dart](file:///Users/jameswilli/Documents/GitHub/flutter-demos/native_interop_demos/permissions_plugin_pigeon/pigeons/messages.dart))

```dart
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/messages.g.dart',
    dartOptions: DartOptions(),
    kotlinOut:
        'android/app/src/main/kotlin/com/example/permissions_plugin_pigeon/Messages.g.kt',
    kotlinOptions: KotlinOptions(
      package: 'com.example.permissions_plugin_pigeon',
      useJni: true,
      appDirectory: './',
    ),
  ),
)
@HostApi()
abstract class PermissionsApi {
  String getPlatformVersion();
  bool checkPermission(String permission);
  int checkAndRequestPermission(String permission);
  bool shouldShowRequestPermissionRationale(String permission);
  void requestPermission(String permission);
}
```

### 4. Kotlin Native Implementation ([android/app/src/main/kotlin/com/example/permissions_plugin_pigeon/MainActivity.kt](file:///Users/jameswilli/Documents/GitHub/flutter-demos/native_interop_demos/permissions_plugin_pigeon/android/app/src/main/kotlin/com/example/permissions_plugin_pigeon/MainActivity.kt))

```kotlin
package com.example.permissions_plugin_pigeon

import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity(), PermissionsApi {
  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    PermissionsApiRegistrar().register(this)
  }

  override fun getPlatformVersion(): String {
    return "Android ${Build.VERSION.RELEASE}"
  }

  override fun checkPermission(permission: String): Boolean {
    return ContextCompat.checkSelfPermission(this, permission) == PackageManager.PERMISSION_GRANTED
  }

  override fun shouldShowRequestPermissionRationale(permission: String): Boolean {
    return ActivityCompat.shouldShowRequestPermissionRationale(this, permission)
  }

  override fun requestPermission(permission: String) {
    ActivityCompat.requestPermissions(this, arrayOf(permission), 0)
  }

  override fun checkAndRequestPermission(permission: String): Long {
    return if (ContextCompat.checkSelfPermission(this, permission) == PackageManager.PERMISSION_GRANTED) {
      1L // Granted
    } else if (ActivityCompat.shouldShowRequestPermissionRationale(this, permission)) {
      -2L // Should show rationale
    } else {
      ActivityCompat.requestPermissions(this, arrayOf(permission), 0)
      0L // Requested
    }
  }
}
```

### 5. Multi-Pass Code Generation

1. **Initial Pigeon pass** (generates Kotlin interface and registrar):
   ```bash
   dart run pigeon --input pigeons/messages.dart
   ```
2. **Compile Kotlin bytecode** (produces `.class` files for JNIgen):
   ```bash
   cd android && ./gradlew compileReleaseKotlin && cd ..
   ```
3. **Final Pigeon + JNIgen pass** (generates Dart JNI bridge):
   ```bash
   dart run pigeon --input pigeons/messages.dart
   ```

### 6. Dart Usage ([lib/main.dart](file:///Users/jameswilli/Documents/GitHub/flutter-demos/native_interop_demos/permissions_plugin_pigeon/lib/main.dart))

```dart
final api = PermissionsApi.createWithNativeInteropApi();

// Check permission
final bool isGranted = await api.checkPermission('android.permission.CAMERA');

// Request permission
final int status = await api.checkAndRequestPermission('android.permission.CAMERA');
```
