import 'dart:async';
import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/core/constants/currency_constants.dart';
import 'package:restaurant_pos_system/core/utils/date_time_formatter.dart';
import 'package:restaurant_pos_system/shared/widgets/animations/countdown_timer.dart';
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

    final statusColor = _getStatusColor();
    final statusBg = _getStatusBg();
    final statusBorder = _getStatusBorder();

    final platformName =
        _currentOrder.platformName ?? _currentOrder.orderType;
    final platformColor = _getPlatformColor(platformName);

    final resolvedOrderNo = (_currentOrder.orderNo != null &&
            _currentOrder.orderNo!.trim().isNotEmpty)
        ? _currentOrder.orderNo!.trim()
        : _currentOrder.orderId;

    final displayOrderNo = resolvedOrderNo.isNotEmpty
        ? (resolvedOrderNo.startsWith('#')
            ? resolvedOrderNo
            : '#$resolvedOrderNo')
        : '#ORDER';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: showActionButtons
              ? const Color(0xFFF59E0B)
              : const Color(0xFFE2E8F0),
          width: showActionButtons ? 1.5 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: showActionButtons
                ? const Color(0xFFF59E0B).withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header: 2-Tier Responsive Layout ──
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: showActionButtons
                      ? const Color(0xFFFFFBEB)
                      : const Color(0xFFF8FAFC),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(15)),
                  border:
                      const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tier 1: Platform Badge (Left) + Status Pill (Right)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3.5,
                            ),
                            decoration: BoxDecoration(
                              color: platformColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: platformColor.withValues(alpha: 0.25),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.delivery_dining_rounded,
                                  size: 12,
                                  color: platformColor,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    platformName.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: platformColor,
                                      letterSpacing: 0.2,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: statusBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _currentOrder.statusDisplayText.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: statusColor,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),

                    // Tier 2: Customer Name (Left) + Timestamp (Right)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_outline_rounded,
                          size: 14,
                          color:
                              AppColors.textSecondary.withValues(alpha: 0.85),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            _currentOrder.customerName.isNotEmpty
                                ? _currentOrder.customerName
                                : 'Online Customer',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              size: 12,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 3.5),
                            Text(
                              _currentOrder.orderTime.timeAgo(),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Body: Platform details, price & action buttons ──
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Chips Row: Order ID, Phone
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.receipt_rounded,
                                size: 11,
                                color: Color(0xFF64748B),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                displayOrderNo,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_currentOrder.phoneNumber != null &&
                            _currentOrder.phoneNumber!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFFBBF7D0),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.phone_outlined,
                                  size: 11,
                                  color: Color(0xFF16A34A),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _currentOrder.phoneNumber!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF15803D),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Price Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          _currentOrder.items.isNotEmpty
                              ? '${_currentOrder.items.length} ${_currentOrder.items.length == 1 ? 'item' : 'items'}'
                              : 'Channel Partner Order',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        if (_currentOrder.totalAmount > 0)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'TOTAL: ',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              Text(
                                _currentOrder.totalAmount.toCurrency(),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primaryDark,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),

                    // Timer Row (if applicable)
                    if (showTimer) ...[
                      const SizedBox(height: 10),
                      CountdownTimer(
                        targetTime: _currentOrder.expectedDeliveryTime!,
                        label: AppStrings.orders.remainingTime,
                      ),
                    ],

                    const SizedBox(height: 12),

                    // Actions
                    if (showActionButtons)
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed:
                                  _isProcessing ? null : () => _handleAccept(),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: _isProcessing
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Icon(Icons.check_circle_outline_rounded,
                                      size: 16),
                              label: Text(
                                _isProcessing ? 'Accepting...' : 'ACCEPT',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed:
                                  _isProcessing ? null : () => _handleDecline(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFEF4444),
                                side: const BorderSide(
                                  color: Color(0xFFFECACA),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(Icons.cancel_outlined, size: 16),
                              label: const Text(
                                'DECLINE',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: widget.onTap,
                          icon: const Icon(
                            Icons.visibility_outlined,
                            size: 15,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'VIEW ORDER DETAILS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPlatformColor(String platform) {
    final lower = platform.toLowerCase();
    if (lower.contains('zomato')) return const Color(0xFFE23744);
    if (lower.contains('swiggy')) return const Color(0xFFFC8019);
    if (lower.contains('uber')) return const Color(0xFF06C167);
    return AppColors.primary;
  }

  Color _getStatusColor() {
    switch (_currentOrder.status) {
      case OrderStatusType.pending:
        return const Color(0xFFD97706);
      case OrderStatusType.accepted:
        return const Color(0xFF2563EB);
      case OrderStatusType.preparing:
        return const Color(0xFF7C3AED);
      case OrderStatusType.ready:
        return const Color(0xFF059669);
      case OrderStatusType.delivered:
        return const Color(0xFF0D9488);
      case OrderStatusType.completed:
        return const Color(0xFF10B981);
      case OrderStatusType.cancelled:
        return const Color(0xFFDC2626);
    }
  }

  Color _getStatusBg() {
    switch (_currentOrder.status) {
      case OrderStatusType.pending:
        return const Color(0xFFFEF3C7);
      case OrderStatusType.accepted:
        return const Color(0xFFEFF6FF);
      case OrderStatusType.preparing:
        return const Color(0xFFF5F3FF);
      case OrderStatusType.ready:
        return const Color(0xFFECFDF5);
      case OrderStatusType.delivered:
        return const Color(0xFFF0FDFA);
      case OrderStatusType.completed:
        return const Color(0xFFD1FAE5);
      case OrderStatusType.cancelled:
        return const Color(0xFFFEE2E2);
    }
  }

  Color _getStatusBorder() {
    switch (_currentOrder.status) {
      case OrderStatusType.pending:
        return const Color(0xFFFDE68A);
      case OrderStatusType.accepted:
        return const Color(0xFFBFDBFE);
      case OrderStatusType.preparing:
        return const Color(0xFFDDD6FE);
      case OrderStatusType.ready:
        return const Color(0xFFA7F3D0);
      case OrderStatusType.delivered:
        return const Color(0xFF99F6E4);
      case OrderStatusType.completed:
        return const Color(0xFF6EE7B7);
      case OrderStatusType.cancelled:
        return const Color(0xFFFECACA);
    }
  }

  void _handleAccept() async {
    setState(() => _isProcessing = true);
    try {
      await widget.onAccept(_currentOrder.orderId);
      final now = DateTime.now();
      final expectedDelivery = now.add(const Duration(minutes: 15));

      setState(() {
        _currentOrder = _currentOrder.copyWith(
          status: OrderStatusType.accepted,
          acceptedTime: now,
          expectedDeliveryTime: expectedDelivery,
        );
      });

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
}

