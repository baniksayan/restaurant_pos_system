import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_pos_system/features/menu/widgets/menu_item_card.dart';

void main() {
  group('MenuItemCard Quantity Keyboard Input & Synchronization Tests', () {
    testWidgets(
      'Typing 67 updates to 67, backspacing to 6 updates to 6, backspacing to blank updates to 0',
      (tester) async {
        int currentQty = 1;
        final reportedQuantities = <int>[];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return MenuItemCard(
                    id: 'dish_1',
                    name: 'Butter Chicken',
                    price: 250,
                    cid: 'c1',
                    cname: 'Curries',
                    isVeg: false,
                    canOrder: true,
                    quantity: currentQty,
                    onQuantityChanged: (newQty) {
                      reportedQuantities.add(newQty);
                      setState(() {
                        currentQty = newQty;
                      });
                    },
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final textFieldFinder = find.byType(TextField);
        expect(textFieldFinder, findsOneWidget);

        // 1. Enter 67
        await tester.enterText(textFieldFinder, '67');
        await tester.pump();
        expect(reportedQuantities.last, 67);

        // 2. Backspace 7 -> now '6'
        await tester.enterText(textFieldFinder, '6');
        await tester.pump();
        expect(reportedQuantities.last, 6);

        // 3. Backspace 6 -> now '' (empty/blank)
        await tester.enterText(textFieldFinder, '');
        await tester.pumpAndSettle();
        // Crucial test: When cleared to blank, onQuantityChanged must be called with 0
        // so the cart DOES NOT still retain 6, and the card controls collapse!
        expect(reportedQuantities.last, 0);
        expect(currentQty, 0);
      },
    );

    testWidgets('Length is capped to 2 digits (max 99)', (tester) async {
      int currentQty = 1;
      final reportedQuantities = <int>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return MenuItemCard(
                  id: 'dish_2',
                  name: 'Paneer Butter Masala',
                  price: 200,
                  cid: 'c1',
                  cname: 'Curries',
                  isVeg: true,
                  canOrder: true,
                  quantity: currentQty,
                  onQuantityChanged: (newQty) {
                    reportedQuantities.add(newQty);
                    setState(() {
                      currentQty = newQty;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textFieldFinder = find.byType(TextField);

      // Try typing 99
      await tester.enterText(textFieldFinder, '99');
      await tester.pump();
      expect(reportedQuantities.last, 99);

      // Try typing a 3-digit number like 999 - capped at 2 digits
      await tester.enterText(textFieldFinder, '999');
      await tester.pump();
      // LengthLimitingTextInputFormatter caps at 2 digits
      final textField = tester.widget<TextField>(textFieldFinder);
      expect(textField.controller?.text.length, lessThanOrEqualTo(2));
    });

    testWidgets('Unfocusing when blank confirms 0 and collapses card', (
      tester,
    ) async {
      int currentQty = 5;
      final reportedQuantities = <int>[];

      final outerFocusNode = FocusNode();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Focus(
                  focusNode: outerFocusNode,
                  child: const Text('Outside'),
                ),
                StatefulBuilder(
                  builder: (context, setState) {
                    return MenuItemCard(
                      id: 'dish_3',
                      name: 'Garlic Naan',
                      price: 50,
                      cid: 'c1',
                      cname: 'Breads',
                      isVeg: true,
                      canOrder: true,
                      quantity: currentQty,
                      onQuantityChanged: (newQty) {
                        reportedQuantities.add(newQty);
                        setState(() {
                          currentQty = newQty;
                        });
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);

      // Clear the text field
      await tester.enterText(textFieldFinder, '');
      await tester.pump();
      expect(reportedQuantities.last, 0);

      // Unfocus by requesting focus on outer widget
      outerFocusNode.requestFocus();
      await tester.pumpAndSettle();

      // Card collapsed because qty == 0
      expect(currentQty, 0);
    });

    testWidgets('Leading zero formatting replaces 05 with 5', (tester) async {
      int currentQty = 1;
      final reportedQuantities = <int>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return MenuItemCard(
                  id: 'dish_4',
                  name: 'Jeera Rice',
                  price: 120,
                  cid: 'c1',
                  cname: 'Rice',
                  isVeg: true,
                  canOrder: true,
                  quantity: currentQty,
                  onQuantityChanged: (newQty) {
                    reportedQuantities.add(newQty);
                    setState(() {
                      currentQty = newQty;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textFieldFinder = find.byType(TextField);

      // Type 05
      await tester.enterText(textFieldFinder, '05');
      await tester.pump();
      expect(reportedQuantities.last, 5);
      final textField = tester.widget<TextField>(textFieldFinder);
      expect(textField.controller?.text, '5');
    });
  });
}
