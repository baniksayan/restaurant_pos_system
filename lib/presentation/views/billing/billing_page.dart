import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/haptic_helper.dart';
import '../../view_models/providers/billing_provider.dart';
import 'widgets/order_summary_card.dart';
import 'widgets/items_list_card.dart';
import 'widgets/bill_details_card.dart';
import 'widgets/customer_phone_card.dart';
import 'widgets/bill_success_dialog.dart';

class BillingPage extends StatefulWidget {
  final String orderNumber;
  final List cartItems;
  final VoidCallback onBillGenerated;

  const BillingPage({
    super.key,
    required this.orderNumber,
    required this.cartItems,
    required this.onBillGenerated,
  });

  @override
  State<BillingPage> createState() => _BillingPageState();
}

class _BillingPageState extends State<BillingPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BillingProvider(),
      child: Consumer<BillingProvider>(
        builder: (context, billingProvider, child) {
          final subtotal = billingProvider.calculateSubtotal(widget.cartItems);
          final gstAmount = billingProvider.calculateGST(subtotal);
          final total = billingProvider.calculateTotal(subtotal, gstAmount);

          return Scaffold(
            backgroundColor: Colors.grey[50],
            appBar: AppBar(
              title: Text('Generate Bill - Order #${widget.orderNumber}'),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () async {
                  await HapticHelper.triggerFeedback();
                  Navigator.pop(context);
                },
              ),
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      OrderSummaryCard(
                        orderNumber: widget.orderNumber,
                        cartItems: widget.cartItems,
                      ),
                      const SizedBox(height: 20),
                      ItemsListCard(cartItems: widget.cartItems),
                      const SizedBox(height: 20),
                      BillDetailsCard(
                        subtotal: subtotal,
                        gstAmount: gstAmount,
                        total: total,
                      ),
                      const SizedBox(height: 20),
                      CustomerPhoneCard(
                        phoneController: _phoneController,
                        formKey: _formKey,
                      ),
                      const SizedBox(height: 30),
                      _buildGenerateBillButton(
                        billingProvider,
                        subtotal,
                        gstAmount,
                        total,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGenerateBillButton(
    BillingProvider billingProvider,
    double subtotal,
    double gstAmount,
    double total,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: billingProvider.isGenerating
            ? null
            : () => _handleGenerateAndSend(
                  billingProvider,
                  subtotal,
                  gstAmount,
                  total,
                ),
        icon: billingProvider.isGenerating
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.receipt_long, size: 20),
        label: Text(
          billingProvider.isGenerating
              ? 'Generating Bill...'
              : (billingProvider.customerPhone?.isNotEmpty == true
                  ? 'Generate & Send Bill'
                  : 'Generate Bill'),
          style: const TextStyle(fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 2,
        ),
      ),
    );
  }

  Future<void> _handleGenerateAndSend(
    BillingProvider billingProvider,
    double subtotal,
    double gstAmount,
    double total,
  ) async {
    if (!_formKey.currentState!.validate()) return;

    await HapticHelper.triggerFeedback();

    try {
      final billBytes = await billingProvider.generateBill(
        cartItems: widget.cartItems,
        orderNumber: widget.orderNumber,
        subtotal: subtotal,
        gstAmount: gstAmount,
        total: total,
      );

      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) => BillSuccessDialog(
            orderNumber: widget.orderNumber,
            total: total,
            customerPhone: billingProvider.customerPhone,
            billBytes: billBytes,
            onBillGenerated: widget.onBillGenerated,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(billingProvider.errorMessage ?? 'Error generating bill'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
