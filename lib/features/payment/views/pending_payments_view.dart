import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/core/constants/currency_constants.dart';
import 'package:restaurant_pos_system/core/utils/haptic_helper.dart';
import 'package:restaurant_pos_system/data/local/hive_service.dart';
import 'package:restaurant_pos_system/data/models/pending_bill.dart';
import 'package:restaurant_pos_system/data/remote/api_service.dart';
import 'package:restaurant_pos_system/features/dashboard/providers/table_provider.dart';
import 'package:restaurant_pos_system/shared/widgets/layout/skeleton_loader.dart';
import 'payment_view.dart';

/// Bills raised but not yet settled, in one place.
///
/// Billing allows a bill to be created with no payment and collected later,
/// and a split bill leaves several bills open on one order. Until now the only
/// route back to an unpaid bill was through the table that produced it, which
/// fails as soon as the table has been reused or the order settled around it.
class PendingPaymentsView extends StatefulWidget {
  const PendingPaymentsView({super.key});

  @override
  State<PendingPaymentsView> createState() => _PendingPaymentsViewState();
}

class _PendingPaymentsViewState extends State<PendingPaymentsView> {
  /// How far back to look. An unpaid bill can be days old, so a single day
  /// would hide exactly the ones that matter most.
  static const _windowDays = 30;

  List<PendingBill> _bills = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final outletId = HiveService.getOutletId();
    if (outletId == null || outletId <= 0) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'No outlet selected. Sign in again to continue.';
      });
      return;
    }

    final now = DateTime.now();
    final bills = await ApiService.getBillsForReprint(
      outletId: outletId,
      from: now.subtract(const Duration(days: _windowDays)),
      to: now,
    );

    if (!mounted) return;

    if (bills == null) {
      setState(() {
        _loading = false;
        _error = 'Could not load bills. Pull down to try again.';
      });
      return;
    }

    setState(() {
      _loading = false;
      // Settled bills belong in reports, not on a screen for collecting money.
      _bills = bills.where((b) => b.isOutstanding).toList();
    });
  }

  double get _outstandingTotal =>
      _bills.fold(0.0, (sum, b) => sum + b.amount);

  Future<void> _openPayment(PendingBill bill) async {
    await HapticHelper.triggerFeedback();
    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => PaymentPage(
              billId: bill.billId,
              orderNumber: bill.orderNo.isNotEmpty ? bill.orderNo : bill.billNo,
              totalAmount: bill.amount,
              // No tableId: a bill reached from here is not tied to the table
              // grid, and releasing a table from this screen would be wrong —
              // the order may still have other bills outstanding.
            ),
      ),
    );

    if (!mounted) return;
    // Whatever happened, the list is now stale.
    await _load();
    if (mounted) {
      context.read<TableProvider>().refreshTables();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Pending Payments'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (!_loading && _error == null && _bills.isNotEmpty)
              _summaryBar(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: _buildBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryBar() {
    return Container(
      width: double.infinity,
      color: AppColors.primary.withValues(alpha: 0.08),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(
            Icons.account_balance_wallet_outlined,
            size: 17,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Text(
            '${_bills.length} bill${_bills.length == 1 ? '' : 's'} awaiting payment',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            '${CurrencyConstants.symbol}${_outstandingTotal.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder:
            (_, __) => const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: SkeletonLoader.rectangular(
                width: double.infinity,
                height: 78,
                borderRadius: BorderRadius.all(Radius.circular(14)),
              ),
            ),
      );
    }

    if (_error != null) {
      return _message(
        icon: Icons.cloud_off_rounded,
        title: 'Could not load',
        detail: _error!,
      );
    }

    if (_bills.isEmpty) {
      return _message(
        icon: Icons.verified_rounded,
        title: 'Nothing pending',
        detail:
            'Every bill from the last $_windowDays days has been settled.',
        tone: AppColors.success,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _bills.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _billCard(_bills[index]),
    );
  }

  Widget _billCard(PendingBill bill) {
    final partial = bill.isPartiallyPaid;
    final tone = partial ? AppColors.warning : AppColors.primary;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => _openPayment(bill),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            // A partly-paid bill is the more urgent of the two: money has
            // already changed hands and the rest is outstanding.
            boxShadow: [
              BoxShadow(
                color: tone.withValues(alpha: 0.07),
                blurRadius: 7,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            bill.billNo.isNotEmpty ? bill.billNo : bill.orderNo,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: tone.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            bill.paymentStatus.isNotEmpty
                                ? bill.paymentStatus
                                : 'Not Paid',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: tone,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [
                        if (bill.customerName.isNotEmpty) bill.customerName,
                        if (bill.orderNo.isNotEmpty &&
                            bill.orderNo != bill.billNo)
                          bill.orderNo,
                        '${bill.itemCount} item${bill.itemCount == 1 ? '' : 's'}',
                        if (bill.billDate != null) _shortDate(bill.billDate!),
                      ].join('  ·  '),
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textHint,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${CurrencyConstants.symbol}${bill.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Collect',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: tone,
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, size: 16, color: tone),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _shortDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

  Widget _message({
    required IconData icon,
    required String title,
    required String detail,
    Color tone = AppColors.textHint,
  }) {
    // A scrollable, so pull-to-refresh still works on an empty screen.
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
      children: [
        Icon(icon, size: 46, color: tone),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          detail,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textHint,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
