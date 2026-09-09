import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:restaurant_pos_system/core/services/app_version_service.dart';
import 'package:restaurant_pos_system/shared/widgets/feedback/app_version_label.dart';

void main() {
  group('AppVersionService', () {
    tearDown(() {
      AppVersionService.reset();
    });

    test(
      'returns empty string when not initialized and no hardcoded fallback',
      () {
        AppVersionService.reset();
        expect(AppVersionService.currentVersion, isEmpty);
        expect(AppVersionService.displayVersion, isEmpty);
      },
    );

    test(
      'dynamically reads version from platform build (pubspec.yaml)',
      () async {
        PackageInfo.setMockInitialValues(
          appName: 'Restaurant POS',
          packageName: 'com.restaurant.pos',
          version: '1.2.3',
          buildNumber: '4',
          buildSignature: '',
        );

        await AppVersionService.init();
        expect(AppVersionService.currentVersion, equals('Version 1.2.3'));
        expect(AppVersionService.displayVersion, equals('Version 1.2.3'));
      },
    );

    test('formats standard 3-segment version correctly as Version 1.1.1', () {
      AppVersionService.setMockVersion('1.1.1');
      expect(AppVersionService.currentVersion, equals('Version 1.1.1'));
      expect(AppVersionService.displayVersion, equals('Version 1.1.1'));
    });

    test('formats 4-segment version correctly as Version 1.1.1.1', () {
      AppVersionService.setMockVersion('1.1.1.1');
      expect(AppVersionService.currentVersion, equals('Version 1.1.1.1'));
      expect(AppVersionService.displayVersion, equals('Version 1.1.1.1'));
    });

    test(
      'formats QA build hyphen suffix into dot notation Version 1.1.40.1',
      () {
        AppVersionService.setMockVersion('1.1.40-1');
        expect(AppVersionService.currentVersion, equals('Version 1.1.40.1'));
        expect(AppVersionService.displayVersion, equals('Version 1.1.40.1'));
      },
    );

    test('strips accidental leading v or Version prefixes cleanly', () {
      AppVersionService.setMockVersion('v1.0.2');
      expect(AppVersionService.currentVersion, equals('Version 1.0.2'));
      expect(AppVersionService.displayVersion, equals('Version 1.0.2'));
    });
  });

  group('AppVersionLabel Widget', () {
    tearDown(() {
      AppVersionService.reset();
    });

    testWidgets('renders current app version accurately as Version X.X.X', (
      tester,
    ) async {
      AppVersionService.setMockVersion('1.1.1.1');

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: AppVersionLabel())),
      );

      expect(find.text('Version 1.1.1.1'), findsOneWidget);
    });
  });
}
