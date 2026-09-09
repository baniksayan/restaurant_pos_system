import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_pos_system/core/constants/storage_keys.dart';
import 'package:restaurant_pos_system/core/permissions/app_permission_service.dart';
import 'package:restaurant_pos_system/core/permissions/widgets/permission_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StorageKeys', () {
    test('hasCheckedInitialPermissions key is defined correctly', () {
      expect(
        StorageKeys.hasCheckedInitialPermissions,
        'has_checked_initial_permissions',
      );
    });
  });

  group('PermissionDialog', () {
    testWidgets('renders title, message, and button labels', (
      WidgetTester tester,
    ) async {
      bool primaryPressed = false;
      bool secondaryPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PermissionDialog(
              title: 'Storage Access',
              message: 'Storage permission is required to save report files.',
              primaryButtonText: 'Allow',
              secondaryButtonText: 'Cancel',
              icon: Icons.folder,
              onPrimaryPressed: () {
                primaryPressed = true;
              },
              onSecondaryPressed: () {
                secondaryPressed = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Storage Access'), findsOneWidget);
      expect(
        find.text('Storage permission is required to save report files.'),
        findsOneWidget,
      );
      expect(find.text('Allow'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.byIcon(Icons.folder), findsOneWidget);

      await tester.tap(find.text('Allow'));
      await tester.pump();
      expect(primaryPressed, isTrue);

      await tester.tap(find.text('Cancel'));
      await tester.pump();
      expect(secondaryPressed, isTrue);
    });
  });

  group('AppPermissionService', () {
    test('ensureStoragePermission completes safely', () async {
      final result = await AppPermissionService.ensureStoragePermission();
      expect(result, isA<bool>());
    });
  });
}
