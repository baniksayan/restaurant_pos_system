import 'package:flutter/material.dart';
import '../../../data/local/hive_service.dart';
import 'package:uuid/uuid.dart';

class AnimatedCartProvider extends ChangeNotifier {
  final Map<String, CartItem> _cartItems = {};
  int _totalItems = 0;

  Map<String, CartItem> get cartItems => _cartItems;
  int get totalItems => _totalItems;
  double get totalAmount => _cartItems.values.fold(
    0,
    (sum, item) => sum + (item.price * item.quantity),
  );

  void addItem(
    String itemId,
    String name,
    double price,
    String tableId,
    String tableName, {
    String? specialNotes,
    String? categoryId,
    String? categoryName,
    String? uom,
    double? discountPercentage,
  }) {
    if (_cartItems.containsKey(itemId)) {
      _cartItems[itemId]!.quantity++;
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
        categoryId: categoryId,
        categoryName: categoryName,
        uom: uom,
        discountPercentage: discountPercentage,
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

  // --- Build order map for backend ---
  Map<String, dynamic> buildOrderMap({
    required String orderId,
    String kotNote = "",
  }) {
    return {
      "userId": HiveService.getUserId(),
      "outletId": HiveService.getOutletId(),
      "orderId": orderId,
      "kotNote": kotNote,
      "orderDetails": _cartItems.values.map((item) => {
        "productId": item.id,
        "productName": item.name,
        "categoryId": item.categoryId ?? "",
        "categoryName": item.categoryName ?? "",
        "productPrice": item.price,
        "discountPercentage": item.discountPercentage ?? 0,
        "uom": item.uom ?? "",
        "quantity": item.quantity,
        "note": item.specialNotes ?? "",
      }).toList(),
    };
  }
}

// Updated CartItem class with all needed fields
class CartItem {
  String id;
  String name;
  double price;
  int quantity;
  String tableId;
  String tableName;
  String? specialNotes;
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