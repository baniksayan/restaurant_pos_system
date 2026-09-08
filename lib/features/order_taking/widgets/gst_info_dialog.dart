import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/core/utils/haptic_helper.dart';
import 'package:restaurant_pos_system/features/billing/providers/tax_provider.dart';

class GSTInfoDialog extends StatelessWidget {
  const GSTInfoDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showGeneralDialog<void>(
      context: context,
      barrierLabel: 'GST Information',
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return const GSTInfoDialog();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).maybePop(),
        child: Stack(
          children: [
            // Fullscreen Background Blur
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 3.5, sigmaY: 3.5),
                child: Container(color: Colors.black.withValues(alpha: 0.12)),
              ),
            ),
            SafeArea(
              child: Center(
                child: GestureDetector(
                  onTap: () {}, // Prevent tap-through
                  child: Consumer<TaxProvider>(
                    builder: (context, taxProvider, child) {
                      final hasData = taxProvider.hasTaxData;
                      final totalGst = taxProvider.totalGstPercentage;
                      final taxData = taxProvider.taxData?.data;

                      return Container(
                        width: MediaQuery.of(context).size.width * 0.88,
                        constraints: const BoxConstraints(maxWidth: 420),
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.78),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header Row with Info Pill and Close Icon
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.receipt_long_rounded,
                                          color: Colors.blue,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Text(
                                          'GST Information',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1E1B4B),
                                          ),
                                        ),
                                      ),
                                      InkWell(
                                        onTap:
                                            () =>
                                                Navigator.of(
                                                  context,
                                                ).maybePop(),
                                        borderRadius: BorderRadius.circular(20),
                                        child: Padding(
                                          padding: const EdgeInsets.all(4.0),
                                          child: Icon(
                                            Icons.close_rounded,
                                            color: Colors.grey[600],
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Restaurant GST Details:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Color(0xFF1E1B4B),
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  if (hasData &&
                                      taxData != null &&
                                      taxData.isNotEmpty) ...[
                                    _buildGstRow(
                                      'Total GST Rate:',
                                      '${totalGst.toStringAsFixed(1)}%',
                                      color: Colors.green[700],
                                      isBold: true,
                                    ),
                                    const SizedBox(height: 8),
                                    Divider(
                                      color: Colors.grey.withValues(alpha: 0.3),
                                      height: 1,
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Tax Components (From API):',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    ...taxData.map(
                                      (tax) => _buildGstRow(
                                        '${tax.componentName ?? 'Unknown'}:',
                                        '${(tax.currentPercentage ?? 0).toStringAsFixed(1)}%',
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Colors.green.withValues(alpha: 0.25),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.check_circle_rounded,
                                            color: Colors.green[700],
                                            size: 16,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Live data from restaurant backend',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.green[800],
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ] else ...[
                                    _buildGstRow(
                                      'GST Rate:',
                                      '10% (Default Fallback)',
                                      color: Colors.orange[800],
                                      isBold: true,
                                    ),
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Colors.orange.withValues(alpha: 0.25),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.warning_amber_rounded,
                                            color: Colors.orange[800],
                                            size: 16,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Using default rate - API data loading...',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.orange[900],
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: 12),
                                  Divider(
                                    color: Colors.grey.withValues(alpha: 0.3),
                                    height: 1,
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Tax Application:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    '• Applied to all food items',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                  const Text(
                                    '• Calculated on subtotal amount',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                  const Text(
                                    '• Added to final bill amount',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF334155),
                                    ),
                                  ),

                                  if (hasData &&
                                      taxData != null &&
                                      taxData.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Text(
                                      'Last updated: ${_getFormattedTime()}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: 18),
                                  // Action Buttons Row
                                  Row(
                                    children: [
                                      if (!hasData ||
                                          taxData == null ||
                                          taxData.isEmpty) ...[
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () async {
                                              await HapticHelper.triggerFeedback();
                                              if (!context.mounted) return;
                                              Navigator.of(context).maybePop();
                                              final taxProvider =
                                                  Provider.of<TaxProvider>(
                                                    context,
                                                    listen: false,
                                                  );
                                              await taxProvider
                                                  .refreshTaxData();
                                              if (context.mounted) {
                                                GSTInfoDialog.show(context);
                                              }
                                            },
                                            icon: const Icon(
                                              Icons.refresh_rounded,
                                              size: 16,
                                            ),
                                            label: const Text('Refresh'),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: Colors.blue[700],
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 12,
                                                  ),
                                              side: BorderSide(
                                                color: Colors.blue.withValues(alpha: 0.3),
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                      ],
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            await HapticHelper.triggerFeedback();
                                            if (!context.mounted) return;
                                            Navigator.of(context).maybePop();
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: const Text(
                                            'Got it',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: isBold ? const Color(0xFF1E1B4B) : const Color(0xFF475569),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color ?? const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }
}
