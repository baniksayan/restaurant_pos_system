import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/core/constants/currency_constants.dart';
import 'package:restaurant_pos_system/core/utils/haptic_helper.dart';
import 'package:restaurant_pos_system/features/payment/models/tender_line.dart';
import 'package:restaurant_pos_system/features/payment/widgets/add_tender_sheet.dart';
import 'package:restaurant_pos_system/features/payment/widgets/tender_list_card.dart';

/// Step 3 of the checkout flow — take payment for a bill that doesn't exist
/// yet. Stages [TenderLine]s exactly like the Payment screen does (reusing
/// the same [AddTenderSheet]/[TenderListCard] widgets, which were already
/// designed to be billId-agnostic — see AddTenderSheet's own doc comment),
/// but never calls SavePayment: there's no bill to attach a payment to
/// until `createBill` runs. Confirming here returns the staged tenders to
/// the caller, who sends them to `createBill`'s own `paymentDetails` —
/// creating and settling the bill in one request instead of two.
///
/// "Bill Later" skips straight past with no tenders staged, preserving the
/// existing pay-later path unchanged.
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

  double get _stagedTotal => _tenders.fold(0.0, (sum, t) => sum + t.amount);

  double get _remaining {
    final left = widget.total - _stagedTotal;
    return left > 0 ? left : 0.0;
  }

  bool get _fullySettled => _remaining <= 0.004;

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
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Take Payment'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.20),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Amount Due',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    CurrencyConstants.format(widget.total),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TenderListCard(
              tenders: _tenders,
              billTotal: widget.total,
              previouslyPaid: 0,
              onRemove: _removeTender,
            ),
            const SizedBox(height: 12),
            if (!_fullySettled)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _addTender,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(
                    _tenders.isEmpty ? 'Add payment' : 'Add another payment',
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton(
                    onPressed: _billLater,
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Bill Later'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _tenders.isEmpty ? null : _confirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Confirm & Generate Bill',
                      style: TextStyle(fontWeight: FontWeight.w700),
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
