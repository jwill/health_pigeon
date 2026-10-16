import 'package:flutter_test/flutter_test.dart';
import 'package:permissions_plugin_pigeon_example/main.dart';

void main() {
  testWidgets('Permissions app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Permissions (Pigeon FFI)'), findsOneWidget);
    expect(find.text('Camera Permission'), findsOneWidget);
  });
}
