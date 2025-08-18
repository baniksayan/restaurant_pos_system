// lib/presentation/views/payment/payment_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import 'package:qr_flutter/qr_flutter.dart';

class PaymentPage extends StatefulWidget {
  final String orderNumber;
  final double totalAmount;
  final VoidCallback onPaymentCompleted;

  const PaymentPage({
    super.key,
    required this.orderNumber,
    required this.totalAmount,
    required this.onPaymentCompleted,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String _selectedPaymentMethod = 'cash';
  bool _processing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Payment - Order #${widget.orderNumber}'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildAmountCard(),
            const SizedBox(height: 20),
            _buildPaymentMethodsCard(),
            const SizedBox(height: 20),
            if (_selectedPaymentMethod == 'upi' || _selectedPaymentMethod == 'card')
              _buildQRCodeCard(),
            const SizedBox(height: 30),
            _buildProcessPaymentButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.payment, color: Colors.white, size: 40),
          const SizedBox(height: 12),
          const Text(
            'Total Amount',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          Text(
            '₹${widget.totalAmount.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
            'Payment Method',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildPaymentOption('cash', 'Cash', Icons.money, Colors.green),
          _buildPaymentOption('card', 'Card', Icons.credit_card, Colors.blue),
          _buildPaymentOption('upi', 'UPI', Icons.account_balance_wallet, Colors.purple),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(String value, String title, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: RadioListTile<String>(
        value: value,
        groupValue: _selectedPaymentMethod,
        onChanged: (newValue) {
          setState(() => _selectedPaymentMethod = newValue!);
          _triggerHapticFeedback();
        },
        title: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Text(title),
          ],
        ),
        activeColor: color,
      ),
    );
  }

  Widget _buildQRCodeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        children: [
          Text(
            'Scan QR Code to Pay',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: QrImageView(
              data: 'upi://pay?pa=restaurant@upi&pn=WiZARD Restaurant&am=${widget.totalAmount}&cu=INR&tn=Order ${widget.orderNumber}',
              version: QrVersions.auto,
              size: 200.0,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Amount: ₹${widget.totalAmount.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessPaymentButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _processing ? null : _processPayment,
        icon: _processing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.check_circle, size: 20),
        label: Text(
          _processing ? 'Processing Payment...' : 'Payment Received',
          style: const TextStyle(fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Future<void> _processPayment() async {
    await _triggerHapticFeedback();
    setState(() => _processing = true);

    // Simulate payment processing
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _processing = false);

    // Show success dialog
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text('Payment Successful!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Order #${widget.orderNumber} payment completed'),
            Text('Amount: ₹${widget.totalAmount.toStringAsFixed(2)}'),
            Text('Method: ${_selectedPaymentMethod.toUpperCase()}'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onPaymentCompleted();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Done', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _triggerHapticFeedback() async {
    try {
      if (await Vibration.hasVibrator() ?? false) {
        await Vibration.vibrate(duration: 50);
      }
      await HapticFeedback.lightImpact();
    } catch (e) {
      await HapticFeedback.lightImpact();
    }
  }
}
