import 'package:flutter/material.dart';

import '../../../core/themes/app_colors.dart';

import '../../../data/models/order_management_model.dart';
import '../../view_models/providers/orders_management_provider.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/animations/blinking_widget.dart';

import 'widgets/order_tab_view.dart';

import 'widgets/order_detail_view.dart';
import 'widgets/channel_partner_order_detail_view.dart';

class OrdersManagementView extends StatefulWidget {
  const OrdersManagementView({super.key});

  @override
  State<OrdersManagementView> createState() => _OrdersManagementViewState();
}

class _OrdersManagementViewState extends State<OrdersManagementView>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<OrderItem> allOrders = [];
  // local loading handled by provider

  // Variables for blinking functionality
  bool _hasNewChannelPartnerOrders = true; // Set based on your logic
  int _currentTabIndex = 0;

  // Search functionality
  bool _isSearchVisible = false;
  final _searchController = TextEditingController();

  void _toggleSearch() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
      if (!_isSearchVisible) {
        // Clear search when hiding search bar
        _searchController.clear();
        Provider.of<OrdersManagementProvider>(
          context,
          listen: false,
        ).clearSearch();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Fetch real orders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrdersManagementProvider>(
        context,
        listen: false,
      ).fetchAllOrders();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Lists are provided by OrdersManagementProvider

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textOnDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Orders',
          style: TextStyle(
            color: AppColors.textOnDark,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _isSearchVisible ? Icons.close : Icons.search,
              color: AppColors.textOnDark,
            ),
            onPressed: _toggleSearch,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) {
            setState(() {
              _currentTabIndex = index;
              if (index == 3) {
                // Channel Partner tab index
                _hasNewChannelPartnerOrders =
                    false; // Stop blinking when viewed
              }
            });
          },
          indicatorColor: AppColors.accent,
          indicatorWeight: 3,
          labelColor: AppColors.textOnDark,
          unselectedLabelColor: AppColors.textOnDark.withOpacity(0.7),
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          tabs: [
            const Tab(text: 'Table'), // Simplified tab text
            const Tab(text: 'Phone'), // Simplified tab text
            const Tab(text: 'Takeaway'), // Simplified tab text
            // Blinking Channel Partner Tab
            Tab(
              child: BlinkingWidget(
                shouldBlink:
                    _hasNewChannelPartnerOrders && _currentTabIndex != 3,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Channel'),
                    if (_hasNewChannelPartnerOrders && _currentTabIndex != 3)
                      Container(
                        margin: const EdgeInsets.only(left: 4),
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      body: Consumer<OrdersManagementProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            );
          }

          return Column(
            children: [
              // Search Bar (conditional visibility)
              if (_isSearchVisible)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(16),
                  color: AppColors.surface,
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    onChanged: (value) {
                      provider.updateSearchQuery(value);
                    },
                    decoration: InputDecoration(
                      hintText: 'Search orders by ID, customer, phone, etc...',
                      hintStyle: TextStyle(color: AppColors.textHint),
                      prefixIcon: Icon(
                        Icons.search,
                        color: AppColors.textSecondary,
                      ),
                      suffixIcon:
                          provider.searchQuery.isNotEmpty
                              ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: AppColors.textSecondary,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  provider.clearSearch();
                                },
                              )
                              : null,
                      filled: true,
                      fillColor: AppColors.cardBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              // Tab Bar View
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    OrderTabView(
                      orders: provider.tableOrders,
                      orderType: 'Table Orders',
                      onOrderTap: _showOrderDetail,
                    ),
                    OrderTabView(
                      orders: provider.phoneOrders,
                      orderType: 'Phone Orders',
                      onOrderTap: _showOrderDetail,
                    ),
                    OrderTabView(
                      orders: provider.takeawayOrders,
                      orderType: 'Takeaway',
                      onOrderTap: _showOrderDetail,
                    ),
                    OrderTabView(
                      orders: provider.channelPartnerOrders,
                      orderType: 'Channel Partner',
                      onOrderTap: _showOrderDetail,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showOrderDetail(OrderItem order) {
    // Check if it's a channel partner order (third-party platform orders)
    final isChannelPartnerOrder =
        order.platformName != null &&
        [
          'Zomato',
          'Swiggy',
          'Uber Eats',
          'FoodPanda',
        ].any((platform) => order.platformName!.contains(platform));

    if (isChannelPartnerOrder) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChannelPartnerOrderDetailView(order: order),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => OrderDetailView(order: order)),
      );
    }
  }
}
