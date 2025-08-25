// import 'package:flutter/material.dart';
// import '../../../../../core/themes/app_colors.dart';
// import '../../../../../core/utils/haptic_helper.dart';

// class CartFooter extends StatelessWidget {
//   final double subtotal;
//   final bool kotGenerated;
//   final VoidCallback onGenerateKOT;
//   final VoidCallback onSendToKitchen;
//   final VoidCallback onGenerateBill;
//   final VoidCallback onShowGSTInfo;

//   const CartFooter({
//     super.key,
//     required this.subtotal,
//     required this.kotGenerated,
//     required this.onGenerateKOT,
//     required this.onSendToKitchen,
//     required this.onGenerateBill,
//     required this.onShowGSTInfo,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final gstAmount = subtotal * 0.18;
//     final total = subtotal + gstAmount;

//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: const BoxDecoration(
//         color: Colors.white,
//         border: Border(top: BorderSide(color: AppColors.cardShadow, width: 1)),
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           GestureDetector(
//             onTap: () async {
//               await HapticHelper.triggerFeedback();
//               onShowGSTInfo();
//             },
//             child: Container(
//               padding: const EdgeInsets.all(12),
//               margin: const EdgeInsets.only(bottom: 12),
//               decoration: BoxDecoration(
//                 color: Colors.blue.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(color: Colors.blue.withOpacity(0.3)),
//               ),
//               child: Row(
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.all(4),
//                     decoration: BoxDecoration(
//                       color: Colors.blue,
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: const Icon(
//                       Icons.info,
//                       color: Colors.white,
//                       size: 14,
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: Text(
//                       'Restaurant GST: 18% (Pre-defined) - Tap for info',
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: Colors.blue[700],
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           _buildPriceRow("Subtotal:", "₹${subtotal.toStringAsFixed(2)}"),
//           const SizedBox(height: 8),
//           _buildPriceRow("GST (18%):", "₹${gstAmount.toStringAsFixed(2)}"),
//           const SizedBox(height: 12),
//           const Divider(thickness: 2),
//           const SizedBox(height: 8),
//           _buildPriceRow(
//             "TOTAL AMOUNT:",
//             "₹${total.toStringAsFixed(2)}",
//             isTotal: true,
//           ),
//           const SizedBox(height: 20),
//           if (!kotGenerated)
//             _buildPreKOTButtons()
//           else
//             _buildPostKOTButtons(),
//         ],
//       ),
//     );
//   }

//   Widget _buildPriceRow(String label, String value, {bool isTotal = false}) {
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
//           value,
//           style: TextStyle(
//             fontSize: isTotal ? 18 : 14,
//             fontWeight: FontWeight.bold,
//             color: isTotal ? AppColors.primary : Colors.black,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildPreKOTButtons() {
//     return SizedBox(
//       width: double.infinity,
//       child: ElevatedButton.icon(
//         onPressed: () async {
//           await HapticHelper.triggerFeedback();
//           onGenerateKOT();
//         },
//         icon: const Icon(Icons.print, size: 20),
//         label: const Text('Generate KOT'),
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Colors.green,
//           foregroundColor: Colors.white,
//           padding: const EdgeInsets.symmetric(vertical: 16),
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//         ),
//       ),
//     );
//   }

//   Widget _buildPostKOTButtons() {
//     return Row(
//       children: [
//         Expanded(
//           child: OutlinedButton.icon(
//             onPressed: () async {
//               await HapticHelper.triggerFeedback();
//               onSendToKitchen();
//             },
//             icon: const Icon(Icons.kitchen, size: 20),
//             label: const Text('Send to Kitchen'),
//             style: OutlinedButton.styleFrom(
//               padding: const EdgeInsets.symmetric(vertical: 12),
//               side: const BorderSide(color: Colors.orange),
//               foregroundColor: Colors.orange,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//             ),
//           ),
//         ),
//         const SizedBox(width: 12),
//         Expanded(
//           child: ElevatedButton.icon(
//             onPressed: () async {
//               await HapticHelper.triggerFeedback();
//               onGenerateBill();
//             },
//             icon: const Icon(Icons.receipt_long, size: 20),
//             label: const Text('Generate Bill'),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: AppColors.primary,
//               foregroundColor: Colors.white,
//               padding: const EdgeInsets.symmetric(vertical: 12),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/themes/app_colors.dart';
import '../../../../../core/utils/haptic_helper.dart';
import '../../../../../presentation/view_models/providers/tax_provider.dart';

class CartFooter extends StatelessWidget {
  final double subtotal;
  final bool kotGenerated;
  final VoidCallback onGenerateKOT;
  final VoidCallback onSendToKitchen;
  final VoidCallback onGenerateBill;
  final VoidCallback onShowGSTInfo;

  const CartFooter({
    super.key,
    required this.subtotal,
    required this.kotGenerated,
    required this.onGenerateKOT,
    required this.onSendToKitchen,
    required this.onGenerateBill,
    required this.onShowGSTInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<TaxProvider>(
      builder: (context, taxProvider, child) {
        final gstPercentage = taxProvider.totalGstPercentage;
        final gstAmount = taxProvider.calculateGstAmount(subtotal);
        final total = subtotal + gstAmount;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: AppColors.cardShadow, width: 1),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () async {
                  await HapticHelper.triggerFeedback();
                  onShowGSTInfo();
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.info,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Restaurant GST: ${gstPercentage.toStringAsFixed(1)}% ${taxProvider.hasTaxData ? "(Dynamic)" : "(Default)"} - Tap for info',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _buildPriceRow("Subtotal:", "₹${subtotal.toStringAsFixed(2)}"),
              const SizedBox(height: 8),
              _buildPriceRow(
                "GST (${gstPercentage.toStringAsFixed(1)}%):",
                "₹${gstAmount.toStringAsFixed(2)}",
              ),
              const SizedBox(height: 12),
              const Divider(thickness: 2),
              const SizedBox(height: 8),
              _buildPriceRow(
                "TOTAL AMOUNT:",
                "₹${total.toStringAsFixed(2)}",
                isTotal: true,
              ),
              const SizedBox(height: 20),
              if (!kotGenerated)
                _buildPreKOTButtons()
              else
                _buildPostKOTButtons(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isTotal = false}) {
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
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: FontWeight.bold,
            color: isTotal ? AppColors.primary : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildPreKOTButtons() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          await HapticHelper.triggerFeedback();
          onGenerateKOT();
        },
        icon: const Icon(Icons.print, size: 20),
        label: const Text('Generate KOT'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildPostKOTButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              await HapticHelper.triggerFeedback();
              onSendToKitchen();
            },
            icon: const Icon(Icons.kitchen, size: 20),
            label: const Text('Send to Kitchen'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: const BorderSide(color: Colors.orange),
              foregroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () async {
              await HapticHelper.triggerFeedback();
              onGenerateBill();
            },
            icon: const Icon(Icons.receipt_long, size: 20),
            label: const Text('Generate Bill'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
