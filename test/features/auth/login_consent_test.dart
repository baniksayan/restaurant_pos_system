import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos_system/features/auth/providers/auth_provider.dart';
import 'package:restaurant_pos_system/features/auth/widgets/login_form.dart';
import 'package:restaurant_pos_system/shared/widgets/buttons/animated_button.dart';

void main() {
  group('AnimatedButton isEnabled property', () {
    testWidgets('fires onPressed when isEnabled is true', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedButton(
              text: 'Login',
              isEnabled: true,
              onPressed: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AnimatedButton));
      expect(tapped, isTrue);
    });

    testWidgets('does not fire onPressed when isEnabled is false', (
      tester,
    ) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedButton(
              text: 'Login',
              isEnabled: false,
              onPressed: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AnimatedButton));
      expect(tapped, isFalse);
    });
  });

  group('LoginForm Terms & Privacy Consent', () {
    late AuthProvider authProvider;

    setUp(() {
      authProvider = AuthProvider();
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<AuthProvider>.value(
            value: authProvider,
            child: LoginForm(onForgotPassword: () {}, onLoginSuccess: () {}),
          ),
        ),
      );
    }

    testWidgets(
      'checkbox is checked by default and Login button is initially enabled',
      (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();

        final checkboxFinder = find.byType(Checkbox);
        expect(checkboxFinder, findsOneWidget);

        final checkbox = tester.widget<Checkbox>(checkboxFinder);
        expect(checkbox.value, isTrue);

        final buttonFinder = find.byType(AnimatedButton);
        expect(buttonFinder, findsOneWidget);

        final button = tester.widget<AnimatedButton>(buttonFinder);
        expect(button.isEnabled, isTrue);
        expect(button.onPressed, isNotNull);
      },
    );

    testWidgets('unchecking consent disables Login button and prevents login', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Tap the checkbox to uncheck it
      final checkboxFinder = find.byType(Checkbox);
      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();

      // Checkbox should now be unchecked
      final updatedCheckbox = tester.widget<Checkbox>(checkboxFinder);
      expect(updatedCheckbox.value, isFalse);

      // Login button should be disabled
      final buttonFinder = find.byType(AnimatedButton);
      final updatedButton = tester.widget<AnimatedButton>(buttonFinder);
      expect(updatedButton.isEnabled, isFalse);
      expect(updatedButton.onPressed, isNull);

      // Tapping the disabled button does nothing
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      // Tap checkbox again to re-check
      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();

      final recheckedCheckbox = tester.widget<Checkbox>(checkboxFinder);
      expect(recheckedCheckbox.value, isTrue);

      final recheckedButton = tester.widget<AnimatedButton>(buttonFinder);
      expect(recheckedButton.isEnabled, isTrue);
      expect(recheckedButton.onPressed, isNotNull);
    });
  });
}
