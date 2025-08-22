import 'package:flutter/material.dart';

class AnimatedCartProvider extends ChangeNotifier {
  final Map<String, CartItem> _cartItems = {};
  int _totalItems = 0;

  Map<String, CartItem> get cartItems => _cartItems;
  int get totalItems => _totalItems;
  double get totalAmount => _cartItems.values.fold(
    0,
    (sum, item) => sum + (item.price * item.quantity),
  );
/*

*/
  // |  UPDATED: Add specialNotes parameter to fix the error
  void addItem(
    String itemId,
    String name,
    double price,
    String tableId,
    String tableName, {
    String? specialNotes,
  }) {
    if (_cartItems.containsKey(itemId)) {
      _cartItems[itemId]!.quantity++;
      // Update special notes if provided
      if (specialNotes != null && specialNotes.isNotEmpty) {
        _cartItems[itemId]!.specialNotes = specialNotes;
      }
    } else {
      _cartItems[itemId] = CartItem(
        id: itemId,
        name: name,
        price: price,
        quantity: 1,
        tableId: tableId,
        tableName: tableName,
        specialNotes: specialNotes,
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

  // Add method to update special notes
  void updateItemNotes(String itemId, String notes) {
    if (_cartItems.containsKey(itemId)) {
      _cartItems[itemId]!.specialNotes = notes;
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

// Updated CartItem class with specialNotes
class CartItem {
  String id;
  String name;
  double price;
  int quantity;
  String tableId;
  String tableName;
  String? specialNotes; // |  ADD this field

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.tableId,
    required this.tableName,
    this.specialNotes, // |  ADD this parameter
  });
}
