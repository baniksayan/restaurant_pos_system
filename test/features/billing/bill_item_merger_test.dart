import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_pos_system/features/billing/utils/bill_item_merger.dart';
import 'package:restaurant_pos_system/features/order_taking/providers/animated_cart_provider.dart';

void main() {
  group('BillItemMerger', () {
    test('returns empty list when input is empty', () {
      expect(BillItemMerger.mergeCartItems([]), isEmpty);
      expect(BillItemMerger.mergeDynamicCartItems([]), isEmpty);
    });

    test('returns unchanged list when all items are distinct', () {
      final items = [
        CartItem(
          id: '1',
          name: 'Chicken Biryani',
          price: 250.0,
          quantity: 2,
          tableId: 'T1',
          tableName: 'Table 1',
        ),
        CartItem(
          id: '2',
          name: 'Mutton Biryani',
          price: 350.0,
          quantity: 1,
          tableId: 'T1',
          tableName: 'Table 1',
        ),
      ];

      final merged = BillItemMerger.mergeCartItems(items);
      expect(merged.length, 2);
      expect(merged[0].name, 'Chicken Biryani');
      expect(merged[0].quantity, 2);
      expect(merged[1].name, 'Mutton Biryani');
      expect(merged[1].quantity, 1);
    });

    test('merges identical items across repeated KOTs into a single entry with summed quantity', () {
      // Scenario: KOT 1 has 1x Chicken Biryani, KOT 2 has 2x Chicken Biryani
      final items = [
        CartItem(
          id: 'kot1_item1',
          name: 'Chicken Biryani',
          price: 250.0,
          quantity: 1,
          tableId: 'T1',
          tableName: 'Table 1',
          specialNotes: 'Less spicy',
        ),
        CartItem(
          id: 'kot1_item2',
          name: 'Butter Naan',
          price: 40.0,
          quantity: 2,
          tableId: 'T1',
          tableName: 'Table 1',
        ),
        CartItem(
          id: 'kot2_item1',
          name: 'Chicken Biryani',
          price: 250.0,
          quantity: 2,
          tableId: 'T1',
          tableName: 'Table 1',
          specialNotes: 'Less spicy',
        ),
        CartItem(
          id: 'kot2_item2',
          name: 'Garlic Naan',
          price: 60.0,
          quantity: 1,
          tableId: 'T1',
          tableName: 'Table 1',
        ),
      ];

      final merged = BillItemMerger.mergeCartItems(items);

      // Expected: 3 items (Chicken Biryani x3, Butter Naan x2, Garlic Naan x1)
      expect(merged.length, 3);

      final biryani = merged.firstWhere((i) => i.name == 'Chicken Biryani');
      expect(biryani.quantity, 3);
      expect(biryani.price, 250.0);
      // Notes should be deduplicated
      expect(biryani.specialNotes, 'Less spicy');

      final butterNaan = merged.firstWhere((i) => i.name == 'Butter Naan');
      expect(butterNaan.quantity, 2);

      final garlicNaan = merged.firstWhere((i) => i.name == 'Garlic Naan');
      expect(garlicNaan.quantity, 1);
    });

    test('merges distinct special instructions without duplication', () {
      final items = [
        CartItem(
          id: '1',
          name: 'Cold Coffee',
          price: 120.0,
          quantity: 1,
          tableId: 'T1',
          tableName: 'Table 1',
          specialNotes: 'Extra sugar, less ice',
        ),
        CartItem(
          id: '2',
          name: 'Cold Coffee',
          price: 120.0,
          quantity: 1,
          tableId: 'T1',
          tableName: 'Table 1',
          specialNotes: 'Less ice, with ice cream',
        ),
      ];

      final merged = BillItemMerger.mergeCartItems(items);
      expect(merged.length, 1);
      expect(merged.first.quantity, 2);
      expect(merged.first.specialNotes, 'Extra sugar, less ice, with ice cream');
    });

    test('differentiates items with same name but different prices or UOM', () {
      final items = [
        CartItem(
          id: '1',
          name: 'Paneer Butter Masala',
          price: 200.0,
          quantity: 1,
          tableId: 'T1',
          tableName: 'Table 1',
          uom: 'Half',
        ),
        CartItem(
          id: '2',
          name: 'Paneer Butter Masala',
          price: 360.0,
          quantity: 1,
          tableId: 'T1',
          tableName: 'Table 1',
          uom: 'Full',
        ),
      ];

      final merged = BillItemMerger.mergeCartItems(items);
      expect(merged.length, 2);
      expect(merged[0].uom, 'Half');
      expect(merged[0].quantity, 1);
      expect(merged[1].uom, 'Full');
      expect(merged[1].quantity, 1);
    });

    test('preserves initial item order', () {
      final items = [
        CartItem(id: '1', name: 'Starter A', price: 100, quantity: 1, tableId: 'T1', tableName: 'Table 1'),
        CartItem(id: '2', name: 'Main B', price: 200, quantity: 1, tableId: 'T1', tableName: 'Table 1'),
        CartItem(id: '3', name: 'Starter A', price: 100, quantity: 2, tableId: 'T1', tableName: 'Table 1'),
      ];

      final merged = BillItemMerger.mergeCartItems(items);
      expect(merged.length, 2);
      expect(merged[0].name, 'Starter A');
      expect(merged[0].quantity, 3);
      expect(merged[1].name, 'Main B');
      expect(merged[1].quantity, 1);
    });

    test('mergeDynamicCartItems correctly merges heterogeneous list of objects', () {
      final dynamicList = [
        {'name': 'Chai', 'price': 20.0, 'quantity': 1, 'specialNotes': 'Strong'},
        {'name': 'Chai', 'price': 20.0, 'quantity': 2, 'specialNotes': 'Strong'},
      ];

      final merged = BillItemMerger.mergeDynamicCartItems(
        dynamicList.map((m) => _TestItem(
          name: m['name'] as String,
          price: m['price'] as double,
          quantity: m['quantity'] as int,
          specialNotes: m['specialNotes'] as String?,
        )).toList(),
      );

      expect(merged.length, 1);
      expect(merged.first.name, 'Chai');
      expect(merged.first.quantity, 3);
      expect(merged.first.specialNotes, 'Strong');
    });
  });
}

class _TestItem {
  final String name;
  final double price;
  final int quantity;
  final String? specialNotes;

  _TestItem({
    required this.name,
    required this.price,
    required this.quantity,
    this.specialNotes,
  });
}
