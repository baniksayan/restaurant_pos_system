import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/core/constants/currency_constants.dart';
import 'package:restaurant_pos_system/core/utils/date_time_formatter.dart';
import 'package:restaurant_pos_system/shared/widgets/dialogs/app_date_range_picker_dialog.dart';
import 'package:restaurant_pos_system/shared/widgets/layout/premium_refresh_indicator.dart';
import '../models/order_management_model.dart';
import '../providers/orders_management_provider.dart';
import '../widgets/order_card.dart';
import '../widgets/order_detail_view.dart';

enum _DateFilterPreset { today, yesterday, custom, past6Months }

class OrdersManagementView extends StatefulWidget {
  const OrdersManagementView({super.key});

  @override
  State<OrdersManagementView> createState() => _OrdersManagementViewState();
}

class _OrdersManagementViewState extends State<OrdersManagementView>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late PageController _pageController;
  int _currentTabIndex = 0;

  final TextEditingController _searchController = TextEditingController();
  _DateFilterPreset _selectedPreset = _DateFilterPreset.today;
  DateTimeRange? _customDateRange;

  // Multi-stop shimmer animation for skeleton loader
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _pageController = PageController(initialPage: 0);

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOutSine),
    );

    // Initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyDatePreset(_DateFilterPreset.today);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _searchController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadOrders();
    }
  }

  Future<void> _loadOrders() async {
    final provider = context.read<OrdersManagementProvider>();
    await provider.fetchAllOrders();
  }

  void _applyDatePreset(_DateFilterPreset preset) {
    setState(() => _selectedPreset = preset);
    final now = DateTime.now();
    final provider = context.read<OrdersManagementProvider>();

    switch (preset) {
      case _DateFilterPreset.today:
        final start = DateTime(now.year, now.month, now.day);
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        provider.fetchOrdersForRange(start, end);
        break;

      case _DateFilterPreset.yesterday:
        final yesterday = now.subtract(const Duration(days: 1));
        final start = DateTime(yesterday.year, yesterday.month, yesterday.day);
        final end = DateTime(
          yesterday.year,
          yesterday.month,
          yesterday.day,
          23,
          59,
          59,
        );
        provider.fetchOrdersForRange(start, end);
        break;

      case _DateFilterPreset.past6Months:
        final start = now.subtract(const Duration(days: 180));
        provider.fetchOrdersForRange(start, now);
        break;

      case _DateFilterPreset.custom:
        if (_customDateRange != null) {
          provider.fetchOrdersForRange(
            _customDateRange!.start,
            _customDateRange!.end,
          );
        }
        break;
    }
  }

  Future<void> _openCustomDateRangePicker() async {
    final now = DateTime.now();
    final firstAllowed = now.subtract(const Duration(days: 180));
    final lastAllowed = now;

    final provider = context.read<OrdersManagementProvider>();
    final initialRange = _customDateRange ??
        DateTimeRange(
          start: provider.fromDate.isAfter(firstAllowed)
              ? provider.fromDate
              : firstAllowed,
          end: provider.toDate.isBefore(lastAllowed)
              ? provider.toDate
              : lastAllowed,
        );

    final result = await AppDateRangePickerDialog.show(
      context,
      firstDate: firstAllowed,
      lastDate: lastAllowed,
      initialRange: initialRange,
    );

    if (result != null) {
      setState(() {
        _customDateRange = result;
        _selectedPreset = _DateFilterPreset.custom;
      });
      _applyDatePreset(_DateFilterPreset.custom);
    }
  }

  void _showOrderDetail(OrderItem order) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailView(order: order),
      ),
    );

    if (mounted) {
      _loadOrders();
    }
  }

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
            // ── Top Pro App Bar ──
            _buildTopHeader(context),

            // ── Pinned Search & Quick Date Filters ──
            _buildSearchAndFilterSection(context),

            // ── PageView for 3 Channel Tabs (Table, Phone, Takeaway) ──
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
                  _buildChannelOrderList(context, 0),
                  _buildChannelOrderList(context, 1),
                  _buildChannelOrderList(context, 2),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomNavigationBar(context),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Top App Bar
  // ────────────────────────────────────────────────────────────────────────────

  Widget _buildTopHeader(BuildContext context) {
    final provider = context.watch<OrdersManagementProvider>();

    final isTableTab = _currentTabIndex == 0;
    final isPhoneTab = _currentTabIndex == 1;

    final String title = isTableTab
        ? 'Table Orders'
        : (isPhoneTab ? 'Phone Orders' : 'Takeaway Orders');

    final String subtitle = isTableTab
        ? 'Dine-in table orders & status'
        : (isPhoneTab
            ? 'Direct phone delivery orders'
            : 'Quick takeaway & counter orders');

    final activeTable = provider.tableOrders
        .where((o) =>
            o.status != OrderStatusType.completed &&
            o.status != OrderStatusType.cancelled)
        .length;
    final activePhone = provider.phoneOrders
        .where((o) =>
            o.status != OrderStatusType.completed &&
            o.status != OrderStatusType.cancelled)
        .length;
    final activeTakeaway = provider.takeawayOrders
        .where((o) =>
            o.status != OrderStatusType.completed &&
            o.status != OrderStatusType.cancelled)
        .length;

    final activeCount = isTableTab
        ? activeTable
        : (isPhoneTab ? activePhone : activeTakeaway);

    final IconData tabIcon = isTableTab
        ? Icons.table_restaurant_rounded
        : (isPhoneTab
            ? Icons.phone_in_talk_rounded
            : Icons.shopping_bag_rounded);

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
                    title,
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
                    subtitle,
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
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    tabIcon,
                    size: 13,
                    color: AppColors.primaryDark,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$activeCount',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    'Active',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark.withValues(alpha: 0.8),
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

  // ────────────────────────────────────────────────────────────────────────────
  // FAANG-Grade Bottom Navigation Bar
  // ────────────────────────────────────────────────────────────────────────────

  Widget _buildBottomNavigationBar(BuildContext context) {
    final provider = context.watch<OrdersManagementProvider>();

    final tabs = [
      _OrdersTabItem(
        icon: Icons.table_restaurant_rounded,
        label: 'Table Orders',
        activeColor: AppColors.primary,
      ),
      _OrdersTabItem(
        icon: Icons.phone_in_talk_rounded,
        label: 'Phone Orders',
        activeColor: const Color(0xFF2563EB),
      ),
      _OrdersTabItem(
        icon: Icons.shopping_bag_rounded,
        label: 'Takeaway',
        activeColor: const Color(0xFFD97706),
      ),
    ];

    return Container(
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Container(
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
            border: Border(
              top: BorderSide(color: Colors.grey[200]!, width: 1),
            ),
          ),
          child: Row(
            children: List.generate(tabs.length, (index) {
              final isSelected = index == _currentTabIndex;
              final tab = tabs[index];
              final badgeCount = switch (index) {
                0 => provider.tableOrders.length,
                1 => provider.phoneOrders.length,
                _ => provider.takeawayOrders.length,
              };

              return Expanded(
                child: _OrdersNavBarItem(
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

  // ────────────────────────────────────────────────────────────────────────────
  // Pinned Search & Quick Date Filter Section
  // ────────────────────────────────────────────────────────────────────────────

  Widget _buildSearchAndFilterSection(BuildContext context) {
    final provider = context.watch<OrdersManagementProvider>();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Real-time Search Bar
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => provider.updateSearchQuery(value),
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Search by Order #, Customer, Table or Item...',
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textHint,
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear_rounded,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          provider.clearSearch();
                          setState(() {});
                        },
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 11,
                ),
                border: InputBorder.none,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Horizontal Date Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildDateChip(
                  label: 'Today',
                  preset: _DateFilterPreset.today,
                  icon: Icons.today_rounded,
                ),
                const SizedBox(width: 8),
                _buildDateChip(
                  label: 'Yesterday',
                  preset: _DateFilterPreset.yesterday,
                  icon: Icons.history_rounded,
                ),
                const SizedBox(width: 8),
                _buildDateChip(
                  label: _selectedPreset == _DateFilterPreset.custom &&
                          _customDateRange != null
                      ? '${DateTimeFormatter.formatDate(_customDateRange!.start)} - ${DateTimeFormatter.formatDate(_customDateRange!.end)}'
                      : 'Custom Date',
                  preset: _DateFilterPreset.custom,
                  icon: Icons.date_range_rounded,
                  onTap: _openCustomDateRangePicker,
                ),
                const SizedBox(width: 8),
                _buildDateChip(
                  label: 'Past 6 Months',
                  preset: _DateFilterPreset.past6Months,
                  icon: Icons.calendar_month_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateChip({
    required String label,
    required _DateFilterPreset preset,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    final isSelected = _selectedPreset == preset;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () => _applyDatePreset(preset),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryDark
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 13,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Channel Order List & Content
  // ────────────────────────────────────────────────────────────────────────────

  Widget _buildChannelOrderList(BuildContext context, int tabIndex) {
    final provider = context.watch<OrdersManagementProvider>();

    if (provider.isLoading) {
      return _buildLoadingSkeleton();
    }

    if (provider.error != null && provider.error!.isNotEmpty) {
      return _buildErrorState(provider.error!);
    }

    final List<OrderItem> orders = switch (tabIndex) {
      0 => provider.tableOrders,
      1 => provider.phoneOrders,
      _ => provider.takeawayOrders,
    };

    final channelTitle = switch (tabIndex) {
      0 => 'Table Orders',
      1 => 'Phone Orders',
      _ => 'Takeaway Orders',
    };

    if (orders.isEmpty) {
      return _buildEmptyState(
        channelTitle: channelTitle,
        isSearchActive: provider.searchQuery.isNotEmpty,
      );
    }

    return PremiumRefreshIndicator(
      onRefresh: _loadOrders,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth >= 700;

          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Summary Metrics Banner
              SliverToBoxAdapter(
                child: _buildChannelSummaryMetrics(orders, tabIndex),
              ),

              // Orders Grid / List
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
                sliver: isTablet
                    ? SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          mainAxisExtent: 220,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final order = orders[index];
                            return OrderCard(
                              order: order,
                              onTap: () => _showOrderDetail(order),
                            );
                          },
                          childCount: orders.length,
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final order = orders[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: OrderCard(
                                order: order,
                                onTap: () => _showOrderDetail(order),
                              ),
                            );
                          },
                          childCount: orders.length,
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Channel Summary Metrics Banner
  // ────────────────────────────────────────────────────────────────────────────

  Widget _buildChannelSummaryMetrics(List<OrderItem> orders, int tabIndex) {
    final totalCount = orders.length;
    final activeCount = orders
        .where((o) =>
            o.status != OrderStatusType.completed &&
            o.status != OrderStatusType.cancelled)
        .length;
    final completedCount =
        orders.where((o) => o.status == OrderStatusType.completed).length;

    final totalAmount = orders.fold<double>(
      0.0,
      (sum, item) => sum + item.totalAmount,
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildMetricColumn(
            label: 'TOTAL',
            value: '$totalCount',
            color: AppColors.primaryDark,
          ),
          _buildMetricDivider(),
          _buildMetricColumn(
            label: 'ACTIVE',
            value: '$activeCount',
            color: const Color(0xFFD97706),
          ),
          _buildMetricDivider(),
          _buildMetricColumn(
            label: 'COMPLETED',
            value: '$completedCount',
            color: const Color(0xFF10B981),
          ),
          if (totalAmount > 0) ...[
            _buildMetricDivider(),
            _buildMetricColumn(
              label: 'VOLUME',
              value: totalAmount.toCurrencyInt(),
              color: const Color(0xFF4F46E5),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricColumn({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: color,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricDivider() {
    return Container(
      width: 1,
      height: 24,
      color: const Color(0xFFF1F5F9),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Skeleton Loading State
  // ────────────────────────────────────────────────────────────────────────────

  Widget _buildLoadingSkeleton() {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, _) {
        return ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(14),
          itemCount: 4,
          itemBuilder: (context, index) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(15)),
                      border:
                          Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _shimmerBone(width: 90, height: 22, borderRadius: 6),
                        _shimmerBone(width: 80, height: 20, borderRadius: 6),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _shimmerBone(width: 160, height: 16, borderRadius: 4),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _shimmerBone(width: 85, height: 22, borderRadius: 6),
                            const SizedBox(width: 8),
                            _shimmerBone(width: 75, height: 22, borderRadius: 6),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _shimmerBone(
                          width: double.infinity,
                          height: 38,
                          borderRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _shimmerBone({
    required double width,
    required double height,
    required double borderRadius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: const [
            Color(0xFFE2E8F0),
            Color(0xFFF8FAFC),
            Color(0xFFE2E8F0),
          ],
          stops: [
            (_shimmerAnimation.value - 0.3).clamp(0.0, 1.0),
            _shimmerAnimation.value.clamp(0.0, 1.0),
            (_shimmerAnimation.value + 0.3).clamp(0.0, 1.0),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Empty & Error States
  // ────────────────────────────────────────────────────────────────────────────

  Widget _buildEmptyState({
    required String channelTitle,
    required bool isSearchActive,
  }) {
    return PremiumRefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.45,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isSearchActive
                            ? Icons.search_off_rounded
                            : Icons.receipt_long_outlined,
                        size: 32,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isSearchActive
                          ? 'No Matching Orders'
                          : 'No $channelTitle',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isSearchActive
                          ? 'Try modifying your search keywords or clear filters.'
                          : 'Orders placed for this date range will show up automatically.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (isSearchActive)
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          _searchController.clear();
                          context.read<OrdersManagementProvider>().clearSearch();
                          setState(() {});
                        },
                        icon: const Icon(Icons.clear_all_rounded, size: 16),
                        label: const Text(
                          'CLEAR SEARCH',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      )
                    else
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => _applyDatePreset(_DateFilterPreset.today),
                        icon: const Icon(Icons.today_rounded, size: 16),
                        label: const Text(
                          'SHOW TODAY\'S ORDERS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return PremiumRefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.45,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFEE2E2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.error_outline_rounded,
                        size: 32,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Failed to Load Orders',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      error,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _loadOrders,
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text(
                        'RETRY',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Bottom Nav Tab Model & Item Widget
// ──────────────────────────────────────────────────────────────────────────────

class _OrdersTabItem {
  final IconData icon;
  final String label;
  final Color activeColor;

  _OrdersTabItem({
    required this.icon,
    required this.label,
    required this.activeColor,
  });
}

class _OrdersNavBarItem extends StatelessWidget {
  final _OrdersTabItem tab;
  final bool isSelected;
  final int badgeCount;
  final VoidCallback onTap;

  const _OrdersNavBarItem({
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
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 3),
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
                          opacity: isSelected ? 1.0 : 0.0,
                          child: Text(
                            tab.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              letterSpacing: 0.2,
                            ),
                            maxLines: 1,
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


