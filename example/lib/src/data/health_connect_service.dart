import 'dart:async';
import 'package:signals/signals.dart';
import 'package:flutter/services.dart';
import 'package:health_pigeon/health_pigeon.dart';
import 'package:health_pigeon_example/src/data/bp_record.dart';

class HealthConnectService {
  final HealthConnectApi _api = HealthConnectApi.createWithNativeInteropApi();
  final isConnected = signal(false);

  Future<void> init() async {
    await _updateConnectionStatus();
  }

  Future<void> _updateConnectionStatus() async {
    try {
      isConnected.value = await _api.hasPermissions();
    } catch (e) {
      print("Error updating Health Connect connection status: $e");
      isConnected.value = false;
    }
  }

  Future<void> checkPermissions() => _updateConnectionStatus();

  Future<void> requestPermissions() async {
    try {
      if (await _api.hasPermissions()) {
        isConnected.value = true;
        return;
      }
      await _api.requestPermissions();
      await _updateConnectionStatus();
      if (!isConnected.value) {
        // Health Connect only prompts once via activity contract.
        // If permissions remain ungranted, redirect to Health Connect settings.
        await _api.openHealthConnectSettings();
      }
    } catch (e) {
      print("Error requesting permissions via FFI: $e");
    }
  }

  Future<void> openSettings() async {
    try {
      await _api.openHealthConnectSettings();
    } catch (e) {
      print("Error opening Health Connect settings: $e");
    }
  }

  Future<void> batchInsertBloodPressure(List<BPRecord> records) async {
    for (final record in records) {
      await insertBloodPressure(record);
    }
  }

  Future<void> insertBloodPressure(BPRecord record) async {
    try {
      await _api.writeBloodPressure(BloodPressureRecordPigeon(
        systolic: record.systolic,
        diastolic: record.diastolic,
        dateMillis: record.date.millisecondsSinceEpoch,
        notes: record.notes,
      ));
    } catch (e) {
      print("Error inserting into Health Connect: $e");
    }
  }

  Future<List<BPRecord>> readBloodPressure(DateTime start, DateTime end) async {
    try {
      final records = await _api.readBloodPressure(
        start.millisecondsSinceEpoch,
        end.millisecondsSinceEpoch,
      );
      
      return records.map((record) => BPRecord(
        date: DateTime.fromMillisecondsSinceEpoch(record.dateMillis),
        systolic: record.systolic,
        diastolic: record.diastolic,
        notes: record.notes ?? "",
      )).toList();
    } catch (e) {
      print("Error reading from Health Connect: $e");
      return [];
    }
  }
}

