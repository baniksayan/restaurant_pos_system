import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos_system/features/menu/providers/menu_provider.dart';
import 'package:restaurant_pos_system/features/order_taking/providers/animated_cart_provider.dart';
import 'package:restaurant_pos_system/features/order_taking/widgets/cart_item_card.dart';
import 'package:restaurant_pos_system/features/order_taking/widgets/cart_items_list.dart';
import 'package:restaurant_pos_system/features/order_taking/widgets/kot_section_widget.dart';

void main() {
  Widget buildTestableWidget({required Widget child}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AnimatedCartProvider()),
        ChangeNotifierProvider(create: (_) => MenuProvider()),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: child,
          ),
        ),
      ),
    );
  }

  group('KOT Page Compact Layout Tests', () {
    testWidgets('CartItemCard renders compact pending KOT item with height under 90px', (
      tester,
    ) async {
      final item = CartItem(
        id: '1',
        name: 'Chicken Dum Biryani',
        price: 260.0,
        quantity: 2,
        tableId: 'T1',
        tableName: 'Table 1',
        specialNotes: 'Extra raita',
      );

      await tester.pumpWidget(
        buildTestableWidget(
          child: CartItemCard(
            item: item,
            onEdit: () {},
          ),
        ),
      );

      // Verify item details are displayed
      expect(find.text('Chicken Dum Biryani'), findsOneWidget);
      expect(find.text('2'), findsOneWidget); // Quantity stepper
      expect(find.textContaining('Extra raita'), findsOneWidget); // Compact note chip

      // Check card size is compact (< 90px height)
      final cardFinder = find.byType(CartItemCard);
      final cardSize = tester.getSize(cardFinder);
      expect(cardSize.height, lessThan(90.0));
    });

    testWidgets('CartItemCard renders compact KOT-generated read-only item with height under 80px', (
      tester,
    ) async {
      final item = CartItem(
        id: '2',
        name: 'Butter Naan',
        price: 45.0,
        quantity: 3,
        tableId: 'T1',
        tableName: 'Table 1',
        isKotGenerated: true,
        kotNumber: 'KOT-101',
      );

      await tester.pumpWidget(
        buildTestableWidget(
          child: CartItemCard(
            item: item,
            onEdit: () {},
            showKotBadge: true,
          ),
        ),
      );

      // Verify KOT status badge and quantity
      expect(find.text('Butter Naan'), findsOneWidget);
      expect(find.text('KOT #KOT-101'), findsOneWidget);
      expect(find.text('Qty: 3'), findsOneWidget);

      // Info icon is removed
      expect(find.byIcon(Icons.info_outline_rounded), findsNothing);

      // Check card size is compact (< 80px height)
      final cardFinder = find.byType(CartItemCard);
      final cardSize = tester.getSize(cardFinder);
      expect(cardSize.height, lessThan(80.0));
    });

    testWidgets('CartItemCard inside grouped frame hides redundant KOT badge by default', (
      tester,
    ) async {
      final item = CartItem(
        id: '3',
        name: 'Dal Makhani',
        price: 180.0,
        quantity: 2,
        tableId: 'T1',
        tableName: 'Table 1',
        isKotGenerated: true,
        kotNumber: 'KOT-1',
      );

      await tester.pumpWidget(
        buildTestableWidget(
          child: CartItemCard(
            item: item,
            onEdit: () {},
          ),
        ),
      );

      // Verify item details and quantity badge without redundant per-item KOT badge
      expect(find.text('Dal Makhani'), findsOneWidget);
      expect(find.text('Qty: 2'), findsOneWidget);
      expect(find.text('KOT #KOT-1'), findsNothing);
      expect(find.byIcon(Icons.info_outline_rounded), findsNothing);
    });

    testWidgets('KotSectionWidget renders compact section header and items list', (
      tester,
    ) async {
      final items = [
        CartItem(
          id: '1',
          name: 'Paneer Butter Masala',
          price: 220.0,
          quantity: 1,
          tableId: 'T1',
          tableName: 'Table 1',
        ),
        CartItem(
          id: '2',
          name: 'Garlic Naan',
          price: 60.0,
          quantity: 2,
          tableId: 'T1',
          tableName: 'Table 1',
        ),
      ];

      await tester.pumpWidget(
        buildTestableWidget(
          child: KotSectionWidget(
            backgroundColor: const Color(0xFFFFF7ED),
            headerIcon: Icons.dinner_dining_rounded,
            headerTitle: 'New Items (Pending KOT)',
            headerColor: const Color(0xFFEA580C),
            itemCountText: '2 Items',
            badgeColor: const Color(0xFFF97316),
            child: CartItemsList(
              items: items,
              onEditItem: (_) {},
            ),
          ),
        ),
      );

      // Verify section header
      expect(find.text('New Items (Pending KOT)'), findsOneWidget);
      expect(find.text('2 Items'), findsOneWidget);

      // Verify all items are rendered
      expect(find.text('Paneer Butter Masala'), findsOneWidget);
      expect(find.text('Garlic Naan'), findsOneWidget);

      // Verify items fit compactly: Total height for 2 items + section header is under 220px
      final sectionFinder = find.byType(KotSectionWidget);
      final sectionSize = tester.getSize(sectionFinder);
      expect(sectionSize.height, lessThan(220.0));
    });

    testWidgets('KotSectionWidget displays whole-ticket kitchen note under the combined box items', (
      tester,
    ) async {
      final items = [
        CartItem(
          id: '1',
          name: 'Mutton Kasha',
          price: 350.0,
          quantity: 2,
          tableId: 'T1',
          tableName: 'Table 1',
          isKotGenerated: true,
          kotNumber: 'KOT-1',
        ),
      ];

      await tester.pumpWidget(
        buildTestableWidget(
          child: KotSectionWidget(
            backgroundColor: const Color(0xFFF5F3FF),
            headerIcon: Icons.receipt_long_rounded,
            headerTitle: 'KOT #1',
            headerColor: const Color(0xFF7C3AED),
            itemCountText: '2 Items',
            badgeColor: const Color(0xFF6D28D9),
            kotNote: 'Make it very spicy and serve piping hot',
            child: CartItemsList(
              items: items,
              onEditItem: (_) {},
            ),
          ),
        ),
      );

      // Verify header and items
      expect(find.text('KOT #1'), findsOneWidget);
      expect(find.text('Mutton Kasha'), findsOneWidget);

      // Verify whole-KOT kitchen note footer under the items
      expect(find.text('Note for Kitchen'), findsOneWidget);
      expect(find.text('KOT Instruction'), findsNothing); // Removed duplicate label
      expect(
        find.text('Make it very spicy and serve piping hot'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.soup_kitchen_rounded), findsOneWidget);
    });

    testWidgets(
      'Multiple KOTs render in separate unified boxes with their own KOT numbers and notes',
      (tester) async {
        final kot1Items = [
          CartItem(
            id: '1',
            name: 'Chicken Dum Biryani',
            price: 260.0,
            quantity: 1,
            tableId: 'T1',
            tableName: 'Table 1',
            isKotGenerated: true,
            kotNumber: '1',
            kotNote: 'Less spicy for biryani',
          ),
        ];

        final kot2Items = [
          CartItem(
            id: '2',
            name: 'Garlic Naan',
            price: 50.0,
            quantity: 2,
            tableId: 'T1',
            tableName: 'Table 1',
            isKotGenerated: true,
            kotNumber: '2',
            kotNote: 'Serve with extra butter',
          ),
          CartItem(
            id: '3',
            name: 'Butter Chicken',
            price: 320.0,
            quantity: 1,
            tableId: 'T1',
            tableName: 'Table 1',
            isKotGenerated: true,
            kotNumber: '2',
            kotNote: 'Serve with extra butter',
          ),
        ];

        await tester.pumpWidget(
          buildTestableWidget(
            child: Column(
              children: [
                KotSectionWidget(
                  backgroundColor: const Color(0xFFF5F3FF),
                  headerIcon: Icons.receipt_long_rounded,
                  headerTitle: 'KOT #1',
                  headerColor: const Color(0xFF7C3AED),
                  itemCountText: '1 Item',
                  badgeColor: const Color(0xFF6D28D9),
                  kotNote: 'Less spicy for biryani',
                  child: CartItemsList(
                    items: kot1Items,
                    onEditItem: (_) {},
                  ),
                ),
                const SizedBox(height: 10),
                KotSectionWidget(
                  backgroundColor: const Color(0xFFF5F3FF),
                  headerIcon: Icons.receipt_long_rounded,
                  headerTitle: 'KOT #2',
                  headerColor: const Color(0xFF7C3AED),
                  itemCountText: '3 Items',
                  badgeColor: const Color(0xFF6D28D9),
                  kotNote: 'Serve with extra butter',
                  child: CartItemsList(
                    items: kot2Items,
                    onEditItem: (_) {},
                  ),
                ),
              ],
            ),
          ),
        );

        // Verify separate KOT section headers
        expect(find.text('KOT #1'), findsOneWidget);
        expect(find.text('KOT #2'), findsOneWidget);
        expect(find.text('1 Item'), findsOneWidget);
        expect(find.text('3 Items'), findsOneWidget);

        // Verify items inside their respective sections
        expect(find.text('Chicken Dum Biryani'), findsOneWidget);
        expect(find.text('Garlic Naan'), findsOneWidget);
        expect(find.text('Butter Chicken'), findsOneWidget);

        // Verify both separate notes for kitchen
        expect(find.text('Less spicy for biryani'), findsOneWidget);
        expect(find.text('Serve with extra butter'), findsOneWidget);
        expect(find.text('Note for Kitchen'), findsNWidgets(2));
      },
    );
  });
}
