import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_localization_service.dart';
import '../app_localizations.dart';
import '../locale_provider.dart';
import '../models/app_language.dart';
import '../translations/app_translations.dart';

extension LocalizationExtension on BuildContext {
  /// Quick access to active translated strings.
  AppTranslations get l10n =>
      AppLocalizations.of(this)?.strings ?? LocalizationService.current;

  /// Shorthand for current locale.
  Locale get currentLocale {
    try {
      return Localizations.localeOf(this);
    } catch (_) {
      return LocalizationService.instance.currentLocale;
    }
  }

  /// Current active language with graceful fallback.
  AppLanguage get currentLanguage {
    try {
      final provider = Provider.of<LocaleProvider>(this, listen: true);
      return provider.currentLanguage;
    } catch (_) {
      return AppLanguage.fromLocale(LocalizationService.instance.currentLocale);
    }
  }

  /// Access to [LocaleProvider] without triggering rebuilds (nullable for test resilience).
  LocaleProvider? get localeProvider {
    try {
      return Provider.of<LocaleProvider>(this, listen: false);
    } catch (_) {
      return null;
    }
  }

  /// Access to [LocaleProvider] with rebuild on change (nullable for test resilience).
  LocaleProvider? get watchLocaleProvider {
    try {
      return Provider.of<LocaleProvider>(this, listen: true);
    } catch (_) {
      return null;
    }
  }
}

