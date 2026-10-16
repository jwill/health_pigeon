import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:permissions_plugin_pigeon/permissions_plugin_pigeon.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('getPlatformVersion test', (WidgetTester tester) async {
    final PermissionsApi api = PermissionsApi();
    final String version = await api.getPlatformVersion();
    expect(version.isNotEmpty, true);
  });
}
