import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_pos_system/core/constants/app_strings.dart';

void main() {
  group('Auth Error Handling and AppStrings Tests', () {
    test('invalidCredentials string is user-friendly and actionable', () {
      expect(
        AppStrings.auth.invalidCredentials,
        'Invalid username or password. Please verify credentials.',
      );
    });

    test('openNavigationDrawer string is defined in AppStrings', () {
      expect(
        AppStrings.openNavigationDrawer,
        'Open navigation drawer',
      );
    });

    test('clear string is defined in AppStrings', () {
      expect(
        AppStrings.clear,
        'Clear',
      );
    });
  });
}
