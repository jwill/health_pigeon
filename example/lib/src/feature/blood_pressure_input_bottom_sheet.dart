import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:signals/signals_flutter.dart';

import 'package:health_pigeon_example/src/data/bp_record.dart';
import '../data/bp_record_signal.dart';
import '../data/health_connect_service.dart';

class BloodPressureInputBottomSheet extends StatefulWidget {
  final date = signal(DateTime.now());
  final systolic = signal('');
  final diastolic = signal('');
  final notes = signal('');
  final HealthConnectService healthConnectService;

  BloodPressureInputBottomSheet({super.key, required this.healthConnectService});

  @override
  State<BloodPressureInputBottomSheet> createState() =>
      _BloodPressureInputBottomSheetState();
}

class _BloodPressureInputBottomSheetState
    extends State<BloodPressureInputBottomSheet> {
  late TextEditingController _systolicController;
  late TextEditingController _diastolicController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _systolicController =
        TextEditingController(text: widget.systolic.value.toString());
    _diastolicController =
        TextEditingController(text: widget.diastolic.value.toString());
    _notesController =
        TextEditingController(text: widget.notes.value.toString());
  }

  @override
  void dispose() {
    _systolicController.dispose();
    _diastolicController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void saveRecord() {
    final signal = SignalProvider.of<BPRecordSignal>(context);
    final systolicVal = int.tryParse(_systolicController.text);
    final diastolicVal = int.tryParse(_diastolicController.text);
    if (systolicVal == null || diastolicVal == null) return;

    final record = BPRecord(
      date: widget.date.value,
      systolic: systolicVal,
      diastolic: diastolicVal,
      notes: _notesController.text,
    );

    // Use health connect if on Android
    if (Platform.isAndroid) {
      widget.healthConnectService.insertBloodPressure(record);
    }

    final newList = [...signal!.value, record]..sort((a, b) {
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
              onChanged: (value) => widget.systolic.value = value,
            ),
            const SizedBox(height: 12),
            Text('Diastolic (mmHg)', style: theme.textTheme.small),
            const SizedBox(height: 4),
            ShadInput(
              controller: _diastolicController,
              keyboardType: TextInputType.number,
              placeholder: const Text('Bottom number (e.g. 80)'),
              onChanged: (value) => widget.diastolic.value = value,
            ),
            const SizedBox(height: 12),
            Text('Notes (optional)', style: theme.textTheme.small),
            const SizedBox(height: 4),
            ShadInput(
              controller: _notesController,
              placeholder: const Text('Optional note...'),
              onChanged: (value) => widget.notes.value = value,
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
                      Watch((context) => Text(
                        DateFormat.yMMMd().format(widget.date.value),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      )),
                      const Spacer(),
                      ShadButton.outline(
                        size: ShadButtonSize.sm,
                        leading: const Icon(LucideIcons.edit2, size: 14),
                        onPressed: () async {
                          final val = await showDatePicker(
                            context: context,
                            initialDate: widget.date.value,
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now(),
                          );
                          if (val != null) widget.date.value = val;
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
                      Watch((context) => Text(
                        DateFormat.jm().format(widget.date.value),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      )),
                      const Spacer(),
                      ShadButton.outline(
                        size: ShadButtonSize.sm,
                        leading: const Icon(LucideIcons.edit2, size: 14),
                        onPressed: () async {
                          final val = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(widget.date.value),
                          );
                          if (val != null) {
                            widget.date.value = widget.date.value.copyWith(
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
