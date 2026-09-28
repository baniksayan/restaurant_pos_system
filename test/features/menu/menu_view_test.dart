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
import 'package:restaurant_pos_system/features/menu/widgets/category_tabs.dart';
import 'package:restaurant_pos_system/features/menu/widgets/menu_search_bar.dart';
import 'package:restaurant_pos_system/features/order_taking/providers/animated_cart_provider.dart';

void main() {
  group('MenuView Widget Tests', () {
    late MenuProvider menuProvider;
    late NavigationProvider navProvider;
    late TableProvider tableProvider;
    late AnimatedCartProvider cartProvider;
    late Directory tempDir;

    setUpAll(() async {
      tempDir = Directory.systemTemp.createTempSync('menu_view_test_');
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

    Widget buildTestWidget({String? selectedTableId, String? tableName}) {
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
          home: MenuView(
            selectedTableId: selectedTableId,
            tableName: tableName,
          ),
        ),
      );
    }

    testWidgets(
      'does NOT render search bar, category chips, or top-right tags when menu items are empty',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(selectedTableId: 'T1', tableName: 'Table 1'),
        );
        await tester.pump();

        // Search bar and Category tabs should NOT be in the tree
        expect(find.byType(MenuSearchBar), findsNothing);
        expect(find.byType(CategoryTabs), findsNothing);

        // Header status tags should NOT be shown
        expect(find.text('ORDERING'), findsNothing);
        expect(find.text('VIEW ONLY'), findsNothing);

        // Header itself is present
        expect(find.text('Menu'), findsOneWidget);
        expect(find.text('Table 1'), findsOneWidget);
      },
    );

    testWidgets(
      'renders search bar, category chips, and top-right tag when menu items exist',
      (tester) async {
        menuProvider.setMenuItemsForTesting([
          Data(
            productId: '1',
            productName: 'Chicken Burger',
            categoryId: 'cat_1',
            categoryName: 'Burgers',
            productPrice: 150,
            pureVeg: false,
          ),
        ]);

        await tester.pumpWidget(
          buildTestWidget(selectedTableId: 'T1', tableName: 'Table 1'),
        );
        await tester.pump();

        // Search bar and Category tabs should be present
        expect(find.byType(MenuSearchBar), findsOneWidget);
        expect(find.byType(CategoryTabs), findsOneWidget);

        // Header status tag should be present
        expect(find.text('ORDERING'), findsOneWidget);
        expect(find.text('Chicken Burger'), findsOneWidget);
      },
    );
  });
}
