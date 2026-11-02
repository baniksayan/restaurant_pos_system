import 'app_translations.dart';

class BnTranslations implements AppTranslations {
  const BnTranslations();

  @override
  String get appName => 'WhizEats Pro';
  @override
  String get appTagline => 'রেস্তোরাঁ ম্যানেজমেন্ট ও পিওএস';
  @override
  String get currencySymbol => '₹';
  @override
  String get brandName => 'WhizEats';
  @override
  String get brandSuffix => 'PRO';
  @override
  String get posTagline => 'রেস্তোরাঁ পিওএস সিস্টেম';
  @override
  String get poweredBy => 'উইজার্ড কমিউনিকেশনস প্রা. লি. দ্বারা পরিচালিত';
  @override
  String get solutionTagline => 'উন্নত রেস্তোরাঁ পরিচালনা সমাধান';

  @override
  String get privacyPolicyUrl =>
      'https://stdpos.wizardcomm.net/WhizEatsPro/privacy-policy.html';
  @override
  String get termsAndConditionsUrl =>
      'https://stdpos.wizardcomm.net/WhizEatsPro/terms-and-conditions.html';

  @override
  String get ok => 'ঠিক আছে';
  @override
  String get cancel => 'বাতিল';
  @override
  String get save => 'সংরক্ষণ করুন';
  @override
  String get delete => 'মুছুন';
  @override
  String get confirm => 'নিশ্চিত করুন';
  @override
  String get retry => 'পুনরায় চেষ্টা করুন';
  @override
  String get back => 'ফিরে যান';
  @override
  String get close => 'বন্ধ করুন';
  @override
  String get tryAgain => 'আবার চেষ্টা করুন';
  @override
  String get gotIt => 'বুঝতে পেরেছি';
  @override
  String get okGotIt => 'ঠিক আছে, বুঝেছি';
  @override
  String get done => 'সম্পন্ন';
  @override
  String get login => 'লগইন';
  @override
  String get logout => 'লগআউট';
  @override
  String get signOut => 'সাইন আউট';
  @override
  String get accessDenied => 'অ্যাক্সেস প্রত্যাখ্যাত';
  @override
  String get signingOut => 'সাইন আউট করা হচ্ছে...';
  @override
  String get loggingOut => 'লগআউট করা হচ্ছে...';
  @override
  String get signOutConfirmation => 'সাইন আউট নিশ্চিতকরণ';
  @override
  String get signOutProConfirm =>
      'আপনি কি নিশ্চিত যে WhizEats Pro থেকে সাইন আউট করতে চান?';
  @override
  String get signOutKdsConfirm =>
      'আপনি কি নিশ্চিত যে WhizEats KDS থেকে সাইন আউট করতে চান?';
  @override
  String get signingOutOfKds => 'KDS থেকে সাইন আউট করা হচ্ছে...';
  @override
  String get connect => 'সংযুক্ত করুন';
  @override
  String get clear => 'পরিষ্কার করুন';
  @override
  String get openNavigationDrawer => 'ন্যাভিগেশন ড্রয়ার খুলুন';

  @override
  String get unitPrice => 'একক মূল্য';
  @override
  String get quantity => 'পরিমাণ';
  @override
  String get total => 'সর্বমোট';
  @override
  String get subtotal => 'সাবটোটাল';
  @override
  String get customerName => 'গ্রাহকের নাম';
  @override
  String get phoneNumber => 'ফোন নম্বর';

  @override
  String get noInternetTitle => 'কোনো ইন্টারনেট সংযোগ নেই';
  @override
  String get noInternetDesc => 'দয়া করে আপনার ইন্টারনেট সংযোগ পরীক্ষা করে পুনরায় চেষ্টা করুন।';

  @override
  AuthTranslations get auth => const _BnAuthTranslations();
  @override
  DashboardTranslations get dashboard => const _BnDashboardTranslations();
  @override
  MenuTranslations get menu => const _BnMenuTranslations();
  @override
  OrderTakingTranslations get orderTaking => const _BnOrderTakingTranslations();
  @override
  BillingTranslations get billing => const _BnBillingTranslations();
  @override
  PaymentTranslations get payment => const _BnPaymentTranslations();
  @override
  ChefTranslations get chef => const _BnChefTranslations();
  @override
  OrdersTranslations get orders => const _BnOrdersTranslations();
  @override
  ProfileTranslations get profile => const _BnProfileTranslations();
  @override
  ReservationsTranslations get reservations =>
      const _BnReservationsTranslations();
  @override
  ReportsTranslations get reports => const _BnReportsTranslations();
  @override
  NetworkTranslations get network => const _BnNetworkTranslations();
  @override
  ValidationTranslations get validation => const _BnValidationTranslations();
  @override
  PdfTranslations get pdf => const _BnPdfTranslations();
  @override
  DrawerTranslations get drawer => const _BnDrawerTranslations();
}

class _BnAuthTranslations implements AuthTranslations {
  const _BnAuthTranslations();

  @override
  String get logIn => 'লগ ইন';
  @override
  String get userName => 'ব্যবহারকারীর নাম';
  @override
  String get password => 'পাসওয়ার্ড';
  @override
  String get enterUsername => 'আপনার ব্যবহারকারীর নাম লিখুন';
  @override
  String get enterPassword => 'আপনার পাসওয়ার্ড লিখুন';
  @override
  String get forgotPassword => 'পাসওয়ার্ড ভুলে গেছেন?';
  @override
  String get forgotPasswordSubtitle =>
      'চিন্তা করবেন না! আপনার ইমেল লিখুন এবং আমরা একটি রিসেট লিংক পাঠাবো।';
  @override
  String get checkEmailForReset => 'পাসওয়ার্ড রিসেটের জন্য আপনার ইমেল চেক করুন';
  @override
  String get emailAddress => 'ইমেল ঠিকানা';
  @override
  String get enterEmailAddress => 'আপনার ইমেল ঠিকানা লিখুন';
  @override
  String get sendResetEmail => 'রিসেট ইমেল পাঠান';
  @override
  String get emailSentTo => 'ইমেল পাঠানো হয়েছে:';
  @override
  String get backToLogin => 'লগইনে ফিরে যান';
  @override
  String get resendEmail => 'পুনরায় ইমেল পাঠান';
  @override
  String get rememberPassword => 'পাসওয়ার্ড মনে পড়েছে? ';

  @override
  String get iAgreeToThe => 'আমি সম্মত হচ্ছি ';
  @override
  String get termsAndConditions => 'নিয়ম ও শর্তাবলী';
  @override
  String get and => ' এবং ';
  @override
  String get privacyPolicy => 'গোপনীয়তা নীতি';

  @override
  String get noServerResponse =>
      'সার্ভার থেকে কোনো সাড়া নেই। অনুগ্রহ করে সংযোগ পরীক্ষা করুন।';
  @override
  String get authCheckError => 'লগইন স্ট্যাটাস যাচাই করতে সমস্যা হয়েছে';
  @override
  String get invalidCredentials =>
      'ভুল ব্যবহারকারীর নাম বা পাসওয়ার্ড। অনুগ্রহ করে যাচাই করুন।';
  @override
  String get loginFailedCredentials =>
      'লগইন ব্যর্থ হয়েছে। অনুগ্রহ করে তথ্য যাচাই করুন।';
  @override
  String get serverResponseError =>
      'সার্ভার রেসপন্স ত্রুটি। অনুগ্রহ করে আবার চেষ্টা করুন।';
  @override
  String get serverError =>
      'সার্ভার ত্রুটি। পরে চেষ্টা করুন বা সহায়তায় যোগাযোগ করুন।';
  @override
  String get noInternet =>
      'ইন্টারনেট সংযোগ নেই। আপনার নেটওয়ার্ক চেক করুন।';
  @override
  String get connectionTimeout =>
      'সংযোগের সময় শেষ। অনুগ্রহ করে আবার চেষ্টা করুন।';
  @override
  String get loginFailed => 'লগইন ব্যর্থ হয়েছে। আবার চেষ্টা করুন।';

  @override
  String get accessDenied => 'অ্যাক্সেস প্রত্যাখ্যাত';
  @override
  String get accessDeniedSubtitle =>
      'WhizEats Pro ব্যবহারের জন্য আপনার অ্যাকাউন্টের অনুমতি নেই।';
  @override
  String get accessDeniedMessage =>
      'কেবলমাত্র অপারেটর এবং শেফ অ্যাকাউন্ট লগইন করতে পারবে। সঠিক অনুমতির জন্য আপনার অ্যাডমিনের সাথে যোগাযোগ করুন।';
  @override
  String get okGotIt => 'ঠিক আছে, বুঝেছি';
}

class _BnDashboardTranslations implements DashboardTranslations {
  const _BnDashboardTranslations();

  @override
  String get tables => 'টেবিল';
  @override
  String get menuLabel => 'মেনু';
  @override
  String get cart => 'কার্ট';

  @override
  String get newOrder => 'নতুন অর্ডার';

  @override
  String get errorLoadingTables => 'টেবিল লোড করতে সমস্যা হয়েছে';
  @override
  String get clearError => 'ত্রুটি মুছুন';
  @override
  String get noTablesFound => 'কোনো টেবিল পাওয়া যায়নি';
  @override
  String get changeLocation => 'অবস্থান পরিবর্তন করুন';

  @override
  String get profileTitle => 'প্রোফাইল';
  @override
  String get profileSubtitle => 'অ্যাকাউন্টের বিবরণ দেখুন';
  @override
  String get settings => 'সেটিংস';
  @override
  String get settingsSubtitle => 'অ্যাপ পছন্দ ও কনফিগারেশন';
  @override
  String get performance => 'পারফরম্যান্স';
  @override
  String get performanceSubtitle => 'রিপোর্ট এবং বিশ্লেষণ বিবরণ';
  @override
  String get settingsComingSoon => 'সেটিংস শীঘ্রই আসছে!';

  @override
  String get selectLocation => 'অবস্থান নির্বাচন করুন';
  @override
  String get selectTableForDineIn => 'ডাইন-ইন অর্ডারের জন্য একটি টেবিল বেছে নিন';
  @override
  String get errorCreatingOrder => 'অর্ডার তৈরিতে সমস্যা হয়েছে';
  @override
  String get failedToAddOrderToServer => 'সার্ভারে অর্ডার যোগ করা যায়নি';

  @override
  String get customerNameLabel => 'গ্রাহকের নাম *';
  @override
  String get phoneNumberLabel => 'ফোন নম্বর *';
  @override
  String get enterCustomerName => 'গ্রাহকের নাম লিখুন';
  @override
  String get enterPhoneNumber => 'ফোন নম্বর লিখুন';
  @override
  String get enterTenDigitMobile => '১০ ডিজিটের মোবাইল নম্বর লিখুন';
}

class _BnMenuTranslations implements MenuTranslations {
  const _BnMenuTranslations();

  @override
  String get searchDishes => 'খাবার খুঁজুন...';
  @override
  String get failedToLoadMenu => 'মেনু লোড করা যায়নি';
  @override
  String get noItemsAvailable => 'কোনো আইটেম নেই';
  @override
  String get loadMenu => 'মেনু লোড করুন';
  @override
  String get kotSentToKitchen => 'KOT রান্নাঘরের প্রিন্টারে পাঠানো হয়েছে!';
}

class _BnOrderTakingTranslations implements OrderTakingTranslations {
  const _BnOrderTakingTranslations();

  @override
  String get clearAll => 'সব মুছুন';
  @override
  String get clearAllItems => 'সব আইটেম বাদ দিন';
  @override
  String get clearCartConfirm =>
      'আপনি কি নিশ্চিত যে কার্ট থেকে না পাঠানো সমস্ত আইটেম বাদ দিতে চান? এটি পুনরুদ্ধার করা যাবে না।';
  @override
  String get specialInstructions => 'বিশেষ নির্দেশাবলী';
  @override
  String get kotGenerated => 'KOT তৈরি হয়েছে';
  @override
  String get cannotGenerateBill => 'বিল তৈরি করা যাচ্ছে না';
  @override
  String get allItemsMustHaveKot =>
      'বিল করার আগে সব আইটেমের KOT তৈরি করতে হবে';
  @override
  String get noItemsInCart => 'কার্টে কোনো আইটেম নেই';
  @override
  String get noNewItemsForKot => 'KOT তৈরির মতো কোনো নতুন আইটেম নেই';
  @override
  String get kotCreationFailed => 'KOT তৈরিতে ব্যর্থতা';
  @override
  String get checkItemsInCart => '• আইটেমগুলি কার্টে এখনও আছে কিনা তা পরীক্ষা করুন';
  @override
  String get contactSupport => '• সমস্যা চলতে থাকলে সহায়তায় যোগাযোগ করুন';
  @override
  String get pleaseGenerateKotFirst => 'অনুগ্রহ করে প্রথমে KOT তৈরি করুন';
  @override
  String get yourCartIsEmpty => 'আপনার কার্ট খালি';
  @override
  String get refresh => 'রিফ্রেশ';
}

class _BnBillingTranslations implements BillingTranslations {
  const _BnBillingTranslations();

  @override
  String get loadingPaymentModes => 'পেমেন্ট মাধ্যম লোড হচ্ছে...';

  @override
  String gstWithRate(double percentage) {
    final rate =
        percentage == percentage.roundToDouble()
            ? percentage.toStringAsFixed(0)
            : percentage.toStringAsFixed(2);
    return 'ট্যাক্স ও চার্জ ($rate%)';
  }
}

class _BnPaymentTranslations implements PaymentTranslations {
  const _BnPaymentTranslations();

  @override
  String get paymentTitle => 'পেমেন্ট';
  @override
  String get cash => 'নগদ';
  @override
  String get cashSubtitle => 'গ্রাহকের থেকে নগদ অর্থ গ্রহণ করুন';
  @override
  String get upi => 'ইউপিআই (UPI)';
  @override
  String get upiSubtitle => 'গ্রাহককে কিউআর কোড স্ক্যান করে অর্থ প্রদান করতে বলুন';
  @override
  String get noPaymentMethods => 'কোনো পেমেন্ট মাধ্যম উপলব্ধ নেই';
  @override
  String get upiHint => 'উদাঃ restaurant@upi বা 8768412832@ptsbi';
  @override
  String get saveUpiId => 'UPI ID সংরক্ষণ করুন';
  @override
  String get customerPhoneNumber => 'গ্রাহকের ফোন নম্বর';

  @override
  String get cashReceived => 'গৃহীত নগদ টাকা';
  @override
  String get cashReceivedHint => 'গ্রাহকের দেওয়া টাকার পরিমাণ';
  @override
  String get changeToReturn => 'ফেরত দেওয়ার টাকা';
  @override
  String get cashShortBy => 'টাকা কম রয়েছে';
  @override
  String get exactAmount => 'সঠিক পরিমাণ';
  @override
  String get cashShortError => 'গৃহীত নগদ টাকা বিলের পরিমাণের চেয়ে কম।';
}

class _BnChefTranslations implements ChefTranslations {
  const _BnChefTranslations();

  @override
  String get all => 'সমস্ত';
  @override
  String get queue => 'কিউ (অপেক্ষারত)';
  @override
  String get preparing => 'তৈরি হচ্ছে';
  @override
  String get serve => 'পরিবেশন করুন';

  @override
  String get noOrdersInView => 'এখানে কোনো অর্ডার নেই';
  @override
  String get filterByStatus => 'স্ট্যাটাস অনুযায়ী ফিল্টার করুন';

  @override
  String get chefProfile => 'শেফ প্রোফাইল';
  @override
  String get chefProfileSubtitle => 'রান্নাঘরের অ্যাকাউন্টের বিবরণ';

  @override
  String get enterRejectionReason => 'বাতিলের কারণ লিখুন...';
}

class _BnOrdersTranslations implements OrdersTranslations {
  const _BnOrdersTranslations();

  @override
  String get tableTab => 'টেবিল';
  @override
  String get phoneTab => 'ফোন';
  @override
  String get takeawayTab => 'টেকঅ্যাওয়ে';
  @override
  String get channelTab => 'চ্যানেল';

  @override
  String get searchOrders => 'আইডি, গ্রাহক, ফোন নম্বর দিয়ে খুঁজুন...';

  @override
  String get printOrder => 'অর্ডার প্রিন্ট করুন';
  @override
  String get shareDetails => 'বিবরণ শেয়ার করুন';
  @override
  String get printComingSoon => 'প্রিন্ট সুবিধা শীঘ্রই আসছে';
  @override
  String get shareComingSoon => 'শেয়ার সুবিধা শীঘ্রই আসছে';
  @override
  String get billIdNotAvailable => 'বিল আইডি পাওয়া যায়নি';
  @override
  String get billRegeneratedSuccessfully => 'বিল পুনরায় সফলভাবে তৈরি হয়েছে!';
  @override
  String get remainingTime => 'অবশিষ্ট সময়';
}

class _BnProfileTranslations implements ProfileTranslations {
  const _BnProfileTranslations();

  @override
  String get editProfile => 'প্রোফাইল সম্পাদনা করুন';
  @override
  String get fullName => 'পুরো নাম';
  @override
  String get role => 'ভূমিকা';
  @override
  String get phoneNumberOptional => 'ফোন নম্বর (ঐচ্ছিক)';
  @override
  String get profileUpdatedSuccessfully => 'প্রোফাইল সফলভাবে আপডেট করা হয়েছে';

  @override
  String get logoutConfirm => 'আপনি কি নিশ্চিত যে লগআউট করতে চান?';
  @override
  String get loggingOut => 'লগআউট করা হচ্ছে...';
  @override
  String get signingOut => 'সাইন আউট করা হচ্ছে...';

  @override
  String get receiptPrinter => 'রসিদ প্রিন্টার';
  @override
  String get receiptPrinterSubtitle => 'গ্রাহকের বিল ও রসিদ প্রিন্ট করুন';
  @override
  String get kitchenPrinter => 'কিচেন প্রিন্টার';
  @override
  String get kitchenPrinterSubtitle => 'KOT (কিচেন অর্ডার টিকিট) প্রিন্ট করুন';
  @override
  String get testPrint => 'টেস্ট প্রিন্ট';
  @override
  String get saveSettings => 'সেটিংস সংরক্ষণ করুন';
  @override
  String get connectPrinterFirst => 'অনুগ্রহ করে প্রথমে প্রিন্টার সংযুক্ত করুন';

  @override
  String get openingBalance => 'প্রারম্ভিক ব্যালেন্স';
  @override
  String get additionalCashIn => 'অতিরিক্ত নগদ জমা';
  @override
  String get cashInHint => 'অন্যান্য প্রাপ্তি ইত্যাদি';
  @override
  String get additionalCashOut => 'অতিরিক্ত নগদ উত্তোলন';
  @override
  String get cashOutHint => 'উত্তোলন, খুচরা খরচ ইত্যাদি';

  @override
  String get sales => 'বিক্রি';
  @override
  String get ordersLabel => 'অর্ডার';
  @override
  String get tablesLabel => 'টেবিল';
  @override
  String get reservationsLabel => 'বুকিং';

  @override
  String get aboutTitle => 'WhizEats Pro সম্পর্কে';
  @override
  String get aboutDescription => 'WhizEats Pro - রেস্তোরাঁ পরিচালনা ব্যবস্থা';
  @override
  String get version => 'ভার্সন: 1.0.0';
  @override
  String get build => 'বিল্ড: 2026.08.13';
  @override
  String get copyright => '© 2026 WhizEats Pro. সমস্ত অধিকার সংরক্ষিত।';

  @override
  String get restaurantManagement => 'রেস্তোরাঁ ব্যবস্থাপনা';
  @override
  String get restaurantDetails => 'রেস্তোরাঁর বিবরণ';
  @override
  String get restaurantDetailsSubtitle => 'রেস্তোরাঁর তথ্য সম্পাদনা করুন';
  @override
  String get staffManagement => 'কর্মী ব্যবস্থাপনা';
  @override
  String get staffManagementSubtitle => 'কর্মী ও অনুমতি পরিচালনা করুন';
  @override
  String get tableConfiguration => 'টেবিল কনফিগারেশন';
  @override
  String get tableConfigurationSubtitle => 'টেবিল ও বসার ব্যবস্থা পরিচালনা';
  @override
  String get menuManagement => 'মেনু ব্যবস্থাপনা';
  @override
  String get menuManagementSubtitle => 'মেনু আইটেম ও মূল্য আপডেট করুন';

  @override
  String get businessAnalytics => 'ব্যবসায়িক বিশ্লেষণ';
  @override
  String get salesReports => 'বিক্রয় রিপোর্ট';
  @override
  String get salesReportsSubtitle => 'দৈনিক, সাপ্তাহিক, মাসিক রিপোর্ট';
  @override
  String get performanceMetrics => 'পারফরম্যান্স মেট্রিক্স';
  @override
  String get performanceMetricsSubtitle => 'জনপ্রিয় আইটেম ও ব্যস্ত সময়';
  @override
  String get inventoryReports => 'ইনভেন্টরি রিপোর্ট';
  @override
  String get inventoryReportsSubtitle => 'স্টকের পরিমাণ ও সতর্কতা';
  @override
  String get customerAnalytics => 'গ্রাহক বিশ্লেষণ';
  @override
  String get customerAnalyticsSubtitle => 'গ্রাহকের পছন্দ ও প্রবণতা';

  @override
  String get financialManagement => 'আর্থিক ব্যবস্থাপনা';
  @override
  String get dailyCashManagement => 'দৈনিক নগদ ব্যবস্থাপনা';
  @override
  String get dailyCashManagementSubtitle => 'ওপেনিং ও ক্লোজিং ব্যালেন্স';
  @override
  String get expenseTracking => 'খরচ ট্র্যাকিং';
  @override
  String get expenseTrackingSubtitle => 'দৈনিক খরচ লিপিবদ্ধ করুন';
  @override
  String get profitAndLoss => 'লাভ ও ক্ষতি';
  @override
  String get profitAndLossSubtitle => 'আর্থিক ফলাফল';
  @override
  String get taxReports => 'ট্যাক্স রিপোর্ট';
  @override
  String get taxReportsSubtitle => 'জিএসটি ও ট্যাক্স হিসাব';

  @override
  String get systemAndSettings => 'সিস্টেম ও সেটিংস';
  @override
  String get printerSettings => 'প্রিন্টার সেটিংস';
  @override
  String get printerSettingsSubtitle => 'রসিদ ও কিচেন প্রিন্টার সেটআপ';
  @override
  String get paymentMethods => 'পেমেন্ট পদ্ধতি';
  @override
  String get paymentMethodsSubtitle => 'পেমেন্ট বিকল্পসমূহ চালু করুন';
  @override
  String get taxConfiguration => 'ট্যাক্স কনফিগারেশন';
  @override
  String get taxConfigurationSubtitle => 'জিএসটি হার ও সার্ভিস চার্জ';
  @override
  String get dataBackup => 'ডেটা ব্যাকআপ';
  @override
  String get dataBackupSubtitle => 'ডেটা ব্যাকআপ ও পুনরুদ্ধার';

  @override
  String get helpAndSupport => 'সহায়তা ও সমর্থন';
  @override
  String get userManual => 'ব্যবহারকারী নির্দেশিকা';
  @override
  String get userManualSubtitle => 'অ্যাপ ব্যবহারের নিয়ম';
  @override
  String get technicalSupport => 'প্রযুক্তিগত সহায়তা';
  @override
  String get technicalSupportSubtitle => 'সাপোর্ট টিমের সাথে যোগাযোগ';
  @override
  String get appUpdates => 'অ্যাপ আপডেট';
  @override
  String get appUpdatesSubtitle => 'আপডেট চেক করুন';
  @override
  String get aboutApp => 'অ্যাপ সম্পর্কে';
  @override
  String get aboutAppSubtitle => 'ভার্সন ও অ্যাপ সংক্রান্ত তথ্য';

  @override
  String get topPerformer => 'সেরা পারফর্মার';
  @override
  String get customerFavorite => 'গ্রাহকদের পছন্দের';

  @override
  String get language => 'ভাষা';
  @override
  String get languageSubtitle => 'English / हिन्दी / বাংলা';
}

class _BnReservationsTranslations implements ReservationsTranslations {
  const _BnReservationsTranslations();

  @override
  String get customerNameRequired => 'গ্রাহকের নাম *';
  @override
  String get enterFullName => 'পুরো নাম লিখুন';
  @override
  String get phoneNumberRequired => 'ফোন নম্বর *';
  @override
  String get enterTenDigitNumber => '১০ ডিজিটের নম্বর লিখুন';
  @override
  String get numberOfPersons => 'ব্যক্তির সংখ্যা';
  @override
  String get enterNumberOfPersons => 'কতজনের জন্য তা লিখুন';
  @override
  String get specialOccasion => 'বিশেষ উপলক্ষ';
  @override
  String get specialNotesOptional => 'বিশেষ নোট (ঐচ্ছিক)';
  @override
  String get specialNotesHint => 'কোনো বিশেষ চাহিদা বা নির্দেশ...';
  @override
  String get from => 'হতে';
  @override
  String get to => 'পর্যন্ত';
  @override
  String get enterAdvanceAmount => 'অগ্রিম টাকার পরিমাণ লিখুন';

  @override
  String get reservationRules => 'বুকিং নিয়মাবলী';
  @override
  String get advanceBooking => 'অগ্রিম বুকিং';
  @override
  String get operatingHours => 'কার্যক্রমের সময়';
  @override
  String get durationLimits => 'সময়সীমা';
  @override
  String get advancePayment => 'অগ্রিম পেমেন্ট';

  @override
  String get selectReservationTime => 'অনুগ্রহ করে বুকিং সময় নির্বাচন করুন';
  @override
  String get tableAlreadyReserved => 'এই সময়ের জন্য টেবিলটি ইতিমধ্যে সংরক্ষিত';
  @override
  String get failedToCreateReservation => 'বুকিং তৈরিতে ব্যর্থ হয়েছে';
  @override
  String get generatingPdfBill => 'পিডিএফ বিল তৈরি করা হচ্ছে...';
  @override
  String get shareBill => 'বিল শেয়ার করুন';
  @override
  String get sharingBillToWhatsApp => 'হোয়াটসঅ্যাপে বিল পাঠানো হচ্ছে...';
  @override
  String get selectWhatsApp => 'অনুগ্রহ করে শেয়ার অপশন থেকে হোয়াটসঅ্যাপ বেছে নিন';

  @override
  String get decorationSubtitle => '₹৪০০ - বেলুন, ফুল ও টেবিল সাজসজ্জা';
}

class _BnReportsTranslations implements ReportsTranslations {
  const _BnReportsTranslations();

  @override
  String get selectTimePeriod => 'সময় নির্বাচন করুন';
  @override
  String get totalRevenue => 'মোট আয়';
  @override
  String get totalOrders => 'মোট অর্ডার';
  @override
  String get avgOrderValue => 'গড় অর্ডার মূল্য';
  @override
  String get tableTurnoverRate => 'টেবিল ব্যবহারের হার';
  @override
  String get pdfLabel => 'পিডিএফ';
  @override
  String get csvLabel => 'সিএসভি';
  @override
  String get generatingReport => 'রিপোর্ট তৈরি করা হচ্ছে...';
}

class _BnNetworkTranslations implements NetworkTranslations {
  const _BnNetworkTranslations();

  @override
  String get uhOh => 'উহ্ ওহ!';
  @override
  String get noDataOrWifi =>
      'মনে হচ্ছে আপনি মোবাইল ডেটা বা ওয়াই-ফাই চালু করেননি';
  @override
  String get checkInternetAndRetry =>
      'অনুগ্রহ করে ইন্টারনেট সংযোগ পরীক্ষা করে আবার চেষ্টা করুন';
  @override
  String get checking => 'যাচাই করা হচ্ছে...';
  @override
  String get openSettings => 'সেটিংস খুলুন';
  @override
  String get checkDeviceSettings =>
      'অনুগ্রহ করে ডিভাইসের নেটওয়ার্ক সেটিংস চেক করুন';
  @override
  String get quickTips => 'দ্রুত পরামর্শ';
  @override
  String get tipWifi => 'ওয়াই-ফাই বা মোবাইল ডেটা চালু করুন';
  @override
  String get tipAirplane => 'বিমান মোড (Airplane mode) বন্ধ আছে কিনা দেখুন';
  @override
  String get tipSignal => 'ভালো সিগন্যাল পাওয়ার জায়গায় যান';
  @override
  String get slowNetwork => 'ধীরগতির নেটওয়ার্ক';
  @override
  String get slowNetworkDesc =>
      'দুর্বল সংযোগের কারণে ডেটা লোড হতে দেরি হচ্ছে';
}

class _BnValidationTranslations implements ValidationTranslations {
  const _BnValidationTranslations();

  @override
  String get nameTooShort => 'নাম কমপক্ষে ২ অক্ষরের হতে হবে';
  @override
  String get enterPhoneNumber => 'অনুগ্রহ করে ফোন নম্বর লিখুন';
  @override
  String get phoneMustBeTenDigits => 'ফোন নম্বর ঠিক ১০ ডিজিটের হতে হবে';
  @override
  String get phoneMustStartWith => 'ফোন নম্বর ৬, ৭, ৮ বা ৯ দিয়ে শুরু হতে হবে';
  @override
  String get enterValidPhone => 'অনুগ্রহ করে একটি সঠিক ফোন নম্বর লিখুন';
  @override
  String get enterEmail => 'অনুগ্রহ করে আপনার ইমেল ঠিকানা লিখুন';
  @override
  String get enterValidEmail => 'অনুগ্রহ করে একটি সঠিক ইমেল ঠিকানা দিন';
}

class _BnPdfTranslations implements PdfTranslations {
  const _BnPdfTranslations();

  @override
  String get baseAmount => 'মূল পরিমাণ:';
  @override
  String get tableDecoration => 'টেবিল সাজসজ্জা:';
  @override
  String get arriveOnTime => 'অনুগ্রহ করে আপনার বুকিং সময়ে পৌঁছান';
  @override
  String get remainingAmountNote =>
      'বাকি টাকা রেস্তোরাঁয় পরিশোধ করতে হবে';
  @override
  String get arriveEarly => '• অনুগ্রহ করে ১৫ মিনিট আগে পৌঁছান';
  @override
  String get nonRefundable => '• অগ্রিম টাকা ফেরতযোগ্য নয়';
  @override
  String get tableHeldNote => '• টেবিল শুধুমাত্র ১৫ মিনিটের জন্য সংরক্ষিত রাখা হবে';
  @override
  String get changesContact => '• কোনো পরিবর্তনের জন্য কল করুন: +91-8768412832';
  @override
  String get reservationBillShareText => 'WhizEats Pro থেকে আপনার বুকিং বিল';

  @override
  String get whatsAppKitchen => 'হোয়াটসঅ্যাপ কিচেন';
  @override
  String get whatsAppKitchenSubtitle =>
      'অর্ডার অ্যালার্ট বার্তা পাঠান (+91 87684 12832)';
  @override
  String get sharePdfDocument => 'পিডিএফ ডকুমেন্ট শেয়ার করুন';
  @override
  String get sharePdfSubtitle =>
      'পিডিএফ ফাইল পাঠাতে শেয়ার ডায়ালগ খুলুন';
}

class _BnDrawerTranslations implements DrawerTranslations {
  const _BnDrawerTranslations();

  @override
  String get locations => 'অবস্থানসমূহ (LOCATIONS)';
  @override
  String get quickActions => 'দ্রুত কাজ (QUICK ACTIONS)';
  @override
  String get pendingPayments => 'বকেয়া পেমেন্ট';
  @override
  String get pendingPaymentsSubtitle => 'অপরিশোধিত বিলের টাকা সংগ্রহ করুন';
  @override
  String get reprint => 'পুনরায় প্রিন্ট';
  @override
  String get reprintSubtitle => 'পূর্বের বিল ও KOT সমূহ';
  @override
  String get account => 'অ্যাকাউন্ট (ACCOUNT)';
  @override
  String get ordersManagement => 'অর্ডার ব্যবস্থাপনা';
  @override
  String get ordersManagementSubtitle => 'সকল অর্ডার দেখুন ও ট্র্যাক করুন';
  @override
  String get readyToCollect => 'নেওয়ার জন্য প্রস্তুত';
  @override
  String get readyToCollectSubtitle => 'রান্নাঘর থেকে প্রস্তুত খাবার সংগ্রহ করুন';
  @override
  String get kitchenMenu => 'কিচেন মেনু';
  @override
  String get language => 'ভাষা';
  @override
  String get languageSubtitle => 'ভাষা নির্বাচন করুন';
  @override
  String get selectLanguage => 'ভাষা নির্বাচন করুন';
  @override
  String get chooseLanguage => 'আপনার পছন্দের ভাষা বেছে নিন';
  @override
  String get english => 'English';
  @override
  String get hindi => 'हिन्दी (Hindi)';
  @override
  String get bengali => 'বাংলা (Bengali)';
  @override
  String get languageChanged => 'ভাষা সফলভাবে পরিবর্তন করা হয়েছে';
}
