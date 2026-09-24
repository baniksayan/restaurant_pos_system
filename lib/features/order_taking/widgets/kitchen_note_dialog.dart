import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/core/utils/haptic_helper.dart';

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

  static const List<String> _quickSuggestions = [
    'Serve together',
    'No onions',
    'Less spicy',
    'Extra spicy',
    'Kids meal first',
    'Allergies at table',
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNote);
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

  void _applySuggestion(String suggestion) async {
    await HapticHelper.triggerFeedback();
    final current = _controller.text.trim();
    if (current.isEmpty) {
      _controller.text = suggestion;
    } else if (!current.toLowerCase().contains(suggestion.toLowerCase())) {
      _controller.text = '$current, $suggestion';
    }
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: _controller.text.length),
    );
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
            Navigator.of(context).pop('');
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
                                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Multi-line Text Area
                                      _buildNoteInputField(isDark),
                                      const SizedBox(height: 14),

                                      // Quick Suggestion Chips
                                      _buildSuggestionsSection(isDark),
                                      const SizedBox(height: 16),

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

          // Close button
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            onPressed: () async {
              await HapticHelper.triggerFeedback();
              if (context.mounted) {
                Navigator.of(context).pop('');
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

  Widget _buildNoteInputField(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B).withValues(alpha: 0.45)
            : Colors.white.withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(18),
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
      child: Column(
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            maxLines: 3,
            minLines: 2,
            textCapitalization: TextCapitalization.sentences,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.textPrimary,
              height: 1.35,
            ),
            decoration: InputDecoration(
              hintText: 'e.g. serve together, no onions across the table, allergy alert...',
              hintStyle: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFF64748B) : AppColors.textHint,
                height: 1.35,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Icon(
                  Icons.edit_note_rounded,
                  size: 22,
                  color: isDark ? const Color(0xFF94A3B8) : AppColors.accent,
                ),
              ),
              suffixIcon: _controller.text.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 16),
                        color: isDark ? const Color(0xFF94A3B8) : AppColors.textHint,
                        onPressed: () {
                          _controller.clear();
                        },
                      ),
                    )
                  : null,
              filled: false,
              isDense: true,
              contentPadding: const EdgeInsets.fromLTRB(12, 14, 14, 14),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: AppColors.accent, width: 1.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.flash_on_rounded,
              size: 13,
              color: isDark ? const Color(0xFF94A3B8) : AppColors.accent,
            ),
            const SizedBox(width: 5),
            Text(
              'QUICK SUGGESTIONS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _quickSuggestions.map((suggestion) {
            final isIncluded = _controller.text
                .toLowerCase()
                .contains(suggestion.toLowerCase());

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _applySuggestion(suggestion),
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isIncluded
                        ? AppColors.accent.withValues(alpha: isDark ? 0.25 : 0.15)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.white.withValues(alpha: 0.60)),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isIncluded
                          ? AppColors.accent.withValues(alpha: 0.60)
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.12)
                              : Colors.white.withValues(alpha: 0.90)),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isIncluded) ...[
                        const Icon(
                          Icons.check_rounded,
                          size: 12,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        suggestion,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight:
                              isIncluded ? FontWeight.w700 : FontWeight.w500,
                          color: isIncluded
                              ? AppColors.accent
                              : (isDark
                                  ? const Color(0xFFCBD5E1)
                                  : AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
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
          // Skip Button
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 46,
              child: OutlinedButton(
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
                  foregroundColor:
                      isDark ? const Color(0xFFCBD5E1) : AppColors.textSecondary,
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
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Add & Send Button
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await HapticHelper.triggerFeedback();
                  if (!context.mounted) return;
                  Navigator.of(context).pop(_controller.text.trim());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 3,
                  shadowColor: AppColors.primary.withValues(alpha: 0.35),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
                icon: const Icon(Icons.send_rounded, size: 16),
                label: Text(
                  _controller.text.trim().isEmpty ? 'Send KOT' : 'Add & Send',
                  style: const TextStyle(
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
