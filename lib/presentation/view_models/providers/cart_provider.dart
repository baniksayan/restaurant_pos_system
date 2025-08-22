import 'package:flutter/material.dart';

class CartProvider with ChangeNotifier {
  Map<String, CartItem> _cartItems = {};
  
  Map<String, CartItem> get cartItems => _cartItems;
  
  int get totalItems => _cartItems.values.fold(0, (sum, item) => sum + item.quantity);
  
  double get totalAmount => _cartItems.values.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  
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
    notifyListeners();
  }
  
  void removeItem(String itemId) {
    if (_cartItems.containsKey(itemId)) {
      if (_cartItems[itemId]!.quantity > 1) {
        _cartItems[itemId]!.quantity--;
      } else {
        _cartItems.remove(itemId);
      }
      notifyListeners();
    }
  }
  
  void updateItemNotes(String itemId, String notes) {
    if (_cartItems.containsKey(itemId)) {
      _cartItems[itemId]!.specialNotes = notes;
      notifyListeners();
    }
  }
  
  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }
}

class CartItem {
  final String id;
  final String name;
  final double price;
  int quantity;
  final String tableId;
  final String tableName;
  String? specialNotes;
  
  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.tableId,
    required this.tableName,
    this.specialNotes,
  });
}
