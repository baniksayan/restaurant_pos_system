import 'package:restaurant_pos_system/data/models/bill_generation_models.dart';

/// One tender taken against a bill — "₹200 cash", "₹100 UPI".
///
/// A bill can be settled with several of these at once: the API's SavePayment
/// accepts a list and SP_SavePayment writes one Payment row per entry, each
/// with its own mode. Splitting a bill across cash and UPI is therefore a
/// single call and a single receipt, not two sequential payments.
class TenderLine {
  /// Matches the `modeId` sent to SavePayment: 1 cash, 2 card, 3 UPI.
  final int modeId;

  /// 'cash' | 'card' | 'upi' — the key the picker and icons use.
  final String method;

  final double amount;

  /// Transaction reference for card/UPI. Empty for cash.
  final String refId;

  /// Cash handed over, when this is a cash line and the customer overpaid.
  /// Only cash produces change, so only a cash line can carry a return.
  final double cashTendered;

  const TenderLine({
    required this.modeId,
    required this.method,
    required this.amount,
    this.refId = '',
    this.cashTendered = 0,
  });

  bool get isCash => method == 'cash';

  /// Change owed on this line. Never negative, and never non-zero for a
  /// non-cash tender.
  double get returnAmount {
    if (!isCash) return 0;
    final change = cashTendered - amount;
    return change > 0 ? change : 0;
  }

  String get label => switch (method) {
    'cash' => 'Cash',
    'card' => 'Card',
    'upi' => 'UPI',
    _ => method.toUpperCase(),
  };

  /// The shape SavePayment expects. `status` defaults to settled (2), which
  /// is what the billing counter records for a completed tender.
  PaymentDetail toPaymentDetail() => PaymentDetail(
    paymentAmount: amount,
    modeId: modeId,
    refId: refId,
    cardNo: '',
    returnAmt: returnAmount,
  );
}
