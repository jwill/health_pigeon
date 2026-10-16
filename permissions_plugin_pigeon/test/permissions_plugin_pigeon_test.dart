import 'package:flutter_test/flutter_test.dart';
import 'package:permissions_plugin_pigeon/permissions_plugin_pigeon.dart';

void main() {
  test('PermissionsApi can be instantiated', () {
    final api = PermissionsApi();
    expect(api, isNotNull);
  });
}
