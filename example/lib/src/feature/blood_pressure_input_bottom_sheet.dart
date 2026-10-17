import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:signals/signals_flutter.dart';

import 'package:health_pigeon_example/src/data/bp_record.dart';
import '../data/bp_record_signal.dart';
import '../data/health_connect_service.dart';

class BloodPressureInputBottomSheet extends StatefulWidget {
  final HealthConnectService healthConnectService;

  const BloodPressureInputBottomSheet({
    super.key,
    required this.healthConnectService,
  });

  @override
  State<BloodPressureInputBottomSheet> createState() =>
      _BloodPressureInputBottomSheetState();
}

class _BloodPressureInputBottomSheetState
    extends State<BloodPressureInputBottomSheet> {
  static final _dateFormat = DateFormat.yMMMd();
  static final _timeFormat = DateFormat.jm();

  late final Signal<DateTime> _dateSignal;
  late final TextEditingController _systolicController;
  late final TextEditingController _diastolicController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _dateSignal = signal(DateTime.now());
    _systolicController = TextEditingController();
    _diastolicController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _dateSignal.dispose();
    _systolicController.dispose();
    _diastolicController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void saveRecord() {
    final signal = SignalProvider.of<BPRecordSignal>(context, listen: false);
    final systolicVal = int.tryParse(_systolicController.text);
    final diastolicVal = int.tryParse(_diastolicController.text);
    if (systolicVal == null || diastolicVal == null) return;

    final record = BPRecord(
      date: _dateSignal.value,
      systolic: systolicVal,
      diastolic: diastolicVal,
      notes: _notesController.text,
    );

    // Use health platform service (Health Connect on Android, HealthKit on iOS)
    if (Platform.isAndroid || Platform.isIOS) {
      widget.healthConnectService.insertBloodPressure(record);
    }

    final current = signal!.value;
    final newList = [...current, record]..sort((a, b) {
      return a.date.millisecondsSinceEpoch
          .compareTo(b.date.millisecondsSinceEpoch);
    });
    signal.value = newList;

    Navigator.pop(context, 'OK');
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return ShadSheet(
      title: const Text('New Reading'),
      description: const Text('Record your systolic and diastolic measurements'),
      actions: [
        ShadButton.outline(
          onPressed: () => Navigator.pop(context, 'Cancel'),
          child: const Text('Cancel'),
        ),
        ShadButton(
          onPressed: saveRecord,
          child: const Text('Add Reading'),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Systolic (mmHg)', style: theme.textTheme.small),
            const SizedBox(height: 4),
            ShadInput(
              controller: _systolicController,
              keyboardType: TextInputType.number,
              placeholder: const Text('Top number (e.g. 120)'),
            ),
            const SizedBox(height: 12),
            Text('Diastolic (mmHg)', style: theme.textTheme.small),
            const SizedBox(height: 4),
            ShadInput(
              controller: _diastolicController,
              keyboardType: TextInputType.number,
              placeholder: const Text('Bottom number (e.g. 80)'),
            ),
            const SizedBox(height: 12),
            Text('Notes (optional)', style: theme.textTheme.small),
            const SizedBox(height: 4),
            ShadInput(
              controller: _notesController,
              placeholder: const Text('Optional note...'),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.calendar, size: 18),
                      const SizedBox(width: 8),
                      SignalBuilder(
                        builder: (context) => Text(
                          _dateFormat.format(_dateSignal.value),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      const Spacer(),
                      ShadButton.outline(
                        size: ShadButtonSize.sm,
                        leading: const Icon(LucideIcons.edit2, size: 14),
                        onPressed: () async {
                          final val = await showDatePicker(
                            context: context,
                            initialDate: _dateSignal.value,
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now(),
                          );
                          if (val != null) _dateSignal.value = val;
                        },
                        child: const Text('Change'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(LucideIcons.clock, size: 18),
                      const SizedBox(width: 8),
                      SignalBuilder(
                        builder: (context) => Text(
                          _timeFormat.format(_dateSignal.value),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      const Spacer(),
                      ShadButton.outline(
                        size: ShadButtonSize.sm,
                        leading: const Icon(LucideIcons.edit2, size: 14),
                        onPressed: () async {
                          final val = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(_dateSignal.value),
                          );
                          if (val != null) {
                            _dateSignal.value = _dateSignal.value.copyWith(
                              hour: val.hour,
                              minute: val.minute,
                            );
                          }
                        },
                        child: const Text('Change'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
