import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import '../../../../../core/themes/app_colors.dart';
import '../../../../../services/pdf_service.dart';

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

  @override
  State<KOTPDFViewerDialog> createState() => _KOTPDFViewerDialogState();
}

class _KOTPDFViewerDialogState extends State<KOTPDFViewerDialog> {
  bool _isSharing = false;
  bool _isPrinting = false;

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: AppColors.surface,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          elevation: 2,
          automaticallyImplyLeading:
              false, // Remove back button since it's undismissible
          title: Row(
            children: [
              Icon(Icons.receipt, color: AppColors.textOnDark, size: 24),
              const SizedBox(width: 8),
              Text(
                'KOT #${widget.kotNumber}',
                style: const TextStyle(
                  color: AppColors.textOnDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          centerTitle: false,
        ),
        body: Column(
          children: [
            // PDF Viewer
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cardShadow,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: PdfPreview(
                    build: (format) => widget.pdfBytes,
                    allowPrinting: false,
                    allowSharing: false,
                    canChangePageFormat: false,
                    canChangeOrientation: false,
                    canDebug: false,
                    maxPageWidth: double.infinity,
                    pdfFileName: widget.fileName,
                  ),
                ),
              ),
            ),

            // Action Buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                border: Border(
                  top: BorderSide(
                    color: AppColors.textHint.withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    // Share Button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isSharing ? null : _shareKOT,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.info,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        icon:
                            _isSharing
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                      Colors.white,
                                    ),
                                  ),
                                )
                                : const Icon(Icons.share, size: 20),
                        label: Text(
                          _isSharing ? 'Sharing...' : 'Share',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Print Button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isPrinting ? null : _printKOT,
                        style: ElevatedButton.styleFrom(
                          // Use KOT-specific color instead of the global success (green)
                          backgroundColor: AppColors.tableCleaning,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        icon:
                            _isPrinting
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                      Colors.white,
                                    ),
                                  ),
                                )
                                : const Icon(Icons.print, size: 20),
                        label: Text(
                          _isPrinting ? 'Printing...' : 'Print',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Close Button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _closeDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.textSecondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        icon: const Icon(Icons.close, size: 20),
                        label: const Text(
                          'Close',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareKOT() async {
    if (_isSharing) return;

    setState(() => _isSharing = true);

    try {
      await PDFService.sharePDF(widget.pdfBytes, widget.fileName);

      if (mounted) {
        // Use KOT color for feedback instead of green snackbars per request
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('KOT shared successfully'),
            backgroundColor: AppColors.tableCleaning,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share KOT: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  Future<void> _printKOT() async {
    if (_isPrinting) return;

    setState(() => _isPrinting = true);

    try {
      await Printing.layoutPdf(
        onLayout: (format) async => widget.pdfBytes,
        name: widget.fileName,
        format: PdfPageFormat.a4,
      );

      if (mounted) {
        // Use KOT color for feedback instead of green snackbars per request
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Print dialog opened'),
            backgroundColor: AppColors.tableCleaning,
            duration: Duration(seconds: 2),
          ),
        );
      }
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
