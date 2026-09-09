import 'dart:async';

import 'package:flutter/material.dart';

import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/core/constants/currency_constants.dart';
import 'package:restaurant_pos_system/core/utils/date_time_formatter.dart';
import 'package:restaurant_pos_system/shared/widgets/animations/countdown_timer.dart';
import 'package:restaurant_pos_system/shared/widgets/badges/app_status_badge.dart';
import '../models/order_management_model.dart';
import 'package:restaurant_pos_system/core/constants/app_strings.dart';
import 'package:restaurant_pos_system/core/utils/snackbar_helper.dart';

class ChannelPartnerOrderCard extends StatefulWidget {
  final OrderItem order;
  final VoidCallback onTap;
  final Function(String orderId) onAccept;
  final Function(String orderId) onDecline;

  const ChannelPartnerOrderCard({
    super.key,
    required this.order,
    required this.onTap,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  State<ChannelPartnerOrderCard> createState() =>
      _ChannelPartnerOrderCardState();
}

class _ChannelPartnerOrderCardState extends State<ChannelPartnerOrderCard> {
  bool _isProcessing = false;
  late OrderItem _currentOrder;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
  }

  @override
  Widget build(BuildContext context) {
    final showActionButtons = _currentOrder.status == OrderStatusType.pending;
    final showTimer =
        _currentOrder.expectedDeliveryTime != null &&
        _currentOrder.status != OrderStatusType.delivered &&
        _currentOrder.status != OrderStatusType.cancelled;

    return Card(
      color: AppColors.cardBackground,
      elevation: 2,
      shadowColor: AppColors.cardShadow,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side:
            showActionButtons
                ? const BorderSide(color: AppColors.warning, width: 1)
                : BorderSide.none,
      ),
      child: Column(
        children: [
          // Main order info (clickable)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius:
                  showActionButtons
                      ? const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      )
                      : BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    Row(
                      children: [
                        if (showActionButtons)
                          const AppStatusBadge(
                            label: 'New',
                            color: Colors.red,
                            icon: Icons.notifications_active,
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            borderRadius: 4,
                          ),
                        const Spacer(),
                        _buildStatusBadge(),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Customer Name
                    Text(
                      _currentOrder.customerName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Order Number - Moved below customer name for prominence
                    Text(
                      'Order #${_currentOrder.orderId}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Platform Info
                    Row(
                      children: [
                        Text(
                          'Platform: ${_currentOrder.platformName ?? _currentOrder.orderType}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          ' • ${_formatOrderTime(_currentOrder.orderTime)}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Price - Clean display
                    Text(
                      '${CurrencyConstants.symbol}${_currentOrder.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    // Timer Row (if applicable)
                    if (showTimer) ...[
                      const SizedBox(height: 12),
                      CountdownTimer(
                        targetTime: _currentOrder.expectedDeliveryTime!,
                        label: AppStrings.orders.remainingTime,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Accept/Decline buttons section
          if (showActionButtons) ...[
            const Divider(height: 1, color: AppColors.warning),
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : () => _handleAccept(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      icon:
                          _isProcessing
                              ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : const Icon(Icons.check_circle, size: 18),
                      label: Text(
                        _isProcessing ? 'Accepting...' : 'Accept',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : () => _handleDecline(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.cancel, size: 18),
                      label: const Text(
                        'Decline',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

  Widget _buildStatusBadge() {
    return AppStatusBadge(
      label: _currentOrder.statusDisplayText,
      color: _getStatusColor(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    );
  }

  void _handleAccept() async {
    setState(() => _isProcessing = true);
    try {
      await widget.onAccept(_currentOrder.orderId);
      // Update local state immediately for better UX
      final now = DateTime.now();
      final expectedDelivery = now.add(
        const Duration(minutes: 15),
      ); // 15 min prep time

      setState(() {
        _currentOrder = _currentOrder.copyWith(
          status: OrderStatusType.accepted,
          acceptedTime: now,
          expectedDeliveryTime: expectedDelivery,
        );
      });

      // Auto-progress to preparing after 2 seconds
      Timer(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _currentOrder = _currentOrder.copyWith(
              status: OrderStatusType.preparing,
            );
          });
        }
      });

      if (mounted) {
        AppSnackBar.showSuccess(
          context,
          'Order #${_currentOrder.orderId} accepted! Preparation started.',
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(
          context,
          'Failed to accept order: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _handleDecline() async {
    setState(() => _isProcessing = true);
    try {
      await widget.onDecline(_currentOrder.orderId);
      setState(() {
        _currentOrder = _currentOrder.copyWith(
          status: OrderStatusType.cancelled,
        );
      });

      if (mounted) {
        AppSnackBar.showWarning(
          context,
          'Order #${_currentOrder.orderId} declined.',
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(
          context,
          'Failed to decline order: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Color _getStatusColor() {
    switch (_currentOrder.status) {
      case OrderStatusType.pending:
        return AppColors.warning;
      case OrderStatusType.accepted:
        return AppColors.info;
      case OrderStatusType.preparing:
        return AppColors.tableCleaning;
      case OrderStatusType.ready:
        return AppColors.success;
      case OrderStatusType.delivered:
        return AppColors.tableAvailable;
      case OrderStatusType.cancelled:
        return AppColors.error;
      case OrderStatusType.completed:
        return AppColors.success;
    }
  }

  String _formatOrderTime(DateTime orderTime) {
    return DateTimeFormatter.formatRelative(
      orderTime,
      includeDateForOlderDays: false,
    );
  }
}
