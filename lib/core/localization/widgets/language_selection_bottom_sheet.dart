import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../utils/haptic_helper.dart';
import '../extensions/localization_extension.dart';
import '../models/app_language.dart';
import '../app_localization_service.dart';

class LanguageSelectionBottomSheet extends StatelessWidget {
  const LanguageSelectionBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const LanguageSelectionBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final localeProvider = context.watchLocaleProvider;
    final currentCode = localeProvider?.locale.languageCode ??
        context.currentLocale.languageCode;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.translate_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.drawer.selectLanguage,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.drawer.chooseLanguage,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                splashRadius: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Options
          ...AppLanguage.values.map((lang) {
            final isSelected = lang.code == currentCode;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    HapticHelper.triggerFeedback();
                    final navigator = Navigator.of(context);
                    navigator.pop();
                    if (localeProvider != null) {
                      await localeProvider.setLanguage(lang);
                    } else {
                      LocalizationService.instance.setLocale(lang.locale);
                    }
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.08)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.grey.shade200,
                        width: isSelected ? 1.8 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: isSelected
                              ? AppColors.primary
                              : Colors.grey.shade400,
                          size: 22,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lang.nativeName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                                ),
                              ),
                              if (lang.nativeName != lang.englishName)
                                Text(
                                  lang.englishName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Active',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
