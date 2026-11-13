import 'package:restaurant_pos_system/features/order_taking/providers/animated_cart_provider.dart';
import 'package:restaurant_pos_system/data/models/bill_details_response.dart'
    show BillOrderDetails;

/// Helper utility to merge identical items for the final order and bill summary,
/// while allowing KOT items to remain separated internally for kitchen-related tracking.
class BillItemMerger {
  /// Deduplicates and merges notes/special instructions from multiple orders of the same item.
  /// Example: 'Extra Spicy' + 'Extra Spicy' -> 'Extra Spicy'
  /// Example: 'Less oil' + 'Extra spicy' -> 'Less oil, Extra spicy'
  static String? mergeNotes(String? note1, String? note2) {
    final n1 = note1?.trim();
    final n2 = note2?.trim();

    if (n1 == null || n1.isEmpty) {
      return (n2 == null || n2.isEmpty) ? null : n2;
    }
    if (n2 == null || n2.isEmpty) {
      return n1;
    }

    final parts1 = n1
        .split(RegExp(r'[,;]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty);
    final parts2 = n2
        .split(RegExp(r'[,;]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty);

    final distinctPhrases = <String>[];
    final seenLower = <String>{};

    for (final part in [...parts1, ...parts2]) {
      final lower = part.toLowerCase();
      if (!seenLower.contains(lower)) {
        seenLower.add(lower);
        distinctPhrases.add(part);
      }
    }

    return distinctPhrases.isEmpty ? null : distinctPhrases.join(', ');
  }

  /// Generates a unique identity key for a [CartItem] based on product name,
  /// rate/price, and unit of measure.
  static String cartItemKey(CartItem item) {
    final nameKey = item.name.trim().toLowerCase();
    final priceKey = item.price.toStringAsFixed(2);
    final uomKey = (item.uom ?? '').trim().toLowerCase();
    return '$nameKey##$priceKey##$uomKey';
  }

  /// Merges a list of [CartItem]s so that repeated identical items
  /// are combined into a single entry with summed quantities and merged notes.
  /// The original insertion order of distinct items is preserved.
  static List<CartItem> mergeCartItems(List<CartItem> items) {
    if (items.isEmpty) return const [];

    final Map<String, CartItem> map = {};

    for (final item in items) {
      final key = cartItemKey(item);
      if (!map.containsKey(key)) {
        map[key] = item.copyWith();
      } else {
        final existing = map[key]!;
        final newQuantity = existing.quantity + item.quantity;
        final mergedNotes = mergeNotes(existing.specialNotes, item.specialNotes);

        map[key] = existing.copyWith(
          quantity: newQuantity,
          specialNotes: mergedNotes,
          imageUrl: existing.imageUrl ?? item.imageUrl,
          categoryId: existing.categoryId ?? item.categoryId,
          categoryName: existing.categoryName ?? item.categoryName,
          uom: existing.uom ?? item.uom,
          discountPercentage:
              existing.discountPercentage ?? item.discountPercentage,
          isKotGenerated: existing.isKotGenerated || item.isKotGenerated,
        );
      }
    }

    return map.values.toList();
  }

  /// Duck-typed merger for dynamic lists of items (e.g., used by PDF generation
  /// or legacy widgets accepting `List<dynamic>`).
  static List<dynamic> mergeDynamicCartItems(List<dynamic> items) {
    if (items.isEmpty) return const [];

    // If every item is already a CartItem, use the strongly-typed merger.
    if (items.every((i) => i is CartItem)) {
      return mergeCartItems(items.cast<CartItem>());
    }

    final Map<String, CartItem> map = {};

    for (final item in items) {
      String name = 'Item';
      double price = 0.0;
      int quantity = 1;
      String? specialNotes;
      String? uom;
      String tableId = '';
      String tableName = '';
      String id = '';

      if (item is CartItem) {
        name = item.name.trim().isNotEmpty ? item.name.trim() : 'Item';
        price = item.price;
        quantity = item.quantity;
        specialNotes = item.specialNotes;
        uom = item.uom;
        tableId = item.tableId;
        tableName = item.tableName;
        id = item.id;
      } else if (item is BillOrderDetails) {
        name = item.itemName.trim().isNotEmpty ? item.itemName.trim() : 'Item';
        price = item.itemPrice;
        quantity = item.orderQty.round();
        if (quantity < 1) quantity = 1;
        uom = item.uom.isNotEmpty ? item.uom : null;
        id = item.orderId;
      } else if (item is Map) {
        name = (item['itemName'] ?? item['productName'] ?? item['name'] ?? 'Item').toString().trim();
        final rawPrice = item['itemPrice'] ?? item['price'] ?? item['rate'];
        if (rawPrice is num) {
          price = rawPrice.toDouble();
        } else if (rawPrice != null) {
          price = double.tryParse(rawPrice.toString().trim()) ?? 0.0;
        }
        final rawQty = item['orderQty'] ?? item['productQty'] ?? item['quantity'] ?? item['qty'];
        if (rawQty is num) {
          quantity = rawQty.toInt();
        } else if (rawQty != null) {
          quantity = int.tryParse(rawQty.toString().trim()) ?? 1;
        }
        if (quantity < 1) quantity = 1;
        specialNotes = item['specialNotes']?.toString();
        uom = (item['uom'] ?? item['unit'])?.toString();
        tableId = (item['tableId'] ?? '').toString();
        tableName = (item['tableName'] ?? '').toString();
        id = (item['orderId'] ?? item['id'] ?? name).toString();
      } else {
        try {
          name = ((item as dynamic).name ?? (item as dynamic).itemName ?? 'Item').toString().trim();
        } catch (_) {}
        try {
          final p = (item as dynamic).price ?? (item as dynamic).itemPrice;
          if (p is num) {
            price = p.toDouble();
          } else if (p != null) {
            price = double.tryParse(p.toString().trim()) ?? 0.0;
          }
        } catch (_) {}
        try {
          final q = (item as dynamic).quantity ?? (item as dynamic).orderQty ?? (item as dynamic).productQty;
          if (q is num) {
            quantity = q.toInt();
          } else if (q != null) {
            quantity = int.tryParse(q.toString().trim()) ?? 1;
          }
        } catch (_) {}
        if (quantity < 1) quantity = 1;
        try {
          specialNotes = (item as dynamic).specialNotes as String?;
        } catch (_) {}
        try {
          uom = (item as dynamic).uom as String?;
        } catch (_) {}
        try {
          tableId = ((item as dynamic).tableId ?? '').toString();
        } catch (_) {}
        try {
          tableName = ((item as dynamic).tableName ?? '').toString();
        } catch (_) {}
        try {
          id = ((item as dynamic).id ?? name).toString();
        } catch (_) {}
      }

      final key = '${name.toLowerCase()}##${price.toStringAsFixed(2)}##${(uom ?? '').toLowerCase()}';

      if (!map.containsKey(key)) {
        map[key] = CartItem(
          id: id.isNotEmpty ? id : name,
          name: name,
          price: price,
          quantity: quantity,
          tableId: tableId,
          tableName: tableName,
          specialNotes: specialNotes,
          uom: uom,
        );
      } else {
        final existing = map[key]!;
        final newQty = existing.quantity + quantity;
        final mergedNotes = mergeNotes(existing.specialNotes, specialNotes);

        map[key] = existing.copyWith(
          quantity: newQty,
          specialNotes: mergedNotes,
        );
      }
    }

    return map.values.toList();
  }
}

/// Convenience top-level functions matching common usage.
List<CartItem> mergeCartItems(List<CartItem> items) =>
    BillItemMerger.mergeCartItems(items);

List<dynamic> mergeDynamicCartItems(List<dynamic> items) =>
    BillItemMerger.mergeDynamicCartItems(items);
