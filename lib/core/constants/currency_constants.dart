import 'package:restaurant_pos_system/data/local/hive_service.dart';

class CurrencyConstants {
  CurrencyConstants._();

  /// Used only until the real company currency has loaded — on first ever
  /// launch, or if Setting/GetCompanyInfo has never succeeded for this
  /// device. Every other case uses the tenant's actual currency symbol from
  /// CurrencyMaster (see CompanyInfo/HiveService.saveCompanyInfo), not this.
  /// Built from its character code rather than a literal so the source
  /// never has to escape a bare currency sign inside a Dart string.
  static final String _fallbackSymbol = String.fromCharCode(0x24); // '$'

  static String _symbol = _fallbackSymbol;

  /// Currency symbol for the logged-in company — e.g. '₹', '$', '€'. Read
  /// freely anywhere a price is shown; it updates itself once the real
  /// value is known, so existing '${CurrencyConstants.symbol}...' call
  /// sites need no changes.
  static String get symbol => _symbol;

  /// Sets the live symbol once Setting/GetCompanyInfo returns one. Ignores
  /// a blank/missing value rather than overwriting a good symbol with
  /// nothing — a transient API hiccup should not blank out prices that were
  /// displaying correctly a moment ago.
  static void setSymbol(String? newSymbol) {
    if (newSymbol != null && newSymbol.trim().isNotEmpty) {
      _symbol = newSymbol.trim();
    }
  }

  /// Restores whatever symbol was cached from the last successful
  /// Setting/GetCompanyInfo call. Call this once at app start (before the
  /// first frame, if possible) so a warm start shows the right currency
  /// immediately rather than the fallback while a fresh fetch is in flight.
  static void loadFromCache() {
    final cached = HiveService.getCompanyInfo();
    final cachedSymbol = cached?['currencySymbol'] as String?;
    setSymbol(cachedSymbol);
  }

  /// Format any number into the standard currency string (e.g. ₹12.50)
  static String format(num amount) => '$_symbol${amount.toStringAsFixed(2)}';
}

/// Convenience extension for currency formatting on numeric values
extension CurrencyFormatting on num {
  String toCurrency() => CurrencyConstants.format(this);
}
