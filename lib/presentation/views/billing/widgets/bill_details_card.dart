import 'package:flutter/material.dart';

class BillDetailsCard extends StatelessWidget {
  final double subtotal;
  final double gstAmount;
  final double total;

  const BillDetailsCard({
    super.key,
    required this.subtotal,
    required this.gstAmount,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
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
            'Bill Amount',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildAmountRow('Subtotal:', '₹${subtotal.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          _buildAmountRow('GST (18%):', '₹${gstAmount.toStringAsFixed(2)}'),
          const SizedBox(height: 12),
          const Divider(thickness: 1),
          const SizedBox(height: 8),
          _buildAmountRow(
            'Total Amount:',
            '₹${total.toStringAsFixed(2)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAmountRow(String label, String amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: FontWeight.bold,
            color: isTotal ? Colors.blue : Colors.black,
          ),
        ),
      ],
    );
  }
}
