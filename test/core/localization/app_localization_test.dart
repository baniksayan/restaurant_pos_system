import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:restaurant_pos_system/core/constants/app_strings.dart';
import 'package:restaurant_pos_system/core/constants/storage_keys.dart';
import 'package:restaurant_pos_system/core/localization/app_localization_service.dart';
import 'package:restaurant_pos_system/core/localization/locale_provider.dart';
import 'package:restaurant_pos_system/core/localization/models/app_language.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LocalizationService.instance.setLocale(const Locale('en'));
  });

  tearDown(() {
    LocalizationService.instance.setLocale(const Locale('en'));
  });

  group('AppLanguage Enum Tests', () {
    test('AppLanguage defines English, Hindi, and Bengali with correct codes', () {
      expect(AppLanguage.values.length, 3);
      expect(AppLanguage.english.code, 'en');
      expect(AppLanguage.hindi.code, 'hi');
      expect(AppLanguage.bengali.code, 'bn');

      expect(AppLanguage.english.nativeName, 'English');
      expect(AppLanguage.hindi.nativeName, 'हिन्दी');
      expect(AppLanguage.bengali.nativeName, 'বাংলা');
    });

    test('AppLanguage.fromLanguageCode parses valid codes correctly', () {
      expect(AppLanguage.fromLanguageCode('en'), AppLanguage.english);
      expect(AppLanguage.fromLanguageCode('EN'), AppLanguage.english);
      expect(AppLanguage.fromLanguageCode('hi'), AppLanguage.hindi);
      expect(AppLanguage.fromLanguageCode('HI'), AppLanguage.hindi);
      expect(AppLanguage.fromLanguageCode('bn'), AppLanguage.bengali);
      expect(AppLanguage.fromLanguageCode('BN'), AppLanguage.bengali);
    });

    test('AppLanguage.fromLanguageCode falls back to English for unknown codes', () {
      expect(AppLanguage.fromLanguageCode(null), AppLanguage.english);
      expect(AppLanguage.fromLanguageCode(''), AppLanguage.english);
      expect(AppLanguage.fromLanguageCode('fr'), AppLanguage.english);
      expect(AppLanguage.fromLanguageCode('de'), AppLanguage.english);
    });

    test('AppLanguage.fromLocale resolves correct language', () {
      expect(AppLanguage.fromLocale(const Locale('en')), AppLanguage.english);
      expect(AppLanguage.fromLocale(const Locale('hi')), AppLanguage.hindi);
      expect(AppLanguage.fromLocale(const Locale('bn')), AppLanguage.bengali);
      expect(AppLanguage.fromLocale(const Locale('es')), AppLanguage.english);
      expect(AppLanguage.fromLocale(null), AppLanguage.english);
    });

    test('supportedLocales returns all 3 locales', () {
      final locales = AppLanguage.supportedLocales;
      expect(locales.length, 3);
      expect(locales.map((l) => l.languageCode).toList(), ['en', 'hi', 'bn']);
    });
  });

  group('LocalizationService & AppStrings Dynamic Switching Tests', () {
    test('Defaults to English strings initially', () {
      LocalizationService.instance.setLocale(const Locale('en'));

      expect(AppStrings.dashboard.tables, 'Tables');
      expect(AppStrings.dashboard.menuLabel, 'Menu');
      expect(AppStrings.dashboard.cart, 'Cart');
      expect(AppStrings.auth.logIn, 'Log In');
      expect(AppStrings.payment.cash, 'Cash');
      expect(AppStrings.payment.upi, 'UPI');
      expect(AppStrings.drawer.ordersManagement, 'Orders Management');
    });

    test('Switching to Hindi dynamically changes AppStrings across all modules', () {
      LocalizationService.instance.setLocale(const Locale('hi'));

      expect(AppStrings.dashboard.tables, 'टेबल');
      expect(AppStrings.dashboard.menuLabel, 'मेन्यू');
      expect(AppStrings.dashboard.cart, 'कार्ट');
      expect(AppStrings.auth.logIn, 'लॉग इन');
      expect(AppStrings.payment.cash, 'नकद');
      expect(AppStrings.payment.upi, 'यूपीआई (UPI)');
      expect(AppStrings.drawer.ordersManagement, 'ऑर्डर प्रबंधन');
      expect(AppStrings.drawer.pendingPayments, 'लंबित भुगतान');
      expect(AppStrings.profile.language, 'भाषा');
    });

    test('Switching to Bengali dynamically changes AppStrings across all modules', () {
      LocalizationService.instance.setLocale(const Locale('bn'));

      expect(AppStrings.dashboard.tables, 'টেবিল');
      expect(AppStrings.dashboard.menuLabel, 'মেনু');
      expect(AppStrings.dashboard.cart, 'কার্ট');
      expect(AppStrings.auth.logIn, 'লগ ইন');
      expect(AppStrings.payment.cash, 'নগদ');
      expect(AppStrings.payment.upi, 'ইউপিআই (UPI)');
      expect(AppStrings.drawer.ordersManagement, 'অর্ডার ব্যবস্থাপনা');
      expect(AppStrings.drawer.pendingPayments, 'বকেয়া পেমেন্ট');
      expect(AppStrings.profile.language, 'ভাষা');
    });

    test('GST with rate formats dynamically in English, Hindi, and Bengali', () {
      LocalizationService.instance.setLocale(const Locale('en'));
      expect(AppStrings.billing.gstWithRate(18.0), 'Tax & Charges (18%)');

      LocalizationService.instance.setLocale(const Locale('hi'));
      expect(AppStrings.billing.gstWithRate(18.0), 'कर और शुल्क (18%)');

      LocalizationService.instance.setLocale(const Locale('bn'));
      expect(AppStrings.billing.gstWithRate(18.0), 'ট্যাক্স ও চার্জ (18%)');
    });

    test('Fallback to English when switching to unsupported locale', () {
      LocalizationService.instance.setLocale(const Locale('de'));
      expect(AppStrings.dashboard.tables, 'Tables');
      expect(AppStrings.auth.logIn, 'Log In');
    });
  });

  group('LocaleProvider State & Persistence Tests', () {
    test('LocaleProvider initializes and defaults to English when storage empty', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = LocaleProvider();
      await provider.init();

      expect(provider.locale.languageCode, 'en');
      expect(provider.currentLanguage, AppLanguage.english);
      expect(provider.isEnglish, isTrue);
      expect(provider.isHindi, isFalse);
      expect(provider.isBengali, isFalse);
    });

    test('LocaleProvider loads saved language preference from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        StorageKeys.selectedLanguageCode: 'hi',
      });

      final provider = LocaleProvider();
      await provider.init();

      expect(provider.locale.languageCode, 'hi');
      expect(provider.currentLanguage, AppLanguage.hindi);
      expect(provider.isHindi, isTrue);
      expect(AppStrings.dashboard.tables, 'टेबल');
    });

    test('LocaleProvider.setLanguage updates state, notifies listeners, and persists to storage', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = LocaleProvider();
      await provider.init();

      bool listenerNotified = false;
      provider.addListener(() {
        listenerNotified = true;
      });

      await provider.setLanguage(AppLanguage.bengali);

      expect(provider.locale.languageCode, 'bn');
      expect(provider.currentLanguage, AppLanguage.bengali);
      expect(provider.isBengali, isTrue);
      expect(listenerNotified, isTrue);
      expect(AppStrings.dashboard.tables, 'টেবিল');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(StorageKeys.selectedLanguageCode), 'bn');
    });
  });
}

