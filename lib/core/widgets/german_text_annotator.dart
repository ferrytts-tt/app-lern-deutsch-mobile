import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/german_verb_detector.dart';

/// Affiche une phrase allemande avec mise en valeur automatique :
/// 1. Des articles définis (der/die/das)
///    - der / den / dem / des (masculin) : Bleu (#2F80ED)
///    - die / der (féminin) : Jaune foncé (#E0A800)
///    - das / dem / des (neutre) : Vert (#2FA866)
/// 2. Des verbes (action & pivot grammatical) :
///    - Verbe coloré en Corail / Orange (#FF8A65 en sombre / #E65100 en clair)
class GermanTextView extends StatelessWidget {
  final String text;
  final TextStyle? baseStyle;
  final TextAlign textAlign;
  final bool enableArticleColoring;
  final bool enableVerbColoring;

  const GermanTextView({
    super.key,
    required this.text,
    this.baseStyle,
    this.textAlign = TextAlign.center,
    this.enableArticleColoring = true,
    this.enableVerbColoring = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultStyle = baseStyle ?? AppTextStyles.germanPhrase(isDark: isDark);

    if (!enableArticleColoring && !enableVerbColoring) {
      return Text(text, style: defaultStyle, textAlign: textAlign);
    }

    final spans = _buildSpans(text, defaultStyle, isDark);
    return Text.rich(
      TextSpan(children: spans),
      textAlign: textAlign,
    );
  }

  List<TextSpan> _buildSpans(String sentence, TextStyle baseStyle, bool isDark) {
    // Regex pour découper les mots tout en préservant exactement les espaces
    final words = sentence.split(RegExp(r'(?<=\s)|(?=\s)'));
    final spans = <TextSpan>[];

    for (final word in words) {
      // Nettoyer les ponctuations pour l'analyse grammaticale
      final clean = word
          .replaceAll(RegExp(r'^[«»"“„(\[\{]+|[»"”\)\]\}.,!?:;]+$'), '')
          .trim()
          .toLowerCase();

      Color? articleColor;

      if (enableArticleColoring) {
        if (clean == 'der' || clean == 'den' || clean == 'dem' || clean == 'des') {
          articleColor = AppColors.articleDer;
        } else if (clean == 'die') {
          articleColor = AppColors.articleDie;
        } else if (clean == 'das') {
          articleColor = AppColors.articleDas;
        }
      }

      if (articleColor != null) {
        spans.add(
          TextSpan(
            text: word,
            style: baseStyle.copyWith(
              color: articleColor,
              fontWeight: FontWeight.w900,
            ),
          ),
        );
      } else if (enableVerbColoring && GermanVerbDetector.isVerb(word)) {
        final verbColor = isDark ? AppColors.verbColorDark : AppColors.verbColorLight;
        spans.add(
          TextSpan(
            text: word,
            style: baseStyle.copyWith(
              color: verbColor,
              fontWeight: FontWeight.w900,
            ),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: word,
            style: baseStyle,
          ),
        );
      }
    }

    return spans;
  }
}
