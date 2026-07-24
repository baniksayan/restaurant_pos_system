import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import '../../../../../core/themes/app_colors.dart';
import '../../../../../core/utils/haptic_helper.dart';
import '../../../../../shared/widgets/overlays/pdf_share_bottom_sheet.dart';

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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isTablet = size.width >= 600;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Fullscreen Minimal Backdrop Blur matching clear_cart_dialog / edit_item_dialog
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3.5, sigmaY: 3.5),
              child: Container(color: Colors.black.withValues(alpha: 0.08)),
            ),
          ),

          // Main Glassmorphism Dialog Card with Balanced Proportions & Breathing Room
          SafeArea(
            child: Center(
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
                                  color: Colors.white.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.75),
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
                                  child: PrimaryScrollController(
                                    controller: ScrollController(),
                                    child: RawScrollbar(
                                      thumbVisibility: true,
                                      trackVisibility: true,
                                      thickness: 5,
                                      radius: const Radius.circular(4),
                                      thumbColor: AppColors.primary.withValues(
                                        alpha: 0.6,
                                      ),
                                      trackColor: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
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
                                              const CircularProgressIndicator(
                                                color: AppColors.primary,
                                              ),
                                              const SizedBox(height: 10),
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
        ],
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
                        'KOT #${widget.kotNumber}',
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
        color: Colors.white.withValues(alpha: 0.28),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.45),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Share Button
          Expanded(
            flex: 3,
            child: ElevatedButton.icon(
              onPressed:
                  _isSharing
                      ? null
                      : () async {
                        await HapticHelper.triggerFeedback();
                        _shareKOT();
                      },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(
                  0xFF0284C7,
                ).withValues(alpha: 0.88), // Sky 600
                foregroundColor: Colors.white,
                elevation: 1.5,
                shadowColor: const Color(0xFF0284C7).withValues(alpha: 0.25),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon:
                  _isSharing
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                      : const Icon(Icons.share_rounded, size: 16),
              label: Text(
                _isSharing ? 'Sharing...' : 'Share',
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Print Button (Primary Action)
          Expanded(
            flex: 4,
            child: ElevatedButton.icon(
              onPressed:
                  _isPrinting
                      ? null
                      : () async {
                        await HapticHelper.triggerFeedback();
                        _printKOT();
                      },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 3,
                shadowColor: AppColors.primary.withValues(alpha: 0.35),
                padding: const EdgeInsets.symmetric(vertical: 12),
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
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                      : const Icon(Icons.print_rounded, size: 18),
              label: Text(
                _isPrinting ? 'Printing...' : 'Print KOT',
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Close / Done Button
          Expanded(
            flex: 3,
            child: OutlinedButton.icon(
              onPressed: () async {
                await HapticHelper.triggerFeedback();
                _closeDialog();
              },
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.65),
                foregroundColor: const Color(0xFF334155),
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(
                  color: Colors.white.withValues(alpha: 0.8),
                  width: 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(
                Icons.check_circle_outline_rounded,
                size: 16,
                color: Color(0xFF475569),
              ),
              label: const Text(
                'Done',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareKOT() async {
    await PDFShareBottomSheet.show(
      context,
      pdfBytes: widget.pdfBytes,
      fileName: widget.fileName,
      orderNumber: widget.kotNumber,
    );
  }

  Future<void> _printKOT() async {
    if (_isPrinting) return;

    setState(() => _isPrinting = true);

    try {
      await Printing.layoutPdf(
        onLayout: (format) async => widget.pdfBytes,
        name: widget.fileName,
        format: PdfPageFormat.roll80,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to print KOT: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
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
