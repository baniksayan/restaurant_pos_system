import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/core/constants/currency_constants.dart';
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
              sum + (i.totPrice ?? ((i.itemPrice ?? 0) * (i.productQty ?? 1)))
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
          color: AppColors.primary.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Items in This Bill',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (!loading && items.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _TextAction(label: 'All', onTap: onSelectAll),
                    const SizedBox(width: 10),
                    _TextAction(label: 'None', onTap: onSelectNone),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
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
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Every item on this order has already been billed.',
                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
              ),
            )
          else ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder:
                  (_, __) => const Divider(
                    height: 8,
                    thickness: 0.5,
                    color: Color(0xFFE2E8F0),
                  ),
              itemBuilder: (context, index) {
                final item = items[index];
                final id = item.orderDetailId ?? '';
                final isSelected = selectedIds.contains(id);
                final lineTotal =
                    item.totPrice ??
                    ((item.itemPrice ?? 0) * (item.productQty ?? 1));
                return InkWell(
                  onTap: id.isEmpty ? null : () => onToggle(id),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Checkbox(
                          value: isSelected,
                          activeColor: AppColors.primary,
                          onChanged: id.isEmpty ? null : (_) => onToggle(id),
                        ),
                        Expanded(
                          child: Text(
                            item.productName ?? 'Item',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          'x${item.productQty ?? 1}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 70,
                          child: Text(
                            CurrencyConstants.format(lineTotal),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Divider(height: 1, thickness: 0.8, color: Color(0xFFCBD5E1)),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Selected ${selectedIds.length} of ${items.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  CurrencyConstants.format(_selectedTotal),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
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

class _TextAction extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _TextAction({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
