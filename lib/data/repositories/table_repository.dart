import 'package:flutter/foundation.dart';

import '../models/order_channel_list_api_response_model.dart';
import '../models/restaurant_table.dart';
import '../remote/api_service.dart';

class TableRepository {
  TableRepository._();

  /// Fetch tables using OrderChannelListByType API - REAL API INTEGRATION
  static Future<List<RestaurantTable>> fetchTablesFromOrderChannelAPI({
    required String token,
    required int outletId,
    String orderChannelType = "Table",
  }) async {
    try {
      debugPrint('[TableRepo] Calling OrderChannelListByType API...');
      debugPrint('[TableRepo] Token: ${token.substring(0, 20)}...');
      debugPrint('[TableRepo] OutletId: $outletId');
      debugPrint('[TableRepo] OrderChannelType: $orderChannelType');

      final response = await ApiService.getOrderChannelListByType(
        token: token,
        outletId: outletId,
        orderChannelType: orderChannelType,
      );

      if (response != null && response.isSuccess == true) {
        debugPrint('[TableRepo] API Success: ${response.isSuccess}');
        debugPrint('[TableRepo] API Message: ${response.message}');
        debugPrint('[TableRepo] Raw API Response Data: ${response.data}');
        debugPrint('[TableRepo] Tables Count: ${response.data?.length ?? 0}');

        if (response.data != null && response.data!.isNotEmpty) {
          // Convert API data to RestaurantTable objects
          final apiTables = _convertApiDataToRestaurantTables(response.data!);
          debugPrint(
            '[TableRepo] Successfully converted ${apiTables.length} tables from API',
          );

          // Debug print each table
          for (final table in apiTables) {
            debugPrint(
              '[TableRepo] Table: ${table.name} - Status: ${table.status} - Orders: ${table.activeOrders.length}',
            );
            for (final order in table.activeOrders) {
              debugPrint(
                '[TableRepo] Order: ${order.generatedOrderNo} - Status: ${order.orderStatus} - Billed: ${order.isBilled}',
              );
            }
          }

          return apiTables;
        } else {
          debugPrint('[TableRepo] No tables found in API response');
          return [];
        }
      } else {
        debugPrint('[TableRepo] API Failed or returned unsuccessful response');
        debugPrint('[TableRepo] Response: $response');
        return [];
      }
    } catch (e) {
      debugPrint('[TableRepo] Error fetching tables: $e');
      if (kDebugMode) {
        debugPrint('[TableRepo] Stack trace: ${StackTrace.current}');
      }
      return [];
    }
  }

  /// Convert API data to RestaurantTable objects using YOUR real JSON structure
  static List<RestaurantTable> _convertApiDataToRestaurantTables(
    List<TableData> apiTables,
  ) {
    debugPrint('[TableRepo] Converting ${apiTables.length} API tables');
    debugPrint('[TableRepo] Raw API tables data: $apiTables');

    return apiTables
        .where((table) {
          final isTable = table.channelType?.toLowerCase() == 'table';
          debugPrint(
            '[TableRepo] Table ${table.name}: channelType=${table.channelType}, isTable=$isTable',
          );
          return isTable;
        })
        .map((table) {
          debugPrint('[TableRepo] Processing table: ${table.name}');
          debugPrint('[TableRepo] Table ID: ${table.orderChannelId}');
          debugPrint('[TableRepo] Table capacity: ${table.capacity}');
          debugPrint('[TableRepo] Raw orderList: ${table.orderList}');

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
                    debugPrint(
                      '[TableRepo] Creating ActiveOrder: ${order.generatedOrderNo}',
                    );
                    return ActiveOrder(
                      orderId: order.orderId!,
                      generatedOrderNo: order.generatedOrderNo ?? 'Unknown',
                      orderStatus: order.orderStatus ?? 'Active',
                      isBilled: order.isBilled ?? false,
                      // Guest counts were being parsed from the response and
                      // then dropped here, so the table card could never show
                      // who was seated. Built by hand rather than via
                      // ActiveOrder.fromNewApiOrderList, which is why adding
                      // fields to that factory had no effect.
                      totalAdult: order.totalAdult,
                      totalChild: order.totalChild,
                    );
                  })
                  .toList() ??
              [];

          debugPrint(
            '[TableRepo] Table ${table.name}: ${activeOrders.length} active orders',
          );

          // Determine enhanced table status based on order progression
          final TableStatus tableStatus;
          final kotGenerated = activeOrders.isNotEmpty;
          final billGenerated = activeOrders.any((order) => order.isBilled);
          final allBillsSettled =
              activeOrders.isNotEmpty &&
              activeOrders.every((order) => order.isBilled);

          if (activeOrders.isEmpty) {
            tableStatus = TableStatus.available;
          } else if (allBillsSettled) {
            // All bills are paid - table is settled and ready to be cleared
            tableStatus = TableStatus.billSettled;
          } else if (billGenerated) {
            // At least one bill generated but not all settled
            tableStatus = TableStatus.billGenerated;
          } else {
            // Orders exist but status depends on whether KOT was generated
            // Default to occupied - status will be updated via manual triggers
            tableStatus = TableStatus.occupied;
          }

          debugPrint(
            '[TableRepo] Table ${table.name}: status=$tableStatus, orders=${activeOrders.length}, billed=$billGenerated',
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
    debugPrint('[TableRepo] === DEBUG TABLE DATA ===');
    debugPrint('[TableRepo] Total tables: ${tables.length}');
    for (final table in tables) {
      debugPrint('[TableRepo] Table: ${table.name}');
      debugPrint('[TableRepo] ID: ${table.id}');
      debugPrint('[TableRepo] Capacity: ${table.capacity}');
      debugPrint('[TableRepo] Location: ${table.location}');
      debugPrint('[TableRepo] Status: ${table.status}');
      debugPrint('[TableRepo] KOT Generated: ${table.kotGenerated}');
      debugPrint('[TableRepo] Bill Generated: ${table.billGenerated}');
      debugPrint('[TableRepo] Active Orders (${table.activeOrders.length}):');
      for (final order in table.activeOrders) {
        debugPrint(
          '[TableRepo] - ${order.generatedOrderNo} (${order.orderStatus}) - Billed: ${order.isBilled}',
        );
      }
      debugPrint('[TableRepo] ---');
    }
    debugPrint('[TableRepo] === END DEBUG ===');
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
        case TableStatus.kotGenerated:
          stats['occupied'] =
              (stats['occupied'] ?? 0) +
              1; // Count as occupied for backward compatibility
          break;
        case TableStatus.billGenerated:
          stats['occupied'] =
              (stats['occupied'] ?? 0) +
              1; // Count as occupied for backward compatibility
          break;
        case TableStatus.billSettled:
          stats['occupied'] =
              (stats['occupied'] ?? 0) +
              1; // Count as occupied for backward compatibility
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

    debugPrint('[TableRepo] Table Statistics: $stats');
    return stats;
  }
}
