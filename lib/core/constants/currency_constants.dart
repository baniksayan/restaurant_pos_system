class CurrencyConstants {
  CurrencyConstants._();

  /// Global currency symbol used across the app for price displays.
  /// Set to USD dollar sign as requested.
  static const String symbol = '\u0024'; // '$'

  /// Format any number into the standard currency string (e.g. $12.50)
  static String format(num amount) => '$symbol${amount.toStringAsFixed(2)}';
}

/// Convenience extension for currency formatting on numeric values
extension CurrencyFormatting on num {
  String toCurrency() => CurrencyConstants.format(this);
}
