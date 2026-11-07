import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/audio_button.dart';
import '../../../../../core/widgets/duo_button.dart';
import '../../../../../core/widgets/german_text_annotator.dart';
import '../../../../../core/widgets/arabic_text_view.dart';
import 'package:app_lern_deutsch_mobile/core/widgets/mascot_widget.dart';
import '../../../../../domain/models/phrase.dart';

/// Bandeau de retour doux affiché après chaque réponse avec mascotte animée style Duolingo.
class FeedbackSheet extends StatelessWidget {
  final bool isSuccess;
  final Phrase phrase;
  final bool hasMinorTypo;
  final VoidCallback onContinue;
  final VoidCallback? onClose;
  final VoidCallback onPlayAudio;
  final bool isTtsPlaying;

  const FeedbackSheet({
    super.key,
    required this.isSuccess,
    required this.phrase,
    this.hasMinorTypo = false,
    required this.onContinue,
    this.onClose,
    required this.onPlayAudio,
    this.isTtsPlaying = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isSuccess
        ? (isDark ? const Color(0xFF142E1F) : AppColors.primaryLight)
        : (isDark ? AppColors.gentleErrorBackgroundDark : AppColors.gentleErrorBackground);

    final titleColor = isSuccess ? AppColors.primary : AppColors.gentleError;
    final titleText = isSuccess
        ? (hasMinorTypo ? 'Bien ! (petite frappe acceptée)' : 'Excellent ! ✨')
        : 'Presque ! Retiens bien :';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: isSuccess ? AppColors.primary : AppColors.gentleError,
            width: 2.0,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Mascotte interactive style Duolingo (heureux si juste, maladroit si faux)
                MascotWidget(
                  mood: isSuccess ? MascotMood.happy : MascotMood.confused,
                  size: 68,
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    titleText,
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                AudioButton(
                  size: 48,
                  isPlaying: isTtsPlaying,
                  onPressed: onPlayAudio,
                ),
                if (onClose != null) ...[
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 24),
                    tooltip: 'Fermer',
                    color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                    onPressed: onClose,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),

            // Bonne phrase allemande mise en valeur
            GermanTextView(
              text: phrase.de,
              textAlign: TextAlign.start,
              baseStyle: AppTextStyles.germanPhraseSmall(isDark: isDark),
            ),
            const SizedBox(height: 4),

            // Traduction arabe et française
            if (phrase.ar != null && phrase.ar!.isNotEmpty) ...[
              ArabicTextView(
                text: phrase.ar!,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                textAlign: TextAlign.start,
                color: isDark ? AppColors.arabicPrimaryDark : AppColors.arabicPrimaryLight,
              ),
              if (phrase.fr.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  phrase.fr,
                  style: AppTextStyles.translation(isDark: isDark).copyWith(fontSize: 14),
                ),
              ],
            ] else if (phrase.fr.isNotEmpty) ...[
              Text(
                phrase.fr,
                style: AppTextStyles.translation(isDark: isDark),
              ),
            ],

            if (phrase.note != null) ...[
              const SizedBox(height: 8),
              Text(
                '💡 ${phrase.note}',
                style: AppTextStyles.caption(isDark: isDark),
              ),
            ],

            const SizedBox(height: 20),

            // Bouton 3D Duolingo Continuer
            DuoButton(
              label: 'Continuer',
              icon: Icons.arrow_forward_rounded,
              variant: isSuccess ? DuoButtonVariant.primary : DuoButtonVariant.secondary,
              customColor: isSuccess ? null : AppColors.gentleError,
              customShadowColor: isSuccess ? null : const Color(0xFFD97706),
              onPressed: onContinue,
            ),
          ],
        ),
      ),
    );
  }
}
