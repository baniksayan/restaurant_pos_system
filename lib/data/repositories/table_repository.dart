import 'package:flutter/foundation.dart';

import '../models/order_channel_list_api_response_model.dart';
import '../models/restaurant_table.dart';
import '../../services/api_service.dart';

class TableRepository {
  TableRepository._();

  /// Fetch tables using OrderChannelListByType API - REAL API INTEGRATION
  static Future<List<RestaurantTable>> fetchTablesFromOrderChannelAPI({
    required String token,
    required int outletId,
    String orderChannelType = "Table",
  }) async {
    try {
      print('[TableRepo] Calling OrderChannelListByType API...');
      print('[TableRepo] Token: ${token.substring(0, 20)}...');
      print('[TableRepo] OutletId: $outletId');
      print('[TableRepo] OrderChannelType: $orderChannelType');

      final response = await ApiService.getOrderChannelListByType(
        token: token,
        outletId: outletId,
        orderChannelType: orderChannelType,
      );

      if (response != null && response.isSuccess == true) {
        print('[TableRepo] API Success: ${response.isSuccess}');
        print('[TableRepo] API Message: ${response.message}');
        print('[TableRepo] Raw API Response Data: ${response.data}');
        print('[TableRepo] Tables Count: ${response.data?.length ?? 0}');

        if (response.data != null && response.data!.isNotEmpty) {
          // Convert API data to RestaurantTable objects
          final apiTables = _convertApiDataToRestaurantTables(response.data!);
          print(
            '[TableRepo] Successfully converted ${apiTables.length} tables from API',
          );

          // Debug print each table
          for (final table in apiTables) {
            print(
              '[TableRepo] Table: ${table.name} - Status: ${table.status} - Orders: ${table.activeOrders.length}',
            );
            for (final order in table.activeOrders) {
              print(
                '[TableRepo] Order: ${order.generatedOrderNo} - Status: ${order.orderStatus} - Billed: ${order.isBilled}',
              );
            }
          }

          return apiTables;
        } else {
          print('[TableRepo] No tables found in API response');
          return [];
        }
      } else {
        print('[TableRepo] API Failed or returned unsuccessful response');
        print('[TableRepo] Response: $response');
        return [];
      }
    } catch (e) {
      print('[TableRepo] Error fetching tables: $e');
      if (kDebugMode) {
        print('[TableRepo] Stack trace: ${StackTrace.current}');
      }
      return [];
    }
  }

  /// Convert API data to RestaurantTable objects using YOUR real JSON structure
  static List<RestaurantTable> _convertApiDataToRestaurantTables(
    List<TableData> apiTables,
  ) {
    print('[TableRepo] Converting ${apiTables.length} API tables');
    print('[TableRepo] Raw API tables data: $apiTables');

    return apiTables
        .where((table) {
          final isTable = table.channelType?.toLowerCase() == 'table';
          print(
            '[TableRepo] Table ${table.name}: channelType=${table.channelType}, isTable=$isTable',
          );
          return isTable;
        })
        .map((table) {
          print('[TableRepo] Processing table: ${table.name}');
          print('[TableRepo] Table ID: ${table.orderChannelId}');
          print('[TableRepo] Table capacity: ${table.capacity}');
          print('[TableRepo] Raw orderList: ${table.orderList}');

          // FIXED: Simplified filtering with proper boolean return
          final activeOrders =
              table.orderList
                  ?.where(
                    (order) =>
                        order.orderId != null &&
                        order.orderId!.isNotEmpty &&
                        order.orderId !=
                            "00000000-0000-0000-0000-000000000000" &&
                        order.orderStatus != 'Cancelled',
                  )
                  .map((order) {
                    print(
                      '[TableRepo] Creating ActiveOrder: ${order.generatedOrderNo}',
                    );
                    return ActiveOrder(
                      orderId: order.orderId!,
                      generatedOrderNo: order.generatedOrderNo ?? 'Unknown',
                      orderStatus: order.orderStatus ?? 'Active',
                      isBilled: order.isBilled ?? false,
                    );
                  })
                  .toList() ??
              [];

          print(
            '[TableRepo] Table ${table.name}: ${activeOrders.length} active orders',
          );

          // Determine table status
          final tableStatus =
              activeOrders.isEmpty
                  ? TableStatus.available
                  : TableStatus.occupied;
          final kotGenerated = activeOrders.isNotEmpty;
          final billGenerated = activeOrders.any((order) => order.isBilled);

          print(
            '[TableRepo] Table ${table.name}: status=$tableStatus, kotGenerated=$kotGenerated, billGenerated=$billGenerated',
          );

          return RestaurantTable(
            id: table.orderChannelId ?? '',
            name: table.name ?? 'Unknown Table',
            capacity: table.capacity ?? 0,
            location: 'Main Hall', // All API tables go to Main Hall
            status: tableStatus,
            kotGenerated: kotGenerated,
            billGenerated: billGenerated,
            activeOrders: activeOrders,
          );
        })
        .toList();
  }

  /// Debug method to verify data conversion
  static void debugPrintTableData(List<RestaurantTable> tables) {
    print('[TableRepo] === DEBUG TABLE DATA ===');
    print('[TableRepo] Total tables: ${tables.length}');
    for (final table in tables) {
      print('[TableRepo] Table: ${table.name}');
      print('[TableRepo] ID: ${table.id}');
      print('[TableRepo] Capacity: ${table.capacity}');
      print('[TableRepo] Location: ${table.location}');
      print('[TableRepo] Status: ${table.status}');
      print('[TableRepo] KOT Generated: ${table.kotGenerated}');
      print('[TableRepo] Bill Generated: ${table.billGenerated}');
      print('[TableRepo] Active Orders (${table.activeOrders.length}):');
      for (final order in table.activeOrders) {
        print(
          '[TableRepo] - ${order.generatedOrderNo} (${order.orderStatus}) - Billed: ${order.isBilled}',
        );
      }
      print('[TableRepo] ---');
    }
    print('[TableRepo] === END DEBUG ===');
  }

  /// Helper method to get table statistics
  static Map<String, int> getTableStatistics(List<RestaurantTable> tables) {
    final stats = {
      'total': tables.length,
      'available': 0,
      'occupied': 0,
      'reserved': 0,
      'outOfOrder': 0,
      'totalActiveOrders': 0,
      'billedOrders': 0,
    };

    for (final table in tables) {
      switch (table.status) {
        case TableStatus.available:
          stats['available'] = (stats['available'] ?? 0) + 1;
          break;
        case TableStatus.occupied:
          stats['occupied'] = (stats['occupied'] ?? 0) + 1;
          break;
        case TableStatus.reserved:
          stats['reserved'] = (stats['reserved'] ?? 0) + 1;
          break;
        case TableStatus.outOfOrder:
          stats['outOfOrder'] = (stats['outOfOrder'] ?? 0) + 1;
          break;
      }

      stats['totalActiveOrders'] =
          (stats['totalActiveOrders'] ?? 0) + table.activeOrders.length;
      stats['billedOrders'] =
          (stats['billedOrders'] ?? 0) +
          table.activeOrders.where((order) => order.isBilled).length;
    }

    print('[TableRepo] Table Statistics: $stats');
    return stats;
  }
}
