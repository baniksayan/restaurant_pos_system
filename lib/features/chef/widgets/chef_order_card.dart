import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import '../models/chef_order_model.dart';
import '../providers/chef_provider.dart';
import 'chef_order_item.dart';
import 'chef_status_badge.dart';
import 'reject_order_dialog.dart';

class ChefOrderCard extends StatefulWidget {
  final ChefOrder order;

  const ChefOrderCard({
    super.key,
    required this.order,
  });

  @override
  State<ChefOrderCard> createState() => _ChefOrderCardState();
}

class _ChefOrderCardState extends State<ChefOrderCard> with SingleTickerProviderStateMixin {
  bool _isHandedOver = false;
  int _remainingSeconds = 5;
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
      context.read<ChefProvider>().giveOrder(widget.order.id);
    }
  }

  void _showRejectDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => RejectOrderDialog(
        order: widget.order,
        onConfirmReject: (reason) {
          context.read<ChefProvider>().rejectOrder(widget.order.id, reason);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Order #${widget.order.orderNumber} rejected'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        },
      ),
    );
  }

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
            border: Border.all(color: borderColor.withValues(alpha: 0.6), width: 1.2),
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
              // Header Row: Order Number, Table Name, Time Ago & Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFF1F5F9)),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Order Number & Table Name
                    Row(
                      children: [
                        Text(
                          '#${order.orderNumber}',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            order.tableNumber.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryDark,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Time ago & Status Badge
                    Row(
                      children: [
                        Text(
                          order.timeAgo,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ChefStatusBadge(
                          status: _isHandedOver ? ChefOrderStatus.served : order.status,
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
        // Step 1 (Queue Tab): Approve / Reject
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error, width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                ),
                onPressed: () {
                  provider.approveOrder(order.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Order #${order.orderNumber} Approved -> Moved to Preparing'),
                      backgroundColor: AppColors.primary,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
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

      case ChefOrderStatus.preparing:
        // Step 2 (Preparing Tab): Preparation Started -> Move to Serve Tab
        return SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B), // Amber/Orange
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(Icons.soup_kitchen_rounded, size: 18),
            label: const Text(
              'PREPARATION STARTED',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: 0.4,
              ),
            ),
            onPressed: () {
              provider.markReadyToServe(order.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Order #${order.orderNumber} Moved to Serve'),
                  backgroundColor: const Color(0xFFF59E0B),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
          ),
        );

      case ChefOrderStatus.ready:
        // Step 3 (Serve Tab): Ready to Serve -> Triggers 5s countdown and smooth vanish animation
        return SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.success,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
            onPressed: _startGiveOrderCountdown,
          ),
        );

      case ChefOrderStatus.served:
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
                  Icon(Icons.highlight_off_rounded, size: 15, color: AppColors.error),
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
                  'Handed Over to Waiter',
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
                      ? 'Removing from serve queue in ${remainingSeconds}s...'
                      : 'Order completed & handed over',
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
