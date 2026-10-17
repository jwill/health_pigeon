import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:health_pigeon_example/src/settings/settings_controller.dart';

/// Displays the various settings that can be customized by the user.
class SettingsView extends StatelessWidget {
  const SettingsView({super.key, required this.controller});

  static const routeName = '/settings';

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final serviceName = Platform.isIOS ? 'Apple Health' : 'Health Connect';
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: theme.textTheme.h4),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ShadCard(
              title: const Text('Appearance'),
              description: const Text('Customize how the app looks on your device'),
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Theme Mode', style: theme.textTheme.p),
                    ShadSelect<ThemeMode>(
                      initialValue: controller.themeMode,
                      placeholder: const Text('Select theme'),
                      minWidth: 160,
                      options: const [
                        ShadOption(value: ThemeMode.system, child: Text('System Theme')),
                        ShadOption(value: ThemeMode.light, child: Text('Light Theme')),
                        ShadOption(value: ThemeMode.dark, child: Text('Dark Theme')),
                      ],
                      selectedOptionBuilder: (context, value) {
                        return Text(switch (value) {
                          ThemeMode.system => 'System Theme',
                          ThemeMode.light => 'Light Theme',
                          ThemeMode.dark => 'Dark Theme',
                        });
                      },
                      onChanged: (mode) {
                        if (mode != null) controller.updateThemeMode(mode);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ShadCard(
              title: const Text('Display Preferences'),
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Show lowest reading per day',
                        style: theme.textTheme.p,
                      ),
                    ),
                    SignalBuilder(
                      builder: (context) => ShadSwitch(
                        value: controller.showLowestOnly.value,
                        onChanged: controller.updateShowLowestOnly,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ShadCard(
              title: const Text('Data Management'),
              description: const Text('Import, export, or sync your blood pressure data'),
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ShadButton.outline(
                      leading: const Icon(LucideIcons.upload, size: 16),
                      onPressed: () async {
                        final records = await controller.loadFile();
                        if (records != null && controller.healthConnectService.isConnected.value && context.mounted) {
                          final shouldSync = await showShadDialog<bool>(
                            context: context,
                            builder: (context) => ShadDialog(
                              title: Text('Sync to $serviceName?'),
                              description: Text('Do you want to sync ${records.length} records to $serviceName?'),
                              actions: [
                                ShadButton.outline(
                                  child: const Text('No'),
                                  onPressed: () => Navigator.pop(context, false),
                                ),
                                ShadButton(
                                  child: const Text('Yes'),
                                  onPressed: () => Navigator.pop(context, true),
                                ),
                              ],
                            ),
                          );

                          if (shouldSync == true && context.mounted) {
                            await controller.healthConnectService.batchInsertBloodPressure(records);
                            if (context.mounted) {
                              ShadToaster.of(context).show(
                                ShadToast(
                                  title: const Text('Synced'),
                                  description: Text('Records synced to $serviceName.'),
                                ),
                              );
                            }
                          }
                        }
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('Import CSV Data'),
                    ),
                    const SizedBox(height: 8),
                    ShadButton.secondary(
                      leading: const Icon(LucideIcons.download, size: 16),
                      onPressed: controller.saveFile,
                      child: const Text('Export CSV Data'),
                    ),
                    SignalBuilder(
                      builder: (context) {
                        final isConnected = controller.healthConnectService.isConnected.value;
                        final hasRecords = controller.recordsSignal.value.isNotEmpty;
                        if (isConnected && hasRecords) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: ShadButton(
                              leading: const Icon(LucideIcons.refreshCw, size: 16),
                              onPressed: () async {
                                await controller.healthConnectService
                                    .batchInsertBloodPressure(controller.recordsSignal.value);
                                if (context.mounted) {
                                  ShadToaster.of(context).show(
                                    ShadToast(
                                      title: const Text('Sync Complete'),
                                      description: Text('All records synced to $serviceName.'),
                                    ),
                                  );
                                }
                              },
                              child: Text('Sync All to $serviceName'),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    const SizedBox(height: 8),
                    SignalBuilder(
                      builder: (context) {
                        final isConnected = controller.healthConnectService.isConnected.value;
                        return ShadButton(
                          leading: Icon(
                            isConnected ? LucideIcons.checkCircle2 : LucideIcons.link,
                            size: 16,
                          ),
                          backgroundColor: isConnected ? const Color(0xFF16A34A) : null,
                          onPressed: () {
                            controller.healthConnectService.requestPermissions();
                          },
                          child: Text(
                            isConnected ? 'Connected to $serviceName' : 'Connect to $serviceName',
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),
                    ShadButton.destructive(
                      leading: const Icon(LucideIcons.trash2, size: 16),
                      onPressed: () async {
                        final confirm = await showShadDialog<bool>(
                          context: context,
                          builder: (context) => ShadDialog.alert(
                            title: const Text('Clear All Data?'),
                            description: const Text(
                              'This will permanently delete all local blood pressure records. This action cannot be undone.',
                            ),
                            actions: [
                              ShadButton.outline(
                                child: const Text('Cancel'),
                                onPressed: () => Navigator.pop(context, false),
                              ),
                              ShadButton.destructive(
                                child: const Text('Delete All'),
                                onPressed: () => Navigator.pop(context, true),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          controller.clearRecords();
                        }
                      },
                      child: const Text('Clear All Local Data'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
