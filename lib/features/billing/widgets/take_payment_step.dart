import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/core/utils/haptic_helper.dart';
import 'package:restaurant_pos_system/features/payment/models/tender_line.dart';
import 'package:restaurant_pos_system/features/payment/widgets/add_tender_sheet.dart';
import 'package:restaurant_pos_system/features/payment/widgets/amount_card.dart';
import 'package:restaurant_pos_system/features/payment/widgets/payment_breakdown_card.dart';
import 'package:restaurant_pos_system/features/payment/widgets/payment_status_illustration.dart';
import 'package:restaurant_pos_system/features/payment/widgets/tender_list_card.dart';

/// Step 3 of the checkout flow — take payment for a bill before generation.
/// Stages [TenderLine]s and displays the dynamic Hero card (pending, partially
/// paid, paid in full) with the SVG illustration and breakdown card.
class TakePaymentStep extends StatefulWidget {
  final String orderNumber;
  final double total;

  const TakePaymentStep({
    super.key,
    required this.orderNumber,
    required this.total,
  });

  @override
  State<TakePaymentStep> createState() => _TakePaymentStepState();
}

class _TakePaymentStepState extends State<TakePaymentStep> {
  final List<TenderLine> _tenders = [];

  double get _stagedTotal =>
      _tenders.fold(0.0, (sum, t) => sum + t.amount);

  double get _remaining {
    final left = widget.total - _stagedTotal;
    return left > 0 ? left : 0.0;
  }

  bool get _fullySettled => _remaining <= 0.004;

  PaymentStatusState get _currentStatus {
    if (_fullySettled || (widget.total > 0 && _stagedTotal >= widget.total - 0.004)) {
      return PaymentStatusState.paidInFull;
    }
    if (_stagedTotal > 0.004) {
      return PaymentStatusState.partiallyPaid;
    }
    return PaymentStatusState.pending;
  }

  Future<void> _addTender() async {
    await HapticHelper.triggerFeedback();
    if (!mounted) return;
    final tender = await AddTenderSheet.show(
      context,
      _remaining,
      orderNumber: widget.orderNumber,
    );
    if (tender == null || !mounted) return;
    setState(() => _tenders.add(tender));
  }

  void _removeTender(int index) {
    setState(() => _tenders.removeAt(index));
  }

  void _confirm() {
    HapticHelper.triggerFeedback();
    Navigator.of(context).pop(_tenders);
  }

  void _billLater() {
    HapticHelper.triggerFeedback();
    Navigator.of(context).pop(const <TenderLine>[]);
  }

  @override
  Widget build(BuildContext context) {
    final status = _currentStatus;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () async {
            await HapticHelper.triggerFeedback();
            if (context.mounted) Navigator.pop(context);
          },
        ),
        title: const Text(
          'Take Payment',
          style: TextStyle(
            fontSize: 18.5,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Padding(
            padding: const EdgeInsets.only(left: 18, right: 18, bottom: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                  ),
                  child: Text(
                    'Order #${widget.orderNumber}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          children: [
            // 1. Top Hero Card (Pending / Partially Paid / Paid in Full)
            AmountCard(
              totalAmount: widget.total,
              paidAmount: _stagedTotal,
              remainingAmount: _remaining,
              status: status,
            ),
            const SizedBox(height: 14),

            // 2. Breakdown Card (Total Amount, Amount Paid, Amount Due)
            PaymentBreakdownCard(
              totalAmount: widget.total,
              paidAmount: _stagedTotal,
              remainingAmount: _remaining,
              status: status,
            ),
            const SizedBox(height: 18),

            // 3. Payments Section with + Add Payment action
            TenderListCard(
              tenders: _tenders,
              billTotal: widget.total,
              previouslyPaid: 0,
              onRemove: _removeTender,
              onAddAnotherPayment: _addTender,
              isFullySettled: _fullySettled,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(
              top: BorderSide(color: Color(0xFFF1F5F9), width: 1.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _billLater,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Bill Later',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _tenders.isEmpty ? null : _confirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFE2E8F0),
                      disabledForegroundColor: const Color(0xFF94A3B8),
                      elevation: _tenders.isNotEmpty ? 2 : 0,
                      shadowColor: const Color(0xFF4F46E5).withValues(alpha: 0.35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: Icon(
                      _tenders.isNotEmpty
                          ? Icons.receipt_long_rounded
                          : Icons.lock_outline_rounded,
                      size: 18,
                    ),
                    label: const Text(
                      'Generate Bill',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
