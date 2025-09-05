import 'package:hive_flutter/hive_flutter.dart';
import 'package:restaurant_pos_system/data/models/auth_api_res_model.dart';
import 'models/table_model.dart';
import 'models/order_model.dart';

class HiveService {
  static const String _tablesBoxName = 'tables';
  static const String _ordersBoxName = 'orders';
  static const String _syncBoxName = 'sync_queue';
  static const String _posBoxName = 'pos';
  static const String _authBoxName = 'auth';

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
    await posBox.put('token', token);
  }

  static String getAuthToken() {
    return posBox.get('token', defaultValue: '');
  }

  static Future<void> clearAuthToken() async {
    await posBox.delete('token');
  }

  // Auth Data Management
  static Future<void> saveAuthData(dynamic data) async {
    // Store as a plain Map (JSON) to avoid requiring a Hive TypeAdapter
    if (data is AuthApiResModel) {
      await posBox.put('auth_data', data.toJson());
    } else {
      // Fallback: store whatever was provided (defensive)
      await posBox.put('auth_data', data);
    }
  }

  static AuthApiResModel? getAuthData() {
    final raw = posBox.get('auth_data');
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
    await posBox.delete('token');
    await posBox.delete('auth_data');
  }

  // User ID Management (Updated methods using both posBox and authBox)
  static String? getUserId() {
    try {
      final box = Hive.box('auth');
      return box.get('userId') ?? box.get('user_id');
    } catch (e) {
      print('[HiveService] Error getting userId: $e');
      return null;
    }
  }

  static void setUserId(String userId) {
    // Store in both boxes for consistency
    posBox.put('userId', userId);
    authBox.put('userId', userId);
  }

  // Waiter ID Management (Updated methods using both posBox and authBox)
  static String? getWaiterId() {
    try {
      final box = Hive.box('auth');
      // Try multiple possible keys
      return box.get('waiterId') ??
          box.get('waiter_id') ??
          box.get('staffId') ??
          box.get('userId'); // Use userId as fallback
    } catch (e) {
      print('[HiveService] Error getting waiterId: $e');
      return getUserId(); // Fallback to userId
    }
  }

  static void setWaiterId(String waiterId) {
    // Store in both boxes for consistency
    posBox.put('waiterId', waiterId);
    authBox.put('waiterId', waiterId);
  }

  // Outlet ID Management
  static int? getOutletId() {
    return posBox.get('outletId');
  }

  static void setOutletId(int outletId) {
    posBox.put('outletId', outletId);
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

  // Utility method to clear all data (useful for logout)
  static Future<void> clearAllData() async {
    await posBox.clear();
    await authBox.clear();
    await tablesBox.clear();
    await ordersBox.clear();
    await syncBox.clear();
  }
}
