import 'app_translations.dart';

class EnTranslations implements AppTranslations {
  const EnTranslations();

  @override
  String get appName => 'WhizEats Pro';
  @override
  String get appTagline => 'Restaurant Management & POS';
  @override
  String get currencySymbol => '₹';
  @override
  String get brandName => 'WhizEats';
  @override
  String get brandSuffix => 'PRO';
  @override
  String get posTagline => 'Restaurant POS System';
  @override
  String get poweredBy => 'Powered by Wizard Communications Pvt. Ltd.';
  @override
  String get solutionTagline => 'Advanced Restaurant Management Solution';

  @override
  String get privacyPolicyUrl =>
      'https://stdpos.wizardcomm.net/WhizEatsPro/privacy-policy.html';
  @override
  String get termsAndConditionsUrl =>
      'https://stdpos.wizardcomm.net/WhizEatsPro/terms-and-conditions.html';

  @override
  String get ok => 'OK';
  @override
  String get cancel => 'Cancel';
  @override
  String get save => 'Save';
  @override
  String get delete => 'Delete';
  @override
  String get confirm => 'Confirm';
  @override
  String get retry => 'Retry';
  @override
  String get back => 'Back';
  @override
  String get close => 'Close';
  @override
  String get tryAgain => 'Try Again';
  @override
  String get gotIt => 'Got it';
  @override
  String get okGotIt => 'OK, Got It';
  @override
  String get done => 'Done';
  @override
  String get login => 'Login';
  @override
  String get logout => 'Logout';
  @override
  String get signOut => 'Sign Out';
  @override
  String get accessDenied => 'Access Denied';
  @override
  String get signingOut => 'Signing out...';
  @override
  String get loggingOut => 'Logging out...';
  @override
  String get signOutConfirmation => 'Sign Out Confirmation';
  @override
  String get signOutProConfirm =>
      'Are you sure you want to sign out of WhizEats Pro?';
  @override
  String get signOutKdsConfirm =>
      'Are you sure you want to sign out of WhizEats KDS?';
  @override
  String get signingOutOfKds => 'Signing out of KDS...';
  @override
  String get connect => 'Connect';
  @override
  String get clear => 'Clear';
  @override
  String get openNavigationDrawer => 'Open navigation drawer';

  @override
  String get unitPrice => 'Unit Price';
  @override
  String get quantity => 'Quantity';
  @override
  String get total => 'Total';
  @override
  String get subtotal => 'Subtotal';
  @override
  String get customerName => 'Customer Name';
  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get noInternetTitle => 'No Internet Connection';
  @override
  String get noInternetDesc => 'Please check your connection and try again.';

  @override
  AuthTranslations get auth => const _EnAuthTranslations();
  @override
  DashboardTranslations get dashboard => const _EnDashboardTranslations();
  @override
  MenuTranslations get menu => const _EnMenuTranslations();
  @override
  OrderTakingTranslations get orderTaking => const _EnOrderTakingTranslations();
  @override
  BillingTranslations get billing => const _EnBillingTranslations();
  @override
  PaymentTranslations get payment => const _EnPaymentTranslations();
  @override
  ChefTranslations get chef => const _EnChefTranslations();
  @override
  OrdersTranslations get orders => const _EnOrdersTranslations();
  @override
  ProfileTranslations get profile => const _EnProfileTranslations();
  @override
  ReservationsTranslations get reservations =>
      const _EnReservationsTranslations();
  @override
  ReportsTranslations get reports => const _EnReportsTranslations();
  @override
  NetworkTranslations get network => const _EnNetworkTranslations();
  @override
  ValidationTranslations get validation => const _EnValidationTranslations();
  @override
  PdfTranslations get pdf => const _EnPdfTranslations();
  @override
  DrawerTranslations get drawer => const _EnDrawerTranslations();
}

class _EnAuthTranslations implements AuthTranslations {
  const _EnAuthTranslations();

  @override
  String get logIn => 'Log In';
  @override
  String get userName => 'User Name';
  @override
  String get password => 'Password';
  @override
  String get enterUsername => 'Enter your username';
  @override
  String get enterPassword => 'Enter your password';
  @override
  String get forgotPassword => 'Forgot Password?';
  @override
  String get forgotPasswordSubtitle =>
      "Don't worry! Enter your email address and we'll send you a link to reset your password.";
  @override
  String get checkEmailForReset => 'Check your email for reset instructions';
  @override
  String get emailAddress => 'Email Address';
  @override
  String get enterEmailAddress => 'Enter your email address';
  @override
  String get sendResetEmail => 'Send Reset Email';
  @override
  String get emailSentTo => 'Email sent to:';
  @override
  String get backToLogin => 'Back to Login';
  @override
  String get resendEmail => 'Resend Email';
  @override
  String get rememberPassword => 'Remember your password? ';

  @override
  String get iAgreeToThe => 'I agree to the ';
  @override
  String get termsAndConditions => 'Terms & Conditions';
  @override
  String get and => ' and ';
  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get noServerResponse =>
      'No response from server. Please check your connection.';
  @override
  String get authCheckError => 'Error checking authentication state';
  @override
  String get invalidCredentials =>
      'Invalid username or password. Please verify credentials.';
  @override
  String get loginFailedCredentials =>
      'Login failed. Please check your credentials.';
  @override
  String get serverResponseError =>
      'Server response error. Please try again.';
  @override
  String get serverError =>
      'Server error. Please try again later or contact support.';
  @override
  String get noInternet =>
      'No internet connection. Please check your network.';
  @override
  String get connectionTimeout => 'Connection timeout. Please try again.';
  @override
  String get loginFailed => 'Login failed. Please try again.';

  @override
  String get accessDenied => 'Access Denied';
  @override
  String get accessDeniedSubtitle =>
      'Your account does not have permission to access WhizEats Pro.';
  @override
  String get accessDeniedMessage =>
      'Only Operator and Chef accounts are allowed to sign in. Please contact your administrator to get the correct access.';
  @override
  String get okGotIt => 'OK, Got It';
}

class _EnDashboardTranslations implements DashboardTranslations {
  const _EnDashboardTranslations();

  @override
  String get tables => 'Tables';
  @override
  String get menuLabel => 'Menu';
  @override
  String get cart => 'Cart';

  @override
  String get newOrder => 'New Order';

  @override
  String get errorLoadingTables => 'Error Loading Tables';
  @override
  String get clearError => 'Clear Error';
  @override
  String get noTablesFound => 'No Tables Found';
  @override
  String get changeLocation => 'Change Location';

  @override
  String get profileTitle => 'Profile';
  @override
  String get profileSubtitle => 'View user account details';
  @override
  String get settings => 'Settings';
  @override
  String get settingsSubtitle => 'App preferences & configuration';
  @override
  String get performance => 'Performance';
  @override
  String get performanceSubtitle => 'Reports & analytics overview';
  @override
  String get settingsComingSoon => 'Settings coming soon!';

  @override
  String get selectLocation => 'Select Location';
  @override
  String get selectTableForDineIn => 'Select a table for dine-in order';
  @override
  String get errorCreatingOrder => 'Error creating order';
  @override
  String get failedToAddOrderToServer => 'Failed to add order to server';

  @override
  String get customerNameLabel => 'Customer Name *';
  @override
  String get phoneNumberLabel => 'Phone Number *';
  @override
  String get enterCustomerName => 'Enter customer name';
  @override
  String get enterPhoneNumber => 'Enter phone number';
  @override
  String get enterTenDigitMobile => 'Enter 10-digit mobile number';
}

class _EnMenuTranslations implements MenuTranslations {
  const _EnMenuTranslations();

  @override
  String get searchDishes => 'Search dishes...';
  @override
  String get failedToLoadMenu => 'Failed to Load Menu';
  @override
  String get noItemsAvailable => 'No Items Available';
  @override
  String get loadMenu => 'Load Menu';
  @override
  String get kotSentToKitchen => 'KOT sent to kitchen printer!';
}

class _EnOrderTakingTranslations implements OrderTakingTranslations {
  const _EnOrderTakingTranslations();

  @override
  String get clearAll => 'Clear All';
  @override
  String get clearAllItems => 'Clear All Items';
  @override
  String get clearCartConfirm =>
      'Are you sure you want to remove all unsent items from your cart? This action cannot be undone.';
  @override
  String get specialInstructions => 'Special Instructions';
  @override
  String get kotGenerated => 'KOT Generated';
  @override
  String get cannotGenerateBill => 'Cannot Generate Bill';
  @override
  String get allItemsMustHaveKot =>
      'All items must have KOT generated before billing';
  @override
  String get noItemsInCart => 'No items in cart to navigate back';
  @override
  String get noNewItemsForKot => 'No new items to generate KOT for';
  @override
  String get kotCreationFailed => 'KOT Creation Failed';
  @override
  String get checkItemsInCart => '• Check if the items are still in your cart';
  @override
  String get contactSupport => '• Contact support if the issue persists';
  @override
  String get pleaseGenerateKotFirst => 'Please generate KOT first';
  @override
  String get yourCartIsEmpty => 'Your Cart is Empty';
  @override
  String get refresh => 'Refresh';
}

class _EnBillingTranslations implements BillingTranslations {
  const _EnBillingTranslations();

  @override
  String get loadingPaymentModes => 'Loading payment modes...';

  @override
  String gstWithRate(double percentage) {
    final rate =
        percentage == percentage.roundToDouble()
            ? percentage.toStringAsFixed(0)
            : percentage.toStringAsFixed(2);
    return 'Tax & Charges ($rate%)';
  }
}

class _EnPaymentTranslations implements PaymentTranslations {
  const _EnPaymentTranslations();

  @override
  String get paymentTitle => 'Payment';
  @override
  String get cash => 'Cash';
  @override
  String get cashSubtitle => 'Collect cash payment from customer';
  @override
  String get upi => 'UPI';
  @override
  String get upiSubtitle => 'Ask customer to scan QR & pay';
  @override
  String get noPaymentMethods => 'No Payment Methods';
  @override
  String get upiHint => 'e.g. restaurant@upi or 8768412832@ptsbi';
  @override
  String get saveUpiId => 'Save UPI ID';
  @override
  String get customerPhoneNumber => 'Customer Phone Number';

  @override
  String get cashReceived => 'Cash Received';
  @override
  String get cashReceivedHint => 'Amount handed by customer';
  @override
  String get changeToReturn => 'Change to Return';
  @override
  String get cashShortBy => 'Cash Short By';
  @override
  String get exactAmount => 'Exact';
  @override
  String get cashShortError =>
      'Cash received is less than the bill amount.';
}

class _EnChefTranslations implements ChefTranslations {
  const _EnChefTranslations();

  @override
  String get all => 'All';
  @override
  String get queue => 'Queue';
  @override
  String get preparing => 'Preparing';
  @override
  String get serve => 'Serve';

  @override
  String get noOrdersInView => 'No Orders in this View';
  @override
  String get filterByStatus => 'Filter by Status';

  @override
  String get chefProfile => 'Chef Profile';
  @override
  String get chefProfileSubtitle => 'Kitchen account details';

  @override
  String get enterRejectionReason => 'Enter rejection reason...';
}

class _EnOrdersTranslations implements OrdersTranslations {
  const _EnOrdersTranslations();

  @override
  String get tableTab => 'Table';
  @override
  String get phoneTab => 'Phone';
  @override
  String get takeawayTab => 'Takeaway';
  @override
  String get channelTab => 'Channel';

  @override
  String get searchOrders => 'Search orders by ID, customer, phone, etc...';

  @override
  String get printOrder => 'Print Order';
  @override
  String get shareDetails => 'Share Details';
  @override
  String get printComingSoon => 'Print functionality coming soon';
  @override
  String get shareComingSoon => 'Share functionality coming soon';
  @override
  String get billIdNotAvailable => 'Bill ID not available';
  @override
  String get billRegeneratedSuccessfully =>
      'Bill regenerated successfully!';
  @override
  String get remainingTime => 'Remaining Time';
}

class _EnProfileTranslations implements ProfileTranslations {
  const _EnProfileTranslations();

  @override
  String get editProfile => 'Edit Profile';
  @override
  String get fullName => 'Full Name';
  @override
  String get role => 'Role';
  @override
  String get phoneNumberOptional => 'Phone Number (Optional)';
  @override
  String get profileUpdatedSuccessfully => 'Profile updated successfully';

  @override
  String get logoutConfirm => 'Are you sure you want to logout?';
  @override
  String get loggingOut => 'Logging out...';
  @override
  String get signingOut => 'Signing out...';

  @override
  String get receiptPrinter => 'Receipt Printer';
  @override
  String get receiptPrinterSubtitle => 'Print customer bills and receipts';
  @override
  String get kitchenPrinter => 'Kitchen Printer';
  @override
  String get kitchenPrinterSubtitle => 'Print KOT (Kitchen Order Tickets)';
  @override
  String get testPrint => 'Test Print';
  @override
  String get saveSettings => 'Save Settings';
  @override
  String get connectPrinterFirst => 'Please connect a printer first';

  @override
  String get openingBalance => 'Opening Balance';
  @override
  String get additionalCashIn => 'Additional Cash In';
  @override
  String get cashInHint => 'Other receipts, loans, etc.';
  @override
  String get additionalCashOut => 'Additional Cash Out';
  @override
  String get cashOutHint => 'Withdrawals, petty cash, etc.';

  @override
  String get sales => 'Sales';
  @override
  String get ordersLabel => 'Orders';
  @override
  String get tablesLabel => 'Tables';
  @override
  String get reservationsLabel => 'Reservations';

  @override
  String get aboutTitle => 'About WhizEats Pro';
  @override
  String get aboutDescription =>
      'WhizEats Pro - Restaurant Management System';
  @override
  String get version => 'Version: 1.0.0';
  @override
  String get build => 'Build: 2026.08.13';
  @override
  String get copyright => '© 2026 WhizEats Pro. All rights reserved.';

  @override
  String get restaurantManagement => 'Restaurant Management';
  @override
  String get restaurantDetails => 'Restaurant Details';
  @override
  String get restaurantDetailsSubtitle => 'Edit restaurant information';
  @override
  String get staffManagement => 'Staff Management';
  @override
  String get staffManagementSubtitle => 'Manage staff and permissions';
  @override
  String get tableConfiguration => 'Table Configuration';
  @override
  String get tableConfigurationSubtitle => 'Manage tables and seating';
  @override
  String get menuManagement => 'Menu Management';
  @override
  String get menuManagementSubtitle => 'Update menu items and prices';

  @override
  String get businessAnalytics => 'Business Analytics';
  @override
  String get salesReports => 'Sales Reports';
  @override
  String get salesReportsSubtitle => 'Daily, weekly, monthly reports';
  @override
  String get performanceMetrics => 'Performance Metrics';
  @override
  String get performanceMetricsSubtitle => 'Popular items and peak hours';
  @override
  String get inventoryReports => 'Inventory Reports';
  @override
  String get inventoryReportsSubtitle => 'Stock levels and alerts';
  @override
  String get customerAnalytics => 'Customer Analytics';
  @override
  String get customerAnalyticsSubtitle => 'Customer behavior insights';

  @override
  String get financialManagement => 'Financial Management';
  @override
  String get dailyCashManagement => 'Daily Cash Management';
  @override
  String get dailyCashManagementSubtitle => 'Opening, closing balance';
  @override
  String get expenseTracking => 'Expense Tracking';
  @override
  String get expenseTrackingSubtitle => 'Record daily expenses';
  @override
  String get profitAndLoss => 'Profit & Loss';
  @override
  String get profitAndLossSubtitle => 'Financial performance';
  @override
  String get taxReports => 'Tax Reports';
  @override
  String get taxReportsSubtitle => 'GST and tax calculations';

  @override
  String get systemAndSettings => 'System & Settings';
  @override
  String get printerSettings => 'Printer Settings';
  @override
  String get printerSettingsSubtitle =>
      'Configure receipt and kitchen printers';
  @override
  String get paymentMethods => 'Payment Methods';
  @override
  String get paymentMethodsSubtitle => 'Enable payment options';
  @override
  String get taxConfiguration => 'Tax Configuration';
  @override
  String get taxConfigurationSubtitle => 'GST rates and service charges';
  @override
  String get dataBackup => 'Data Backup';
  @override
  String get dataBackupSubtitle => 'Backup and restore data';

  @override
  String get helpAndSupport => 'Help & Support';
  @override
  String get userManual => 'User Manual';
  @override
  String get userManualSubtitle => 'How to use the app';
  @override
  String get technicalSupport => 'Technical Support';
  @override
  String get technicalSupportSubtitle => 'Contact support team';
  @override
  String get appUpdates => 'App Updates';
  @override
  String get appUpdatesSubtitle => 'Check for updates';
  @override
  String get aboutApp => 'About App';
  @override
  String get aboutAppSubtitle => 'Version and app information';

  @override
  String get topPerformer => 'Top Performer';
  @override
  String get customerFavorite => 'Customer Favorite';

  @override
  String get language => 'Language';
  @override
  String get languageSubtitle => 'English / हिन्दी / বাংলা';
}

class _EnReservationsTranslations implements ReservationsTranslations {
  const _EnReservationsTranslations();

  @override
  String get customerNameRequired => 'Customer Name *';
  @override
  String get enterFullName => 'Enter full name';
  @override
  String get phoneNumberRequired => 'Phone Number *';
  @override
  String get enterTenDigitNumber => 'Enter 10-digit number';
  @override
  String get numberOfPersons => 'Number of Persons';
  @override
  String get enterNumberOfPersons => 'Enter number of persons';
  @override
  String get specialOccasion => 'Special Occasion';
  @override
  String get specialNotesOptional => 'Special Notes (Optional)';
  @override
  String get specialNotesHint => 'Any special requirements or notes...';
  @override
  String get from => 'From';
  @override
  String get to => 'To';
  @override
  String get enterAdvanceAmount => 'Enter advance amount';

  @override
  String get reservationRules => 'Reservation Rules';
  @override
  String get advanceBooking => 'Advance Booking';
  @override
  String get operatingHours => 'Operating Hours';
  @override
  String get durationLimits => 'Duration Limits';
  @override
  String get advancePayment => 'Advance Payment';

  @override
  String get selectReservationTime => 'Please select reservation time';
  @override
  String get tableAlreadyReserved =>
      'Table is already reserved for this time slot';
  @override
  String get failedToCreateReservation => 'Failed to create reservation';
  @override
  String get generatingPdfBill => 'Generating PDF bill...';
  @override
  String get shareBill => 'Share Bill';
  @override
  String get sharingBillToWhatsApp => 'Sharing bill to WhatsApp...';
  @override
  String get selectWhatsApp => 'Please select WhatsApp from the share options';

  @override
  String get decorationSubtitle => '₹400 - Balloons, flowers & table setup';
}

class _EnReportsTranslations implements ReportsTranslations {
  const _EnReportsTranslations();

  @override
  String get selectTimePeriod => 'Select Time Period';
  @override
  String get totalRevenue => 'Total Revenue';
  @override
  String get totalOrders => 'Total Orders';
  @override
  String get avgOrderValue => 'Avg Order Value';
  @override
  String get tableTurnoverRate => 'Table Turnover Rate';
  @override
  String get pdfLabel => 'PDF';
  @override
  String get csvLabel => 'CSV';
  @override
  String get generatingReport => 'Generating report...';
}

class _EnNetworkTranslations implements NetworkTranslations {
  const _EnNetworkTranslations();

  @override
  String get uhOh => 'Uh oh!';
  @override
  String get noDataOrWifi =>
      "Looks like you haven't turned on your mobile data or WiFi";
  @override
  String get checkInternetAndRetry =>
      'Please check your internet connection and try again';
  @override
  String get checking => 'Checking...';
  @override
  String get openSettings => 'Open Settings';
  @override
  String get checkDeviceSettings =>
      'Please check your device network settings';
  @override
  String get quickTips => 'Quick Tips';
  @override
  String get tipWifi => 'Turn on WiFi or Mobile Data';
  @override
  String get tipAirplane => 'Check if Airplane mode is off';
  @override
  String get tipSignal => 'Move to an area with better signal';
  @override
  String get slowNetwork => 'Slow Network';
  @override
  String get slowNetworkDesc =>
      'Data is loading slowly due to poor connection';
}

class _EnValidationTranslations implements ValidationTranslations {
  const _EnValidationTranslations();

  @override
  String get nameTooShort => 'Name must be at least 2 characters';
  @override
  String get enterPhoneNumber => 'Please enter phone number';
  @override
  String get phoneMustBeTenDigits => 'Phone number must be exactly 10 digits';
  @override
  String get phoneMustStartWith =>
      'Phone number must start with 6, 7, 8, or 9';
  @override
  String get enterValidPhone => 'Please enter a valid phone number';
  @override
  String get enterEmail => 'Please enter your email address';
  @override
  String get enterValidEmail => 'Please enter a valid email address';
}

class _EnPdfTranslations implements PdfTranslations {
  const _EnPdfTranslations();

  @override
  String get baseAmount => 'Base Amount:';
  @override
  String get tableDecoration => 'Table Decoration:';
  @override
  String get arriveOnTime => 'Please arrive on time for your reservation';
  @override
  String get remainingAmountNote =>
      'Remaining amount to be paid at the restaurant';
  @override
  String get arriveEarly => '• Please arrive 15 minutes early';
  @override
  String get nonRefundable => '• Advance amount is non-refundable';
  @override
  String get tableHeldNote => '• Table will be held for 15 minutes only';
  @override
  String get changesContact => '• For changes, call: +91-8768412832';
  @override
  String get reservationBillShareText =>
      'Your reservation bill from WhizEats Pro';

  @override
  String get whatsAppKitchen => 'WhatsApp Kitchen';
  @override
  String get whatsAppKitchenSubtitle =>
      'Send order alert text (+91 87684 12832)';
  @override
  String get sharePdfDocument => 'Share PDF Document';
  @override
  String get sharePdfSubtitle =>
      'Open system share dialog to send the PDF file';
}

class _EnDrawerTranslations implements DrawerTranslations {
  const _EnDrawerTranslations();

  @override
  String get locations => 'LOCATIONS';
  @override
  String get quickActions => 'QUICK ACTIONS';
  @override
  String get pendingPayments => 'Pending Payments';
  @override
  String get pendingPaymentsSubtitle => 'Collect on unpaid bills';
  @override
  String get reprint => 'Reprint';
  @override
  String get reprintSubtitle => 'Past bills and KOTs';
  @override
  String get account => 'ACCOUNT';
  @override
  String get ordersManagement => 'Orders Management';
  @override
  String get ordersManagementSubtitle => 'View & track all orders';
  @override
  String get readyToCollect => 'Ready to Collect';
  @override
  String get readyToCollectSubtitle => 'Collect prepared orders from kitchen';
  @override
  String get kitchenMenu => 'KITCHEN MENU';
  @override
  String get language => 'Language';
  @override
  String get languageSubtitle => 'Choose language';
  @override
  String get selectLanguage => 'Select Language';
  @override
  String get chooseLanguage => 'Choose your preferred language';
  @override
  String get english => 'English';
  @override
  String get hindi => 'हिन्दी (Hindi)';
  @override
  String get bengali => 'বাংলা (Bengali)';
  @override
  String get languageChanged => 'Language changed successfully';
}
