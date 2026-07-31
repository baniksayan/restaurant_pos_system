import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/constants/currency_constants.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../services/upi_storage_service.dart';

class QRSection extends StatefulWidget {
  final double amount;
  final String orderNumber;

  const QRSection({
    super.key,
    required this.amount,
    required this.orderNumber,
  });

  @override
  State<QRSection> createState() => _QRSectionState();
}

class _QRSectionState extends State<QRSection> {
  String _upiId = UpiStorageService.defaultUpiId;
  bool _loadingUpi = true;

  @override
  void initState() {
    super.initState();
    _loadStoredUpi();
  }

  Future<void> _loadStoredUpi() async {
    final upi = await UpiStorageService.getUpiId();
    if (mounted) {
      setState(() {
        _upiId = upi;
        _loadingUpi = false;
      });
    }
  }

  void _showConfigureUpiDialog() {
    final upiController = TextEditingController(text: _upiId);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.25),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F172A).withValues(alpha: 0.45)
                      : Colors.white.withValues(alpha: 0.30),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.45),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 25,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.qr_code_scanner, color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Configure UPI ID',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Restaurant UPI ID',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: upiController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. restaurant@upi or 9876543210@paytm',
                          prefixIcon: Icon(Icons.alternate_email_rounded, size: 18),
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a valid UPI ID';
                          }
                          if (!value.contains('@')) {
                            return 'UPI ID must contain "@" (e.g. name@upi)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: () async {
                              if (formKey.currentState?.validate() ?? false) {
                                final newUpi = upiController.text.trim();
                                await UpiStorageService.setUpiId(newUpi);
                                if (mounted) {
                                  setState(() {
                                    _upiId = newUpi;
                                  });
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('UPI ID saved: $newUpi'),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                }
                              }
                            },
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Save UPI ID'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final upiPayload =
        'upi://pay?pa=$_upiId&pn=${Uri.encodeComponent(UpiStorageService.defaultMerchantName)}&am=${widget.amount}&cu=INR&tn=Order%20${widget.orderNumber}';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header & Configure Button
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.qr_code_2_rounded, color: cs.primary, size: 22),
              ),
              const SizedBox(width: 10),
              Text(
                'Scan QR to Pay',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _showConfigureUpiDialog,
                style: TextButton.styleFrom(
                  foregroundColor: cs.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: cs.primary.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text(
                  'UPI ID',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // QR Code View Container
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _loadingUpi
                  ? const SizedBox(
                      width: 190,
                      height: 190,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : QrImageView(
                      data: upiPayload,
                      version: QrVersions.auto,
                      size: 190,
                      backgroundColor: Colors.white,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
