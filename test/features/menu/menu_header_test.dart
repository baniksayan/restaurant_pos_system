import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_pos_system/features/menu/widgets/menu_header.dart';

void main() {
  group('MenuHeader Widget Tests', () {
    testWidgets('shows ORDERING tag when canOrder is true and showStatusTag is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MenuHeader(
              canOrder: true,
              tableName: 'Table 1',
              showStatusTag: true,
            ),
          ),
        ),
      );

      expect(find.text('Menu'), findsOneWidget);
      expect(find.text('Table 1'), findsOneWidget);
      expect(find.text('ORDERING'), findsOneWidget);
      expect(find.text('VIEW ONLY'), findsNothing);
    });

    testWidgets('shows VIEW ONLY tag when canOrder is false and showStatusTag is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MenuHeader(
              canOrder: false,
              tableName: 'Table 1',
              showStatusTag: true,
            ),
          ),
        ),
      );

      expect(find.text('Menu'), findsOneWidget);
      expect(find.text('VIEW ONLY'), findsOneWidget);
      expect(find.text('ORDERING'), findsNothing);
    });

    testWidgets(
      'does NOT show ORDERING or VIEW ONLY tags when showStatusTag is false',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: MenuHeader(
                canOrder: true,
                tableName: 'Table 1',
                showStatusTag: false,
              ),
            ),
          ),
        );

        expect(find.text('Menu'), findsOneWidget);
        expect(find.text('ORDERING'), findsNothing);
        expect(find.text('VIEW ONLY'), findsNothing);
      },
    );
  });
}
