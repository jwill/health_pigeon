import 'dart:typed_data';
import 'package:health_pigeon_example/src/data/csv_service.dart';
import 'package:health_pigeon_example/src/data/bp_record.dart';
import 'package:health_pigeon_example/src/data/bp_record_signal.dart';
import 'package:health_pigeon_example/src/data/health_connect_service.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cross_file/cross_file.dart';
import 'package:health_pigeon_example/src/settings/settings_service.dart';
import 'dart:io' show File, Platform;
import 'package:signals/signals.dart';

/// A class that many Widgets can interact with to listen to user settings changes.
class SettingsController with ChangeNotifier {
  SettingsController(this._settingsService, this.recordsSignal, this._csvService, this.healthConnectService);

  final SettingsService _settingsService;
  final CsvService _csvService;
  final HealthConnectService healthConnectService;
  late ThemeMode _themeMode;
  final showLowestOnly = signal(false);
  final BPRecordSignal recordsSignal;

  late final filteredRecords = computed(() {
    final allRecords = recordsSignal.value;
    if (!showLowestOnly.value) return allRecords;

    final lowestPerDay = <String, BPRecord>{};
    for (final record in allRecords) {
      final dateKey = '${record.date.year}-${record.date.month}-${record.date.day}';
      final existing = lowestPerDay[dateKey];
      if (existing == null || record.systolic < existing.systolic) {
        lowestPerDay[dateKey] = record;
      }
    }
    return lowestPerDay.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  });

  ThemeMode get themeMode => _themeMode;
 
  Future<void> loadSettings() async {
    _themeMode = await _settingsService.themeMode();
    showLowestOnly.value = await _settingsService.showLowestOnly();
    notifyListeners();
  }

  Future<void> updateThemeMode(ThemeMode? newThemeMode) async {
    if (newThemeMode == null) return;
    if (newThemeMode == _themeMode) return;
    _themeMode = newThemeMode;
    notifyListeners();
    await _settingsService.updateThemeMode(newThemeMode);
  }

  Future<void> updateShowLowestOnly(bool? value) async {
    if (value == null) return;
    if (value == showLowestOnly.value) return;
    showLowestOnly.value = value;
    await _settingsService.updateShowLowestOnly(value);
  }

  Future<List<BPRecord>?> loadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      XFile file = result.xFiles.first;
      final csvString = await file.readAsString();
      final records = _csvService.importFromCsv(csvString);

      if (records.isNotEmpty) {
        recordsSignal.value = records;
        return records;
      }
    }
    return null;
  }

  Future<void> saveFile() async {
    final records = recordsSignal.value;
    final csvContent = _csvService.exportToCsv(records);
    
    String? path;
    if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      path = await FilePicker.platform.saveFile(
          dialogTitle: 'Please select an output file:', fileName: 'output.csv');
      if (path != null) {
        await File(path).writeAsString(csvContent);
      }
    } else {
      await FilePicker.platform.saveFile(
          dialogTitle: 'Please select an output file:',
          fileName: 'output.csv',
          bytes: Uint8List.fromList(csvContent.codeUnits));
    }
  }

  static Future<void> saveImage(Uint8List bytes) async {
    String? result;
    if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      result = await FilePicker.platform.saveFile(
          dialogTitle: 'Please select an output file:', fileName: 'output.png');
      if (result != null) {
        var file = File(result);
        file.writeAsBytes(bytes);
      }
    } else {
      result = await FilePicker.platform.saveFile(
          dialogTitle: 'Please select an output file:',
          fileName: 'output.png',
          bytes: bytes);
    }
  }

  Future<void> clearRecords() async {
    recordsSignal.value = [];
    notifyListeners();
  }
}
