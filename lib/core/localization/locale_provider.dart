import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/storage_keys.dart';
import 'app_localization_service.dart';
import 'models/app_language.dart';

/// Provider responsible for managing the app-wide locale and persistence.
class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');
  bool _isInitialized = false;
  Future<void>? _initFuture;

  Locale get locale => _locale;
  bool get isInitialized => _isInitialized;

  AppLanguage get currentLanguage => AppLanguage.fromLocale(_locale);
  bool get isEnglish => _locale.languageCode == 'en';
  bool get isHindi => _locale.languageCode == 'hi';
  bool get isBengali => _locale.languageCode == 'bn';

  LocaleProvider() {
    init();
  }

  /// Initializes the saved locale from local storage or falls back to system locale.
  Future<void> init() {
    _initFuture ??= _performInit();
    return _initFuture!;
  }

  Future<void> _performInit() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(StorageKeys.selectedLanguageCode);

      if (savedCode != null && savedCode.isNotEmpty) {
        final language = AppLanguage.fromLanguageCode(savedCode);
        _locale = language.locale;
      } else {
        // First-run: check device preferred locale
        final deviceLocale =
            WidgetsBinding.instance.platformDispatcher.locale;
        final language = AppLanguage.fromLanguageCode(deviceLocale.languageCode);
        _locale = language.locale;
      }
    } catch (e) {
      debugPrint('Error initializing LocaleProvider: $e');
      _locale = const Locale('en');
    } finally {
      LocalizationService.instance.setLocale(_locale);
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Updates app locale and persists user selection.
  Future<void> setLocale(Locale newLocale) async {
    if (_locale.languageCode == newLocale.languageCode) return;

    _locale = newLocale;
    LocalizationService.instance.setLocale(newLocale);
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        StorageKeys.selectedLanguageCode,
        newLocale.languageCode,
      );
    } catch (e) {
      debugPrint('Error saving selected locale: $e');
    }
  }

  /// Sets language using the [AppLanguage] enum.
  Future<void> setLanguage(AppLanguage language) async {
    await setLocale(language.locale);
  }
}
