import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:health_pigeon_example/src/data/bp_record_signal.dart';
import 'package:health_pigeon_example/src/feature/blood_pressure_tab_view.dart';
import 'package:health_pigeon_example/src/feature/blood_pressure_item_details_view.dart';
import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import 'package:health_pigeon_example/src/settings/settings_controller.dart';
import 'package:health_pigeon_example/src/settings/settings_view.dart';

// final healthConnectSignal = signal(false);

/// The Widget that configures your application.
class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.settingsController, required this.signal});

  final SettingsController settingsController;
  final BPRecordSignal signal;

  @override
  Widget build(BuildContext bcontext) {
    return SignalProvider<BPRecordSignal>.value(
      value: signal,
      child: ListenableBuilder(
        listenable: settingsController,
        builder: (BuildContext context, Widget? child) {
          return ShadApp(
            restorationScopeId: 'app',
            themeMode: settingsController.themeMode,
            debugShowCheckedModeBanner: false,
            theme: ShadThemeData(
              brightness: Brightness.light,
              colorScheme: const ShadSlateColorScheme.light(),
            ),
            darkTheme: ShadThemeData(
              brightness: Brightness.dark,
              colorScheme: const ShadSlateColorScheme.dark(),
            ),
            onGenerateRoute: (RouteSettings routeSettings) {
              return MaterialPageRoute<void>(
                settings: routeSettings,
                builder: (BuildContext context) {
                  switch (routeSettings.name) {
                    case SettingsView.routeName:
                      return SettingsView(controller: settingsController);
                    case BloodPressureItemDetailsView.routeName:
                      return const BloodPressureItemDetailsView();
                    case BloodPressureTabView.routeName:
                    default:
                      return BloodPressureTabView(controller: settingsController);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
