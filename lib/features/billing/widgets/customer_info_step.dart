import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/core/utils/haptic_helper.dart';
import 'package:restaurant_pos_system/data/remote/api_service.dart';
import 'package:restaurant_pos_system/shared/widgets/dialogs/glassmorphic_country_picker.dart';
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
  final bool skipPayment;

  const CustomerInfoResult({
    required this.phone,
    required this.firstName,
    required this.lastName,
    this.customerId,
    this.skipPayment = false,
  });
}

/// Step 2 of the checkout flow — collects the customer's phone number and,
/// once looked up, either auto-fills their name (existing customer) or lets
/// the cashier type a new one (walk-in).
///
/// Styled with a premium frosted glassmorphic popup modal matching
/// [GenerateBillSummaryDialog].
class CustomerInfoStep extends StatefulWidget {
  final String orderNumber;

  const CustomerInfoStep({super.key, required this.orderNumber});

  static Future<CustomerInfoResult?> show(
    BuildContext context, {
    required String orderNumber,
  }) {
    return showGeneralDialog<CustomerInfoResult>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Customer Details',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return CustomerInfoStep(orderNumber: orderNumber);
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
  }

  @override
  State<CustomerInfoStep> createState() => _CustomerInfoStepState();
}

class _CustomerInfoStepState extends State<CustomerInfoStep> {
  final _phoneController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  final _phoneFocusNode = FocusNode();
  final _firstNameFocusNode = FocusNode();
  final _lastNameFocusNode = FocusNode();

  late Country _selectedCountry;
  String _countryCode = '+91';
  String? _customerId;
  bool _looking = false;
  String? _lastLookedUpNumber;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _selectedCountry = countries.firstWhere(
      (c) => c.code == 'IN',
      orElse: () => countries.first,
    );
    _countryCode = '+${_selectedCountry.dialCode}';
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _phoneController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneFocusNode.dispose();
    _firstNameFocusNode.dispose();
    _lastNameFocusNode.dispose();
    super.dispose();
  }

  void _onPhoneChanged(String number) {
    final digits = number.replaceAll(RegExp(r'\D'), '');
    if (_customerId != null && digits != _lastLookedUpNumber) {
      setState(() {
        _customerId = null;
      });
    }

    _debounce?.cancel();
    if (digits.length == 10) {
      _debounce = Timer(const Duration(milliseconds: 300), () {
        _autoLookup(digits);
      });
    }
  }

  Future<void> _autoLookup(String digits) async {
    if (digits.length != 10) return;
    if (_lastLookedUpNumber == digits && _customerId != null) return;
    _lastLookedUpNumber = digits;

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

        // Existing customer found: unfocus keyboard
        FocusScope.of(context).unfocus();

        AppSnackBar.showSuccess(
          context,
          data.customerFirstName.isNotEmpty
              ? 'Welcome back, ${data.customerFirstName}!'
              : 'Existing customer found.',
        );
      } else {
        // Customer not found: clear existing flag and auto-shift focus to First Name
        setState(() {
          _customerId = null;
        });
        _firstNameFocusNode.requestFocus();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _customerId = null);
        _firstNameFocusNode.requestFocus();
      }
    } finally {
      if (mounted) setState(() => _looking = false);
    }
  }

  void _continue() {
    HapticHelper.triggerFeedback();
    final digits = _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
    Navigator.of(context).pop(
      CustomerInfoResult(
        phone: digits.isEmpty ? '' : '$_countryCode$digits',
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        customerId: _customerId,
        skipPayment: false,
      ),
    );
  }

  void _skip() {
    HapticHelper.triggerFeedback();
    Navigator.of(context).pop(
      const CustomerInfoResult(
        phone: '',
        firstName: '',
        lastName: '',
        skipPayment: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isTablet = size.width >= 600;

    final cleanOrderNo = widget.orderNumber.replaceFirst(RegExp(r'^#+'), '').trim();
    final badgeOrderText = cleanOrderNo.isNotEmpty ? '#$cleanOrderNo' : '#OD';

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Fullscreen Minimal Backdrop Blur matching GenerateBillSummaryDialog
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3.5, sigmaY: 3.5),
              child: Container(color: Colors.black.withValues(alpha: 0.12)),
            ),
          ),

          // Main Frosted Glassmorphic Modal Card
          SafeArea(
            child: Center(
              child: Container(
                width: isTablet ? size.width * 0.72 : size.width * 0.90,
                constraints: BoxConstraints(
                  maxWidth: isTablet ? 600 : 440,
                  maxHeight: isTablet ? 700 : 620,
                ),
                margin: EdgeInsets.symmetric(
                  horizontal: isTablet ? 24 : 12,
                  vertical: isTablet ? 20 : 12,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.70),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.85),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.10),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Glass Header Bar
                          _buildHeader(context, badgeOrderText),

                          // Scrollable Form Content
                          Flexible(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Informational Header Card
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.70),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.90),
                                        width: 1,
                                      ),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline_rounded,
                                          size: 16,
                                          color: AppColors.primary,
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Optional — enter phone number to find existing customer, or skip for walk-in.',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              color: AppColors.textSecondary,
                                              height: 1.3,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 14),

                                  // Phone Number Section
                                  const Text(
                                    'PHONE NUMBER',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textSecondary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  // Unified Glassmorphic Phone Input Row
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Country Dial Code Selector Pill
                                      InkWell(
                                        onTap: () async {
                                          HapticHelper.triggerFeedback();
                                          final picked =
                                              await GlassmorphicCountryPicker.show(
                                            context,
                                            selectedCountry: _selectedCountry,
                                          );
                                          if (picked != null && mounted) {
                                            setState(() {
                                              _selectedCountry = picked;
                                              _countryCode = '+${picked.dialCode}';
                                            });
                                            _onPhoneChanged(_phoneController.text);
                                          }
                                        },
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          height: 52,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.85),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: const Color(0xFFE2E8F0),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                _selectedCountry.flag,
                                                style: const TextStyle(fontSize: 20),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                '+${_selectedCountry.dialCode}',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(width: 2),
                                              const Icon(
                                                Icons.arrow_drop_down_rounded,
                                                size: 20,
                                                color: AppColors.textSecondary,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),

                                      // Phone Number Input
                                      Expanded(
                                        child: TextFormField(
                                          controller: _phoneController,
                                          focusNode: _phoneFocusNode,
                                          keyboardType: TextInputType.phone,
                                          inputFormatters: [
                                            FilteringTextInputFormatter.digitsOnly,
                                            LengthLimitingTextInputFormatter(
                                              _selectedCountry.maxLength > 0
                                                  ? _selectedCountry.maxLength
                                                  : 15,
                                            ),
                                          ],
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          decoration: InputDecoration(
                                            labelText: 'Phone Number',
                                            hintText: _selectedCountry.maxLength > 0
                                                ? 'Enter ${_selectedCountry.maxLength}-digit number'
                                                : 'Enter phone number',
                                            labelStyle: const TextStyle(
                                              color: AppColors.textSecondary,
                                            ),
                                            filled: true,
                                            fillColor: Colors.white.withValues(alpha: 0.85),
                                            contentPadding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 15,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                color: Color(0xFFCBD5E1),
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                color: Color(0xFFE2E8F0),
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                color: AppColors.primary,
                                                width: 1.5,
                                              ),
                                            ),
                                            suffixIcon: _looking
                                                ? const Padding(
                                                  padding: EdgeInsets.all(12),
                                                  child: SizedBox(
                                                    width: 18,
                                                    height: 18,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor:
                                                          AlwaysStoppedAnimation(
                                                            AppColors.primary,
                                                          ),
                                                    ),
                                                  ),
                                                )
                                                : (_customerId != null
                                                    ? const Padding(
                                                      padding: EdgeInsets.all(10),
                                                      child: Icon(
                                                        Icons.check_circle_rounded,
                                                        size: 20,
                                                        color: AppColors.success,
                                                      ),
                                                    )
                                                    : (_phoneController.text.isNotEmpty
                                                        ? IconButton(
                                                          icon: const Icon(
                                                            Icons.clear_rounded,
                                                            size: 18,
                                                          ),
                                                          color: AppColors.textSecondary,
                                                          onPressed: () {
                                                            _phoneController.clear();
                                                            _onPhoneChanged('');
                                                            setState(() {});
                                                          },
                                                        )
                                                        : null)),
                                          ),
                                          onChanged: (val) {
                                            _onPhoneChanged(val);
                                            setState(() {});
                                          },
                                        ),
                                      ),
                                    ],
                                  ),

                                  if (_customerId != null) ...[
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.success.withValues(alpha: 0.10),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppColors.success.withValues(alpha: 0.30),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.verified_rounded,
                                            size: 15,
                                            color: AppColors.success,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Existing Customer • ${_firstNameController.text} ${_lastNameController.text}'.trim(),
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.success,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: 16),

                                  // Customer Name Section
                                  const Text(
                                    'CUSTOMER NAME',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textSecondary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  CustomTextField(
                                    controller: _firstNameController,
                                    focusNode: _firstNameFocusNode,
                                    label: 'First Name',
                                    hintText: 'Enter first name',
                                    textInputAction: TextInputAction.next,
                                    onFieldSubmitted: (_) {
                                      _lastNameFocusNode.requestFocus();
                                    },
                                  ),
                                  const SizedBox(height: 12),

                                  CustomTextField(
                                    controller: _lastNameController,
                                    focusNode: _lastNameFocusNode,
                                    label: 'Last Name',
                                    hintText: 'Enter last name',
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => _continue(),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Glass Action Bar
                          _buildActionBar(context),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String badgeText) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.35),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.60),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.30),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              size: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Customer Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.30),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        badgeText,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            onPressed: () {
              HapticHelper.triggerFeedback();
              Navigator.of(context).pop(null);
            },
            style: IconButton.styleFrom(
              backgroundColor: Colors.black.withValues(alpha: 0.05),
              foregroundColor: AppColors.textSecondary,
              padding: const EdgeInsets.all(6),
              minimumSize: const Size(32, 32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.35),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.60),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 46,
              child: OutlinedButton(
                onPressed: _skip,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFCBD5E1), width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Skip',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 46,
              child: ElevatedButton(
                onPressed: _continue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shadowColor: AppColors.primary.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Continue to Payment',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
