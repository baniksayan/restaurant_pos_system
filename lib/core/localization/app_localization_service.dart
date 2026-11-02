import 'package:flutter/material.dart';
import 'models/app_language.dart';
import 'translations/app_translations.dart';
import 'translations/bn_translations.dart';
import 'translations/en_translations.dart';
import 'translations/hi_translations.dart';

/// Central singleton service that manages translation instances and active language lookup.
class LocalizationService {
  LocalizationService._internal();

  static final LocalizationService instance = LocalizationService._internal();

  /// Quick static accessor for current active translations.
  static AppTranslations get current => instance.currentTranslations;

  final Map<String, AppTranslations> _translations = {
    AppLanguage.english.code: const EnTranslations(),
    AppLanguage.hindi.code: const HiTranslations(),
    AppLanguage.bengali.code: const BnTranslations(),
  };

  Locale _currentLocale = const Locale('en');
  AppTranslations _currentTranslations = const EnTranslations();

  Locale get currentLocale => _currentLocale;
  AppTranslations get currentTranslations => _currentTranslations;

  /// Updates active translations based on [locale].
  void setLocale(Locale locale) {
    _currentLocale = locale;
    final code = locale.languageCode.toLowerCase();
    _currentTranslations = _translations[code] ?? const EnTranslations();
  }

  /// Returns translations for a specific [locale] or defaults to English.
  AppTranslations getTranslationsForLocale(Locale locale) {
    final code = locale.languageCode.toLowerCase();
    return _translations[code] ?? const EnTranslations();
  }
}

