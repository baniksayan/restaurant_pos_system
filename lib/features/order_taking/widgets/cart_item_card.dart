import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos_system/shared/widgets/images/network_image_widget.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/core/constants/currency_constants.dart';
import 'package:restaurant_pos_system/core/utils/haptic_helper.dart';
import 'package:restaurant_pos_system/features/menu/providers/menu_provider.dart';
import '../providers/animated_cart_provider.dart';

class CartItemCard extends StatelessWidget {
  final CartItem item;
  final VoidCallback onEdit;
  final bool showKotBadge;

  const CartItemCard({
    super.key,
    required this.item,
    required this.onEdit,
    this.showKotBadge = false,
  });

  String _getImageUrl(BuildContext context) {
    if (item.imageUrl != null && item.imageUrl!.isNotEmpty) {
      return item.imageUrl!;
    }
    final menuProvider = Provider.of<MenuProvider>(context, listen: false);
    return menuProvider.getImageUrlForProduct(item.id) ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<AnimatedCartProvider>(context);

    if (item.isKotGenerated) {
      return _buildKotGeneratedCard(context);
    }

    return _buildPendingItemCard(context, cartProvider);
  }

  // ✅ Pending KOT Item Card (Editable) - Compact POS Layout
  Widget _buildPendingItemCard(
    BuildContext context,
    AnimatedCartProvider cartProvider,
  ) {
    const accentColor = Color(0xFFEA580C);
    final imageUrl = _getImageUrl(context);
    final hasNote =
        item.specialNotes != null && item.specialNotes!.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFED7AA),
          width: 0.9,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 52x52 Thumbnail with image or food icon
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 52,
              height: 52,
              child: imageUrl.isNotEmpty
                  ? NetworkImageWidget(
                      imageUrl: imageUrl,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: accentColor.withValues(alpha: 0.08),
                      child: const Icon(
                        Icons.restaurant_rounded,
                        color: accentColor,
                        size: 22,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 10),

          // Main details & controls
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Row 1: Name + Item Total Amount
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E1B4B),
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      (item.price * item.quantity).toCurrency(),
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                // Row 2: Unit rate on left, compact stepper & edit/delete on right
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Unit rate & UOM
                    Text(
                      '${item.price.toCurrency()}${item.uom != null && item.uom!.isNotEmpty ? ' / ${item.uom}' : ''}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),

                    // Controls: Stepper (- qty +), Edit Note icon, Delete icon
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Compact Stepper
                        Container(
                          height: 27,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: () async {
                                  await HapticHelper.triggerFeedback();
                                  if (!context.mounted) return;
                                  if (item.quantity == 1) {
                                    final shouldRemove =
                                        await _showRemoveConfirmDialog(context);
                                    if (shouldRemove) {
                                      cartProvider.removeItem(item.id);
                                    }
                                  } else {
                                    cartProvider.removeItem(item.id);
                                  }
                                },
                                borderRadius: const BorderRadius.horizontal(
                                  left: Radius.circular(6),
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  child: Icon(
                                    Icons.remove_rounded,
                                    size: 14,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                                child: Text(
                                  '${item.quantity}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: accentColor,
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () async {
                                  await HapticHelper.triggerFeedback();
                                  cartProvider.addItem(
                                    item.id,
                                    item.name,
                                    item.price,
                                    item.tableId,
                                    item.tableName,
                                    imageUrl: item.imageUrl,
                                    specialNotes: item.specialNotes,
                                    categoryId: item.categoryId,
                                    categoryName: item.categoryName,
                                    uom: item.uom,
                                    discountPercentage: item.discountPercentage,
                                  );
                                },
                                borderRadius: const BorderRadius.horizontal(
                                  right: Radius.circular(6),
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  child: Icon(
                                    Icons.add_rounded,
                                    size: 14,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 6),

                        // Edit Note Button
                        InkWell(
                          onTap: () async {
                            await HapticHelper.triggerFeedback();
                            onEdit();
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: const Padding(
                            padding: EdgeInsets.all(3.0),
                            child: Icon(
                              Icons.edit_note_rounded,
                              size: 20,
                              color: Color(0xFF6366F1),
                            ),
                          ),
                        ),

                        // Delete All Button (if qty > 1)
                        if (item.quantity > 1 && item.canEdit) ...[
                          const SizedBox(width: 2),
                          InkWell(
                            onTap: () async {
                              await HapticHelper.triggerFeedback();
                              if (!context.mounted) return;
                              final shouldDelete =
                                  await _showDeleteAllConfirmDialog(context);
                              if (shouldDelete) {
                                cartProvider.deleteAllOfItem(item.id);
                              }
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.all(3.0),
                              child: Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                                color: Colors.red[600],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),

                // Row 3: Special Instructions / Item Note (at the bottom)
                if (hasNote) ...[
                  const SizedBox(height: 6),
                  _buildCompactSpecialInstructions(context),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ KOT Generated Item Card (Read-only) - Compact POS Layout
  Widget _buildKotGeneratedCard(BuildContext context) {
    const accentColor = Color(0xFF6D28D9);
    final imageUrl = _getImageUrl(context);
    final hasNote =
        item.specialNotes != null && item.specialNotes!.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFDDD6FE),
          width: 0.9,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 52x52 Thumbnail with image or food icon
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 52,
              height: 52,
              child: imageUrl.isNotEmpty
                  ? NetworkImageWidget(
                      imageUrl: imageUrl,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: accentColor.withValues(alpha: 0.08),
                      child: const Icon(
                        Icons.restaurant_rounded,
                        color: accentColor,
                        size: 22,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 10),

          // Main details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Row 1: Name + Total Price
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E1B4B),
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      (item.price * item.quantity).toCurrency(),
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                // Row 2: Unit rate + Qty badge (Info dialog icon removed)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Unit rate
                    Text(
                      '${item.price.toCurrency()}${item.uom != null && item.uom!.isNotEmpty ? ' / ${item.uom}' : ''}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),

                    // KOT Status Badges
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (showKotBadge && item.kotNumber != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: accentColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'KOT #${item.kotNumber}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFF7C3AED).withValues(alpha: 0.25),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            'Qty: ${item.quantity}',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: accentColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Row 3: Special Instructions / Item Note (at the bottom)
                if (hasNote) ...[
                  const SizedBox(height: 6),
                  _buildCompactSpecialInstructions(context),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Special instructions banner - Perfectly Aligned Note Bar at bottom
  Widget _buildCompactSpecialInstructions(BuildContext context) {
    final instruction = item.specialNotes!;

    return GestureDetector(
      onTap: item.canEdit ? onEdit : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFFDE68A), width: 0.8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 1),
              child: Icon(
                Icons.edit_note_rounded,
                color: Color(0xFFD97706),
                size: 14,
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: 'Item Note: ',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFB45309),
                      ),
                    ),
                    TextSpan(
                      text: instruction,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (item.canEdit) ...[
              const SizedBox(width: 4),
              const Padding(
                padding: EdgeInsets.only(top: 1.5),
                child: Icon(
                  Icons.edit_outlined,
                  color: Color(0xFFD97706),
                  size: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ✅ CONFIRMATION DIALOG for Delete All Items (in Cart)
  Future<bool> _showDeleteAllConfirmDialog(BuildContext context) async {
    final result = await showGeneralDialog<bool>(
      context: context,
      barrierLabel: 'Delete All Items',
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return Material(
          type: MaterialType.transparency,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(dialogContext).pop(false),
            child: Stack(
              children: [
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 3.5, sigmaY: 3.5),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                SafeArea(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: GestureDetector(
                        onTap: () {},
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 340),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.52),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  24,
                                  20,
                                  20,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color: Colors.red.withValues(
                                          alpha: 0.12,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.delete_sweep_rounded,
                                        color: Colors.red,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Delete All Items',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Are you sure you want to remove all ${item.quantity} "${item.name}" items from your cart?',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        color: AppColors.textSecondary,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed:
                                                () => Navigator.of(
                                                  dialogContext,
                                                ).pop(false),
                                            style: OutlinedButton.styleFrom(
                                              backgroundColor: Colors.white
                                                  .withValues(alpha: 0.4),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 13,
                                                  ),
                                              side: BorderSide(
                                                color: Colors.white.withValues(
                                                  alpha: 0.75,
                                                ),
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                            child: const Text(
                                              'Cancel',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed:
                                                () => Navigator.of(
                                                  dialogContext,
                                                ).pop(true),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red[600],
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 13,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                            child: const Text(
                                              'Delete All',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
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
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
    );
    return result ?? false;
  }

  // ✅ CONFIRMATION DIALOG when decrementing to zero
  Future<bool> _showRemoveConfirmDialog(BuildContext context) async {
    final result = await showGeneralDialog<bool>(
      context: context,
      barrierLabel: 'Remove Item',
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return Material(
          type: MaterialType.transparency,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(dialogContext).pop(false),
            child: Stack(
              children: [
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 3.5, sigmaY: 3.5),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                SafeArea(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: GestureDetector(
                        onTap: () {},
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 340),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.52),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  24,
                                  20,
                                  20,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color: Colors.red.withValues(
                                          alpha: 0.12,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: Colors.red,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Remove Item',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Are you sure you want to remove "${item.name}" from your cart?',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        color: AppColors.textSecondary,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed:
                                                () => Navigator.of(
                                                  dialogContext,
                                                ).pop(false),
                                            style: OutlinedButton.styleFrom(
                                              backgroundColor: Colors.white
                                                  .withValues(alpha: 0.4),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 13,
                                                  ),
                                              side: BorderSide(
                                                color: Colors.white.withValues(
                                                  alpha: 0.75,
                                                ),
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                            child: const Text(
                                              'Cancel',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed:
                                                () => Navigator.of(
                                                  dialogContext,
                                                ).pop(true),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red[600],
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 13,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                            child: const Text(
                                              'Remove',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
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
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
    );
    return result ?? false;
  }
}
