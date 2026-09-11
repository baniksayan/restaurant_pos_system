class AppStrings {
  AppStrings._();

  static const String appName = 'WhizEats Pro';
  static const String appTagline = 'Restaurant Management & POS';
  static const String currencySymbol = '₹';
  static const String brandName = 'WhizEats';
  static const String brandSuffix = 'PRO';
  static const String posTagline = 'Restaurant POS System';
  static const String poweredBy = 'Powered by Wizard Communications Pvt. Ltd.';
  static const String solutionTagline =
      'Advanced Restaurant Management Solution';

  // Legal & Policy URLs
  static const String privacyPolicyUrl =
      'https://stdpos.wizardcomm.net/WhizEatsPro/privacy-policy.html';
  static const String termsAndConditionsUrl =
      'https://stdpos.wizardcomm.net/WhizEatsPro/terms-and-conditions.html';

  // Common button labels
  static const String ok = 'OK';
  static const String cancel = 'Cancel';
  static const String save = 'Save';
  static const String delete = 'Delete';
  static const String confirm = 'Confirm';
  static const String retry = 'Retry';
  static const String back = 'Back';
  static const String close = 'Close';
  static const String tryAgain = 'Try Again';
  static const String gotIt = 'Got it';
  static const String done = 'Done';
  static const String login = 'Login';
  static const String logout = 'Logout';
  static const String signOut = 'Sign Out';
  static const String connect = 'Connect';

  // Common labels
  static const String unitPrice = 'Unit Price';
  static const String quantity = 'Quantity';
  static const String total = 'Total';
  static const String subtotal = 'Subtotal';
  static const String customerName = 'Customer Name';
  static const String phoneNumber = 'Phone Number';

  // Network messages
  static const String noInternetTitle = 'No Internet Connection';
  static const String noInternetDesc =
      'Please check your connection and try again.';

  // Feature namespaces
  static const auth = _AuthStrings();
  static const dashboard = _DashboardStrings();
  static const menu = _MenuStrings();
  static const orderTaking = _OrderTakingStrings();
  static const billing = _BillingStrings();
  static const payment = _PaymentStrings();
  static const chef = _ChefStrings();
  static const orders = _OrdersStrings();
  static const profile = _ProfileStrings();
  static const reservations = _ReservationsStrings();
  static const reports = _ReportsStrings();
  static const network = _NetworkStrings();
  static const validation = _ValidationStrings();
  static const pdf = _PdfStrings();
}

// --- Auth ---
class _AuthStrings {
  const _AuthStrings();

  final String logIn = 'Log In';
  final String userName = 'User Name';
  final String password = 'Password';
  final String enterUsername = 'Enter your username';
  final String enterPassword = 'Enter your password';
  final String forgotPassword = 'Forgot Password?';
  final String forgotPasswordSubtitle =
      "Don't worry! Enter your email address and we'll send you a link to reset your password.";
  final String checkEmailForReset = 'Check your email for reset instructions';
  final String emailAddress = 'Email Address';
  final String enterEmailAddress = 'Enter your email address';
  final String sendResetEmail = 'Send Reset Email';
  final String emailSentTo = 'Email sent to:';
  final String backToLogin = 'Back to Login';
  final String resendEmail = 'Resend Email';
  final String rememberPassword = 'Remember your password? ';

  // Consent & Legal
  final String iAgreeToThe = 'I agree to the ';
  final String termsAndConditions = 'Terms & Conditions';
  final String and = ' and ';
  final String privacyPolicy = 'Privacy Policy';

  // Error messages
  final String noServerResponse =
      'No response from server. Please check your connection.';
  final String authCheckError = 'Error checking authentication state';
  final String invalidCredentials = 'Invalid username or password';
  final String loginFailedCredentials =
      'Login failed. Please check your credentials.';
  final String serverResponseError = 'Server response error. Please try again.';
  final String serverError =
      'Server error. Please try again later or contact support.';
  final String noInternet =
      'No internet connection. Please check your network.';
  final String connectionTimeout = 'Connection timeout. Please try again.';
  final String loginFailed = 'Login failed. Please try again.';
}

// --- Dashboard ---
class _DashboardStrings {
  const _DashboardStrings();

  // Navigation
  final String tables = 'Tables';
  final String menuLabel = 'Menu';
  final String cart = 'Cart';

  // Header
  final String newOrder = 'New Order';

  // Table states
  final String errorLoadingTables = 'Error Loading Tables';
  final String clearError = 'Clear Error';
  final String noTablesFound = 'No Tables Found';
  final String changeLocation = 'Change Location';

  // Drawer
  final String profileTitle = 'Profile';
  final String profileSubtitle = 'View user account details';
  final String settings = 'Settings';
  final String settingsSubtitle = 'App preferences & configuration';
  final String performance = 'Performance';
  final String performanceSubtitle = 'Reports & analytics overview';
  final String settingsComingSoon = 'Settings coming soon!';

  // Dialogs
  final String selectLocation = 'Select Location';
  final String selectTableForDineIn = 'Select a table for dine-in order';
  final String errorCreatingOrder = 'Error creating order';
  final String failedToAddOrderToServer = 'Failed to add order to server';

  // Customer details
  final String customerNameLabel = 'Customer Name *';
  final String phoneNumberLabel = 'Phone Number *';
  final String enterCustomerName = 'Enter customer name';
  final String enterPhoneNumber = 'Enter phone number';
  final String enterTenDigitMobile = 'Enter 10-digit mobile number';
}

// --- Menu ---
class _MenuStrings {
  const _MenuStrings();

  final String searchDishes = 'Search dishes...';
  final String failedToLoadMenu = 'Failed to Load Menu';
  final String noItemsAvailable = 'No Items Available';
  final String loadMenu = 'Load Menu';
  final String kotSentToKitchen = 'KOT sent to kitchen printer!';
}

// --- Order Taking ---
class _OrderTakingStrings {
  const _OrderTakingStrings();

  final String clearAll = 'Clear All';
  final String clearAllItems = 'Clear All Items';
  final String clearCartConfirm =
      'Are you sure you want to remove all unsent items from your cart? This action cannot be undone.';
  final String specialInstructions = 'Special Instructions';
  final String kotGenerated = 'KOT Generated';
  final String cannotGenerateBill = 'Cannot Generate Bill';
  final String allItemsMustHaveKot =
      'All items must have KOT generated before billing';
  final String noItemsInCart = 'No items in cart to navigate back';
  final String noNewItemsForKot = 'No new items to generate KOT for';
  final String kotCreationFailed = 'KOT Creation Failed';
  final String checkItemsInCart = '• Check if the items are still in your cart';
  final String contactSupport = '• Contact support if the issue persists';
  final String pleaseGenerateKotFirst = 'Please generate KOT first';
  final String yourCartIsEmpty = 'Your Cart is Empty';
  final String refresh = 'Refresh';
}

// --- Billing ---
class _BillingStrings {
  const _BillingStrings();

  final String loadingPaymentModes = 'Loading payment modes...';

  /// GST label carrying the live rate, e.g. "GST (5%)" / "GST (18%)".
  /// Replaces the old fixed `gstFivePercent`, which claimed 5% while the
  /// bill was actually being computed at a different rate.
  String gstWithRate(double percentage) {
    final rate =
        percentage == percentage.roundToDouble()
            ? percentage.toStringAsFixed(0)
            : percentage.toStringAsFixed(2);
    return 'GST ($rate%)';
  }
}

// --- Payment ---
class _PaymentStrings {
  const _PaymentStrings();

  final String paymentTitle = 'Payment';
  final String cash = 'Cash';
  final String cashSubtitle = 'Collect cash payment from customer';
  final String upi = 'UPI';
  final String upiSubtitle = 'Ask customer to scan QR & pay';
  final String noPaymentMethods = 'No Payment Methods';
  final String upiHint = 'e.g. restaurant@upi or 8768412832@ptsbi';
  final String saveUpiId = 'Save UPI ID';
  final String customerPhoneNumber = 'Customer Phone Number';

  // Cash tendered / change
  final String cashReceived = 'Cash Received';
  final String cashReceivedHint = 'Amount handed by customer';
  final String changeToReturn = 'Change to Return';
  final String cashShortBy = 'Cash Short By';
  final String exactAmount = 'Exact';
  final String cashShortError =
      'Cash received is less than the bill amount.';
}

// --- Chef ---
class _ChefStrings {
  const _ChefStrings();

  // Tabs
  final String all = 'All';
  final String queue = 'Queue';
  final String preparing = 'Preparing';
  final String serve = 'Serve';

  // States
  final String noOrdersInView = 'No Orders in this View';
  final String filterByStatus = 'Filter by Status';

  // Drawer
  final String orderHistory = 'Order History (All)';
  final String orderHistorySubtitle = 'View past completed orders';
  final String chefProfile = 'Chef Profile';
  final String chefProfileSubtitle = 'Kitchen account details';

  // Dialogs
  final String enterRejectionReason = 'Enter rejection reason...';
}

// --- Orders ---
class _OrdersStrings {
  const _OrdersStrings();

  // Tabs
  final String tableTab = 'Table';
  final String phoneTab = 'Phone';
  final String takeawayTab = 'Takeaway';
  final String channelTab = 'Channel';

  // Search
  final String searchOrders = 'Search orders by ID, customer, phone, etc...';

  // Actions
  final String printOrder = 'Print Order';
  final String shareDetails = 'Share Details';
  final String printComingSoon = 'Print functionality coming soon';
  final String shareComingSoon = 'Share functionality coming soon';
  final String billIdNotAvailable = 'Bill ID not available';
  final String billRegeneratedSuccessfully = 'Bill regenerated successfully!';
  final String remainingTime = 'Remaining Time';
}

// --- Profile ---
class _ProfileStrings {
  const _ProfileStrings();

  // Edit profile
  final String editProfile = 'Edit Profile';
  final String fullName = 'Full Name';
  final String role = 'Role';
  final String phoneNumberOptional = 'Phone Number (Optional)';
  final String profileUpdatedSuccessfully = 'Profile updated successfully';

  // Logout
  final String logoutConfirm = 'Are you sure you want to logout?';
  final String loggingOut = 'Logging out...';
  final String signingOut = 'Signing out...';

  // Printer settings
  final String receiptPrinter = 'Receipt Printer';
  final String receiptPrinterSubtitle = 'Print customer bills and receipts';
  final String kitchenPrinter = 'Kitchen Printer';
  final String kitchenPrinterSubtitle = 'Print KOT (Kitchen Order Tickets)';
  final String testPrint = 'Test Print';
  final String saveSettings = 'Save Settings';
  final String connectPrinterFirst = 'Please connect a printer first';

  // Cash management
  final String openingBalance = 'Opening Balance';
  final String additionalCashIn = 'Additional Cash In';
  final String cashInHint = 'Other receipts, loans, etc.';
  final String additionalCashOut = 'Additional Cash Out';
  final String cashOutHint = 'Withdrawals, petty cash, etc.';

  // Quick stats
  final String sales = 'Sales';
  final String ordersLabel = 'Orders';
  final String tablesLabel = 'Tables';
  final String reservationsLabel = 'Reservations';

  // About
  final String aboutTitle = 'About WhizEats Pro';
  final String aboutDescription = 'WhizEats Pro - Restaurant Management System';
  final String version = 'Version: 1.0.0';
  final String build = 'Build: 2026.08.13';
  final String copyright = '© 2026 WhizEats Pro. All rights reserved.';

  // Profile menu sections
  final String restaurantManagement = 'Restaurant Management';
  final String restaurantDetails = 'Restaurant Details';
  final String restaurantDetailsSubtitle = 'Edit restaurant information';
  final String staffManagement = 'Staff Management';
  final String staffManagementSubtitle = 'Manage staff and permissions';
  final String tableConfiguration = 'Table Configuration';
  final String tableConfigurationSubtitle = 'Manage tables and seating';
  final String menuManagement = 'Menu Management';
  final String menuManagementSubtitle = 'Update menu items and prices';

  final String businessAnalytics = 'Business Analytics';
  final String salesReports = 'Sales Reports';
  final String salesReportsSubtitle = 'Daily, weekly, monthly reports';
  final String performanceMetrics = 'Performance Metrics';
  final String performanceMetricsSubtitle = 'Popular items and peak hours';
  final String inventoryReports = 'Inventory Reports';
  final String inventoryReportsSubtitle = 'Stock levels and alerts';
  final String customerAnalytics = 'Customer Analytics';
  final String customerAnalyticsSubtitle = 'Customer behavior insights';

  final String financialManagement = 'Financial Management';
  final String dailyCashManagement = 'Daily Cash Management';
  final String dailyCashManagementSubtitle = 'Opening, closing balance';
  final String expenseTracking = 'Expense Tracking';
  final String expenseTrackingSubtitle = 'Record daily expenses';
  final String profitAndLoss = 'Profit & Loss';
  final String profitAndLossSubtitle = 'Financial performance';
  final String taxReports = 'Tax Reports';
  final String taxReportsSubtitle = 'GST and tax calculations';

  final String systemAndSettings = 'System & Settings';
  final String printerSettings = 'Printer Settings';
  final String printerSettingsSubtitle =
      'Configure receipt and kitchen printers';
  final String paymentMethods = 'Payment Methods';
  final String paymentMethodsSubtitle = 'Enable payment options';
  final String taxConfiguration = 'Tax Configuration';
  final String taxConfigurationSubtitle = 'GST rates and service charges';
  final String dataBackup = 'Data Backup';
  final String dataBackupSubtitle = 'Backup and restore data';

  final String helpAndSupport = 'Help & Support';
  final String userManual = 'User Manual';
  final String userManualSubtitle = 'How to use the app';
  final String technicalSupport = 'Technical Support';
  final String technicalSupportSubtitle = 'Contact support team';
  final String appUpdates = 'App Updates';
  final String appUpdatesSubtitle = 'Check for updates';
  final String aboutApp = 'About App';
  final String aboutAppSubtitle = 'Version and app information';

  // Achievements
  final String topPerformer = 'Top Performer';
  final String customerFavorite = 'Customer Favorite';
}

// --- Reservations ---
class _ReservationsStrings {
  const _ReservationsStrings();

  // Form fields
  final String customerNameRequired = 'Customer Name *';
  final String enterFullName = 'Enter full name';
  final String phoneNumberRequired = 'Phone Number *';
  final String enterTenDigitNumber = 'Enter 10-digit number';
  final String numberOfPersons = 'Number of Persons';
  final String enterNumberOfPersons = 'Enter number of persons';
  final String specialOccasion = 'Special Occasion';
  final String specialNotesOptional = 'Special Notes (Optional)';
  final String specialNotesHint = 'Any special requirements or notes...';
  final String from = 'From';
  final String to = 'To';
  final String enterAdvanceAmount = 'Enter advance amount';

  // Rules
  final String reservationRules = 'Reservation Rules';
  final String advanceBooking = 'Advance Booking';
  final String operatingHours = 'Operating Hours';
  final String durationLimits = 'Duration Limits';
  final String advancePayment = 'Advance Payment';

  // Messages
  final String selectReservationTime = 'Please select reservation time';
  final String tableAlreadyReserved =
      'Table is already reserved for this time slot';
  final String failedToCreateReservation = 'Failed to create reservation';
  final String generatingPdfBill = 'Generating PDF bill...';
  final String shareBill = 'Share Bill';
  final String sharingBillToWhatsApp = 'Sharing bill to WhatsApp...';
  final String selectWhatsApp = 'Please select WhatsApp from the share options';

  // Decoration option
  final String decorationSubtitle = '₹400 - Balloons, flowers & table setup';
}

// --- Reports ---
class _ReportsStrings {
  const _ReportsStrings();

  final String selectTimePeriod = 'Select Time Period';
  final String totalRevenue = 'Total Revenue';
  final String totalOrders = 'Total Orders';
  final String avgOrderValue = 'Avg Order Value';
  final String tableTurnoverRate = 'Table Turnover Rate';
  final String pdfLabel = 'PDF';
  final String csvLabel = 'CSV';
  final String generatingReport = 'Generating report...';
}

// --- Network ---
class _NetworkStrings {
  const _NetworkStrings();

  final String uhOh = 'Uh oh!';
  final String noDataOrWifi =
      "Looks like you haven't turned on your mobile data or WiFi";
  final String checkInternetAndRetry =
      'Please check your internet connection and try again';
  final String checking = 'Checking...';
  final String openSettings = 'Open Settings';
  final String checkDeviceSettings =
      'Please check your device network settings';
  final String quickTips = 'Quick Tips';
  final String tipWifi = 'Turn on WiFi or Mobile Data';
  final String tipAirplane = 'Check if Airplane mode is off';
  final String tipSignal = 'Move to an area with better signal';
  final String slowNetwork = 'Slow Network';
  final String slowNetworkDesc =
      'Data is loading slowly due to poor connection';
}

// --- Validation ---
class _ValidationStrings {
  const _ValidationStrings();

  final String nameTooShort = 'Name must be at least 2 characters';
  final String enterPhoneNumber = 'Please enter phone number';
  final String phoneMustBeTenDigits = 'Phone number must be exactly 10 digits';
  final String phoneMustStartWith =
      'Phone number must start with 6, 7, 8, or 9';
  final String enterValidPhone = 'Please enter a valid phone number';
  final String enterEmail = 'Please enter your email address';
  final String enterValidEmail = 'Please enter a valid email address';
}

// --- PDF ---
class _PdfStrings {
  const _PdfStrings();

  // Reservation bill
  final String baseAmount = 'Base Amount:';
  final String tableDecoration = 'Table Decoration:';
  final String arriveOnTime = 'Please arrive on time for your reservation';
  final String remainingAmountNote =
      'Remaining amount to be paid at the restaurant';
  final String arriveEarly = '• Please arrive 15 minutes early';
  final String nonRefundable = '• Advance amount is non-refundable';
  final String tableHeldNote = '• Table will be held for 15 minutes only';
  final String changesContact = '• For changes, call: +91-8768412832';
  final String reservationBillShareText =
      'Your reservation bill from WhizEats Pro';

  // Share options
  final String whatsAppKitchen = 'WhatsApp Kitchen';
  final String whatsAppKitchenSubtitle =
      'Send order alert text (+91 87684 12832)';
  final String sharePdfDocument = 'Share PDF Document';
  final String sharePdfSubtitle =
      'Open system share dialog to send the PDF file';
}
