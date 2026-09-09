import 'dart:ui';
import 'package:flutter/material.dart';

/// Glassmorphic modal presentation shell providing frosted glass background blur,
/// rounded frosted card container, and touch outside to dismiss.
class AppGlassDialog extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const AppGlassDialog({
    super.key,
    required this.child,
    this.maxWidth = 340,
    this.padding = const EdgeInsets.fromLTRB(20, 24, 20, 20),
    this.borderRadius = 24.0,
  });

  /// Shows the glass dialog with standard fade & scale transitions.
  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    double maxWidth = 340,
    EdgeInsetsGeometry padding = const EdgeInsets.fromLTRB(20, 24, 20, 20),
    double borderRadius = 24.0,
    bool barrierDismissible = true,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierLabel: 'GlassDialog',
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return AppGlassDialog(
          maxWidth: maxWidth,
          padding: padding,
          borderRadius: borderRadius,
          child: child,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, dialogChild) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: dialogChild,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).maybePop(),
        child: Stack(
          children: [
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 3.5, sigmaY: 3.5),
                child: Container(color: Colors.black.withValues(alpha: 0.08)),
              ),
            ),
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: GestureDetector(
                    onTap: () {}, // Block tap propagation
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(borderRadius),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          constraints: BoxConstraints(maxWidth: maxWidth),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.52),
                            borderRadius: BorderRadius.circular(borderRadius),
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
                          child: Padding(padding: padding, child: child),
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
