import 'package:flutter/material.dart';
import 'package:health_pigeon_example/src/app.dart';
import 'package:health_pigeon_example/src/settings/settings_controller.dart';
import 'package:health_pigeon_example/src/settings/settings_service.dart';
import 'package:health_pigeon_example/src/data/csv_service.dart';
import 'package:health_pigeon_example/src/data/bp_record_signal.dart';
import 'package:health_pigeon_example/src/data/health_connect_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final settingsService = SettingsService();
  final csvService = CsvService();
  final healthConnectService = HealthConnectService();
  final recordsSignal = BPRecordSignal([], 'bp_records');

  final settingsController = SettingsController(
    settingsService,
    recordsSignal,
    csvService,
    healthConnectService
  );

  await settingsController.loadSettings();

  runApp(MyApp(
    settingsController: settingsController,
    signal: recordsSignal,
  ));
}
