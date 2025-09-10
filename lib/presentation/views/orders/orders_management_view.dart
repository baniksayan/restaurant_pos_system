import 'package:flutter/material.dart';

import '../../../core/themes/app_colors.dart';

import '../../../data/models/order_management_model.dart';

import '../../../shared/widgets/animations/blinking_widget.dart';

import 'widgets/order_tab_view.dart';

import 'widgets/order_detail_view.dart';

class OrdersManagementView extends StatefulWidget {
  const OrdersManagementView({super.key});

  @override
  State<OrdersManagementView> createState() => _OrdersManagementViewState();
}

class _OrdersManagementViewState extends State<OrdersManagementView>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<OrderItem> allOrders = [];
  bool isLoading = true;

  // Variables for blinking functionality
  bool _hasNewChannelPartnerOrders = true; // Set based on your logic
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => isLoading = true);
    // Simulate loading - replace with your actual API call
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      allOrders = _getMockOrders();
      isLoading = false;
    });
  }

  List<OrderItem> get tableOrders =>
      allOrders.where((o) => o.orderType == 'Table Orders').toList();

  List<OrderItem> get phoneOrders =>
      allOrders.where((o) => o.orderType == 'Phone Orders').toList();

  List<OrderItem> get takeawayOrders =>
      allOrders.where((o) => o.orderType == 'Takeaway').toList();

  List<OrderItem> get channelPartnerOrders =>
      allOrders.where((o) => o.orderType == 'Channel Partner').toList();

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
            icon: const Icon(Icons.refresh, color: AppColors.textOnDark),
            onPressed: _loadOrders,
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
      body:
          isLoading
              ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              )
              : TabBarView(
                controller: _tabController,
                children: [
                  OrderTabView(
                    orders: tableOrders,
                    orderType: 'Table Orders',
                    onOrderTap: _showOrderDetail,
                  ),
                  OrderTabView(
                    orders: phoneOrders,
                    orderType: 'Phone Orders',
                    onOrderTap: _showOrderDetail,
                  ),
                  OrderTabView(
                    orders: takeawayOrders,
                    orderType: 'Takeaway',
                    onOrderTap: _showOrderDetail,
                  ),
                  OrderTabView(
                    orders: channelPartnerOrders,
                    orderType: 'Channel Partner',
                    onOrderTap: _showOrderDetail,
                  ),
                ],
              ),
    );
  }

  void _showOrderDetail(OrderItem order) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => OrderDetailView(order: order)),
    );
  }

  List<OrderItem> _getMockOrders() {
    return [
      OrderItem(
        orderId: '12345',
        customerName: 'Savan Banik',
        phoneNumber: '+91 87684 12832',
        orderType: 'Phone Orders',
        status: OrderStatusType.pending,
        totalAmount: 25.50,
        orderTime: DateTime.now(),
        items: const [
          OrderItemDetail(
            productId: '1',
            productName: 'Chicken Butter Masala',
            quantity: 1,
            price: 25.50,
            imageUrl:
                'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=400',
          ),
        ],
      ),
      OrderItem(
        orderId: '12346',
        customerName: 'Kawshik Roy',
        phoneNumber: '+91 76795 15130',
        orderType: 'Phone Orders',
        status: OrderStatusType.accepted,
        totalAmount: 32.75,
        orderTime: DateTime.now(),
        items: const [
          OrderItemDetail(
            productId: '2',
            productName: 'Biryani Special',
            quantity: 1,
            price: 32.75,
            imageUrl:
                'https://images.unsplash.com/photo-1563379091339-03246963d25a?w=400',
          ),
        ],
      ),
      OrderItem(
        orderId: '12347',
        customerName: 'Pikan Das',
        orderType: 'Takeaway',
        status: OrderStatusType.ready,
        totalAmount: 18.99,
        orderTime: DateTime.now(),
        items: const [
          OrderItemDetail(
            productId: '3',
            productName: 'Pancakes',
            quantity: 2,
            price: 18.99,
            imageUrl:
                'https://images.unsplash.com/photo-1528207776546-365bb710ee93?w=400',
          ),
        ],
      ),
      OrderItem(
        orderId: '67890',
        customerName: 'Table Service',
        tableNumber: '3',
        waiterName: 'Pikan',
        orderType: 'Table Orders',
        status: OrderStatusType.preparing,
        totalAmount: 35.00,
        orderTime: DateTime.now(),
        items: const [
          OrderItemDetail(
            productId: '4',
            productName: 'Mixed Salad',
            quantity: 1,
            price: 35.00,
            imageUrl:
                'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400',
          ),
        ],
      ),
      // Channel Partner Orders with Platform Names
      OrderItem(
        orderId: '123456',
        customerName: 'Swiggy Order',
        orderType: 'Channel Partner',
        platformName: 'Swiggy', // Added platform name
        status: OrderStatusType.pending,
        totalAmount: 25.00,
        orderTime: DateTime.now().subtract(const Duration(minutes: 5)),
        expectedDeliveryTime: null, // Will be set when accepted
        items: const [
          OrderItemDetail(
            productId: '5',
            productName: 'Burger Combo',
            quantity: 1,
            price: 25.00,
            imageUrl:
                'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400',
          ),
        ],
      ),
      OrderItem(
        orderId: '123457',
        customerName: 'Zomato Order',
        orderType: 'Channel Partner',
        platformName: 'Zomato', // Added platform name
        status: OrderStatusType.accepted,
        totalAmount: 42.50,
        orderTime: DateTime.now().subtract(const Duration(minutes: 8)),
        expectedDeliveryTime: DateTime.now().add(const Duration(minutes: 25)),
        items: const [
          OrderItemDetail(
            productId: '6',
            productName: 'Pizza Margherita',
            quantity: 1,
            price: 32.50,
            imageUrl:
                'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=400',
          ),
          OrderItemDetail(
            productId: '7',
            productName: 'Garlic Bread',
            quantity: 1,
            price: 10.00,
            imageUrl:
                'https://images.unsplash.com/photo-1549007953-2f2dc0b24019?w=400',
          ),
        ],
      ),
      OrderItem(
        orderId: '123458',
        customerName: 'Uber Eats Order',
        orderType: 'Channel Partner',
        platformName: 'Uber Eats', // Added platform name
        status: OrderStatusType.preparing,
        totalAmount: 28.75,
        orderTime: DateTime.now().subtract(const Duration(minutes: 12)),
        expectedDeliveryTime: DateTime.now().add(const Duration(minutes: 18)),
        items: const [
          OrderItemDetail(
            productId: '8',
            productName: 'Chicken Tikka',
            quantity: 1,
            price: 28.75,
            imageUrl:
                'https://images.unsplash.com/photo-1599487488170-d11ec9c172f0?w=400',
          ),
        ],
      ),
      OrderItem(
        orderId: '123459',
        customerName: 'Foodpanda Order',
        orderType: 'Channel Partner',
        platformName: 'Foodpanda', // Added platform name
        status: OrderStatusType.ready,
        totalAmount: 35.25,
        orderTime: DateTime.now().subtract(const Duration(minutes: 20)),
        expectedDeliveryTime: DateTime.now().add(const Duration(minutes: 5)),
        items: const [
          OrderItemDetail(
            productId: '9',
            productName: 'Mutton Curry',
            quantity: 1,
            price: 35.25,
            imageUrl:
                'https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=400',
          ),
        ],
      ),
      OrderItem(
        orderId: '123460',
        customerName: 'Dunzo Order',
        orderType: 'Channel Partner',
        platformName: 'Dunzo', // Added platform name
        status: OrderStatusType.delivered,
        totalAmount: 22.00,
        orderTime: DateTime.now().subtract(
          const Duration(hours: 1, minutes: 30),
        ),
        expectedDeliveryTime: DateTime.now().subtract(
          const Duration(minutes: 45),
        ),
        items: const [
          OrderItemDetail(
            productId: '10',
            productName: 'Samosa Chaat',
            quantity: 2,
            price: 22.00,
            imageUrl:
                'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=400',
          ),
        ],
      ),
    ];
  }
}
