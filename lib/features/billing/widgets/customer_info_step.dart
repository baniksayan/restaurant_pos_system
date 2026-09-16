import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/core/utils/haptic_helper.dart';
import 'package:restaurant_pos_system/data/remote/api_service.dart';
import 'package:restaurant_pos_system/shared/widgets/forms/custom_text_field.dart';
import 'package:restaurant_pos_system/core/utils/snackbar_helper.dart';

/// What this step hands back once the cashier continues — a resolved
/// existing customer (matched by phone) or a new walk-in's details. Every
/// field can be empty: billing already allows a fully anonymous walk-in,
/// and this step must not force a phone number where none was required
/// before.
class CustomerInfoResult {
  final String phone;
  final String firstName;
  final String lastName;
  final String? customerId;

  const CustomerInfoResult({
    required this.phone,
    required this.firstName,
    required this.lastName,
    this.customerId,
  });
}

/// Step 2 of the checkout flow — collects the customer's phone number and,
/// once looked up, either auto-fills their name (existing customer) or lets
/// the cashier type a new one (walk-in). Runs before Payment; nothing here
/// touches the bill or the order — it only produces a [CustomerInfoResult]
/// for the caller to pass into `BillingProvider.generateBill`.
class CustomerInfoStep extends StatefulWidget {
  final String orderNumber;

  const CustomerInfoStep({super.key, required this.orderNumber});

  @override
  State<CustomerInfoStep> createState() => _CustomerInfoStepState();
}

class _CustomerInfoStepState extends State<CustomerInfoStep> {
  final _phoneController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  String _countryCode = '+91';
  String? _customerId;
  bool _looking = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  /// Looking up a different number after a match invalidates it — keep the
  /// typed name, but stop attributing it to the previous customerId.
  void _forgetMatchedCustomer() {
    if (_customerId != null) {
      setState(() => _customerId = null);
    }
  }

  Future<void> _lookup() async {
    final digits = _phoneController.text.trim();
    if (digits.length < 7) {
      AppSnackBar.showWarning(
        context,
        'Enter a valid phone number to look up.',
      );
      return;
    }
    await HapticHelper.triggerFeedback();
    setState(() => _looking = true);
    try {
      final response = await ApiService.getCustomerByMobileNo(
        contactNo: '$_countryCode$digits',
      );
      final data = response?.data;
      if (!mounted) return;
      if (response?.isSuccess == true &&
          data != null &&
          data.customerId.isNotEmpty) {
        setState(() {
          _firstNameController.text = data.customerFirstName;
          _lastNameController.text = data.customerLastName;
          _customerId = data.customerId;
        });
        AppSnackBar.showSuccess(
          context,
          data.customerFirstName.isNotEmpty
              ? 'Welcome back, ${data.customerFirstName}!'
              : 'Existing customer found.',
        );
      } else {
        setState(() => _customerId = null);
        AppSnackBar.showSuccess(context, 'New customer — enter their name below.');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Could not look up that number: $e');
      }
    } finally {
      if (mounted) setState(() => _looking = false);
    }
  }

  void _continue() {
    HapticHelper.triggerFeedback();
    final digits = _phoneController.text.trim();
    Navigator.of(context).pop(
      CustomerInfoResult(
        phone: digits.isEmpty ? '' : '$_countryCode$digits',
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        customerId: _customerId,
      ),
    );
  }

  void _skip() {
    HapticHelper.triggerFeedback();
    Navigator.of(
      context,
    ).pop(const CustomerInfoResult(phone: '', firstName: '', lastName: ''));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Customer Details'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Order #${widget.orderNumber}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Who is this bill for?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            const Text(
              'Optional — skip for an anonymous walk-in. If the number '
              'matches an existing customer, their name fills in automatically.',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: IntlPhoneField(
                    controller: _phoneController,
                    initialCountryCode: 'IN',
                    // IntlPhoneField doesn't reliably inherit the app's text
                    // theme for what you type — left unset, the digits were
                    // rendering in a colour indistinguishable from the field
                    // background (invisible while typing, even though the
                    // value was captured correctly and submitted fine).
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                    ),
                    dropdownTextStyle: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                      border: OutlineInputBorder(),
                    ),
                    showCountryFlag: true,
                    showDropdownIcon: true,
                    onChanged: (phone) {
                      _countryCode = phone.countryCode;
                      _forgetMatchedCustomer();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _looking ? null : _lookup,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child:
                          _looking
                              ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text('Look Up'),
                    ),
                  ),
                ),
              ],
            ),
            if (_customerId != null) ...[
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: AppColors.success,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Existing customer',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            CustomTextField(
              controller: _firstNameController,
              label: 'First Name',
              hintText: 'Walk-in',
            ),
            const SizedBox(height: 14),
            CustomTextField(
              controller: _lastNameController,
              label: 'Last Name',
              hintText: 'Customer',
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton(
                    onPressed: _skip,
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Skip'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _continue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Continue to Payment',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
