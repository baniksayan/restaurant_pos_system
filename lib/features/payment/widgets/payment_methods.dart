import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/shared/widgets/layout/skeleton_loader.dart';
import 'package:restaurant_pos_system/shared/widgets/layout/empty_state_widget.dart';

/// Data class representing a payment method definition.
class PaymentMethodData {
  final String value;
  final String title;
  final String subtitle;
  final IconData icon;
  final String? badgeText;
  final Color? badgeColor;

  const PaymentMethodData({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.badgeText,
    this.badgeColor,
  });
}

class PaymentMethods extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  final bool isLoading;
  final bool enabled;
  final List<PaymentMethodData>? customMethods;

  const PaymentMethods({
    super.key,
    required this.selected,
    required this.onChanged,
    this.isLoading = false,
    this.enabled = true,
    this.customMethods,
  });

  static const List<PaymentMethodData> defaultMethods = [
    PaymentMethodData(
      value: 'cash',
      title: 'Cash',
      subtitle: 'Collect cash payment from customer',
      icon: Icons.payments_outlined,
      badgeText: 'Popular',
      badgeColor: AppColors.success,
    ),
    PaymentMethodData(
      value: 'upi',
      title: 'UPI',
      subtitle: 'Ask customer to scan QR & pay',
      icon: Icons.qr_code_2_rounded,
      badgeText: 'Instant QR',
      badgeColor: AppColors.accent,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final methods = customMethods ?? defaultMethods;

    if (isLoading) {
      return _buildSkeleton(theme);
    }

    if (methods.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.payment_outlined,
        title: 'No Payment Methods',
        description: 'No payment methods are currently available.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 20,
              color: cs.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Payment Method',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: methods.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final method = methods[index];
            final isSelected = selected == method.value;

            return _PaymentMethodTile(
              method: method,
              isSelected: isSelected,
              enabled: enabled,
              onTap: () {
                if (enabled && !isSelected) {
                  onChanged(method.value);
                }
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildSkeleton(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SkeletonLoader.circular(size: 20),
            const SizedBox(width: 8),
            SkeletonLoader.rectangular(
              height: 20,
              width: 140,
              borderRadius: BorderRadius.circular(6),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...List.generate(
          3,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SkeletonLoader.rectangular(
              height: 72,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }
}

class _PaymentMethodTile extends StatefulWidget {
  final PaymentMethodData method;
  final bool isSelected;
  final bool enabled;
  final VoidCallback onTap;

  const _PaymentMethodTile({
    required this.method,
    required this.isSelected,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_PaymentMethodTile> createState() => _PaymentMethodTileState();
}

class _PaymentMethodTileState extends State<_PaymentMethodTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.975).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.enabled) {
      _pressController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.enabled) {
      _pressController.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.enabled) {
      _pressController.reverse();
    }
  }

  void _handleTap() {
    if (widget.enabled) {
      HapticFeedback.selectionClick();
      widget.onTap();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isSelected = widget.isSelected;
    final method = widget.method;

    final primaryColor = cs.primary;
    final borderColor =
        isSelected ? primaryColor : const Color(0xFFE2E8F0); // Slate 200
    final backgroundColor =
        isSelected ? primaryColor.withValues(alpha: 0.05) : AppColors.surface;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(scale: _scaleAnimation.value, child: child);
      },
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 1.6 : 1.0,
            ),
            boxShadow:
                isSelected
                    ? [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.10),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                    : [
                      const BoxShadow(
                        color: AppColors.cardShadow,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
          ),
          child: Row(
            children: [
              // Icon Container
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? primaryColor.withValues(alpha: 0.12)
                          : const Color(0xFFF1F5F9), // Slate 100
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  method.icon,
                  color: isSelected ? primaryColor : AppColors.textSecondary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),

              // Title and Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            method.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight:
                                  isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w700,
                              color: AppColors.textPrimary,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (method.badgeText != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: (method.badgeColor ?? primaryColor)
                                  .withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              method.badgeText!,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: method.badgeColor ?? primaryColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      method.subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Selection Radio Indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? primaryColor : Colors.transparent,
                  border: Border.all(
                    color:
                        isSelected
                            ? primaryColor
                            : const Color(0xFFCBD5E1), // Slate 300
                    width: isSelected ? 2.0 : 1.5,
                  ),
                ),
                child: Center(
                  child: AnimatedScale(
                    scale: isSelected ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutBack,
                    child: AnimatedOpacity(
                      opacity: isSelected ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 150),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
