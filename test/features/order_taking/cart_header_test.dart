import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_pos_system/features/menu/widgets/menu_header.dart';
import 'package:restaurant_pos_system/features/order_taking/widgets/cart_header.dart';

void main() {
  group('CartHeader & MenuHeader Visual Consistency Tests', () {
    testWidgets('MenuHeader and CartHeader have consistent height in empty state', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const MenuHeader(
                  canOrder: true,
                  tableName: 'Table 1',
                  selectedLocation: 'Main Hall',
                  showStatusTag: false,
                ),
                CartHeader(
                  hasKotItems: false,
                  hasNewItems: false,
                  tableName: 'Table 1',
                  selectedLocation: 'Main Hall',
                  totalItems: 0,
                  hasItems: false,
                  showClearAll: false,
                  onClearCart: () {},
                  onAddMore: () {},
                ),
              ],
            ),
          ),
        ),
      );

      final menuHeaderFinder = find.byType(MenuHeader);
      final cartHeaderFinder = find.byType(CartHeader);

      expect(menuHeaderFinder, findsOneWidget);
      expect(cartHeaderFinder, findsOneWidget);

      final menuSize = tester.getSize(menuHeaderFinder);
      final cartSize = tester.getSize(cartHeaderFinder);

      expect(menuSize.height, equals(cartSize.height));
    });
  });
}
