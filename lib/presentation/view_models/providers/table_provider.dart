import 'package:flutter/material.dart';
import '../../../data/models/restaurant_table.dart';
import '../../../data/repositories/table_repository.dart';
import '../../../data/models/order_channel.dart';
import '../../../services/api_service.dart';

class TableProvider extends ChangeNotifier {
  List<RestaurantTable> _tables = [];
  List<OrderChannel> _orderChannels = [];
  bool _isLoading = false;
  bool _isApiLoading = false;
  String? _error;
  String? _tableApiError;
  String _selectedLocation = 'Main Hall'; // Default to Main Hall
  int _outletId = 55; // Default outlet ID, you can make this dynamic

  // Getters
  List<RestaurantTable> get tables => _tables;
  List<OrderChannel> get orderChannels => _orderChannels;
  bool get isLoading => _isLoading;
  bool get isApiLoading => _isApiLoading;
  String? get error => _error;
  String? get tableApiError => _tableApiError;
  String get selectedLocation => _selectedLocation;
  int get outletId => _outletId;

  // Set outlet ID (call this from your auth or settings)
  void setOutletId(int outletId) {
    _outletId = outletId;
    notifyListeners();
  }

  // Initialize tables with API call
  void initializeTables() {
    fetchTables();
  }

  // Fetch tables from API (new method)
  Future<void> fetchTables() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final tables = await TableRepository.fetchTablesFromApi(
        outletId: _outletId,
        orderChannelType: "", // Empty to get all tables
      );
      _tables = tables;
      if (_tables.isEmpty) {
        _error = 'No tables found for this outlet';
      }
    } catch (e) {
      _error = 'Failed to fetch tables: ${e.toString()}';
      _tables = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Legacy method for backward compatibility
  Future<void> fetchTablesByOutlet({
    required String token,
    required int outletId,
  }) async {
    _isApiLoading = true;
    _tableApiError = null;
    notifyListeners();

    try {
      final result = await ApiService.getTablesByOutlet(
        token: token,
        outletId: outletId,
      );
      if (result != null) {
        _orderChannels = result;
        // Also update the main tables list
        await fetchTables();
      } else {
        _tableApiError = 'Failed to fetch tables from API';
        _orderChannels = [];
      }
    } catch (e) {
      _tableApiError = 'Error: $e';
      _orderChannels = [];
    } finally {
      _isApiLoading = false;
      notifyListeners();
    }
  }

  // Refresh tables
  Future<void> refreshTables() async {
    await fetchTables();
  }

  // Get tables filtered by location and status with proper sorting
  List<RestaurantTable> getTablesForLocation(String locationName, [String? statusFilter]) {
    List<RestaurantTable> filteredTables = _tables;

    // Always filter by location (no "show all" option from location filter)
    filteredTables = filteredTables.where((table) => table.location == locationName).toList();

    // Filter by status if provided (this is where "All Tables" status filter works)
    if (statusFilter != null && statusFilter != 'all') {
      switch (statusFilter) {
        case 'available':
          filteredTables = filteredTables.where((table) => table.status == TableStatus.available).toList();
          break;
        case 'occupied':
          filteredTables = filteredTables.where((table) => table.status == TableStatus.occupied).toList();
          break;
        case 'reserved':
          filteredTables = filteredTables.where((table) => table.status == TableStatus.reserved).toList();
          break;
        case 'kot_generated':
          filteredTables = filteredTables.where((table) => table.kotGenerated == true).toList();
          break;
        case 'bill_generated':
          filteredTables = filteredTables.where((table) => table.billGenerated == true).toList();
          break;
      }
    }

    // Sort tables properly - handle numeric sorting for table names like "Table 1", "Table 10", etc.
    filteredTables.sort((a, b) {
      return _compareTableNames(a.name, b.name);
    });

    return filteredTables;
  }

  // Helper method for proper table name sorting
  int _compareTableNames(String name1, String name2) {
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

  // Update table status locally (for UI responsiveness)
  void updateTableStatus(String tableId, String newStatus) {
    try {
      final tableIndex = _tables.indexWhere((table) => table.id == tableId);
      if (tableIndex != -1) {
        final table = _tables[tableIndex];
        final updatedStatus = _getTableStatusFromString(newStatus);

        _tables[tableIndex] = RestaurantTable(
          id: table.id,
          name: table.name,
          capacity: table.capacity,
          location: table.location,
          status: updatedStatus,
          kotGenerated: table.kotGenerated,
          billGenerated: table.billGenerated,
          reservationInfo: table.reservationInfo,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to update table status: ${e.toString()}';
      notifyListeners();
    }
  }

  // Add reservation to table
  void addReservation(String tableId, ReservationInfo reservationInfo) {
    try {
      final tableIndex = _tables.indexWhere((table) => table.id == tableId);
      if (tableIndex != -1) {
        final table = _tables[tableIndex];
        _tables[tableIndex] = RestaurantTable(
          id: table.id,
          name: table.name,
          capacity: table.capacity,
          location: table.location,
          status: TableStatus.reserved,
          kotGenerated: table.kotGenerated,
          billGenerated: table.billGenerated,
          reservationInfo: reservationInfo,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to add reservation: ${e.toString()}';
      notifyListeners();
    }
  }

  // Set selected location filter
  void setSelectedLocation(String location) {
    _selectedLocation = location;
    notifyListeners();
  }

  // Clear general error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear API error
  void clearApiError() {
    _tableApiError = null;
    notifyListeners();
  }

  // Convert string to TableStatus enum
  TableStatus _getTableStatusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return TableStatus.available;
      case 'occupied':
        return TableStatus.occupied;
      case 'reserved':
        return TableStatus.reserved;
      default:
        return TableStatus.available;
    }
  }
}
