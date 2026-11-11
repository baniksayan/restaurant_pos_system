import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/core/constants/currency_constants.dart';
import 'package:restaurant_pos_system/core/utils/haptic_helper.dart';
import 'package:restaurant_pos_system/data/models/order_detail_api_response_model.dart';
import 'package:restaurant_pos_system/shared/widgets/layout/skeleton_loader.dart';

/// Lets the cashier choose which of an order's still-unbilled items go on
/// *this* bill — the rest stay unbilled for a later split. Everything shown
/// here comes straight from `GetOrderDetailById`, so the ids are real
/// `OrderDetailId`s that `createBill`'s itemList already understands; no new
/// backend support is needed, just a UI in front of the existing per-item
/// billing the stored procedure supports.
class SplitBillPicker extends StatelessWidget {
  final bool loading;
  final List<OrderDetailList> items;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;
  final VoidCallback onSelectAll;
  final VoidCallback onSelectNone;

  const SplitBillPicker({
    super.key,
    required this.loading,
    required this.items,
    required this.selectedIds,
    required this.onToggle,
    required this.onSelectAll,
    required this.onSelectNone,
  });

  double get _selectedTotal {
    return items
        .where((i) => selectedIds.contains(i.orderDetailId))
        .fold<double>(
          0,
          (sum, i) =>
              sum +
              (i.totPrice ?? ((i.itemPrice ?? 0) * (i.productQty ?? 1)))
                  .toDouble(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.90),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon, title, subtitle & action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.checklist_rounded,
                      size: 17,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Items for This Bill',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Select items to include in this bill',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (!loading && items.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ActionButton(
                      label: 'All',
                      isPrimary: true,
                      onTap: () {
                        HapticHelper.triggerFeedback();
                        onSelectAll();
                      },
                    ),
                    const SizedBox(width: 6),
                    _ActionButton(
                      label: 'Clear',
                      isPrimary: false,
                      onTap: () {
                        HapticHelper.triggerFeedback();
                        onSelectNone();
                      },
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 10),

          if (loading)
            Column(
              children: List.generate(
                3,
                (_) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SkeletonLoader.rectangular(
                    height: 44,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            )
          else if (items.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.center,
              child: const Text(
                'Every item on this order has already been billed.',
                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
              ),
            )
          else ...[
            // Column Header Row matching Order Items table
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFCBD5E1), width: 0.8),
                ),
              ),
              child: const Row(
                children: [
                  SizedBox(width: 26), // selection indicator placeholder
                  Expanded(
                    child: Text(
                      'ITEM',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  SizedBox(
                    width: 52,
                    child: Center(
                      child: Text(
                        'QTY',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  SizedBox(
                    width: 95,
                    child: Text(
                      'AMOUNT',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // Selectable Items List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final item = items[index];
                final id = item.orderDetailId ?? '';
                final isSelected = selectedIds.contains(id);
                final lineTotal =
                    (item.totPrice ??
                            ((item.itemPrice ?? 0) * (item.productQty ?? 1)))
                        .toDouble();

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap:
                        id.isEmpty
                            ? null
                            : () {
                              HapticHelper.triggerFeedback();
                              onToggle(id);
                            },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? AppColors.primary.withValues(alpha: 0.06)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color:
                              isSelected
                                  ? AppColors.primary.withValues(alpha: 0.20)
                                  : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Sleek custom selection circle
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  isSelected
                                      ? AppColors.primary
                                      : Colors.transparent,
                              border: Border.all(
                                color:
                                    isSelected
                                        ? AppColors.primary
                                        : const Color(0xFFCBD5E1),
                                width: 1.5,
                              ),
                            ),
                            child:
                                isSelected
                                    ? const Icon(
                                      Icons.check_rounded,
                                      size: 13,
                                      color: Colors.white,
                                    )
                                    : null,
                          ),
                          const SizedBox(width: 8),

                          // Item Name
                          Expanded(
                            child: Text(
                              item.productName ?? 'Item',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight:
                                    isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                color:
                                    isSelected
                                        ? AppColors.textPrimary
                                        : const Color(0xFF64748B),
                                height: 1.25,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Clean Quantity Pill matching main table
                          SizedBox(
                            width: 52,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2.5,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? AppColors.primary.withValues(
                                            alpha: 0.10,
                                          )
                                          : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${item.productQty ?? 1}',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color:
                                        isSelected
                                            ? AppColors.primary
                                            : const Color(0xFF64748B),
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Amount column (matching header)
                          SizedBox(
                            width: 95,
                            child: Text(
                              lineTotal.toCurrency(),
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color:
                                    isSelected
                                        ? AppColors.textPrimary
                                        : const Color(0xFF94A3B8),
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Divider(
                height: 1,
                thickness: 0.8,
                color: Color(0xFFCBD5E1),
              ),
            ),

            // Summary Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color:
                        selectedIds.isEmpty
                            ? Colors.amber.withValues(alpha: 0.12)
                            : AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    selectedIds.isEmpty
                        ? 'Select at least 1 item'
                        : 'Selected ${selectedIds.length} of ${items.length} items',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color:
                          selectedIds.isEmpty
                              ? const Color(0xFFD97706)
                              : AppColors.primary,
                    ),
                  ),
                ),
                Text(
                  _selectedTotal.toCurrency(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color:
              isPrimary
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                isPrimary
                    ? AppColors.primary.withValues(alpha: 0.3)
                    : const Color(0xFFCBD5E1),
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isPrimary ? AppColors.primary : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}
