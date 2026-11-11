import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  bool _showOverlayContent = false;

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

        if (isDisconnected && !_showOverlayContent) {
          _showOverlayContent = true;
        }

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
                  onEnd: () {
                    if (!isDisconnected && mounted) {
                      setState(() {
                        _showOverlayContent = false;
                      });
                    }
                  },
                  child: (_showOverlayContent || isDisconnected)
                      ? const NoInternetScreen(isOverlay: true)
                      : const SizedBox.shrink(),
                ),
              ),
            ),

            // Top Floating "Back Online" Capsule Pill
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Builder(
                builder: (context) {
                  final topPadding = MediaQuery.paddingOf(context).top;
                  // Provide clean 12px breathing room below punch-hole camera / notch
                  final topOffset = (topPadding > 0 ? topPadding : 14.0) + 12.0;

                  return Padding(
                    padding: EdgeInsets.only(top: topOffset),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: _BackOnlinePill(
                        isVisible: showRestoredBanner,
                        onDismiss: () {
                          HapticHelper.triggerFeedback();
                          networkProvider.dismissRestoredBanner();
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Floating Dynamic-Island Style "Back Online" Capsule Pill
class _BackOnlinePill extends StatefulWidget {
  final bool isVisible;
  final VoidCallback onDismiss;

  const _BackOnlinePill({
    required this.isVisible,
    required this.onDismiss,
  });

  @override
  State<_BackOnlinePill> createState() => _BackOnlinePillState();
}

class _BackOnlinePillState extends State<_BackOnlinePill>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      reverseDuration: const Duration(milliseconds: 280),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.88,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
        reverseCurve: Curves.easeIn,
      ),
    );

    if (widget.isVisible) {
      _slideController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant _BackOnlinePill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _slideController.forward();
      } else {
        _slideController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slideController,
      builder: (context, child) {
        if (_slideController.isDismissed && !widget.isVisible) {
          return const SizedBox.shrink();
        }

        return IgnorePointer(
          ignoring: !widget.isVisible,
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: FadeTransition(
                opacity: _opacityAnimation,
                child: child,
              ),
            ),
          ),
        );
      },
      child: Material(
        type: MaterialType.transparency,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onDismiss,
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity != null &&
                details.primaryVelocity! < 0) {
              // Flick / swipe up to dismiss
              widget.onDismiss();
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: const Color(0xFF10B981).withValues(alpha: 0.4),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.18),
                  blurRadius: 18,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated Glowing Beacon
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final scale = 1.0 + (_pulseController.value * 0.4);
                    final alpha = 0.5 - (_pulseController.value * 0.35);
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF10B981)
                                  .withValues(alpha: alpha),
                            ),
                          ),
                        ),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF10B981),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981)
                                    .withValues(alpha: 0.6),
                                blurRadius: 4,
                                spreadRadius: 0.5,
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(width: 8),
                const Text(
                  'Back Online',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: -0.1,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(width: 7),
                Container(
                  width: 3.5,
                  height: 3.5,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(width: 7),
                const Text(
                  'Live Sync Active',
                  style: TextStyle(
                    color: Color(0xFF059669),
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                    letterSpacing: 0,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(width: 8),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.onDismiss,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFF1F5F9),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.close_rounded,
                          size: 11,
                          color: Color(0xFF64748B),
                        ),
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
  }
}
