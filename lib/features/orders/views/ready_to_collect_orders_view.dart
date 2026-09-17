import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/core/utils/haptic_helper.dart';
import 'package:restaurant_pos_system/core/utils/snackbar_helper.dart';
import 'package:restaurant_pos_system/features/chef/models/chef_order_model.dart';
import 'package:restaurant_pos_system/features/chef/widgets/chef_status_badge.dart';
import 'package:restaurant_pos_system/features/orders/providers/ready_to_collect_provider.dart';
import 'package:restaurant_pos_system/shared/widgets/dialogs/app_date_range_picker_dialog.dart';
import 'package:restaurant_pos_system/shared/widgets/layout/premium_refresh_indicator.dart';
import 'package:restaurant_pos_system/shared/widgets/layout/shimmer_effect.dart';

/// A FAANG-grade kitchen pass management view for WhizEats Pro waiters.
/// Features a 2-tab bottom navigation bar:
///   1. Ready to Collect: Active prepared orders waiting for waiter pickup.
///   2. All KOTs: Served KOTs history (View-Only, no actions available).
class ReadyToCollectOrdersView extends StatefulWidget {
  final int initialTabIndex;

  const ReadyToCollectOrdersView({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<ReadyToCollectOrdersView> createState() =>
      _ReadyToCollectOrdersViewState();
}

class _ReadyToCollectOrdersViewState extends State<ReadyToCollectOrdersView> {
  late PageController _pageController;
  late TextEditingController _searchController;
  late int _currentTabIndex;
  final Set<String> _confirming = {};

  final List<_PassTabItem> _tabs = [
    _PassTabItem(
      icon: Icons.room_service_rounded,
      label: 'Ready to Collect',
      activeColor: const Color(0xFF10B981), // Emerald Green
    ),
    _PassTabItem(
      icon: Icons.receipt_long_rounded,
      label: 'All KOTs',
      activeColor: AppColors.primary, // Indigo / Blue
    ),
  ];

  @override
  void initState() {
    super.initState();
    _currentTabIndex = widget.initialTabIndex;
    _pageController = PageController(initialPage: _currentTabIndex);
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ReadyToCollectProvider>();
      provider.changeTabIndex(_currentTabIndex);
      provider.fetchOrders();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() =>
      context.read<ReadyToCollectProvider>().fetchOrders();

  Future<void> _onPickCustomDateRange(
    BuildContext context,
    ReadyToCollectProvider provider,
  ) async {
    final picked = await AppDateRangePickerDialog.show(
      context,
      initialRange: provider.customDateRange,
    );

    if (picked != null) {
      await provider.setServedDateFilter(
        ServedDateFilter.custom,
        customRange: picked,
      );
    }
  }

  void _onClearFilters(ReadyToCollectProvider provider) {
    _searchController.clear();
    provider.clearServedFilters();
  }

  Future<void> _onMarkCollected(
    BuildContext ctx,
    ReadyToCollectProvider provider,
    ChefOrder order,
  ) async {
    if (_confirming.contains(order.id)) return;
    setState(() => _confirming.add(order.id));

    await HapticHelper.triggerFeedback();
    if (!ctx.mounted) return;

    final confirmed = await showDialog<bool>(
      context: ctx,
      barrierColor: Colors.black.withValues(alpha: 0.25),
      builder: (dialogCtx) => _CollectConfirmDialog(
        kotNo: order.kotNo,
        tableNumber: order.tableNumber,
      ),
    );

    if (!mounted) return;
    setState(() => _confirming.remove(order.id));

    if (confirmed == true) {
      final success = await provider.markAsCollected(order.id);
      if (ctx.mounted) {
        final displayKotNo = order.kotNo.startsWith('#') || order.kotNo.startsWith('KOT')
            ? order.kotNo
            : '#${order.kotNo}';
        if (success) {
          AppSnackBar.showSuccess(
            ctx,
            'Order $displayKotNo marked as Delivered & Served',
          );
        } else {
          AppSnackBar.showError(
            ctx,
            'Failed to update Order $displayKotNo status. Please try again.',
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReadyToCollectProvider>();

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
            _buildTopHeader(context, provider),

            // PageView for 2 tabs: Ready to Collect & All KOTs (Served)
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const ClampingScrollPhysics(),
                onPageChanged: (index) {
                  if (_currentTabIndex != index) {
                    setState(() => _currentTabIndex = index);
                    provider.changeTabIndex(index);
                  }
                },
                children: [
                  // Tab 0: Ready to Collect (Active)
                  _buildTabContent(
                    context: context,
                    provider: provider,
                    orders: provider.readyOrders,
                    isReadyTab: true,
                  ),
                  // Tab 1: All KOTs (Served - View Only with Search & Date Filters)
                  _buildTabContent(
                    context: context,
                    provider: provider,
                    orders: provider.servedOrders,
                    isReadyTab: false,
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomNavigationBar(context, provider),
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context, ReadyToCollectProvider provider) {
    final isReadyTab = _currentTabIndex == 0;
    final activeCount = isReadyTab ? provider.readyCount : provider.servedCount;

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
                    isReadyTab ? 'Ready to Collect' : 'All KOTs (Served)',
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
                    isReadyTab
                        ? 'Food prepared & waiting on the kitchen pass'
                        : 'Completed and served kitchen order history',
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
                color: isReadyTab
                    ? const Color(0xFF10B981).withValues(alpha: 0.12)
                    : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isReadyTab
                      ? const Color(0xFF10B981).withValues(alpha: 0.25)
                      : AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isReadyTab
                        ? Icons.room_service_rounded
                        : Icons.done_all_rounded,
                    size: 13,
                    color: isReadyTab
                        ? const Color(0xFF059669)
                        : AppColors.primaryDark,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$activeCount',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isReadyTab
                          ? const Color(0xFF059669)
                          : AppColors.primaryDark,
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

  Widget _buildTabContent({
    required BuildContext context,
    required ReadyToCollectProvider provider,
    required List<ChefOrder> orders,
    required bool isReadyTab,
  }) {
    if (isReadyTab) {
      // Tab 0: Ready to Collect
      return PremiumRefreshIndicator(
        onRefresh: _refresh,
        child: provider.isLoading && orders.isEmpty
            ? _buildSkeletonView(context)
            : provider.error != null && orders.isEmpty
                ? _buildErrorState(provider.error!)
                : orders.isEmpty
                    ? _buildEmptyState(true)
                    : _buildOrdersList(context, provider, orders, true),
      );
    }

    // Tab 1: All KOTs (Served History) with pinned search & date filter header
    return Column(
      children: [
        _buildAllKotsSearchAndFilterBar(context, provider),
        Expanded(
          child: PremiumRefreshIndicator(
            onRefresh: _refresh,
            child: provider.isLoading && orders.isEmpty
                ? _buildSkeletonView(context)
                : provider.error != null && orders.isEmpty
                    ? _buildErrorState(provider.error!)
                    : orders.isEmpty
                        ? (provider.isServedFilterActive
                            ? _buildFilteredEmptyState(provider)
                            : _buildEmptyState(false))
                        : _buildOrdersList(context, provider, orders, false),
          ),
        ),
      ],
    );
  }

  Widget _buildAllKotsSearchAndFilterBar(
    BuildContext context,
    ReadyToCollectProvider provider,
  ) {
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
                color: provider.servedSearchQuery.isNotEmpty
                    ? AppColors.primary.withValues(alpha: 0.5)
                    : const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => provider.setServedSearchQuery(val),
              textInputAction: TextInputAction.search,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Search by table, KOT #, item name...',
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
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.cancel_rounded,
                          size: 18,
                          color: Color(0xFF94A3B8),
                        ),
                        onPressed: () {
                          _searchController.clear();
                          provider.setServedSearchQuery('');
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
                  isSelected:
                      provider.servedDateFilter == ServedDateFilter.today,
                  onTap: () {
                    provider.setServedDateFilter(ServedDateFilter.today);
                  },
                ),
                const SizedBox(width: 8),
                _buildDateFilterChip(
                  label: 'Yesterday',
                  icon: Icons.history_rounded,
                  isSelected:
                      provider.servedDateFilter == ServedDateFilter.yesterday,
                  onTap: () {
                    provider.setServedDateFilter(ServedDateFilter.yesterday);
                  },
                ),
                const SizedBox(width: 8),
                _buildDateFilterChip(
                  label: _getCustomDateChipLabel(provider),
                  icon: Icons.calendar_month_rounded,
                  isSelected:
                      provider.servedDateFilter == ServedDateFilter.custom,
                  onTap: () => _onPickCustomDateRange(context, provider),
                ),
                const SizedBox(width: 8),
                _buildDateFilterChip(
                  label: 'Past 6 Months',
                  icon: Icons.history_toggle_off_rounded,
                  isSelected: provider.servedDateFilter == ServedDateFilter.all,
                  onTap: () {
                    provider.setServedDateFilter(ServedDateFilter.all);
                  },
                ),
              ],
            ),
          ),

          // Active filter indicator strip
          if (provider.isServedFilterActive) ...[
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
                      'Showing ${provider.servedCount} of ${provider.rawServedCount} KOTs',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () => _onClearFilters(provider),
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

  String _getCustomDateChipLabel(ReadyToCollectProvider provider) {
    if (provider.servedDateFilter == ServedDateFilter.custom &&
        provider.customDateRange != null) {
      final start = provider.customDateRange!.start;
      final end = provider.customDateRange!.end;
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

  Widget _buildFilteredEmptyState(ReadyToCollectProvider provider) {
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
                    const Text(
                      'No Matching KOTs',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      provider.servedSearchQuery.isNotEmpty
                          ? 'No served orders match "${provider.servedSearchQuery}".'
                          : 'No served orders found for the selected date filter.',
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
                          side: const BorderSide(color: AppColors.primary, width: 1.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        ),
                        onPressed: () => _onClearFilters(provider),
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

  Widget _buildOrdersList(
    BuildContext context,
    ReadyToCollectProvider provider,
    List<ChefOrder> orders,
    bool isReadyTab,
  ) {
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
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final order = orders[index];
              return isReadyTab
                  ? _ReadyToCollectCard(
                      key: ValueKey('ready_${order.id}'),
                      order: order,
                      isConfirming: _confirming.contains(order.id),
                      onMarkCollected: () =>
                          _onMarkCollected(context, provider, order),
                    )
                  : _ServedKotCard(
                      key: ValueKey('served_${order.id}'),
                      order: order,
                    );
            },
          );
        }

        // Multi-column Grid for Tablets / POS Form Factors
        return GridView.builder(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            mainAxisExtent: isReadyTab ? 320 : 270,
          ),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return isReadyTab
                ? _ReadyToCollectCard(
                    key: ValueKey('ready_${order.id}'),
                    order: order,
                    isConfirming: _confirming.contains(order.id),
                    onMarkCollected: () =>
                        _onMarkCollected(context, provider, order),
                  )
                : _ServedKotCard(
                    key: ValueKey('served_${order.id}'),
                    order: order,
                  );
          },
        );
      },
    );
  }

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
              itemBuilder: (context, index) => _buildCardSkeleton(index),
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
              mainAxisExtent: 310,
            ),
            itemCount: 6,
            itemBuilder: (context, index) => _buildCardSkeleton(index),
          );
        },
      ),
    );
  }

  Widget _buildCardSkeleton(int index) {
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
            // Header skeleton
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ShimmerBone.circular(
                              size: 11,
                              color: AppColors.primaryDark.withValues(alpha: 0.35),
                            ),
                            const SizedBox(width: 4),
                            ShimmerBone.rectangular(
                              width: 50,
                              height: 11,
                              borderRadius: BorderRadius.circular(3),
                              color: AppColors.primaryDark.withValues(alpha: 0.35),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ShimmerBone.circular(
                            size: 12,
                            color: const Color(0xFF94A3B8).withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 4),
                          ShimmerBone.rectangular(
                            width: 40,
                            height: 11,
                            borderRadius: BorderRadius.circular(3),
                            color: const Color(0xFF94A3B8).withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 8),
                          const ShimmerBone.pill(
                            width: 60,
                            height: 20,
                            color: Color(0xFFE2E8F0),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      ShimmerBone.rectangular(
                        width: 14,
                        height: 14,
                        borderRadius: BorderRadius.circular(3),
                        color: AppColors.textSecondary.withValues(alpha: 0.4),
                      ),
                      const SizedBox(width: 6),
                      ShimmerBone.rectangular(
                        width: 130,
                        height: 14,
                        borderRadius: BorderRadius.circular(4),
                        color: AppColors.textPrimary.withValues(alpha: 0.2),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Items skeleton
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Column(
                children: [
                  _buildItemSkeletonRow(hasNote: index % 2 == 0),
                  const SizedBox(height: 4),
                  _buildItemSkeletonRow(hasNote: false),
                  const SizedBox(height: 12),
                  // Button skeleton
                  ShimmerBone.rectangular(
                    width: double.infinity,
                    height: 42,
                    borderRadius: BorderRadius.circular(10),
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemSkeletonRow({required bool hasNote}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ShimmerBone.rectangular(
              width: 14,
              height: 14,
              borderRadius: BorderRadius.circular(3),
              color: AppColors.primaryDark.withValues(alpha: 0.35),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ShimmerBone.rectangular(
                  width: 130,
                  height: 14,
                  borderRadius: BorderRadius.circular(4),
                  color: const Color(0xFFCBD5E1),
                ),
                if (hasNote) ...[
                  const SizedBox(height: 4),
                  ShimmerBone.rectangular(
                    width: 90,
                    height: 10,
                    borderRadius: BorderRadius.circular(3),
                    color: const Color(0xFFFEF3C7),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isReadyTab) {
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
                        color: isReadyTab
                            ? const Color(0xFF10B981).withValues(alpha: 0.1)
                            : AppColors.primary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isReadyTab
                            ? Icons.room_service_rounded
                            : Icons.receipt_long_rounded,
                        size: 40,
                        color: isReadyTab
                            ? const Color(0xFF10B981)
                            : AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isReadyTab
                          ? 'Kitchen Pass is Clear'
                          : 'No Served Orders Today',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isReadyTab
                          ? 'No prepared orders are currently waiting for waiter collection.\nPull down to check for updates.'
                          : 'Completed orders that have been served will appear here as history.\nPull down to refresh.',
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
                      'Could not load orders',
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
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomNavigationBar(
    BuildContext context,
    ReadyToCollectProvider provider,
  ) {
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
                  index == 0 ? provider.readyCount : provider.servedCount;

              return Expanded(
                child: _PassNavBarItem(
                  tab: tab,
                  isSelected: isSelected,
                  badgeCount: badgeCount,
                  onTap: () {
                    if (!isSelected) {
                      HapticFeedback.selectionClick();
                      setState(() => _currentTabIndex = index);
                      provider.changeTabIndex(index);
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

class _PassTabItem {
  final IconData icon;
  final String label;
  final Color activeColor;

  _PassTabItem({
    required this.icon,
    required this.label,
    required this.activeColor,
  });
}

class _PassNavBarItem extends StatelessWidget {
  final _PassTabItem tab;
  final bool isSelected;
  final int badgeCount;
  final VoidCallback onTap;

  const _PassNavBarItem({
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
                                : [const Color(0xFFFF6B6B), const Color(0xFFEF4444)],
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
// Tab 0 Card: Ready to Collect (Actionable with "COLLECTED & SERVED" button)
// ──────────────────────────────────────────────────────────────────────────────

class _ReadyToCollectCard extends StatelessWidget {
  final ChefOrder order;
  final bool isConfirming;
  final VoidCallback onMarkCollected;

  const _ReadyToCollectCard({
    super.key,
    required this.order,
    required this.isConfirming,
    required this.onMarkCollected,
  });

  @override
  Widget build(BuildContext context) {
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
            color: const Color(0xFF10B981).withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: 2-Tier responsive layout matching ChefOrderCard
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
                // Tier 1: Table Badge + Time Ago + Ready Status Pill
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
                          Text(
                            order.tableNumber.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryDark,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 13,
                          color: order.effectiveWaitingMinutes >= 30
                              ? const Color(0xFFEA580C)
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 3.5),
                        Text(
                          order.timeAgo,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: order.effectiveWaitingMinutes >= 30
                                ? const Color(0xFFEA580C)
                                : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const ChefStatusBadge(status: ChefOrderStatus.ready),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 7),

                // Tier 2: Receipt icon + KOT Ticket Number
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
                        order.kotNo.isNotEmpty
                            ? (order.kotNo.startsWith('KOT') ||
                                    order.kotNo.startsWith('#')
                                ? order.kotNo
                                : '#${order.kotNo}')
                            : (order.orderNumber.isNotEmpty
                                ? '#${order.orderNumber}'
                                : '#KOT'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Items List
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...order.items.map((item) => _buildItemTile(item)),
                const SizedBox(height: 12),

                // Action Button: Full-width COLLECTED & SERVED
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: isConfirming ? null : onMarkCollected,
                    icon: const Icon(Icons.done_all_rounded, size: 18),
                    label: const Text(
                      'COLLECTED & SERVED',
                      style: TextStyle(
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
      padding: const EdgeInsets.symmetric(vertical: 4.5),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                if (hasNote) ...[
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2.5,
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

// ──────────────────────────────────────────────────────────────────────────────
// Tab 1 Card: All KOTs (Served History - View Only, No Action Available)
// ──────────────────────────────────────────────────────────────────────────────

class _ServedKotCard extends StatelessWidget {
  final ChefOrder order;

  const _ServedKotCard({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: 2-Tier layout
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
                // Tier 1: Table Badge + Time Ago + Served Badge Pill
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
                        color: const Color(0xFF64748B).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFF64748B).withValues(alpha: 0.2),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.table_restaurant_rounded,
                            size: 12,
                            color: Color(0xFF475569),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            order.tableNumber.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF475569),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
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
                          order.timeAgo,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const ChefStatusBadge(status: ChefOrderStatus.served),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 7),

                // Tier 2: Receipt icon + KOT Ticket Number
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
                        order.kotNo.isNotEmpty
                            ? (order.kotNo.startsWith('KOT') ||
                                    order.kotNo.startsWith('#')
                                ? order.kotNo
                                : '#${order.kotNo}')
                            : (order.orderNumber.isNotEmpty
                                ? '#${order.orderNumber}'
                                : '#KOT'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Items List (View Only)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...order.items.map((item) => _buildItemTile(item)),
                const SizedBox(height: 10),

                // View-Only Served Status Strip
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFBBF7D0),
                      width: 1,
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 15,
                        color: Color(0xFF16A34A),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Delivered to Table & Completed',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ],
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
      padding: const EdgeInsets.symmetric(vertical: 4.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
              ),
            ),
            child: Text(
              '${item.quantity}×',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF475569),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                if (hasNote) ...[
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2.5,
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

// ──────────────────────────────────────────────────────────────────────────────
// Modern Confirmation Modal Dialog
// ──────────────────────────────────────────────────────────────────────────────

class _CollectConfirmDialog extends StatelessWidget {
  final String kotNo;
  final String tableNumber;

  const _CollectConfirmDialog({
    required this.kotNo,
    required this.tableNumber,
  });

  @override
  Widget build(BuildContext context) {
    final display = kotNo.startsWith('#') || kotNo.startsWith('KOT')
        ? kotNo
        : '#$kotNo';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      elevation: 10,
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.room_service_rounded,
                color: Color(0xFF059669),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Collect & Serve $display?',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Confirm you have collected this order from the kitchen pass and delivered it to ${tableNumber.toUpperCase()}.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      'Yes, Delivered',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
