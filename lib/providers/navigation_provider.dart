// lib/providers/navigation_provider.dart
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
    _currentIndex = index;
    notifyListeners();
  }

  void selectTable(String tableId, String tableName, String location) {
    _selectedTableId = tableId;
    _selectedTableName = tableName;
    _selectedLocation = location;
    _currentIndex = 1; // Menu tab index
    notifyListeners();
  }

  void clearTableSelection() {
    _selectedTableId = null;
    _selectedTableName = null;
    _selectedLocation = null;
    notifyListeners();
  }
}
