import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos_system/data/local/hive_service.dart';

import '../providers/menu_provider.dart';
import 'package:restaurant_pos_system/features/dashboard/providers/navigation_provider.dart';
import 'package:restaurant_pos_system/features/dashboard/providers/table_provider.dart';
import 'package:restaurant_pos_system/features/dashboard/providers/dashboard_provider.dart';
import 'package:restaurant_pos_system/features/order_taking/providers/animated_cart_provider.dart';
import '../widgets/menu_header.dart';
import '../widgets/menu_search_bar.dart';
import '../widgets/category_tabs.dart';
import '../widgets/menu_grid.dart';
import '../widgets/cart_footer.dart';
import 'package:restaurant_pos_system/shared/widgets/layout/premium_refresh_indicator.dart';
import 'package:restaurant_pos_system/core/constants/app_strings.dart';
import 'package:restaurant_pos_system/core/utils/snackbar_helper.dart';

class MenuView extends StatefulWidget {
  final String? selectedTableId;
  final String? tableName;
  final String? selectedLocation;
  final Function(
    String itemId,
    String itemName,
    double price,
    String categoryId,
    String categoryName,
    Offset position,
  )?
  onAddToCart;

  const MenuView({
    super.key,
    this.selectedTableId,
    this.tableName,
    this.selectedLocation,
    this.onAddToCart,
  });

  @override
  State<MenuView> createState() => _MenuViewState();
}

class _MenuViewState extends State<MenuView> {
  int _resolveOutletId() {
    try {
      final dashboardProvider =
          Provider.of<DashboardProvider>(context, listen: false);
      if (widget.selectedLocation != null &&
          widget.selectedLocation!.isNotEmpty) {
        final matched = dashboardProvider.locations
            .where((l) => l.name == widget.selectedLocation)
            .firstOrNull;
        if (matched?.id != null && matched!.id! > 0) {
          return matched.id!;
        }
      }
      final dId = dashboardProvider.selectedLocationId;
      if (dId != null && dId > 0) {
        return dId;
      }
    } catch (_) {
      // DashboardProvider not present in some test widget trees
    }

    return HiveService.getSelectedLocationId() ??
        HiveService.getOutletId() ??
        0;
  }

  @override
  void initState() {
    super.initState();
    // Load menu data when the widget initializes - BUT ONLY IF AUTHENTICATED
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final menuProvider = Provider.of<MenuProvider>(context, listen: false);

      // Switch to selected table for proper state isolation
      if (widget.selectedTableId != null) {
        await _switchToNewTable();
      }

      // Check if user is authenticated before loading menu
      final token = HiveService.getAuthToken();
      if (token.isNotEmpty) {
        final outletId = _resolveOutletId();
        debugPrint('[MenuView] Resolved outlet ID: $outletId');

        if (outletId > 0) {
          debugPrint('[MenuView] ✅ Using outlet ID: $outletId');
          menuProvider.loadMenuData(outletId: outletId);
        } else {
          debugPrint(
            '[MenuView] ❌ No valid outlet ID available - skipping menu load',
          );
        }
      } else {
        debugPrint('No auth token available - skipping menu load in MenuView');
      }
    });
  }

  @override
  void didUpdateWidget(MenuView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Switch to new table when table selection changes
    if (widget.selectedTableId != oldWidget.selectedTableId) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (mounted) await _switchToNewTable();
      });
    }

    // Reload menu if selected location changes
    if (widget.selectedLocation != oldWidget.selectedLocation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final outletId = _resolveOutletId();
        if (outletId > 0) {
          debugPrint(
            '[MenuView] Location changed to ${widget.selectedLocation} -> reloading for outlet ID: $outletId',
          );
          Provider.of<MenuProvider>(context, listen: false).loadMenuData(
            outletId: outletId,
          );
        }
      });
    }
  }

  Future<void> _switchToNewTable() async {
    if (widget.selectedTableId == null) return;

    final menuProvider = Provider.of<MenuProvider>(context, listen: false);
    final animatedCartProvider = Provider.of<AnimatedCartProvider>(
      context,
      listen: false,
    );
    debugPrint('[MenuView] Switching to table: ${widget.selectedTableId}');

    // Switch menu provider
    menuProvider.switchToTable(widget.selectedTableId);

    // Switch cart provider
    debugPrint(
      '[MenuView] Switching cart provider to table ${widget.selectedTableId}',
    );

    animatedCartProvider.switchToOrder(
      context.read<TableProvider>().currentOrderId,
      tableId: widget.selectedTableId!,
      tableName: widget.tableName,
    );

    debugPrint('[MenuView] Table switch completed');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        bottom: false,
        child: Consumer2<MenuProvider, NavigationProvider>(
          builder: (context, menuProvider, navProvider, child) {
            // Debug prints
            debugPrint(
              'MenuView DEBUG: selectedTableId = ${widget.selectedTableId}',
            );
            debugPrint(
              'MenuView DEBUG: selectedOrderType = ${navProvider.selectedOrderType}',
            );

            // Can order if table is selected OR if phone/takeaway order is active
            final canOrder =
                widget.selectedTableId != null ||
                (navProvider.selectedOrderType != null &&
                    [
                      'PhoneOrder',
                      'Takeaway',
                    ].contains(navProvider.selectedOrderType));

            debugPrint('MenuView DEBUG: canOrder = $canOrder');

            final effectiveOutletId = _resolveOutletId();
            if (effectiveOutletId > 0 &&
                menuProvider.currentOutletId != null &&
                menuProvider.currentOutletId != effectiveOutletId &&
                !menuProvider.isLoading) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted &&
                    menuProvider.currentOutletId != effectiveOutletId &&
                    !menuProvider.isLoading) {
                  debugPrint(
                    '[MenuView] Outlet desync detected (current: ${menuProvider.currentOutletId}, expected: $effectiveOutletId). Reloading menu.',
                  );
                  menuProvider.loadMenuData(outletId: effectiveOutletId);
                }
              });
            }

            final hasMenuItems = menuProvider.apiMenuItems.isNotEmpty;

            return Consumer<AnimatedCartProvider>(
              builder: (context, cartProvider, child) {
                return Column(
                  children: [
                    MenuHeader(
                      canOrder: canOrder,
                      tableName:
                          widget.tableName ?? _getOrderDisplayName(navProvider),
                      selectedLocation: widget.selectedLocation,
                      onPrintKOT: _printKOT,
                      showStatusTag: hasMenuItems,
                    ),
                    Expanded(
                      child: Stack(
                        children: [
                          if (hasMenuItems)
                            NestedScrollView(
                              headerSliverBuilder: (context, innerBoxIsScrolled) {
                                return [
                                  SliverAppBar(
                                    floating: true,
                                    snap: true,
                                    pinned: false,
                                    elevation: 0,
                                    backgroundColor: Colors.grey[50],
                                    automaticallyImplyLeading: false,
                                    toolbarHeight: 140,
                                    flexibleSpace: const SafeArea(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          MenuSearchBar(),
                                          CategoryTabs(),
                                        ],
                                      ),
                                    ),
                                  ),
                                ];
                              },
                              body: PremiumRefreshIndicator(
                                onRefresh: () async {
                                  final outletId = _resolveOutletId();
                                  if (outletId > 0) {
                                    await menuProvider.loadMenuData(
                                      outletId: outletId,
                                      forceRefresh: true,
                                    );
                                  }
                                },
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    bottom:
                                        canOrder && cartProvider.newItemsCount > 0
                                            ? 95
                                            : 0,
                                  ),
                                  child: MenuGrid(
                                    canOrder: canOrder,
                                    onAddToCart: widget.onAddToCart,
                                  ),
                                ),
                              ),
                            )
                          else
                            PremiumRefreshIndicator(
                              onRefresh: () async {
                                final outletId = _resolveOutletId();
                                if (outletId > 0) {
                                  await menuProvider.loadMenuData(
                                    outletId: outletId,
                                    forceRefresh: true,
                                  );
                                }
                              },
                              child: MenuGrid(
                                canOrder: canOrder,
                                onAddToCart: widget.onAddToCart,
                              ),
                            ),
                          if (canOrder && cartProvider.newItemsCount > 0)
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: CartFooter(
                                onPlaceOrder: () {
                                  // Navigate to Cart tab (index 2)
                                  Provider.of<NavigationProvider>(
                                    context,
                                    listen: false,
                                  ).navigateToIndex(2);
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _printKOT() {
    AppSnackBar.showInfo(context, AppStrings.menu.kotSentToKitchen);
  }

  String? _getOrderDisplayName(NavigationProvider navProvider) {
    if (navProvider.selectedOrderType != null) {
      return '${navProvider.selectedOrderType} Order - ${navProvider.customerName}';
    }
    return null;
  }
}
