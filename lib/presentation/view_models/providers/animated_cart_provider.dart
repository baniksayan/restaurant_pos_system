import 'package:flutter/material.dart';

import '../../../data/local/hive_service.dart';
import '../../../data/models/order_detail_api_response_model.dart';

class AnimatedCartProvider extends ChangeNotifier {
  final Map<String, CartItem> _cartItems = {};
  final Map<String, Map<String, CartItem>> _tableWiseCarts =
      {}; // Store cart per table
  final Map<String, List<OrderDetailList>> _tableWiseServerKotItems =
      {}; // Store server KOT items per table
  int _totalItems = 0;
  String? _currentTableId;
  List<OrderDetailList> _serverKotItems =
      []; // Current table's server KOT items

  Map<String, CartItem> get cartItems => _cartItems;
  int get totalItems => _totalItems;
  String? get currentTableId => _currentTableId;
  List<OrderDetailList> get serverKotItems => _serverKotItems;

  // Get items that are not yet KOT'd
  Map<String, CartItem> get newItems => Map.fromEntries(
    _cartItems.entries.where((entry) => !entry.value.isKotGenerated),
  );

  // Get items that have been KOT'd
  Map<String, CartItem> get kotGeneratedItems => Map.fromEntries(
    _cartItems.entries.where((entry) => entry.value.isKotGenerated),
  );

  // Check if all items have been KOT'd (required for billing)
  bool get canProceedToBilling =>
      _cartItems.isNotEmpty &&
      _cartItems.values.every((item) => item.isKotGenerated);

  // Check if there are new items to generate KOT
  bool get hasNewItemsForKot => newItems.isNotEmpty;

  double get totalAmount => _cartItems.values.fold(
    0.0,
    (sum, item) => sum + (item.price * item.quantity),
  );

  // Switch to a different table's cart and sync with server state
  void switchToTable(String? newTableId) {
    if (newTableId == null || _currentTableId == newTableId) return;

    // Save current cart state to persistent storage
    if (_currentTableId != null) {
      _saveCartToPersistentStorage(_currentTableId!);
    }

    debugPrint(
      '[AnimatedCart] Switching from table $_currentTableId to $newTableId',
    );

    // Switch to new table
    _currentTableId = newTableId;

    // Load cart from memory first, then from persistent storage if needed
    _cartItems.clear();
    final existingCart = _tableWiseCarts[newTableId];
    if (existingCart != null && existingCart.isNotEmpty) {
      _cartItems.addAll(existingCart);
    } else {
      // If no cart in memory, try loading from persistent storage
      _loadCartFromPersistentStorage(newTableId);
      final loadedCart = _tableWiseCarts[newTableId];
      if (loadedCart != null) {
        _cartItems.addAll(loadedCart);
      }
    }

    // Also load server KOT items for this table
    _serverKotItems = _tableWiseServerKotItems[newTableId] ?? [];

    _updateTotalItems();
    debugPrint(
      '[AnimatedCart] Switched to table $newTableId with ${_cartItems.length} items',
    );
    notifyListeners();
  }

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
    // Ensure we're working with the correct table
    if (_currentTableId != tableId) {
      switchToTable(tableId);
    }

    if (_cartItems.containsKey(itemId)) {
      // Only allow quantity increase if item is not KOT'd
      if (_cartItems[itemId]!.canEdit) {
        _cartItems[itemId]!.quantity++;
        if (specialNotes != null && specialNotes.isNotEmpty) {
          _cartItems[itemId]!.specialNotes = specialNotes;
        }
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
      final item = _cartItems[itemId]!;
      // Only allow removal if item is not KOT'd
      if (item.canEdit) {
        if (item.quantity > 1) {
          item.quantity--;
        } else {
          _cartItems.remove(itemId);
        }
        _updateTotalItems();
        notifyListeners();
      }
    }
  }

  // Enhanced method - Delete all quantities of a specific item (only if not KOT'd)
  void deleteAllOfItem(String itemId) {
    if (_cartItems.containsKey(itemId) && _cartItems[itemId]!.canEdit) {
      _cartItems.remove(itemId);
      _updateTotalItems();
      notifyListeners();
    }
  }

  // Mark items as KOT generated
  void markItemsAsKotGenerated(List<String> itemIds, String kotNumber) {
    for (String itemId in itemIds) {
      if (_cartItems.containsKey(itemId)) {
        _cartItems[itemId]!.markAsKotGenerated(kotNumber);
      }
    }
    notifyListeners();
  }

  // Get only new (non-KOT'd) items for KOT generation
  Map<String, dynamic> buildNewItemsOrderMap({
    required String orderId,
    String kotNote = "",
  }) {
    final newItemsList = newItems.values.toList();
    return {
      "userId": HiveService.getUserId(),
      "outletId": HiveService.getOutletId(),
      "orderId": orderId,
      "kotNote": kotNote,
      "orderDetails":
          newItemsList.map((item) {
            // Match exact Postman format and field order
            final orderDetail = <String, dynamic>{
              "productId": item.id,
              "productName": item.name,
              "categoryId": item.categoryId ?? "",
              "categoryName": item.categoryName ?? "",
              "productPrice": item.price,
              "discountPercentage": item.discountPercentage ?? 0,
              "uom": item.uom ?? "Plate",
              "quantity": item.quantity,
              "note": item.specialNotes ?? "",
            };

            return orderDetail;
          }).toList(),
    };
  }

  void updateItemNotes(String itemId, String notes) {
    if (_cartItems.containsKey(itemId) && _cartItems[itemId]!.canEdit) {
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

  // Clear only new (non-KOT'd) items while keeping KOT'd items for billing
  void clearNewItems() {
    _cartItems.removeWhere((key, item) => !item.isKotGenerated);
    _updateTotalItems();
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
      "orderDetails":
          _cartItems.values.map((item) {
            final orderDetail = <String, dynamic>{
              "productId": item.id,
              "productName": item.name,
              "productPrice": item.price,
              "discountPercentage": item.discountPercentage ?? 0,
              "quantity": item.quantity,
              "note": item.specialNotes ?? "",
            };

            // Only add categoryId if it's not null and not empty
            if (item.categoryId != null && item.categoryId!.isNotEmpty) {
              orderDetail["categoryId"] = item.categoryId;
            }

            // Only add categoryName if it's not null and not empty
            if (item.categoryName != null && item.categoryName!.isNotEmpty) {
              orderDetail["categoryName"] = item.categoryName;
            }

            // Only add uom if it's not null and not empty
            if (item.uom != null && item.uom!.isNotEmpty) {
              orderDetail["uom"] = item.uom;
            }

            return orderDetail;
          }).toList(),
    };
  }

  // --- Import from order cart state with KOT status support ---
  void importFromOrderCart(
    List<Map<String, dynamic>> items, {
    String tableId = '',
    String tableName = '',
    bool clearExisting = true,
  }) {
    if (clearExisting) {
      _cartItems.clear();
    }

    for (final raw in items) {
      final id = (raw['productId'] ?? raw['id'] ?? '').toString();
      if (id.isEmpty) continue;

      final name =
          (raw['productName'] ?? raw['productName'] ?? raw['name'] ?? '')
              .toString();

      // price -> ensure double
      double price = 0;
      final p = raw['price'] ?? raw['productPrice'] ?? raw['itemPrice'];
      if (p is num) {
        price = p.toDouble();
      } else if (p is String) {
        price = double.tryParse(p) ?? 0;
      }

      // quantity -> ensure int
      int quantity = 1;
      final q = raw['quantity'] ?? raw['productQty'] ?? raw['qty'];
      if (q is int) {
        quantity = q;
      } else if (q is double) {
        quantity = q.toInt();
      } else if (q is String) {
        quantity = int.tryParse(q) ?? 1;
      }

      final specialNotes =
          (raw['specialNotes'] ?? raw['note'] ?? '').toString();
      final categoryId = (raw['categoryId'] ?? '').toString();
      final categoryName = (raw['categoryName'] ?? '').toString();
      final uom = (raw['uom'] ?? '').toString();
      final discount = raw['discountPercentage'];
      double? discountPercentage;
      if (discount is num)
        discountPercentage = discount.toDouble();
      else if (discount is String)
        discountPercentage = double.tryParse(discount);

      // Check KOT status
      final isKotGenerated =
          raw['isKotGenerated'] == true ||
          raw['kotNo'] != null ||
          raw['kotNumber'] != null;
      final kotNumber = (raw['kotNo'] ?? raw['kotNumber'] ?? '').toString();
      DateTime? kotGeneratedAt;
      if (raw['kotGeneratedAt'] != null) {
        if (raw['kotGeneratedAt'] is String) {
          kotGeneratedAt = DateTime.tryParse(raw['kotGeneratedAt']);
        } else if (raw['kotGeneratedAt'] is DateTime) {
          kotGeneratedAt = raw['kotGeneratedAt'];
        }
      }

      // Create CartItem with KOT status
      _cartItems[id] = CartItem(
        id: id,
        name: name,
        price: price,
        quantity: quantity,
        tableId: tableId,
        tableName: tableName,
        specialNotes: specialNotes.isNotEmpty ? specialNotes : null,
        categoryId: categoryId.isNotEmpty ? categoryId : null,
        categoryName: categoryName.isNotEmpty ? categoryName : null,
        uom: uom.isNotEmpty ? uom : null,
        discountPercentage: discountPercentage,
        isKotGenerated: isKotGenerated,
        kotNumber: kotNumber.isNotEmpty ? kotNumber : null,
        kotGeneratedAt: kotGeneratedAt,
      );
    }

    // Set current table
    if (tableId.isNotEmpty) {
      _currentTableId = tableId;
    }

    _updateTotalItems();
    notifyListeners();
  }

  // Persistent storage methods for cart data
  void _saveCartToPersistentStorage(String tableId) {
    try {
      final cartData = _tableWiseCarts[tableId];
      if (cartData != null && cartData.isNotEmpty) {
        final cartJson = cartData.map(
          (key, item) => MapEntry(key, {
            'id': item.id,
            'name': item.name,
            'price': item.price,
            'quantity': item.quantity,
            'tableId': item.tableId,
            'tableName': item.tableName,
            'specialNotes': item.specialNotes,
            'categoryId': item.categoryId,
            'categoryName': item.categoryName,
            'uom': item.uom,
            'discountPercentage': item.discountPercentage,
            'isKotGenerated': item.isKotGenerated,
            'kotNumber': item.kotNumber,
            'kotGeneratedAt': item.kotGeneratedAt?.toIso8601String(),
          }),
        );
        HiveService.saveTableCart(tableId, cartJson);
        debugPrint(
          '[AnimatedCart] Saved cart for table $tableId to persistent storage',
        );
      }
    } catch (e) {
      debugPrint('[AnimatedCart] Error saving cart to persistent storage: $e');
    }
  }

  void _loadCartFromPersistentStorage(String tableId) {
    try {
      final cartData = HiveService.getTableCart(tableId);
      if (cartData != null && cartData.isNotEmpty) {
        final Map<String, CartItem> loadedCart = {};

        for (final entry in cartData.entries) {
          final itemData = entry.value as Map<String, dynamic>;
          DateTime? kotGeneratedAt;
          if (itemData['kotGeneratedAt'] != null) {
            kotGeneratedAt = DateTime.tryParse(itemData['kotGeneratedAt']);
          }

          loadedCart[entry.key] = CartItem(
            id: itemData['id'] ?? '',
            name: itemData['name'] ?? '',
            price: (itemData['price'] ?? 0.0).toDouble(),
            quantity: itemData['quantity'] ?? 1,
            tableId: itemData['tableId'] ?? tableId,
            tableName: itemData['tableName'] ?? '',
            specialNotes: itemData['specialNotes'],
            categoryId: itemData['categoryId'],
            categoryName: itemData['categoryName'],
            uom: itemData['uom'],
            discountPercentage:
                (itemData['discountPercentage'] ?? 0.0).toDouble(),
            isKotGenerated: itemData['isKotGenerated'] ?? false,
            kotNumber: itemData['kotNumber'],
            kotGeneratedAt: kotGeneratedAt,
          );
        }

        _tableWiseCarts[tableId] = loadedCart;
        debugPrint(
          '[AnimatedCart] Loaded ${loadedCart.length} items for table $tableId from persistent storage',
        );
      }
    } catch (e) {
      debugPrint(
        '[AnimatedCart] Error loading cart from persistent storage: $e',
      );
    }
  }
}

// Updated CartItem class with KOT status tracking
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
  bool isKotGenerated; // Track if this item has been KOT'd
  String? kotNumber; // Store KOT number for reference
  DateTime? kotGeneratedAt; // When was KOT generated

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
    this.isKotGenerated = false,
    this.kotNumber,
    this.kotGeneratedAt,
  });

  // Mark this item as KOT generated
  void markAsKotGenerated(String kotNo) {
    isKotGenerated = true;
    kotNumber = kotNo;
    kotGeneratedAt = DateTime.now();
  }

  // Check if item can be edited (not KOT'd)
  bool get canEdit => !isKotGenerated;
}
