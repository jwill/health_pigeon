import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:health_pigeon_example/src/feature/blood_pressure_chart_view.dart';
import 'package:health_pigeon_example/src/feature/blood_pressure_input_bottom_sheet.dart';
import 'package:health_pigeon_example/src/feature/blood_pressure_list_view.dart';
import 'package:health_pigeon_example/src/settings/settings_controller.dart';
import 'package:health_pigeon_example/src/settings/settings_view.dart';

class BloodPressureTabView extends StatefulWidget {
  const BloodPressureTabView({super.key, required this.controller});

  final SettingsController controller;

  static const routeName = '/';

  @override
  State<BloodPressureTabView> createState() => _BloodPressureTabViewState();
}

class _BloodPressureTabViewState extends State<BloodPressureTabView> {
  String _selectedTab = 'data';

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Blood Pressure Tracking',
          style: theme.textTheme.h4,
        ),
        actions: [
          ShadIconButton.ghost(
            icon: const Icon(LucideIcons.settings, size: 20),
            onPressed: () {
              Navigator.restorablePushNamed(context, SettingsView.routeName);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ShadTabs<String>(
            value: _selectedTab,
            onChanged: (val) => setState(() => _selectedTab = val),
            tabs: [
              ShadTab(
                value: 'data',
                expandContent: true,
                leading: const Icon(LucideIcons.table, size: 16),
                content: BloodPressureListView(controller: widget.controller),
                child: const Text('My Data'),
              ),
              ShadTab(
                value: 'chart',
                expandContent: true,
                leading: const Icon(LucideIcons.lineChart, size: 16),
                content: const BloodPressureChartView(),
                child: const Text('Chart'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _selectedTab == 'data'
          ? FloatingActionButton(
              heroTag: 'add_reading_fab',
              onPressed: () {
                showShadSheet(
                  context: context,
                  side: ShadSheetSide.bottom,
                  builder: (context) {
                    return BloodPressureInputBottomSheet(
                      healthConnectService: widget.controller.healthConnectService,
                    );
                  },
                );
              },
              tooltip: 'Add Reading',
              child: const Icon(LucideIcons.plus),
            )
          : null,
    );
  }
}
