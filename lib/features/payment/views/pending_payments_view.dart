// lib/features/payment/views/pending_payments_view.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/core/constants/currency_constants.dart';
import 'package:restaurant_pos_system/core/utils/date_time_formatter.dart';
import 'package:restaurant_pos_system/core/utils/haptic_helper.dart';
import 'package:restaurant_pos_system/core/utils/snackbar_helper.dart';
import 'package:restaurant_pos_system/data/local/hive_service.dart';
import 'package:restaurant_pos_system/data/models/pending_bill.dart';
import 'package:restaurant_pos_system/data/remote/api_service.dart';
import 'package:restaurant_pos_system/features/dashboard/providers/table_provider.dart';
import 'package:restaurant_pos_system/features/orders/providers/ready_to_collect_provider.dart'
    show ServedDateFilter;
import 'package:restaurant_pos_system/shared/widgets/dialogs/app_date_range_picker_dialog.dart';
import 'package:restaurant_pos_system/shared/widgets/layout/premium_refresh_indicator.dart';
import 'package:restaurant_pos_system/shared/widgets/layout/shimmer_effect.dart';
import 'payment_view.dart';

/// A FAANG-grade Pending Payments management view for WhizEats Pro.
///
/// Features:
/// - Custom top app bar matching Ready to Collect & Reprint screens with live count badge.
/// - Pinned real-time search box & quick date filter chips (Today, Yesterday, Custom Date, Past 6 Months).
/// - Modal popup [AppDateRangePickerDialog] with 6-month historical limit and future dates disabled.
/// - Outstanding summary metrics banner showing total pending balance & bill count.
/// - Premium card design with customer details, payment status pill, formatted total, and direct payment action.
/// - Hourglass pull-to-refresh via [PremiumRefreshIndicator].
/// - Synchronized multi-stop shimmer skeleton loading state.
class PendingPaymentsView extends StatefulWidget {
  const PendingPaymentsView({super.key});

  @override
  State<PendingPaymentsView> createState() => _PendingPaymentsViewState();
}

class _PendingPaymentsViewState extends State<PendingPaymentsView> {
  static const int _windowDays = 180; // 6 months historical window

  List<PendingBill> _rawBills = [];
  bool _loading = true;
  String? _error;
  String _searchQuery = '';
  ServedDateFilter _dateFilter = ServedDateFilter.today;
  DateTimeRange? _customDateRange;
  late TextEditingController _searchController;
  String? _openingBillId;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBills();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ────────────────────────── Data Fetching ────────────────────────────────

  Future<void> _loadBills() async {
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

    try {
      final now = DateTime.now();
      final from = now.subtract(const Duration(days: _windowDays));
      final bills = await ApiService.getBillsForReprint(
        outletId: outletId,
        from: from,
        to: now,
      );

      if (!mounted) return;

      if (bills == null) {
        setState(() {
          _loading = false;
          _error = 'Could not load pending bills. Pull down to retry.';
        });
        return;
      }

      setState(() {
        _loading = false;
        // Keep only outstanding (not fully paid) bills
        _rawBills = bills.where((b) => b.isOutstanding).toList();
        _rawBills.sort((a, b) {
          final aDate = a.billDate ?? DateTime(2000);
          final bDate = b.billDate ?? DateTime(2000);
          return bDate.compareTo(aDate);
        });
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to fetch pending bills: $e';
      });
    }
  }

  // ────────────────────────── Filtered Getters ─────────────────────────────

  List<PendingBill> get _filteredBills {
    final query = _searchQuery.trim().toLowerCase();
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));
    final yesterdayEnd = DateTime(
      yesterdayStart.year,
      yesterdayStart.month,
      yesterdayStart.day,
      23,
      59,
      59,
      999,
    );

    return _rawBills.where((bill) {
      // 1. Date Filter
      final bDate = bill.billDate;
      if (bDate != null) {
        switch (_dateFilter) {
          case ServedDateFilter.today:
            if (bDate.isBefore(todayStart) || bDate.isAfter(todayEnd)) {
              return false;
            }
            break;
          case ServedDateFilter.yesterday:
            if (bDate.isBefore(yesterdayStart) || bDate.isAfter(yesterdayEnd)) {
              return false;
            }
            break;
          case ServedDateFilter.custom:
            if (_customDateRange != null) {
              final start = DateTime(
                _customDateRange!.start.year,
                _customDateRange!.start.month,
                _customDateRange!.start.day,
              );
              final end = DateTime(
                _customDateRange!.end.year,
                _customDateRange!.end.month,
                _customDateRange!.end.day,
                23,
                59,
                59,
                999,
              );
              if (bDate.isBefore(start) || bDate.isAfter(end)) {
                return false;
              }
            }
            break;
          case ServedDateFilter.all:
            break;
        }
      }

      // 2. Search Query Filter
      if (query.isNotEmpty) {
        final matchesBillNo = bill.billNo.toLowerCase().contains(query);
        final matchesOrderNo = bill.orderNo.toLowerCase().contains(query);
        final matchesCustomer = bill.customerName.toLowerCase().contains(query);
        final matchesAmount = bill.amount.toString().contains(query);
        final matchesStatus = bill.paymentStatus.toLowerCase().contains(query);

        if (!matchesBillNo &&
            !matchesOrderNo &&
            !matchesCustomer &&
            !matchesAmount &&
            !matchesStatus) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  bool get _isFilterActive =>
      _searchQuery.trim().isNotEmpty || _dateFilter != ServedDateFilter.today;

  double get _filteredOutstandingTotal =>
      _filteredBills.fold(0.0, (sum, b) => sum + b.amount);

  // ────────────────────────── Filter Actions ───────────────────────────────

  void _onClearFilters() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _dateFilter = ServedDateFilter.today;
      _customDateRange = null;
    });
  }

  Future<void> _onPickCustomDateRange() async {
    final picked = await AppDateRangePickerDialog.show(
      context,
      initialRange: _customDateRange,
    );
    if (picked != null) {
      setState(() {
        _dateFilter = ServedDateFilter.custom;
        _customDateRange = picked;
      });
    }
  }

  // ────────────────────────── Payment Action ───────────────────────────────

  Future<void> _openPayment(PendingBill bill) async {
    if (_openingBillId != null) return;
    await HapticHelper.triggerFeedback();
    if (!mounted) return;

    setState(() => _openingBillId = bill.billId);
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => PaymentPage(
                billId: bill.billId,
                orderNumber:
                    bill.orderNo.isNotEmpty ? bill.orderNo : bill.billNo,
                totalAmount: bill.amount,
              ),
        ),
      );

      if (!mounted) return;
      await _loadBills();
      if (mounted) {
        context.read<TableProvider>().refreshTables();
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Error opening payment: $e');
      }
    } finally {
      if (mounted) setState(() => _openingBillId = null);
    }
  }

  // ────────────────────────── Main Build ───────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredBills;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: Column(
          children: [
            // Top Header: WhizEats Pro style
            _buildTopHeader(context, filtered.length),

            // Pinned Search & Filter Section
            _buildSearchAndFilterBar(context, filtered.length),

            // Outstanding Summary Metrics Banner (when bills are present)
            if (!_loading && _error == null && filtered.isNotEmpty)
              _buildSummaryMetricsBar(),

            // Scrollable Content
            Expanded(
              child: PremiumRefreshIndicator(
                onRefresh: _loadBills,
                child:
                    _loading && _rawBills.isEmpty
                        ? _buildSkeletonView(context)
                        : _error != null && _rawBills.isEmpty
                        ? _buildErrorState(_error!)
                        : filtered.isEmpty
                        ? (_isFilterActive
                            ? _buildFilteredEmptyState()
                            : _buildEmptyState())
                        : _buildBillsList(context, filtered),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────────────── Top Header ───────────────────────────────────

  Widget _buildTopHeader(BuildContext context, int pendingCount) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.cardShadow, width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Back Button
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
                onPressed: () => Navigator.pop(context),
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                padding: const EdgeInsets.all(6),
                tooltip: 'Back',
              ),
            ),
            const SizedBox(width: 12),

            // Title & Subtitle Area
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Pending Payments',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 1),
                  Text(
                    'Outstanding & unpaid bills · Ready for settlement',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Live status count badge pill on top right
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.28),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.account_balance_wallet_rounded,
                    size: 13,
                    color: Color(0xFFD97706),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$pendingCount Pending',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFD97706),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────────────── Search & Filters Bar ─────────────────────────

  Widget _buildSearchAndFilterBar(BuildContext context, int filteredCount) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 0.8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dynamic Search Box
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    _searchQuery.isNotEmpty
                        ? AppColors.primary.withValues(alpha: 0.5)
                        : const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              textInputAction: TextInputAction.search,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Search by bill #, order #, or customer...',
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: Color(0xFF64748B),
                ),
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          icon: const Icon(
                            Icons.cancel_rounded,
                            size: 18,
                            color: Color(0xFF94A3B8),
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                        : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Horizontal Date Filter Chips Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildDateFilterChip(
                  label: 'Today',
                  icon: Icons.today_rounded,
                  isSelected: _dateFilter == ServedDateFilter.today,
                  onTap: () {
                    setState(() {
                      _dateFilter = ServedDateFilter.today;
                    });
                  },
                ),
                const SizedBox(width: 8),
                _buildDateFilterChip(
                  label: 'Yesterday',
                  icon: Icons.history_rounded,
                  isSelected: _dateFilter == ServedDateFilter.yesterday,
                  onTap: () {
                    setState(() {
                      _dateFilter = ServedDateFilter.yesterday;
                    });
                  },
                ),
                const SizedBox(width: 8),
                _buildDateFilterChip(
                  label: _getCustomDateChipLabel(),
                  icon: Icons.calendar_month_rounded,
                  isSelected: _dateFilter == ServedDateFilter.custom,
                  onTap: _onPickCustomDateRange,
                ),
                const SizedBox(width: 8),
                _buildDateFilterChip(
                  label: 'Past 6 Months',
                  icon: Icons.history_toggle_off_rounded,
                  isSelected: _dateFilter == ServedDateFilter.all,
                  onTap: () {
                    setState(() {
                      _dateFilter = ServedDateFilter.all;
                    });
                  },
                ),
              ],
            ),
          ),

          // Active filter indicator strip
          if (_isFilterActive) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF59E0B),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Showing $filteredCount of ${_rawBills.length} pending bills',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: _onClearFilters,
                  borderRadius: BorderRadius.circular(4),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.clear_all_rounded,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 3),
                        Text(
                          'Reset filters',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _getCustomDateChipLabel() {
    if (_dateFilter == ServedDateFilter.custom && _customDateRange != null) {
      final start = _customDateRange!.start;
      final end = _customDateRange!.end;
      final s = '${start.day}/${start.month}';
      final e = '${end.day}/${end.month}';
      return start.day == end.day &&
              start.month == end.month &&
              start.year == end.year
          ? s
          : '$s - $e';
    }
    return 'Custom Date';
  }

  Widget _buildDateFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6.5),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
              width: 1,
            ),
            boxShadow:
                isSelected
                    ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ────────────────────────── Summary Metrics Bar ──────────────────────────

  Widget _buildSummaryMetricsBar() {
    final total = _filteredOutstandingTotal;
    final count = _filteredBills.length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFEF3C7).withValues(alpha: 0.9),
            const Color(0xFFFFFBEB),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFDE68A),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD97706).withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFD97706).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              size: 18,
              color: Color(0xFFB45309),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$count ${count == 1 ? 'Bill' : 'Bills'} Awaiting Collection',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF92400E),
                  ),
                ),
                const SizedBox(height: 1),
                const Text(
                  'Total Outstanding Balance',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          ),
          Text(
            total.toCurrency(),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: Color(0xFFB45309),
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────── Bills List & Cards ───────────────────────────

  Widget _buildBillsList(BuildContext context, List<PendingBill> bills) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int crossAxisCount = 1;
        if (width >= 900) {
          crossAxisCount = 3;
        } else if (width >= 600) {
          crossAxisCount = 2;
        }

        if (crossAxisCount == 1) {
          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: bills.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final bill = bills[index];
              return _PendingPaymentBillCard(
                key: ValueKey('bill_${bill.billId}_${bill.billNo}'),
                bill: bill,
                isOpening: _openingBillId == bill.billId,
                onCollectPayment: () => _openPayment(bill),
              );
            },
          );
        }

        // Multi-column Grid for Tablets / POS Form Factors
        return GridView.builder(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            mainAxisExtent: 220,
          ),
          itemCount: bills.length,
          itemBuilder: (context, index) {
            final bill = bills[index];
            return _PendingPaymentBillCard(
              key: ValueKey('bill_${bill.billId}_${bill.billNo}'),
              bill: bill,
              isOpening: _openingBillId == bill.billId,
              onCollectPayment: () => _openPayment(bill),
            );
          },
        );
      },
    );
  }

  // ────────────────────────── Skeleton Loading ─────────────────────────────

  Widget _buildSkeletonView(BuildContext context) {
    return Shimmer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          int crossAxisCount = 1;
          if (width >= 900) {
            crossAxisCount = 3;
          } else if (width >= 600) {
            crossAxisCount = 2;
          }

          if (crossAxisCount == 1) {
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              itemCount: 5,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _buildCardSkeleton(),
            );
          }

          return GridView.builder(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              mainAxisExtent: 220,
            ),
            itemCount: 6,
            itemBuilder: (context, index) => _buildCardSkeleton(),
          );
        },
      ),
    );
  }

  Widget _buildCardSkeleton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShimmerBone.pill(
                      width: 75,
                      height: 20,
                      color: AppColors.primary.withValues(alpha: 0.15),
                    ),
                    const ShimmerBone.pill(
                      width: 65,
                      height: 20,
                      color: Color(0xFFE2E8F0),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    const ShimmerBone.circular(size: 14),
                    const SizedBox(width: 6),
                    ShimmerBone.rectangular(
                      width: 140,
                      height: 14,
                      borderRadius: BorderRadius.circular(4),
                      color: AppColors.textPrimary.withValues(alpha: 0.2),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShimmerBone.rectangular(
                      width: 80,
                      height: 14,
                      borderRadius: BorderRadius.circular(4),
                      color: const Color(0xFFCBD5E1),
                    ),
                    ShimmerBone.rectangular(
                      width: 90,
                      height: 18,
                      borderRadius: BorderRadius.circular(4),
                      color: const Color(0xFFCBD5E1),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ShimmerBone.rectangular(
                  width: double.infinity,
                  height: 42,
                  borderRadius: BorderRadius.circular(10),
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────── Empty & Error States ─────────────────────────

  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 80),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified_rounded,
                        size: 40,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'All Payments Settled',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'There are no pending or partially paid bills awaiting payment.\nPull down to check for updates.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilteredEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 60),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.search_off_rounded,
                        size: 36,
                        color: Color(0xFFD97706),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'No Matching Pending Bills',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _searchQuery.isNotEmpty
                          ? 'No pending bills match "$_searchQuery".'
                          : 'No pending bills found for the selected date filter.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: AppColors.primary,
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                        ),
                        onPressed: _onClearFilters,
                        icon: const Icon(
                          Icons.refresh_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        label: const Text(
                          'Reset Filters',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(String error) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 80),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.cloud_off_rounded,
                      size: 50,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Could not load pending bills',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _loadBills,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Card: Pending Payment Bill Card (Actionable with "COLLECT PAYMENT")
// ──────────────────────────────────────────────────────────────────────────────

class _PendingPaymentBillCard extends StatelessWidget {
  final PendingBill bill;
  final bool isOpening;
  final VoidCallback onCollectPayment;

  const _PendingPaymentBillCard({
    super.key,
    required this.bill,
    required this.isOpening,
    required this.onCollectPayment,
  });

  @override
  Widget build(BuildContext context) {
    final partial = bill.isPartiallyPaid;
    final toneColor =
        partial ? const Color(0xFFD97706) : const Color(0xFFDC2626);
    final toneBg =
        partial ? const Color(0xFFFEF3C7) : const Color(0xFFFEE2E2);
    final toneBorder =
        partial ? const Color(0xFFFDE68A) : const Color(0xFFFECACA);

    final displayBillNo =
        bill.billNo.isNotEmpty
            ? (bill.billNo.startsWith('BL') || bill.billNo.startsWith('#')
                ? bill.billNo
                : '#${bill.billNo}')
            : (bill.orderNo.isNotEmpty ? '#${bill.orderNo}' : '#BILL');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              partial
                  ? const Color(0xFFF59E0B).withValues(alpha: 0.35)
                  : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color:
                partial
                    ? const Color(0xFFF59E0B).withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: 2-Tier responsive layout
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tier 1: Bill Number Badge + Payment Status Pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3.5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.receipt_rounded,
                              size: 12,
                              color: AppColors.primaryDark,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                displayBillNo,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryDark,
                                  letterSpacing: 0.2,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: toneBg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: toneBorder),
                      ),
                      child: Text(
                        bill.paymentStatus.isNotEmpty
                            ? bill.paymentStatus.toUpperCase()
                            : (partial ? 'PARTIALLY PAID' : 'NOT PAID'),
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: toneColor,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),

                // Tier 2: Customer info (Left) + Timestamp (Right)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_outline_rounded,
                      size: 14,
                      color: AppColors.textSecondary.withValues(alpha: 0.85),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        bill.customerName.isNotEmpty
                            ? bill.customerName
                            : (bill.orderNo.isNotEmpty &&
                                    bill.orderNo != bill.billNo
                                ? 'Order #${bill.orderNo}'
                                : 'Walk-in Guest'),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 12,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 3.5),
                        Text(
                          bill.billDate != null
                              ? bill.billDate!.timeAgo()
                              : 'Pending',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Body: Item count, Amount Due, and Action Button
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        '${bill.itemCount} ${bill.itemCount == 1 ? 'item' : 'items'}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'AMOUNT DUE',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.3,
                          ),
                        ),
                        Text(
                          bill.amount.toCurrency(),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Action Button: COLLECT PAYMENT
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          partial
                              ? const Color(0xFFD97706)
                              : AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      elevation: 1,
                    ),
                    onPressed: isOpening ? null : onCollectPayment,
                    icon:
                        isOpening
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Icon(
                              Icons.payments_rounded,
                              size: 17,
                              color: Colors.white,
                            ),
                    label: Text(
                      isOpening ? 'OPENING...' : 'COLLECT PAYMENT',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                        letterSpacing: 0.3,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

