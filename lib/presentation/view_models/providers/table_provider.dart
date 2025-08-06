import 'package:flutter/material.dart';
import '../../../data/models/table.dart';

class TableProvider with ChangeNotifier {
  List<RestaurantTable> _tables = [];

  List<RestaurantTable> get tables => _tables;

  void updateTableStatus(String tableId, TableStatus status) {
    final index = _tables.indexWhere((t) => t.id == tableId);
    if (index != -1) {
      _tables[index] = _tables[index].copyWith(status: status);
      notifyListeners();
    }
  }

  void addTable(RestaurantTable table) {
    _tables.add(table);
    notifyListeners();
  }
}
