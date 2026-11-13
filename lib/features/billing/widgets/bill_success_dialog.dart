import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos_system/core/constants/currency_constants.dart';
import 'package:restaurant_pos_system/core/utils/haptic_helper.dart';
import '../providers/billing_provider.dart';
import 'package:restaurant_pos_system/features/dashboard/providers/table_provider.dart';
import 'package:restaurant_pos_system/features/dashboard/providers/navigation_provider.dart';
import 'package:restaurant_pos_system/features/order_taking/providers/animated_cart_provider.dart';
import 'package:restaurant_pos_system/features/payment/views/payment_view.dart';
import 'package:restaurant_pos_system/core/utils/snackbar_helper.dart';
import 'package:restaurant_pos_system/data/remote/api_service.dart';

import 'package:restaurant_pos_system/data/local/hive_service.dart';

/// Presentation dialog for post-billing status:
/// 1. "Payment Successful" when fully settled (Bill Paid & Settled)
/// 2. "Partially Paid" when partial tender was collected (PARTIALLY PAID · Due remaining)
/// 3. "Payment Pending (Pay Later)" when unpaid (Billed · Unpaid)
class BillSuccessDialog extends StatelessWidget {
  final String orderNumber;
  final double total;
  final String? customerPhone;
  final dynamic billBytes;
  final VoidCallback onBillGenerated;
  final String? tableId;
  final String? orderId;
  final int remainingUnbilledCount;
  final bool paidAtCheckout;
  final double paidAmount;
  final String? tableName;
  final String? orderType;

  const BillSuccessDialog({
    super.key,
    required this.orderNumber,
    required this.total,
    required this.customerPhone,
    required this.billBytes,
    required this.onBillGenerated,
    this.tableId,
    this.orderId,
    this.remainingUnbilledCount = 0,
    this.paidAtCheckout = false,
    this.paidAmount = 0.0,
    this.tableName,
    this.orderType,
  });

  double get effectivePaidAmount =>
      paidAmount > 0 ? paidAmount : (paidAtCheckout ? total : 0.0);

  double get remainingDue =>
      (total - effectivePaidAmount) > 0.004 ? (total - effectivePaidAmount) : 0.0;

  bool get isFullyPaid =>
      total > 0 ? (effectivePaidAmount >= total - 0.004) : paidAtCheckout;

  bool get isPartiallyPaid => effectivePaidAmount > 0.004 && !isFullyPaid;

  bool get isUnpaid => effectivePaidAmount <= 0.004;

  String get _displayOrderNo {
    final clean = orderNumber.trim();
    if (clean.isEmpty) return 'OD/0001';
    return clean.startsWith('#') ? clean.substring(1) : clean;
  }

  String _resolveTableName(BuildContext context) {
    if (tableName != null && tableName!.isNotEmpty) return tableName!;
    if (tableId == null) return 'N/A';
    if (tableId == 'PhoneOrder' || tableId == 'Phone') return 'Phone';
    if (tableId == 'Takeaway') return 'Takeaway';
    try {
      final tableProvider = Provider.of<TableProvider>(context, listen: false);
      final t =
          tableProvider.tables.where((tbl) => tbl.id == tableId).firstOrNull;
      if (t != null && t.name.isNotEmpty) return t.name;
    } catch (_) {}
    return tableId!.startsWith('Table') ? tableId! : 'Table $tableId';
  }

  String _resolveOrderType() {
    if (orderType != null && orderType!.isNotEmpty) return orderType!;
    if (tableId == 'PhoneOrder' || tableId == 'Phone') return 'Phone Order';
    if (tableId == 'Takeaway') return 'Takeaway';
    return 'Dine In';
  }

  String _formatDateTime() {
    final now = DateTime.now();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final day = now.day;
    final month = months[now.month - 1];
    final year = now.year;
    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final minute = now.minute.toString().padLeft(2, '0');
    final ampm = now.hour >= 12 ? 'PM' : 'AM';
    return '$day $month $year, ${hour.toString().padLeft(2, '0')}:$minute $ampm';
  }

  @override
  Widget build(BuildContext context) {
    if (tableId != null &&
        !['PhoneOrder', 'Takeaway', 'Phone'].contains(tableId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final tableProvider = Provider.of<TableProvider>(
          context,
          listen: false,
        );

        try {
          final billingProvider = Provider.of<BillingProvider>(
            context,
            listen: false,
          );
          if (orderId != null && orderId!.isNotEmpty) {
            tableProvider.storeBillId(orderId!, billingProvider.billId ?? '');
          }
        } catch (e) {
          debugPrint('BillSuccessDialog - Error storing billId: $e');
        }

        await tableProvider.refreshTables();
      });
    }

    final size = MediaQuery.sizeOf(context);
    final isTablet = size.width >= 600;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Fullscreen Backdrop Blur
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
              child: Container(color: Colors.black.withValues(alpha: 0.16)),
            ),
          ),

          // Main Modal Card
          SafeArea(
            child: Center(
              child: Container(
                width: isTablet ? 460 : min(size.width * 0.92, 420),
                constraints: const BoxConstraints(maxWidth: 460),
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 28,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        child: isFullyPaid
                            ? _buildPaidSuccessContent(context)
                            : (isPartiallyPaid
                                ? _buildPartialPaidContent(context)
                                : _buildPendingContent(context)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // SCREENSHOT 2: Payment Pending (Pay Later) / Bill Status
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildPendingContent(BuildContext context) {
    final resolvedOrderType = _resolveOrderType();
    final resolvedTableName = _resolveTableName(context);
    final formattedDateTime = _formatDateTime();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Top Header Bar ──
        Container(
          padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
          decoration: const BoxDecoration(
            color: Color(0xFFFAFAFA),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
            ),
          ),
          child: Row(
            children: [
              // Orange receipt icon avatar
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.receipt_rounded,
                  size: 19,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),

              const Text(
                'Bill Status',
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 8),

              // BILLED · UNPAID Pill Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3.5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFFDE68A),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5.5,
                      height: 5.5,
                      decoration: const BoxDecoration(
                        color: Color(0xFFD97706),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4.5),
                    const Text(
                      'BILLED · UNPAID',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFB45309),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Close (X) button
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () async {
                  await HapticHelper.triggerFeedback();
                  if (!context.mounted) return;
                  await _payLater(context);
                },
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF1F5F9),
                  foregroundColor: const Color(0xFF64748B),
                  padding: const EdgeInsets.all(6),
                  minimumSize: const Size(32, 32),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // ── Hero Section ──
        Center(
          child: Column(
            children: [
              // Circular Clock Icon with layered ring
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFFEF3C7),
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFF59E0B),
                      width: 3.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.access_time_rounded,
                    size: 28,
                    color: Color(0xFFD97706),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Title
              const Text(
                'Payment Pending (Pay Later)',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Pill: Customer will pay this bill later.
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFFED7AA),
                    width: 1,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 13,
                      color: Color(0xFFC2410C),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Customer will pay this bill later.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF9A3412),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'This bill has been generated, but the payment is not collected yet.',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ── Details Card (2x2 Grid) ──
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 18),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Row 1: Order ID (Left) & Order Type (Right)
              Row(
                children: [
                  Expanded(
                    child: _buildGridCell(
                      icon: Icons.receipt_long_outlined,
                      label: 'Order ID',
                      value: _displayOrderNo,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 36,
                    color: const Color(0xFFE2E8F0),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildGridCell(
                      icon: Icons.restaurant_menu_rounded,
                      label: 'Order Type',
                      value: resolvedOrderType,
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1, color: Color(0xFFE2E8F0)),
              ),
              // Row 2: Table (Left) & Bill Date & Time (Right)
              Row(
                children: [
                  Expanded(
                    child: _buildGridCell(
                      icon: Icons.table_restaurant_outlined,
                      label: 'Table',
                      value: resolvedTableName,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 36,
                    color: const Color(0xFFE2E8F0),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildGridCell(
                      icon: Icons.calendar_month_outlined,
                      label: 'Bill Date & Time',
                      value: formattedDateTime,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ── Amount & Payment Status Card ──
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 18),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFFEF3C7),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              // Left: Total Bill Amount (Due)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Bill Amount (Due)',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF78350F),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      total.toCurrency(),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF92400E),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Vertical Divider
              Container(
                width: 1,
                height: 42,
                color: const Color(0xFFFDE68A),
              ),
              const SizedBox(width: 16),

              // Right: Payment Status
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.payments_outlined,
                        size: 15,
                        color: Color(0xFF78350F),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Payment Status',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF78350F),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 3.5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFFDE68A),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFFD97706),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'Pending',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── Bottom Action Buttons (Only 2 buttons: Close & Pay Now) ──
        Container(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          child: Row(
            children: [
              // Close Button
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await HapticHelper.triggerFeedback();
                      if (!context.mounted) return;
                      await _payLater(context);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Color(0xFFCBD5E1),
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: Color(0xFF475569),
                    ),
                    label: const Text(
                      'Close',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Pay Now Button
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await HapticHelper.triggerFeedback();
                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                      _navigateToPayment(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shadowColor:
                          const Color(0xFF4F46E5).withValues(alpha: 0.35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    label: const Text(
                      'Pay Now',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGridCell({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 1.5),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // SCREENSHOT: Partially Paid (Partial Payment Collected · Balance Remaining)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildPartialPaidContent(BuildContext context) {
    final resolvedOrderType = _resolveOrderType();
    final resolvedTableName = _resolveTableName(context);
    final formattedDateTime = _formatDateTime();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Top Header Bar ──
        Container(
          padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
          decoration: const BoxDecoration(
            color: Color(0xFFFAFAFA),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
            ),
          ),
          child: Row(
            children: [
              // Amber receipt icon avatar
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.receipt_rounded,
                  size: 19,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),

              const Text(
                'Bill Status',
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 8),

              // PARTIALLY PAID Pill Badge
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3.5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFFDE68A),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5.5,
                        height: 5.5,
                        decoration: const BoxDecoration(
                          color: Color(0xFFD97706),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4.5),
                      Flexible(
                        child: Text(
                          'PARTIALLY PAID · ${remainingDue.toCurrency()} DUE',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFB45309),
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 6),

              // Close (X) button
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () async {
                  await HapticHelper.triggerFeedback();
                  if (!context.mounted) return;
                  await _finishPartiallyPaid(context);
                },
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF1F5F9),
                  foregroundColor: const Color(0xFF64748B),
                  padding: const EdgeInsets.all(6),
                  minimumSize: const Size(32, 32),
                ),
              ),
            ],
          ),
        ),

        // ── Hero Section ──
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
          child: Column(
            children: [
              // Circular Amber Hourglass / Receipt Avatar
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD97706),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.hourglass_top_rounded,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              const Text(
                'Partially Paid',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),

              Text(
                'Order #$_displayOrderNo · Table $resolvedTableName',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Partial payment of ${effectivePaidAmount.toCurrency()} was recorded. Outstanding balance: ${remainingDue.toCurrency()}.',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                    height: 1.35,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ── 3-Metric Breakdown Card ──
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 18),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1.2,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Bill Amount',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    total.toCurrency(),
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 15,
                        color: Color(0xFF16A34A),
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Amount Paid',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    effectivePaidAmount.toCurrency(),
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF15803D),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1, color: Color(0xFFE2E8F0)),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.pending_actions_rounded,
                        size: 16,
                        color: Color(0xFFD97706),
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Remaining Due',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    remainingDue.toCurrency(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFD97706),
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ── Order Details 2x2 Grid ──
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 18),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1.2,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildGridCell(
                      icon: Icons.tag_rounded,
                      label: 'Order ID',
                      value: '#$_displayOrderNo',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildGridCell(
                      icon: Icons.table_restaurant_rounded,
                      label: 'Table',
                      value: resolvedTableName,
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1, color: Color(0xFFF1F5F9)),
              ),
              Row(
                children: [
                  Expanded(
                    child: _buildGridCell(
                      icon: Icons.restaurant_menu_rounded,
                      label: 'Order Type',
                      value: resolvedOrderType,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildGridCell(
                      icon: Icons.access_time_rounded,
                      label: 'Time',
                      value: formattedDateTime,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── Bottom Action Buttons ──
        Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
          decoration: const BoxDecoration(
            color: Color(0xFFFAFAFA),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: Color(0xFFF1F5F9), width: 1),
            ),
          ),
          child: Row(
            children: [
              // Done (Pay Later) Button
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 46,
                  child: OutlinedButton(
                    onPressed: () async {
                      await HapticHelper.triggerFeedback();
                      if (!context.mounted) return;
                      await _finishPartiallyPaid(context);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Color(0xFFCBD5E1),
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Done (Pay Later)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Pay Remaining Now Button
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () async {
                      await HapticHelper.triggerFeedback();
                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                      _navigateToPayment(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shadowColor:
                          const Color(0xFF4F46E5).withValues(alpha: 0.35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Pay ${remainingDue.toCurrency()}',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // SCREENSHOT 1: Payment Successful (Bill Paid & Settled)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildPaidSuccessContent(BuildContext context) {
    final formattedDateTime = _formatDateTime();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Top Right Close Button ──
        Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 12, 12, 0),
            child: IconButton(
              icon: const Icon(Icons.close_rounded, size: 18),
              onPressed: () async {
                await HapticHelper.triggerFeedback();
                if (!context.mounted) return;
                await _finishAlreadyPaid(context);
              },
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFF1F5F9),
                foregroundColor: const Color(0xFF64748B),
                padding: const EdgeInsets.all(6),
                minimumSize: const Size(32, 32),
              ),
            ),
          ),
        ),

        // ── Hero Section ──
        Center(
          child: Column(
            children: [
              // Circular Green Checkmark with festive confetti / glow
              Container(
                width: 76,
                height: 76,
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: Color(0xFF16A34A),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Title
              const Text(
                'Payment Successful',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Pill: Bill Paid & Settled
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFBBF7D0),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF16A34A),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'Bill Paid & Settled',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF15803D),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'The payment for this order has been collected successfully.',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ── Amount Paid Card ──
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 18),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFDCFCE7),
              width: 1.2,
            ),
          ),
          child: Column(
            children: [
              const Text(
                'Amount Paid',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF15803D),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                effectivePaidAmount.toCurrency(),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF15803D),
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ── Details List ──
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            children: [
              // Row 1: Order ID
              Row(
                children: [
                  const Icon(
                    Icons.receipt_long_outlined,
                    size: 18,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Order ID',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _displayOrderNo,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: _displayOrderNo));
                      HapticHelper.triggerFeedback();
                      AppSnackBar.showSuccess(context, 'Order ID copied');
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: const Padding(
                      padding: EdgeInsets.all(2.0),
                      child: Icon(
                        Icons.copy_rounded,
                        size: 15,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 9),
                child: Divider(height: 1, color: Color(0xFFF1F5F9)),
              ),

              // (Transaction ID & Payment Method removed per user request)

              // Row 2: Date & Time
              Row(
                children: [
                  const Icon(
                    Icons.calendar_month_outlined,
                    size: 18,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Date & Time',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    formattedDateTime,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 9),
                child: Divider(height: 1, color: Color(0xFFF1F5F9)),
              ),

              // Row 3: Status
              Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 18,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Status',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3.5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFFBBF7D0),
                        width: 1,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_rounded,
                          size: 13,
                          color: Color(0xFF15803D),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Transaction Complete',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF15803D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // ── Bottom Action Buttons (Only 2 buttons: Close & Done) ──
        Container(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          child: Row(
            children: [
              // Close Button
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: OutlinedButton(
                    onPressed: () async {
                      await HapticHelper.triggerFeedback();
                      if (!context.mounted) return;
                      await _finishAlreadyPaid(context);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Color(0xFFCBD5E1),
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Done Button
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await HapticHelper.triggerFeedback();
                      if (!context.mounted) return;
                      await _finishAlreadyPaid(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shadowColor:
                          const Color(0xFF16A34A).withValues(alpha: 0.35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    label: const Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Handlers
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> _payLater(BuildContext context) async {
    final isRealTable =
        tableId != null &&
        !['PhoneOrder', 'Takeaway', 'Phone'].contains(tableId);

    try {
      final billingProvider = Provider.of<BillingProvider>(
        context,
        listen: false,
      );
      final tableProvider = Provider.of<TableProvider>(
        context,
        listen: false,
      );
      final cartProvider = Provider.of<AnimatedCartProvider>(
        context,
        listen: false,
      );

      final billIdToSave = billingProvider.billId ?? '';
      if (orderId != null && orderId!.isNotEmpty) {
        if (billIdToSave.isNotEmpty) {
          tableProvider.storeBillId(orderId!, billIdToSave);
          HiveService.saveOrderBillId(orderId!, billIdToSave);
        }
        cartProvider.markOrderBilled(orderId!);
      }
      if (isRealTable) {
        tableProvider.updateTableStatus(tableId!, 'billGenerated');
        await tableProvider.refreshTables();
      }
    } catch (e) {
      debugPrint('BillSuccessDialog - Error on payLater: $e');
    }

    if (!context.mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
    final navProvider = Provider.of<NavigationProvider>(context, listen: false);
    navProvider.clearTableSelection();
    navProvider.navigateToTables();
  }

  Future<void> _finishPartiallyPaid(BuildContext context) async {
    final isRealTable =
        tableId != null &&
        !['PhoneOrder', 'Takeaway', 'Phone'].contains(tableId);

    try {
      final billingProvider = Provider.of<BillingProvider>(
        context,
        listen: false,
      );
      final tableProvider = Provider.of<TableProvider>(
        context,
        listen: false,
      );
      final cartProvider = Provider.of<AnimatedCartProvider>(
        context,
        listen: false,
      );

      final billIdToSave = billingProvider.billId ?? '';
      if (orderId != null && orderId!.isNotEmpty) {
        if (billIdToSave.isNotEmpty) {
          tableProvider.storeBillId(orderId!, billIdToSave);
          HiveService.saveOrderBillId(orderId!, billIdToSave);
        }
        cartProvider.markOrderBilled(orderId!);
      }
      if (isRealTable) {
        // TABLE MUST REMAIN IN BILL GENERATED STATUS! NEVER AVAILABLE!
        tableProvider.updateTableStatus(tableId!, 'billGenerated');
        await tableProvider.refreshTables();
      }
    } catch (e) {
      debugPrint('BillSuccessDialog - Error on finishPartiallyPaid: $e');
    }

    if (!context.mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
    final navProvider = Provider.of<NavigationProvider>(context, listen: false);
    navProvider.clearTableSelection();
    navProvider.navigateToTables();
  }

  Future<void> _finishAlreadyPaid(BuildContext context) async {
    // If not truly fully paid, route to partial paid handler
    if (!isFullyPaid) {
      await _finishPartiallyPaid(context);
      return;
    }

    final isFinalSettlement = remainingUnbilledCount == 0;

    final isRealTable =
        tableId != null &&
        !['PhoneOrder', 'Takeaway', 'Phone'].contains(tableId);

    if (isRealTable && isFinalSettlement) {
      try {
        final tableProvider = Provider.of<TableProvider>(
          context,
          listen: false,
        );

        if (orderId != null && orderId!.isNotEmpty) {
          try {
            await ApiService.updateOrderHeadStatus(
              orderHeadId: orderId!,
              statusId: 7,
            );
          } catch (e) {
            debugPrint('BillSuccessDialog - Error updating order status: $e');
          }

          await tableProvider.markOrderSettled(orderId!);
          if (context.mounted) {
            try {
              Provider.of<AnimatedCartProvider>(
                context,
                listen: false,
              ).clearOrderData(orderId!);
            } catch (_) {}
          }
        }

        if (tableId != null && tableId!.isNotEmpty) {
          tableProvider.updateTableStatus(tableId!, 'available');
        }

        await tableProvider.refreshTables();
      } catch (e) {
        debugPrint('BillSuccessDialog - Error releasing table: $e');
      }
    }

    if (!context.mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);

    if (isFinalSettlement) {
      onBillGenerated();
    } else {
      AppSnackBar.showSuccess(
        context,
        'Bill settled. $remainingUnbilledCount item'
        '${remainingUnbilledCount == 1 ? '' : 's'} still unbilled on this order.',
      );
    }
  }

  void _navigateToPayment(BuildContext context) {
    String? billId;
    try {
      final billingProvider = Provider.of<BillingProvider>(
        context,
        listen: false,
      );
      billId = billingProvider.billId;
    } catch (e) {
      debugPrint('BillSuccessDialog - Error getting billId: $e');
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => PaymentPage(
              orderId: orderId,
              orderNumber: orderNumber,
              totalAmount: total,
              tableId: tableId,
              billId: billId,
              isFinalSettlement: remainingUnbilledCount == 0,
              onPaymentCompleted: () {
                if (remainingUnbilledCount > 0) {
                  AppSnackBar.showSuccess(
                    context,
                    'Bill settled. $remainingUnbilledCount item'
                    '${remainingUnbilledCount == 1 ? '' : 's'} still '
                    'unbilled on this order.',
                  );
                  Navigator.of(context).pop();
                } else {
                  onBillGenerated();
                }
              },
            ),
      ),
    );
  }
}
