import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_pos_system/features/order_taking/widgets/kitchen_note_dialog.dart';

void main() {
  Widget buildTestWidget({
    String initialNote = '',
    void Function(String?)? onResult,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return Center(
              child: ElevatedButton(
                onPressed: () async {
                  final result = await KitchenNoteDialog.show(
                    context,
                    initialNote: initialNote,
                  );
                  onResult?.call(result);
                },
                child: const Text('Open Kitchen Note Dialog'),
              ),
            );
          },
        ),
      ),
    );
  }

  testWidgets(
    'KitchenNoteDialog renders correctly with Add & Send button without send icon or Send KOT text',
    (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Open dialog
      await tester.tap(find.text('Open Kitchen Note Dialog'));
      await tester.pumpAndSettle();

      // Verify Header & Sections
      expect(find.text('Note for Kitchen'), findsOneWidget);
      expect(find.text('Instructions for the entire ticket'), findsOneWidget);
      expect(find.text('QUICK SUGGESTIONS'), findsNothing); // Quick suggestions removed

      // Verify character counter shows 0/75 initially
      expect(find.text('0/75'), findsOneWidget);

      // Verify Footer Buttons
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Add & Send'), findsOneWidget);
      // Ensure "Send KOT" is NOT displayed
      expect(find.text('Send KOT'), findsNothing);

      // Ensure no Icons.send_rounded is present
      expect(find.byIcon(Icons.send_rounded), findsNothing);
    },
  );

  testWidgets(
    'Entering text in text field updates note and returns it on Add & Send',
    (tester) async {
      String? returnedNote;
      await tester.pumpWidget(
        buildTestWidget(onResult: (res) => returnedNote = res),
      );

      await tester.tap(find.text('Open Kitchen Note Dialog'));
      await tester.pumpAndSettle();

      final textFieldFinder = find.byType(TextField);
      await tester.enterText(textFieldFinder, 'Serve together, extra spicy');
      await tester.pumpAndSettle();

      TextField textField = tester.widget(textFieldFinder);
      expect(textField.controller?.text, 'Serve together, extra spicy');
      expect(find.text('${'Serve together, extra spicy'.length}/75'), findsOneWidget);

      await tester.tap(find.text('Add & Send'));
      await tester.pumpAndSettle();

      expect(returnedNote, 'Serve together, extra spicy');
    },
  );

  testWidgets(
    'Enforces maximum character limit of 75 characters in text field',
    (tester) async {
      await tester.pumpWidget(buildTestWidget());

      await tester.tap(find.text('Open Kitchen Note Dialog'));
      await tester.pumpAndSettle();

      final longText = 'A' * 100; // 100 characters
      await tester.enterText(find.byType(TextField), longText);
      await tester.pumpAndSettle();

      final TextField textField = tester.widget(find.byType(TextField));
      // Should be truncated / limited to 75 characters
      expect(textField.controller?.text.length, 75);
      expect(find.text('75/75'), findsOneWidget);
    },
  );

  testWidgets('Skip button closes dialog returning empty string', (
    tester,
  ) async {
    String? returnedNote;
    await tester.pumpWidget(
      buildTestWidget(onResult: (res) => returnedNote = res),
    );

    await tester.tap(find.text('Open Kitchen Note Dialog'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(returnedNote, '');
    expect(find.text('Note for Kitchen'), findsNothing);
  });

  testWidgets(
    'Close cross button (X) cancels dialog returning null',
    (tester) async {
      String? returnedNote = 'initial_sentinel';
      await tester.pumpWidget(
        buildTestWidget(onResult: (res) => returnedNote = res),
      );

      await tester.tap(find.text('Open Kitchen Note Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(returnedNote, isNull);
      expect(find.text('Note for Kitchen'), findsNothing);
    },
  );

  testWidgets(
    'Add & Send button is disabled when empty, and enabled when text is typed',
    (tester) async {
      await tester.pumpWidget(buildTestWidget());

      await tester.tap(find.text('Open Kitchen Note Dialog'));
      await tester.pumpAndSettle();

      // Initially empty -> Add & Send button is disabled (onPressed is null)
      ElevatedButton addAndSendButton = tester.widget(
        find.widgetWithText(ElevatedButton, 'Add & Send'),
      );
      expect(addAndSendButton.onPressed, isNull);

      // Type text -> Add & Send becomes enabled
      await tester.enterText(find.byType(TextField), 'Less spicy');
      await tester.pumpAndSettle();

      addAndSendButton = tester.widget(
        find.widgetWithText(ElevatedButton, 'Add & Send'),
      );
      expect(addAndSendButton.onPressed, isNotNull);

      // Clear text -> Add & Send becomes disabled again
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();

      addAndSendButton = tester.widget(
        find.widgetWithText(ElevatedButton, 'Add & Send'),
      );
      expect(addAndSendButton.onPressed, isNull);
    },
  );
}
