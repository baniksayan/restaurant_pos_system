import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos_system/core/constants/currency_constants.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/core/utils/haptic_helper.dart';
import '../providers/billing_provider.dart';
import 'package:restaurant_pos_system/features/dashboard/providers/table_provider.dart';
import 'package:restaurant_pos_system/features/payment/views/payment_view.dart';
import 'package:restaurant_pos_system/core/utils/snackbar_helper.dart';

class BillSuccessDialog extends StatelessWidget {
  final String orderNumber;
  final double total;
  final String? customerPhone;
  final dynamic billBytes;
  final VoidCallback onBillGenerated;
  final String? tableId;

  /// Order this bill belongs to. Required to remember the bill id, which is
  /// stored per order rather than per table — a shared table runs several
  /// orders at once and each has its own bill.
  final String? orderId;

  /// How many items on this order were left unbilled by a split bill (0 for
  /// a normal, full-order bill). When this is > 0, the table isn't actually
  /// finished yet — paying this bill returns to the order screen instead of
  /// clearing the table, so the cashier can split the rest.
  final int remainingUnbilledCount;

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
  });

  @override
  Widget build(BuildContext context) {
    if (tableId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final tableProvider = Provider.of<TableProvider>(
          context,
          listen: false,
        );

        // Persist the bill id BEFORE anything is awaited. It used to be
        // stored after `await refreshTables()`, behind a `context.mounted`
        // check — so dismissing this dialog while the refresh was in flight
        // dropped the id entirely. It is only held in BillingProvider memory,
        // which is cleared when the billing screen is disposed, and
        // getOrderDetailById cannot supply it (Sp_GetOrderViewNew returns no
        // BillId). Losing it here means the bill can never be settled later.
        try {
          final billingProvider = Provider.of<BillingProvider>(
            context,
            listen: false,
          );
          if (orderId != null && orderId!.isNotEmpty) {
            tableProvider.storeBillId(orderId!, billingProvider.billId ?? '');
          } else {
            debugPrint(
              'BillSuccessDialog - No orderId supplied; bill id not stored',
            );
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
          // Fullscreen Backdrop Dimming with Blur (Will not close on outside tap)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3.5, sigmaY: 3.5),
              child: Container(color: Colors.black.withValues(alpha: 0.12)),
            ),
          ),

          // Main Frosted Glassmorphic Modal Card
          SafeArea(
            child: Center(
              child: Container(
                width: isTablet ? 460 : size.width * 0.88,
                constraints: const BoxConstraints(maxWidth: 460),
                margin: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.85),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.10),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header Bar
                          _buildHeader(context),

                          // Content Section with Equal Balanced Spacing
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Success Icon Container
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF10B981,
                                    ).withValues(alpha: 0.16),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(
                                        0xFF10B981,
                                      ).withValues(alpha: 0.35),
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.check_circle_rounded,
                                    color: Color(0xFF10B981),
                                    size: 38,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Title
                                const Text(
                                  'Bill Generated Successfully',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -0.3,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),

                                // Order Number
                                Text(
                                  'Order #$orderNumber',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Total Bill Amount Card (Crisp Frosted Glass Card)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.70),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.90,
                                      ),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      const Text(
                                        'Total Bill Amount',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textSecondary,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${CurrencyConstants.symbol}${total.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primary,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Action Footer Bar (Proceed to Pay)
                          _buildActionBar(context),
                        ],
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 14, 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.35),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.60),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.receipt_rounded,
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),

          const Expanded(
            child: Text(
              'Bill Status',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
          ),

          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            onPressed: () async {
              await HapticHelper.triggerFeedback();
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            style: IconButton.styleFrom(
              backgroundColor: Colors.black.withValues(alpha: 0.05),
              foregroundColor: AppColors.textSecondary,
              padding: const EdgeInsets.all(6),
              minimumSize: const Size(32, 32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.35),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.60),
            width: 1,
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          onPressed: () async {
            await HapticHelper.triggerFeedback();
            if (context.mounted) {
              Navigator.of(context).pop();
              _navigateToPayment(context);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 3,
            shadowColor: AppColors.primary.withValues(alpha: 0.35),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: const Icon(Icons.payment_rounded, size: 18),
          label: const Text(
            'Proceed to Pay',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
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
              // Gates PaymentPage's own table-release + auto-clear + final
              // dashboard navigation. false here is what actually stops a
              // split bill from releasing the table early — see the fix in
              // payment_view.dart's executeRedirect.
              isFinalSettlement: remainingUnbilledCount == 0,
              onPaymentCompleted: () {
                if (remainingUnbilledCount > 0) {
                  // This was one split of a bigger order — other guests'
                  // items are still unbilled, so the table stays open and
                  // we just return to the order screen for the next split.
                  AppSnackBar.showSuccess(
                    context,
                    'Bill settled. $remainingUnbilledCount item'
                    '${remainingUnbilledCount == 1 ? '' : 's'} still '
                    'unbilled on this order.',
                  );
                  Navigator.of(context).pop();
                } else {
                  // PaymentPage's own step 5 (isFinalSettlement: true)
                  // already returns to the dashboard.
                  onBillGenerated();
                }
              },
            ),
      ),
    );
  }
}
