import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/gen/health_connect.g.dart',
    kotlinOut: 'android/src/main/kotlin/com/example/health_pigeon/HealthPigeon.g.kt',
    kotlinOptions: KotlinOptions(
      package: 'com.example.health_pigeon',
      useJni: true,
      appDirectory: 'example',
      jnigenOptions: JnigenOptions(
        config: JnigenConfig(
          androidSdk: AndroidSdk(
            androidExample: 'example',
          ),
        ),
      ),
    ),
    dartPackageName: 'blood_pressure_app',
  ),
)
class BloodPressureRecordPigeon {
  BloodPressureRecordPigeon({
    required this.systolic,
    required this.diastolic,
    required this.dateMillis,
    this.notes,
  });

  int systolic;
  int diastolic;
  int dateMillis;
  String? notes;
}

@HostApi()
abstract class HealthConnectApi {
  @async
  bool hasPermissions();

  @async
  void requestPermissions();

  @async
  List<BloodPressureRecordPigeon> readBloodPressure(int startMillis, int endMillis);

  @async
  void writeBloodPressure(BloodPressureRecordPigeon record);
}
