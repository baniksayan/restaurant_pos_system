import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_pos_system/core/constants/app_strings.dart';
import 'package:restaurant_pos_system/shared/widgets/dialogs/sign_out_confirmation_dialog.dart';

void main() {
  testWidgets('SignOutConfirmationDialog renders properly and handles cancel', (
    tester,
  ) async {
    bool confirmed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    final res = await SignOutConfirmationDialog.show(
                      context,
                      message: AppStrings.signOutProConfirm,
                      onConfirm: () {
                        confirmed = true;
                      },
                    );
                    if (res == true) {
                      confirmed = true;
                    }
                  },
                  child: const Text('Open Dialog'),
                ),
              ),
            );
          },
        ),
      ),
    );

    // Tap to open dialog
    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    // Verify dialog content
    expect(find.text(AppStrings.signOutConfirmation), findsOneWidget);
    expect(
      find.text(AppStrings.signOutProConfirm),
      findsOneWidget,
    );
    expect(find.text(AppStrings.cancel), findsOneWidget);
    expect(find.text(AppStrings.signOut), findsOneWidget);

    // Tap Cancel
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // Verify dialog closed and confirm callback was not triggered
    expect(find.text('Sign Out Confirmation'), findsNothing);
    expect(confirmed, isFalse);
  });

  testWidgets(
    'SignOutConfirmationDialog triggers onConfirm when Sign Out is tapped',
    (tester) async {
      bool confirmed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      SignOutConfirmationDialog.show(
                        context,
                        title: 'KDS Sign Out',
                        message: AppStrings.signOutKdsConfirm,
                        onConfirm: () {
                          confirmed = true;
                        },
                      );
                    },
                    child: const Text('Open KDS Dialog'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open KDS Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('KDS Sign Out'), findsOneWidget);
      expect(
        find.text(AppStrings.signOutKdsConfirm),
        findsOneWidget,
      );

      // Tap Sign Out
      await tester.tap(find.text(AppStrings.signOut));
      await tester.pumpAndSettle();

      // Dialog should be dismissed and callback executed
      expect(find.text('KDS Sign Out'), findsNothing);
      expect(confirmed, isTrue);
    },
  );
}
