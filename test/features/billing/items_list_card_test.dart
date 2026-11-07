import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_pos_system/features/billing/widgets/items_list_card.dart';
import 'package:restaurant_pos_system/features/order_taking/providers/animated_cart_provider.dart';

void main() {
  testWidgets('ItemsListCard merges repeated KOT items in the Order Items list', (tester) async {
    final cartItems = [
      CartItem(
        id: 'kot1_item1',
        name: 'Chicken Biryani',
        price: 250.0,
        quantity: 1,
        tableId: 'T1',
        tableName: 'Table 1',
        specialNotes: 'Less spicy',
      ),
      CartItem(
        id: 'kot1_item2',
        name: 'Butter Naan',
        price: 40.0,
        quantity: 2,
        tableId: 'T1',
        tableName: 'Table 1',
      ),
      CartItem(
        id: 'kot2_item1',
        name: 'Chicken Biryani',
        price: 250.0,
        quantity: 2,
        tableId: 'T1',
        tableName: 'Table 1',
        specialNotes: 'Extra raita',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ItemsListCard(cartItems: cartItems),
          ),
        ),
      ),
    );

    // Verify "Order Items" header exists
    expect(find.text('Order Items'), findsOneWidget);

    // Verify "Chicken Biryani" appears only ONCE
    expect(find.text('Chicken Biryani'), findsOneWidget);

    // Verify combined quantity is 3 (1 from KOT1 + 2 from KOT2)
    expect(find.textContaining('× 3'), findsOneWidget);

    // Verify notes are merged
    expect(find.text('Note: Less spicy, Extra raita'), findsOneWidget);

    // Verify "Butter Naan" appears once with quantity 2
    expect(find.text('Butter Naan'), findsOneWidget);
    expect(find.textContaining('× 2'), findsOneWidget);
  });
}
