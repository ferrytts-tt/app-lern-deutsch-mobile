import 'package:flutter/material.dart';
import '../theme/app_text_styles.dart';

/// Détecte si une chaîne contient des caractères arabes.
bool isArabicString(String? text) {
  if (text == null || text.isEmpty) return false;
  return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
}

/// Widget d'affichage de texte arabe raffiné avec gestion native du RTL,
/// typographie élégante basée sur la police Cairo et fond noble sophistiqué (sans icône superflue).
class ArabicTextView extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final Color? color;
  final TextAlign textAlign;
  final double height;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool withBackground;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final bool showBadge;

  const ArabicTextView({
    super.key,
    required this.text,
    this.fontSize = 15,
    this.fontWeight = FontWeight.w700,
    this.color,
    this.textAlign = TextAlign.start,
    this.height = 1.5,
    this.maxLines,
    this.overflow,
    this.withBackground = true,
    this.padding,
    this.borderRadius,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final effectiveColor = color ?? (isDark ? const Color(0xFF6EE7B7) : const Color(0xFF065F46));

    final textWidget = Directionality(
      textDirection: TextDirection.rtl,
      child: Text(
        text,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
        style: AppTextStyles.arabicPhrase(
          isDark: isDark,
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: effectiveColor,
        ).copyWith(height: height),
      ),
    );

    if (!withBackground) {
      return textWidget;
    }

    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF0F261E).withValues(alpha: 0.85),
                  const Color(0xFF143328).withValues(alpha: 0.85),
                ]
              : [
                  const Color(0xFFF0FDF4),
                  const Color(0xFFE8F9EE),
                ],
        ),
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? const Color(0xFF10B981).withValues(alpha: 0.28)
              : const Color(0xFF059669).withValues(alpha: 0.20),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.08 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: textWidget,
    );
  }
}

/// Carte élégante pour la traduction arabe, harmonieuse avec l'allemand et le français.
///
/// Intègre un dégradé subtil, une bordure soignée et une typographie arabe épurée.
class ElegantArabicCard extends StatelessWidget {
  final String arabicText;
  final String? frenchSubtitle;
  final VoidCallback? onTap;
  final double arabicFontSize;
  final EdgeInsetsGeometry padding;

  const ElegantArabicCard({
    super.key,
    required this.arabicText,
    this.frenchSubtitle,
    this.onTap,
    this.arabicFontSize = 21,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardContent = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF0D281E),
                  const Color(0xFF133829),
                ]
              : [
                  const Color(0xFFF0FDF4),
                  const Color(0xFFE6F7EC),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? const Color(0xFF10B981).withValues(alpha: 0.35)
              : const Color(0xFF059669).withValues(alpha: 0.25),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF10B981)).withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // En-tête discret "Traduction arabe"
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF059669).withValues(alpha: 0.25)
                      : const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'العربية',
                  style: AppTextStyles.arabicCaption(
                    isDark: isDark,
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Texte en arabe calligraphique et élégant
          ArabicTextView(
            text: arabicText,
            fontSize: arabicFontSize,
            fontWeight: FontWeight.w700,
            textAlign: TextAlign.center,
            withBackground: false,
          ),

          // Sous-titre français si présent
          if (frenchSubtitle != null && frenchSubtitle!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
                    width: 0.8,
                  ),
                ),
              ),
              child: Text(
                frenchSubtitle!,
                style: AppTextStyles.translation(isDark: isDark).copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: cardContent,
      );
    }

    return cardContent;
  }
}
