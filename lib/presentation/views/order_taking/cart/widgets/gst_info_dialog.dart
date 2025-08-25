// import 'package:flutter/material.dart';

// class GSTInfoDialog extends StatelessWidget {
//   const GSTInfoDialog({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       title: const Row(
//         children: [
//           Icon(Icons.info, color: Colors.blue),
//           SizedBox(width: 8),
//           Text('GST Information'),
//         ],
//       ),
//       content: const Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Restaurant GST Details:',
//             style: TextStyle(fontWeight: FontWeight.bold),
//           ),
//           SizedBox(height: 8),
//           Text('• GST Rate: 18% (Pre-defined)'),
//           Text('• Applied to all food items'),
//           Text('• Inclusive in final amount'),
//           SizedBox(height: 12),
//           Card(
//             color: Color(0xFFE8F5E8),
//             child: Padding(
//               padding: EdgeInsets.all(8),
//               child: Text(
//                 'This is a standard restaurant GST rate as per regulations.',
//                 style: TextStyle(fontSize: 12, color: Colors.green),
//               ),
//             ),
//           ),
//         ],
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.pop(context),
//           child: const Text('Got it'),
//         ),
//       ],
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../presentation/view_models/providers/tax_provider.dart';

class GSTInfoDialog extends StatelessWidget {
  const GSTInfoDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TaxProvider>(
      builder: (context, taxProvider, child) {
        final hasData = taxProvider.hasTaxData;
        final totalGst = taxProvider.totalGstPercentage;
        final cgst = taxProvider.cgstPercentage;
        final sgst = taxProvider.sgstPercentage;

        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.info, color: Colors.blue),
              SizedBox(width: 8),
              Text('GST Information'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Restaurant GST Details:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              if (hasData) ...[
                // Dynamic GST breakdown
                _buildGstRow(
                  'Total GST Rate:',
                  '${totalGst.toStringAsFixed(1)}%',
                  color: Colors.green,
                  isBold: true,
                ),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'GST Breakdown:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                _buildGstRow('CGST:', '${cgst.toStringAsFixed(1)}%'),
                _buildGstRow('SGST:', '${sgst.toStringAsFixed(1)}%'),
              ] else ...[
                // Fallback when no data
                _buildGstRow(
                  'GST Rate:',
                  '18% (Default)',
                  color: Colors.orange,
                  isBold: true,
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Loading dynamic rates...',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],

              const SizedBox(height: 12),
              const Text('• Applied to all food items'),
              const Text('• Inclusive in final amount'),

              const SizedBox(height: 12),
              Card(
                color: const Color(0xFFE8F5E8),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    hasData
                        ? 'GST rates are dynamically loaded from backend.'
                        : 'Using standard restaurant GST rate as fallback.',
                    style: const TextStyle(fontSize: 12, color: Colors.green),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Got it'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGstRow(
    String label,
    String value, {
    Color? color,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
