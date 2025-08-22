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
    await Hive.openBox<TableModel>(_tablesBoxName);
    await Hive.openBox<OrderModel>(_ordersBoxName);
    await Hive.openBox<Map>(_syncBoxName);
    await Hive.openBox('pos'); // Box for storing auth token
  }

  // Get box instances
  static Box<TableModel> get tablesBox => Hive.box<TableModel>(_tablesBoxName);
  static Box<OrderModel> get ordersBox => Hive.box<OrderModel>(_ordersBoxName);
  static Box<Map> get syncBox => Hive.box<Map>(_syncBoxName);
  static Box get posBox => Hive.box('pos');

  // Table CRUD operations
  static Future<void> saveTable(TableModel table) async {
    table.lastUpdated = DateTime.now();
    table.synced = false;
    await tablesBox.put(table.id, table);
    await _addToSyncQueue('table_update', table.id);
  }

  static List<TableModel> getAllTables() {
    return tablesBox.values.toList();
  }

  // save auth token
  static Future<void> saveAuthToken(String token) async {
    await posBox.put('token', token);
  }

  static String getAuthToken() {
    return posBox.get('token', defaultValue: '');
  }

  //save auth data from api
  static Future<void> saveAuthData(data) async {
    await posBox.put('auth_data', data);
  }

  static AuthApiResModel? getAuthData() {
    return posBox.get('auth_data');
  }

  //deleting auth data on logout
  static Future<void> clearAuthData() async {
    await posBox.delete('token');
    await posBox.delete('auth_data');
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
    return ordersBox.values.toList();
  }

  static List<OrderModel> getOrdersForTable(String tableId) {
    return ordersBox.values.where((order) => order.tableId == tableId).toList();
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

  static List<Map> getUnsyncedItems() {
    return syncBox.values.where((item) => item['synced'] == false).toList();
  }

  static Future<void> markAsSynced(String key) async {
    final item = syncBox.get(key);
    if (item != null) {
      item['synced'] = true;
      await syncBox.put(key, item);
    }
  }
}
