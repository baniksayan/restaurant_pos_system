import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos_system/data/models/menu_api_res_model.dart';
import 'package:restaurant_pos_system/features/menu/providers/menu_provider.dart';
import 'package:restaurant_pos_system/features/menu/widgets/category_tabs.dart';

void main() {
  group('CategoryTabs Widget Tests', () {
    late MenuProvider menuProvider;

    setUp(() {
      menuProvider = MenuProvider();
    });

    Widget buildTestWidget() {
      return MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<MenuProvider>.value(
            value: menuProvider,
            child: const CategoryTabs(),
          ),
        ),
      );
    }

    testWidgets('renders nothing when menu items are empty', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      expect(find.text('All'), findsNothing);
      expect(find.text('Veg Only'), findsNothing);
    });

    testWidgets(
      'does NOT show "Veg Only" tab when no items are vegetarian',
      (tester) async {
        menuProvider.setMenuItemsForTesting([
          Data(
            productId: '1',
            productName: 'Chicken Burger',
            categoryId: 'cat_1',
            categoryName: 'Burgers',
            pureVeg: false,
          ),
          Data(
            productId: '2',
            productName: 'Fish & Chips',
            categoryId: 'cat_2',
            categoryName: 'Seafood',
            pureVeg: false,
          ),
        ]);

        await tester.pumpWidget(buildTestWidget());

        expect(find.text('All'), findsOneWidget);
        expect(find.text('Burgers'), findsOneWidget);
        expect(find.text('Seafood'), findsOneWidget);
        expect(find.text('Veg Only'), findsNothing);
      },
    );

    testWidgets(
      'shows "Veg Only" tab when at least one item is vegetarian',
      (tester) async {
        menuProvider.setMenuItemsForTesting([
          Data(
            productId: '1',
            productName: 'Chicken Burger',
            categoryId: 'cat_1',
            categoryName: 'Burgers',
            pureVeg: false,
          ),
          Data(
            productId: '2',
            productName: 'Veggie Pizza',
            categoryId: 'cat_3',
            categoryName: 'Pizzas',
            pureVeg: true,
          ),
        ]);

        await tester.pumpWidget(buildTestWidget());

        expect(find.text('All'), findsOneWidget);
        expect(find.text('Veg Only'), findsOneWidget);
        expect(find.text('Burgers'), findsOneWidget);
        expect(find.text('Pizzas'), findsOneWidget);
      },
    );
  });
}
