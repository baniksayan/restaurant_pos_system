import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos_system/core/utils/haptic_helper.dart';
import 'dart:io';

import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/core/constants/currency_constants.dart';
import 'package:restaurant_pos_system/data/models/restaurant_table.dart';
import '../models/reservation.dart';
import '../providers/reservation_provider.dart';
import 'package:restaurant_pos_system/features/dashboard/providers/navigation_provider.dart';
import '../services/reservation_bill_service.dart';
import 'package:restaurant_pos_system/core/constants/app_strings.dart';
import 'package:restaurant_pos_system/core/utils/app_validators.dart';
import 'package:restaurant_pos_system/core/utils/snackbar_helper.dart';

class TableReservationView extends StatefulWidget {
  final RestaurantTable table;
  final Function(Reservation)? onReservationConfirmed;

  const TableReservationView({
    super.key,
    required this.table,
    this.onReservationConfirmed,
  });

  @override
  State<TableReservationView> createState() => _TableReservationViewState();
}

class _TableReservationViewState extends State<TableReservationView> {
  final _formKey = GlobalKey<FormState>();
  final _personsController = TextEditingController(text: '2');
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _specialNotesController = TextEditingController();
  final _advanceAmountController = TextEditingController();

  DateTime? _fromTime;
  DateTime? _toTime;
  String _selectedOccasion = 'Other';
  bool _decoration = false;
  double _calculatedPrice = 0.0;
  double _minAdvanceAmount = 100.0;
  String? _timeValidationError;

  final List<String> _occasions = [
    'Other',
    'Birthday',
    'Anniversary',
    'Ceremony',
    'Party',
  ];

  @override
  void initState() {
    super.initState();
    _setDefaultTimes();
  }

  void _setDefaultTimes() {
    final now = DateTime.now();
    final defaultStart = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour + 3,
      0,
    );
    final defaultEnd = defaultStart.add(const Duration(hours: 2));

    setState(() {
      _fromTime = defaultStart;
      _toTime = defaultEnd;
    });
    _calculatePrice();
    _validateReservationTime();
  }

  void _calculatePrice() {
    if (_fromTime != null && _toTime != null) {
      final reservationProvider = context.read<ReservationProvider>();
      final price = reservationProvider.calculatePrice(
        fromTime: _fromTime!,
        toTime: _toTime!,
        occasion: _selectedOccasion,
        decoration: _decoration,
      );
      setState(() {
        _calculatedPrice = price;
        _minAdvanceAmount = Reservation.getMinAdvanceAmount(price);
        _advanceAmountController.text = _minAdvanceAmount.toStringAsFixed(0);
      });
    }
  }

  void _validateReservationTime() {
    if (_fromTime != null && _toTime != null) {
      final reservationProvider = context.read<ReservationProvider>();
      setState(() {
        _timeValidationError = reservationProvider.validateReservationTime(
          fromTime: _fromTime!,
          toTime: _toTime!,
        );
      });
    }
  }

  Future<void> _triggerHapticFeedback() => HapticHelper.triggerFeedback();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            _buildModernHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTableInfoCard(),
                      const SizedBox(height: 16),
                      _buildCustomerInfoCard(),
                      const SizedBox(height: 16),
                      _buildReservationDetailsCard(),
                      const SizedBox(height: 16),
                      _buildPricingAndPaymentCard(),
                      const SizedBox(height: 16),
                      _buildActionButtons(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildPersistentBottomNav(),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back,
                color: AppColors.primary,
                size: 22,
              ),
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reserve Table',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Book ${widget.table.name} for dining',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Available',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade400, Colors.orange.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.table_restaurant,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.table.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Capacity: ${widget.table.capacity} persons',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.person, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Customer Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _customerNameController,
            decoration: InputDecoration(
              labelText: AppStrings.reservations.customerNameRequired,
              hintText: AppStrings.reservations.enterFullName,
              prefixIcon: const Icon(Icons.person_outline),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
            ),
            validator: (value) => AppValidators.name(value, 'customer name'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _customerPhoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            decoration: InputDecoration(
              labelText: AppStrings.reservations.phoneNumberRequired,
              hintText: AppStrings.reservations.enterTenDigitNumber,
              prefixIcon: const Icon(Icons.phone_outlined),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
            ),
            validator: AppValidators.indianPhone,
          ),
        ],
      ),
    );
  }

  Widget _buildReservationDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reservation Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          _buildPersonsField(),
          const SizedBox(height: 20),
          _buildTimeSelectionSection(),
          const SizedBox(height: 20),
          _buildOccasionSelection(),
          const SizedBox(height: 20),
          _buildSpecialNotesField(),
          const SizedBox(height: 20),
          _buildDurationDisplay(),
        ],
      ),
    );
  }

  Widget _buildPersonsField() {
    return TextFormField(
      controller: _personsController,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: AppStrings.reservations.numberOfPersons,
        hintText: AppStrings.reservations.enterNumberOfPersons,
        prefixIcon: const Icon(Icons.people_outline),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter number of persons';
        }
        final persons = int.tryParse(value);
        if (persons == null || persons < 1 || persons > widget.table.capacity) {
          return 'Please enter between 1 and ${widget.table.capacity} persons';
        }
        return null;
      },
    );
  }

  Widget _buildTimeSelectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Reservation Time',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: _showTimeInfo,
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Colors.blue,
                  size: 16,
                ),
              ),
              tooltip: AppStrings.reservations.reservationRules,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTimeSelector(
                label: AppStrings.reservations.from,
                time: _fromTime,
                icon: Icons.schedule,
                onTimeSelected: (time) {
                  setState(() {
                    _fromTime = time;
                    if (_toTime != null && time.isAfter(_toTime!)) {
                      _toTime = time.add(const Duration(hours: 1));
                    }
                  });
                  _calculatePrice();
                  _validateReservationTime();
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTimeSelector(
                label: AppStrings.reservations.to,
                time: _toTime,
                icon: Icons.schedule_outlined,
                onTimeSelected: (time) {
                  setState(() {
                    _toTime = time;
                  });
                  _calculatePrice();
                  _validateReservationTime();
                },
              ),
            ),
          ],
        ),
        if (_timeValidationError != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber, color: Colors.orange, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _timeValidationError!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTimeSelector({
    required String label,
    required DateTime? time,
    required IconData icon,
    required Function(DateTime) onTimeSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            await _triggerHapticFeedback();
            if (!mounted) return;
            final pickedTime = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.fromDateTime(time ?? DateTime.now()),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: Theme.of(
                      context,
                    ).colorScheme.copyWith(primary: AppColors.primary),
                  ),
                  child: child!,
                );
              },
            );
            if (pickedTime != null) {
              final now = DateTime.now();
              final selectedDateTime = DateTime(
                now.year,
                now.month,
                now.day,
                pickedTime.hour,
                pickedTime.minute,
              );
              final finalDateTime =
                  selectedDateTime.isBefore(now)
                      ? selectedDateTime.add(const Duration(days: 1))
                      : selectedDateTime;
              onTimeSelected(finalDateTime);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.grey.shade600, size: 18),
                const SizedBox(width: 8),
                Text(
                  time != null
                      ? TimeOfDay.fromDateTime(time).format(context)
                      : 'Select time',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color:
                        time != null ? AppColors.textPrimary : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOccasionSelection() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedOccasion,
      decoration: InputDecoration(
        labelText: AppStrings.reservations.specialOccasion,
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      items:
          _occasions.map((occasion) {
            return DropdownMenuItem(
              value: occasion,
              child: Text(
                occasion,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            );
          }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedOccasion = value!;
        });
        _calculatePrice();
      },
    );
  }

  Widget _buildSpecialNotesField() {
    return TextFormField(
      controller: _specialNotesController,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: AppStrings.reservations.specialNotesOptional,
        hintText: AppStrings.reservations.specialNotesHint,
        prefixIcon: const Icon(Icons.note_outlined),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }

  Widget _buildDurationDisplay() {
    final duration =
        _fromTime != null && _toTime != null
            ? _toTime!.difference(_fromTime!)
            : Duration.zero;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.timer_outlined,
              color: Colors.blue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Duration',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue,
                ),
              ),
              Text(
                '${duration.inHours}h ${duration.inMinutes % 60}m',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPricingAndPaymentCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.attach_money, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Pricing & Payment',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPricingBreakdown(),
          const SizedBox(height: 20),
          _buildAdvancePaymentSection(),
          const SizedBox(height: 16),
          _buildDecorationOption(),
        ],
      ),
    );
  }

  Widget _buildPricingBreakdown() {
    final advanceAmount =
        double.tryParse(_advanceAmountController.text) ?? _minAdvanceAmount;
    final remainingAmount = _calculatedPrice - advanceAmount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.green.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Base Amount:', style: TextStyle(fontSize: 14)),
              Text(
                '${CurrencyConstants.symbol}${_calculatedPrice.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
          if (_decoration) ...[
            const SizedBox(height: 4),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Decoration:', style: TextStyle(fontSize: 14)),
                Text(
                  '${CurrencyConstants.symbol}500',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ],
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
              Text(
                '${CurrencyConstants.symbol}${_calculatedPrice.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Advance Payment:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${CurrencyConstants.symbol}${advanceAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Remaining Amount:',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      '${CurrencyConstants.symbol}${remainingAmount.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancePaymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Advance Payment Amount',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _advanceAmountController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: AppStrings.reservations.enterAdvanceAmount,
            prefixIcon: const Icon(Icons.attach_money),
            suffixText: 'USD',
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            helperText:
                'Minimum: ${CurrencyConstants.symbol}${_minAdvanceAmount.toStringAsFixed(0)} • Maximum: ${CurrencyConstants.symbol}${_calculatedPrice.toStringAsFixed(0)}',
            helperStyle: const TextStyle(fontSize: 11),
          ),
          onChanged: (value) {
            setState(() {});
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter advance amount';
            }
            final amount = double.tryParse(value);
            if (amount == null) {
              return 'Please enter valid amount';
            }
            if (amount < _minAdvanceAmount) {
              return 'Minimum advance: ${CurrencyConstants.symbol}${_minAdvanceAmount.toStringAsFixed(0)}';
            }
            if (amount > _calculatedPrice) {
              return 'Cannot exceed total amount';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDecorationOption() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.purple, size: 20),
            SizedBox(width: 8),
            Text(
              'Table Decoration',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        subtitle: Text(AppStrings.reservations.decorationSubtitle),
        value: _decoration,
        activeThumbColor: AppColors.primary,
        onChanged: (value) {
          setState(() {
            _decoration = value;
          });
          _calculatePrice();
        },
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed:
                _timeValidationError == null ? _confirmReservation : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, size: 20),
                const SizedBox(width: 8),
                Text(
                  _timeValidationError == null
                      ? 'Confirm & Generate Bill'
                      : 'Fix Time Issues',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red, width: 2),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cancel, size: 20),
                SizedBox(width: 8),
                Text(
                  'Cancel',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPersistentBottomNav() {
    return Consumer<NavigationProvider>(
      builder: (context, navProvider, _) {
        return Container(
          height: 65,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 15,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.table_restaurant, 'Tables', navProvider),
              _buildNavItem(1, Icons.restaurant_menu, 'Menu', navProvider),
              _buildNavItem(2, Icons.shopping_cart, 'Cart', navProvider),
              _buildNavItem(3, Icons.person, 'Profile', navProvider),
              _buildNavItem(4, Icons.analytics, 'Reports', navProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    String label,
    NavigationProvider navProvider,
  ) {
    final isActive = navProvider.currentIndex == index;
    return GestureDetector(
      onTap: () {
        _triggerHapticFeedback();
        navProvider.navigateToIndex(index);
        Navigator.pop(context);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isActive ? AppColors.primary : Colors.grey[600],
            size: 22,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? AppColors.primary : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _showTimeInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.info_outline,
                        color: Colors.blue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Reservation Rules',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoItem(
                  icon: Icons.schedule,
                  title: AppStrings.reservations.advanceBooking,
                  description: 'Reserve at least 2 hours in advance',
                ),
                _buildInfoItem(
                  icon: Icons.access_time,
                  title: AppStrings.reservations.operatingHours,
                  description:
                      'Reservations until 12:00 AM (restaurant closing)',
                ),
                _buildInfoItem(
                  icon: Icons.timer,
                  title: AppStrings.reservations.durationLimits,
                  description: 'Minimum 30 minutes, Maximum 6 hours',
                ),
                _buildInfoItem(
                  icon: Icons.attach_money,
                  title: AppStrings.reservations.advancePayment,
                  description:
                      'Minimum 20% of total amount, ${CurrencyConstants.symbol}100 minimum',
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Got it',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReservation() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fromTime == null || _toTime == null) {
      _showErrorSnackBar(AppStrings.reservations.selectReservationTime);
      return;
    }
    if (_timeValidationError != null) {
      _showErrorSnackBar(_timeValidationError!);
      return;
    }

    final reservationProvider = context.read<ReservationProvider>();
    if (!reservationProvider.isTableAvailable(
      tableId: widget.table.id,
      fromTime: _fromTime!,
      toTime: _toTime!,
    )) {
      _showErrorSnackBar(AppStrings.reservations.tableAlreadyReserved);
      return;
    }

    final advanceAmount =
        double.tryParse(_advanceAmountController.text) ?? _minAdvanceAmount;
    final remainingAmount = _calculatedPrice - advanceAmount;
    final billNumber = ReservationBillService.generateBillNumber();

    final reservation = Reservation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      tableId: widget.table.id,
      tableName: widget.table.name,
      customerName: _customerNameController.text.trim(),
      customerPhone: _customerPhoneController.text.trim(),
      persons: int.parse(_personsController.text),
      fromTime: _fromTime!,
      toTime: _toTime!,
      occasion: _selectedOccasion,
      specialNotes:
          _specialNotesController.text.trim().isEmpty
              ? null
              : _specialNotesController.text.trim(),
      basePrice: _calculatedPrice,
      finalPrice: _calculatedPrice,
      advanceAmount: advanceAmount,
      remainingAmount: remainingAmount,
      decoration: _decoration,
      createdAt: DateTime.now(),
      billNumber: billNumber,
    );

    final success = await reservationProvider.addReservation(reservation);
    if (success) {
      await _triggerHapticFeedback();
      widget.onReservationConfirmed?.call(reservation);
      if (mounted) {
        // Generate and show advance bill
        await _generateAndShowAdvanceBill(reservation);
      }
    } else {
      _showErrorSnackBar(AppStrings.reservations.failedToCreateReservation);
    }
  }

  // Updated method for generating and showing advance bill with PDF
  Future<void> _generateAndShowAdvanceBill(Reservation reservation) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(AppStrings.reservations.generatingPdfBill),
                ],
              ),
            ),
      );

      // Generate PDF bill file
      final pdfFile = await ReservationBillService.generateAdvanceBillPDF(
        reservation,
      );

      // Wait a bit for UX
      await Future.delayed(const Duration(seconds: 1));

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show success dialog with automatic sharing
      if (mounted) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Reservation Confirmed!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Table: ${reservation.tableName}\nAdvance: ${CurrencyConstants.symbol}${reservation.advanceAmount.toStringAsFixed(0)}\nBill: ${reservation.billNumber}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await _triggerHapticFeedback();
                              if (!context.mounted) return;
                              Navigator.pop(context); // Close dialog first
                              await _shareToWhatsAppAutomatically(
                                reservation,
                                pdfFile,
                              );
                            },
                            icon: const Icon(Icons.share, size: 18),
                            label: Text(AppStrings.reservations.shareBill),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.green,
                              side: const BorderSide(color: Colors.green),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context); // Close dialog
                              Navigator.pop(context); // Go back to tables
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text(AppStrings.done),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _showErrorSnackBar('Failed to generate bill: $e');
      }
    }
  }

  // New method for automatic WhatsApp sharing
  Future<void> _shareToWhatsAppAutomatically(
    Reservation reservation,
    File pdfFile,
  ) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(AppStrings.reservations.sharingBillToWhatsApp),
                ],
              ),
            ),
      );

      // Wait a moment
      await Future.delayed(const Duration(seconds: 1));

      // Close loading
      if (mounted) Navigator.pop(context);

      // Share to WhatsApp
      final success =
          await ReservationBillService.shareToSpecificWhatsAppNumber(
            reservation,
            pdfFile,
          );

      if (mounted) {
        if (success) {
          // Removed green SnackBar: bill shared success message (was green)
        } else {
          // Fallback: Open share dialog
          await ReservationBillService.shareAdvanceBillToWhatsApp(
            reservation,
            pdfFile,
          );

          if (!mounted) return;

          AppSnackBar.showWarning(
            context,
            AppStrings.reservations.selectWhatsApp,
            duration: const Duration(seconds: 3),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog if open
        _showErrorSnackBar('Error sharing bill: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    AppSnackBar.showError(context, message);
  }

  @override
  void dispose() {
    _personsController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _specialNotesController.dispose();
    _advanceAmountController.dispose();
    super.dispose();
  }
}
