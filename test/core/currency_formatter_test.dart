import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_pos_system/core/constants/currency_constants.dart';
import 'package:restaurant_pos_system/core/utils/currency_formatter.dart';

void main() {
  group('CurrencyFormatter & CurrencyConstants Tests', () {
    setUp(() {
      CurrencyConstants.setSymbol('₹');
      CurrencyConstants.setStyle(CurrencyFormatStyle.indian);
    });

    test('Indian format correctly groups numbers (₹2,03,94,845)', () {
      expect(CurrencyConstants.format(20394845), '₹2,03,94,845.00');
      expect(CurrencyConstants.format(20394845, decimalDigits: 0), '₹2,03,94,845');
      expect(CurrencyConstants.formatInt(20394845), '₹2,03,94,845');
      expect(20394845.toCurrency(), '₹2,03,94,845.00');
      expect(20394845.toCurrencyInt(), '₹2,03,94,845');
    });

    test('Indian format for various magnitudes', () {
      expect(CurrencyConstants.format(0), '₹0.00');
      expect(CurrencyConstants.format(5), '₹5.00');
      expect(CurrencyConstants.format(99), '₹99.00');
      expect(CurrencyConstants.format(100), '₹100.00');
      expect(CurrencyConstants.format(1000), '₹1,000.00');
      expect(CurrencyConstants.format(10000), '₹10,000.00');
      expect(CurrencyConstants.format(100000), '₹1,00,000.00');
      expect(CurrencyConstants.format(1000000), '₹10,00,000.00');
      expect(CurrencyConstants.format(10000000), '₹1,00,00,000.00');
    });

    test('Handles negative numbers and decimals properly', () {
      expect(CurrencyConstants.format(-150.5), '-₹150.50');
      expect(CurrencyConstants.format(-1234567.89), '-₹12,34,567.89');
      expect(CurrencyConstants.formatWithoutSymbol(1234567.89), '12,34,567.89');
      expect(1234567.89.toCurrencyWithoutSymbol(), '12,34,567.89');
    });

    test('Switching style to International changes grouping to standard 3-digit commas', () {
      CurrencyConstants.setStyle(CurrencyFormatStyle.international);
      expect(CurrencyConstants.format(20394845), '₹20,394,845.00');
      expect(CurrencyConstants.format(1000000), '₹1,000,000.00');
      expect(CurrencyConstants.format(100000), '₹100,000.00');
    });

    test('Changing currency symbol updates format output', () {
      CurrencyConstants.setSymbol('\$');
      CurrencyConstants.setStyle(CurrencyFormatStyle.international);
      expect(CurrencyConstants.format(1234567.89), '\$1,234,567.89');

      CurrencyConstants.setSymbol('€');
      expect(CurrencyConstants.format(500), '€500.00');
    });

    test('Compact format handles Lakhs and Crores in Indian mode', () {
      CurrencyConstants.setStyle(CurrencyFormatStyle.indian);
      expect(CurrencyConstants.formatCompact(20394845), '₹2.04 Cr');
      expect(CurrencyConstants.formatCompact(184350), '₹1.84 L');
      expect(CurrencyConstants.formatCompact(12500), '₹12.5 k');
      expect(CurrencyConstants.formatCompact(500), '₹500');
    });

    test('Compact format handles Millions and Billions in International mode', () {
      CurrencyConstants.setStyle(CurrencyFormatStyle.international);
      expect(CurrencyConstants.formatCompact(20394845), '₹20.39 M');
      expect(CurrencyConstants.formatCompact(1500000000), '₹1.50 B');
      expect(CurrencyConstants.formatCompact(12500), '₹12.5 k');
    });

    test('Null safety extensions return placeholder for null values', () {
      num? nullNum;
      expect(nullNum.toCurrencyOrDash(), '-');
      expect(nullNum.toCurrencyOrDash(placeholder: 'N/A'), 'N/A');
      num? validNum = 450;
      expect(validNum.toCurrencyOrDash(), '₹450.00');
    });
  });
}
