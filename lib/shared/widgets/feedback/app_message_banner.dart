import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/core/constants/app_radius.dart';

enum MessageBannerType { error, warning, info, success }

class AppMessageBanner extends StatelessWidget {
  final String message;
  final MessageBannerType type;
  final VoidCallback? onDismiss;
  final EdgeInsetsGeometry margin;

  const AppMessageBanner({
    super.key,
    required this.message,
    this.type = MessageBannerType.error,
    this.onDismiss,
    this.margin = const EdgeInsets.only(bottom: 16),
  });

  @override
  Widget build(BuildContext context) {
    if (message.isEmpty) {
      return const SizedBox.shrink();
    }

    final config = _getStyleConfig(type);

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: Container(
        margin: margin,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: config.backgroundColor,
          borderRadius: AppRadius.radiusMd,
          border: Border.all(color: config.borderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: config.borderColor.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: config.iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(config.icon, color: config.iconColor, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: config.textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
            ),
            if (onDismiss != null) ...[
              const SizedBox(width: 8),
              InkWell(
                onTap: onDismiss,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: config.textColor.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  _BannerStyleConfig _getStyleConfig(MessageBannerType type) {
    switch (type) {
      case MessageBannerType.error:
        return _BannerStyleConfig(
          backgroundColor: const Color(0xFFFEF2F2),
          borderColor: const Color(0xFFFCA5A5),
          iconBgColor: const Color(0xFFFEE2E2),
          iconColor: AppColors.error,
          textColor: const Color(0xFF991B1B),
          icon: Icons.error_outline_rounded,
        );
      case MessageBannerType.warning:
        return _BannerStyleConfig(
          backgroundColor: const Color(0xFFFFFBEB),
          borderColor: const Color(0xFFFCD34D),
          iconBgColor: const Color(0xFFFEF3C7),
          iconColor: AppColors.warning,
          textColor: const Color(0xFF92400E),
          icon: Icons.warning_amber_rounded,
        );
      case MessageBannerType.info:
        return _BannerStyleConfig(
          backgroundColor: const Color(0xFFEFF6FF),
          borderColor: const Color(0xFF93C5FD),
          iconBgColor: const Color(0xFFDBEAFE),
          iconColor: AppColors.info,
          textColor: const Color(0xFF1E40AF),
          icon: Icons.info_outline_rounded,
        );
      case MessageBannerType.success:
        return _BannerStyleConfig(
          backgroundColor: const Color(0xFFF0FDF4),
          borderColor: const Color(0xFF86EFAC),
          iconBgColor: const Color(0xFFDCFCE7),
          iconColor: AppColors.success,
          textColor: const Color(0xFF166534),
          icon: Icons.check_circle_outline_rounded,
        );
    }
  }
}

class _BannerStyleConfig {
  final Color backgroundColor;
  final Color borderColor;
  final Color iconBgColor;
  final Color iconColor;
  final Color textColor;
  final IconData icon;

  _BannerStyleConfig({
    required this.backgroundColor,
    required this.borderColor,
    required this.iconBgColor,
    required this.iconColor,
    required this.textColor,
    required this.icon,
  });
}
