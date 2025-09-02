import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/data/models/restaurant_table.dart';
import 'package:restaurant_pos_system/services/sync_service.dart';
import 'table_provider.dart';

class LocationSection {
  final String name;
  final IconData icon;
  final Color color;

  LocationSection(this.name, this.icon, this.color);
}

class DashboardProvider extends ChangeNotifier {
  String _selectedLocation = 'Main Hall'; // Default to Main Hall instead of empty
  String _selectedStatusFilter = 'all';
  bool _isSyncing = false;
  String? _syncMessage;

  String get selectedLocation => _selectedLocation;
  String get selectedStatusFilter => _selectedStatusFilter;
  bool get isSyncing => _isSyncing;
  String? get syncMessage => _syncMessage;

  // Removed 'All' from locations list as requested
  final List<LocationSection> locations = [
    LocationSection('Main Hall', Icons.home, Colors.blue),
    LocationSection('VIP Section', Icons.star, Colors.purple),
    LocationSection('Terrace', Icons.deck, Colors.orange),
    LocationSection('Garden Area', Icons.local_florist, Colors.green),
    LocationSection('Balcony', Icons.balcony, Colors.teal),
    LocationSection('Private Room', Icons.meeting_room, Colors.red),
  ];

  void changeLocation(String location) {
    _selectedLocation = location;
    notifyListeners();
  }

  void changeStatusFilter(String statusFilter) {
    _selectedStatusFilter = statusFilter;
    notifyListeners();
  }

  // Show Main Hall by default (when app first opens)
  bool get isShowingMainHall => _selectedLocation == 'Main Hall';

  // Add method to check if location has tables
  bool hasTablesForLocation(String location, List<RestaurantTable> allTables) {
    return allTables.any((table) => table.location == location);
  }

  // Get available locations that have tables
  List<LocationSection> getAvailableLocations(List<RestaurantTable> allTables) {
    return locations.where((location) =>
      hasTablesForLocation(location.name, allTables)
    ).toList();
  }

  // Get table count for a specific location
  int getTableCountForLocation(String location, List<RestaurantTable> allTables) {
    return allTables.where((table) => table.location == location).length;
  }

  // Get status counts for a location
  Map<String, int> getStatusCountsForLocation(String location, List<RestaurantTable> allTables) {
    List<RestaurantTable> filteredTables = allTables.where((table) => table.location == location).toList();

    return {
      'total': filteredTables.length,
      'available': filteredTables.where((t) => t.status == TableStatus.available).length,
      'occupied': filteredTables.where((t) => t.status == TableStatus.occupied).length,
      'reserved': filteredTables.where((t) => t.status == TableStatus.reserved).length,
      'kot_generated': filteredTables.where((t) => t.kotGenerated == true).length,
      'bill_generated': filteredTables.where((t) => t.billGenerated == true).length,
    };
  }

  // Check if current location has any tables
  bool get hasTablesInSelectedLocation {
    return _selectedLocation.isNotEmpty;
  }

  // Get empty state message based on current filters
  String getEmptyStateMessage(List<RestaurantTable> allTables) {
    if (allTables.isEmpty) {
      return 'No tables found for this outlet';
    }

    if (!hasTablesForLocation(_selectedLocation, allTables)) {
      return 'No tables found in $_selectedLocation';
    }

    if (_selectedStatusFilter != 'all') {
      final statusName = _getStatusFilterDisplayName(_selectedStatusFilter);
      return 'No $statusName tables found in $_selectedLocation';
    }

    return 'No tables available';
  }

  // Get display name for status filter
  String _getStatusFilterDisplayName(String statusFilter) {
    switch (statusFilter) {
      case 'available':
        return 'available';
      case 'occupied':
        return 'occupied';
      case 'reserved':
        return 'reserved';
      case 'kot_generated':
        return 'KOT generated';
      case 'bill_generated':
        return 'bill generated';
      default:
        return statusFilter;
    }
  }

  // Reset filters to show Main Hall (not all tables)
  void resetFilters() {
    _selectedLocation = 'Main Hall';
    _selectedStatusFilter = 'all';
    notifyListeners();
  }

  // Check if any filters are active
  bool get hasActiveFilters {
    return _selectedLocation != 'Main Hall' || _selectedStatusFilter != 'all';
  }

  Future<void> syncData({TableProvider? tableProvider}) async {
    _isSyncing = true;
    _syncMessage = null;
    notifyListeners();

    try {
      // Sync general data
      final success = await SyncService.syncAllData();
      
      // Also refresh tables if provider is available
      if (tableProvider != null) {
        await tableProvider.refreshTables();
      }

      _syncMessage = success
          ? 'Data synced successfully!'
          : 'Sync failed. Please try again.';
    } catch (e) {
      _syncMessage = 'Sync error: ${e.toString()}';
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  void clearSyncMessage() {
    _syncMessage = null;
    notifyListeners();
  }
}
