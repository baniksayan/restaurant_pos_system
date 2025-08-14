// lib/presentation/views/reservations/table_reservation_view.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 👈 ADD this import for HapticFeedback
import 'package:restaurant_pos_system/data/models/restaurant_table.dart';
import 'package:restaurant_pos_system/data/models/table.dart';
import 'package:vibration/vibration.dart';

class TableReservationView extends StatefulWidget {
  final RestaurantTable table;
  final Function(ReservationDetails) onReservationConfirmed;

  const TableReservationView({
    Key? key,
    required this.table,
    required this.onReservationConfirmed,
  }) : super(key: key);

  @override
  State<TableReservationView> createState() => _TableReservationViewState();
}

class _TableReservationViewState extends State<TableReservationView> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay.now().replacing(hour: TimeOfDay.now().hour + 2);
  int _guestCount = 2;
  String _selectedOccasion = 'Dining';
  bool _includeDecoration = false;
  bool _advanceOrder = false;
  double _calculatedAmount = 0.0;

  final List<String> _occasions = [
    'Dining',
    'Birthday Party',
    'Anniversary',
    'Business Meeting',
    'Family Gathering',
    'Date Night',
    'Celebration',
    'Corporate Event',
  ];

  final List<String> _decorationOptions = [
    'Birthday Decoration (₹500)',
    'Anniversary Setup (₹800)',
    'Business Setup (₹300)',
    'Premium Decoration (₹1200)',
  ];

  @override
  void initState() {
    super.initState();
    _calculateAmount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Reserve ${widget.table.name}'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey[300],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTableInfoCard(),
            const SizedBox(height: 16),
            _buildDateTimeSection(),
            const SizedBox(height: 16),
            _buildGuestDetailsSection(),
            const SizedBox(height: 16),
            _buildOccasionSection(),
            const SizedBox(height: 16),
            _buildExtrasSection(),
            const SizedBox(height: 16),
            _buildPricingCard(),
          ],
        ),
      ),
      bottomNavigationBar: _buildReservationFooter(),
    );
  }

  Widget _buildTableInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
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
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.table_restaurant,
              color: Colors.blue,
              size: 30,
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
                  ),
                ),
                Text(
                  'Capacity: ${widget.table.capacity} persons',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'AVAILABLE',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Date & Time',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Date selection
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today, color: Colors.blue),
            title: const Text('Select Date'),
            subtitle: Text(
              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _selectDate,
          ),
          
          const Divider(),
          
          // Time selection
          Row(
            children: [
              Expanded(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.access_time, color: Colors.green),
                  title: const Text('Start Time'),
                  subtitle: Text(
                    _startTime.format(context),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () => _selectTime(true),
                ),
              ),
              Expanded(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.access_time_filled, color: Colors.red),
                  title: const Text('End Time'),
                  subtitle: Text(
                    _endTime.format(context),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () => _selectTime(false),
                ),
              ),
            ],
          ),
          
          // Time validation warning
          if (_getReservationDuration() < 2) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.amber, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Minimum 2 hours reservation required',
                    style: TextStyle(color: Colors.amber, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGuestDetailsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Guest Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              const Icon(Icons.group, color: Colors.purple),
              const SizedBox(width: 12),
              const Text('Number of Guests:'),
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: _guestCount > 1 ? () => setState(() => _guestCount--) : null,
                      icon: const Icon(Icons.remove, size: 18),
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                    Text(
                      '$_guestCount',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      onPressed: _guestCount < widget.table.capacity 
                          ? () => setState(() => _guestCount++) 
                          : null,
                      icon: const Icon(Icons.add, size: 18),
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          if (_guestCount > widget.table.capacity) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Guest count exceeds table capacity (${widget.table.capacity})',
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOccasionSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Occasion',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          DropdownButtonFormField<String>(
            value: _selectedOccasion,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.celebration),
            ),
            items: _occasions.map((occasion) => DropdownMenuItem(
              value: occasion,
              child: Text(occasion),
            )).toList(),
            onChanged: (value) {
              setState(() {
                _selectedOccasion = value!;
                _calculateAmount();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExtrasSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Extras',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          CheckboxListTile(
            title: const Text('Table Decoration'),
            subtitle: const Text('Special decoration for your occasion'),
            value: _includeDecoration,
            onChanged: (value) {
              setState(() {
                _includeDecoration = value!;
                _calculateAmount();
              });
            },
            secondary: const Icon(Icons.auto_awesome, color: Colors.pink),
          ),
          
          CheckboxListTile(
            title: const Text('Advance Food Order'),
            subtitle: const Text('Pre-order your meals'),
            value: _advanceOrder,
            onChanged: (value) {
              setState(() {
                _advanceOrder = value!;
              });
            },
            secondary: const Icon(Icons.restaurant_menu, color: Colors.orange),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pricing Breakdown',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          _buildPriceRow('Base Reservation', _getBasePrice()),
          _buildPriceRow('Duration (${_getReservationDuration()}h)', _getDurationPrice()),
          _buildPriceRow('Occasion Premium', _getOccasionPrice()),
          if (_includeDecoration) _buildPriceRow('Decoration', _getDecorationPrice()),
          
          const Divider(),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '₹${_calculatedAmount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          const Text(
            '* No GST applicable on table reservations',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text('₹${amount.toStringAsFixed(0)}'),
        ],
      ),
    );
  }

  Widget _buildReservationFooter() {
    final isValid = _isReservationValid();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isValid) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.error, color: Colors.red, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Please fix the errors above to proceed',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: isValid ? _confirmReservation : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Confirm Reservation',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          
          if (_advanceOrder) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: isValid ? _proceedToMenu : null,
              icon: const Icon(Icons.restaurant_menu),
              label: const Text('Order Food in Advance'),
            ),
          ],
        ],
      ),
    );
  }

  // Helper methods
  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _calculateAmount();
      });
    }
  }

  void _selectTime(bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
          // Auto-adjust end time to minimum 2 hours later
          final endHour = picked.hour + 2;
          _endTime = TimeOfDay(
            hour: endHour > 23 ? 23 : endHour,
            minute: picked.minute,
          );
        } else {
          _endTime = picked;
        }
        _calculateAmount();
      });
    }
  }

  double _getReservationDuration() {
    final start = _startTime.hour + _startTime.minute / 60.0;
    final end = _endTime.hour + _endTime.minute / 60.0;
    return end > start ? end - start : 0;
  }

  bool _isReservationValid() {
    final now = DateTime.now();
    final reservationDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );
    
    // Must be at least 2 hours from now
    final twoHoursFromNow = now.add(const Duration(hours: 2));
    
    return _getReservationDuration() >= 2 &&
           _guestCount <= widget.table.capacity &&
           _guestCount > 0 &&
           reservationDateTime.isAfter(twoHoursFromNow);
  }

  void _calculateAmount() {
    double total = 0;
    
    total += _getBasePrice();
    total += _getDurationPrice();
    total += _getOccasionPrice();
    if (_includeDecoration) total += _getDecorationPrice();
    
    setState(() {
      _calculatedAmount = total;
    });
  }

  double _getBasePrice() {
    // Base price based on time of day
    final hour = _startTime.hour;
    if (hour >= 6 && hour < 12) return 200; // Morning
    if (hour >= 12 && hour < 17) return 300; // Afternoon
    return 400; // Evening/Night
  }

  double _getDurationPrice() {
    return _getReservationDuration() * 100; // ₹100 per hour
  }

  double _getOccasionPrice() {
    switch (_selectedOccasion) {
      case 'Birthday Party':
      case 'Anniversary':
        return 200;
      case 'Corporate Event':
      case 'Business Meeting':
        return 300;
      case 'Celebration':
        return 150;
      default:
        return 0;
    }
  }

  double _getDecorationPrice() {
    switch (_selectedOccasion) {
      case 'Birthday Party':
        return 500;
      case 'Anniversary':
        return 800;
      case 'Corporate Event':
      case 'Business Meeting':
        return 300;
      default:
        return 400;
    }
  }

  void _confirmReservation() async {
    await _triggerHapticFeedback();
    
    final reservation = ReservationDetails(
      tableId: widget.table.id,
      tableName: widget.table.name,
      date: _selectedDate,
      startTime: _startTime,
      endTime: _endTime,
      guestCount: _guestCount,
      occasion: _selectedOccasion,
      includeDecoration: _includeDecoration,
      totalAmount: _calculatedAmount,
    );
    
    widget.onReservationConfirmed(reservation);
    Navigator.pop(context);
  }

  void _proceedToMenu() {
    // TODO: Navigate to menu for advance ordering
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Proceeding to menu for advance ordering...'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  // 👈 FIX: Properly implement haptic feedback method with HapticFeedback import
  Future<void> _triggerHapticFeedback() async {
    try {
      // Try vibration first
      if (await Vibration.hasVibrator() ?? false) {
        await Vibration.vibrate(duration: 100, amplitude: 128);
      }
      // Fallback to system haptic
      await HapticFeedback.lightImpact(); // 👈 NOW this will work
    } catch (e) {
      // Fallback to system haptic only
      await HapticFeedback.lightImpact();
    }
  }
}

// Models
class ReservationDetails {
  final String tableId;
  final String tableName;
  final DateTime date;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final int guestCount;
  final String occasion;
  final bool includeDecoration;
  final double totalAmount;

  ReservationDetails({
    required this.tableId,
    required this.tableName,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.guestCount,
    required this.occasion,
    required this.includeDecoration,
    required this.totalAmount,
  });
}
