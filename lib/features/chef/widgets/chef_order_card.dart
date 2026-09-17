import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import '../models/chef_order_model.dart';
import '../providers/chef_provider.dart';
import 'chef_order_item.dart';
import 'chef_status_badge.dart';
// import 'reject_order_dialog.dart'; // Preserved for future reject restoration
import 'package:restaurant_pos_system/core/utils/snackbar_helper.dart';

class ChefOrderCard extends StatefulWidget {
  final ChefOrder order;

  const ChefOrderCard({super.key, required this.order});

  @override
  State<ChefOrderCard> createState() => _ChefOrderCardState();
}

class _ChefOrderCardState extends State<ChefOrderCard>
    with SingleTickerProviderStateMixin {
  final bool _isHandedOver = false;
  final int _remainingSeconds = 5;
  Timer? _countdownTimer;
  late AnimationController _vanishController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _sizeAnimation;

  @override
  void initState() {
    super.initState();
    _vanishController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _vanishController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _sizeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _vanishController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeInOutCubic),
      ),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _vanishController.dispose();
    super.dispose();
  }

  /*
  // Preserved: Countdown handover animation previously used before direct banner display
  void _startGiveOrderCountdown() {
    if (_isHandedOver) return;

    setState(() {
      _isHandedOver = true;
      _remainingSeconds = 5;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_remainingSeconds > 1) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();
        _animateAndRemove();
      }
    });
  }

  void _animateAndRemove() async {
    if (!mounted) return;
    await _vanishController.forward();
    if (mounted) {
      context.read<ChefProvider>().confirmPassHandover(widget.order.id);
    }
  }
  */

  /*
  // Preserved for future rejection flow restoration
  void _showRejectDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (ctx) => RejectOrderDialog(
            order: widget.order,
            onConfirmReject: (reason) {
              context.read<ChefProvider>().rejectOrder(widget.order.id, reason);
              AppSnackBar.showError(
                context,
                'Order #${widget.order.orderNumber} rejected',
              );
            },
          ),
    );
  }
  */

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChefProvider>();
    final order = widget.order;

    Color borderColor;
    if (_isHandedOver || order.status == ChefOrderStatus.ready) {
      borderColor = AppColors.success;
    } else if (order.status == ChefOrderStatus.pending) {
      borderColor = const Color(0xFFF59E0B); // Amber
    } else if (order.status == ChefOrderStatus.preparing) {
      borderColor = AppColors.primary; // Blue/Violet
    } else {
      borderColor = const Color(0xFFE2E8F0);
    }

    return SizeTransition(
      sizeFactor: _sizeAnimation,
      axisAlignment: 0.0,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor.withValues(alpha: 0.6),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header: 2-Tier responsive layout to guarantee full kotNo display
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                  border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tier 1: Table Badge on Left, Time Ago & Status Badge on Right
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
                            ChefStatusBadge(
                              status:
                                  _isHandedOver
                                      ? ChefOrderStatus.served
                                      : order.status,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    // Tier 2: Full KOT Ticket Number (softWrap, no ellipsis)
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
                            softWrap: true,
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

              // Body: Food Items (with item image on right & item-wise KOT notes)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Items List
                    ...order.items.map((item) => ChefOrderItemTile(item: item)),

                    const SizedBox(height: 12),

                    // Action Buttons / Status Banners
                    _buildActionButtons(context, provider),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ChefProvider provider) {
    final order = widget.order;

    // If Give Order was clicked and is counting down to vanish:
    if (_isHandedOver) {
      return _buildHandedOverBanner(remainingSeconds: _remainingSeconds);
    }

    switch (order.status) {
      case ChefOrderStatus.pending:
        // Step 1 (Queue Tab): Single primary action -> ACCEPT ORDER
        // NOTE: The Reject action is commented out per requirement.
        /*
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error, width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                ),
                onPressed: () => _showRejectDialog(context),
                child: const Text(
                  'REJECT',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                ),
                onPressed: () {
                  provider.approveOrder(order.id);
                  AppSnackBar.showSuccess(
                    context,
                    'Order #${order.orderNumber} Approved -> Moved to Preparing',
                    duration: const Duration(seconds: 1),
                  );
                },
                child: const Text(
                  'APPROVE',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
          ],
        );
        */
        return SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
            label: const Text(
              'ACCEPT ORDER',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: 0.4,
              ),
            ),
            onPressed: () {
              provider.approveOrder(order.id);
              AppSnackBar.showSuccess(
                context,
                'Order #${order.orderNumber} Accepted -> Moved to Preparing',
                duration: const Duration(seconds: 1),
              );
            },
          ),
        );

      case ChefOrderStatus.preparing:
        // Step 2 (Preparing Tab): Chef marks order Ready to Serve -> moves to Waiter / Ready to Collect
        return SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B), // Amber/Orange
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(Icons.room_service_rounded, size: 18),
            label: const Text(
              'READY TO SERVE',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: 0.4,
              ),
            ),
            onPressed: () {
              provider.markReadyToServe(order.id);
              AppSnackBar.showSuccess(
                context,
                'Order #${order.orderNumber} Prepared -> Ready for Waiter Pickup',
                duration: const Duration(seconds: 1),
              );
            },
          ),
        );

      case ChefOrderStatus.ready:
      case ChefOrderStatus.served:
        // Status 3 (Serve Tab): Food is placed on the pass.
        // No 'Confirm on Pass' button; directly shows the confirmation message banner.
        return _buildHandedOverBanner(remainingSeconds: null);

      case ChefOrderStatus.rejected:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.highlight_off_rounded,
                    size: 15,
                    color: AppColors.error,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Order Rejected',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
              if (order.rejectionReason != null) ...[
                const SizedBox(height: 2),
                Text(
                  'Reason: ${order.rejectionReason}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        );
    }
  }

  Widget _buildHandedOverBanner({required int? remainingSeconds}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFECFDF5), // Mint 50
            Color(0xFFD1FAE5), // Emerald 100
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Animated Check Circle Icon
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.done_all_rounded,
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),

          // Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Placed on Kitchen Pass',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF065F46),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  remainingSeconds != null
                      ? 'Awaiting waiter pickup (${remainingSeconds}s)...'
                      : 'Ready for Operator/Waiter collection',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF047857),
                  ),
                ),
              ],
            ),
          ),

          // Countdown Pill Indicator (when counting down)
          if (remainingSeconds != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF065F46),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF065F46).withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 11,
                    height: 11,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${remainingSeconds}s',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 11.5,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
