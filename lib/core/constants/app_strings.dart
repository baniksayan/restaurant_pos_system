import '../localization/app_localization_service.dart';
import '../localization/translations/app_translations.dart';

/// Centralized strings access point for WhizEats POS.
///
/// Delegates dynamically to the currently active [AppTranslations] from [LocalizationService],
/// enabling seamless multi-language switching across all existing call sites without code rewrites.
class AppStrings {
  AppStrings._();

  static String get appName => LocalizationService.current.appName;
  static String get appTagline => LocalizationService.current.appTagline;
  static String get currencySymbol => LocalizationService.current.currencySymbol;
  static String get brandName => LocalizationService.current.brandName;
  static String get brandSuffix => LocalizationService.current.brandSuffix;
  static String get posTagline => LocalizationService.current.posTagline;
  static String get poweredBy => LocalizationService.current.poweredBy;
  static String get solutionTagline =>
      LocalizationService.current.solutionTagline;

  // Legal & Policy URLs
  static String get privacyPolicyUrl =>
      LocalizationService.current.privacyPolicyUrl;
  static String get termsAndConditionsUrl =>
      LocalizationService.current.termsAndConditionsUrl;

  // Common button labels
  static String get ok => LocalizationService.current.ok;
  static String get cancel => LocalizationService.current.cancel;
  static String get save => LocalizationService.current.save;
  static String get delete => LocalizationService.current.delete;
  static String get confirm => LocalizationService.current.confirm;
  static String get retry => LocalizationService.current.retry;
  static String get back => LocalizationService.current.back;
  static String get close => LocalizationService.current.close;
  static String get tryAgain => LocalizationService.current.tryAgain;
  static String get gotIt => LocalizationService.current.gotIt;
  static String get okGotIt => LocalizationService.current.okGotIt;
  static String get done => LocalizationService.current.done;
  static String get login => LocalizationService.current.login;
  static String get logout => LocalizationService.current.logout;
  static String get signOut => LocalizationService.current.signOut;
  static String get accessDenied => LocalizationService.current.accessDenied;
  static String get signingOut => LocalizationService.current.signingOut;
  static String get loggingOut => LocalizationService.current.loggingOut;
  static String get signOutConfirmation =>
      LocalizationService.current.signOutConfirmation;
  static String get signOutProConfirm =>
      LocalizationService.current.signOutProConfirm;
  static String get signOutKdsConfirm =>
      LocalizationService.current.signOutKdsConfirm;
  static String get signingOutOfKds =>
      LocalizationService.current.signingOutOfKds;
  static String get connect => LocalizationService.current.connect;
  static String get clear => LocalizationService.current.clear;
  static String get openNavigationDrawer =>
      LocalizationService.current.openNavigationDrawer;

  // Common labels
  static String get unitPrice => LocalizationService.current.unitPrice;
  static String get quantity => LocalizationService.current.quantity;
  static String get total => LocalizationService.current.total;
  static String get subtotal => LocalizationService.current.subtotal;
  static String get customerName => LocalizationService.current.customerName;
  static String get phoneNumber => LocalizationService.current.phoneNumber;

  // Network messages
  static String get noInternetTitle =>
      LocalizationService.current.noInternetTitle;
  static String get noInternetDesc =>
      LocalizationService.current.noInternetDesc;

  // Feature namespaces
  static AuthTranslations get auth => LocalizationService.current.auth;
  static DashboardTranslations get dashboard =>
      LocalizationService.current.dashboard;
  static MenuTranslations get menu => LocalizationService.current.menu;
  static OrderTakingTranslations get orderTaking =>
      LocalizationService.current.orderTaking;
  static BillingTranslations get billing => LocalizationService.current.billing;
  static PaymentTranslations get payment => LocalizationService.current.payment;
  static ChefTranslations get chef => LocalizationService.current.chef;
  static OrdersTranslations get orders => LocalizationService.current.orders;
  static ProfileTranslations get profile => LocalizationService.current.profile;
  static ReservationsTranslations get reservations =>
      LocalizationService.current.reservations;
  static ReportsTranslations get reports => LocalizationService.current.reports;
  static NetworkTranslations get network => LocalizationService.current.network;
  static ValidationTranslations get validation =>
      LocalizationService.current.validation;
  static PdfTranslations get pdf => LocalizationService.current.pdf;
  static DrawerTranslations get drawer => LocalizationService.current.drawer;
}
