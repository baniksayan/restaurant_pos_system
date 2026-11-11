import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_pos_system/core/utils/no_emoji_formatter.dart';
import 'package:restaurant_pos_system/features/order_taking/providers/animated_cart_provider.dart';
import 'package:restaurant_pos_system/shared/services/pdf_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Emoji Filter & Sanitization', () {
    test('removeEmojis strips emojis and pictographs from text', () {
      expect(removeEmojis('Serve together 🍕🔥'), 'Serve together ');
      expect(removeEmojis('No onions! 🧅❌'), 'No onions! ');
      expect(removeEmojis('Mild spicy 🌶️'), 'Mild spicy ');
      expect(removeEmojis('Regular note without emojis'), 'Regular note without emojis');
    });

    test('noEmojiFormatter denies emoji input in text fields', () {
      const oldValue = TextEditingValue(text: 'Hello');
      const newValueWithEmoji = TextEditingValue(text: 'Hello 😊');
      final formatted = noEmojiFormatter.formatEditUpdate(oldValue, newValueWithEmoji);
      expect(formatted.text, 'Hello ');
    });
  });

  group('PDFService.generateKOT', () {
    test('generates valid PDF bytes without crashing on emojis and notes', () async {
      final items = [
        CartItem(
          id: 'item_1',
          name: 'Chicken Biryani 🍗',
          price: 250.0,
          quantity: 2,
          tableId: 'table_1',
          tableName: 'Table 1',
          specialNotes: 'Less spicy 🌶️ please',
        ),
        CartItem(
          id: 'item_2',
          name: 'Paneer Butter Masala',
          price: 220.0,
          quantity: 1,
          tableId: 'table_1',
          tableName: 'Table 1',
          specialNotes: null, // Note is null -> must NOT output '-'
        ),
      ];

      final Uint8List pdfBytes = await PDFService.generateKOT(
        items: items,
        tableId: 'table_1',
        tableName: 'Table 1',
        orderNumber: 'ORD-1001',
        orderTime: DateTime.now(),
        kotNo: 'KOT-101',
        waiterName: 'Rahul',
        specialNotes: 'Serve together with extra plates 🍽️',
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.isNotEmpty, isTrue);
      // Valid PDF files start with %PDF
      final header = String.fromCharCodes(pdfBytes.sublist(0, 4));
      expect(header, '%PDF');
    });
  });
}
