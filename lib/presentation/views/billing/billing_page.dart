// // lib/presentation/views/billing/billing_page.dart
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:intl_phone_field/intl_phone_field.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:vibration/vibration.dart';
// import '../../view_models/providers/animated_cart_provider.dart';
// import '../../../services/pdf_service.dart';
// import '../../../core/themes/app_colors.dart';
// import '../payment/payment_page.dart';

// class BillingPage extends StatefulWidget {
//   final String orderNumber;
//   final List<CartItem> cartItems;
//   final VoidCallback onBillGenerated;

//   const BillingPage({
//     super.key,
//     required this.orderNumber,
//     required this.cartItems,
//     required this.onBillGenerated,
//   });

//   @override
//   State<BillingPage> createState() => _BillingPageState();
// }

// class _BillingPageState extends State<BillingPage> {
//   String? _customerPhone;
//   String _countryCode = "+91";
//   final _formKey = GlobalKey<FormState>();
//   final _phoneController = TextEditingController();
//   bool _generating = false;

//   double get subtotal {
//     return widget.cartItems.fold(
//       0.0,
//       (sum, item) => sum + (item.price * item.quantity),
//     );
//   }

//   double get gstAmount => subtotal * 0.18;
//   double get total => subtotal + gstAmount;

//   @override
//   void dispose() {
//     _phoneController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       appBar: AppBar(
//         title: Text('Generate Bill - Order #${widget.orderNumber}'),
//         backgroundColor: Colors.blue,
//         foregroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () {
//             _triggerHapticFeedback();
//             Navigator.pop(context);
//           },
//         ),
//       ),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(20),
//           child: Form(
//             key: _formKey,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 _buildOrderSummaryCard(),
//                 const SizedBox(height: 20),
//                 _buildItemsListCard(),
//                 const SizedBox(height: 20),
//                 _buildBillDetailsCard(),
//                 const SizedBox(height: 20),
//                 _buildCustomerPhoneCard(),
//                 const SizedBox(height: 30),
//                 _buildGenerateBillButton(),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildOrderSummaryCard() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             blurRadius: 10,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: Colors.blue.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: const Icon(
//                   Icons.receipt_long,
//                   color: Colors.blue,
//                   size: 28,
//                 ),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Order Summary',
//                       style: TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       'Order #${widget.orderNumber}',
//                       style: const TextStyle(color: Colors.grey, fontSize: 14),
//                     ),
//                   ],
//                 ),
//               ),
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                 decoration: BoxDecoration(
//                   color: Colors.green,
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: const Text(
//                   'KOT SENT',
//                   style: TextStyle(
//                     fontSize: 10,
//                     color: Colors.white,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           Divider(color: Colors.grey[300]),
//           const SizedBox(height: 12),
//           Row(
//             children: [
//               Expanded(
//                 child: _buildInfoItem(
//                   'Table',
//                   widget.cartItems.first.tableName,
//                 ),
//               ),
//               Expanded(
//                 child: _buildInfoItem('Items', '${widget.cartItems.length}'),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           Row(
//             children: [
//               Expanded(
//                 child: _buildInfoItem(
//                   'Date',
//                   '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
//                 ),
//               ),
//               Expanded(
//                 child: _buildInfoItem(
//                   'Time',
//                   '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildInfoItem(String label, String value) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(
//             fontSize: 12,
//             color: Colors.grey,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//         const SizedBox(height: 2),
//         Text(
//           value,
//           style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
//         ),
//       ],
//     );
//   }

//   Widget _buildItemsListCard() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             blurRadius: 10,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Order Items',
//             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 16),
//           ...widget.cartItems
//               .map(
//                 (item) => Container(
//                   margin: const EdgeInsets.only(bottom: 12),
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: Colors.grey[50],
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Row(
//                     children: [
//                       Container(
//                         width: 40,
//                         height: 40,
//                         decoration: BoxDecoration(
//                           color: Colors.orange.withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: const Icon(
//                           Icons.restaurant,
//                           color: Colors.orange,
//                           size: 20,
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               item.name,
//                               style: const TextStyle(
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 14,
//                               ),
//                             ),
//                             if (item.specialNotes != null &&
//                                 item.specialNotes!.isNotEmpty)
//                               Text(
//                                 'Note: ${item.specialNotes}',
//                                 style: const TextStyle(
//                                   fontSize: 11,
//                                   color: Colors.blue,
//                                   fontStyle: FontStyle.italic,
//                                 ),
//                               ),
//                           ],
//                         ),
//                       ),
//                       Column(
//                         crossAxisAlignment: CrossAxisAlignment.end,
//                         children: [
//                           Text(
//                             '₹${item.price.toStringAsFixed(2)} × ${item.quantity}',
//                             style: const TextStyle(fontSize: 12),
//                           ),
//                           Text(
//                             '₹${(item.price * item.quantity).toStringAsFixed(2)}',
//                             style: const TextStyle(
//                               fontWeight: FontWeight.bold,
//                               color: Colors.blue,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               )
//               .toList(),
//         ],
//       ),
//     );
//   }

//   Widget _buildBillDetailsCard() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             blurRadius: 10,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Bill Amount',
//             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 16),
//           _buildAmountRow('Subtotal:', '₹${subtotal.toStringAsFixed(2)}'),
//           const SizedBox(height: 8),
//           _buildAmountRow('GST (18%):', '₹${gstAmount.toStringAsFixed(2)}'),
//           const SizedBox(height: 12),
//           const Divider(thickness: 1),
//           const SizedBox(height: 8),
//           _buildAmountRow(
//             'Total Amount:',
//             '₹${total.toStringAsFixed(2)}',
//             isTotal: true,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildAmountRow(String label, String amount, {bool isTotal = false}) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Text(
//           label,
//           style: TextStyle(
//             fontSize: isTotal ? 16 : 14,
//             fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
//           ),
//         ),
//         Text(
//           amount,
//           style: TextStyle(
//             fontSize: isTotal ? 18 : 14,
//             fontWeight: FontWeight.bold,
//             color: isTotal ? Colors.blue : Colors.black,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildCustomerPhoneCard() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             blurRadius: 10,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Customer Details',
//             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 8),
//           const Text(
//             'Enter phone number to send e-bill (optional)',
//             style: TextStyle(fontSize: 12, color: Colors.grey),
//           ),
//           const SizedBox(height: 16),
//           IntlPhoneField(
//             controller: _phoneController,
//             initialCountryCode: 'IN',
//             decoration: const InputDecoration(
//               labelText: 'Customer Phone Number',
//               hintText: 'Enter phone number',
//               border: OutlineInputBorder(),
//               prefixIcon: Icon(Icons.phone),
//             ),
//             showCountryFlag: true,
//             showDropdownIcon: true,
//             onChanged: (phone) {
//               setState(() {
//                 _customerPhone = phone.completeNumber;
//                 _countryCode = phone.countryCode;
//               });
//             },
//             validator: (value) {
//               if (value != null &&
//                   value.number.isNotEmpty &&
//                   value.number.length < 7) {
//                 return 'Please enter a valid phone number';
//               }
//               return null;
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildGenerateBillButton() {
//     return SizedBox(
//       width: double.infinity,
//       child: ElevatedButton.icon(
//         onPressed: _generating ? null : _handleGenerateAndSend,
//         icon:
//             _generating
//                 ? const SizedBox(
//                   width: 20,
//                   height: 20,
//                   child: CircularProgressIndicator(
//                     strokeWidth: 2,
//                     color: Colors.white,
//                   ),
//                 )
//                 : const Icon(Icons.receipt_long, size: 20),
//         label: Text(
//           _generating
//               ? 'Generating Bill...'
//               : (_customerPhone?.isNotEmpty == true
//                   ? 'Generate & Send Bill'
//                   : 'Generate Bill'),
//           style: const TextStyle(fontSize: 16),
//         ),
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Colors.blue,
//           foregroundColor: Colors.white,
//           padding: const EdgeInsets.symmetric(vertical: 16),
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//           elevation: 2,
//         ),
//       ),
//     );
//   }

//   Future<void> _handleGenerateAndSend() async {
//     if (!_formKey.currentState!.validate()) return;

//     await _triggerHapticFeedback();
//     setState(() => _generating = true);

//     try {
//       final billBytes = await PDFService.generateCustomerBill(
//         items: widget.cartItems,
//         tableId: widget.cartItems.first.tableId,
//         tableName: widget.cartItems.first.tableName,
//         orderNumber: widget.orderNumber,
//         orderTime: DateTime.now(),
//         subtotal: subtotal,
//         gstAmount: gstAmount,
//         total: total,
//       );

//       await _showBillGeneratedDialog(billBytes);
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error generating bill: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     } finally {
//       if (mounted) setState(() => _generating = false);
//     }
//   }

//   // |  FIX 1: Responsive Dialog Layout
//   Future<void> _showBillGeneratedDialog(dynamic billBytes) async {
//     await showDialog(
//       context: context,
//       barrierDismissible: true, // |  FIX 2: Allow closing by tapping outside
//       builder:
//           (context) => AlertDialog(
//             title: const Row(
//               children: [
//                 Icon(Icons.check_circle, color: Colors.green, size: 24),
//                 SizedBox(width: 8),
//                 Expanded(
//                   child: Text(
//                     'Bill Generated!',
//                     style: TextStyle(fontSize: 18),
//                   ),
//                 ),
//               ],
//             ),
//             content: SingleChildScrollView(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Text('Order #${widget.orderNumber} bill ready'),
//                   const SizedBox(height: 8),
//                   Text('Total: ₹${total.toStringAsFixed(2)}'),
//                   if (_customerPhone?.isNotEmpty == true) ...[
//                     const SizedBox(height: 12),
//                     Container(
//                       padding: const EdgeInsets.all(8),
//                       decoration: BoxDecoration(
//                         color: Colors.blue.withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: Column(
//                         children: [
//                           Text(
//                             'Ready to send to:',
//                             style: const TextStyle(fontSize: 12),
//                           ),
//                           Text(
//                             _customerPhone!,
//                             style: const TextStyle(
//                               color: Colors.blue,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//             actions: [
//               // |  FIX 1: Responsive Action Layout
//               Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   if (_customerPhone?.isNotEmpty == true)
//                     SizedBox(
//                       width: double.infinity,
//                       child: TextButton.icon(
//                         onPressed: () async {
//                           Navigator.pop(context);
//                           await _sendToWhatsApp(billBytes);
//                         },
//                         icon: const Icon(Icons.message, color: Colors.green),
//                         label: const Text('Send via WhatsApp'),
//                       ),
//                     ),
//                   Row(
//                     children: [
//                       Expanded(
//                         child: TextButton.icon(
//                           onPressed: () async {
//                             Navigator.pop(context);
//                             await PDFService.sharePDF(
//                               billBytes,
//                               'Bill_${widget.orderNumber}',
//                             );
//                           },
//                           icon: const Icon(Icons.share),
//                           label: const Text('Share'),
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                       Expanded(
//                         child: ElevatedButton(
//                           onPressed: () {
//                             Navigator.pop(context);
//                             _navigateToPayment();
//                           },
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.blue,
//                           ),
//                           child: const Text(
//                             'Proceed to Pay',
//                             style: TextStyle(color: Colors.white),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ],
//           ),
//     );
//   }

//   // |  FIX 2: WhatsApp Integration
//   Future<void> _sendToWhatsApp(dynamic billBytes) async {
//     try {
//       await PDFService.sharePDF(billBytes, 'Bill_${widget.orderNumber}');

//       final cleanPhone = _customerPhone!
//           .replaceAll('+', '')
//           .replaceAll(' ', '');
//       final message =
//           'Hello! Your restaurant bill for Order #${widget.orderNumber} is ready. Total: ₹${total.toStringAsFixed(2)}';
//       final whatsappUrl =
//           'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}';

//       if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
//         await launchUrl(
//           Uri.parse(whatsappUrl),
//           mode: LaunchMode.externalApplication,
//         );

//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Bill shared to $_customerPhone via WhatsApp!'),
//             backgroundColor: Colors.green,
//           ),
//         );
//       } else {
//         // |  FIX 2: Fallback for WhatsApp not available
//         await PDFService.sharePDF(billBytes, 'Bill_${widget.orderNumber}');
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text(
//               'WhatsApp not available. Bill shared via other apps.',
//             ),
//             backgroundColor: Colors.orange,
//           ),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error sharing bill: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   // |  FIX 5: Navigate to Payment Page
//   void _navigateToPayment() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder:
//             (context) => PaymentPage(
//               orderNumber: widget.orderNumber,
//               totalAmount: total,
//               onPaymentCompleted: () {
//                 // After payment is completed, call the callback and go back
//                 widget.onBillGenerated();
//                 Navigator.of(context).popUntil((route) => route.isFirst);
//               },
//             ),
//       ),
//     );
//   }

//   Future<void> _triggerHapticFeedback() async {
//     try {
//       if (await Vibration.hasVibrator() ?? false) {
//         await Vibration.vibrate(duration: 50);
//       }
//       await HapticFeedback.lightImpact();
//     } catch (e) {
//       await HapticFeedback.lightImpact();
//     }
//   }
// }
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
