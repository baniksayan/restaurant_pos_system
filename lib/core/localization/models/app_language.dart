import 'package:flutter/material.dart';

/// Supported application languages with metadata.
enum AppLanguage {
  english(
    code: 'en',
    englishName: 'English',
    nativeName: 'English',
    subTitle: 'Default',
    locale: Locale('en'),
  ),
  hindi(
    code: 'hi',
    englishName: 'Hindi',
    nativeName: 'हिन्दी',
    subTitle: 'Hindi',
    locale: Locale('hi'),
  ),
  bengali(
    code: 'bn',
    englishName: 'Bengali',
    nativeName: 'বাংলা',
    subTitle: 'Bengali',
    locale: Locale('bn'),
  );

  final String code;
  final String englishName;
  final String nativeName;
  final String subTitle;
  final Locale locale;

  const AppLanguage({
    required this.code,
    required this.englishName,
    required this.nativeName,
    required this.subTitle,
    required this.locale,
  });

  /// All supported Flutter [Locale]s.
  static List<Locale> get supportedLocales =>
      AppLanguage.values.map((lang) => lang.locale).toList();

  /// Resolves an [AppLanguage] from a language code (e.g., 'en', 'hi', 'bn').
  static AppLanguage fromLanguageCode(String? code) {
    if (code == null || code.isEmpty) return AppLanguage.english;
    final normalized = code.toLowerCase().trim();
    for (final lang in AppLanguage.values) {
      if (lang.code == normalized) return lang;
    }
    return AppLanguage.english;
  }

  /// Resolves an [AppLanguage] from a Flutter [Locale].
  static AppLanguage fromLocale(Locale? locale) {
    if (locale == null) return AppLanguage.english;
    return fromLanguageCode(locale.languageCode);
  }
}

