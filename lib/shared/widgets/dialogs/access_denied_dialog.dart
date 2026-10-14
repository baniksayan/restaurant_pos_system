import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/core/constants/app_strings.dart';
import 'package:restaurant_pos_system/core/utils/haptic_helper.dart';

/// Common glassmorphic access denied dialog for unauthorized login attempts.
///
/// Exactly matches the project standard glassmorphic design found in
/// [SignOutConfirmationDialog], featuring identical frosted glass backdrop blur,
/// translucent white card, clean icon badge, and flat action button.
class AccessDeniedDialog extends StatelessWidget {
  final VoidCallback? onDismiss;
  final double? maxWidth;

  const AccessDeniedDialog({super.key, this.onDismiss, this.maxWidth});

  /// Displays the glass-morphic access denied dialog.
  static Future<void> show(BuildContext context, {VoidCallback? onDismiss}) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AccessDeniedDialog(onDismiss: onDismiss);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final dialogMaxWidth =
        maxWidth ?? (size.width < 480 ? size.width * 0.92 : 380.0);

    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {}, // Prevent backdrop tap from dismissing dialog
        child: Stack(
          children: [
            // Standard ambient backdrop blur & subtle dimming
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 3.5, sigmaY: 3.5),
                child: Container(color: Colors.black.withValues(alpha: 0.08)),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 24,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: dialogMaxWidth),
                    child: GestureDetector(
                      onTap: () {}, // Prevent card taps from propagating
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.52),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.75),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(22),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Standard circular icon badge
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.lock_person_rounded,
                                      color: Colors.redAccent,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(height: 14),

                                  // Title
                                  Text(
                                    AppStrings.auth.accessDenied,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  // Subtitle & Message
                                  Text(
                                    '${AppStrings.auth.accessDeniedSubtitle}\n\n${AppStrings.auth.accessDeniedMessage}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      color: AppColors.textSecondary,
                                      height: 1.45,
                                    ),
                                  ),
                                  const SizedBox(height: 22),

                                  // Standard confirmation button matching other dialogs
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        await HapticHelper.triggerFeedback();
                                        if (context.mounted) {
                                          Navigator.of(context).pop();
                                        }
                                        onDismiss?.call();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.redAccent,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 13,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        AppStrings.auth.okGotIt,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
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
            ),
          ],
        ),
      ),
    );
  }
}
