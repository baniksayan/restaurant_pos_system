// lib/presentation/view_models/providers/table_provider.dart
import 'package:flutter/material.dart';
import '../../../data/models/restaurant_table.dart';

class TableProvider extends ChangeNotifier {
  List<RestaurantTable> _tables = [];
  bool _isLoading = false; // 👈 ADD this property
  String? _error; // 👈 ADD this property
  String _selectedLocation = 'All'; // 👈 ADD location tracking

  // 👈 ADD these getters
  List<RestaurantTable> get tables => _tables;
  bool get isLoading => _isLoading; // Fix for line 1365
  String? get error => _error; // Fix for line 1369 & 1772
  String get selectedLocation => _selectedLocation;

  // lib/presentation/view_models/providers/table_provider.dart
  // Update your initializeTables method:

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
            // 👈 FIX: Complete reservation info
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

  // 👈 ADD this method - Fix for line 1373
  List<RestaurantTable> getTablesForLocation(String locationName) {
    if (locationName == 'All') {
      return _tables;
    }
    return _tables.where((table) => table.location == locationName).toList();
  }

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

  void setSelectedLocation(String location) {
    _selectedLocation = location;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

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
