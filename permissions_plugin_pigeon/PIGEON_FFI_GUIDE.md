# Comprehensive Guide: Building Android Apps with Pigeon FFI (Native Interop / JNI)

This guide documents the complete step-by-step process and architectural considerations for creating a Flutter Android application using **Pigeon FFI (Native Interop with JNI)**.

---

## 1. Overview & Architecture

Pigeon FFI allows Flutter applications on Android to communicate directly with Kotlin code via JNI (Java Native Interface) instead of passing messages through Flutter engine `MethodChannel` platform buffers.

```
┌────────────────────────────────────────────────────────────────────────┐
│                        Flutter App (Dart)                              │
│                                                                        │
│   final api = PermissionsApi.createWithNativeInteropApi();            │
│   await api.checkPermission("android.permission.CAMERA");             │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                         Direct JNI FFI Execution
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                  Generated Dart-to-JNI Bridge                          │
│                   lib/src/messages.g.jni.dart                          │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                           JNI / JVM Call
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                       Native Android (Kotlin)                          │
│                   MainActivity.kt / PermissionsApi                     │
│                                                                        │
│   override fun checkPermission(permission: String): Boolean { ... }    │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Step-by-Step Instructions to Build the App

### Step 1: Initialize Flutter Project

Create a Flutter project targeting Android:

```bash
flutter create --platforms=android permissions_plugin_pigeon
cd permissions_plugin_pigeon
```

### Step 2: Configure Dependencies in `pubspec.yaml`

Add `jni`, `jni_flutter`, `pigeon`, and `jnigen`:

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

Run `flutter pub get`.

### Step 3: Configure Analyzer & Gradle

1. **`analysis_options.yaml`**: Exclude generated files from analyzer:
   ```yaml
   include: package:flutter_lints/flutter.yaml

   analyzer:
     exclude:
       - "**/*.g.dart"
       - "**/*.g.*.dart"
   ```

2. **`android/settings.gradle.kts`**: Lock Kotlin Gradle Plugin version to `<= 2.1.0`:
   ```kotlin
   plugins {
       id("dev.flutter.flutter-plugin-loader") version "1.0.0"
       id("com.android.application") version "9.0.1" apply false
       id("org.jetbrains.kotlin.android") version "2.1.0" apply false
   }
   ```

3. **`android/app/build.gradle.kts`**: Set Java and Kotlin compilation targets to Java 17:
   ```kotlin
   compileOptions {
       sourceCompatibility = JavaVersion.VERSION_17
       targetCompatibility = JavaVersion.VERSION_17
   }

   kotlin {
       compilerOptions {
           jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
       }
   }
   ```

### Step 4: Add Permissions to `AndroidManifest.xml`

In `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-feature android:name="android.hardware.camera" android:required="false" />
    ...
```

### Step 5: Define Pigeon Schema

Create `pigeons/messages.dart`:

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

### Step 6: Native Implementation in Kotlin

In `android/app/src/main/kotlin/com/example/permissions_plugin_pigeon/MainActivity.kt`:

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
      1L
    } else if (ActivityCompat.shouldShowRequestPermissionRationale(this, permission)) {
      -2L
    } else {
      ActivityCompat.requestPermissions(this, arrayOf(permission), 0)
      0L
    }
  }
}
```

### Step 7: Multi-Pass Code Generation Workflow

1. Initial pass:
   ```bash
   dart run pigeon --input pigeons/messages.dart
   ```
2. Compile Kotlin classes:
   ```bash
   cd android && ./gradlew compileReleaseKotlin && cd ..
   ```
3. Final pass:
   ```bash
   dart run pigeon --input pigeons/messages.dart
   ```

### Step 8: Call Native Interop API from Flutter UI

```dart
final api = PermissionsApi.createWithNativeInteropApi();
final platformVersion = await api.getPlatformVersion();
final isGranted = await api.checkPermission('android.permission.CAMERA');
```

---

## 3. Key Troubleshooting Tips & Gotchas

1. **Missing Android SDK in JNIgen pass**:
   - Set `ANDROID_HOME` or `ANDROID_SDK_ROOT` environment variable before running the second pigeon pass.
2. **Kotlin metadata parsing**:
   - Keep the Kotlin Gradle plugin at `<= 2.1.0` in `settings.gradle.kts` so that JNIgen's classfile reader can inspect Kotlin annotations and types.
3. **Pigeon Schema output paths**:
   - `kotlinOut` must match the package directory structure in `android/app/src/main/kotlin/...`.
4. **Registering API instance**:
   - Always invoke `PermissionsApiRegistrar().register(this)` in `MainActivity.onCreate` (or plugin initialization) before Dart invokes the API.
