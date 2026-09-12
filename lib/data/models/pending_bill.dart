/// A bill that has been generated but not yet fully settled.
///
/// Backed by Order/GetBillForReprint, which returns every bill in a date
/// range along with its payment state. A bill can sit unpaid indefinitely —
/// billing deliberately allows "bill now, pay later" — so these need a home
/// of their own rather than being reachable only from the table that produced
/// them.
class PendingBill {
  final String billId;
  final String billNo;
  final String orderNo;
  final String customerName;
  final double amount;
  final int itemCount;

  /// 0 = not paid, 1 = partially paid, 2 = fully paid.
  final int isPaid;

  /// Server-rendered label: "Not Paid" / "Partially Paid" / "Paid".
  final String paymentStatus;

  final DateTime? billDate;

  const PendingBill({
    required this.billId,
    required this.billNo,
    required this.orderNo,
    required this.customerName,
    required this.amount,
    required this.itemCount,
    required this.isPaid,
    required this.paymentStatus,
    this.billDate,
  });

  /// Anything not fully settled still needs collecting.
  bool get isOutstanding => isPaid != 2;

  bool get isPartiallyPaid => isPaid == 1;

  factory PendingBill.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0;
      return 0;
    }

    return PendingBill(
      billId: (json['billId'] ?? '').toString(),
      billNo: (json['billNo'] ?? '').toString(),
      orderNo: (json['orderNo'] ?? '').toString(),
      customerName: (json['customerName'] ?? '').toString().trim(),
      amount: toDouble(json['billAmountInclTax']),
      itemCount: (json['itemCount'] is num) ? json['itemCount'] as int : 0,
      isPaid: (json['isPaid'] is num) ? (json['isPaid'] as num).toInt() : 0,
      paymentStatus: (json['paymentStatus'] ?? '').toString(),
      billDate: DateTime.tryParse((json['billDate'] ?? '').toString()),
    );
  }
}
