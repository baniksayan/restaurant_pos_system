import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/core/constants/currency_constants.dart';
import 'package:restaurant_pos_system/core/utils/date_time_formatter.dart';
import 'package:restaurant_pos_system/core/utils/haptic_helper.dart';
import 'package:restaurant_pos_system/core/utils/snackbar_helper.dart';
import 'package:restaurant_pos_system/data/local/hive_service.dart';
import 'package:restaurant_pos_system/data/models/pending_bill.dart';
import 'package:restaurant_pos_system/data/remote/api_service.dart';
import 'package:restaurant_pos_system/features/billing/widgets/bill_pdf_viewer_dialog.dart';
import 'package:restaurant_pos_system/features/chef/data/chef_api.dart';
import 'package:restaurant_pos_system/features/chef/models/chef_order_model.dart';
import 'package:restaurant_pos_system/features/chef/widgets/chef_status_badge.dart';
import 'package:restaurant_pos_system/features/order_taking/providers/animated_cart_provider.dart';
import 'package:restaurant_pos_system/features/order_taking/widgets/kot_pdf_viewer_dialog.dart';
import 'package:restaurant_pos_system/features/orders/providers/ready_to_collect_provider.dart';
import 'package:restaurant_pos_system/shared/services/pdf_service.dart';
import 'package:restaurant_pos_system/shared/widgets/dialogs/app_date_range_picker_dialog.dart';
import 'package:restaurant_pos_system/shared/widgets/layout/premium_refresh_indicator.dart';
import 'package:restaurant_pos_system/shared/widgets/layout/shimmer_effect.dart';

/// A FAANG-grade Reprint view for WhizEats, designed to perfectly match
/// the Ready to Collect screen architecture, design system, and UX patterns.
///
/// Features:
/// - 2-Tab Bottom Navigation Bar: Bills & KOTs.
/// - Modern top header with live status count indicators.
/// - Dynamic real-time search across bill numbers, order IDs, table numbers, items & customers.
/// - Quick date filter chips (Today, Yesterday, Custom Date Range, Past 6 Months).
/// - Reusable modal popup [AppDateRangePickerDialog] with 6-month constraint and future dates disabled.
/// - Hourglass pull-to-refresh via [PremiumRefreshIndicator].
/// - Pixel-perfect synchronized shimmer skeleton loading states.
/// - Thermal PDF generation & printing preview dialogs.
class ReprintView extends StatefulWidget {
  const ReprintView({super.key});

  @override
  State<ReprintView> createState() => _ReprintViewState();
}

class _ReprintViewState extends State<ReprintView> {
  late PageController _pageController;
  int _currentTabIndex = 0;

  // ── Bills Tab State ──
  List<PendingBill> _rawBills = [];
  bool _loadingBills = true;
  String? _billsError;
  String _billsSearchQuery = '';
  ServedDateFilter _billsDateFilter = ServedDateFilter.today;
  DateTimeRange? _billsCustomDateRange;
  String? _openingBillId;
  late TextEditingController _billsSearchController;

  // ── KOTs Tab State ──
  List<ChefOrder> _rawKots = [];
  bool _loadingKots = true;
  String? _kotsError;
  String _kotsSearchQuery = '';
  ServedDateFilter _kotsDateFilter = ServedDateFilter.today;
  DateTimeRange? _kotsCustomDateRange;
  String? _openingKotId;
  late TextEditingController _kotsSearchController;

  final List<_ReprintTabItem> _tabs = [
    _ReprintTabItem(
      icon: Icons.receipt_long_rounded,
      label: 'Bills',
      activeColor: AppColors.primary, // Indigo / Blue
    ),
    _ReprintTabItem(
      icon: Icons.soup_kitchen_rounded,
      label: 'KOTs',
      activeColor: const Color(0xFF10B981), // Emerald Green
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _billsSearchController = TextEditingController();
    _kotsSearchController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBills();
      _loadKots();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _billsSearchController.dispose();
    _kotsSearchController.dispose();
    super.dispose();
  }

  // ────────────────────────── Filtered Getters ─────────────────────────────

  List<PendingBill> get _filteredBills {
    final query = _billsSearchQuery.trim().toLowerCase();
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
        switch (_billsDateFilter) {
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
            if (_billsCustomDateRange != null) {
              final start = DateTime(
                _billsCustomDateRange!.start.year,
                _billsCustomDateRange!.start.month,
                _billsCustomDateRange!.start.day,
              );
              final end = DateTime(
                _billsCustomDateRange!.end.year,
                _billsCustomDateRange!.end.month,
                _billsCustomDateRange!.end.day,
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

      // 2. Search Query
      if (query.isNotEmpty) {
        final matchesBillNo = bill.billNo.toLowerCase().contains(query);
        final matchesOrderNo = bill.orderNo.toLowerCase().contains(query);
        final matchesCust = bill.customerName.toLowerCase().contains(query);
        final matchesStatus = bill.paymentStatus.toLowerCase().contains(query);

        if (!matchesBillNo && !matchesOrderNo && !matchesCust && !matchesStatus) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  List<ChefOrder> get _filteredKots {
    final query = _kotsSearchQuery.trim().toLowerCase();
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

    return _rawKots.where((kot) {
      // 1. Date Filter
      final kDate = kot.orderTime;
      switch (_kotsDateFilter) {
        case ServedDateFilter.today:
          if (kDate.isBefore(todayStart) || kDate.isAfter(todayEnd)) {
            return false;
          }
          break;
        case ServedDateFilter.yesterday:
          if (kDate.isBefore(yesterdayStart) || kDate.isAfter(yesterdayEnd)) {
            return false;
          }
          break;
        case ServedDateFilter.custom:
          if (_kotsCustomDateRange != null) {
            final start = DateTime(
              _kotsCustomDateRange!.start.year,
              _kotsCustomDateRange!.start.month,
              _kotsCustomDateRange!.start.day,
            );
            final end = DateTime(
              _kotsCustomDateRange!.end.year,
              _kotsCustomDateRange!.end.month,
              _kotsCustomDateRange!.end.day,
              23,
              59,
              59,
              999,
            );
            if (kDate.isBefore(start) || kDate.isAfter(end)) {
              return false;
            }
          }
          break;
        case ServedDateFilter.all:
          break;
      }

      // 2. Search Query
      if (query.isNotEmpty) {
        final matchesTable = kot.tableNumber.toLowerCase().contains(query);
        final matchesKotNo = kot.kotNo.toLowerCase().contains(query);
        final matchesOrderNum = kot.orderNumber.toLowerCase().contains(query);
        final matchesIdentifier =
            (kot.orderIdentifier ?? '').toLowerCase().contains(query);
        final matchesGenerated =
            (kot.generatedOrderNo ?? '').toLowerCase().contains(query);
        final matchesItem = kot.items.any((item) =>
            item.name.toLowerCase().contains(query) ||
            (item.specialInstructions ?? '').toLowerCase().contains(query));

        if (!matchesTable &&
            !matchesKotNo &&
            !matchesOrderNum &&
            !matchesIdentifier &&
            !matchesGenerated &&
            !matchesItem) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  bool get _isBillsFilterActive =>
      _billsSearchQuery.trim().isNotEmpty ||
      _billsDateFilter != ServedDateFilter.today;

  bool get _isKotsFilterActive =>
      _kotsSearchQuery.trim().isNotEmpty ||
      _kotsDateFilter != ServedDateFilter.today;

  // ────────────────────────── Data Fetching ────────────────────────────────

  Future<void> _loadBills({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loadingBills = true;
        _billsError = null;
      });
    }

    final outletId = HiveService.getOutletId();
    if (outletId == null || outletId <= 0) {
      if (!mounted) return;
      setState(() {
        _loadingBills = false;
        _billsError = 'No outlet selected. Please sign in again.';
      });
      return;
    }

    final now = DateTime.now();
    DateTime apiFrom;
    DateTime apiTo;

    if (_billsDateFilter == ServedDateFilter.today) {
      apiFrom = DateTime(now.year, now.month, now.day);
      apiTo = DateTime(now.year, now.month, now.day, 23, 59, 59);
    } else if (_billsDateFilter == ServedDateFilter.yesterday) {
      final y = now.subtract(const Duration(days: 1));
      apiFrom = DateTime(y.year, y.month, y.day);
      apiTo = DateTime(y.year, y.month, y.day, 23, 59, 59);
    } else if (_billsDateFilter == ServedDateFilter.custom &&
        _billsCustomDateRange != null) {
      apiFrom = DateTime(
        _billsCustomDateRange!.start.year,
        _billsCustomDateRange!.start.month,
        _billsCustomDateRange!.start.day,
      );
      apiTo = DateTime(
        _billsCustomDateRange!.end.year,
        _billsCustomDateRange!.end.month,
        _billsCustomDateRange!.end.day,
        23,
        59,
        59,
      );
    } else {
      apiFrom = DateTime(now.year, now.month - 6, now.day);
      apiTo = DateTime(now.year, now.month, now.day, 23, 59, 59);
    }

    try {
      final bills = await ApiService.getBillsForReprint(
        outletId: outletId,
        from: apiFrom,
        to: apiTo,
      );

      if (!mounted) return;
      if (bills == null) {
        setState(() {
          _loadingBills = false;
          _billsError = 'Could not load bills. Pull down to try again.';
        });
        return;
      }

      bills.sort(
        (a, b) => (b.billDate ?? DateTime(0)).compareTo(a.billDate ?? DateTime(0)),
      );
      setState(() {
        _loadingBills = false;
        _rawBills = bills;
        _billsError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingBills = false;
        _billsError = 'Could not load bills. Pull down to retry.';
      });
    }
  }

  Future<void> _loadKots({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loadingKots = true;
        _kotsError = null;
      });
    }

    final now = DateTime.now();
    DateTime apiFrom;
    DateTime apiTo;

    if (_kotsDateFilter == ServedDateFilter.today) {
      apiFrom = DateTime(now.year, now.month, now.day);
      apiTo = DateTime(now.year, now.month, now.day, 23, 59, 59);
    } else if (_kotsDateFilter == ServedDateFilter.yesterday) {
      final y = now.subtract(const Duration(days: 1));
      apiFrom = DateTime(y.year, y.month, y.day);
      apiTo = DateTime(y.year, y.month, y.day, 23, 59, 59);
    } else if (_kotsDateFilter == ServedDateFilter.custom &&
        _kotsCustomDateRange != null) {
      apiFrom = DateTime(
        _kotsCustomDateRange!.start.year,
        _kotsCustomDateRange!.start.month,
        _kotsCustomDateRange!.start.day,
      );
      apiTo = DateTime(
        _kotsCustomDateRange!.end.year,
        _kotsCustomDateRange!.end.month,
        _kotsCustomDateRange!.end.day,
        23,
        59,
        59,
      );
    } else {
      apiFrom = DateTime(now.year, now.month - 6, now.day);
      apiTo = DateTime(now.year, now.month, now.day, 23, 59, 59);
    }

    try {
      final kots = await ChefApi.fetchChefOrders(
        statusIds: const [1, 2, 3, 4, 5],
        fromDate: apiFrom,
        toDate: apiTo,
      );

      if (!mounted) return;
      kots.sort((a, b) => b.orderTime.compareTo(a.orderTime));
      setState(() {
        _loadingKots = false;
        _rawKots = kots;
        _kotsError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingKots = false;
        _kotsError = 'Could not load KOTs. Pull down to retry.';
      });
    }
  }

  // ────────────────────────── Filter Actions ───────────────────────────────

  Future<void> _setBillsDateFilter(
    ServedDateFilter filter, {
    DateTimeRange? customRange,
  }) async {
    setState(() {
      _billsDateFilter = filter;
      if (customRange != null) {
        _billsCustomDateRange = customRange;
      }
    });
    await _loadBills();
  }

  void _clearBillsFilters() {
    _billsSearchController.clear();
    setState(() {
      _billsSearchQuery = '';
      _billsDateFilter = ServedDateFilter.today;
      _billsCustomDateRange = null;
    });
    _loadBills();
  }

  Future<void> _setKotsDateFilter(
    ServedDateFilter filter, {
    DateTimeRange? customRange,
  }) async {
    setState(() {
      _kotsDateFilter = filter;
      if (customRange != null) {
        _kotsCustomDateRange = customRange;
      }
    });
    await _loadKots();
  }

  void _clearKotsFilters() {
    _kotsSearchController.clear();
    setState(() {
      _kotsSearchQuery = '';
      _kotsDateFilter = ServedDateFilter.today;
      _kotsCustomDateRange = null;
    });
    _loadKots();
  }

  Future<void> _onPickCustomDateRange(bool isBillsTab) async {
    final currentRange =
        isBillsTab ? _billsCustomDateRange : _kotsCustomDateRange;
    final picked = await AppDateRangePickerDialog.show(
      context,
      initialRange: currentRange,
    );

    if (picked != null) {
      if (isBillsTab) {
        await _setBillsDateFilter(ServedDateFilter.custom, customRange: picked);
      } else {
        await _setKotsDateFilter(ServedDateFilter.custom, customRange: picked);
      }
    }
  }

  // ────────────────────────── PDF Actions ──────────────────────────────────

  Future<void> _viewBill(PendingBill bill) async {
    await HapticHelper.triggerFeedback();
    if (!mounted) return;

    setState(() => _openingBillId = bill.billId);
    try {
      final billDetailsResponse = await ApiService.getBillDetailByBillId(
        billId: bill.billId,
      );
      final billData = billDetailsResponse?.data;
      if (!mounted) return;
      if (billDetailsResponse?.isSuccess != true || billData == null) {
        AppSnackBar.showError(context, 'Could not load this bill right now.');
        return;
      }

      String gstLabel = 'GST';
      if (billData.taxInf.isNotEmpty) {
        final totalPct = billData.taxInf.fold<double>(
          0,
          (sum, t) => sum + t.taxPercentage,
        );
        gstLabel =
            'GST (${totalPct % 1 == 0 ? totalPct.toStringAsFixed(0) : totalPct.toStringAsFixed(1)}%)';
      }
      final gstAmount =
          billData.billHeadDt.billAmountInclTax -
          billData.billHeadDt.amountAfterDisc;

      final items =
          billData.billOrderDt
              .map(
                (o) => CartItem(
                  id: o.orderId,
                  name: o.itemName,
                  price: o.itemPrice,
                  quantity: o.orderQty.round(),
                  tableId: '',
                  tableName: '',
                ),
              )
              .toList();

      final discountAmount =
          billData.billHeadDt.discountAmnt + billData.billHeadDt.specDisAmt;

      final billBytes = await PDFService.generateThermalBill(
        items: items,
        tableId: bill.orderNo,
        tableName: billData.orderChanelDt.isNotEmpty
            ? billData.orderChanelDt.first.channelName
            : bill.orderNo,
        orderNumber: bill.orderNo.isNotEmpty ? bill.orderNo : bill.billNo,
        orderTime: bill.billDate ?? DateTime.now(),
        subtotal: billData.billHeadDt.amountAfterDisc,
        gstAmount: gstAmount > 0 ? gstAmount : 0,
        total: billData.billHeadDt.billAmountInclTax,
        companyName: billData.companyDt.companyName,
        companyAddress: billData.companyDt.companyAddress,
        companyPhone: billData.companyDt.contactNo,
        companyGstNo: billData.companyDt.gstNo,
        gstLabel: gstLabel,
        billNo: billData.billHeadDt.billNo,
        customerName: billData.billHeadDt.customerName,
        customerPhone: billData.billHeadDt.custMobNo,
        discountAmount: discountAmount,
        payments: billData.paymentDetail,
      );

      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: true,
        builder:
            (context) => BillPDFViewerDialog(
              pdfBytes: billBytes,
              orderNumber: bill.billNo.isNotEmpty ? bill.billNo : bill.orderNo,
              fileName:
                  'Bill_${bill.billNo.isNotEmpty ? bill.billNo : bill.billId}.pdf',
            ),
      );
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Error opening bill: $e');
      }
    } finally {
      if (mounted) setState(() => _openingBillId = null);
    }
  }

  Future<void> _viewKot(ChefOrder kot) async {
    await HapticHelper.triggerFeedback();
    if (!mounted) return;

    setState(() => _openingKotId = kot.id);
    try {
      final items =
          kot.items
              .map(
                (i) => CartItem(
                  id: i.id,
                  name: i.name,
                  price: i.price,
                  quantity: i.quantity,
                  tableId: '',
                  tableName: kot.tableNumber,
                  specialNotes: i.specialInstructions,
                ),
              )
              .toList();

      final resolvedKotNo =
          kot.kotNo.trim().isNotEmpty ? kot.kotNo.trim() : 'KOT';
      final resolvedOrderNo =
          (kot.generatedOrderNo != null &&
                  kot.generatedOrderNo!.trim().isNotEmpty)
              ? kot.generatedOrderNo!.trim()
              : (kot.orderNumber.trim().isNotEmpty
                  ? kot.orderNumber.trim()
                  : resolvedKotNo);
      final resolvedTable =
          kot.tableNumber.trim().isNotEmpty ? kot.tableNumber.trim() : 'Table';

      final kotBytes = await PDFService.generateKOT(
        items: items,
        tableId: resolvedTable,
        tableName: resolvedTable,
        orderNumber: resolvedOrderNo,
        orderTime: kot.orderTime,
        kotNo: resolvedKotNo,
        waiterName: '',
      );

      if (!mounted) return;
      await KOTPDFViewerDialog.show(
        context,
        pdfBytes: kotBytes,
        kotNumber: resolvedKotNo,
        fileName: 'KOT_${resolvedKotNo.replaceAll('/', '_')}.pdf',
      );
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Error opening KOT: $e');
      }
    } finally {
      if (mounted) setState(() => _openingKotId = null);
    }
  }

  // ────────────────────────── Main Build ───────────────────────────────────

  @override
  Widget build(BuildContext context) {
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
            // Top Header: WhizEats Pro style with back button & dynamic context info
            _buildTopHeader(context),

            // PageView for 2 tabs: Bills & KOTs
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const ClampingScrollPhysics(),
                onPageChanged: (index) {
                  if (_currentTabIndex != index) {
                    setState(() => _currentTabIndex = index);
                  }
                },
                children: [
                  // Tab 0: Bills
                  _buildBillsTabContent(context),
                  // Tab 1: KOTs
                  _buildKotsTabContent(context),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomNavigationBar(context),
      ),
    );
  }

  // ────────────────────────── Top Header ───────────────────────────────────

  Widget _buildTopHeader(BuildContext context) {
    final isBillsTab = _currentTabIndex == 0;
    final activeCount =
        isBillsTab ? _filteredBills.length : _filteredKots.length;

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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isBillsTab ? 'Reprint Bills' : 'Reprint KOTs',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    isBillsTab
                        ? 'View, generate & reprint customer bills'
                        : 'View, generate & reprint kitchen order tickets',
                    style: const TextStyle(
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

            // Live status indicator badge pill on top right
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isBillsTab
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isBillsTab
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : const Color(0xFF10B981).withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isBillsTab
                        ? Icons.receipt_long_rounded
                        : Icons.soup_kitchen_rounded,
                    size: 13,
                    color: isBillsTab
                        ? AppColors.primaryDark
                        : const Color(0xFF059669),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$activeCount',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isBillsTab
                          ? AppColors.primaryDark
                          : const Color(0xFF059669),
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

  // ────────────────────────── Tab Content: Bills ───────────────────────────

  Widget _buildBillsTabContent(BuildContext context) {
    final bills = _filteredBills;

    return Column(
      children: [
        _buildSearchAndFilterBar(
          context: context,
          controller: _billsSearchController,
          hintText: 'Search by bill #, order #, or customer...',
          searchQuery: _billsSearchQuery,
          onSearchChanged: (val) => setState(() => _billsSearchQuery = val),
          selectedFilter: _billsDateFilter,
          customRange: _billsCustomDateRange,
          onSelectFilter: (f) => _setBillsDateFilter(f),
          onPickCustomRange: () => _onPickCustomDateRange(true),
          isFilterActive: _isBillsFilterActive,
          currentCount: bills.length,
          totalCount: _rawBills.length,
          itemLabel: 'Bills',
          onResetFilters: _clearBillsFilters,
        ),
        Expanded(
          child: PremiumRefreshIndicator(
            onRefresh: () => _loadBills(),
            child: _loadingBills && bills.isEmpty
                ? _buildSkeletonView(context)
                : _billsError != null && bills.isEmpty
                    ? _buildErrorState(_billsError!, () => _loadBills())
                    : bills.isEmpty
                        ? (_isBillsFilterActive
                            ? _buildFilteredEmptyState(
                                query: _billsSearchQuery,
                                isBillsTab: true,
                                onReset: _clearBillsFilters,
                              )
                            : _buildEmptyState(
                                isBillsTab: true,
                                onRefresh: () => _loadBills(),
                              ))
                        : _buildBillsList(context, bills),
          ),
        ),
      ],
    );
  }

  // ────────────────────────── Tab Content: KOTs ────────────────────────────

  Widget _buildKotsTabContent(BuildContext context) {
    final kots = _filteredKots;

    return Column(
      children: [
        _buildSearchAndFilterBar(
          context: context,
          controller: _kotsSearchController,
          hintText: 'Search by table, KOT #, or item name...',
          searchQuery: _kotsSearchQuery,
          onSearchChanged: (val) => setState(() => _kotsSearchQuery = val),
          selectedFilter: _kotsDateFilter,
          customRange: _kotsCustomDateRange,
          onSelectFilter: (f) => _setKotsDateFilter(f),
          onPickCustomRange: () => _onPickCustomDateRange(false),
          isFilterActive: _isKotsFilterActive,
          currentCount: kots.length,
          totalCount: _rawKots.length,
          itemLabel: 'KOTs',
          onResetFilters: _clearKotsFilters,
        ),
        Expanded(
          child: PremiumRefreshIndicator(
            onRefresh: () => _loadKots(),
            child: _loadingKots && kots.isEmpty
                ? _buildSkeletonView(context)
                : _kotsError != null && kots.isEmpty
                    ? _buildErrorState(_kotsError!, () => _loadKots())
                    : kots.isEmpty
                        ? (_isKotsFilterActive
                            ? _buildFilteredEmptyState(
                                query: _kotsSearchQuery,
                                isBillsTab: false,
                                onReset: _clearKotsFilters,
                              )
                            : _buildEmptyState(
                                isBillsTab: false,
                                onRefresh: () => _loadKots(),
                              ))
                        : _buildKotsList(context, kots),
          ),
        ),
      ],
    );
  }

  // ────────────────────────── Search & Filter Bar ──────────────────────────

  Widget _buildSearchAndFilterBar({
    required BuildContext context,
    required TextEditingController controller,
    required String hintText,
    required String searchQuery,
    required ValueChanged<String> onSearchChanged,
    required ServedDateFilter selectedFilter,
    required DateTimeRange? customRange,
    required ValueChanged<ServedDateFilter> onSelectFilter,
    required VoidCallback onPickCustomRange,
    required bool isFilterActive,
    required int currentCount,
    required int totalCount,
    required String itemLabel,
    required VoidCallback onResetFilters,
  }) {
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
          // Dynamic Search Field
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: searchQuery.isNotEmpty
                    ? AppColors.primary.withValues(alpha: 0.5)
                    : const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            child: TextField(
              controller: controller,
              onChanged: onSearchChanged,
              textInputAction: TextInputAction.search,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: hintText,
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
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.cancel_rounded,
                          size: 18,
                          color: Color(0xFF94A3B8),
                        ),
                        onPressed: () {
                          controller.clear();
                          onSearchChanged('');
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

          // Horizontal Date Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildDateFilterChip(
                  label: 'Today',
                  icon: Icons.today_rounded,
                  isSelected: selectedFilter == ServedDateFilter.today,
                  onTap: () => onSelectFilter(ServedDateFilter.today),
                ),
                const SizedBox(width: 8),
                _buildDateFilterChip(
                  label: 'Yesterday',
                  icon: Icons.history_rounded,
                  isSelected: selectedFilter == ServedDateFilter.yesterday,
                  onTap: () => onSelectFilter(ServedDateFilter.yesterday),
                ),
                const SizedBox(width: 8),
                _buildDateFilterChip(
                  label: _getCustomDateChipLabel(selectedFilter, customRange),
                  icon: Icons.calendar_month_rounded,
                  isSelected: selectedFilter == ServedDateFilter.custom,
                  onTap: onPickCustomRange,
                ),
                const SizedBox(width: 8),
                _buildDateFilterChip(
                  label: 'Past 6 Months',
                  icon: Icons.history_toggle_off_rounded,
                  isSelected: selectedFilter == ServedDateFilter.all,
                  onTap: () => onSelectFilter(ServedDateFilter.all),
                ),
              ],
            ),
          ),

          // Active filter indicator strip
          if (isFilterActive) ...[
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
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Showing $currentCount of $totalCount $itemLabel',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: onResetFilters,
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

  String _getCustomDateChipLabel(
    ServedDateFilter filter,
    DateTimeRange? customRange,
  ) {
    if (filter == ServedDateFilter.custom && customRange != null) {
      final start = customRange.start;
      final end = customRange.end;
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
            boxShadow: isSelected
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

  // ────────────────────────── Lists & Cards ────────────────────────────────

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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            itemCount: bills.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final bill = bills[index];
              return _ReprintBillCard(
                key: ValueKey('bill_${bill.billId}'),
                bill: bill,
                isOpening: _openingBillId == bill.billId,
                onViewBill: () => _viewBill(bill),
              );
            },
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
          itemCount: bills.length,
          itemBuilder: (context, index) {
            final bill = bills[index];
            return _ReprintBillCard(
              key: ValueKey('bill_${bill.billId}'),
              bill: bill,
              isOpening: _openingBillId == bill.billId,
              onViewBill: () => _viewBill(bill),
            );
          },
        );
      },
    );
  }

  Widget _buildKotsList(BuildContext context, List<ChefOrder> kots) {
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            itemCount: kots.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final kot = kots[index];
              return _ReprintKotCard(
                key: ValueKey('kot_${kot.id}'),
                kot: kot,
                isOpening: _openingKotId == kot.id,
                onViewKot: () => _viewKot(kot),
              );
            },
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
            mainAxisExtent: 290,
          ),
          itemCount: kots.length,
          itemBuilder: (context, index) {
            final kot = kots[index];
            return _ReprintKotCard(
              key: ValueKey('kot_${kot.id}'),
              kot: kot,
              isOpening: _openingKotId == kot.id,
              onViewKot: () => _viewKot(kot),
            );
          },
        );
      },
    );
  }

  // ────────────────────────── Skeleton State ───────────────────────────────

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
              itemCount: 4,
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
              mainAxisExtent: 250,
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ShimmerLoading(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ShimmerBone.pill(
                        width: 70,
                        height: 20,
                        color: AppColors.primary.withValues(alpha: 0.15),
                      ),
                      const ShimmerBone.pill(
                        width: 60,
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
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Column(
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
                        width: 70,
                        height: 16,
                        borderRadius: BorderRadius.circular(4),
                        color: AppColors.primaryDark.withValues(alpha: 0.3),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ShimmerBone.rectangular(
                    width: double.infinity,
                    height: 42,
                    borderRadius: BorderRadius.circular(10),
                    color: AppColors.primary.withValues(alpha: 0.15),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────────────── Empty & Error States ─────────────────────────

  Widget _buildEmptyState({
    required bool isBillsTab,
    required Future<void> Function() onRefresh,
  }) {
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
                        color: isBillsTab
                            ? AppColors.primary.withValues(alpha: 0.08)
                            : const Color(0xFF10B981).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isBillsTab
                            ? Icons.receipt_long_rounded
                            : Icons.soup_kitchen_rounded,
                        size: 40,
                        color: isBillsTab
                            ? AppColors.primary
                            : const Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isBillsTab ? 'No Bills Found Today' : 'No KOTs Found Today',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isBillsTab
                          ? 'No customer bills were generated for today.\nPull down to check for updates.'
                          : 'No kitchen orders were placed for today.\nPull down to refresh.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
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

  Widget _buildFilteredEmptyState({
    required String query,
    required bool isBillsTab,
    required VoidCallback onReset,
  }) {
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
                        color: AppColors.primary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.search_off_rounded,
                        size: 36,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      isBillsTab ? 'No Matching Bills' : 'No Matching KOTs',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      query.isNotEmpty
                          ? 'No ${isBillsTab ? "bills" : "KOTs"} match "$query".'
                          : 'No ${isBillsTab ? "bills" : "KOTs"} found for the selected date filter.',
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
                        onPressed: onReset,
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

  Widget _buildErrorState(String error, VoidCallback onRetry) {
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
                      'Could not load records',
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
                        onPressed: onRetry,
                        icon: const Icon(
                          Icons.refresh_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        label: const Text(
                          'Try Again',
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

  // ────────────────────────── Bottom Navigation Bar ────────────────────────

  Widget _buildBottomNavigationBar(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Container(
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
            border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1)),
          ),
          child: Row(
            children: List.generate(_tabs.length, (index) {
              final isSelected = index == _currentTabIndex;
              final tab = _tabs[index];
              final badgeCount =
                  index == 0 ? _filteredBills.length : _filteredKots.length;

              return Expanded(
                child: _ReprintNavBarItem(
                  tab: tab,
                  isSelected: isSelected,
                  badgeCount: badgeCount,
                  onTap: () {
                    if (!isSelected) {
                      HapticFeedback.selectionClick();
                      setState(() => _currentTabIndex = index);
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Bottom Nav Tab Model & Item Widget
// ──────────────────────────────────────────────────────────────────────────────

class _ReprintTabItem {
  final IconData icon;
  final String label;
  final Color activeColor;

  _ReprintTabItem({
    required this.icon,
    required this.label,
    required this.activeColor,
  });
}

class _ReprintNavBarItem extends StatelessWidget {
  final _ReprintTabItem tab;
  final bool isSelected;
  final int badgeCount;
  final VoidCallback onTap;

  const _ReprintNavBarItem({
    required this.tab,
    required this.isSelected,
    required this.badgeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        padding: EdgeInsets.symmetric(horizontal: isSelected ? 12 : 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? tab.activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(28),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: tab.activeColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: TweenAnimationBuilder<Color?>(
                      duration: const Duration(milliseconds: 280),
                      tween: ColorTween(
                        begin: Colors.grey[500],
                        end: isSelected ? Colors.white : Colors.grey[500],
                      ),
                      builder: (context, color, _) {
                        return Icon(tab.icon, color: color, size: 22);
                      },
                    ),
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      right: -9,
                      top: -8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4.5,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isSelected
                                ? [Colors.white, Colors.white70]
                                : [
                                    const Color(0xFFFF6B6B),
                                    const Color(0xFFEF4444),
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? tab.activeColor : Colors.white,
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isSelected
                                  ? Colors.black.withValues(alpha: 0.15)
                                  : const Color(0xFFEF4444).withValues(alpha: 0.4),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 15,
                          minHeight: 15,
                        ),
                        child: Center(
                          child: Text(
                            badgeCount > 99 ? '99+' : '$badgeCount',
                            style: TextStyle(
                              color: isSelected ? tab.activeColor : Colors.white,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                              height: 1.0,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                child: isSelected
                    ? Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 220),
                          opacity: isSelected ? 1 : 0,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              tab.label,
                              maxLines: 1,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Tab 0: Bill Card Component
// ──────────────────────────────────────────────────────────────────────────────

class _ReprintBillCard extends StatelessWidget {
  final PendingBill bill;
  final bool isOpening;
  final VoidCallback onViewBill;

  const _ReprintBillCard({
    super.key,
    required this.bill,
    required this.isOpening,
    required this.onViewBill,
  });

  @override
  Widget build(BuildContext context) {
    final paid = bill.isPaid == 2;
    final partiallyPaid = bill.isPaid == 1;

    final Color statusColor = paid
        ? const Color(0xFF10B981)
        : partiallyPaid
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);

    final displayBillNo = bill.billNo.isNotEmpty
        ? (bill.billNo.startsWith('#') || bill.billNo.startsWith('BL')
            ? bill.billNo
            : '#${bill.billNo}')
        : (bill.orderNo.isNotEmpty ? '#${bill.orderNo}' : '#BILL');

    final dateStr = bill.billDate != null
        ? DateTimeFormatter.formatDateTime(bill.billDate!)
        : 'Just now';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header Tier ──
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
                // Row 1: Bill Badge + Status Pill
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
                              Icons.receipt_long_rounded,
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
                                  letterSpacing: 0.3,
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
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        bill.paymentStatus.isNotEmpty
                            ? bill.paymentStatus
                            : (paid
                                ? 'Paid'
                                : partiallyPaid
                                    ? 'Partially Paid'
                                    : 'Not Paid'),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),

                // Row 2: Customer / Order details (Left) + Time (Right)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.person_rounded,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        bill.customerName.isNotEmpty
                            ? bill.customerName
                            : (bill.orderNo.isNotEmpty
                                ? 'Order #${bill.orderNo}'
                                : 'Walk-in Customer'),
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2,
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
                          size: 13,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 3.5),
                        Text(
                          bill.billDate != null
                              ? bill.billDate!.timeAgo()
                              : 'Today',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
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

          // ── Content & Action Bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${bill.itemCount} item${bill.itemCount == 1 ? '' : 's'}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          dateStr,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      CurrencyConstants.format(bill.amount),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Action Button: Full-width VIEW & REPRINT BILL
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                    onPressed: isOpening ? null : onViewBill,
                    icon: isOpening
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.print_rounded, size: 17),
                    label: Text(
                      isOpening ? 'GENERATING...' : 'VIEW & REPRINT BILL',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        letterSpacing: 0.3,
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

// ──────────────────────────────────────────────────────────────────────────────
// Tab 1: KOT Card Component
// ──────────────────────────────────────────────────────────────────────────────

class _ReprintKotCard extends StatelessWidget {
  final ChefOrder kot;
  final bool isOpening;
  final VoidCallback onViewKot;

  const _ReprintKotCard({
    super.key,
    required this.kot,
    required this.isOpening,
    required this.onViewKot,
  });

  @override
  Widget build(BuildContext context) {
    final displayKotNo = kot.kotNo.isNotEmpty
        ? (kot.kotNo.startsWith('KOT') || kot.kotNo.startsWith('#')
            ? kot.kotNo
            : '#${kot.kotNo}')
        : (kot.orderNumber.isNotEmpty
            ? '#${kot.orderNumber}'
            : '#KOT');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header: Table + Time + Status Badge ──
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
                // Tier 1: Table Badge + Status Badge
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
                              Icons.table_restaurant_rounded,
                              size: 12,
                              color: AppColors.primaryDark,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                kot.tableNumber.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryDark,
                                  letterSpacing: 0.3,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ChefStatusBadge(status: kot.status),
                  ],
                ),
                const SizedBox(height: 7),

                // Tier 2: KOT Ticket Number (Left) + Timestamp (Right)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long_rounded,
                      size: 14,
                      color: AppColors.textSecondary.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        displayKotNo,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2,
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
                          size: 13,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 3.5),
                        Text(
                          kot.timeAgo,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
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

          // ── Items List & Action Button ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...kot.items.map((item) => _buildItemTile(item)),
                const SizedBox(height: 12),

                // Action Button: Full-width VIEW & REPRINT KOT
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                    onPressed: isOpening ? null : onViewKot,
                    icon: isOpening
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.print_rounded, size: 17),
                    label: Text(
                      isOpening ? 'GENERATING...' : 'VIEW & REPRINT KOT',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        letterSpacing: 0.3,
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

  Widget _buildItemTile(ChefOrderItem item) {
    final hasNote = (item.specialInstructions ?? '').trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.25),
              ),
            ),
            child: Text(
              '${item.quantity}×',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                if (hasNote) ...[
                  const SizedBox(height: 2.5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.edit_note_rounded,
                          size: 13,
                          color: Color(0xFFD97706),
                        ),
                        const SizedBox(width: 3.5),
                        Flexible(
                          child: Text(
                            item.specialInstructions!,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF92400E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
