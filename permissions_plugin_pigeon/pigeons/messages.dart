import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/messages.g.dart',
    dartOptions: DartOptions(),
    kotlinOut:
        'android/src/main/kotlin/com/example/permissions_plugin_pigeon/Messages.g.kt',
    kotlinOptions: KotlinOptions(
      package: 'com.example.permissions_plugin_pigeon',
      useJni: true,
      appDirectory: './example',
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
  void requestPermissions(List<String> permissions);
  bool openAppSettings();
}
