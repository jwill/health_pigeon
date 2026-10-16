import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:signals/signals_flutter.dart';

import 'package:health_pigeon_example/src/data/bp_record.dart';
import '../data/bp_record_signal.dart';

/// Displays detailed information about a blood pressure reading.
class BloodPressureItemDetailsView extends StatelessWidget {
  const BloodPressureItemDetailsView({super.key});

  static const routeName = '/sample_item';

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final record = ModalRoute.of(context)?.settings.arguments as Map<String, String>?;
    final signal = SignalProvider.of<BPRecordSignal>(context)!;

    if (record == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Item Details')),
        body: const Center(child: Text('Record not found')),
      );
    }

    DateTime? parsedDate;
    try {
      parsedDate = DateTime.parse(record['date'] ?? '');
    } catch (_) {}

    return Scaffold(
      appBar: AppBar(
        title: Text('Reading Details', style: theme.textTheme.h4),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ShadCard(
              title: Text(
                '${record['systolic']} / ${record['diastolic']} mmHg',
                style: theme.textTheme.h2,
              ),
              description: Text(
                parsedDate != null
                    ? DateFormat.yMMMd().add_jm().format(parsedDate)
                    : (record['date'] ?? ''),
              ),
              child: record['notes']?.isNotEmpty == true
                  ? Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Note: ${record['notes']}',
                        style: theme.textTheme.muted,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ShadButton.destructive(
                leading: const Icon(LucideIcons.trash2, size: 16),
                onPressed: () {
                  if (parsedDate != null) {
                    signal.value.removeWhere((BPRecord elem) => elem.date == parsedDate);
                    signal.save(signal.value);
                    signal.set(signal.value, force: true);
                  }
                  Navigator.pop(context);
                },
                child: const Text('Delete Reading'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
