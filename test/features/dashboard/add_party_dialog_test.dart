import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_pos_system/features/dashboard/widgets/add_party_dialog.dart';

void main() {
  Widget buildTestWidget({
    String tableName = 'Table 1',
    int capacity = 4,
    int seatedGuests = 0,
    void Function(PartyDetails?)? onResult,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return Center(
              child: ElevatedButton(
                onPressed: () async {
                  final result = await AddPartyDialog.show(
                    context,
                    tableName: tableName,
                    capacity: capacity,
                    seatedGuests: seatedGuests,
                  );
                  onResult?.call(result);
                },
                child: const Text('Open Party Dialog'),
              ),
            );
          },
        ),
      ),
    );
  }

  testWidgets('AddPartyDialog renders all fields and buttons in default state', (
    tester,
  ) async {
    PartyDetails? result;

    await tester.pumpWidget(
      buildTestWidget(
        tableName: 'Table 5',
        capacity: 4,
        onResult: (r) => result = r,
      ),
    );

    // Open the dialog
    await tester.tap(find.text('Open Party Dialog'));
    await tester.pumpAndSettle();

    // Verify Header
    expect(find.text('New Party'), findsOneWidget);
    expect(find.text('Table 5'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);

    // Verify Party Size section
    expect(find.text('PARTY SIZE'), findsOneWidget);
    expect(find.text('Adults'), findsOneWidget);
    expect(find.text('Standard / 12+ yrs'), findsOneWidget);
    expect(find.text('Children'), findsOneWidget);
    expect(find.text('Under 12 yrs'), findsOneWidget);

    // Verify Counters
    expect(find.text('1'), findsOneWidget); // Default adults
    expect(find.text('0'), findsOneWidget); // Default children

    // Verify Customer details section
    expect(find.text('CUSTOMER DETAILS (OPTIONAL)'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    // Verify Capacity banner
    expect(find.textContaining('available'), findsOneWidget);
    expect(find.text('Total: 1'), findsOneWidget);

    // Verify Action buttons
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Start Order'), findsOneWidget);

    // Test counter increment
    final addButtons = find.byIcon(Icons.add_rounded);
    await tester.tap(addButtons.first); // Increment adults to 2
    await tester.pumpAndSettle();
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Total: 2'), findsOneWidget);

    // Test entering customer name
    await tester.enterText(find.byType(TextField), 'Alice');
    await tester.pumpAndSettle();

    // Tap Start Order
    await tester.tap(find.text('Start Order'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.adults, 2);
    expect(result!.children, 0);
    expect(result!.customerName, 'Alice');
  });

  testWidgets(
    'All fields and buttons remain accessible when keyboard is open (viewInsets > 0)',
    (tester) async {
      PartyDetails? result;

      // Simulate a mobile screen with keyboard open
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;

      await tester.pumpWidget(
        buildTestWidget(
          tableName: 'Table 1',
          capacity: 4,
          onResult: (r) => result = r,
        ),
      );

      await tester.tap(find.text('Open Party Dialog'));
      await tester.pumpAndSettle();

      // Simulate keyboard opening: 350 logical pixels bottom inset = 1050 physical pixels
      tester.view.viewInsets = const FakeViewPadding(bottom: 1050);
      await tester.pumpAndSettle();

      // Verify that Header, Steppers, Name input, Capacity banner, and Footer buttons are ALL accessible
      expect(find.text('New Party'), findsOneWidget);
      expect(find.text('Table 1'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      expect(find.text('Adults'), findsOneWidget);
      expect(find.text('Children'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Start Order'), findsOneWidget);

      // Verify buttons are clickable while keyboard is active
      await tester.enterText(find.byType(TextField), 'Bob');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start Order'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.adults, 1);
      expect(result!.customerName, 'Bob');

      // Reset viewInsets and view size
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.view.resetViewInsets();
      });
    },
  );

  testWidgets('Submitting customer name via keyboard Done action starts order', (
    tester,
  ) async {
    PartyDetails? result;

    await tester.pumpWidget(
      buildTestWidget(
        tableName: 'Table 2',
        capacity: 6,
        onResult: (r) => result = r,
      ),
    );

    await tester.tap(find.text('Open Party Dialog'));
    await tester.pumpAndSettle();

    // Enter name and submit via keyboard action
    await tester.enterText(find.byType(TextField), 'Charlie');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.customerName, 'Charlie');
    expect(result!.adults, 1);
  });

  testWidgets('Cancel button dismisses dialog without creating party', (
    tester,
  ) async {
    PartyDetails? result;

    await tester.pumpWidget(
      buildTestWidget(tableName: 'Table 3', onResult: (r) => result = r),
    );

    await tester.tap(find.text('Open Party Dialog'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(result, isNull);
    expect(find.text('New Party'), findsNothing);
  });
}
