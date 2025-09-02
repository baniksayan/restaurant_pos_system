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
          final apiTables = _convertToRestaurantTables(apiResponse.data!);
          
          // Add static demo data for other locations
          final demoTables = _createStaticDemoTables();
          
          // Combine API tables with demo data
          final allTables = [...apiTables, ...demoTables];
          
          // Sort all tables properly
          allTables.sort((a, b) => _compareTableNames(a.name, b.name));
          
          return allTables;
        }
        return [];
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('TableRepository error: $e');
      }
      return [];
    }
  }

  /// Convert API table data to RestaurantTable objects (Main Hall only)
  static List<RestaurantTable> _convertToRestaurantTables(List apiTables) {
    final tables = apiTables.where((table) =>
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

    return tables;
  }

  /// Create static demo tables for other locations
  /// TODO: Replace with real API integration when backend provides location-specific tables
  static List<RestaurantTable> _createStaticDemoTables() {
    if (kDebugMode) {
      debugPrint('Adding static demo tables for VIP Section, Terrace, Garden Area, Balcony, Private Room');
    }
    
    return [
      // VIP Section - Static Demo Data
      RestaurantTable(
        id: 'static_vip_1',
        name: 'VIP 1',
        capacity: 8,
        location: 'VIP Section',
        status: TableStatus.available,
        kotGenerated: false,
        billGenerated: false,
      ),
      RestaurantTable(
        id: 'static_vip_2',
        name: 'VIP 2',
        capacity: 6,
        location: 'VIP Section',
        status: TableStatus.occupied,
        kotGenerated: true,
        billGenerated: false,
      ),
      RestaurantTable(
        id: 'static_vip_3',
        name: 'VIP Premium',
        capacity: 10,
        location: 'VIP Section',
        status: TableStatus.reserved,
        kotGenerated: false,
        billGenerated: false,
        reservationInfo: ReservationInfo(
          startTime: '8:00 PM',
          endTime: '10:00 PM',
          occasion: 'Anniversary celebration',
          guestCount: 6,
          reservationDate: DateTime.now(),
          totalAmount: 3500.0,
          customerName: 'Sharma Family',
          specialRequests: 'Cake arrangement needed',
        ),
      ),
      
      // Terrace - Static Demo Data  
      RestaurantTable(
        id: 'static_terrace_1',
        name: 'Terrace 1',
        capacity: 4,
        location: 'Terrace',
        status: TableStatus.available,
        kotGenerated: false,
        billGenerated: false,
      ),
      RestaurantTable(
        id: 'static_terrace_2',
        name: 'Terrace 2',
        capacity: 6,
        location: 'Terrace',
        status: TableStatus.occupied,
        kotGenerated: true,
        billGenerated: false,
      ),
      RestaurantTable(
        id: 'static_terrace_3',
        name: 'Terrace Corner',
        capacity: 4,
        location: 'Terrace',
        status: TableStatus.available,
        kotGenerated: false,
        billGenerated: true,
      ),
      
      // Garden Area - Static Demo Data
      RestaurantTable(
        id: 'static_garden_1',
        name: 'Garden 1',
        capacity: 6,
        location: 'Garden Area',
        status: TableStatus.available,
        kotGenerated: false,
        billGenerated: false,
      ),
      RestaurantTable(
        id: 'static_garden_2',
        name: 'Garden 2',
        capacity: 8,
        location: 'Garden Area',
        status: TableStatus.reserved,
        kotGenerated: false,
        billGenerated: false,
        reservationInfo: ReservationInfo(
          startTime: '6:00 PM',
          endTime: '11:00 PM',
          occasion: 'Outdoor wedding setup',
          guestCount: 15,
          reservationDate: DateTime.now(),
          totalAmount: 8500.0,
          customerName: 'Wedding Reception',
          specialRequests: 'Outdoor decorations required',
        ),
      ),
      
      // Balcony - Static Demo Data
      RestaurantTable(
        id: 'static_balcony_1',
        name: 'Balcony 1',
        capacity: 2,
        location: 'Balcony',
        status: TableStatus.available,
        kotGenerated: false,
        billGenerated: false,
      ),
      RestaurantTable(
        id: 'static_balcony_2',
        name: 'Balcony 2',
        capacity: 4,
        location: 'Balcony',
        status: TableStatus.occupied,
        kotGenerated: true,
        billGenerated: false,
      ),
      
      // Private Room - Static Demo Data
      RestaurantTable(
        id: 'static_private_1',
        name: 'Private Room A',
        capacity: 12,
        location: 'Private Room',
        status: TableStatus.available,
        kotGenerated: false,
        billGenerated: false,
      ),
      RestaurantTable(
        id: 'static_private_2',
        name: 'Private Room B',
        capacity: 16,
        location: 'Private Room',
        status: TableStatus.reserved,
        kotGenerated: false,
        billGenerated: false,
        reservationInfo: ReservationInfo(
          startTime: '2:00 PM',
          endTime: '5:00 PM',
          occasion: 'Business lunch with AV setup',
          guestCount: 12,
          reservationDate: DateTime.now(),
          totalAmount: 5500.0,
          customerName: 'Corporate Meeting',
          specialRequests: 'Projector and microphone needed',
        ),
      ),
    ];
  }

  /// Helper method for proper table name sorting (Table 1, Table 2, ... Table 10, Table 11)
  static int _compareTableNames(String name1, String name2) {
    // Extract numbers from table names for proper sorting
    final regex = RegExp(r'(\d+)');
    
    final match1 = regex.firstMatch(name1);
    final match2 = regex.firstMatch(name2);
    
    if (match1 != null && match2 != null) {
      // Both have numbers, compare numerically
      final num1 = int.tryParse(match1.group(1)!) ?? 0;
      final num2 = int.tryParse(match2.group(1)!) ?? 0;
      
      // First compare the prefix (before number)
      final prefix1 = name1.substring(0, match1.start);
      final prefix2 = name2.substring(0, match2.start);
      
      final prefixComparison = prefix1.compareTo(prefix2);
      if (prefixComparison != 0) return prefixComparison;
      
      // Then compare numbers
      return num1.compareTo(num2);
    }
    
    // Fallback to alphabetical comparison
    return name1.compareTo(name2);
  }

  /// Determine table location based on name (API tables will be Main Hall)
  static String _determineLocation(String tableName) {
    final name = tableName.toLowerCase();
    
    if (name.contains('vip') || name.contains('premium')) {
      return 'VIP Section';
    } else if (name.contains('terrace') || name.contains('outdoor')) {
      return 'Terrace';
    } else if (name.contains('garden') || name.contains('lawn')) {
      return 'Garden Area';
    } else if (name.contains('balcony')) {
      return 'Balcony';
    } else if (name.contains('private') || name.contains('room')) {
      return 'Private Room';
    } else {
      return 'Main Hall'; // All API tables default to Main Hall
    }
  }

  /// Determine table status based on order list
  static TableStatus _determineTableStatus(List? orderList) {
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
  static bool _hasActiveOrder(List? orderList) {
    if (orderList == null || orderList.isEmpty) return false;
    return orderList.any((order) =>
      order.orderId != null &&
      order.orderId != "00000000-0000-0000-0000-000000000000"
    );
  }

  /// Check if table has billed order
  static bool _hasBilledOrder(List? orderList) {
    if (orderList == null || orderList.isEmpty) return false;
    return orderList.any((order) => order.isBilled == true);
  }
}
