import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos_system/features/billing/providers/tax_provider.dart';
import 'package:restaurant_pos_system/features/order_taking/widgets/cart_footer.dart';

void main() {
  Widget buildTestWidget({
    double subtotal = 250.0,
    bool kotGenerated = false,
    String kotNote = '',
    ValueChanged<String>? onKotNoteChanged,
    VoidCallback? onGenerateKOT,
    VoidCallback? onOpenKotNoteDialog,
  }) {
    return ChangeNotifierProvider<TaxProvider>(
      create: (_) => TaxProvider(),
      child: MaterialApp(
        home: Scaffold(
          body: CartFooter(
            subtotal: subtotal,
            kotGenerated: kotGenerated,
            kotNote: kotNote,
            onKotNoteChanged: onKotNoteChanged,
            onGenerateKOT: onGenerateKOT ?? () {},
            onSendToKitchen: () {},
            onGenerateBill: () {},
            onShowGSTInfo: () {},
            onOpenKotNoteDialog: onOpenKotNoteDialog,
          ),
        ),
      ),
    );
  }

  testWidgets(
    'CartFooter displays kitchen note bar collapsed by default above Generate KOT button',
    (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Collapsed bar shown by default
      expect(find.text('Note for Kitchen (Optional)'), findsOneWidget);
      expect(find.text('+ Add'), findsOneWidget);
      expect(find.text('Generate KOT'), findsOneWidget);
      expect(find.text('NOTE FOR KITCHEN'), findsNothing);

      // Tap to expand
      await tester.tap(find.text('Note for Kitchen (Optional)'));
      await tester.pumpAndSettle();

      // Expanded panel shown
      expect(find.text('NOTE FOR KITCHEN'), findsOneWidget);
      expect(find.text('0/75'), findsOneWidget);

      // Tap collapse arrow
      await tester.tap(find.byIcon(Icons.keyboard_arrow_up_rounded));
      await tester.pumpAndSettle();

      // Collapsed bar shown again
      expect(find.text('Note for Kitchen (Optional)'), findsOneWidget);
      expect(find.text('+ Add'), findsOneWidget);
    },
  );

  testWidgets(
    'Entering text in expanded CartFooter note field updates note via callback',
    (tester) async {
      String latestNote = '';
      await tester.pumpWidget(
        buildTestWidget(
          onKotNoteChanged: (note) => latestNote = note,
        ),
      );
      await tester.pumpAndSettle();

      // Expand note bar first
      await tester.tap(find.text('Note for Kitchen (Optional)'));
      await tester.pumpAndSettle();

      final textFieldFinder = find.widgetWithText(
        TextField,
        'e.g. Serve together, no onions across table...',
      );
      await tester.enterText(textFieldFinder, 'Less spicy, no onions');
      await tester.pumpAndSettle();

      expect(latestNote, 'Less spicy, no onions');
      expect(find.text('21/75'), findsOneWidget);
    },
  );

  testWidgets(
    'CartFooter displays active note preview when note is set',
    (tester) async {
      String latestNote = 'No spicy';
      await tester.pumpWidget(
        buildTestWidget(
          kotNote: 'No spicy',
          onKotNoteChanged: (note) => latestNote = note,
        ),
      );
      await tester.pumpAndSettle();

      // Active note shown
      expect(find.text('Note: No spicy'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);

      // Tap clear icon to clear note
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(latestNote, '');
    },
  );

  testWidgets(
    'Tapping Generate KOT directly fires onGenerateKOT callback',
    (tester) async {
      bool kotGeneratedFired = false;
      await tester.pumpWidget(
        buildTestWidget(
          kotNote: 'Serve hot',
          onGenerateKOT: () => kotGeneratedFired = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Generate KOT'));
      await tester.pumpAndSettle();

      expect(kotGeneratedFired, isTrue);
    },
  );
}
