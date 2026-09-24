import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/core/constants/currency_constants.dart';
import 'package:restaurant_pos_system/core/utils/date_time_formatter.dart';
import '../models/order_management_model.dart';

class OrderCard extends StatelessWidget {
  final OrderItem order;
  final VoidCallback onTap;

  const OrderCard({
    super.key,
    required this.order,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final statusBg = _getStatusBg();
    final statusBorder = _getStatusBorder();

    final isTable = order.orderType.toLowerCase().contains('table');
    final isPhone = order.orderType.toLowerCase().contains('phone');

    final typeIcon = isTable
        ? Icons.table_restaurant_rounded
        : isPhone
            ? Icons.phone_in_talk_rounded
            : Icons.shopping_bag_outlined;

    final typeLabel = isTable
        ? (order.tableNumber != null && order.tableNumber!.isNotEmpty
            ? order.tableNumber!.toUpperCase()
            : 'TABLE ORDER')
        : (isPhone ? 'PHONE ORDER' : 'TAKEAWAY');

    final resolvedOrderNo =
        (order.orderNo != null && order.orderNo!.trim().isNotEmpty)
            ? order.orderNo!.trim()
            : order.orderId;

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
          color: const Color(0xFFE2E8F0),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header: 2-Tier Responsive Layout ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                  border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tier 1: Channel/Table Badge (Left) + Status Pill (Right)
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
                                Icon(
                                  typeIcon,
                                  size: 12,
                                  color: AppColors.primaryDark,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    typeLabel,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primaryDark,
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
                                _getStatusText().toUpperCase(),
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

                    // Tier 2: Customer name (Left) + Timestamp (Right)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_outline_rounded,
                          size: 14,
                          color: AppColors.textSecondary.withValues(alpha: 0.85),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            order.customerName.isNotEmpty
                                ? order.customerName
                                : 'Walk-in Guest',
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
                              order.orderTime.timeAgo(),
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

              // ── Body: Order Metadata & Details ──
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Chips Row: Order No & Phone on Left, Waiter Name on Right
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left side: Order No & Optional Phone Number
                        Flexible(
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
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
                              if (order.phoneNumber != null &&
                                  order.phoneNumber!.isNotEmpty)
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
                                        order.phoneNumber!,
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
                        ),

                        // Right side: Waiter Name
                        if (order.waiterName != null &&
                            order.waiterName!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFFC7D2FE),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.badge_outlined,
                                  size: 11,
                                  color: Color(0xFF4F46E5),
                                ),
                                const SizedBox(width: 4),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 120),
                                  child: Text(
                                    order.waiterName!,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF4338CA),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Amount Due / Total Amount Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          order.items.isNotEmpty
                              ? '${order.items.length} ${order.items.length == 1 ? 'item' : 'items'}'
                              : order.orderType,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        if (order.totalAmount > 0)
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
                                order.totalAmount.toCurrency(),
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

                    const SizedBox(height: 12),

                    // Action Button: View Order Details
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
                        onPressed: onTap,
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

  Color _getStatusColor() {
    switch (order.status) {
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
    switch (order.status) {
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
    switch (order.status) {
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

  String _getStatusText() {
    switch (order.status) {
      case OrderStatusType.pending:
        return 'Pending';
      case OrderStatusType.accepted:
        return 'Accepted';
      case OrderStatusType.preparing:
        return 'Preparing';
      case OrderStatusType.ready:
        return 'Ready';
      case OrderStatusType.delivered:
        return 'Delivered';
      case OrderStatusType.completed:
        return 'Completed';
      case OrderStatusType.cancelled:
        return 'Cancelled';
    }
  }
}
