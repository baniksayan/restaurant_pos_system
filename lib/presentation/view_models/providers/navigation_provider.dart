import 'package:flutter/material.dart';

class NavigationProvider extends ChangeNotifier {
  int _currentIndex = 0;
  String? _selectedTableId;
  String? _selectedTableName;
  String? _selectedLocation;

  // Added properties
  String? _selectedOrderType;
  String? _customerName;
  String? _customerPhone;

  int get currentIndex => _currentIndex;
  String? get selectedTableId => _selectedTableId;
  String? get selectedTableName => _selectedTableName;
  String? get selectedLocation => _selectedLocation;

  // Added getters
  String? get selectedOrderType => _selectedOrderType;
  String? get customerName => _customerName;
  String? get customerPhone => _customerPhone;

  void navigateToIndex(int index) {
    // Ensure index is within valid range (0-3)
    if (index >= 0 && index <= 3) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  void selectTable(String tableId, String tableName, String location) {
    _selectedTableId = tableId;
    _selectedTableName = tableName;
    _selectedLocation = location;
    _currentIndex = 1; // Menu tab
    notifyListeners();
  }

  // Added method - now clears table selection to prevent contamination
  void selectOrderTypeAndNavigate(
    String orderType,
    String customerName,
    String phoneNumber,
  ) {
    // Clear any existing table selection to prevent data contamination
    _selectedTableId = null;
    _selectedTableName = null;
    _selectedLocation = null;

    _selectedOrderType = orderType;
    _customerName = customerName;
    _customerPhone = phoneNumber;
    _currentIndex = 1; // Navigate to menu
    notifyListeners();
  }

  void clearTableSelection() {
    _selectedTableId = null;
    _selectedTableName = null;
    _selectedLocation = null;
    notifyListeners();
  }

  // Navigate to specific tabs by name
  void navigateToTables() => navigateToIndex(0);
  void navigateToMenu() => navigateToIndex(1);
  void navigateToCart() => navigateToIndex(2);
  void navigateToReports() => navigateToIndex(3);
}
