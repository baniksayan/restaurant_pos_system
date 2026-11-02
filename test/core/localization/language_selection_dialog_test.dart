import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:restaurant_pos_system/core/constants/app_strings.dart';
import 'package:restaurant_pos_system/core/localization/app_localizations.dart';
import 'package:restaurant_pos_system/core/localization/locale_provider.dart';
import 'package:restaurant_pos_system/core/localization/models/app_language.dart';
import 'package:restaurant_pos_system/core/localization/widgets/language_selection_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocaleProvider localeProvider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    localeProvider = LocaleProvider();
    await localeProvider.init();
  });

  final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();

  Widget createTestWidget() {
    return ChangeNotifierProvider<LocaleProvider>.value(
      value: localeProvider,
      child: Consumer<LocaleProvider>(
        builder: (context, provider, _) {
          return MaterialApp(
            navigatorKey: navKey,
            locale: provider.locale,
            supportedLocales: AppLanguage.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return Center(
                    child: ElevatedButton(
                      onPressed: () => LanguageSelectionDialog.show(context),
                      child: const Text('OPEN DIALOG'),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  testWidgets('LanguageSelectionDialog displays all supported languages and switches to Hindi',
      (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Open language selection dialog
    await tester.tap(find.text('OPEN DIALOG'));
    await tester.pumpAndSettle();

    // Dialog title and language names in native script
    expect(find.text('Select Language'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('हिन्दी'), findsOneWidget);
    expect(find.text('বাংলা'), findsOneWidget);

    // Tap Hindi option
    await tester.tap(find.text('हिन्दी'));
    await tester.pumpAndSettle();

    // Dialog dismissed and provider updated
    expect(find.byType(LanguageSelectionDialog), findsNothing);
    expect(localeProvider.locale.languageCode, 'hi');
    expect(localeProvider.currentLanguage, AppLanguage.hindi);
    expect(AppStrings.dashboard.tables, 'टेबल');
  });

  testWidgets('LanguageSelectionDialog switches to Bengali', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Open language selection dialog
    await tester.tap(find.text('OPEN DIALOG'));
    await tester.pumpAndSettle();

    // Tap Bengali option
    await tester.tap(find.text('বাংলা'));
    await tester.pumpAndSettle();

    // Dialog dismissed and provider updated
    expect(find.byType(LanguageSelectionDialog), findsNothing);
    expect(localeProvider.locale.languageCode, 'bn');
    expect(localeProvider.currentLanguage, AppLanguage.bengali);
    expect(AppStrings.dashboard.tables, 'টেবিল');
  });
}
