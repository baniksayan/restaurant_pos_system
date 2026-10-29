import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/core/utils/haptic_helper.dart';
import 'package:restaurant_pos_system/data/local/sync_service.dart';
import 'package:restaurant_pos_system/features/chef/providers/chef_provider.dart';
import 'package:restaurant_pos_system/features/dashboard/providers/table_provider.dart';
import 'package:restaurant_pos_system/features/network/providers/network_provider.dart';
import 'package:restaurant_pos_system/features/network/views/no_internet_screen.dart';
import 'package:restaurant_pos_system/features/orders/providers/orders_management_provider.dart';

class GlobalNetworkWrapper extends StatefulWidget {
  final Widget child;

  const GlobalNetworkWrapper({
    super.key,
    required this.child,
  });

  @override
  State<GlobalNetworkWrapper> createState() => _GlobalNetworkWrapperState();
}

class _GlobalNetworkWrapperState extends State<GlobalNetworkWrapper> {
  NetworkProvider? _networkProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = Provider.of<NetworkProvider>(context, listen: false);
    if (_networkProvider != provider) {
      _networkProvider?.removeRestoredCallback(_handleNetworkRestored);
      _networkProvider = provider;
      _networkProvider?.addRestoredCallback(_handleNetworkRestored);
    }
  }

  @override
  void dispose() {
    _networkProvider?.removeRestoredCallback(_handleNetworkRestored);
    super.dispose();
  }

  void _handleNetworkRestored() {
    if (!mounted) return;

    // Haptic feedback on reconnection
    HapticHelper.triggerFeedback();

    // 1. Refresh TableProvider data (Waiter Dashboard)
    try {
      final tableProvider = Provider.of<TableProvider>(context, listen: false);
      tableProvider.refreshTables();
    } catch (_) {}

    // 2. Refresh ChefProvider data (Chef Dashboard / KDS)
    try {
      final chefProvider = Provider.of<ChefProvider>(context, listen: false);
      chefProvider.fetchOrders(forceRefresh: true);
    } catch (_) {}

    // 3. Refresh OrdersManagementProvider data (Orders List)
    try {
      final ordersProvider =
          Provider.of<OrdersManagementProvider>(context, listen: false);
      ordersProvider.fetchAllOrders();
    } catch (_) {}

    // 4. Sync pending local offline data
    try {
      SyncService.syncAllData();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NetworkProvider>(
      builder: (context, networkProvider, _) {
        final isDisconnected = networkProvider.isDisconnected;
        final showRestoredBanner = networkProvider.showRestoredBanner;

        return Stack(
          fit: StackFit.expand,
          children: [
            // Underlying application navigator and active screen (100% state preserved)
            widget.child,

            // Fullscreen No Internet Overlay with Smooth Fade
            Positioned.fill(
              child: IgnorePointer(
                ignoring: !isDisconnected,
                child: AnimatedOpacity(
                  opacity: isDisconnected ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeInOut,
                  child: isDisconnected
                      ? const NoInternetScreen(isOverlay: true)
                      : const SizedBox.shrink(),
                ),
              ),
            ),

            // Top Apple Dynamic-Island Style "Back Online" Capsule Pill
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: AnimatedSlide(
                  offset: showRestoredBanner
                      ? const Offset(0, 0.15)
                      : const Offset(0, -1.6),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutBack,
                  child: AnimatedOpacity(
                    opacity: showRestoredBanner ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 260),
                    child: Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF090D16).withValues(alpha: 0.94),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.success.withValues(alpha: 0.25),
                                  blurRadius: 20,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 6),
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Glowing emerald status beacon
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF10B981),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF10B981)
                                            .withValues(alpha: 0.7),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'Back Online',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(width: 7),
                                const Text(
                                  '•  Live Sync Active',
                                  style: TextStyle(
                                    color: Color(0xFF34D399),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
