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

  // Get total count of only new (non-KOT'd) items
  int get newItemsCount =>
      newItems.values.fold(0, (sum, item) => sum + item.quantity);

  // Get total amount of only new (non-KOT'd) items
  double get newItemsTotalAmount => newItems.values.fold(
    0.0,
    (sum, item) => sum + (item.price * item.quantity),
  );

  double get totalAmount => _cartItems.values.fold(
    0.0,
    (sum, item) => sum + (item.price * item.quantity),
  );

  // Get quantity for a specific item ID (only count editable/non-KOT'd items)
  int getItemQuantity(String itemId) {
    int qty = 0;
    for (final item in _cartItems.values) {
      if (item.id == itemId && !item.isKotGenerated) {
        qty += item.quantity;
      }
    }
    return qty;
  }

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
    String? imageUrl,
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

    // Check if there is an editable item in the cart for this food
    String? editableKey;
    CartItem? editableItem;
    for (final entry in _cartItems.entries) {
      if (entry.value.id == itemId && entry.value.canEdit) {
        editableKey = entry.key;
        editableItem = entry.value;
        break;
      }
    }

    if (editableItem != null && editableKey != null) {
      // Editable item already exists, increment its quantity up to 99
      if (editableItem.quantity < 99) {
        editableItem.quantity++;
      } else {
        debugPrint(
          '[AnimatedCart] Maximum item quantity (99) reached. Blocked increment.',
        );
      }
      if (specialNotes != null && specialNotes.isNotEmpty) {
        editableItem.specialNotes = specialNotes;
      }
      if (imageUrl != null && imageUrl.isNotEmpty) {
        editableItem.imageUrl = imageUrl;
      }
      debugPrint(
        '[AnimatedCart] Incremented quantity of existing editable item $name (key: $editableKey) to ${editableItem.quantity}',
      );
    } else {
      // No editable item exists for this food.
      // If the original itemId key exists (it must be KOT'd since there is no editable item),
      // we must use a unique key to add the new editable item.
      if (_cartItems.containsKey(itemId)) {
        final uniqueKey = '${itemId}_${DateTime.now().millisecondsSinceEpoch}';
        _cartItems[uniqueKey] = CartItem(
          id: itemId,
          name: name,
          price: price,
          quantity: 1,
          tableId: tableId,
          tableName: tableName,
          imageUrl: imageUrl,
          specialNotes: specialNotes,
          categoryId: categoryId,
          categoryName: categoryName,
          uom: uom,
          discountPercentage: discountPercentage,
          isKotGenerated: false,
        );
        debugPrint(
          '[AnimatedCart] Added new instance of KOT\'d item $name with key: $uniqueKey',
        );
      } else {
        // Otherwise, use the original itemId as key
        _cartItems[itemId] = CartItem(
          id: itemId,
          name: name,
          price: price,
          quantity: 1,
          tableId: tableId,
          tableName: tableName,
          imageUrl: imageUrl,
          specialNotes: specialNotes,
          categoryId: categoryId,
          categoryName: categoryName,
          uom: uom,
          discountPercentage: discountPercentage,
          isKotGenerated: false,
        );
        debugPrint('[AnimatedCart] Added new item $name with key: $itemId');
      }
    }

    _updateTotalItems();
    notifyListeners();
  }

  void removeItem(String itemId) {
    // Find the editable item for this itemId
    String? editableKey;
    CartItem? editableItem;
    for (final entry in _cartItems.entries) {
      if (entry.value.id == itemId && entry.value.canEdit) {
        editableKey = entry.key;
        editableItem = entry.value;
        break;
      }
    }

    if (editableItem != null && editableKey != null) {
      if (editableItem.quantity > 1) {
        editableItem.quantity--;
      } else {
        _cartItems.remove(editableKey);
      }
      _updateTotalItems();
      notifyListeners();
    }
  }

  void setItemQuantity(
    String itemId,
    int quantity,
    String name,
    double price,
    String tableId,
    String tableName, {
    String? imageUrl,
    String? categoryId,
    String? categoryName,
    String? uom,
    double? discountPercentage,
  }) {
    // Ensure we're working with the correct table
    if (_currentTableId != tableId) {
      switchToTable(tableId);
    }

    // Find the editable item for this itemId
    String? editableKey;
    CartItem? editableItem;
    for (final entry in _cartItems.entries) {
      if (entry.value.id == itemId && entry.value.canEdit) {
        editableKey = entry.key;
        editableItem = entry.value;
        break;
      }
    }

    if (quantity <= 0) {
      if (editableKey != null) {
        _cartItems.remove(editableKey);
      }
    } else {
      final finalQty = quantity > 99 ? 99 : quantity;
      if (editableItem != null) {
        editableItem.quantity = finalQty;
        if (imageUrl != null && imageUrl.isNotEmpty) {
          editableItem.imageUrl = imageUrl;
        }
      } else {
        // Create new item with specified quantity
        if (_cartItems.containsKey(itemId)) {
          final uniqueKey =
              '${itemId}_${DateTime.now().millisecondsSinceEpoch}';
          _cartItems[uniqueKey] = CartItem(
            id: itemId,
            name: name,
            price: price,
            quantity: finalQty,
            tableId: tableId,
            tableName: tableName,
            imageUrl: imageUrl,
            categoryId: categoryId,
            categoryName: categoryName,
            uom: uom,
            discountPercentage: discountPercentage,
            isKotGenerated: false,
          );
        } else {
          _cartItems[itemId] = CartItem(
            id: itemId,
            name: name,
            price: price,
            quantity: finalQty,
            tableId: tableId,
            tableName: tableName,
            imageUrl: imageUrl,
            categoryId: categoryId,
            categoryName: categoryName,
            uom: uom,
            discountPercentage: discountPercentage,
            isKotGenerated: false,
          );
        }
      }
    }

    _updateTotalItems();
    notifyListeners();
  }

  // Enhanced method - Delete all quantities of a specific item (only if not KOT'd)
  void deleteAllOfItem(String itemId) {
    // Find the editable item for this itemId
    String? editableKey;
    for (final entry in _cartItems.entries) {
      if (entry.value.id == itemId && entry.value.canEdit) {
        editableKey = entry.key;
        break;
      }
    }

    if (editableKey != null) {
      _cartItems.remove(editableKey);
      _updateTotalItems();
      notifyListeners();
    }
  }

  // Mark items as KOT generated
  void markItemsAsKotGenerated(List<String> cartKeys, String kotNumber) {
    for (String cartKey in cartKeys) {
      if (_cartItems.containsKey(cartKey)) {
        _cartItems[cartKey]!.markAsKotGenerated(kotNumber);
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
    for (final entry in _cartItems.entries) {
      if (entry.value.id == itemId && entry.value.canEdit) {
        entry.value.specialNotes = notes;
        notifyListeners();
        debugPrint('[AnimatedCart] Updated notes for $itemId to: $notes');
        return;
      }
    }
    // Fallback/direct check
    if (_cartItems.containsKey(itemId) && _cartItems[itemId]!.canEdit) {
      _cartItems[itemId]!.specialNotes = notes;
      notifyListeners();
      debugPrint('[AnimatedCart] Updated notes via key for $itemId to: $notes');
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

  // Clear all session data when starting a new order type (table -> takeaway/phone)
  void clearAllSessionData() {
    debugPrint('[AnimatedCart] Clearing all session data for new order type');

    // Clear current cart items
    _cartItems.clear();

    // Clear table-wise carts to prevent cross-contamination
    _tableWiseCarts.clear();

    // Clear server KOT items
    _serverKotItems.clear();
    _tableWiseServerKotItems.clear();

    // Reset current table ID
    _currentTableId = null;

    // Reset total items
    _totalItems = 0;

    debugPrint('[AnimatedCart] All session data cleared');
    notifyListeners();
  }

  // Clear specific table's data after bill settlement
  void clearTableData(String tableId) {
    debugPrint('[AnimatedCart] Clearing data for table: $tableId');

    // Remove from table-wise carts
    _tableWiseCarts.remove(tableId);

    // Remove from server KOT items
    _tableWiseServerKotItems.remove(tableId);

    // Clear current cart if it's the same table
    if (_currentTableId == tableId) {
      _cartItems.clear();
      _serverKotItems.clear();
      _currentTableId = null;
      _totalItems = 0;
    }

    debugPrint('[AnimatedCart] Data cleared for table: $tableId');
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

      final imageUrl =
          (raw['imageUrl'] ?? raw['imageThumbUrl'] ?? raw['image'] ?? '')
              .toString();
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
        imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
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
            'imageUrl': item.imageUrl,
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
            imageUrl: itemData['imageUrl'],
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
  String? imageUrl;
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
    this.imageUrl,
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
