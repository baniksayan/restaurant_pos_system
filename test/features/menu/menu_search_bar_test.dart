import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos_system/core/constants/app_strings.dart';
import 'package:restaurant_pos_system/features/menu/providers/menu_provider.dart';
import 'package:restaurant_pos_system/features/menu/widgets/menu_search_bar.dart';

void main() {
  group('MenuSearchBar Widget Tests', () {
    late MenuProvider menuProvider;

    setUp(() {
      menuProvider = MenuProvider();
    });

    Widget buildTestWidget() {
      return MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<MenuProvider>.value(
            value: menuProvider,
            child: const MenuSearchBar(),
          ),
        ),
      );
    }

    testWidgets('renders search field with initial hint text', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      expect(find.text(AppStrings.menu.searchDishes), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.clear), findsNothing);
    });

    testWidgets(
      'shows clear button when text is entered and clears query when tapped',
      (tester) async {
        await tester.pumpWidget(buildTestWidget());

        // Enter text
        await tester.enterText(find.byType(TextField), 'Burger');
        await tester.pump();

        expect(find.text('Burger'), findsOneWidget);
        expect(menuProvider.searchQuery, 'Burger');
        expect(find.byIcon(Icons.clear), findsOneWidget);

        // Tap the clear icon
        await tester.tap(find.byIcon(Icons.clear));
        await tester.pump();

        expect(find.text('Burger'), findsNothing);
        expect(menuProvider.searchQuery, '');
        expect(find.byIcon(Icons.clear), findsNothing);
      },
    );
  });
}
