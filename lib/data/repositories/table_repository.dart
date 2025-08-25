import 'package:flutter/foundation.dart';
import '../models/tables_api_response_model.dart';
import '../models/restaurant_table.dart';
import '../../services/api_service.dart';

class TableRepository {
  TableRepository._();

  /// Fetch tables from API and convert to RestaurantTable objects
  static Future<List<RestaurantTable>> fetchTablesFromApi({
    required int outletId,
    String orderChannelType = "",
  }) async {
    try {
      final response = await ApiService.getTablesByOutletNew(
        outletId: outletId,
        orderChannelType: orderChannelType,
      );

      if (response != null && response['isSuccess'] == true) {
        final apiResponse = TablesApiResponseModel.fromJson(response);
        
        if (apiResponse.data != null) {
          return _convertToRestaurantTables(apiResponse.data!);
        }
      }
      
      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('TableRepository error: $e');
      }
      return [];
    }
  }

  /// Convert API table data to RestaurantTable objects
  static List<RestaurantTable> _convertToRestaurantTables(List<TableData> apiTables) {
    return apiTables.where((table) => 
      table.channelType?.toLowerCase() == 'table'
    ).map((table) {
      return RestaurantTable(
        id: table.orderChannelId ?? '',
        name: table.name ?? 'Unknown Table',
        capacity: table.capacity ?? 0,
        location: _determineLocation(table.name ?? ''),
        status: _determineTableStatus(table.orderList),
        kotGenerated: _hasActiveOrder(table.orderList),
        billGenerated: _hasBilledOrder(table.orderList),
      );
    }).toList();
  }

  /// Determine table location based on name
  static String _determineLocation(String tableName) {
    final name = tableName.toLowerCase();
    if (name.contains('vip')) return 'VIP Section';
    if (name.contains('terrace')) return 'Terrace';
    if (name.contains('garden')) return 'Garden Area';
    if (name.contains('private')) return 'Private Room';
    if (name.contains('balcony')) return 'Balcony';
    return 'Main Hall';
  }

  /// Determine table status based on order list
  static TableStatus _determineTableStatus(List<OrderList>? orderList) {
    if (orderList == null || orderList.isEmpty) {
      return TableStatus.available;
    }

    final hasActiveOrder = orderList.any((order) => 
      order.orderId != null && 
      order.orderId != "00000000-0000-0000-0000-000000000000" &&
      order.isBilled == false
    );

    return hasActiveOrder ? TableStatus.occupied : TableStatus.available;
  }

  /// Check if table has active order (KOT generated)
  static bool _hasActiveOrder(List<OrderList>? orderList) {
    if (orderList == null || orderList.isEmpty) return false;
    
    return orderList.any((order) => 
      order.orderId != null && 
      order.orderId != "00000000-0000-0000-0000-000000000000"
    );
  }

  /// Check if table has billed order
  static bool _hasBilledOrder(List<OrderList>? orderList) {
    if (orderList == null || orderList.isEmpty) return false;
    
    return orderList.any((order) => order.isBilled == true);
  }
}
