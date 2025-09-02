import 'package:flutter/material.dart';

class NavigationProvider extends ChangeNotifier {
  int _currentIndex = 0;
  String? _selectedTableId;
  String? _selectedTableName;
  String? _selectedLocation;

  int get currentIndex => _currentIndex;
  String? get selectedTableId => _selectedTableId;
  String? get selectedTableName => _selectedTableName;
  String? get selectedLocation => _selectedLocation;

  void navigateToIndex(int index) {
    // Ensure index is within valid range (0-3 instead of 0-4)
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
