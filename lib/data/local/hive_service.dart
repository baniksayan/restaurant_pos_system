import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:restaurant_pos_system/core/constants/storage_keys.dart';
import 'package:restaurant_pos_system/data/models/auth_api_res_model.dart';
import 'models/table_model.dart';
import 'models/order_model.dart';

class HiveService {
  static const String _tablesBoxName = StorageKeys.tablesBox;
  static const String _ordersBoxName = StorageKeys.ordersBox;
  static const String _syncBoxName = StorageKeys.syncQueueBox;
  static const String _posBoxName = StorageKeys.posBox;
  static const String _authBoxName = StorageKeys.authBox;

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(TableModelAdapter());
    Hive.registerAdapter(OrderModelAdapter());
    Hive.registerAdapter(OrderItemModelAdapter());

    // Open boxes
    await Hive.openBox(_tablesBoxName);
    await Hive.openBox(_ordersBoxName);
    await Hive.openBox(_syncBoxName);
    await Hive.openBox(_posBoxName);
    await Hive.openBox(_authBoxName);
  }

  // Get box instances
  static Box get tablesBox => Hive.box(_tablesBoxName);
  static Box get ordersBox => Hive.box(_ordersBoxName);
  static Box get syncBox => Hive.box(_syncBoxName);
  static Box get posBox => Hive.box(_posBoxName);
  static Box get authBox => Hive.box(_authBoxName);

  // Table CRUD operations
  static Future<void> saveTable(TableModel table) async {
    table.lastUpdated = DateTime.now();
    table.synced = false;
    await tablesBox.put(table.id, table);
    await _addToSyncQueue('table_update', table.id);
  }

  static List<TableModel> getAllTables() {
    return tablesBox.values.cast<TableModel>().toList();
  }

  static TableModel? getTable(String id) {
    return tablesBox.get(id);
  }

  static Future<void> updateTableStatus(String tableId, String status) async {
    final table = tablesBox.get(tableId);
    if (table != null) {
      table.status = status;
      table.lastUpdated = DateTime.now();
      table.synced = false;
      await table.save();
      await _addToSyncQueue('table_status_update', tableId);
    }
  }

  // Order CRUD operations
  static Future<void> saveOrder(OrderModel order) async {
    order.synced = false;
    await ordersBox.put(order.id, order);
    await _addToSyncQueue('order_create', order.id);
  }

  static List<OrderModel> getAllOrders() {
    return ordersBox.values.cast<OrderModel>().toList();
  }

  static List<OrderModel> getOrdersForTable(String tableId) {
    return ordersBox.values
        .cast<OrderModel>()
        .where((order) => order.tableId == tableId)
        .toList();
  }

  // Auth Token Management
  static Future<void> saveAuthToken(String token) async {
    await posBox.put(StorageKeys.token, token);
  }

  static String getAuthToken() {
    return posBox.get(StorageKeys.token, defaultValue: '');
  }

  static Future<void> clearAuthToken() async {
    await posBox.delete(StorageKeys.token);
  }

  // Auth Data Management
  static Future<void> saveAuthData(dynamic data) async {
    // Store as a plain Map (JSON) to avoid requiring a Hive TypeAdapter
    if (data is AuthApiResModel) {
      await posBox.put(StorageKeys.authData, data.toJson());
    } else {
      // Fallback: store whatever was provided (defensive)
      await posBox.put(StorageKeys.authData, data);
    }
  }

  static AuthApiResModel? getAuthData() {
    final raw = posBox.get(StorageKeys.authData);
    if (raw == null) return null;
    // If the stored value is already the model (unlikely), return it.
    if (raw is AuthApiResModel) return raw;
    // If it's a Map (stored JSON), convert and deserialize.
    if (raw is Map) {
      try {
        final map = Map<String, dynamic>.from(raw);
        return AuthApiResModel.fromJson(map);
      } catch (e) {
        // If casting fails, return null
        return null;
      }
    }
    return null;
  }

  static Future<void> clearAuthData() async {
    await posBox.delete(StorageKeys.token);
    await posBox.delete(StorageKeys.authData);
  }

  // User ID Management (Updated methods using both posBox and authBox)
  static String? getUserId() {
    return posBox.get(StorageKeys.userId);
  }

  static void setUserId(String userId) {
    // Store in both boxes for consistenc
    posBox.put(StorageKeys.userId, userId);
  }

  // Waiter ID Management (Updated methods using both posBox and authBox)
  static String? getWaiterId() {
    return posBox.get(StorageKeys.waiterId); // Fallback to userId
  }

  static void setWaiterId(String waiterId) {
    // Store in both boxes for consistency
    posBox.put(StorageKeys.waiterId, waiterId);
  }

  // Outlet ID Management
  static int? getOutletId() {
    return posBox.get(StorageKeys.outletId);
  }

  static void setOutletId(int outletId) {
    posBox.put(StorageKeys.outletId, outletId);
  }

  // Company Site URL Management
  static String? getCompanySiteUrl() {
    return posBox.get(StorageKeys.companySiteUrl);
  }

  static void setCompanySiteUrl(String companySiteUrl) {
    posBox.put(StorageKeys.companySiteUrl, companySiteUrl);
  }

  static void clearCompanySiteUrl() {
    posBox.delete(StorageKeys.companySiteUrl);
  }

  // Chef Session Management
  static Future<void> setChefSession(bool isChef) async {
    await posBox.put(StorageKeys.isChefLoggedIn, isChef);
  }

  static bool isChefLoggedIn() {
    return posBox.get(StorageKeys.isChefLoggedIn, defaultValue: false) == true;
  }

  static Future<void> clearChefSession() async {
    await posBox.delete(StorageKeys.isChefLoggedIn);
  }

  // Tax Data Management
  static void saveTaxData(Map<String, dynamic> taxData) {
    posBox.put(StorageKeys.taxData, taxData);
    posBox.put(
      StorageKeys.taxDataTimestamp,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  static Map<String, dynamic>? getTaxData() {
    return posBox.get(StorageKeys.taxData);
  }

  static DateTime? getTaxDataTimestamp() {
    final timestamp = posBox.get(StorageKeys.taxDataTimestamp);
    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  static void clearTaxData() {
    posBox.delete(StorageKeys.taxData);
    posBox.delete(StorageKeys.taxDataTimestamp);
  }

  static bool isTaxDataExpired({int maxAgeHours = 24}) {
    final timestamp = getTaxDataTimestamp();
    if (timestamp == null) return true;

    final now = DateTime.now();
    final difference = now.difference(timestamp);
    return difference.inHours > maxAgeHours;
  }

  // Sync queue management
  static Future<void> _addToSyncQueue(String action, String entityId) async {
    final syncItem = {
      'action': action,
      'entityId': entityId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'synced': false,
    };
    await syncBox.put('${action}_$entityId', syncItem);
  }

  static List<Map<dynamic, dynamic>> getUnsyncedItems() {
    return syncBox.values
        .cast<Map<dynamic, dynamic>>()
        .where((item) => item['synced'] == false)
        .toList();
  }

  static Future<void> markAsSynced(String key) async {
    final item = syncBox.get(key);
    if (item != null) {
      item['synced'] = true;
      await syncBox.put(key, item);
    }
  }

  // Table-wise cart storage methods
  static Future<void> saveTableCart(
    String tableId,
    Map<String, dynamic> cartData,
  ) async {
    try {
      await posBox.put('cart_$tableId', cartData);
    } catch (e) {
      debugPrint('Error saving table cart: $e');
    }
  }

  static Map<String, dynamic>? getTableCart(String tableId) {
    try {
      final data = posBox.get('cart_$tableId');
      if (data != null && data is Map) {
        return Map<String, dynamic>.from(data);
      }
    } catch (e) {
      debugPrint('Error getting table cart: $e');
    }
    return null;
  }

  static Future<void> clearTableCart(String tableId) async {
    try {
      await posBox.delete('cart_$tableId');
    } catch (e) {
      debugPrint('Error clearing table cart: $e');
    }
  }

  // Table-wise bill ID storage methods (replacing bill amount storage)
  static Future<void> saveTableBillId(String tableId, String billId) async {
    try {
      await posBox.put('bill_id_$tableId', billId);
      debugPrint('Saved bill ID for table $tableId: $billId');
    } catch (e) {
      debugPrint('Error saving table bill ID: $e');
    }
  }

  static String? getTableBillId(String tableId) {
    try {
      final billId = posBox.get('bill_id_$tableId');
      if (billId != null && billId is String) {
        return billId;
      }
    } catch (e) {
      debugPrint('Error getting table bill ID: $e');
    }
    return null;
  }

  static Future<void> clearTableBillId(String tableId) async {
    try {
      await posBox.delete('bill_id_$tableId');
      debugPrint('Cleared bill ID for table $tableId');
    } catch (e) {
      debugPrint('Error clearing table bill ID: $e');
    }
  }

  // Legacy methods for backward compatibility (temporarily kept)
  @Deprecated('Use saveTableBillId instead')
  static Future<void> saveTableBillAmount(
    String tableId,
    double billAmount,
  ) async {
    // This method is deprecated - use saveTableBillId instead
    debugPrint(
      'Warning: saveTableBillAmount is deprecated. Use saveTableBillId instead.',
    );
  }

  @Deprecated('Use getBillDetailByBillId API instead')
  static double? getTableBillAmount(String tableId) {
    // This method is deprecated - use getBillDetailByBillId API instead
    debugPrint(
      'Warning: getTableBillAmount is deprecated. Use getBillDetailByBillId API instead.',
    );
    return null;
  }

  @Deprecated('Use clearTableBillId instead')
  static Future<void> clearTableBillAmount(String tableId) async {
    // This method is deprecated - use clearTableBillId instead
    debugPrint(
      'Warning: clearTableBillAmount is deprecated. Use clearTableBillId instead.',
    );
  }

  // Utility method to clear all data (useful for logout)
  static Future<void> clearAllData() async {
    await posBox.clear();
    await authBox.clear();
    await tablesBox.clear();
    await ordersBox.clear();
    await syncBox.clear();
  }
}
