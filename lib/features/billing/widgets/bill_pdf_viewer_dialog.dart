import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/core/utils/haptic_helper.dart';
import 'package:restaurant_pos_system/core/utils/snackbar_helper.dart';

class BillPDFViewerDialog extends StatefulWidget {
  final Uint8List pdfBytes;
  final String orderNumber;
  final String fileName;

  const BillPDFViewerDialog({
    super.key,
    required this.pdfBytes,
    required this.orderNumber,
    required this.fileName,
  });

  @override
  State<BillPDFViewerDialog> createState() => _BillPDFViewerDialogState();
}

class _BillPDFViewerDialogState extends State<BillPDFViewerDialog> {
  bool _isPrinting = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isTablet = size.width >= 600;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Minimal Backdrop Blur with outside tap to close functionality
          Positioned.fill(
            child: GestureDetector(
              onTap: () async {
                await HapticHelper.triggerFeedback();
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 3.5, sigmaY: 3.5),
                child: Container(color: Colors.black.withValues(alpha: 0.12)),
              ),
            ),
          ),

          // Main Centered Frosted Glass Modal
          SafeArea(
            child: Center(
              child: Container(
                width: isTablet ? size.width * 0.72 : size.width * 0.90,
                height: isTablet ? size.height * 0.80 : size.height * 0.84,
                constraints: BoxConstraints(
                  maxWidth: isTablet ? 640 : 460,
                  maxHeight: isTablet ? 720 : 640,
                ),
                margin: EdgeInsets.symmetric(
                  horizontal: isTablet ? 24 : 12,
                  vertical: isTablet ? 20 : 12,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.85),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.10),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Header Bar
                          _buildHeader(context),

                          // PDF Canvas Sheet
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                12,
                                10,
                                12,
                                10,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.60),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: PdfPreview(
                                    build: (format) => widget.pdfBytes,
                                    allowPrinting: false,
                                    allowSharing: false,
                                    canChangePageFormat: false,
                                    canChangeOrientation: false,
                                    canDebug: false,
                                    maxPageWidth: double.infinity,
                                    pdfFileName: widget.fileName,
                                    loadingWidget: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.hourglass_empty_rounded,
                                            size: 40,
                                            color: AppColors.primary,
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'Rendering Bill Preview...',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Docked Action Buttons Bar (Close on LEFT with Border, Print on RIGHT)
                          _buildActionBar(context),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.35),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.60),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.30),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              size: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Bill Print Preview',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.30),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Order #${widget.orderNumber}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            onPressed: () async {
              await HapticHelper.triggerFeedback();
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            style: IconButton.styleFrom(
              backgroundColor: Colors.black.withValues(alpha: 0.05),
              foregroundColor: AppColors.textSecondary,
              padding: const EdgeInsets.all(6),
              minimumSize: const Size(32, 32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.35),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.60),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Close Glass Button on the LEFT with Distinct Border
          Expanded(
            child: SizedBox(
              height: 42,
              child: OutlinedButton(
                onPressed: () async {
                  await HapticHelper.triggerFeedback();
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.60),
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: Color(0xFF94A3B8), width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Print Primary Button on the RIGHT
          Expanded(
            child: SizedBox(
              height: 42,
              child: ElevatedButton.icon(
                onPressed: _isPrinting ? null : _printBill,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 3,
                  shadowColor: AppColors.primary.withValues(alpha: 0.35),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon:
                    _isPrinting
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Icon(Icons.print_rounded, size: 17),
                label: Text(
                  _isPrinting ? 'Printing...' : 'Print',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _printBill() async {
    if (_isPrinting) return;
    await HapticHelper.triggerFeedback();
    setState(() => _isPrinting = true);
    try {
      await Printing.layoutPdf(
        onLayout: (format) async => widget.pdfBytes,
        name: widget.fileName,
        format: PdfPageFormat.a4,
      );
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Failed to print bill: $e');
      }
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }
}
