import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import '../models/chef_order_model.dart';
import '../providers/chef_provider.dart';
import 'package:restaurant_pos_system/shared/widgets/layout/premium_refresh_indicator.dart';
import '../widgets/chef_drawer.dart';
import '../widgets/chef_empty_state.dart';
import '../widgets/chef_header.dart';
import '../widgets/chef_order_card.dart';
import '../widgets/chef_status_filter_dialog.dart';
import 'package:restaurant_pos_system/core/constants/app_strings.dart';

class ChefDashboardView extends StatefulWidget {
  const ChefDashboardView({super.key});

  @override
  State<ChefDashboardView> createState() => _ChefDashboardViewState();
}

class _ChefDashboardViewState extends State<ChefDashboardView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late PageController _pageController;

  final List<_KdsNavigationItem> _navItems = [
    _KdsNavigationItem(
      icon: Icons.grid_view_rounded,
      label: AppStrings.chef.all,
      activeColor: AppColors.primary,
    ),
    _KdsNavigationItem(
      icon: Icons.hourglass_top_rounded,
      label: AppStrings.chef.queue,
      activeColor: const Color(0xFFE11D48),
    ),
    _KdsNavigationItem(
      icon: Icons.soup_kitchen_rounded,
      label: AppStrings.chef.preparing,
      activeColor: const Color(0xFFF59E0B),
    ),
    _KdsNavigationItem(
      icon: Icons.room_service_rounded,
      label: AppStrings.chef.serve,
      activeColor: AppColors.success,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<ChefOrder> _getOrdersForTab(ChefProvider chefProvider, int tabIndex) {
    List<ChefOrder> tabOrders;
    switch (tabIndex) {
      case 0: // All: All Active Orders (Pending, Preparing, Ready)
        tabOrders =
            chefProvider.orders
                .where(
                  (o) =>
                      o.status == ChefOrderStatus.pending ||
                      o.status == ChefOrderStatus.preparing ||
                      o.status == ChefOrderStatus.ready,
                )
                .toList();
        break;
      case 1: // Queue: Only Pending (Approve & Reject)
        tabOrders =
            chefProvider.orders
                .where((o) => o.status == ChefOrderStatus.pending)
                .toList();
        break;
      case 2: // Preparing: In Kitchen (Ready to Serve)
        tabOrders =
            chefProvider.orders
                .where((o) => o.status == ChefOrderStatus.preparing)
                .toList();
        break;
      case 3: // Serve: Ready to Serve (Give Order)
      default:
        tabOrders =
            chefProvider.orders
                .where((o) => o.status == ChefOrderStatus.ready)
                .toList();
        break;
    }

    if (chefProvider.selectedStatusFilter != 'All Statuses') {
      tabOrders =
          tabOrders.where((o) {
            switch (chefProvider.selectedStatusFilter.toLowerCase()) {
              case 'pending':
                return o.status == ChefOrderStatus.pending;
              case 'preparing':
                return o.status == ChefOrderStatus.preparing;
              case 'ready to serve':
              case 'ready':
                return o.status == ChefOrderStatus.ready;
              case 'served':
                return o.status == ChefOrderStatus.served;
              default:
                return true;
            }
          }).toList();
    }

    return tabOrders;
  }

  @override
  Widget build(BuildContext context) {
    final chefProvider = context.watch<ChefProvider>();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.grey[50],
        drawerScrimColor: Colors.black.withValues(alpha: 0.12),
        drawer: const ChefDrawer(),
        body: Column(
          children: [
            // Top Header ("WhizEats KDS" + Hamburger Menu & Filter Button)
            ChefHeader(
              showFilter: chefProvider.currentTabIndex == 0,
              onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
              onFilterPressed:
                  () => showChefStatusFilterDialog(context, chefProvider),
            ),

            // Swipeable PageView across 4 tabs (All, Queue, Preparing, Serve)
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const ClampingScrollPhysics(),
                onPageChanged: (index) {
                  if (chefProvider.currentTabIndex != index) {
                    chefProvider.changeTabIndex(index);
                  }
                },
                children: [
                  // Tab 0: All (All Active Kitchen Orders with Full End-to-End Workflow)
                  _buildOrdersPage(context, chefProvider, 0),
                  // Tab 1: Queue (Pending)
                  _buildOrdersPage(context, chefProvider, 1),
                  // Tab 2: Preparing (In Kitchen)
                  _buildOrdersPage(context, chefProvider, 2),
                  // Tab 3: Serve (Ready to Serve)
                  _buildOrdersPage(context, chefProvider, 3),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomNavigationBar(context, chefProvider),
      ),
    );
  }

  Widget _buildOrdersPage(
    BuildContext context,
    ChefProvider chefProvider,
    int tabIndex,
  ) {
    final orders = _getOrdersForTab(chefProvider, tabIndex);

    return PremiumRefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child:
          orders.isEmpty
              ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                  ChefEmptyState(
                    title: AppStrings.chef.noOrdersInView,
                    description: _getEmptyStateDescription(tabIndex),
                  ),
                ],
              )
              : LayoutBuilder(
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      itemCount: orders.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return ChefOrderCard(
                          key: ValueKey(orders[index].id),
                          order: orders[index],
                        );
                      },
                    );
                  }

                  // Multi-column Grid for Tablets/Desktop
                  return GridView.builder(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      mainAxisExtent: 330,
                    ),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      return ChefOrderCard(
                        key: ValueKey(orders[index].id),
                        order: orders[index],
                      );
                    },
                  );
                },
              ),
    );
  }

  Widget _buildBottomNavigationBar(
    BuildContext context,
    ChefProvider chefProvider,
  ) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Container(
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: 4),
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
            children: List.generate(_navItems.length, (index) {
              final isSelected = index == chefProvider.currentTabIndex;
              final item = _navItems[index];
              final badgeCount = _getBadgeCount(index, chefProvider);

              return Expanded(
                child: _KdsNavBarItem(
                  item: item,
                  isSelected: isSelected,
                  badgeCount: badgeCount,
                  onTap: () {
                    if (!isSelected) {
                      HapticFeedback.selectionClick();
                      chefProvider.changeTabIndex(index);
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

  int _getBadgeCount(int index, ChefProvider provider) {
    switch (index) {
      case 0:
        return provider.allActiveCount;
      case 1:
        return provider.queueCount;
      case 2:
        return provider.preparingCount;
      case 3:
        return provider.serveCount;
      default:
        return 0;
    }
  }

  String _getEmptyStateDescription(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return 'No active kitchen orders at the moment.';
      case 1:
        return 'No pending orders waiting in the kitchen queue.';
      case 2:
        return 'No orders currently cooking in the kitchen.';
      case 3:
      default:
        return 'No orders currently ready to be served.';
    }
  }
}

class _KdsNavigationItem {
  final IconData icon;
  final String label;
  final Color activeColor;

  _KdsNavigationItem({
    required this.icon,
    required this.label,
    required this.activeColor,
  });
}

class _KdsNavBarItem extends StatelessWidget {
  final _KdsNavigationItem item;
  final bool isSelected;
  final int badgeCount;
  final VoidCallback onTap;

  const _KdsNavBarItem({
    required this.item,
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
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 1),
        padding: EdgeInsets.symmetric(horizontal: isSelected ? 5 : 0),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? item.activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(28),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: item.activeColor.withValues(alpha: 0.3),
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
                    width: 20,
                    height: 20,
                    child: TweenAnimationBuilder<Color?>(
                      duration: const Duration(milliseconds: 280),
                      tween: ColorTween(
                        begin: Colors.grey[500],
                        end: isSelected ? Colors.white : Colors.grey[500],
                      ),
                      builder: (context, color, _) {
                        return Icon(item.icon, color: color, size: 20);
                      },
                    ),
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      right: -9,
                      top: -8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? item.activeColor : Colors.white,
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFFFF6B6B,
                              ).withValues(alpha: 0.4),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 14,
                          minHeight: 14,
                        ),
                        child: Center(
                          child: Text(
                            badgeCount > 99 ? '99+' : '$badgeCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8.0,
                              fontWeight: FontWeight.bold,
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
                child:
                    isSelected
                        ? Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 220),
                            opacity: isSelected ? 1 : 0,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                item.label,
                                maxLines: 1,
                                style: const TextStyle(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.bold,
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
