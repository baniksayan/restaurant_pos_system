import 'app_translations.dart';

class HiTranslations implements AppTranslations {
  const HiTranslations();

  @override
  String get appName => 'WhizEats Pro';
  @override
  String get appTagline => 'रेस्टोरेंट प्रबंधन और पीओएस';
  @override
  String get currencySymbol => '₹';
  @override
  String get brandName => 'WhizEats';
  @override
  String get brandSuffix => 'PRO';
  @override
  String get posTagline => 'रेस्टोरेंट पीओएस सिस्टम';
  @override
  String get poweredBy => 'विज़ार्ड कम्युनिकेशंस प्रा. लि. द्वारा संचालित';
  @override
  String get solutionTagline => 'उन्नत रेस्टोरेंट प्रबंधन समाधान';

  @override
  String get privacyPolicyUrl =>
      'https://stdpos.wizardcomm.net/WhizEatsPro/privacy-policy.html';
  @override
  String get termsAndConditionsUrl =>
      'https://stdpos.wizardcomm.net/WhizEatsPro/terms-and-conditions.html';

  @override
  String get ok => 'ठीक है';
  @override
  String get cancel => 'रद्द करें';
  @override
  String get save => 'सहेजें';
  @override
  String get delete => 'हटाएं';
  @override
  String get confirm => 'पुष्टि करें';
  @override
  String get retry => 'पुनः प्रयास करें';
  @override
  String get back => 'वापस';
  @override
  String get close => 'बंद करें';
  @override
  String get tryAgain => 'पुनः प्रयास करें';
  @override
  String get gotIt => 'समझ गया';
  @override
  String get okGotIt => 'ठीक है, समझ गया';
  @override
  String get done => 'संपन्न';
  @override
  String get login => 'लॉगिन';
  @override
  String get logout => 'लॉगआउट';
  @override
  String get signOut => 'साइन आउट';
  @override
  String get accessDenied => 'पहुंच अस्वीकृत';
  @override
  String get signingOut => 'साइन आउट हो रहा है...';
  @override
  String get loggingOut => 'लॉगआउट हो रहा है...';
  @override
  String get signOutConfirmation => 'साइन आउट पुष्टि';
  @override
  String get signOutProConfirm =>
      'क्या आप निश्चित रूप से WhizEats Pro से साइन आउट करना चाहते हैं?';
  @override
  String get signOutKdsConfirm =>
      'क्या आप निश्चित रूप से WhizEats KDS से साइन आउट करना चाहते हैं?';
  @override
  String get signingOutOfKds => 'KDS से साइन आउट हो रहा है...';
  @override
  String get connect => 'कनेक्ट करें';
  @override
  String get clear => 'साफ़ करें';
  @override
  String get openNavigationDrawer => 'नेविगेशन ड्रॉअर खोलें';

  @override
  String get unitPrice => 'इकाई मूल्य';
  @override
  String get quantity => 'मात्रा';
  @override
  String get total => 'कुल';
  @override
  String get subtotal => 'उप-कुल';
  @override
  String get customerName => 'ग्राहक का नाम';
  @override
  String get phoneNumber => 'फ़ोन नंबर';

  @override
  String get noInternetTitle => 'कोई इंटरनेट कनेक्शन नहीं';
  @override
  String get noInternetDesc => 'कृपया अपना कनेक्शन जांचें और पुनः प्रयास करें।';

  @override
  AuthTranslations get auth => const _HiAuthTranslations();
  @override
  DashboardTranslations get dashboard => const _HiDashboardTranslations();
  @override
  MenuTranslations get menu => const _HiMenuTranslations();
  @override
  OrderTakingTranslations get orderTaking => const _HiOrderTakingTranslations();
  @override
  BillingTranslations get billing => const _HiBillingTranslations();
  @override
  PaymentTranslations get payment => const _HiPaymentTranslations();
  @override
  ChefTranslations get chef => const _HiChefTranslations();
  @override
  OrdersTranslations get orders => const _HiOrdersTranslations();
  @override
  ProfileTranslations get profile => const _HiProfileTranslations();
  @override
  ReservationsTranslations get reservations =>
      const _HiReservationsTranslations();
  @override
  ReportsTranslations get reports => const _HiReportsTranslations();
  @override
  NetworkTranslations get network => const _HiNetworkTranslations();
  @override
  ValidationTranslations get validation => const _HiValidationTranslations();
  @override
  PdfTranslations get pdf => const _HiPdfTranslations();
  @override
  DrawerTranslations get drawer => const _HiDrawerTranslations();
}

class _HiAuthTranslations implements AuthTranslations {
  const _HiAuthTranslations();

  @override
  String get logIn => 'लॉग इन';
  @override
  String get userName => 'उपयोगकर्ता नाम';
  @override
  String get password => 'पासवर्ड';
  @override
  String get enterUsername => 'अपना उपयोगकर्ता नाम दर्ज करें';
  @override
  String get enterPassword => 'अपना पासवर्ड दर्ज करें';
  @override
  String get forgotPassword => 'पासवर्ड भूल गए?';
  @override
  String get forgotPasswordSubtitle =>
      'चिंता न करें! अपना ईमेल पता दर्ज करें और हम पासवर्ड रीसेट करने का लिंक भेजेंगे।';
  @override
  String get checkEmailForReset => 'रीसेट निर्देशों के लिए अपना ईमेल जांचें';
  @override
  String get emailAddress => 'ईमेल पता';
  @override
  String get enterEmailAddress => 'अपना ईमेल पता दर्ज करें';
  @override
  String get sendResetEmail => 'रीसेट ईमेल भेजें';
  @override
  String get emailSentTo => 'ईमेल भेजा गया:';
  @override
  String get backToLogin => 'लॉगिन पर वापस जाएं';
  @override
  String get resendEmail => 'ईमेल पुनः भेजें';
  @override
  String get rememberPassword => 'क्या पासवर्ड याद आ गया? ';

  @override
  String get iAgreeToThe => 'मैं सहमत हूँ ';
  @override
  String get termsAndConditions => 'नियम और शर्तें';
  @override
  String get and => ' और ';
  @override
  String get privacyPolicy => 'गोपनीयता नीति';

  @override
  String get noServerResponse =>
      'सर्वर से कोई प्रतिक्रिया नहीं। कृपया अपना कनेक्शन जांचें।';
  @override
  String get authCheckError => 'प्रमाणीकरण स्थिति जांचने में त्रुटि';
  @override
  String get invalidCredentials =>
      'गलत उपयोगकर्ता नाम या पासवर्ड। कृपया जांचें।';
  @override
  String get loginFailedCredentials =>
      'लॉगिन विफल। कृपया अपने क्रेडेंशियल्स जांचें।';
  @override
  String get serverResponseError =>
      'सर्वर प्रतिक्रिया में त्रुटि। कृपया पुनः प्रयास करें।';
  @override
  String get serverError =>
      'सर्वर त्रुटि। कृपया बाद में प्रयास करें या सहायता से संपर्क करें।';
  @override
  String get noInternet =>
      'कोई इंटरनेट कनेक्शन नहीं। कृपया अपना नेटवर्क जांचें।';
  @override
  String get connectionTimeout =>
      'कनेक्शन समय समाप्त। कृपया पुनः प्रयास करें।';
  @override
  String get loginFailed => 'लॉगिन विफल। कृपया पुनः प्रयास करें।';

  @override
  String get accessDenied => 'पहुंच अस्वीकृत';
  @override
  String get accessDeniedSubtitle =>
      'आपके खाते के पास WhizEats Pro तक पहुंचने की अनुमति नहीं है।';
  @override
  String get accessDeniedMessage =>
      'केवल ऑपरेटर और शेफ खातों को साइन इन करने की अनुमति है। कृपया सही पहुंच प्राप्त करने के लिए अपने व्यवस्थापक से संपर्क करें।';
  @override
  String get okGotIt => 'ठीक है, समझ गया';
}

class _HiDashboardTranslations implements DashboardTranslations {
  const _HiDashboardTranslations();

  @override
  String get tables => 'टेबल';
  @override
  String get menuLabel => 'मेन्यू';
  @override
  String get cart => 'कार्ट';

  @override
  String get newOrder => 'नया ऑर्डर';

  @override
  String get errorLoadingTables => 'टेबल लोड करने में त्रुटि';
  @override
  String get clearError => 'त्रुटि हटाएं';
  @override
  String get noTablesFound => 'कोई टेबल नहीं मिली';
  @override
  String get changeLocation => 'स्थान बदलें';

  @override
  String get profileTitle => 'प्रोफ़ाइल';
  @override
  String get profileSubtitle => 'खाता विवरण देखें';
  @override
  String get settings => 'सेटिंग्स';
  @override
  String get settingsSubtitle => 'ऐप प्राथमिकताएं और कॉन्फ़िगरेशन';
  @override
  String get performance => 'प्रदर्शन';
  @override
  String get performanceSubtitle => 'रिपोर्ट और विश्लेषण अवलोकन';
  @override
  String get settingsComingSoon => 'सेटिंग्स जल्द आ रही हैं!';

  @override
  String get selectLocation => 'स्थान चुनें';
  @override
  String get selectTableForDineIn => 'डाइन-इन ऑर्डर के लिए टेबल चुनें';
  @override
  String get errorCreatingOrder => 'ऑर्डर बनाने में त्रुटि';
  @override
  String get failedToAddOrderToServer => 'सर्वर में ऑर्डर जोड़ने में विफल';

  @override
  String get customerNameLabel => 'ग्राहक का नाम *';
  @override
  String get phoneNumberLabel => 'फ़ोन नंबर *';
  @override
  String get enterCustomerName => 'ग्राहक का नाम दर्ज करें';
  @override
  String get enterPhoneNumber => 'फ़ोन नंबर दर्ज करें';
  @override
  String get enterTenDigitMobile => '10 अंकों का मोबाइल नंबर दर्ज करें';
}

class _HiMenuTranslations implements MenuTranslations {
  const _HiMenuTranslations();

  @override
  String get searchDishes => 'व्यंजन खोजें...';
  @override
  String get failedToLoadMenu => 'मेन्यू लोड करने में विफल';
  @override
  String get noItemsAvailable => 'कोई आइटम उपलब्ध नहीं';
  @override
  String get loadMenu => 'मेन्यू लोड करें';
  @override
  String get kotSentToKitchen => 'KOT किचन प्रिंटर पर भेज दिया गया!';
}

class _HiOrderTakingTranslations implements OrderTakingTranslations {
  const _HiOrderTakingTranslations();

  @override
  String get clearAll => 'सब साफ़ करें';
  @override
  String get clearAllItems => 'सभी आइटम हटाएं';
  @override
  String get clearCartConfirm =>
      'क्या आप निश्चित रूप से अपने कार्ट से सभी बिना भेजे गए आइटम हटाना चाहते हैं? यह क्रिया पूर्ववत नहीं की जा सकती।';
  @override
  String get specialInstructions => 'विशेष निर्देश';
  @override
  String get kotGenerated => 'KOT जनरेट हो गया';
  @override
  String get cannotGenerateBill => 'बिल जनरेट नहीं हो सकता';
  @override
  String get allItemsMustHaveKot =>
      'बिलिंग से पहले सभी आइटमों के लिए KOT जनरेट होना चाहिए';
  @override
  String get noItemsInCart => 'वापस नेविगेट करने के लिए कार्ट में कोई आइटम नहीं';
  @override
  String get noNewItemsForKot => 'KOT के लिए कोई नया आइटम नहीं है';
  @override
  String get kotCreationFailed => 'KOT निर्माण विफल';
  @override
  String get checkItemsInCart => '• जांचें कि आइटम अभी भी आपके कार्ट में हैं या नहीं';
  @override
  String get contactSupport => '• यदि समस्या बनी रहती है तो सहायता से संपर्क करें';
  @override
  String get pleaseGenerateKotFirst => 'कृपया पहले KOT जनरेट करें';
  @override
  String get yourCartIsEmpty => 'आपका कार्ट खाली है';
  @override
  String get refresh => 'रिफ्रेश करें';
}

class _HiBillingTranslations implements BillingTranslations {
  const _HiBillingTranslations();

  @override
  String get loadingPaymentModes => 'भुगतान के तरीके लोड हो रहे हैं...';

  @override
  String gstWithRate(double percentage) {
    final rate =
        percentage == percentage.roundToDouble()
            ? percentage.toStringAsFixed(0)
            : percentage.toStringAsFixed(2);
    return 'कर और शुल्क ($rate%)';
  }
}

class _HiPaymentTranslations implements PaymentTranslations {
  const _HiPaymentTranslations();

  @override
  String get paymentTitle => 'भुगतान';
  @override
  String get cash => 'नकद';
  @override
  String get cashSubtitle => 'ग्राहक से नकद भुगतान प्राप्त करें';
  @override
  String get upi => 'यूपीआई (UPI)';
  @override
  String get upiSubtitle => 'ग्राहक को क्यूआर कोड स्कैन करके भुगतान करने को कहें';
  @override
  String get noPaymentMethods => 'कोई भुगतान विधि उपलब्ध नहीं';
  @override
  String get upiHint => 'उदा. restaurant@upi या 8768412832@ptsbi';
  @override
  String get saveUpiId => 'UPI ID सहेजें';
  @override
  String get customerPhoneNumber => 'ग्राहक का फ़ोन नंबर';

  @override
  String get cashReceived => 'प्राप्त नकद';
  @override
  String get cashReceivedHint => 'ग्राहक द्वारा दी गई राशि';
  @override
  String get changeToReturn => 'वापस करने योग्य राशि';
  @override
  String get cashShortBy => 'नकद राशि कम है';
  @override
  String get exactAmount => 'सटीक राशि';
  @override
  String get cashShortError => 'प्राप्त नकद बिल राशि से कम है।';
}

class _HiChefTranslations implements ChefTranslations {
  const _HiChefTranslations();

  @override
  String get all => 'सभी';
  @override
  String get queue => 'कतार';
  @override
  String get preparing => 'तैयार हो रहा है';
  @override
  String get serve => 'परोसें';

  @override
  String get noOrdersInView => 'इस दृश्य में कोई ऑर्डर नहीं है';
  @override
  String get filterByStatus => 'स्थिति के अनुसार फ़िल्टर करें';

  @override
  String get chefProfile => 'शेफ प्रोफ़ाइल';
  @override
  String get chefProfileSubtitle => 'रसोई खाता विवरण';

  @override
  String get enterRejectionReason => 'अस्वीकृति का कारण दर्ज करें...';
}

class _HiOrdersTranslations implements OrdersTranslations {
  const _HiOrdersTranslations();

  @override
  String get tableTab => 'टेबल';
  @override
  String get phoneTab => 'फ़ोन';
  @override
  String get takeawayTab => 'टेकअवे';
  @override
  String get channelTab => 'चैनल';

  @override
  String get searchOrders => 'आईडी, ग्राहक, फ़ोन आदि से ऑर्डर खोजें...';

  @override
  String get printOrder => 'ऑर्डर प्रिंट करें';
  @override
  String get shareDetails => 'विवरण साझा करें';
  @override
  String get printComingSoon => 'प्रिंट सुविधा जल्द आ रही है';
  @override
  String get shareComingSoon => 'साझा करने की सुविधा जल्द आ रही है';
  @override
  String get billIdNotAvailable => 'बिल आईडी उपलब्ध नहीं है';
  @override
  String get billRegeneratedSuccessfully => 'बिल सफलतापूर्वक पुनः जनरेट किया गया!';
  @override
  String get remainingTime => 'शेष समय';
}

class _HiProfileTranslations implements ProfileTranslations {
  const _HiProfileTranslations();

  @override
  String get editProfile => 'प्रोफ़ाइल संपादित करें';
  @override
  String get fullName => 'पूरा नाम';
  @override
  String get role => 'भूमिका';
  @override
  String get phoneNumberOptional => 'फ़ोन नंबर (वैकल्पिक)';
  @override
  String get profileUpdatedSuccessfully => 'प्रोफ़ाइल सफलतापूर्वक अपडेट की गई';

  @override
  String get logoutConfirm => 'क्या आप निश्चित रूप से लॉगआउट करना चाहते हैं?';
  @override
  String get loggingOut => 'लॉगआउट हो रहा है...';
  @override
  String get signingOut => 'साइन आउट हो रहा है...';

  @override
  String get receiptPrinter => 'रसीद प्रिंटर';
  @override
  String get receiptPrinterSubtitle => 'ग्राहक बिल और रसीदें प्रिंट करें';
  @override
  String get kitchenPrinter => 'किचन प्रिंटर';
  @override
  String get kitchenPrinterSubtitle => 'KOT (किचन ऑर्डर टिकट) प्रिंट करें';
  @override
  String get testPrint => 'टेस्ट प्रिंट';
  @override
  String get saveSettings => 'सेटिंग्स सहेजें';
  @override
  String get connectPrinterFirst => 'कृपया पहले एक प्रिंटर कनेक्ट करें';

  @override
  String get openingBalance => 'प्रारंभिक शेष';
  @override
  String get additionalCashIn => 'अतिरिक्त नकद आवक';
  @override
  String get cashInHint => 'अन्य प्राप्तियां, आदि';
  @override
  String get additionalCashOut => 'अतिरिक्त नकद निकासी';
  @override
  String get cashOutHint => 'निकासी, फुटकर खर्च, आदि';

  @override
  String get sales => 'बिक्री';
  @override
  String get ordersLabel => 'ऑर्डर्स';
  @override
  String get tablesLabel => 'टेबल्स';
  @override
  String get reservationsLabel => 'आरक्षण';

  @override
  String get aboutTitle => 'WhizEats Pro के बारे में';
  @override
  String get aboutDescription => 'WhizEats Pro - रेस्टोरेंट प्रबंधन प्रणाली';
  @override
  String get version => 'संस्करण: 1.0.0';
  @override
  String get build => 'बिल्ड: 2026.08.13';
  @override
  String get copyright => '© 2026 WhizEats Pro. सर्वाधिकार सुरक्षित।';

  @override
  String get restaurantManagement => 'रेस्टोरेंट प्रबंधन';
  @override
  String get restaurantDetails => 'रेस्टोरेंट विवरण';
  @override
  String get restaurantDetailsSubtitle => 'रेस्टोरेंट की जानकारी संपादित करें';
  @override
  String get staffManagement => 'स्टाफ प्रबंधन';
  @override
  String get staffManagementSubtitle => 'कर्मचारी और अनुमतियां प्रबंधित करें';
  @override
  String get tableConfiguration => 'टेबल कॉन्फ़िगरेशन';
  @override
  String get tableConfigurationSubtitle => 'टेबल और बैठक व्यवस्था प्रबंधित करें';
  @override
  String get menuManagement => 'मेन्यू प्रबंधन';
  @override
  String get menuManagementSubtitle => 'मेन्यू आइटम और कीमतें अपडेट करें';

  @override
  String get businessAnalytics => 'बिजनेस एनालिटिक्स';
  @override
  String get salesReports => 'बिक्री रिपोर्ट';
  @override
  String get salesReportsSubtitle => 'दैनिक, साप्ताहिक, मासिक रिपोर्ट';
  @override
  String get performanceMetrics => 'प्रदर्शन मेट्रिक्स';
  @override
  String get performanceMetricsSubtitle => 'लोकप्रिय आइटम और पीक आवर्स';
  @override
  String get inventoryReports => 'इन्वेंटरी रिपोर्ट';
  @override
  String get inventoryReportsSubtitle => 'स्टॉक स्तर और अलर्ट';
  @override
  String get customerAnalytics => 'ग्राहक विश्लेषण';
  @override
  String get customerAnalyticsSubtitle => 'ग्राहक व्यवहार अंतर्दृष्टि';

  @override
  String get financialManagement => 'वित्तीय प्रबंधन';
  @override
  String get dailyCashManagement => 'दैनिक नकद प्रबंधन';
  @override
  String get dailyCashManagementSubtitle => 'ओपनिंग, क्लोजिंग बैलेंस';
  @override
  String get expenseTracking => 'खर्च ट्रैकिंग';
  @override
  String get expenseTrackingSubtitle => 'दैनिक खर्च दर्ज करें';
  @override
  String get profitAndLoss => 'लाभ और हानि';
  @override
  String get profitAndLossSubtitle => 'वित्तीय प्रदर्शन';
  @override
  String get taxReports => 'टैक्स रिपोर्ट';
  @override
  String get taxReportsSubtitle => 'जीएसटी और टैक्स गणना';

  @override
  String get systemAndSettings => 'सिस्टम और सेटिंग्स';
  @override
  String get printerSettings => 'प्रिंटर सेटिंग्स';
  @override
  String get printerSettingsSubtitle => 'रसीद और किचन प्रिंटर कॉन्फ़िगर करें';
  @override
  String get paymentMethods => 'भुगतान के तरीके';
  @override
  String get paymentMethodsSubtitle => 'भुगतान विकल्प सक्षम करें';
  @override
  String get taxConfiguration => 'टैक्स कॉन्फ़िगरेशन';
  @override
  String get taxConfigurationSubtitle => 'जीएसटी दरें और सेवा शुल्क';
  @override
  String get dataBackup => 'डेटा बैकअप';
  @override
  String get dataBackupSubtitle => 'डेटा बैकअप और पुनर्स्थापना';

  @override
  String get helpAndSupport => 'सहायता और समर्थन';
  @override
  String get userManual => 'उपयोगकर्ता गाइड';
  @override
  String get userManualSubtitle => 'ऐप का उपयोग कैसे करें';
  @override
  String get technicalSupport => 'तकनीकी सहायता';
  @override
  String get technicalSupportSubtitle => 'सपोर्ट टीम से संपर्क करें';
  @override
  String get appUpdates => 'ऐप अपडेट';
  @override
  String get appUpdatesSubtitle => 'अपडेट की जांच करें';
  @override
  String get aboutApp => 'ऐप के बारे में';
  @override
  String get aboutAppSubtitle => 'संस्करण और ऐप जानकारी';

  @override
  String get topPerformer => 'शीर्ष प्रदर्शनकर्ता';
  @override
  String get customerFavorite => 'ग्राहकों की पसंद';

  @override
  String get language => 'भाषा';
  @override
  String get languageSubtitle => 'English / हिन्दी / বাংলা';
}

class _HiReservationsTranslations implements ReservationsTranslations {
  const _HiReservationsTranslations();

  @override
  String get customerNameRequired => 'ग्राहक का नाम *';
  @override
  String get enterFullName => 'पूरा नाम दर्ज करें';
  @override
  String get phoneNumberRequired => 'फ़ोन नंबर *';
  @override
  String get enterTenDigitNumber => '10 अंकों का नंबर दर्ज करें';
  @override
  String get numberOfPersons => 'व्यक्तियों की संख्या';
  @override
  String get enterNumberOfPersons => 'व्यक्तियों की संख्या दर्ज करें';
  @override
  String get specialOccasion => 'विशेष अवसर';
  @override
  String get specialNotesOptional => 'विशेष नोट्स (वैकल्पिक)';
  @override
  String get specialNotesHint => 'कोई विशेष आवश्यकता या नोट...';
  @override
  String get from => 'से';
  @override
  String get to => 'तक';
  @override
  String get enterAdvanceAmount => 'अग्रिम राशि दर्ज करें';

  @override
  String get reservationRules => 'आरक्षण नियम';
  @override
  String get advanceBooking => 'अग्रिम बुकिंग';
  @override
  String get operatingHours => 'कार्य के घंटे';
  @override
  String get durationLimits => 'समय सीमा';
  @override
  String get advancePayment => 'अग्रिम भुगतान';

  @override
  String get selectReservationTime => 'कृपया आरक्षण समय चुनें';
  @override
  String get tableAlreadyReserved => 'इस समय स्लॉट के लिए टेबल पहले से आरक्षित है';
  @override
  String get failedToCreateReservation => 'आरक्षण बनाने में विफल';
  @override
  String get generatingPdfBill => 'पीडीएफ बिल तैयार हो रहा है...';
  @override
  String get shareBill => 'बिल साझा करें';
  @override
  String get sharingBillToWhatsApp => 'व्हाट्सएप पर बिल साझा हो रहा है...';
  @override
  String get selectWhatsApp => 'कृपया साझाकरण विकल्पों में से व्हाट्सएप चुनें';

  @override
  String get decorationSubtitle => '₹400 - गुब्बारे, फूल और टेबल सजावट';
}

class _HiReportsTranslations implements ReportsTranslations {
  const _HiReportsTranslations();

  @override
  String get selectTimePeriod => 'समय अवधि चुनें';
  @override
  String get totalRevenue => 'कुल राजस्व';
  @override
  String get totalOrders => 'कुल ऑर्डर्स';
  @override
  String get avgOrderValue => 'औसत ऑर्डर मूल्य';
  @override
  String get tableTurnoverRate => 'टेबल टर्नओवर दर';
  @override
  String get pdfLabel => 'पीडीएफ';
  @override
  String get csvLabel => 'सीएसवी';
  @override
  String get generatingReport => 'रिपोर्ट तैयार हो रही है...';
}

class _HiNetworkTranslations implements NetworkTranslations {
  const _HiNetworkTranslations();

  @override
  String get uhOh => 'ओह!';
  @override
  String get noDataOrWifi =>
      'ऐसा लगता है कि आपने मोबाइल डेटा या वाई-फाई चालू नहीं किया है';
  @override
  String get checkInternetAndRetry =>
      'कृपया अपना इंटरनेट कनेक्शन जांचें और पुनः प्रयास करें';
  @override
  String get checking => 'जांच हो रही है...';
  @override
  String get openSettings => 'सेटिंग्स खोलें';
  @override
  String get checkDeviceSettings =>
      'कृपया अपनी डिवाइस नेटवर्क सेटिंग्स जांचें';
  @override
  String get quickTips => 'त्वरित सुझाव';
  @override
  String get tipWifi => 'वाई-फाई या मोबाइल डेटा चालू करें';
  @override
  String get tipAirplane => 'जांचें कि क्या हवाई जहाज मोड बंद है';
  @override
  String get tipSignal => 'बेहतर सिग्नल वाले क्षेत्र में जाएं';
  @override
  String get slowNetwork => 'धीमा नेटवर्क';
  @override
  String get slowNetworkDesc =>
      'कमजोर कनेक्शन के कारण डेटा धीरे लोड हो रहा है';
}

class _HiValidationTranslations implements ValidationTranslations {
  const _HiValidationTranslations();

  @override
  String get nameTooShort => 'नाम कम से कम 2 अक्षरों का होना चाहिए';
  @override
  String get enterPhoneNumber => 'कृपया फ़ोन नंबर दर्ज करें';
  @override
  String get phoneMustBeTenDigits => 'फ़ोन नंबर ठीक 10 अंकों का होना चाहिए';
  @override
  String get phoneMustStartWith => 'फ़ोन नंबर 6, 7, 8 या 9 से शुरू होना चाहिए';
  @override
  String get enterValidPhone => 'कृपया एक वैध फ़ोन नंबर दर्ज करें';
  @override
  String get enterEmail => 'कृपया अपना ईमेल पता दर्ज करें';
  @override
  String get enterValidEmail => 'कृपया एक मान्य ईमेल पता दर्ज करें';
}

class _HiPdfTranslations implements PdfTranslations {
  const _HiPdfTranslations();

  @override
  String get baseAmount => 'मूल राशि:';
  @override
  String get tableDecoration => 'टेबल सजावट:';
  @override
  String get arriveOnTime => 'कृपया अपने आरक्षण के लिए समय पर पहुंचें';
  @override
  String get remainingAmountNote =>
      'शेष राशि का भुगतान रेस्टोरेंट में किया जाएगा';
  @override
  String get arriveEarly => '• कृपया 15 मिनट पहले पहुंचें';
  @override
  String get nonRefundable => '• अग्रिम राशि गैर-वापसी योग्य है';
  @override
  String get tableHeldNote => '• टेबल केवल 15 मिनट तक आरक्षित रखी जाएगी';
  @override
  String get changesContact => '• किसी भी बदलाव के लिए कॉल करें: +91-8768412832';
  @override
  String get reservationBillShareText => 'WhizEats Pro से आपका आरक्षण बिल';

  @override
  String get whatsAppKitchen => 'व्हाट्सएप किचन';
  @override
  String get whatsAppKitchenSubtitle =>
      'ऑर्डर अलर्ट संदेश भेजें (+91 87684 12832)';
  @override
  String get sharePdfDocument => 'पीडीएफ दस्तावेज़ साझा करें';
  @override
  String get sharePdfSubtitle =>
      'पीडीएफ फ़ाइल भेजने के लिए सिस्टम शेयर डायलॉग खोलें';
}

class _HiDrawerTranslations implements DrawerTranslations {
  const _HiDrawerTranslations();

  @override
  String get locations => 'स्थान (LOCATIONS)';
  @override
  String get quickActions => 'त्वरित कार्य (QUICK ACTIONS)';
  @override
  String get pendingPayments => 'लंबित भुगतान';
  @override
  String get pendingPaymentsSubtitle => 'अदत्त बिलों का भुगतान प्राप्त करें';
  @override
  String get reprint => 'पुनः प्रिंट करें';
  @override
  String get reprintSubtitle => 'पुराने बिल और KOT';
  @override
  String get account => 'खाता (ACCOUNT)';
  @override
  String get ordersManagement => 'ऑर्डर प्रबंधन';
  @override
  String get ordersManagementSubtitle => 'सभी ऑर्डर देखें और ट्रैक करें';
  @override
  String get readyToCollect => 'प्राप्ति के लिए तैयार';
  @override
  String get readyToCollectSubtitle => 'रसोई से तैयार ऑर्डर प्राप्त करें';
  @override
  String get kitchenMenu => 'किचन मेन्यू';
  @override
  String get language => 'भाषा';
  @override
  String get languageSubtitle => 'भाषा चुनें';
  @override
  String get selectLanguage => 'भाषा चुनें';
  @override
  String get chooseLanguage => 'अपनी पसंदीदा भाषा चुनें';
  @override
  String get english => 'English';
  @override
  String get hindi => 'हिन्दी (Hindi)';
  @override
  String get bengali => 'বাংলা (Bengali)';
  @override
  String get languageChanged => 'भाषा सफलतापूर्वक बदल दी गई है';
}

