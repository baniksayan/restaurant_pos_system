import 'package:flutter/material.dart';
import '../../../data/models/restaurant_table.dart';
import '../../../data/repositories/table_repository.dart';
import '../../../data/local/hive_service.dart';
import '../../../data/models/order_channel.dart';
import '../../../services/api_service.dart';

class TableProvider extends ChangeNotifier {
  List<RestaurantTable> _tables = [];
  List<OrderChannel> _orderChannels = [];
  bool _isLoading = false;
  bool _isApiLoading = false;
  String? _error;
  String? _tableApiError;
  String _selectedLocation = 'All';
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

  // Get tables filtered by location
  List<RestaurantTable> getTablesForLocation(String locationName) {
    if (locationName == 'All') {
      return _tables;
    }
    return _tables.where((table) => table.location == locationName).toList();
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
