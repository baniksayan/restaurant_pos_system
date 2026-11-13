import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/core/constants/currency_constants.dart';
import 'package:restaurant_pos_system/core/utils/haptic_helper.dart';
import 'package:restaurant_pos_system/core/utils/no_emoji_formatter.dart';
import 'package:restaurant_pos_system/features/billing/providers/tax_provider.dart';
import 'package:restaurant_pos_system/features/order_taking/widgets/kitchen_note_dialog.dart';

class CartFooter extends StatefulWidget {
  final double subtotal;
  final bool kotGenerated;
  final VoidCallback onGenerateKOT;
  final VoidCallback onSendToKitchen;
  final VoidCallback onGenerateBill;
  final VoidCallback onShowGSTInfo;
  final String kotNote;
  final ValueChanged<String>? onKotNoteChanged;
  final VoidCallback? onOpenKotNoteDialog;
  final bool isBilled;
  final VoidCallback? onProceedToPayment;

  const CartFooter({
    super.key,
    required this.subtotal,
    required this.kotGenerated,
    required this.onGenerateKOT,
    required this.onSendToKitchen,
    required this.onGenerateBill,
    required this.onShowGSTInfo,
    this.kotNote = '',
    this.onKotNoteChanged,
    this.onOpenKotNoteDialog,
    this.isBilled = false,
    this.onProceedToPayment,
  });

  @override
  State<CartFooter> createState() => _CartFooterState();
}

class _CartFooterState extends State<CartFooter> {
  bool _expanded = false; // default collapsed (for GST details)
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _noteController =
        TextEditingController(text: removeEmojis(widget.kotNote));
    _noteController.addListener(_onNoteTextChanged);
  }

  @override
  void didUpdateWidget(CartFooter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.kotNote != oldWidget.kotNote &&
        widget.kotNote != _noteController.text) {
      _noteController.text = removeEmojis(widget.kotNote);
    }
  }

  void _onNoteTextChanged() {
    if (widget.onKotNoteChanged != null &&
        _noteController.text != widget.kotNote) {
      widget.onKotNoteChanged!(_noteController.text);
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _noteController.removeListener(_onNoteTextChanged);
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handleOpenFullDialog() async {
    if (widget.onOpenKotNoteDialog != null) {
      widget.onOpenKotNoteDialog!();
      return;
    }
    final result = await KitchenNoteDialog.show(
      context,
      initialNote: _noteController.text,
    );
    if (result != null) {
      _noteController.text = result;
      widget.onKotNoteChanged?.call(result);
      if (mounted) setState(() {});
    }
  }

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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: 0.72,
                  ), // Transparent frosted glass fill
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(
                      alpha: 0.85,
                    ), // Clean white glass border
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
                              (widget.subtotal + taxProvider.calculateGstAmount(widget.subtotal)).toCurrency(),
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
                      if (widget.isBilled)
                        _buildBilledButtons()
                      else if (!widget.kotGenerated)
                        _buildPreKOTButtons()
                      else
                        _buildPostKOTButtons(),
                    ] else ...[
                      // Expanded: Header row with Title on left, collapse arrow on right
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Bill Details',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF64748B),
                              letterSpacing: 0.2,
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
                      const SizedBox(height: 6),
                      _buildPriceRow(
                        "Subtotal:",
                        widget.subtotal.toCurrency(),
                      ),
                      const SizedBox(height: 6),
                      _buildPriceRow(
                        "GST (${gstPercentage.toStringAsFixed(1)}%):",
                        gstAmount.toCurrency(),
                        onTapInfo: () async {
                          await HapticHelper.triggerFeedback();
                          widget.onShowGSTInfo();
                        },
                      ),
                      const SizedBox(height: 8),
                      Divider(
                        thickness: 1,
                        height: 1,
                        color: Colors.grey.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 8),
                      _buildPriceRow(
                        "TOTAL AMOUNT:",
                        total.toCurrency(),
                        isTotal: true,
                      ),
                      const SizedBox(height: 10),
                      if (widget.isBilled)
                        _buildBilledButtons()
                      else if (!widget.kotGenerated)
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

  Widget _buildPriceRow(
    String label,
    String value, {
    bool isTotal = false,
    VoidCallback? onTapInfo,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: isTotal ? 14 : 13,
                fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
                color: isTotal ? const Color(0xFF1E1B4B) : const Color(0xFF475569),
              ),
            ),
            if (onTapInfo != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onTapInfo,
                child: const Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: Color(0xFF6366F1),
                ),
              ),
            ],
          ],
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
    final note = _noteController.text.trim();
    final hasNote = note.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!hasNote) ...[
          _buildKitchenNoteBar(),
          const SizedBox(height: 8),
        ],
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () async {
              await HapticHelper.triggerFeedback();
              widget.onGenerateKOT();
            },
            icon: const Icon(Icons.print_rounded, size: 18),
            label: const Text(
              'Generate KOT',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A).withValues(alpha: 0.92),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 11),
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

  Widget _buildKitchenNoteBar() {
    final note = _noteController.text.trim();
    final hasNote = note.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          await HapticHelper.triggerFeedback();
          await _handleOpenFullDialog();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7.5),
          decoration: BoxDecoration(
            color: hasNote
                ? const Color(0xFFFFF7ED)
                : Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasNote
                  ? const Color(0xFFEA580C).withValues(alpha: 0.65)
                  : Colors.grey.withValues(alpha: 0.32),
              width: 1.1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                hasNote
                    ? Icons.soup_kitchen_rounded
                    : Icons.edit_note_rounded,
                size: 16,
                color: hasNote
                    ? const Color(0xFFEA580C)
                    : const Color(0xFF64748B),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasNote ? 'Note: $note' : 'Note for Kitchen (Optional)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: hasNote ? FontWeight.w700 : FontWeight.w600,
                    color: hasNote
                        ? const Color(0xFF9A3412)
                        : const Color(0xFF475569),
                  ),
                ),
              ),
              if (hasNote)
                InkWell(
                  onTap: () async {
                    await HapticHelper.triggerFeedback();
                    _noteController.clear();
                    widget.onKotNoteChanged?.call('');
                    if (mounted) setState(() {});
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: Color(0xFF9A3412),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBilledButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.45),
              width: 1,
            ),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.receipt_long_rounded,
                size: 16,
                color: Color(0xFFD97706),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Bill Generated • Payment Pending',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF92400E),
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () async {
              await HapticHelper.triggerFeedback();
              widget.onProceedToPayment?.call();
            },
            icon: const Icon(Icons.payment_rounded, size: 18),
            label: const Text(
              'Proceed to Payment',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              elevation: 2,
              shadowColor: const Color(0xFF10B981).withValues(alpha: 0.35),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
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
