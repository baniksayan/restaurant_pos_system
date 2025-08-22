import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../services/pdf_service.dart';
import '../../payment/payment_page.dart';

class BillSuccessDialog extends StatelessWidget {
  final String orderNumber;
  final double total;
  final String? customerPhone;
  final dynamic billBytes;
  final VoidCallback onBillGenerated;

  const BillSuccessDialog({
    super.key,
    required this.orderNumber,
    required this.total,
    required this.customerPhone,
    required this.billBytes,
    required this.onBillGenerated,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 24),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Bill Generated!',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Order #$orderNumber bill ready'),
            const SizedBox(height: 8),
            Text('Total: ₹${total.toStringAsFixed(2)}'),
            if (customerPhone?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Ready to send to:',
                      style: TextStyle(fontSize: 12),
                    ),
                    Text(
                      customerPhone!,
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (customerPhone?.isNotEmpty == true)
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _sendToWhatsApp(context);
                  },
                  icon: const Icon(Icons.message, color: Colors.green),
                  label: const Text('Send via WhatsApp'),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      await PDFService.sharePDF(
                        billBytes,
                        'Bill_$orderNumber',
                      );
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _navigateToPayment(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    child: const Text(
                      'Proceed to Pay',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _sendToWhatsApp(BuildContext context) async {
    try {
      await PDFService.sharePDF(billBytes, 'Bill_$orderNumber');
      final cleanPhone = customerPhone!
          .replaceAll('+', '')
          .replaceAll(' ', '');
      final message =
          'Hello! Your restaurant bill for Order #$orderNumber is ready. Total: ₹${total.toStringAsFixed(2)}';
      final whatsappUrl =
          'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}';

      if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
        await launchUrl(
          Uri.parse(whatsappUrl),
          mode: LaunchMode.externalApplication,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bill shared to $customerPhone via WhatsApp!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        await PDFService.sharePDF(billBytes, 'Bill_$orderNumber');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'WhatsApp not available. Bill shared via other apps.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing bill: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToPayment(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentPage(
          orderNumber: orderNumber,
          totalAmount: total,
          onPaymentCompleted: () {
            onBillGenerated();
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
      ),
    );
  }
}
