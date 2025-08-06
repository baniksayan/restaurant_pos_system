import 'package:flutter/material.dart';
// import '../../../data/models/menu_item.dart';

class CartProvider with ChangeNotifier {
  Map<String, int> _cartItems = {};
  
  Map<String, int> get cartItems => _cartItems;
  
  int get totalItems => _cartItems.values.fold(0, (sum, quantity) => sum + quantity);
  
  void addItem(String itemId) {
    _cartItems[itemId] = (_cartItems[itemId] ?? 0) + 1;
    notifyListeners();
  }
  
  void removeItem(String itemId) {
    if (_cartItems.containsKey(itemId)) {
      if (_cartItems[itemId]! > 1) {
        _cartItems[itemId] = _cartItems[itemId]! - 1;
      } else {
        _cartItems.remove(itemId);
      }
      notifyListeners();
    }
  }
  
  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }
}
