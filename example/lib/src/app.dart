import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:health_pigeon_example/src/data/bp_record_signal.dart';
import 'package:health_pigeon_example/src/feature/blood_pressure_tab_view.dart';
import 'package:health_pigeon_example/src/feature/blood_pressure_item_details_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:signals/signals_flutter.dart';

import 'package:health_pigeon_example/src/feature/blood_pressure_list_view.dart';
import 'package:health_pigeon_example/src/settings/settings_controller.dart';
import 'package:health_pigeon_example/src/settings/settings_view.dart';

// final healthConnectSignal = signal(false);

/// The Widget that configures your application.
class MyApp extends StatelessWidget {
  MyApp({super.key, required this.settingsController, required this.signal});

  final SettingsController settingsController;
  final BPRecordSignal signal;



  @override
  Widget build(BuildContext bcontext) {
    // Glue the SettingsController to the MaterialApp.
    //
    // The ListenableBuilder Widget listens to the SettingsController for changes.
    // Whenever the user updates their settings, the MaterialApp is rebuilt.


    return SignalProvider<BPRecordSignal>(
        create: () => signal,
        child: ListenableBuilder(
          listenable: settingsController,
          builder: (BuildContext context, Widget? child) {
            return ShadApp(
              restorationScopeId: 'app',
              themeMode: settingsController.themeMode,
              debugShowCheckedModeBanner: false,
              // Define a function to handle named routes in order to support
              // Flutter web url navigation and deep linking.
              onGenerateRoute: (RouteSettings routeSettings) {
                return MaterialPageRoute<void>(
                  settings: routeSettings,
                  builder: (BuildContext context) {
                    switch (routeSettings.name) {
                      case SettingsView.routeName:
                        return SettingsView(controller: settingsController);
                      case BloodPressureItemDetailsView.routeName:
                        return BloodPressureItemDetailsView();
                      case BloodPressureTabView.routeName:
                        return BloodPressureTabView(controller: settingsController);
                      default:
                        return BloodPressureListView(controller: settingsController);
                    }
                  },
                );
              },
            );
          },
        ));
  }
}
