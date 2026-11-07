import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/spoken_phrase_card.dart';
import '../../../../domain/engine/srs_engine.dart';
import '../../../../domain/models/phrase.dart';

/// Carte pour les phrases d'échauffement ou de révision avec auto-évaluation bienveillante.
class ReviewCard extends StatefulWidget {
  final Phrase phrase;
  final bool isWarmup;
  final bool isTtsPlaying;
  final VoidCallback onPlayNormal;
  final Function(ReviewOutcome) onAnswer;

  final String preferredTranslationLanguage;

  const ReviewCard({
    super.key,
    required this.phrase,
    this.isWarmup = false,
    this.preferredTranslationLanguage = 'fr',
    required this.isTtsPlaying,
    required this.onPlayNormal,
    required this.onAnswer,
  });

  @override
  State<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<ReviewCard> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Column(
        children: [
          SpokenPhraseCard(
            phrase: widget.phrase,
            preferredTranslationLanguage: widget.preferredTranslationLanguage,
            onPlayNormal: widget.onPlayNormal,
            onTooEasy: () => widget.onAnswer(ReviewOutcome.easy),
            bottomAction: Column(
              children: [
                const SizedBox(height: 14),
                Text(
                  'Comment as-tu trouvé cette phrase ?',
                  style: AppTextStyles.bodyMedium(isDark: isDark).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    // Difficile (Erreur douce / consolidation)
                    Expanded(
                      child: _EvalButton(
                        label: 'Difficile',
                        color: AppColors.secondary,
                        onTap: () => widget.onAnswer(ReviewOutcome.mistake),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Moyen (Succès standard)
                    Expanded(
                      child: _EvalButton(
                        label: 'Bien',
                        color: AppColors.accentDark,
                        onTap: () => widget.onAnswer(ReviewOutcome.success),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Facile (Saut de niveau)
                    Expanded(
                      child: _EvalButton(
                        label: 'Facile !',
                        color: AppColors.primary,
                        onTap: () => widget.onAnswer(ReviewOutcome.easy),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _EvalButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _EvalButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.15),
        foregroundColor: color,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: color, width: 1.5),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: color,
        ),
      ),
    );
  }
}
