import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/core/utils/haptic_helper.dart';
import 'package:restaurant_pos_system/shared/services/pdf_service.dart';
import 'package:restaurant_pos_system/core/constants/app_strings.dart';
import 'package:restaurant_pos_system/core/utils/snackbar_helper.dart';

class PDFShareBottomSheet extends StatelessWidget {
  final Uint8List pdfBytes;
  final String fileName;
  final String orderNumber;

  const PDFShareBottomSheet({
    super.key,
    required this.pdfBytes,
    required this.fileName,
    required this.orderNumber,
  });

  static Future<void> show(
    BuildContext context, {
    required Uint8List pdfBytes,
    required String fileName,
    required String orderNumber,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.18),
      isScrollControlled: true,
      builder: (BuildContext context) {
        return PDFShareBottomSheet(
          pdfBytes: pdfBytes,
          fileName: fileName,
          orderNumber: orderNumber,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(28),
        topRight: Radius.circular(28),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.72),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.88),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag Indicator Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Header Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.kotStatus.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.kotStatus.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.share_rounded,
                        color: AppColors.kotStatus,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Share Document',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Order: #$orderNumber',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
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
                        padding: const EdgeInsets.all(8),
                        minimumSize: const Size(32, 32),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Option Cards
                _buildOptionCard(
                  context: context,
                  icon: Icons.message_rounded,
                  iconColor: Colors.green[600]!,
                  bgColor: Colors.green[50]!,
                  title: AppStrings.pdf.whatsAppKitchen,
                  subtitle: AppStrings.pdf.whatsAppKitchenSubtitle,
                  onTap: () async {
                    await HapticHelper.triggerFeedback();
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      _sendViaWhatsApp(context);
                    }
                  },
                ),
                const SizedBox(height: 12),
                _buildOptionCard(
                  context: context,
                  icon: Icons.picture_as_pdf_rounded,
                  iconColor: AppColors.kotStatus,
                  bgColor: AppColors.kotStatus.withValues(alpha: 0.12),
                  title: AppStrings.pdf.sharePdfDocument,
                  subtitle: AppStrings.pdf.sharePdfSubtitle,
                  onTap: () async {
                    await HapticHelper.triggerFeedback();
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      _sharePDF(context);
                    }
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.8),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.grey[400],
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendViaWhatsApp(BuildContext context) async {
    try {
      final whatsappMessage = "New KOT/Bill generated! Ticket #$orderNumber.";
      final whatsappUrl =
          "https://wa.me/+918768412832?text=${Uri.encodeComponent(whatsappMessage)}";

      if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
        await launchUrl(
          Uri.parse(whatsappUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw "Could not open WhatsApp. Please ensure WhatsApp is installed.";
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.showError(context, 'Error sending via WhatsApp: $e');
      }
    }
  }

  Future<void> _sharePDF(BuildContext context) async {
    try {
      await PDFService.sharePDF(pdfBytes, fileName);
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.showError(context, 'Error sharing PDF: $e');
      }
    }
  }
}
