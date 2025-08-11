// lib/presentation/view_models/providers/animated_cart_provider.dart
import 'package:flutter/material.dart';

class AnimatedCartProvider extends ChangeNotifier {
  final Map<String, CartItem> _cartItems = {};
  int _totalItems = 0;
  
  Map<String, CartItem> get cartItems => _cartItems;
  int get totalItems => _totalItems;
  double get totalAmount => _cartItems.values.fold(0, (sum, item) => sum + (item.price * item.quantity));
  
  void addItem(String itemId, String name, double price, String tableId, String tableName) {
    if (_cartItems.containsKey(itemId)) {
      _cartItems[itemId]!.quantity++;
    } else {
      _cartItems[itemId] = CartItem(
        id: itemId,
        name: name,
        price: price,
        quantity: 1,
        tableId: tableId,
        tableName: tableName,
      );
    }
    _updateTotalItems();
    notifyListeners();
  }
  
  void removeItem(String itemId) {
    if (_cartItems.containsKey(itemId)) {
      if (_cartItems[itemId]!.quantity > 1) {
        _cartItems[itemId]!.quantity--;
      } else {
        _cartItems.remove(itemId);
      }
      _updateTotalItems();
      notifyListeners();
    }
  }
  
  void _updateTotalItems() {
    _totalItems = _cartItems.values.fold(0, (sum, item) => sum + item.quantity);
  }
  
  void clearCart() {
    _cartItems.clear();
    _totalItems = 0;
    notifyListeners();
  }
}

class CartItem {
  String id;
  String name;
  double price;
  int quantity;
  String tableId;
  String tableName;
  
  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.tableId,
    required this.tableName,
  });
}
