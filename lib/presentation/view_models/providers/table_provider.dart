// lib/presentation/view_models/providers/table_provider.dart
import 'package:flutter/material.dart';
import '../../../data/models/restaurant_table.dart';
import '../../../services/api_service.dart';
import '../../../data/models/order_channel.dart';

class TableProvider extends ChangeNotifier {
  List<RestaurantTable> _tables = [];
  List<OrderChannel> _orderChannels = [];
  bool _isLoading = false;
  bool _isApiLoading = false;
  String? _error;
  String? _tableApiError;
  String _selectedLocation = 'All';

  // Getters
  List<RestaurantTable> get tables => _tables;
  List<OrderChannel> get orderChannels => _orderChannels;
  bool get isLoading => _isLoading;
  bool get isApiLoading => _isApiLoading;
  String? get error => _error;
  String? get tableApiError => _tableApiError;
  String get selectedLocation => _selectedLocation;

  // Initialize tables with mock data
  void initializeTables() {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _tables.clear();
      _tables.addAll([
        RestaurantTable(
          id: '1',
          name: 'Table 1',
          capacity: 4,
          location: 'Main Hall',
          status: TableStatus.available,
          kotGenerated: false,
          billGenerated: false,
        ),
        RestaurantTable(
          id: '2',
          name: 'Table 2',
          capacity: 2,
          location: 'Main Hall',
          status: TableStatus.occupied,
          kotGenerated: true,
          billGenerated: false,
        ),
        RestaurantTable(
          id: '3',
          name: 'VIP 1',
          capacity: 6,
          location: 'VIP Section',
          status: TableStatus.reserved,
          kotGenerated: false,
          billGenerated: false,
          reservationInfo: ReservationInfo(
            startTime: '19:00',
            endTime: '21:00',
            occasion: 'Birthday Party',
            guestCount: 4,
            reservationDate: DateTime.now().add(const Duration(hours: 2)),
            totalAmount: 1200.0,
            customerName: 'Sayan Banik',
            specialRequests: 'Birthday cake decoration',
          ),
        ),
        RestaurantTable(
          id: '4',
          name: 'Terrace 1',
          capacity: 8,
          location: 'Terrace',
          status: TableStatus.available,
          kotGenerated: false,
          billGenerated: false,
        ),
        RestaurantTable(
          id: '5',
          name: 'Garden 1',
          capacity: 4,
          location: 'Garden Area',
          status: TableStatus.occupied,
          kotGenerated: true,
          billGenerated: false,
        ),
        RestaurantTable(
          id: '6',
          name: 'Private Room 1',
          capacity: 12,
          location: 'Private Room',
          status: TableStatus.available,
          kotGenerated: false,
          billGenerated: false,
        ),
      ]);

      _isLoading = false;
      _error = null;
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to load tables: ${e.toString()}';
    }

    notifyListeners();
  }

  // Fetch tables from API
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

  // Get tables filtered by location
  List<RestaurantTable> getTablesForLocation(String locationName) {
    if (locationName == 'All') {
      return _tables;
    }
    return _tables.where((table) => table.location == locationName).toList();
  }

  // Update table status
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
