import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _isNoteExpanded = false; // default collapsed in bottom section
  late final TextEditingController _noteController;

  static const int _maxNoteCharacters = 75;

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
                        widget.subtotal.toCurrency(),
                      ),
                      const SizedBox(height: 6),
                      _buildPriceRow(
                        "GST (${gstPercentage.toStringAsFixed(1)}%):",
                        gstAmount.toCurrency(),
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildCollapsibleKitchenNote(),
        const SizedBox(height: 8),
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

  Widget _buildCollapsibleKitchenNote() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: _isNoteExpanded
          ? _buildExpandedNotePanel()
          : _buildCollapsedNoteBar(),
    );
  }

  Widget _buildCollapsedNoteBar() {
    final note = _noteController.text.trim();
    final hasNote = note.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          await HapticHelper.triggerFeedback();
          setState(() => _isNoteExpanded = true);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
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
              if (hasNote) ...[
                // Clear button
                InkWell(
                  onTap: () async {
                    await HapticHelper.triggerFeedback();
                    _noteController.clear();
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: const Padding(
                    padding: EdgeInsets.all(3.0),
                    child: Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: Color(0xFF9A3412),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    hasNote ? 'Edit' : '+ Add',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: hasNote
                          ? const Color(0xFFEA580C)
                          : const Color(0xFF6D28D9),
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: hasNote
                        ? const Color(0xFFEA580C)
                        : const Color(0xFF6D28D9),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedNotePanel() {
    final length = _noteController.text.length;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFEA580C).withValues(alpha: 0.45),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Section header with counter badge and collapse trigger
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.soup_kitchen_rounded,
                    size: 14,
                    color: Color(0xFFEA580C),
                  ),
                  SizedBox(width: 5),
                  Text(
                    'NOTE FOR KITCHEN',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: Color(0xFF9A3412),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Full dialog button
                  InkWell(
                    onTap: _handleOpenFullDialog,
                    borderRadius: BorderRadius.circular(6),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Icon(
                        Icons.open_in_full_rounded,
                        size: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Character counter badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: length >= _maxNoteCharacters
                          ? Colors.orange.withValues(alpha: 0.15)
                          : Colors.grey.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$length/$_maxNoteCharacters',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: length >= _maxNoteCharacters
                            ? Colors.deepOrange
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Collapse button
                  InkWell(
                    onTap: () async {
                      await HapticHelper.triggerFeedback();
                      setState(() => _isNoteExpanded = false);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.all(2.0),
                      child: Icon(
                        Icons.keyboard_arrow_up_rounded,
                        size: 18,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Compact text input
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            child: TextField(
              controller: _noteController,
              maxLength: _maxNoteCharacters,
              inputFormatters: [
                LengthLimitingTextInputFormatter(_maxNoteCharacters),
                noEmojiFormatter,
              ],
              buildCounter: (
                context, {
                required currentLength,
                required isFocused,
                maxLength,
              }) =>
                  null,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
                height: 1.25,
              ),
              decoration: InputDecoration(
                hintText: 'e.g. Serve together, no onions across table...',
                hintStyle: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF94A3B8),
                ),
                counterText: '',
                isDense: true,
                filled: false,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFFEA580C),
                    width: 1.2,
                  ),
                ),
                suffixIcon: _noteController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 14),
                        color: const Color(0xFF94A3B8),
                        splashRadius: 14,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        onPressed: () => _noteController.clear(),
                      )
                    : null,
                suffixIconConstraints: const BoxConstraints(
                  minWidth: 28,
                  minHeight: 28,
                ),
              ),
            ),
          ),
        ],
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
