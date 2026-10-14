import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/data/models/restaurant_table.dart';
import 'package:restaurant_pos_system/data/local/sync_service.dart';
import 'package:restaurant_pos_system/data/local/hive_service.dart';
import 'package:restaurant_pos_system/data/models/auth_api_res_model.dart';
import 'package:restaurant_pos_system/data/models/order_channel_types_model.dart';
import 'table_provider.dart';

class LocationSection {
  final String name;
  final IconData icon;
  final Color color;
  final int? id;
  final String? type;
  final String? address;

  LocationSection(
    this.name,
    this.icon,
    this.color, {
    this.id,
    this.type,
    this.address,
  });
}

class DashboardProvider extends ChangeNotifier {
  String _selectedLocation = '';
  String _selectedStatusFilter = 'all';
  bool _isSyncing = false;
  String? _syncMessage;

  // New properties for order management - using the correct OrderType
  OrderType? _selectedOrderType;
  String? _customerName;
  String? _customerPhone;

  List<LocationSection> _locations = [];

  String get selectedLocation => _selectedLocation;
  String get selectedStatusFilter => _selectedStatusFilter;
  bool get isSyncing => _isSyncing;
  String? get syncMessage => _syncMessage;

  // New getters
  OrderType? get selectedOrderType => _selectedOrderType;
  String? get customerName => _customerName;
  String? get customerPhone => _customerPhone;

  List<LocationSection> get locations => _locations;

  int? get selectedLocationId {
    final matched =
        _locations.where((l) => l.name == _selectedLocation).firstOrNull;
    return matched?.id ??
        HiveService.getSelectedLocationId() ??
        HiveService.getOutletId();
  }

  int? getOutletIdForLocation(String locationName) {
    final matched =
        _locations.where((l) => l.name == locationName).firstOrNull;
    return matched?.id;
  }

  DashboardProvider() {
    loadLocationsFromHive();
  }

  void loadLocationsFromHive() {
    final storedLocations = HiveService.getLocations();
    if (storedLocations.isNotEmpty) {
      _locations = _mapApiLocationsToSections(storedLocations);
      final savedName = HiveService.getSelectedLocationName();
      if (savedName != null &&
          savedName.isNotEmpty &&
          _locations.any((l) => l.name == savedName)) {
        _selectedLocation = savedName;
        final matched = _locations.firstWhere((l) => l.name == savedName);
        if (matched.id != null) {
          HiveService.setOutletId(matched.id!);
          HiveService.setSelectedLocationId(matched.id!);
        }
      } else {
        _selectedLocation = _locations.first.name;
        HiveService.setSelectedLocationName(_selectedLocation);
        if (_locations.first.id != null) {
          HiveService.setOutletId(_locations.first.id!);
          HiveService.setSelectedLocationId(_locations.first.id!);
        }
      }
    } else {
      _locations = [];
      _selectedLocation = '';
    }
    notifyListeners();
  }

  void updateLocationsFromApi(List<Location> apiLocations) {
    if (apiLocations.isEmpty) return;
    HiveService.saveLocations(apiLocations);
    _locations = _mapApiLocationsToSections(apiLocations);
    final savedName = HiveService.getSelectedLocationName();
    if (savedName != null &&
        savedName.isNotEmpty &&
        _locations.any((l) => l.name == savedName)) {
      _selectedLocation = savedName;
      final matched = _locations.firstWhere((l) => l.name == savedName);
      if (matched.id != null) {
        HiveService.setOutletId(matched.id!);
        HiveService.setSelectedLocationId(matched.id!);
      }
    } else {
      _selectedLocation = _locations.first.name;
      HiveService.setSelectedLocationName(_selectedLocation);
      if (_locations.first.id != null) {
        HiveService.setOutletId(_locations.first.id!);
        HiveService.setSelectedLocationId(_locations.first.id!);
      }
    }
    notifyListeners();
  }

  static List<LocationSection> _mapApiLocationsToSections(
    List<Location> apiLocations,
  ) {
    const icons = [
      Icons.storefront_rounded,
      Icons.restaurant_rounded,
      Icons.local_dining_rounded,
      Icons.lunch_dining_rounded,
      Icons.dinner_dining_rounded,
      Icons.coffee_rounded,
    ];
    const colors = [
      Colors.blue,
      Colors.teal,
      Colors.purple,
      Colors.orange,
      Colors.indigo,
      Colors.deepOrange,
    ];

    return apiLocations.asMap().entries.map((entry) {
      final index = entry.key;
      final loc = entry.value;
      final name = loc.locationName?.trim().isNotEmpty == true
          ? loc.locationName!.trim()
          : 'Location ${loc.locationId ?? index + 1}';
      return LocationSection(
        name,
        icons[index % icons.length],
        colors[index % colors.length],
        id: loc.locationId,
        type: loc.locationType,
        address: loc.locAddress,
      );
    }).toList();
  }

  void changeLocation(String location) {
    _selectedLocation = location;
    HiveService.setSelectedLocationName(location);
    final matched = _locations.where((l) => l.name == location).firstOrNull;
    if (matched != null && matched.id != null) {
      HiveService.setOutletId(matched.id!);
      HiveService.setSelectedLocationId(matched.id!);
    }
    notifyListeners();
  }

  void changeStatusFilter(String statusFilter) {
    _selectedStatusFilter = statusFilter;
    notifyListeners();
  }

  // New methods for order management - using correct OrderType
  void setOrderType(OrderType orderType) {
    _selectedOrderType = orderType;
    notifyListeners();
  }

  void setCustomerDetails(String name, String phone) {
    _customerName = name;
    _customerPhone = phone;
    notifyListeners();
  }

  void clearOrderSelection() {
    _selectedOrderType = null;
    _customerName = null;
    _customerPhone = null;
    notifyListeners();
  }

  // Show default location by default
  bool get isShowingDefaultLocation =>
      _locations.isNotEmpty && _selectedLocation == _locations.first.name;

  @Deprecated('Use isShowingDefaultLocation instead')
  bool get isShowingMainHall => isShowingDefaultLocation;

  // Add method to check if location has tables
  bool hasTablesForLocation(String location, List<RestaurantTable> allTables) {
    return allTables.any((table) => table.location == location);
  }

  // Get available locations that have tables
  List<LocationSection> getAvailableLocations(List<RestaurantTable> allTables) {
    return locations
        .where((location) => hasTablesForLocation(location.name, allTables))
        .toList();
  }

  // Get table count for a specific location
  int getTableCountForLocation(
    String location,
    List<RestaurantTable> allTables,
  ) {
    return allTables.where((table) => table.location == location).length;
  }

  // Get status counts for a location
  Map<String, int> getStatusCountsForLocation(
    String location,
    List<RestaurantTable> allTables,
  ) {
    List<RestaurantTable> filteredTables =
        allTables.where((table) => table.location == location).toList();

    return {
      'total': filteredTables.length,
      'available':
          filteredTables.where((t) => t.status == TableStatus.available).length,
      'occupied':
          filteredTables.where((t) => t.status == TableStatus.occupied).length,
      'kot_generated':
          filteredTables
              .where((t) => t.status == TableStatus.kotGenerated)
              .length,
      'bill_generated':
          filteredTables
              .where((t) => t.status == TableStatus.billGenerated)
              .length,
      'bill_settled':
          filteredTables
              .where((t) => t.status == TableStatus.billSettled)
              .length,
      'reserved':
          filteredTables.where((t) => t.status == TableStatus.reserved).length,
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
      case 'bill_settled':
        return 'bill settled';
      default:
        return statusFilter;
    }
  }

  // Reset filters to show default location (not all tables)
  void resetFilters() {
    _selectedLocation = _locations.isNotEmpty ? _locations.first.name : '';
    _selectedStatusFilter = 'all';
    notifyListeners();
  }

  // Check if any filters are active
  bool get hasActiveFilters {
    final defaultLocation = _locations.isNotEmpty ? _locations.first.name : '';
    return _selectedLocation != defaultLocation || _selectedStatusFilter != 'all';
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

      _syncMessage =
          success
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

  /// Wipes all in-memory dashboard state when the user signs out.
  void reset() {
    _locations = [];
    _selectedLocation = '';
    _selectedStatusFilter = 'all';
    _selectedOrderType = null;
    _customerName = null;
    _customerPhone = null;
    _isSyncing = false;
    _syncMessage = null;
    notifyListeners();
  }
}
