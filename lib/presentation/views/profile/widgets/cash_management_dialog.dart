// lib/presentation/views/profile/widgets/cash_management_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/themes/app_colors.dart';

class CashManagementDialog extends StatefulWidget {
  const CashManagementDialog({super.key});

  @override
  State<CashManagementDialog> createState() => _CashManagementDialogState();
}

class _CashManagementDialogState extends State<CashManagementDialog> {
  final _openingBalanceController = TextEditingController();
  final _cashInController = TextEditingController();
  final _cashOutController = TextEditingController();

  // Mock data - in real app, this would come from your backend
  double _totalSales = 15240.0;
  double _totalReservations = 3500.0;
  double _totalExpenses = 2100.0;
  double _openingBalance = 5000.0;

  @override
  void initState() {
    super.initState();
    _openingBalanceController.text = _openingBalance.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _openingBalanceController.dispose();
    _cashInController.dispose();
    _cashOutController.dispose();
    super.dispose();
  }

  double get _calculatedClosingBalance {
    final cashIn = double.tryParse(_cashInController.text) ?? 0.0;
    final cashOut = double.tryParse(_cashOutController.text) ?? 0.0;
    return _openingBalance +
        _totalSales +
        _totalReservations +
        cashIn -
        _totalExpenses -
        cashOut;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxHeight: 700, maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header - Fixed the first overflow here
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.green,
                    size: 20, // Reduced size
                  ),
                ),
                const SizedBox(width: 8), // Reduced spacing
                const Expanded(
                  // Fixed: Wrapped with Expanded
                  child: Text(
                    'Daily Cash Management',
                    style: TextStyle(
                      fontSize: 18, // Reduced font size
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis, // Added overflow handling
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 20), // Reduced size
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Today's Summary
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade50, Colors.blue.shade100],
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
                            'Today\'s Summary',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildSummaryRow(
                            'Total Sales:',
                            _totalSales,
                            Colors.green,
                          ),
                          const SizedBox(height: 6),
                          _buildSummaryRow(
                            'Reservation Advances:',
                            _totalReservations,
                            Colors.blue,
                          ),
                          const SizedBox(height: 6),
                          _buildSummaryRow(
                            'Total Expenses:',
                            _totalExpenses,
                            Colors.red,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Manual Entries
                    const Text(
                      'Cash Flow Management',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Opening Balance
                    TextFormField(
                      controller: _openingBalanceController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: 'Opening Balance',
                        prefixIcon: const Icon(Icons.account_balance, size: 20),
                        prefixText: '₹',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _openingBalance = double.tryParse(value) ?? 0.0;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // Cash In
                    TextFormField(
                      controller: _cashInController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: 'Additional Cash In',
                        prefixIcon: const Icon(
                          Icons.add_circle,
                          color: Colors.green,
                          size: 20,
                        ),
                        prefixText: '₹',
                        hintText: 'Other receipts, loans, etc.',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),

                    const SizedBox(height: 16),

                    // Cash Out
                    TextFormField(
                      controller: _cashOutController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: 'Additional Cash Out',
                        prefixIcon: const Icon(
                          Icons.remove_circle,
                          color: Colors.red,
                          size: 20,
                        ),
                        prefixText: '₹',
                        hintText: 'Withdrawals, petty cash, etc.',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),

                    const SizedBox(height: 20),

                    // Closing Balance - Fixed the second overflow here
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green.shade50, Colors.green.shade100],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        // Changed from Row to Column for better space management
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'Expected Closing Balance',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '₹${_calculatedClosingBalance.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontSize: 14)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveCashManagement,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Save & Close Day',
                      style: TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
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

  // Helper method to build summary rows with proper constraints
  Widget _buildSummaryRow(String label, double amount, Color color) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          flex: 1,
          child: Text(
            '₹${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: color,
              fontSize: 14,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _saveCashManagement() {
    // Here you would save the cash management data to your backend
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Daily cash management saved successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
