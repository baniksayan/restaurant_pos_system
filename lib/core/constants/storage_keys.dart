class StorageKeys {
  StorageKeys._();

  // Hive Box Names
  static const String tablesBox = 'tables';
  static const String ordersBox = 'orders';
  static const String syncQueueBox = 'sync_queue';
  static const String posBox = 'pos';
  static const String authBox = 'auth';

  // Storage Item Keys
  static const String token = 'token';
  static const String authData = 'auth_data';
  static const String userId = 'userId';
  static const String waiterId = 'waiterId';
  static const String outletId = 'outletId';
  static const String companySiteUrl = 'companySiteUrl';
  static const String isChefLoggedIn = 'is_chef_logged_in';
  static const String taxData = 'taxData';
  static const String taxDataTimestamp = 'taxDataTimestamp';
  static const String hasCheckedInitialPermissions =
      'has_checked_initial_permissions';
}
