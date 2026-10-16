import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:signals/signals_flutter.dart';

import 'package:health_pigeon_example/src/data/bp_record.dart';
import 'package:health_pigeon_example/src/data/bp_record_signal.dart';
import 'package:health_pigeon_example/src/feature/blood_pressure_item_details_view.dart';
import 'package:health_pigeon_example/src/settings/settings_controller.dart';

/// Displays a list of blood pressure readings.
class BloodPressureListView extends StatefulWidget {
  const BloodPressureListView({
    super.key,
    required this.controller,
  });

  final SettingsController controller;

  static const routeName = '/list';

  @override
  State<BloodPressureListView> createState() => _BloodPressureListViewState();
}

class _BloodPressureListViewState extends State<BloodPressureListView> {
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _syncWithHealthConnect,
      child: _buildList(context),
    );
  }

  Widget _buildCategoryBadge(BPRecord record) {
    if (record.systolic < 120 && record.diastolic < 80) {
      return const ShadBadge(
        child: Text('Normal'),
      );
    } else if (record.systolic <= 129 && record.diastolic < 80) {
      return const ShadBadge.secondary(
        child: Text('Elevated'),
      );
    } else if (record.systolic <= 139 || record.diastolic <= 89) {
      return const ShadBadge.outline(
        child: Text('Stage 1'),
      );
    } else {
      return const ShadBadge.destructive(
        child: Text('Stage 2'),
      );
    }
  }

  Widget _buildItem(BuildContext context, BPRecord item) {
    final theme = ShadTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: GestureDetector(
        onTap: () {
          Navigator.restorablePushNamed(
            context,
            BloodPressureItemDetailsView.routeName,
            arguments: <String, String>{
              'date': item.date.toString(),
              'systolic': item.systolic.toString(),
              'diastolic': item.diastolic.toString(),
              'notes': item.notes,
            },
          );
        },
        child: ShadCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${item.systolic} / ${item.diastolic}',
                          style: theme.textTheme.h3.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'mmHg',
                          style: theme.textTheme.muted.copyWith(fontSize: 12),
                        ),
                        const Spacer(),
                        _buildCategoryBadge(item),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(LucideIcons.calendar, size: 14, color: theme.colorScheme.mutedForeground),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat.yMMMd().format(item.date),
                          style: theme.textTheme.muted.copyWith(fontSize: 12),
                        ),
                        const SizedBox(width: 12),
                        Icon(LucideIcons.clock, size: 14, color: theme.colorScheme.mutedForeground),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat.jm().format(item.date),
                          style: theme.textTheme.muted.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                    if (item.notes.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        item.notes,
                        style: theme.textTheme.small.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: theme.colorScheme.mutedForeground,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    final signal = SignalProvider.of<BPRecordSignal>(context)!;

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, child) {
        return Watch((context) {
          final allRecords = signal.value;
          List<BPRecord> displayRecords;

          if (widget.controller.showLowestOnly) {
            // Group by day and find lowest systolic
            final Map<String, BPRecord> lowestPerDay = {};

            for (var record in allRecords) {
              final dateKey = DateFormat('yyyy-MM-dd').format(record.date);
              if (!lowestPerDay.containsKey(dateKey) ||
                  record.systolic < lowestPerDay[dateKey]!.systolic) {
                lowestPerDay[dateKey] = record;
              }
            }
            displayRecords = lowestPerDay.values.toList()
              ..sort((a, b) => a.date.compareTo(b.date));
          } else {
            displayRecords = allRecords;
          }

          if (displayRecords.isEmpty) {
            return LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.activity,
                          size: 48,
                          color: ShadTheme.of(context).colorScheme.mutedForeground,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No blood pressure records yet',
                          style: ShadTheme.of(context).textTheme.muted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          return ListView.builder(
            restorationId: 'bloodPressureItemListView',
            itemCount: displayRecords.length,
            padding: const EdgeInsets.only(top: 12, bottom: 80),
            itemBuilder: (BuildContext context, int index) {
              final item = displayRecords[index];
              return _buildItem(context, item);
            },
          );
        });
      },
    );
  }

  Future<void> _syncWithHealthConnect() async {
    final service = widget.controller.healthConnectService;
    if (!service.isConnected.value) {
      if (mounted) {
        ShadToaster.of(context).show(
          const ShadToast.destructive(
            title: Text('Health Connect'),
            description: Text('Health Connect is not connected.'),
          ),
        );
      }
      return;
    }

    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final signal = SignalProvider.of<BPRecordSignal>(context, listen: false)!;

    final records = await service.readBloodPressure(thirtyDaysAgo, now);

    if (records.isNotEmpty) {
      final currentRecords = signal.value;

      final Map<DateTime, BPRecord> recordMap = {
        for (var r in currentRecords) r.date: r,
      };

      int addedCount = 0;
      for (var record in records) {
        if (!recordMap.containsKey(record.date)) {
          recordMap[record.date] = record;
          addedCount++;
        }
      }

      if (addedCount > 0) {
        final newList = recordMap.values.toList()
          ..sort((a, b) => a.date.compareTo(b.date));
        signal.value = newList;

        if (mounted) {
          ShadToaster.of(context).show(
            ShadToast(
              title: const Text('Sync Complete'),
              description: Text('Synced $addedCount new records from Health Connect.'),
            ),
          );
        }
      } else {
        if (mounted) {
          ShadToaster.of(context).show(
            ShadToast(
              title: const Text('Sync Complete'),
              description: const Text('No new records found in Health Connect.'),
            ),
          );
        }
      }
    } else {
      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast(
            title: const Text('Health Connect'),
            description: const Text('No records found in Health Connect for the last 30 days.'),
          ),
        );
      }
    }
  }
}
