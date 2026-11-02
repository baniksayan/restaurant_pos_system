import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../utils/haptic_helper.dart';
import '../extensions/localization_extension.dart';
import '../models/app_language.dart';
import '../app_localization_service.dart';

class LanguageSelectionDialog extends StatelessWidget {
  const LanguageSelectionDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const LanguageSelectionDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final localeProvider = context.watchLocaleProvider;
    final currentCode = localeProvider?.locale.languageCode ??
        context.currentLocale.languageCode;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 12,
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(22),
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Close Button
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
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.drawer.selectLanguage,
                        style: const TextStyle(
                          fontSize: 19,
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
            const SizedBox(height: 18),
            const Divider(height: 1),
            const SizedBox(height: 14),

            // Language Options
            ...AppLanguage.values.map((lang) {
              final isSelected = lang.code == currentCode;
              return _LanguageTile(
                language: lang,
                isSelected: isSelected,
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
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final AppLanguage language;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.language,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.grey.shade200,
                width: isSelected ? 1.8 : 1.0,
              ),
            ),
            child: Row(
              children: [
                // Radio/Check circle
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.grey.shade400,
                      width: 2,
                    ),
                    color: isSelected ? AppColors.primary : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          size: 14,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                // Native and English Name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        language.nativeName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                      if (language.nativeName != language.englishName)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            language.englishName,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Badge for selected
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
  }
}
