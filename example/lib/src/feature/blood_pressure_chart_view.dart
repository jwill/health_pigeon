import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:health_pigeon_example/src/data/bp_record.dart';
import 'package:health_pigeon_example/src/data/bp_record_signal.dart';
import 'package:health_pigeon_example/src/settings/settings_controller.dart';
import 'package:flutter/material.dart';

import 'package:d_chart/d_chart.dart';
import 'package:signals/signals_flutter.dart';
import 'package:widgets_to_image/widgets_to_image.dart';

/// Displays a list of SampleItems.
class BloodPressureChartView extends StatefulWidget {
  const BloodPressureChartView({
    super.key,
  });

  static const routeName = '/b';

  @override
  State<BloodPressureChartView> createState() => _BloodPressureChartViewState();
}

class _BloodPressureChartViewState extends State<BloodPressureChartView> {
  late final WidgetsToImageController _imageController;

  @override
  void initState() {
    super.initState();
    _imageController = WidgetsToImageController();
  }

  @override
  Widget build(BuildContext context) {
    final signal = SignalProvider.of<BPRecordSignal>(context, listen: false)!;

    return SignalBuilder(
      builder: (context) {
        final items = signal.value;

        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.lineChart,
                  size: 48,
                  color: ShadTheme.of(context).colorScheme.mutedForeground,
                ),
                const SizedBox(height: 12),
                Text(
                  'No blood pressure records for chart',
                  style: ShadTheme.of(context).textTheme.muted,
                ),
              ],
            ),
          );
        }

        return Stack(
          children: [
            Positioned.fill(
              child: WidgetsToImage(
                controller: _imageController,
                child: _buildChart(context, items),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 16,
              child: FloatingActionButton(
                heroTag: 'export_chart_fab',
                onPressed: () async {
                  var bytes = await _imageController.capture();
                  if (bytes != null) {
                    SettingsController.saveImage(bytes);
                  }
                },
                tooltip: 'Export Chart',
                child: const Icon(LucideIcons.camera),
              ),
            ),
          ],
        );
      },
    );
  }

  Color pickColorForBP(BPRecord record) {
    if (record.systolic <= 120 && record.diastolic <= 80) {
      return Colors.green;
    } else if (record.systolic <= 130 && record.diastolic <= 85) {
      return Colors.yellow;
    } else if (record.systolic >= 140 || record.diastolic >= 90) {
      return Colors.red;
    } else {
      return Colors.orange;
    }
  }

  Widget _buildChart(BuildContext context, List items) {
    final colorScheme = Theme.of(context).colorScheme;
    List<TimeData> systolic = items
        .map((e) => TimeData(domain: e.date, measure: e.systolic))
        .toList();
    List<TimeData> diastolic = items
        .map((e) => TimeData(domain: e.date, measure: e.diastolic))
        .toList();

    final timeGroupList = [
      TimeGroup(
        id: '1',
        color: colorScheme.secondary,
        data: systolic,
      ),
      TimeGroup(
        id: '2',
        color: colorScheme.tertiary,
        data: diastolic,
      ),
      // TimeGroup(id: '3', data: baselineSystolic),
      // TimeGroup(id: '4', data: baselineDiastolic)
    ];

    return Padding(
        padding: const EdgeInsets.all(8.0),
        child: DChartLineT(
          allowSliding: true,
          measureAxis: const MeasureAxis(
              numericViewport: NumericViewport(60, 155), showLine: true),
          //configRenderLine: ConfigRenderLine(includePoints: true),
          groupList: timeGroupList,
        ));
  }
}
