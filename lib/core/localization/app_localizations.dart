import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'app_localization_service.dart';
import 'models/app_language.dart';
import 'translations/app_translations.dart';

/// Flutter standard [Localizations] integration for WhizEats POS.
class AppLocalizations {
  final Locale locale;
  final AppTranslations strings;

  AppLocalizations(this.locale)
      : strings = LocalizationService.instance.getTranslationsForLocale(locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  /// Global accessor to current active translations.
  static AppTranslations get current => LocalizationService.current;

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLanguage.values.any((lang) => lang.code == locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    LocalizationService.instance.setLocale(locale);
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

