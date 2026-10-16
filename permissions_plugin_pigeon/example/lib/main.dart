import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permissions_plugin_pigeon/permissions_plugin_pigeon.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.permissionsApi});

  final PermissionsApi? permissionsApi;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Permissions Pigeon FFI Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      home: PermissionsHomePage(permissionsApi: permissionsApi),
    );
  }
}

class PermissionsHomePage extends StatefulWidget {
  const PermissionsHomePage({super.key, this.permissionsApi});

  final PermissionsApi? permissionsApi;

  @override
  State<PermissionsHomePage> createState() => _PermissionsHomePageState();
}

class _PermissionsHomePageState extends State<PermissionsHomePage> {
  late final PermissionsApi _permissionsApi;

  static const String _cameraPermission = 'android.permission.CAMERA';

  String _platformVersion = 'Loading...';
  bool? _isCameraGranted;
  bool? _shouldShowRationale;
  String _lastActionStatus = 'Idle';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.permissionsApi != null) {
      _permissionsApi = widget.permissionsApi!;
    } else {
      try {
        if (Platform.isAndroid) {
          _permissionsApi = PermissionsApi.createWithNativeInteropApi();
        } else {
          _permissionsApi = PermissionsApi();
        }
      } catch (_) {
        _permissionsApi = PermissionsApi();
      }
    }
    _loadInitialState();
  }

  Future<void> _loadInitialState() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _fetchPlatformVersion(),
      _checkPermissionStatus(),
    ]);
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchPlatformVersion() async {
    try {
      final version = await _permissionsApi.getPlatformVersion();
      if (mounted) {
        setState(() {
          _platformVersion = version;
        });
      }
    } on PlatformException catch (e) {
      if (mounted) {
        setState(() {
          _platformVersion = 'Failed to get platform version: ${e.message}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _platformVersion = 'Environment note: $e';
        });
      }
    }
  }

  Future<void> _checkPermissionStatus() async {
    try {
      final granted = await _permissionsApi.checkPermission(_cameraPermission);
      final rationale = await _permissionsApi
          .shouldShowRequestPermissionRationale(_cameraPermission);
      if (mounted) {
        setState(() {
          _isCameraGranted = granted;
          _shouldShowRationale = rationale;
        });
      }
    } on PlatformException catch (e) {
      if (mounted) {
        setState(() {
          _lastActionStatus = 'Check failed: ${e.message}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _lastActionStatus = 'Check status: $e';
        });
      }
    }
  }

  Future<void> _checkAndRequest() async {
    setState(() => _isLoading = true);
    try {
      final result = await _permissionsApi
          .checkAndRequestPermission(_cameraPermission);
      String statusMessage;
      if (result == 1) {
        statusMessage = 'Camera permission is already granted!';
      } else if (result == -2) {
        statusMessage =
            'User previously denied permission. Showing rationale recommendation.';
      } else {
        statusMessage = 'Native permission dialog requested.';
      }

      await _checkPermissionStatus();

      if (mounted) {
        setState(() {
          _lastActionStatus = statusMessage;
          _isLoading = false;
        });
      }
    } on PlatformException catch (e) {
      if (mounted) {
        setState(() {
          _lastActionStatus = 'Request failed: ${e.message}';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _lastActionStatus = 'Request error: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _directRequest() async {
    setState(() => _isLoading = true);
    try {
      await _permissionsApi.requestPermission(_cameraPermission);
      await _checkPermissionStatus();
      if (mounted) {
        setState(() {
          _lastActionStatus = 'Direct permission request triggered.';
          _isLoading = false;
        });
      }
    } on PlatformException catch (e) {
      if (mounted) {
        setState(() {
          _lastActionStatus = 'Direct request failed: ${e.message}';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _lastActionStatus = 'Direct request error: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openSettings() async {
    setState(() => _isLoading = true);
    try {
      final success = await _permissionsApi.openAppSettings();
      if (mounted) {
        setState(() {
          _lastActionStatus = success
              ? 'Opened App Settings. Modify permissions there and return to refresh.'
              : 'Failed to open App Settings.';
          _isLoading = false;
        });
      }
    } on PlatformException catch (e) {
      if (mounted) {
        setState(() {
          _lastActionStatus = 'Error opening settings: ${e.message}';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _lastActionStatus = 'Settings error: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isGranted = _isCameraGranted == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Permissions (Pigeon FFI)'),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Status',
            onPressed: _isLoading ? null : _loadInitialState,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Platform Info Card
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.android,
                        size: 36,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Platform Environment',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _platformVersion,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Permission Status Card
              Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.camera_alt_outlined,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Camera Permission',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Chip(
                            avatar: Icon(
                              isGranted ? Icons.check_circle : Icons.cancel,
                              size: 18,
                              color: isGranted ? Colors.green : Colors.redAccent,
                            ),
                            label: Text(
                              isGranted ? 'Granted' : 'Not Granted',
                              style: TextStyle(
                                color: isGranted ? Colors.green : Colors.redAccent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            backgroundColor: (isGranted
                                    ? Colors.green
                                    : Colors.redAccent)
                                .withValues(alpha: 0.12),
                            side: BorderSide.none,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Target: $_cameraPermission',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontFamily: 'monospace',
                        ),
                      ),
                      if (_shouldShowRationale == true) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.shade700),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.amber.shade900,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Rationale recommended: Permission was previously denied.',
                                  style: TextStyle(
                                    color: Colors.amber.shade900,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Action Buttons
              FilledButton.icon(
                onPressed: _isLoading ? null : _checkAndRequest,
                icon: const Icon(Icons.security),
                label: const Text('Check & Request Permission'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _directRequest,
                icon: const Icon(Icons.touch_app_outlined),
                label: const Text('Direct Request Dialog'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _openSettings,
                icon: const Icon(Icons.settings_outlined),
                label: const Text('Manage / Revoke in App Settings'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _isLoading ? null : _checkPermissionStatus,
                icon: const Icon(Icons.sync),
                label: const Text('Re-check Status'),
              ),

              const SizedBox(height: 20),

              // Status Logs
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Last Action Status:',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _lastActionStatus,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
