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
        final taxData = taxProvider.taxData?.data;

        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.info, color: Colors.blue),
              SizedBox(width: 8),
              Text('GST Information'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Restaurant GST Details:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                if (hasData && taxData != null && taxData.isNotEmpty) ...[
                  // API Data breakdown
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
                    'Tax Components (From API):',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 6),

                  // Show all tax components from API
                  ...taxData.map(
                    (tax) => _buildGstRow(
                      '${tax.componentName ?? 'Unknown'}:',
                      '${(tax.currentPercentage ?? 0).toStringAsFixed(1)}%',
                    ),
                  ),

                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 16),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Text(
                            'Live data from restaurant backend',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Fallback when no data
                  _buildGstRow(
                    'GST Rate:',
                    '10% (Default Fallback)',
                    color: Colors.orange,
                    isBold: true,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange, size: 16),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Text(
                            'Using default rate - API data loading...',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Tax Application:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                const Text(
                  '• Applied to all food items',
                  style: TextStyle(fontSize: 12),
                ),
                const Text(
                  '• Calculated on subtotal amount',
                  style: TextStyle(fontSize: 12),
                ),
                const Text(
                  '• Added to final bill amount',
                  style: TextStyle(fontSize: 12),
                ),

                if (hasData && taxData != null && taxData.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Last updated: ${_getFormattedTime()}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            if (!hasData || taxData == null || taxData.isEmpty)
              TextButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  // Get TaxProvider and refresh data
                  final taxProvider = Provider.of<TaxProvider>(
                    context,
                    listen: false,
                  );
                  await taxProvider.refreshTaxData();
                  // Show dialog again with updated data
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      builder: (context) => const GSTInfoDialog(),
                    );
                  }
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh from API'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Got it'),
            ),
          ],
        );
      },
    );
  }

  String _getFormattedTime() {
    final now = DateTime.now();
    return '${now.day}/${now.month}/${now.year} at ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
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
