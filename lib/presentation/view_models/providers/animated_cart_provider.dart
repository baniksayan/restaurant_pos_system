import 'package:flutter/material.dart';

import '../../../data/local/hive_service.dart';
import '../../../services/api_service.dart';
import '../../../data/models/order_detail_api_response_model.dart';

class AnimatedCartProvider extends ChangeNotifier {
  final Map<String, CartItem> _cartItems = {};
  final Map<String, Map<String, CartItem>> _tableWiseCarts =
      {}; // Store cart per table
  final Map<String, List<OrderDetailList>> _tableWiseServerKotItems = 
      {}; // Store server KOT items per table
  int _totalItems = 0;
  String? _currentTableId;
  List<OrderDetailList> _serverKotItems = []; // Current table's server KOT items

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
  Future<void> switchToTable(
    String tableId,
    String tableName, {
    String? orderId,
  }) async {
    // Save current cart state and server KOT items if we have a current table
    if (_currentTableId != null) {
      _tableWiseCarts[_currentTableId!] = Map.from(_cartItems);
      _tableWiseServerKotItems[_currentTableId!] = List.from(_serverKotItems);
    }

    // Load the target table's cart and server KOT items
    _currentTableId = tableId;
    if (_tableWiseCarts.containsKey(tableId)) {
      _cartItems.clear();
      _cartItems.addAll(_tableWiseCarts[tableId]!);
    } else {
      _cartItems.clear();
    }
    
    // Load table-specific server KOT items
    if (_tableWiseServerKotItems.containsKey(tableId)) {
      _serverKotItems = List.from(_tableWiseServerKotItems[tableId]!);
    } else {
      _serverKotItems.clear();
    }

    // Sync with server state if orderId is provided
    if (orderId != null && orderId.isNotEmpty) {
      await _syncWithServerState(orderId);
    }

    _updateTotalItems();
    notifyListeners();
  }

  // Sync local cart state with server state to handle KOT status correctly
  Future<void> _syncWithServerState(String orderId) async {
    try {
      final authToken = HiveService.getAuthToken();
      if (authToken.isEmpty) return;

      final orderDetails = await ApiService.getOrderDetailById(
        token: authToken,
        orderId: orderId,
      );

      if (orderDetails?.isSuccess == true &&
          orderDetails?.data?.isNotEmpty == true) {
        final serverItems = orderDetails!.data!.first.orderDetailList ?? [];

        // Create a map to track server items by product ID
        final Map<String, OrderDetailList> serverItemsMap = {};
        for (final item in serverItems) {
          if (item.productId != null) {
            serverItemsMap[item.productId!] = item;
          }
        }

        // Separate KOT'd and non-KOT'd items from server
        final List<OrderDetailList> kotItems = [];
        final Map<String, CartItem> updatedCart = {};

        for (final serverItem in serverItems) {
          final bool isKotGenerated =
              serverItem.kotNo != null &&
              serverItem.kotNo!.isNotEmpty &&
              serverItem.kotId != null &&
              serverItem.kotId!.isNotEmpty;

          if (isKotGenerated) {
            // This item is KOT'd - add to server KOT items for display
            kotItems.add(serverItem);
          }
        }

        // Update local cart - keep ALL items but sync their KOT status correctly
        for (final cartItem in _cartItems.values) {
          final serverItem = serverItemsMap[cartItem.id];

          if (serverItem != null) {
            // Item exists on server - sync KOT status from server
            final bool isKotGenerated =
                serverItem.kotNo != null &&
                serverItem.kotNo!.isNotEmpty &&
                serverItem.kotId != null &&
                serverItem.kotId!.isNotEmpty;

            // Keep ALL items in cart but with correct KOT status from server
            updatedCart[cartItem.id] = CartItem(
              id: cartItem.id,
              name: cartItem.name,
              price: cartItem.price,
              quantity: serverItem.productQty?.toInt() ?? cartItem.quantity,
              tableId: cartItem.tableId,
              tableName: cartItem.tableName,
              specialNotes: cartItem.specialNotes,
              categoryId: cartItem.categoryId,
              categoryName: cartItem.categoryName,
              uom: cartItem.uom,
              discountPercentage: cartItem.discountPercentage,
              isKotGenerated: isKotGenerated,
              kotNumber: isKotGenerated ? serverItem.kotNo : null,
              kotGeneratedAt: isKotGenerated ? DateTime.now() : null,
            );
          } else {
            // Item doesn't exist on server yet - keep as new item
            updatedCart[cartItem.id] = cartItem;
          }
        }

        // Add any server items that aren't in local cart
        for (final serverItem in serverItems) {
          if (serverItem.productId != null && 
              !updatedCart.containsKey(serverItem.productId!)) {
            final bool isKotGenerated =
                serverItem.kotNo != null &&
                serverItem.kotNo!.isNotEmpty &&
                serverItem.kotId != null &&
                serverItem.kotId!.isNotEmpty;

            // Add ALL server items to maintain consistency
            updatedCart[serverItem.productId!] = CartItem(
              id: serverItem.productId!,
              name: serverItem.productName ?? 'Unknown Item',
              price: (serverItem.itemPrice ?? 0).toDouble(),
              quantity: serverItem.productQty?.toInt() ?? 1,
              tableId: _currentTableId ?? '',
              tableName: '',
              specialNotes: serverItem.instruction,
              categoryId: null, // Not available in OrderDetailList
              categoryName: null, // Not available in OrderDetailList  
              uom: serverItem.uom,
              discountPercentage: (serverItem.discountPerc ?? 0).toDouble(),
              isKotGenerated: isKotGenerated,
              kotNumber: isKotGenerated ? serverItem.kotNo : null,
              kotGeneratedAt: isKotGenerated ? DateTime.now() : null,
            );
          }
        }

        // Update state - now _serverKotItems is only for display purposes
        _serverKotItems = kotItems;
        _cartItems.clear();
        _cartItems.addAll(updatedCart);

        // Update table-wise cache for both cart and server KOT items
        if (_currentTableId != null) {
          _tableWiseCarts[_currentTableId!] = Map.from(_cartItems);
          _tableWiseServerKotItems[_currentTableId!] = List.from(_serverKotItems);
        }
      }
    } catch (e) {
      debugPrint('Error syncing with server state: $e');
      // Continue with local state if server sync fails
    }
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
      switchToTable(tableId, tableName);
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
