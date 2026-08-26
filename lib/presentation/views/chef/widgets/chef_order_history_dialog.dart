import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos_system/core/themes/app_colors.dart';
import 'package:restaurant_pos_system/presentation/view_models/providers/chef_provider.dart';
import 'chef_order_card.dart';

void showChefOrderHistoryDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierColor: Colors.transparent,
    builder: (BuildContext dialogContext) {
      final size = MediaQuery.sizeOf(dialogContext);
      final maxWidth = size.width < 600 ? size.width * 0.94 : 520.0;

      return Material(
        type: MaterialType.transparency,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(dialogContext).maybePop(),
          child: Stack(
            children: [
              // Glassmorphism Blur
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.12),
                  ),
                ),
              ),
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: GestureDetector(
                        onTap: () {}, // Prevent tap inside from closing
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.95),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Header
                                  Container(
                                    padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.5),
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Colors.grey.withValues(alpha: 0.2),
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 38,
                                          height: 38,
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(
                                            Icons.history_rounded,
                                            color: AppColors.primary,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Order History (All)',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                              Text(
                                                'Completed and handed-over kitchen orders',
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.close_rounded, size: 20),
                                          onPressed: () => Navigator.pop(dialogContext),
                                          style: IconButton.styleFrom(
                                            backgroundColor: Colors.white.withValues(alpha: 0.6),
                                            padding: const EdgeInsets.all(8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Body: List of History Orders
                                  Consumer<ChefProvider>(
                                    builder: (context, provider, _) {
                                      final history = provider.historyOrders;

                                      if (history.isEmpty) {
                                        return const Padding(
                                          padding: EdgeInsets.all(32),
                                          child: Column(
                                            children: [
                                              Icon(
                                                Icons.receipt_long_outlined,
                                                size: 40,
                                                color: AppColors.textSecondary,
                                              ),
                                              SizedBox(height: 10),
                                              Text(
                                                'No Order History Yet',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                'Completed orders will appear here.',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }

                                      return Container(
                                        constraints: BoxConstraints(
                                          maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.6,
                                        ),
                                        child: ListView.separated(
                                          shrinkWrap: true,
                                          padding: const EdgeInsets.all(16),
                                          itemCount: history.length,
                                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                                          itemBuilder: (context, index) {
                                            return ChefOrderCard(
                                              key: ValueKey(history[index].id),
                                              order: history[index],
                                            );
                                          },
                                        ),
                                      );
                                    },
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
          ),
        ),
      );
    },
  );
}
