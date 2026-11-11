import 'package:restaurant_pos_system/core/utils/date_time_formatter.dart';
import 'package:restaurant_pos_system/data/local/hive_service.dart';

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
  final double paidAmount;
  final double balanceAmount;
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
    this.paidAmount = 0,
    this.balanceAmount = 0,
    required this.itemCount,
    required this.isPaid,
    required this.paymentStatus,
    this.billDate,
  });

  /// Anything not fully settled still needs collecting.
  bool get isOutstanding => isPaid != 2;

  bool get isPartiallyPaid => isPaid == 1;

  /// True only when the timestamp has non-zero hour/minute/second (real time),
  /// preventing display of midnight default '0:00'.
  bool get hasTime =>
      billDate != null &&
      (billDate!.hour != 0 || billDate!.minute != 0 || billDate!.second != 0);

  factory PendingBill.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0;
      return 0;
    }

    double parseAmount() {
      for (final key in [
        'billAmountInclTax',
        'billAmount',
        'totalAmount',
        'netAmount',
        'amountAfterDisc',
        'orderAmount',
        'amount',
        'grossAmount',
        'grandTotal',
      ]) {
        final val = toDouble(json[key]);
        if (val > 0) return val;
      }
      return toDouble(json['billAmountInclTax']);
    }

    double parsePaid() {
      for (final key in [
        'paidAmount',
        'amountPaid',
        'totalPaid',
        'paidAmt',
        'collectedAmount',
        'advanceAmount',
      ]) {
        final val = toDouble(json[key]);
        if (val > 0) return val;
      }
      return 0.0;
    }

    double parseBalance() {
      for (final key in [
        'balanceAmount',
        'balAmount',
        'balance',
        'dueAmount',
        'pendingAmount',
        'remainingAmount',
      ]) {
        final val = toDouble(json[key]);
        if (val > 0) return val;
      }
      return 0.0;
    }

    final isPaidVal =
        (json['isPaid'] is num) ? (json['isPaid'] as num).toInt() : 0;
    final totalAmount = parseAmount();
    double effectivePaid = parsePaid();
    double effectiveBalance = parseBalance();

    if (effectivePaid == 0 &&
        effectiveBalance > 0 &&
        totalAmount >= effectiveBalance) {
      effectivePaid = totalAmount - effectiveBalance;
    } else if (effectiveBalance == 0 &&
        effectivePaid > 0 &&
        totalAmount >= effectivePaid) {
      effectiveBalance = totalAmount - effectivePaid;
    } else if (isPaidVal == 2) {
      effectivePaid = totalAmount;
      effectiveBalance = 0;
    } else if (isPaidVal == 0) {
      effectivePaid = 0;
      effectiveBalance = totalAmount;
    }

    final billId = (json['billId'] ?? '').toString();
    final billNo = (json['billNo'] ?? '').toString();
    final orderNo = (json['orderNo'] ??
            json['orderNumber'] ??
            json['orderId'] ??
            '')
        .toString();

    DateTime? parsedDate = DateTimeFormatter.parseDateTime(
      json['paidDate'] ??
          json['billDate'] ??
          json['billDateTime'] ??
          json['createdOn'] ??
          json['billCreatedOn'] ??
          json['paymentDate'] ??
          json['orderDate'],
    );

    // If API returned midnight 00:00:00 or null, check Hive for dynamic first bill timing
    final hasRealTime = parsedDate != null &&
        (parsedDate.hour != 0 ||
            parsedDate.minute != 0 ||
            parsedDate.second != 0);

    if (!hasRealTime) {
      final hiveTime = HiveService.getBillTimestamp(billId) ??
          HiveService.getBillTimestamp(billNo) ??
          HiveService.getBillTimestamp(orderNo);
      if (hiveTime != null) {
        parsedDate = hiveTime;
      }
    }

    var resolvedCustomer = DateTimeFormatter.resolveCustomerName(json);
    if (resolvedCustomer.isEmpty ||
        resolvedCustomer.toLowerCase() == 'walk-in' ||
        resolvedCustomer.toLowerCase() == 'walk-in customer' ||
        !resolvedCustomer.contains(' ')) {
      final hiveName = HiveService.getCustomerName(billId) ??
          (billNo.isNotEmpty ? HiveService.getCustomerName(billNo) : null) ??
          (orderNo.isNotEmpty ? HiveService.getCustomerName(orderNo) : null);
      if (hiveName != null && hiveName.trim().isNotEmpty) {
        resolvedCustomer = hiveName.trim();
      }
    }

    return PendingBill(
      billId: billId,
      billNo: billNo,
      orderNo: orderNo,
      customerName: resolvedCustomer,
      amount: totalAmount,
      paidAmount: effectivePaid,
      balanceAmount: effectiveBalance,
      itemCount: (json['itemCount'] is num) ? json['itemCount'] as int : 0,
      isPaid: isPaidVal,
      paymentStatus: (json['paymentStatus'] ?? '').toString(),
      billDate: parsedDate,
    );
  }
}
