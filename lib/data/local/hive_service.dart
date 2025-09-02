import 'package:hive_flutter/hive_flutter.dart';
import 'package:restaurant_pos_system/data/models/auth_api_res_model.dart';
import 'models/table_model.dart';
import 'models/order_model.dart';

class HiveService {
  static const String _tablesBoxName = 'tables';
  static const String _ordersBoxName = 'orders';
  static const String _syncBoxName = 'sync_queue';

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
    await Hive.openBox('pos'); // Box for storing auth token
  }

  // Get box instances
  static Box get tablesBox => Hive.box(_tablesBoxName);
  static Box get ordersBox => Hive.box(_ordersBoxName);
  static Box get syncBox => Hive.box(_syncBoxName);
  static Box get posBox => Hive.box('pos');

  // Table CRUD operations
  static Future<void> saveTable(TableModel table) async {
    table.lastUpdated = DateTime.now();
    table.synced = false;
    await tablesBox.put(table.id, table);
    await _addToSyncQueue('table_update', table.id);
  }

  // FIX: Add cast to return correct type
  static List<TableModel> getAllTables() {
    return tablesBox.values.cast<TableModel>().toList();
  }

  // Save auth token
  static Future<void> saveAuthToken(String token) async {
    await posBox.put('token', token);
  }

  static String getAuthToken() {
    return posBox.get('token', defaultValue: '');
  }

  // Save auth data from api
  static Future<void> saveAuthData(data) async {
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

  // Deleting auth data on logout
  static Future<void> clearAuthData() async {
    await posBox.delete('token');
    await posBox.delete('auth_data');
  }

  // ADD THIS NEW METHOD:
  static Future<void> clearAuthToken() async {
    await posBox.delete('token');
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

  // FIX: Add cast to return correct type
  static List<OrderModel> getAllOrders() {
    return ordersBox.values.cast<OrderModel>().toList();
  }

  // FIX: Add cast to return correct type
  static List<OrderModel> getOrdersForTable(String tableId) {
    return ordersBox.values
        .cast<OrderModel>()
        .where((order) => order.tableId == tableId)
        .toList();
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

  static List getUnsyncedItems() {
    return syncBox.values.where((item) => item['synced'] == false).toList();
  }

  static Future<void> markAsSynced(String key) async {
    final item = syncBox.get(key);
    if (item != null) {
      item['synced'] = true;
      await syncBox.put(key, item);
    }
  }

  // Adding these methods to our HiveService class
  static String? getWaiterId() => posBox.get('waiterId');
  static int? getOutletId() => posBox.get('outletId');
  static String? getUserId() => posBox.get('userId');

  // Methods to set these values
  static void setWaiterId(String waiterId) => posBox.put('waiterId', waiterId);
  static void setUserId(String userId) => posBox.put('userId', userId);
}
