import 'package:restaurant_pos_system/data/local/hive_service.dart';

/// Available comma formatting styles for numbers and currencies.
enum CurrencyFormatStyle {
  /// Indian numbering system: 2,03,94,845.00 (lakhs & crores)
  indian,

  /// International / US numbering system: 20,394,845.00 (thousands & millions)
  international,
}

/// Centralized currency and number formatting utility.
///
/// Features:
/// - Defaults to Indian comma grouping (e.g. ₹2,03,94,845.00 / ₹2,005.00).
/// - Easily switchable to International / US formatting via [setStyle].
/// - Auto-syncs with tenant company currency symbol from Hive cache / API.
/// - Comprehensive helpers for integer, decimal, compact, and symbol-less outputs.
class CurrencyConstants {
  CurrencyConstants._();

  static final String _fallbackSymbol = String.fromCharCode(0x24); // '$'
  static String _symbol = _fallbackSymbol;
  static CurrencyFormatStyle _style = CurrencyFormatStyle.indian;

  /// Currency symbol for the logged-in company — e.g. '₹', '$', '€'.
  static String get symbol => _symbol;

  /// Active formatting style (default: [CurrencyFormatStyle.indian]).
  static CurrencyFormatStyle get style => _style;

  /// Sets the live symbol once Setting/GetCompanyInfo returns one.
  static void setSymbol(String? newSymbol) {
    if (newSymbol != null && newSymbol.trim().isNotEmpty) {
      _symbol = newSymbol.trim();
    }
  }

  /// Sets the active formatting style across the entire app.
  static void setStyle(CurrencyFormatStyle style) {
    _style = style;
  }

  /// Restores cached company currency symbol from local storage.
  static void loadFromCache() {
    final cached = HiveService.getCompanyInfo();
    final cachedSymbol = cached?['currencySymbol'] as String?;
    setSymbol(cachedSymbol);
  }

  /// Formats any numeric amount into standard localized currency string.
  ///
  /// Examples (with default Indian style):
  /// - `format(20394845)` -> "₹2,03,94,845.00"
  /// - `format(20394845, decimalDigits: 0)` -> "₹2,03,94,845"
  /// - `format(2005.5)` -> "₹2,005.50"
  /// - `format(2005, showSymbol: false)` -> "2,005.00"
  /// - `format(-150.5)` -> "-₹150.50"
  static String format(
    num? amount, {
    int decimalDigits = 2,
    bool showSymbol = true,
    bool trimZeroDecimals = false,
    CurrencyFormatStyle? overrideStyle,
  }) {
    if (amount == null) return showSymbol ? '$_symbol 0.00' : '0.00';

    final activeStyle = overrideStyle ?? _style;
    final isNegative = amount < 0;
    final absAmount = amount.abs();

    String formattedNumber;
    switch (activeStyle) {
      case CurrencyFormatStyle.indian:
        formattedNumber = _formatIndian(absAmount, decimalDigits);
        break;
      case CurrencyFormatStyle.international:
        formattedNumber = _formatInternational(absAmount, decimalDigits);
        break;
    }

    if (trimZeroDecimals && decimalDigits > 0) {
      formattedNumber = _trimZeroDecimals(formattedNumber);
    }

    if (showSymbol) {
      return isNegative
          ? '-$_symbol$formattedNumber'
          : '$_symbol$formattedNumber';
    } else {
      return isNegative ? '-$formattedNumber' : formattedNumber;
    }
  }

  /// Formats amount without the currency symbol (e.g. "2,03,94,845.00").
  static String formatWithoutSymbol(
    num? amount, {
    int decimalDigits = 2,
    bool trimZeroDecimals = false,
    CurrencyFormatStyle? overrideStyle,
  }) =>
      format(
        amount,
        decimalDigits: decimalDigits,
        showSymbol: false,
        trimZeroDecimals: trimZeroDecimals,
        overrideStyle: overrideStyle,
      );

  /// Formats amount as an integer with no decimal places (e.g. "₹2,03,94,845").
  static String formatInt(
    num? amount, {
    bool showSymbol = true,
    CurrencyFormatStyle? overrideStyle,
  }) =>
      format(
        amount,
        decimalDigits: 0,
        showSymbol: showSymbol,
        overrideStyle: overrideStyle,
      );

  /// Formats large numbers compactly (e.g. ₹2.04 Cr, ₹1.84 L, ₹12.5 k).
  static String formatCompact(
    num? amount, {
    bool showSymbol = true,
    CurrencyFormatStyle? overrideStyle,
  }) {
    if (amount == null) return showSymbol ? '$_symbol 0' : '0';
    final activeStyle = overrideStyle ?? _style;
    final isNegative = amount < 0;
    final abs = amount.abs();

    String result;
    if (activeStyle == CurrencyFormatStyle.indian) {
      if (abs >= 10000000) {
        result = '${(abs / 10000000).toStringAsFixed(2)} Cr';
      } else if (abs >= 100000) {
        result = '${(abs / 100000).toStringAsFixed(2)} L';
      } else if (abs >= 1000) {
        result = '${(abs / 1000).toStringAsFixed(1)} k';
      } else {
        result = abs.toStringAsFixed(0);
      }
    } else {
      if (abs >= 1000000000) {
        result = '${(abs / 1000000000).toStringAsFixed(2)} B';
      } else if (abs >= 1000000) {
        result = '${(abs / 1000000).toStringAsFixed(2)} M';
      } else if (abs >= 1000) {
        result = '${(abs / 1000).toStringAsFixed(1)} k';
      } else {
        result = abs.toStringAsFixed(0);
      }
    }

    result = _trimZeroDecimals(result);
    return showSymbol
        ? (isNegative ? '-$_symbol$result' : '$_symbol$result')
        : (isNegative ? '-$result' : result);
  }

  /// Parses a formatted currency string back to a numeric double value.
  static double parse(String? formatted) {
    if (formatted == null || formatted.trim().isEmpty) return 0.0;
    final cleaned = formatted
        .replaceAll(_symbol, '')
        .replaceAll('₹', '')
        .replaceAll(r'$', '')
        .replaceAll('€', '')
        .replaceAll('£', '')
        .replaceAll('Rs.', '')
        .replaceAll('Rs', '')
        .replaceAll(',', '')
        .trim();
    return double.tryParse(cleaned) ?? 0.0;
  }

  // ────────────────────────── Internal Helpers ──────────────────────────

  /// Formats integer portion according to the Indian numbering system (3, 2, 2, ...).
  static String _formatIndian(num amount, int decimalDigits) {
    final fixedStr = amount.toStringAsFixed(decimalDigits);
    final parts = fixedStr.split('.');
    final intPart = parts[0];
    final decPart = parts.length > 1 ? '.${parts[1]}' : '';

    if (intPart.length <= 3) {
      return '$intPart$decPart';
    }

    final lastThree = intPart.substring(intPart.length - 3);
    final rest = intPart.substring(0, intPart.length - 3);

    final buffer = StringBuffer();
    for (int i = 0; i < rest.length; i++) {
      final remaining = rest.length - i;
      buffer.write(rest[i]);
      if (remaining > 1 && remaining % 2 == 1) {
        buffer.write(',');
      }
    }
    buffer.write(',');
    buffer.write(lastThree);
    buffer.write(decPart);

    return buffer.toString();
  }

  /// Formats integer portion according to International system (3, 3, 3, ...).
  static String _formatInternational(num amount, int decimalDigits) {
    final fixedStr = amount.toStringAsFixed(decimalDigits);
    final parts = fixedStr.split('.');
    final intPart = parts[0];
    final decPart = parts.length > 1 ? '.${parts[1]}' : '';

    final buffer = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      final remaining = intPart.length - i;
      buffer.write(intPart[i]);
      if (remaining > 1 && (remaining - 1) % 3 == 0) {
        buffer.write(',');
      }
    }
    buffer.write(decPart);

    return buffer.toString();
  }

  static String _trimZeroDecimals(String val) {
    if (val.contains('.')) {
      var trimmed = val.replaceAll(RegExp(r'0+$'), '');
      if (trimmed.endsWith('.')) {
        trimmed = trimmed.substring(0, trimmed.length - 1);
      }
      return trimmed;
    }
    return val;
  }
}

/// Convenience alias for [CurrencyConstants].
typedef CurrencyFormatter = CurrencyConstants;

/// Extension on [num] for standard currency formatting.
extension CurrencyFormatting on num {
  String toCurrency({
    int decimalDigits = 2,
    bool showSymbol = true,
    bool trimZeroDecimals = false,
    CurrencyFormatStyle? overrideStyle,
  }) =>
      CurrencyConstants.format(
        this,
        decimalDigits: decimalDigits,
        showSymbol: showSymbol,
        trimZeroDecimals: trimZeroDecimals,
        overrideStyle: overrideStyle,
      );

  String toCurrencyWithoutSymbol({
    int decimalDigits = 2,
    bool trimZeroDecimals = false,
    CurrencyFormatStyle? overrideStyle,
  }) =>
      CurrencyConstants.formatWithoutSymbol(
        this,
        decimalDigits: decimalDigits,
        trimZeroDecimals: trimZeroDecimals,
        overrideStyle: overrideStyle,
      );

  String toCurrencyInt({
    bool showSymbol = true,
    CurrencyFormatStyle? overrideStyle,
  }) =>
      CurrencyConstants.formatInt(
        this,
        showSymbol: showSymbol,
        overrideStyle: overrideStyle,
      );
}

/// Extension on nullable [num?] for standard currency formatting.
extension NullableCurrencyFormatting on num? {
  String toCurrency({
    int decimalDigits = 2,
    bool showSymbol = true,
    bool trimZeroDecimals = false,
    CurrencyFormatStyle? overrideStyle,
  }) =>
      CurrencyConstants.format(
        this,
        decimalDigits: decimalDigits,
        showSymbol: showSymbol,
        trimZeroDecimals: trimZeroDecimals,
        overrideStyle: overrideStyle,
      );

  String toCurrencyWithoutSymbol({
    int decimalDigits = 2,
    bool trimZeroDecimals = false,
    CurrencyFormatStyle? overrideStyle,
  }) =>
      CurrencyConstants.formatWithoutSymbol(
        this,
        decimalDigits: decimalDigits,
        trimZeroDecimals: trimZeroDecimals,
        overrideStyle: overrideStyle,
      );

  String toCurrencyInt({
    bool showSymbol = true,
    CurrencyFormatStyle? overrideStyle,
  }) =>
      CurrencyConstants.formatInt(
        this,
        showSymbol: showSymbol,
        overrideStyle: overrideStyle,
      );

  /// Returns formatted currency or a fallback [placeholder] (e.g. '-') if null.
  String toCurrencyOrDash({
    String placeholder = '-',
    int decimalDigits = 2,
    bool showSymbol = true,
    bool trimZeroDecimals = false,
    CurrencyFormatStyle? overrideStyle,
  }) {
    if (this == null) return placeholder;
    return toCurrency(
      decimalDigits: decimalDigits,
      showSymbol: showSymbol,
      trimZeroDecimals: trimZeroDecimals,
      overrideStyle: overrideStyle,
    );
  }
}
