import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/core/utils/haptic_helper.dart';
import 'package:restaurant_pos_system/core/utils/no_emoji_formatter.dart';

/// Modal dialog for capturing an order-level note for the kitchen (KOT).
///
/// Provides a frosted glassmorphic UI, quick suggestion chips for fast input,
/// and returns the note string or empty string on skip/dismissal.
class KitchenNoteDialog extends StatefulWidget {
  final String initialNote;

  const KitchenNoteDialog({super.key, this.initialNote = ''});

  /// Shows the glassmorphic kitchen note dialog with smooth scale/fade transitions.
  static Future<String?> show(
    BuildContext context, {
    String initialNote = '',
  }) {
    return showGeneralDialog<String>(
      context: context,
      barrierLabel: 'KitchenNoteDialog',
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return KitchenNoteDialog(initialNote: initialNote);
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<KitchenNoteDialog> createState() => _KitchenNoteDialogState();
}

class _KitchenNoteDialogState extends State<KitchenNoteDialog> {
  late final TextEditingController _controller;

  static const int _maxCharacters = 75;

  @override
  void initState() {
    super.initState();
    final clean = removeEmojis(widget.initialNote);
    final initial = clean.length > _maxCharacters
        ? clean.substring(0, _maxCharacters)
        : clean;
    _controller = TextEditingController(text: initial);
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);
    final isTablet = size.width >= 600;

    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop(null);
          }
        },
        child: Stack(
          children: [
            // Fullscreen ambient backdrop blur
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: Container(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.35)
                      : Colors.black.withValues(alpha: 0.12),
                ),
              ),
            ),

            // Modal card container
            AnimatedPadding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOutCubic,
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    child: GestureDetector(
                      onTap: () {}, // Prevent backdrop tap from dismissing
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(26),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                          child: Container(
                            width: isTablet ? 430 : size.width * 0.90,
                            constraints: const BoxConstraints(maxWidth: 440),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: isDark
                                    ? [
                                        const Color(0xFF0F172A).withValues(alpha: 0.70),
                                        const Color(0xFF1E293B).withValues(alpha: 0.60),
                                      ]
                                    : [
                                        Colors.white.withValues(alpha: 0.82),
                                        Colors.white.withValues(alpha: 0.62),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(26),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.18)
                                    : Colors.white.withValues(alpha: 0.85),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accent.withValues(alpha: 0.08),
                                  blurRadius: 28,
                                  offset: const Offset(0, 10),
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: isDark ? 0.35 : 0.08,
                                  ),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Glass Header
                                _buildHeader(context, isDark),

                                // Main Content Body
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Section Header with Counter Badge
                                      _buildNoteHeader(isDark),
                                      const SizedBox(height: 8),

                                      // Multi-line Text Area
                                      _buildNoteInputField(isDark),
                                      const SizedBox(height: 14),

                                      // Info Callout Banner
                                      _buildInfoCallout(isDark),
                                    ],
                                  ),
                                ),

                                // Action Buttons Footer
                                _buildFooter(context, isDark),
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
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.white.withValues(alpha: 0.35),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.10)
                : Colors.white.withValues(alpha: 0.60),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Header Badge
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.accent, Color(0xFFEA580C)],
              ),
              borderRadius: BorderRadius.circular(11),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.30),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.soup_kitchen_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Title and Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Note for Kitchen',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Instructions for the entire ticket',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Close button (Cancels and returns null)
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            onPressed: () async {
              await HapticHelper.triggerFeedback();
              if (context.mounted) {
                Navigator.of(context).pop(null);
              }
            },
            style: IconButton.styleFrom(
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.05),
              foregroundColor:
                  isDark ? const Color(0xFFCBD5E1) : AppColors.textSecondary,
              padding: const EdgeInsets.all(6),
              minimumSize: const Size(32, 32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteHeader(bool isDark) {
    final currentLength = _controller.text.length;
    final isNearLimit = currentLength >= _maxCharacters;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.edit_note_rounded,
              size: 15,
              color: isDark ? const Color(0xFF94A3B8) : AppColors.accent,
            ),
            const SizedBox(width: 5),
            Text(
              'KITCHEN NOTE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: isNearLimit
                ? AppColors.warning.withValues(alpha: isDark ? 0.25 : 0.15)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04)),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isNearLimit
                  ? AppColors.warning.withValues(alpha: 0.50)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.10)
                      : Colors.black.withValues(alpha: 0.06)),
              width: 0.8,
            ),
          ),
          child: Text(
            '$currentLength/$_maxCharacters',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isNearLimit
                  ? AppColors.warning
                  : (isDark
                      ? const Color(0xFF94A3B8)
                      : AppColors.textSecondary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoteInputField(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B).withValues(alpha: 0.45)
            : Colors.white.withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.85),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: 3,
        minLines: 2,
        maxLength: _maxCharacters,
        inputFormatters: [
          LengthLimitingTextInputFormatter(_maxCharacters),
          noEmojiFormatter,
        ],
        buildCounter: (
          context, {
          required currentLength,
          required isFocused,
          maxLength,
        }) =>
            null,
        textCapitalization: TextCapitalization.sentences,
        style: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : AppColors.textPrimary,
          height: 1.35,
        ),
        decoration: InputDecoration(
          hintText: 'e.g. serve together, no onions, extra spicy...',
          hintStyle: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFF64748B) : AppColors.textHint,
            height: 1.35,
          ),
          counterText: '',
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 16),
                  color: isDark ? const Color(0xFF94A3B8) : AppColors.textHint,
                  splashRadius: 16,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                  onPressed: () {
                    _controller.clear();
                  },
                )
              : null,
          suffixIconConstraints:
              const BoxConstraints(minWidth: 36, minHeight: 36),
          filled: false,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCallout(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.primary.withValues(alpha: 0.15),
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.print_rounded,
              size: 15,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'This note is printed at the top of the KOT and displayed on the Chef screen.',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFFCBD5E1) : AppColors.textSecondary,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool isDark) {
    final hasText = _controller.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.white.withValues(alpha: 0.35),
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.10)
                : Colors.white.withValues(alpha: 0.60),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Skip Button - Highlighted as primary action when text is empty
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 46,
              child: hasText
                  ? OutlinedButton(
                      onPressed: () async {
                        await HapticHelper.triggerFeedback();
                        if (context.mounted) {
                          Navigator.of(context).pop('');
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.white.withValues(alpha: 0.50),
                        foregroundColor: isDark
                            ? const Color(0xFFCBD5E1)
                            : AppColors.textSecondary,
                        side: BorderSide(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.15)
                              : const Color(0xFFCBD5E1),
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: () async {
                        await HapticHelper.triggerFeedback();
                        if (context.mounted) {
                          Navigator.of(context).pop('');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shadowColor: AppColors.primary.withValues(alpha: 0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),

          // Add & Send Button - Disabled when text is empty, highlighted when text entered
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 46,
              child: ElevatedButton(
                onPressed: hasText
                    ? () async {
                        await HapticHelper.triggerFeedback();
                        if (!context.mounted) return;
                        Navigator.of(context).pop(_controller.text.trim());
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFFE2E8F0),
                  disabledForegroundColor: isDark
                      ? const Color(0xFF64748B)
                      : const Color(0xFF94A3B8),
                  elevation: hasText ? 3 : 0,
                  shadowColor: AppColors.primary.withValues(alpha: 0.35),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
                child: const Text(
                  'Send',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
