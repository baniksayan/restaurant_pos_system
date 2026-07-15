import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/core/themes/app_colors.dart';
import 'package:restaurant_pos_system/data/models/order_channel_types_model.dart';

class OrderTypeSelectorDialog extends StatelessWidget {
  final Function(OrderType) onOrderTypeSelected;

  const OrderTypeSelectorDialog({
    super.key,
    required this.onOrderTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final maxWidth = size.width < 480 ? size.width * 0.92 : 400.0;
    
    final orderTypes = [
      OrderType.dineIn,
      OrderType.phoneOrder,
      OrderType.takeaway,
    ];

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.06),
                      AppColors.kotStatus.withOpacity(0.03),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: const Border(
                    bottom: BorderSide(
                      color: Color(0xFFF1F5F9),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.add_circle_outline_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'Select Order Type',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFF1F5F9),
                        foregroundColor: AppColors.textSecondary,
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                  ],
                ),
              ),

              // Content List
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  children: [
                    ...orderTypes.map((orderType) => _buildOrderTypeCard(
                          context,
                          orderType,
                          () => onOrderTypeSelected(orderType),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderTypeCard(
    BuildContext context,
    OrderType orderType,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
            onTap();
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    orderType.icon,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    orderType.displayName,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
