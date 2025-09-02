import 'package:flutter/material.dart';
import '../../../data/local/hive_service.dart';

class CartProvider with ChangeNotifier {
  Map<String, CartItem> _cartItems = {};

  Map<String, CartItem> get cartItems => _cartItems;

  int get totalItems =>
      _cartItems.values.fold(0, (sum, item) => sum + item.quantity);

  double get totalAmount => _cartItems.values.fold(
    0.0,
    (sum, item) => sum + (item.price * item.quantity),
  );

  void addItem(
    String itemId,
    String name,
    double price,
    String tableId,
    String tableName,
    String categoryId,
    String categoryName,
  ) {
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
        categoryId: categoryId,
        categoryName: categoryName,
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

  // --- Add this method to build the order map for backend ---
  Map<String, dynamic> buildOrderMap({
    required String orderId,
    String kotNote = "",
  }) {
    return {
      "userId": HiveService.getUserId(),
      "outletId": HiveService.getOutletId(),
      "orderId": orderId,
      "kotNote": kotNote,
      "orderDetails":
          _cartItems.values
              .map(
                (item) => {
                  "productId": item.id,
                  "productName": item.name,
                  // Add categoryId, categoryName, uom, discountPercentage if available in CartItem
                  "categoryId": item.categoryId ?? "",
                  "categoryName": item.categoryName ?? "",
                  "productPrice": item.price,
                  "discountPercentage": item.discountPercentage ?? 0,
                  "uom": item.uom ?? "",
                  "quantity": item.quantity,
                  "note": item.specialNotes ?? "",
                },
              )
              .toList(),
    };
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

  // Add these fields if you want to support category, uom, discount, etc.
  String? categoryId;
  String? categoryName;
  String? uom;
  double? discountPercentage;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.tableId,
    required this.tableName,
    this.specialNotes,
    this.categoryId,
    this.categoryName,
    this.uom,
    this.discountPercentage,
  });
}
