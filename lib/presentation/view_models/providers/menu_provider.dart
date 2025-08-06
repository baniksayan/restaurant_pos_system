import 'package:flutter/material.dart';
import '../../../data/models/menu_item.dart';

class MenuProvider with ChangeNotifier {
  List<MenuItem> _menuItems = [];

  List<MenuItem> get menuItems => _menuItems;

  void addMenuItem(MenuItem item) {
    _menuItems.add(item);
    notifyListeners();
  }

  void updateMenuItem(MenuItem item) {
    final index = _menuItems.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      _menuItems[index] = item;
      notifyListeners();
    }
  }

  void removeMenuItem(String id) {
    _menuItems.removeWhere((item) => item.id == id);
    notifyListeners();
  }
}
