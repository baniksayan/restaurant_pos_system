import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/features/order_taking/providers/order_provider.dart';
import '../../providers/navigation_provider.dart';
import 'package:restaurant_pos_system/core/constants/app_strings.dart';
import 'package:restaurant_pos_system/core/utils/snackbar_helper.dart';
import 'package:restaurant_pos_system/shared/widgets/dialogs/app_glass_dialog.dart';
import 'package:restaurant_pos_system/shared/widgets/forms/custom_text_field.dart';

class CustomerInfoDialog extends StatefulWidget {
  final String orderChannelType; // 'Phone' or 'Takeaway'
  final VoidCallback? onSuccess;
  final VoidCallback? onBack;

  const CustomerInfoDialog({
    super.key,
    required this.orderChannelType,
    this.onSuccess,
    this.onBack,
  });

  @override
  State<CustomerInfoDialog> createState() => _CustomerInfoDialogState();
}

class _CustomerInfoDialogState extends State<CustomerInfoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      final navigationProvider = Provider.of<NavigationProvider>(
        context,
        listen: false,
      );

      // Create order for Phone/Takeaway
      final success = await orderProvider.createPhoneTakeawayOrder(
        orderChannelType: widget.orderChannelType,
        customerName: _nameController.text.trim(),
        customerPhone: _phoneController.text.trim(),
      );

      if (success && mounted) {
        Navigator.of(context).pop();

        // Navigate to menu for phone/takeaway order
        navigationProvider.selectOrderTypeAndNavigate(
          widget.orderChannelType,
          _nameController.text.trim(),
          _phoneController.text.trim(),
        );

        // Show success message
        AppSnackBar.showSuccess(
          context,
          '${widget.orderChannelType} order created successfully!',
        );

        widget.onSuccess?.call();
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Error creating order: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayType =
        (widget.orderChannelType == 'Phone' ||
                widget.orderChannelType == 'PhoneOrder')
            ? 'Phone'
            : 'Takeaway';

    return AppGlassDialog(
      maxWidth: 400,
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with Close button
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    displayType == 'Phone'
                        ? Icons.phone_in_talk_rounded
                        : Icons.shopping_bag_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$displayType Order',
                    style: const TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.05),
                    foregroundColor: AppColors.textSecondary,
                    padding: const EdgeInsets.all(8),
                    minimumSize: const Size(32, 32),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Customer Name Field
            CustomTextField(
              controller: _nameController,
              labelText: AppStrings.dashboard.customerNameLabel,
              hintText: AppStrings.dashboard.enterCustomerName,
              prefixIcon: Icons.person_outline_rounded,
              fillColor: Colors.white.withValues(alpha: 0.48),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Customer name is required';
                }
                if (value.trim().length < 2) {
                  return 'Name must be at least 2 characters';
                }
                return null;
              },
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 14),

            // Customer Phone Field
            CustomTextField(
              controller: _phoneController,
              labelText: AppStrings.dashboard.phoneNumberLabel,
              hintText: AppStrings.dashboard.enterPhoneNumber,
              prefixIcon: Icons.phone_outlined,
              fillColor: Colors.white.withValues(alpha: 0.48),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Phone number is required';
                }
                if (value.trim().length < 10) {
                  return 'Enter valid phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _isLoading
                            ? null
                            : (widget.onBack ??
                                () => Navigator.of(context).pop()),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.4),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Back',
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
                    onPressed: _isLoading ? null : _handleConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child:
                        _isLoading
                            ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : const Text(
                              'Confirm',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
