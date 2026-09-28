import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/core/constants/app_strings.dart';

/// Common glassmorphic confirmation dialog for signing out / logging out.
///
/// Features the frosted glass backdrop blur, rounded translucent card,
/// warning sign-out icon, message, and glassmorphic Cancel/Sign Out action buttons.
class SignOutConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final double? maxWidth;

  const SignOutConfirmationDialog({
    super.key,
    this.title = AppStrings.signOutConfirmation,
    this.message = AppStrings.signOutProConfirm,
    this.confirmText = AppStrings.signOut,
    this.cancelText = AppStrings.cancel,
    this.onConfirm,
    this.onCancel,
    this.maxWidth,
  });

  /// Displays the glass-morphic sign-out confirmation dialog.
  ///
  /// Returns `true` if the user confirmed sign out, `false` or `null` otherwise.
  static Future<bool?> show(
    BuildContext context, {
    String title = AppStrings.signOutConfirmation,
    String message = AppStrings.signOutProConfirm,
    String confirmText = AppStrings.signOut,
    String cancelText = AppStrings.cancel,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool useRootNavigator = false,
  }) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.transparent,
      useRootNavigator: useRootNavigator,
      builder: (BuildContext dialogContext) {
        return SignOutConfirmationDialog(
          title: title,
          message: message,
          confirmText: confirmText,
          cancelText: cancelText,
          onConfirm: () {
            Navigator.of(dialogContext).pop(true);
            onConfirm?.call();
          },
          onCancel: () {
            Navigator.of(dialogContext).pop(false);
            onCancel?.call();
          },
        );
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
        onTap: () {
          if (onCancel != null) {
            onCancel!();
          } else {
            Navigator.of(context).maybePop(false);
          }
        },
        child: Stack(
          children: [
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 3.5, sigmaY: 3.5),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.08),
                ),
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
                      onTap:
                          () {}, // Prevent backdrop tap from dismissing dialog
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
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.logout_rounded,
                                      color: Colors.redAccent,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    message,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      color: AppColors.textSecondary,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 22),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () {
                                            if (onCancel != null) {
                                              onCancel!();
                                            } else {
                                              Navigator.of(
                                                context,
                                              ).maybePop(false);
                                            }
                                          },
                                          style: OutlinedButton.styleFrom(
                                            backgroundColor: Colors.white
                                                .withValues(alpha: 0.4),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 13,
                                            ),
                                            side: BorderSide(
                                              color: Colors.white.withValues(
                                                alpha: 0.75,
                                              ),
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: Text(
                                            cancelText,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () {
                                            if (onConfirm != null) {
                                              onConfirm!();
                                            } else {
                                              Navigator.of(context).pop(true);
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.redAccent,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 13,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: Text(
                                            confirmText,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
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
