import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/core/utils/haptic_helper.dart';
import 'package:restaurant_pos_system/core/utils/snackbar_helper.dart';
import 'package:restaurant_pos_system/shared/widgets/overlays/pdf_share_bottom_sheet.dart';

class KOTPDFViewerDialog extends StatefulWidget {
  final Uint8List pdfBytes;
  final String kotNumber;
  final String fileName;

  const KOTPDFViewerDialog({
    super.key,
    required this.pdfBytes,
    required this.kotNumber,
    required this.fileName,
  });

  static Future<void> show(
    BuildContext context, {
    required Uint8List pdfBytes,
    required String kotNumber,
    required String fileName,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'KOT Print Preview',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return KOTPDFViewerDialog(
          pdfBytes: pdfBytes,
          kotNumber: kotNumber,
          fileName: fileName,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<KOTPDFViewerDialog> createState() => _KOTPDFViewerDialogState();
}

class _KOTPDFViewerDialogState extends State<KOTPDFViewerDialog> {
  bool _isSharing = false;
  bool _isPrinting = false;

  String _formatKotNumber(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '#';
    final stripped = trimmed
        .replaceFirst(RegExp(r'^KOT\s*[-#]?\s*', caseSensitive: false), '')
        .trim();
    if (stripped.isEmpty || stripped.toUpperCase() == 'KOT') return '#';
    return stripped.startsWith('#') ? stripped : '#$stripped';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isTablet = size.width >= 600;

    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () async {
          await HapticHelper.triggerFeedback();
          _closeDialog();
        },
        child: Stack(
          children: [
            // Fullscreen Minimal Backdrop Blur matching clear_cart_dialog / edit_item_dialog
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 3.5, sigmaY: 3.5),
                child: Container(color: Colors.black.withValues(alpha: 0.12)),
              ),
            ),

            // Main Glassmorphism Dialog Card with Balanced Proportions & Breathing Room
            SafeArea(
              child: Center(
                child: GestureDetector(
                  onTap: () {}, // Prevent card tap from dismissing
                  child: Container(
                    width: isTablet ? size.width * 0.72 : size.width * 0.88,
                    height: isTablet ? size.height * 0.76 : size.height * 0.80,
                    constraints: BoxConstraints(
                      maxWidth: isTablet ? 650 : 440,
                      maxHeight: isTablet ? 740 : 640,
                    ),
                    margin: EdgeInsets.symmetric(
                      horizontal: isTablet ? 28 : 16,
                      vertical: isTablet ? 20 : 16,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(
                              alpha: 0.34,
                            ), // Genuine ultra-translucent frosted glass
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.55),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.10),
                                blurRadius: 32,
                                offset: const Offset(0, 12),
                              ),
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.20),
                                blurRadius: 10,
                                offset: const Offset(0, -2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Glassmorphic Header Bar
                              _buildHeader(context),

                              // PDF Preview Canvas Container with Visible Scrollbar
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
                                      color:
                                          Colors.white.withValues(alpha: 0.65),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.75,
                                        ),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.05,
                                          ),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
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
                                                'Rendering KOT Preview...',
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

                              // Docked Action Buttons Bar
                              _buildActionBar(context),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.45),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // KOT Icon Container
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

          // Title & Subtitle Badge Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'KOT Print Preview',
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
                        _formatKotNumber(widget.kotNumber),
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

          // Close IconButton
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            onPressed: () async {
              await HapticHelper.triggerFeedback();
              _closeDialog();
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
            color: Colors.white.withValues(alpha: 0.55),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Done Button (Left - Secondary action)
          Expanded(
            child: SizedBox(
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await HapticHelper.triggerFeedback();
                  _closeDialog();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF334155),
                  elevation: 1,
                  shadowColor: Colors.black.withValues(alpha: 0.08),
                  side: const BorderSide(
                    color: Color(0xFFCBD5E1),
                    width: 1.2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
                icon: const Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: Color(0xFF475569),
                ),
                label: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Share Button (Middle - Tonal action)
          Expanded(
            child: SizedBox(
              height: 44,
              child: ElevatedButton.icon(
                onPressed: _isSharing ? null : _shareKOT,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  elevation: 1,
                  shadowColor: const Color(0xFF0284C7).withValues(alpha: 0.25),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
                icon: _isSharing
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Icon(Icons.share_rounded, size: 16),
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _isSharing ? 'Sharing...' : 'Share',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Print Button (Right - Primary action)
          Expanded(
            child: SizedBox(
              height: 44,
              child: ElevatedButton.icon(
                onPressed: _isPrinting ? null : _printKOT,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 1,
                  shadowColor: AppColors.primary.withValues(alpha: 0.25),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
                icon: _isPrinting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Icon(Icons.print_rounded, size: 16),
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _isPrinting ? 'Printing...' : 'Print',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
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

  Future<void> _shareKOT() async {
    if (_isSharing) return;
    await HapticHelper.triggerFeedback();
    if (!mounted) return;
    setState(() => _isSharing = true);
    try {
      await PDFShareBottomSheet.show(
        context,
        pdfBytes: widget.pdfBytes,
        fileName: widget.fileName,
        orderNumber: widget.kotNumber,
      );
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Failed to share KOT: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  Future<void> _printKOT() async {
    if (_isPrinting) return;
    await HapticHelper.triggerFeedback();
    setState(() => _isPrinting = true);

    try {
      final printed = await Printing.layoutPdf(
        onLayout: (format) async => widget.pdfBytes,
        name: widget.fileName,
        format: PdfPageFormat.roll80,
      );
      if (printed && mounted) {
        AppSnackBar.showSuccess(
          context,
          'KOT sent to printer',
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(
          context,
          'Failed to print KOT: ${e.toString()}',
          duration: const Duration(seconds: 3),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPrinting = false);
      }
    }
  }

  void _closeDialog() {
    Navigator.of(context).pop();
  }
}
