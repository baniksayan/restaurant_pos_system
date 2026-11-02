/// Base contract defining all localized string groups for the application.
abstract class AppTranslations {
  String get appName;
  String get appTagline;
  String get currencySymbol;
  String get brandName;
  String get brandSuffix;
  String get posTagline;
  String get poweredBy;
  String get solutionTagline;

  String get privacyPolicyUrl;
  String get termsAndConditionsUrl;

  String get ok;
  String get cancel;
  String get save;
  String get delete;
  String get confirm;
  String get retry;
  String get back;
  String get close;
  String get tryAgain;
  String get gotIt;
  String get okGotIt;
  String get done;
  String get login;
  String get logout;
  String get signOut;
  String get accessDenied;
  String get signingOut;
  String get loggingOut;
  String get signOutConfirmation;
  String get signOutProConfirm;
  String get signOutKdsConfirm;
  String get signingOutOfKds;
  String get connect;
  String get clear;
  String get openNavigationDrawer;

  String get unitPrice;
  String get quantity;
  String get total;
  String get subtotal;
  String get customerName;
  String get phoneNumber;

  String get noInternetTitle;
  String get noInternetDesc;

  AuthTranslations get auth;
  DashboardTranslations get dashboard;
  MenuTranslations get menu;
  OrderTakingTranslations get orderTaking;
  BillingTranslations get billing;
  PaymentTranslations get payment;
  ChefTranslations get chef;
  OrdersTranslations get orders;
  ProfileTranslations get profile;
  ReservationsTranslations get reservations;
  ReportsTranslations get reports;
  NetworkTranslations get network;
  ValidationTranslations get validation;
  PdfTranslations get pdf;
  DrawerTranslations get drawer;
}

abstract class AuthTranslations {
  String get logIn;
  String get userName;
  String get password;
  String get enterUsername;
  String get enterPassword;
  String get forgotPassword;
  String get forgotPasswordSubtitle;
  String get checkEmailForReset;
  String get emailAddress;
  String get enterEmailAddress;
  String get sendResetEmail;
  String get emailSentTo;
  String get backToLogin;
  String get resendEmail;
  String get rememberPassword;

  String get iAgreeToThe;
  String get termsAndConditions;
  String get and;
  String get privacyPolicy;

  String get noServerResponse;
  String get authCheckError;
  String get invalidCredentials;
  String get loginFailedCredentials;
  String get serverResponseError;
  String get serverError;
  String get noInternet;
  String get connectionTimeout;
  String get loginFailed;

  String get accessDenied;
  String get accessDeniedSubtitle;
  String get accessDeniedMessage;
  String get okGotIt;
}

abstract class DashboardTranslations {
  String get tables;
  String get menuLabel;
  String get cart;

  String get newOrder;

  String get errorLoadingTables;
  String get clearError;
  String get noTablesFound;
  String get changeLocation;

  String get profileTitle;
  String get profileSubtitle;
  String get settings;
  String get settingsSubtitle;
  String get performance;
  String get performanceSubtitle;
  String get settingsComingSoon;

  String get selectLocation;
  String get selectTableForDineIn;
  String get errorCreatingOrder;
  String get failedToAddOrderToServer;

  String get customerNameLabel;
  String get phoneNumberLabel;
  String get enterCustomerName;
  String get enterPhoneNumber;
  String get enterTenDigitMobile;
}

abstract class MenuTranslations {
  String get searchDishes;
  String get failedToLoadMenu;
  String get noItemsAvailable;
  String get loadMenu;
  String get kotSentToKitchen;
}

abstract class OrderTakingTranslations {
  String get clearAll;
  String get clearAllItems;
  String get clearCartConfirm;
  String get specialInstructions;
  String get kotGenerated;
  String get cannotGenerateBill;
  String get allItemsMustHaveKot;
  String get noItemsInCart;
  String get noNewItemsForKot;
  String get kotCreationFailed;
  String get checkItemsInCart;
  String get contactSupport;
  String get pleaseGenerateKotFirst;
  String get yourCartIsEmpty;
  String get refresh;
}

abstract class BillingTranslations {
  String get loadingPaymentModes;
  String gstWithRate(double percentage);
}

abstract class PaymentTranslations {
  String get paymentTitle;
  String get cash;
  String get cashSubtitle;
  String get upi;
  String get upiSubtitle;
  String get noPaymentMethods;
  String get upiHint;
  String get saveUpiId;
  String get customerPhoneNumber;

  String get cashReceived;
  String get cashReceivedHint;
  String get changeToReturn;
  String get cashShortBy;
  String get exactAmount;
  String get cashShortError;
}

abstract class ChefTranslations {
  String get all;
  String get queue;
  String get preparing;
  String get serve;

  String get noOrdersInView;
  String get filterByStatus;

  String get chefProfile;
  String get chefProfileSubtitle;

  String get enterRejectionReason;
}

abstract class OrdersTranslations {
  String get tableTab;
  String get phoneTab;
  String get takeawayTab;
  String get channelTab;

  String get searchOrders;

  String get printOrder;
  String get shareDetails;
  String get printComingSoon;
  String get shareComingSoon;
  String get billIdNotAvailable;
  String get billRegeneratedSuccessfully;
  String get remainingTime;
}

abstract class ProfileTranslations {
  String get editProfile;
  String get fullName;
  String get role;
  String get phoneNumberOptional;
  String get profileUpdatedSuccessfully;

  String get logoutConfirm;
  String get loggingOut;
  String get signingOut;

  String get receiptPrinter;
  String get receiptPrinterSubtitle;
  String get kitchenPrinter;
  String get kitchenPrinterSubtitle;
  String get testPrint;
  String get saveSettings;
  String get connectPrinterFirst;

  String get openingBalance;
  String get additionalCashIn;
  String get cashInHint;
  String get additionalCashOut;
  String get cashOutHint;

  String get sales;
  String get ordersLabel;
  String get tablesLabel;
  String get reservationsLabel;

  String get aboutTitle;
  String get aboutDescription;
  String get version;
  String get build;
  String get copyright;

  String get restaurantManagement;
  String get restaurantDetails;
  String get restaurantDetailsSubtitle;
  String get staffManagement;
  String get staffManagementSubtitle;
  String get tableConfiguration;
  String get tableConfigurationSubtitle;
  String get menuManagement;
  String get menuManagementSubtitle;

  String get businessAnalytics;
  String get salesReports;
  String get salesReportsSubtitle;
  String get performanceMetrics;
  String get performanceMetricsSubtitle;
  String get inventoryReports;
  String get inventoryReportsSubtitle;
  String get customerAnalytics;
  String get customerAnalyticsSubtitle;

  String get financialManagement;
  String get dailyCashManagement;
  String get dailyCashManagementSubtitle;
  String get expenseTracking;
  String get expenseTrackingSubtitle;
  String get profitAndLoss;
  String get profitAndLossSubtitle;
  String get taxReports;
  String get taxReportsSubtitle;

  String get systemAndSettings;
  String get printerSettings;
  String get printerSettingsSubtitle;
  String get paymentMethods;
  String get paymentMethodsSubtitle;
  String get taxConfiguration;
  String get taxConfigurationSubtitle;
  String get dataBackup;
  String get dataBackupSubtitle;

  String get helpAndSupport;
  String get userManual;
  String get userManualSubtitle;
  String get technicalSupport;
  String get technicalSupportSubtitle;
  String get appUpdates;
  String get appUpdatesSubtitle;
  String get aboutApp;
  String get aboutAppSubtitle;

  String get topPerformer;
  String get customerFavorite;

  String get language;
  String get languageSubtitle;
}

abstract class ReservationsTranslations {
  String get customerNameRequired;
  String get enterFullName;
  String get phoneNumberRequired;
  String get enterTenDigitNumber;
  String get numberOfPersons;
  String get enterNumberOfPersons;
  String get specialOccasion;
  String get specialNotesOptional;
  String get specialNotesHint;
  String get from;
  String get to;
  String get enterAdvanceAmount;

  String get reservationRules;
  String get advanceBooking;
  String get operatingHours;
  String get durationLimits;
  String get advancePayment;

  String get selectReservationTime;
  String get tableAlreadyReserved;
  String get failedToCreateReservation;
  String get generatingPdfBill;
  String get shareBill;
  String get sharingBillToWhatsApp;
  String get selectWhatsApp;

  String get decorationSubtitle;
}

abstract class ReportsTranslations {
  String get selectTimePeriod;
  String get totalRevenue;
  String get totalOrders;
  String get avgOrderValue;
  String get tableTurnoverRate;
  String get pdfLabel;
  String get csvLabel;
  String get generatingReport;
}

abstract class NetworkTranslations {
  String get uhOh;
  String get noDataOrWifi;
  String get checkInternetAndRetry;
  String get checking;
  String get openSettings;
  String get checkDeviceSettings;
  String get quickTips;
  String get tipWifi;
  String get tipAirplane;
  String get tipSignal;
  String get slowNetwork;
  String get slowNetworkDesc;
}

abstract class ValidationTranslations {
  String get nameTooShort;
  String get enterPhoneNumber;
  String get phoneMustBeTenDigits;
  String get phoneMustStartWith;
  String get enterValidPhone;
  String get enterEmail;
  String get enterValidEmail;
}

abstract class PdfTranslations {
  String get baseAmount;
  String get tableDecoration;
  String get arriveOnTime;
  String get remainingAmountNote;
  String get arriveEarly;
  String get nonRefundable;
  String get tableHeldNote;
  String get changesContact;
  String get reservationBillShareText;

  String get whatsAppKitchen;
  String get whatsAppKitchenSubtitle;
  String get sharePdfDocument;
  String get sharePdfSubtitle;
}

abstract class DrawerTranslations {
  String get locations;
  String get quickActions;
  String get pendingPayments;
  String get pendingPaymentsSubtitle;
  String get reprint;
  String get reprintSubtitle;
  String get account;
  String get ordersManagement;
  String get ordersManagementSubtitle;
  String get readyToCollect;
  String get readyToCollectSubtitle;
  String get kitchenMenu;
  String get language;
  String get languageSubtitle;
  String get selectLanguage;
  String get chooseLanguage;
  String get english;
  String get hindi;
  String get bengali;
  String get languageChanged;
}
