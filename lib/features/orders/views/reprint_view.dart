import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/core/constants/currency_constants.dart';
import 'package:restaurant_pos_system/core/utils/haptic_helper.dart';
import 'package:restaurant_pos_system/core/utils/snackbar_helper.dart';
import 'package:restaurant_pos_system/data/local/hive_service.dart';
import 'package:restaurant_pos_system/data/models/pending_bill.dart';
import 'package:restaurant_pos_system/data/remote/api_service.dart';
import 'package:restaurant_pos_system/features/billing/widgets/bill_pdf_viewer_dialog.dart';
import 'package:restaurant_pos_system/features/chef/data/chef_api.dart';
import 'package:restaurant_pos_system/features/chef/models/chef_order_model.dart';
import 'package:restaurant_pos_system/features/order_taking/providers/animated_cart_provider.dart';
import 'package:restaurant_pos_system/features/order_taking/widgets/kot_pdf_viewer_dialog.dart';
import 'package:restaurant_pos_system/shared/services/pdf_service.dart';
import 'package:restaurant_pos_system/shared/widgets/layout/skeleton_loader.dart';

/// Look back at any past bill or KOT and reprint/view it — the one place
/// both live, one tab each, rather than two separate drawer entries for what
/// a cashier thinks of as a single "history" action (mirrors BillReprint in
/// the old desktop app, extended to cover KOTs too).
class ReprintView extends StatelessWidget {
  const ReprintView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('Reprint'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          bottom: TabBar(
            // Material 3's TabBar does not inherit AppBar.foregroundColor —
            // left unset, label/icon colour falls back to the theme's
            // colorScheme.primary, the same colour as this AppBar's own
            // background, making both tabs effectively invisible.
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: 'Bills', icon: Icon(Icons.receipt_long_rounded)),
              Tab(text: 'KOTs', icon: Icon(Icons.soup_kitchen_rounded)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_PastBillsTab(), _PastKotsTab()],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────── Bills tab ───────────────────

class _PastBillsTab extends StatefulWidget {
  const _PastBillsTab();

  @override
  State<_PastBillsTab> createState() => _PastBillsTabState();
}

class _PastBillsTabState extends State<_PastBillsTab>
    with AutomaticKeepAliveClientMixin {
  DateTime _selectedDate = DateTime.now();

  List<PendingBill> _bills = [];
  bool _loading = true;
  String? _error;
  String? _openingBillId; // which row's PDF is currently being fetched

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _pickDate() async {
    await HapticHelper.triggerFeedback();
    if (!mounted) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked == null || !mounted) return;
    setState(() => _selectedDate = picked);
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

    // Whole selected day, local time — defaults to today.
    final from = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final to = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      23,
      59,
      59,
    );
    // GetBillForReprint has no pageNumber/pageSize on its request DTO
    // (ReqGetBillForReprint) — the server returns the whole day's bills in
    // one shot, so there is no pagination to wire up here.
    final bills = await ApiService.getBillsForReprint(
      outletId: outletId,
      from: from,
      to: to,
    );

    if (!mounted) return;
    if (bills == null) {
      setState(() {
        _loading = false;
        _error = 'Could not load bills. Pull down to try again.';
      });
      return;
    }

    // Newest first — that's what a cashier reprinting "the last bill" wants.
    bills.sort(
      (a, b) => (b.billDate ?? DateTime(0)).compareTo(a.billDate ?? DateTime(0)),
    );
    setState(() {
      _loading = false;
      _bills = bills;
    });
  }

  /// Fetches the real bill and renders the exact same PDF the counter would
  /// have produced — never a reconstruction from local data. Mirrors
  /// OrderDetailView._viewOrDownloadBill.
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

      // The line items, mapped into the shape generateThermalBill expects.
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
              fileName: 'Bill_${bill.billNo.isNotEmpty ? bill.billNo : bill.billId}.pdf',
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        _DateFilterBar(date: _selectedDate, onTap: _pickDate),
        Expanded(
          child: RefreshIndicator(onRefresh: _load, child: _buildBody()),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder:
            (_, __) => const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: SkeletonLoader.rectangular(
                width: double.infinity,
                height: 74,
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
        icon: Icons.receipt_long_outlined,
        title: 'No bills',
        detail: 'No bills were raised on ${_formatDate(_selectedDate)}.',
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
    final paid = bill.isPaid == 2;
    final tone = paid ? AppColors.success : AppColors.warning;
    final opening = _openingBillId == bill.billId;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: opening ? null : () => _viewBill(bill),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
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
                                : (paid ? 'Paid' : 'Not Paid'),
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
                    CurrencyConstants.format(bill.amount),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (opening)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.print_outlined,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 2),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
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
  }) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
      children: [
        Icon(icon, size: 46, color: AppColors.textHint),
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

// ─────────────────────────────────────────── KOTs tab ────────────────────

class _PastKotsTab extends StatefulWidget {
  const _PastKotsTab();

  @override
  State<_PastKotsTab> createState() => _PastKotsTabState();
}

class _PastKotsTabState extends State<_PastKotsTab>
    with AutomaticKeepAliveClientMixin {
  DateTime _selectedDate = DateTime.now();

  List<ChefOrder> _kots = [];
  bool _loading = true;
  String? _error;
  String? _openingKotId;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _pickDate() async {
    await HapticHelper.triggerFeedback();
    if (!mounted) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked == null || !mounted) return;
    setState(() => _selectedDate = picked);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final from = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final to = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      23,
      59,
      59,
    );
    try {
      // fetchKotDetails (RequestFetchKot) has no pageNumber/pageSize either
      // — same as GetBillForReprint, the server returns the full day in one
      // response, so there's no pagination to add here.
      final kots = await ChefApi.fetchChefOrders(
        statusIds: const [1, 2, 3, 4], // every status — this is history, not
        // a live queue, so a rejected/served KOT should still be reprintable.
        fromDate: from,
        toDate: to,
      );
      if (!mounted) return;
      kots.sort((a, b) => b.orderTime.compareTo(a.orderTime));
      setState(() {
        _loading = false;
        _kots = kots;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load KOTs. Pull down to try again.';
      });
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

      final kotBytes = await PDFService.generateKOT(
        items: items,
        tableId: kot.tableNumber,
        tableName: kot.tableNumber,
        orderNumber: kot.generatedOrderNo ?? kot.kotNo,
        orderTime: kot.orderTime,
        kotNo: kot.kotNo,
        waiterName: '',
      );

      if (!mounted) return;
      await KOTPDFViewerDialog.show(
        context,
        pdfBytes: kotBytes,
        kotNumber: kot.kotNo,
        fileName: 'KOT_${kot.kotNo}.pdf',
      );
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Error opening KOT: $e');
      }
    } finally {
      if (mounted) setState(() => _openingKotId = null);
    }
  }

  Color _statusTone(ChefOrderStatus status) {
    switch (status) {
      case ChefOrderStatus.rejected:
        return AppColors.error;
      case ChefOrderStatus.served:
        return AppColors.success;
      case ChefOrderStatus.ready:
        return AppColors.info;
      case ChefOrderStatus.preparing:
      case ChefOrderStatus.pending:
        return AppColors.warning;
    }
  }

  String _statusLabel(ChefOrderStatus status) {
    switch (status) {
      case ChefOrderStatus.rejected:
        return 'Rejected';
      case ChefOrderStatus.served:
        return 'Served';
      case ChefOrderStatus.ready:
        return 'Ready';
      case ChefOrderStatus.preparing:
        return 'Preparing';
      case ChefOrderStatus.pending:
        return 'New';
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        _DateFilterBar(date: _selectedDate, onTap: _pickDate),
        Expanded(
          child: RefreshIndicator(onRefresh: _load, child: _buildBody()),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder:
            (_, __) => const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: SkeletonLoader.rectangular(
                width: double.infinity,
                height: 74,
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

    if (_kots.isEmpty) {
      return _message(
        icon: Icons.soup_kitchen_outlined,
        title: 'No KOTs',
        detail: 'No KOTs were sent on ${_formatDate(_selectedDate)}.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _kots.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _kotCard(_kots[index]),
    );
  }

  Widget _kotCard(ChefOrder kot) {
    final tone = _statusTone(kot.status);
    final opening = _openingKotId == kot.id;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: opening ? null : () => _viewKot(kot),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
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
                            kot.kotNo,
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
                            _statusLabel(kot.status),
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
                        kot.tableNumber,
                        '${kot.totalItemCount} item${kot.totalItemCount == 1 ? '' : 's'}',
                        _shortDateTime(kot.orderTime),
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
              if (opening)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.print_outlined,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _shortDateTime(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  Widget _message({
    required IconData icon,
    required String title,
    required String detail,
  }) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
      children: [
        Icon(icon, size: 46, color: AppColors.textHint),
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

String _formatDate(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', // ignore: prefer_const_declarations
  ];
  final today = DateTime.now();
  if (d.year == today.year && d.month == today.month && d.day == today.day) {
    return 'Today';
  }
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

/// A single date picker shared by both tabs — each tab queries its own
/// server endpoint for just that one day (both GetBillForReprint and
/// fetchKotDetails take fromDate/toDate, no rolling window), defaulting to
/// today on first load.
class _DateFilterBar extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTap;

  const _DateFilterBar({required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 15,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 10),
                Text(
                  _formatDate(date),
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.expand_more_rounded,
                  size: 18,
                  color: AppColors.textHint,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
