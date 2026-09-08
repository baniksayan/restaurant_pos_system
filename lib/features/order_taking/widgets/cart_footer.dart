import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/core/constants/currency_constants.dart';
import 'package:restaurant_pos_system/core/utils/haptic_helper.dart';
import 'package:restaurant_pos_system/features/billing/providers/tax_provider.dart';

class CartFooter extends StatefulWidget {
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
  State<CartFooter> createState() => _CartFooterState();
}

class _CartFooterState extends State<CartFooter> {
  bool _expanded = false; // default collapsed

  @override
  Widget build(BuildContext context) {
    return Consumer<TaxProvider>(
      builder: (context, taxProvider, child) {
        final gstPercentage = taxProvider.totalGstPercentage;
        final gstAmount = taxProvider.calculateGstAmount(widget.subtotal);
        final total = widget.subtotal + gstAmount;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.72), // Transparent frosted glass fill
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.85), // Clean white glass border
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!_expanded) ...[
                      // Collapsed: TOTAL AMOUNT row with arrow on right
                      Row(
                        children: [
                          Expanded(
                            child: _buildPriceRow(
                              "TOTAL AMOUNT:",
                              "${CurrencyConstants.symbol}${(widget.subtotal + taxProvider.calculateGstAmount(widget.subtotal)).toStringAsFixed(2)}",
                              isTotal: true,
                            ),
                          ),
                          InkWell(
                            onTap: () async {
                              await HapticHelper.triggerFeedback();
                              setState(() => _expanded = !_expanded);
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(
                                Icons.keyboard_arrow_up_rounded,
                                size: 24,
                                color: Color(0xFF6D28D9),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (!widget.kotGenerated)
                        _buildPreKOTButtons()
                      else
                        _buildPostKOTButtons(),
                    ] else ...[
                      // Expanded: GST info row with arrow on right
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                await HapticHelper.triggerFeedback();
                                widget.onShowGSTInfo();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.blue.withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.info,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Restaurant GST: ${gstPercentage.toStringAsFixed(1)}% ${taxProvider.hasTaxData ? "(From API)" : "(Default)"} - Tap for info',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.blue[800],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () async {
                              await HapticHelper.triggerFeedback();
                              setState(() => _expanded = !_expanded);
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 24,
                                color: Color(0xFF6D28D9),
                              ),
                            ),
                          ),
                        ],
                      ),
                      _buildPriceRow(
                        "Subtotal:",
                        "${CurrencyConstants.symbol}${widget.subtotal.toStringAsFixed(2)}",
                      ),
                      const SizedBox(height: 6),
                      _buildPriceRow(
                        "GST (${gstPercentage.toStringAsFixed(1)}%):",
                        "${CurrencyConstants.symbol}${gstAmount.toStringAsFixed(2)}",
                      ),
                      const SizedBox(height: 8),
                      Divider(thickness: 1, height: 1, color: Colors.grey.withValues(alpha: 0.3)),
                      const SizedBox(height: 8),
                      _buildPriceRow(
                        "TOTAL AMOUNT:",
                        "${CurrencyConstants.symbol}${total.toStringAsFixed(2)}",
                        isTotal: true,
                      ),
                      const SizedBox(height: 10),
                      if (!widget.kotGenerated)
                        _buildPreKOTButtons()
                      else
                        _buildPostKOTButtons(),
                    ],
                  ],
                ),
              ),
            ),
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
            fontSize: isTotal ? 14 : 13,
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
            color: isTotal ? const Color(0xFF1E1B4B) : const Color(0xFF475569),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 17 : 13,
            fontWeight: FontWeight.w800,
            color: isTotal ? AppColors.primary : const Color(0xFF1E293B),
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
          widget.onGenerateKOT();
        },
        icon: const Icon(Icons.print_rounded, size: 18),
        label: const Text(
          'Generate KOT',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.3),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF16A34A).withValues(alpha: 0.92),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 11),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              widget.onSendToKitchen();
            },
            icon: const Icon(Icons.kitchen_rounded, size: 18),
            label: const Text(
              'Send to Kitchen',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10),
              side: BorderSide(color: Colors.orange[700]!, width: 1.5),
              foregroundColor: Colors.orange[800],
              backgroundColor: Colors.white.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () async {
              await HapticHelper.triggerFeedback();
              widget.onGenerateBill();
            },
            icon: const Icon(Icons.receipt_long_rounded, size: 18),
            label: const Text(
              'Generate Bill',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary.withValues(alpha: 0.92),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
