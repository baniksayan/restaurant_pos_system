import 'package:restaurant_pos_system/features/order_taking/providers/animated_cart_provider.dart';

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
      final String name = (item.name as String? ?? 'Item').trim();
      final double price = (item.price as num? ?? 0).toDouble();
      final int quantity = (item.quantity as num? ?? 1).toInt();
      final String? specialNotes = (item.specialNotes as String?);
      final String? uom = (item is CartItem ? item.uom : null);
      final String tableId =
          item is CartItem ? item.tableId : (item.tableId?.toString() ?? '');
      final String tableName =
          item is CartItem ? item.tableName : (item.tableName?.toString() ?? '');
      final String id =
          item is CartItem ? item.id : (item.id?.toString() ?? name);

      final key = '${name.toLowerCase()}##${price.toStringAsFixed(2)}##${(uom ?? '').toLowerCase()}';

      if (!map.containsKey(key)) {
        map[key] = CartItem(
          id: id,
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
