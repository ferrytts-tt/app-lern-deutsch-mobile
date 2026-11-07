import 'package:flutter/material.dart';
import '../localization/app_languages.dart';
import '../theme/app_colors.dart';
import '../../domain/models/phrase.dart';
import 'arabic_text_view.dart';

/// Carte universelle affichant la traduction principale (Langue 1)
/// et optionnellement la traduction secondaire (Langue 2).
class MultiLanguageTranslationCard extends StatelessWidget {
  final Phrase phrase;
  final String primaryLanguage;
  final String? secondaryLanguage;
  final double primaryFontSize;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const MultiLanguageTranslationCard({
    super.key,
    required this.phrase,
    this.primaryLanguage = 'fr',
    this.secondaryLanguage,
    this.primaryFontSize = 18,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final primaryTrans = phrase.getTranslation(primaryLanguage);
    final secondaryTrans = secondaryLanguage != null && secondaryLanguage!.isNotEmpty
        ? phrase.getTranslation(secondaryLanguage!)
        : null;

    final primaryMeta = AppLanguage.fromCode(primaryLanguage);
    final secondaryMeta = secondaryLanguage != null ? AppLanguage.fromCode(secondaryLanguage!) : null;

    final isPrimaryArabic = primaryMeta.isRtl || primaryLanguage == 'ar';
    final isSecondaryArabic = secondaryMeta != null && (secondaryMeta.isRtl || secondaryLanguage == 'ar');

    // Si la langue principale est l'arabe, utiliser le style dédié ElegantArabicCard
    if (isPrimaryArabic && primaryTrans.isNotEmpty) {
      return ElegantArabicCard(
        arabicText: primaryTrans,
        frenchSubtitle: (secondaryTrans != null && secondaryTrans.isNotEmpty) ? secondaryTrans : null,
        arabicFontSize: 21,
        onTap: onTap,
        padding: padding,
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Badge Langue principale
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(primaryMeta.flag, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  primaryMeta.name,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Texte de la traduction principale
            Text(
              primaryTrans.isNotEmpty ? primaryTrans : phrase.fr,
              style: TextStyle(
                fontSize: primaryFontSize,
                fontWeight: FontWeight.bold,
                height: 1.35,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
              textAlign: TextAlign.center,
            ),

            // Sous-titre secondaire (si activé)
            if (secondaryTrans != null && secondaryTrans.isNotEmpty && secondaryTrans != primaryTrans) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (secondaryMeta != null) ...[
                      Text(secondaryMeta.flag, style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: isSecondaryArabic
                          ? ArabicTextView(
                              text: secondaryTrans,
                              fontSize: 13,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              textAlign: TextAlign.center,
                              withBackground: false,
                            )
                          : Text(
                              secondaryTrans,
                              style: TextStyle(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                              textAlign: TextAlign.center,
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
