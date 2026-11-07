import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos_system/core/constants/storage_keys.dart';
import 'package:restaurant_pos_system/data/models/menu_api_res_model.dart';
import 'package:restaurant_pos_system/features/dashboard/providers/navigation_provider.dart';
import 'package:restaurant_pos_system/features/dashboard/providers/table_provider.dart';
import 'package:restaurant_pos_system/features/menu/providers/menu_provider.dart';
import 'package:restaurant_pos_system/features/menu/views/menu_view.dart';
import 'package:restaurant_pos_system/features/menu/widgets/cart_footer.dart';
import 'package:restaurant_pos_system/features/menu/widgets/category_tabs.dart';
import 'package:restaurant_pos_system/features/menu/widgets/menu_search_bar.dart';
import 'package:restaurant_pos_system/features/order_taking/providers/animated_cart_provider.dart';

void main() {
  group('Glassmorphic Menu Components Tests', () {
    late MenuProvider menuProvider;
    late NavigationProvider navProvider;
    late TableProvider tableProvider;
    late AnimatedCartProvider cartProvider;
    late Directory tempDir;

    setUpAll(() async {
      tempDir = Directory.systemTemp.createTempSync('glass_menu_test_');
      Hive.init(tempDir.path);
      await Hive.openBox(StorageKeys.posBox);
      await Hive.openBox(StorageKeys.authBox);
      await Hive.openBox(StorageKeys.tablesBox);
      await Hive.openBox(StorageKeys.ordersBox);
      await Hive.openBox(StorageKeys.syncQueueBox);
    });

    tearDownAll(() async {
      await Hive.close();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    setUp(() {
      menuProvider = MenuProvider();
      navProvider = NavigationProvider();
      tableProvider = TableProvider();
      cartProvider = AnimatedCartProvider();
    });

    Widget buildTestHarness({Widget? child}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<MenuProvider>.value(value: menuProvider),
          ChangeNotifierProvider<NavigationProvider>.value(value: navProvider),
          ChangeNotifierProvider<TableProvider>.value(value: tableProvider),
          ChangeNotifierProvider<AnimatedCartProvider>.value(
            value: cartProvider,
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body:
                child ??
                const MenuView(selectedTableId: 'T1', tableName: 'Table 1'),
          ),
        ),
      );
    }

    testWidgets('CartFooter renders compact floating pill with item count and Go to Cart', (
      tester,
    ) async {
      bool orderPlaced = false;

      // When items count is 0, CartFooter is empty
      await tester.pumpWidget(
        buildTestHarness(
          child: CartFooter(onPlaceOrder: () => orderPlaced = true),
        ),
      );
      expect(find.text('Go to Cart'), findsNothing);

      // Add item to cart
      cartProvider.addItem(
        'dish_1',
        'Paneer Butter Masala',
        220,
        'cat_1',
        'Main Course',
      );
      await tester.pumpWidget(
        buildTestHarness(
          child: CartFooter(onPlaceOrder: () => orderPlaced = true),
        ),
      );
      await tester.pumpAndSettle();

      // Verify item badge & Go to Cart button
      expect(find.text('1 item'), findsOneWidget);
      expect(find.text('Go to Cart'), findsOneWidget);
      expect(find.byIcon(Icons.shopping_bag_outlined), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);

      // Tap Go to Cart
      await tester.tap(find.text('Go to Cart'));
      await tester.pump();
      expect(orderPlaced, isTrue);

      // Add second item
      cartProvider.addItem(
        'dish_2',
        'Garlic Naan',
        60,
        'cat_1',
        'Main Course',
      );
      await tester.pump();
      expect(find.text('2 items'), findsOneWidget);
    });

    testWidgets('MenuSearchBar renders refined translucent search input', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestHarness(child: const MenuSearchBar()),
      );

      expect(find.text('Search dishes...'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);

      // Enter query
      await tester.enterText(find.byType(TextField), 'Biryani');
      await tester.pump();
      expect(menuProvider.searchQuery, 'Biryani');
      expect(find.byIcon(Icons.clear), findsOneWidget);

      // Clear query
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();
      expect(menuProvider.searchQuery, '');
    });

    testWidgets('CategoryTabs renders glassmorphic chips and handles selection', (
      tester,
    ) async {
      menuProvider.setMenuItemsForTesting([
        Data(
          productId: '1',
          productName: 'Butter Chicken',
          categoryId: 'c1',
          categoryName: 'Curries',
          productPrice: 320,
          pureVeg: false,
        ),
        Data(
          productId: '2',
          productName: 'Dal Makhani',
          categoryId: 'c1',
          categoryName: 'Curries',
          productPrice: 240,
          pureVeg: true,
        ),
      ]);

      await tester.pumpWidget(
        buildTestHarness(child: const CategoryTabs()),
      );
      await tester.pumpAndSettle();

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Veg Only'), findsOneWidget);
      expect(find.text('Curries'), findsOneWidget);

      // Tap Veg Only
      await tester.tap(find.text('Veg Only'));
      await tester.pumpAndSettle();
      expect(menuProvider.selectedDietaryFilter, 'Veg');

      // Tap Curries
      await tester.tap(find.text('Curries'));
      await tester.pumpAndSettle();
      expect(menuProvider.selectedCategory, 'Curries');
    });

    testWidgets('MenuView renders frosted-glass search section and floating cart bar', (
      tester,
    ) async {
      menuProvider.setMenuItemsForTesting([
        Data(
          productId: '1',
          productName: 'Paneer Tikka',
          categoryId: 'c1',
          categoryName: 'Starters',
          productPrice: 200,
          pureVeg: true,
        ),
      ]);

      await tester.pumpWidget(buildTestHarness());
      await tester.pumpAndSettle();

      // Header components exist inside frosted glass section
      expect(find.byType(MenuSearchBar), findsOneWidget);
      expect(find.byType(CategoryTabs), findsOneWidget);
      expect(find.text('Paneer Tikka'), findsOneWidget);

      // Cart is empty initially, so CartFooter is not visible
      expect(find.text('Go to Cart'), findsNothing);

      // Add item to cart
      cartProvider.addItem('1', 'Paneer Tikka', 200, 'c1', 'Starters');
      await tester.pumpAndSettle();

      // Floating CartFooter is now visible
      expect(find.text('Go to Cart'), findsOneWidget);
      expect(find.text('1 item'), findsOneWidget);
    });
  });
}
