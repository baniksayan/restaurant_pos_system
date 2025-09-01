import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/local/hive_service.dart';
import '../core/utils/connectivity_helper.dart';

class SyncService {
  static const String baseUrl = 'https://your-api-server.com/api';
  
  static Future<bool> syncAllData() async {
    if (!await ConnectivityHelper.hasInternetConnection()) {
      print('No internet connection. Sync postponed.');
      return false;
    }

    try {
      // Get all unsynced items
      final unsyncedItems = HiveService.getUnsyncedItems();
      
      for (final item in unsyncedItems) {
        await _syncItem(item);
      }

      // Sync tables
      await _syncTables();
      
      // Sync orders
      await _syncOrders();
      
      print('All data synced successfully');
      return true;
      
    } catch (e) {
      print('Sync failed: ${e.toString()}');
      return false;
    }
  }

  static Future<void> _syncTables() async {
    final tables = HiveService.getAllTables();
    final unsyncedTables = tables.where((t) => !t.synced).toList();
    
    for (final table in unsyncedTables) {
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/tables'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'id': table.id,
            'name': table.name,
            'capacity': table.capacity,
            'status': table.status,
            'currentOrderId': table.currentOrderId,
            'kotGenerated': table.kotGenerated,
            'billGenerated': table.billGenerated,
            'lastUpdated': table.lastUpdated.toIso8601String(),
          }),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          table.synced = true;
          await table.save();
          print('Table ${table.name} synced');
        }
      } catch (e) {
        print('Failed to sync table ${table.name}: $e');
      }
    }
  }

  static Future<void> _syncOrders() async {
    final orders = HiveService.getAllOrders();
    final unsyncedOrders = orders.where((o) => !o.synced).toList();
    
    for (final order in unsyncedOrders) {
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/orders'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'id': order.id,
            'tableId': order.tableId,
            'items': order.items.map((item) => {
              'menuItemId': item.menuItemId,
              'name': item.name,
              'price': item.price,
              'quantity': item.quantity,
              'notes': item.notes,
            }).toList(),
            'createdAt': order.createdAt.toIso8601String(),
            'status': order.status,
            'totalAmount': order.totalAmount,
            'waiterId': order.waiterId,
          }),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          order.synced = true;
          await order.save();
          print('Order ${order.id} synced');
        }
      } catch (e) {
        print('Failed to sync order ${order.id}: $e');
      }
    }
  }

  static Future<void> _syncItem(Map item) async {
    // Handle individual sync queue items
    try {
      final action = item['action'];
      // final entityId = item['entityId'];
      
      // Process based on action type
      switch (action) {
        case 'table_update':
        case 'table_status_update':
          // Table already handled in _syncTables
          break;
        case 'order_create':
          // Order already handled in _syncOrders
          break;
      }
      
    } catch (e) {
      print('Failed to sync item: $e');
    }
  }

  // Schedule end-of-day sync
  static Future<void> scheduleEndOfDaySync() async {
    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59); // 11:59 PM
    
    if (now.isAfter(endOfDay)) {
      // If it's past end of day, schedule for next day
      final tomorrow = endOfDay.add(const Duration(days: 1));
      print('Sync scheduled for: $tomorrow');
    } else {
      print('Sync scheduled for: $endOfDay');
    }
    
    // In a real app, you'd use a background task scheduler
    // For now, we'll just call sync immediately if needed
    await syncAllData();
  }
}
