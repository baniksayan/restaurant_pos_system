import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/core/utils/haptic_helper.dart';

/// What a new party on a table is opened with.
///
/// A table seats several groups at once, each running its own order and its
/// own bill. The guest count is what tells them apart in the order list, and
/// what makes "3 of 8 seated" possible on the table card.
class PartyDetails {
  final int adults;
  final int children;
  final String customerName;

  const PartyDetails({
    required this.adults,
    this.children = 0,
    this.customerName = '',
  });

  int get totalGuests => adults + children;
}

/// Asks for party size (and optionally a name) before opening a new order.
/// Styled with a premium frosted glassmorphic UI, responsive counters,
/// and instant seat-capacity feedback.
class AddPartyDialog extends StatefulWidget {
  final String tableName;

  /// Seats the table has, when known, so the sheet can warn about overbooking
  /// rather than block it. Zero means "unknown", and no warning is shown.
  final int capacity;

  /// Guests already seated across the existing parties, when known.
  final int seatedGuests;

  const AddPartyDialog({
    super.key,
    required this.tableName,
    this.capacity = 0,
    this.seatedGuests = 0,
  });

  /// Opens the dialog with a smooth fade-and-scale glassmorphism transition.
  static Future<PartyDetails?> show(
    BuildContext context, {
    required String tableName,
    int capacity = 0,
    int seatedGuests = 0,
  }) {
    return showGeneralDialog<PartyDetails>(
      context: context,
      barrierLabel: 'AddPartyDialog',
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return AddPartyDialog(
          tableName: tableName,
          capacity: capacity,
          seatedGuests: seatedGuests,
        );
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
  State<AddPartyDialog> createState() => _AddPartyDialogState();
}

class _AddPartyDialogState extends State<AddPartyDialog> {
  int _adults = 1;
  int _children = 0;
  final TextEditingController _nameController = TextEditingController();

  /// Seats left once this party is added, or null when capacity is unknown.
  int? get _remainingSeats {
    if (widget.capacity <= 0) return null;
    return widget.capacity - widget.seatedGuests - (_adults + _children);
  }

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onNameChanged);
  }

  void _onNameChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);
    final isTablet = size.width >= 600;

    final remaining = _remainingSeats;
    final overCapacity = remaining != null && remaining < 0;

    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        },
        child: Stack(
          children: [
            // Fullscreen ambient backdrop blur & dimming
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: Container(
                  color:
                      isDark
                          ? Colors.black.withValues(alpha: 0.35)
                          : Colors.black.withValues(alpha: 0.12),
                ),
              ),
            ),

            // Centered Glassmorphic Modal Card
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  child: GestureDetector(
                    onTap: () {}, // Prevent taps inside the card from closing
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
                              colors:
                                  isDark
                                      ? [
                                        const Color(
                                          0xFF0F172A,
                                        ).withValues(alpha: 0.70),
                                        const Color(
                                          0xFF1E293B,
                                        ).withValues(alpha: 0.60),
                                      ]
                                      : [
                                        Colors.white.withValues(alpha: 0.80),
                                        Colors.white.withValues(alpha: 0.60),
                                      ],
                            ),
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(
                              color:
                                  isDark
                                      ? Colors.white.withValues(alpha: 0.18)
                                      : Colors.white.withValues(alpha: 0.85),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(
                                  alpha: 0.08,
                                ),
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

                              // Main Dialog Body
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  18,
                                  20,
                                  16,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Section Title: Party Size
                                    _buildSectionLabel(
                                      'PARTY SIZE',
                                      Icons.group_outlined,
                                      isDark,
                                    ),
                                    const SizedBox(height: 10),

                                    // Adults Stepper Card
                                    _buildCounterCard(
                                      title: 'Adults',
                                      subtitle: 'Standard / 12+ yrs',
                                      icon: Icons.person_rounded,
                                      iconColor: AppColors.primary,
                                      value: _adults,
                                      min: 1,
                                      isDark: isDark,
                                      onChanged:
                                          (v) => setState(() => _adults = v),
                                    ),
                                    const SizedBox(height: 10),

                                    // Children Stepper Card
                                    _buildCounterCard(
                                      title: 'Children',
                                      subtitle: 'Under 12 yrs',
                                      icon: Icons.child_care_rounded,
                                      iconColor: AppColors.accent,
                                      value: _children,
                                      min: 0,
                                      isDark: isDark,
                                      onChanged:
                                          (v) => setState(() => _children = v),
                                    ),
                                    const SizedBox(height: 18),

                                    // Section Title: Customer Info
                                    _buildSectionLabel(
                                      'CUSTOMER DETAILS (OPTIONAL)',
                                      Icons.badge_outlined,
                                      isDark,
                                    ),
                                    const SizedBox(height: 10),

                                    // Glass Customer Name Input
                                    _buildNameInput(isDark),
                                    const SizedBox(height: 16),

                                    // Live Capacity & Status Banner
                                    _buildCapacityBanner(
                                      remaining: remaining,
                                      overCapacity: overCapacity,
                                      isDark: isDark,
                                    ),
                                  ],
                                ),
                              ),

                              // Glass Footer Actions
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
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(
          icon,
          size: 13,
          color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
      decoration: BoxDecoration(
        color:
            isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.white.withValues(alpha: 0.35),
        border: Border(
          bottom: BorderSide(
            color:
                isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : Colors.white.withValues(alpha: 0.60),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Header Icon Badge
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(11),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.30),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.groups_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Title & Table Name Chip
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'New Party',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.22),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.table_restaurant_rounded,
                            size: 12,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.tableName,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                Navigator.of(context).pop();
              }
            },
            style: IconButton.styleFrom(
              backgroundColor:
                  isDark
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

  Widget _buildCounterCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required int value,
    required int min,
    required bool isDark,
    required ValueChanged<int> onChanged,
  }) {
    final canDecrement = value > min;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color:
            isDark
                ? const Color(0xFF1E293B).withValues(alpha: 0.45)
                : Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isDark
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
      child: Row(
        children: [
          // Icon Box
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: iconColor.withValues(alpha: 0.22),
                width: 1,
              ),
            ),
            child: Icon(icon, color: iconColor, size: 19),
          ),
          const SizedBox(width: 12),

          // Labels
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color:
                        isDark ? const Color(0xFF94A3B8) : AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),

          // Stepper Controls
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Decrement Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap:
                      canDecrement
                          ? () async {
                            await HapticHelper.triggerFeedback();
                            onChanged(value - 1);
                          }
                          : null,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color:
                          canDecrement
                              ? (isDark
                                  ? Colors.white.withValues(alpha: 0.10)
                                  : Colors.white.withValues(alpha: 0.85))
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.04)
                                  : Colors.black.withValues(alpha: 0.03)),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color:
                            canDecrement
                                ? (isDark
                                    ? Colors.white.withValues(alpha: 0.18)
                                    : Colors.white)
                                : (isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : Colors.black.withValues(alpha: 0.06)),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.remove_rounded,
                      size: 16,
                      color:
                          canDecrement
                              ? (isDark ? Colors.white : AppColors.textPrimary)
                              : (isDark
                                  ? const Color(0xFF475569)
                                  : AppColors.textHint),
                    ),
                  ),
                ),
              ),

              // Counter Display
              SizedBox(
                width: 38,
                child: Text(
                  '$value',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),

              // Increment Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    await HapticHelper.triggerFeedback();
                    onChanged(value + 1);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primary, AppColors.primaryDark],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.30),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNameInput(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color:
            isDark
                ? const Color(0xFF1E293B).withValues(alpha: 0.45)
                : Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isDark
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
        controller: _nameController,
        textCapitalization: TextCapitalization.words,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'Customer name (e.g. John Doe)',
          hintStyle: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFF64748B) : AppColors.textHint,
          ),
          prefixIcon: Icon(
            Icons.person_outline_rounded,
            size: 20,
            color: isDark ? const Color(0xFF94A3B8) : AppColors.primary,
          ),
          suffixIcon:
              _nameController.text.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 16),
                    color:
                        isDark ? const Color(0xFF94A3B8) : AppColors.textHint,
                    onPressed: () {
                      _nameController.clear();
                    },
                  )
                  : null,
          filled: false,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
          ),
        ),
      ),
    );
  }

  Widget _buildCapacityBanner({
    required int? remaining,
    required bool overCapacity,
    required bool isDark,
  }) {
    final totalParty = _adults + _children;

    if (remaining != null) {
      final bannerColor = overCapacity ? AppColors.warning : AppColors.primary;
      final bgColor =
          overCapacity
              ? (isDark
                  ? AppColors.warning.withValues(alpha: 0.15)
                  : const Color(0xFFFEF3C7).withValues(alpha: 0.70))
              : (isDark
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : AppColors.primary.withValues(alpha: 0.08));

      final borderColor =
          overCapacity
              ? AppColors.warning.withValues(alpha: 0.35)
              : AppColors.primary.withValues(alpha: 0.20);

      final message =
          overCapacity
              ? '${widget.seatedGuests + totalParty} guests on a '
                  '${widget.capacity}-seat table — over by ${-remaining}'
              : widget.seatedGuests > 0
              ? '${widget.seatedGuests} seated · '
                  '$remaining ${remaining == 1 ? 'seat' : 'seats'} left after this party'
              : '$remaining of ${widget.capacity} ${widget.capacity == 1 ? 'seat' : 'seats'} available';

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: Row(
          children: [
            Icon(
              overCapacity
                  ? Icons.warning_amber_rounded
                  : Icons.event_seat_rounded,
              size: 16,
              color: bannerColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color:
                      isDark && !overCapacity
                          ? const Color(0xFFCBD5E1)
                          : (overCapacity
                              ? const Color(0xFFB45309)
                              : AppColors.textPrimary),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color:
                    isDark
                        ? Colors.white.withValues(alpha: 0.10)
                        : Colors.white.withValues(alpha: 0.80),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Total: $totalParty',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Default summary card when capacity is unknown
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color:
            isDark
                ? Colors.white.withValues(alpha: 0.05)
                : AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color:
              isDark
                  ? Colors.white.withValues(alpha: 0.10)
                  : AppColors.primary.withValues(alpha: 0.15),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Party of $totalParty ($_adults Adult${_adults == 1 ? '' : 's'}${_children > 0 ? ', $_children Child${_children == 1 ? '' : 'ren'}' : ''})',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFCBD5E1) : AppColors.textPrimary,
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
        color:
            isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.white.withValues(alpha: 0.35),
        border: Border(
          top: BorderSide(
            color:
                isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : Colors.white.withValues(alpha: 0.60),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Cancel Button
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 46,
              child: OutlinedButton(
                onPressed: () async {
                  await HapticHelper.triggerFeedback();
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor:
                      isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.white.withValues(alpha: 0.50),
                  foregroundColor:
                      isDark
                          ? const Color(0xFFCBD5E1)
                          : AppColors.textSecondary,
                  side: BorderSide(
                    color:
                        isDark
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
                  'Cancel',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Start Order Button
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await HapticHelper.triggerFeedback();
                  if (!context.mounted) return;
                  Navigator.of(context).pop(
                    PartyDetails(
                      adults: _adults,
                      children: _children,
                      customerName: _nameController.text.trim(),
                    ),
                  );
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
                icon: const Icon(Icons.arrow_forward_rounded, size: 17),
                label: const Text(
                  'Start Order',
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
