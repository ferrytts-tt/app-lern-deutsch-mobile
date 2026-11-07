import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/audio_button.dart';
import '../../../../../core/widgets/custom_card.dart';
import '../../../../../core/widgets/german_text_annotator.dart';
import '../../../../../core/widgets/primary_button.dart';
import '../../../../../domain/engine/srs_engine.dart';
import '../../../../../domain/models/phrase.dart';
import '../../../../../domain/models/topic.dart';

/// Exercice de Niveaux 5-6 : « Rappel contextualisé ».
/// Mise en situation concrète dans la vie réelle (« Tu es au restaurant. Que dis-tu ? »)
/// pour ancrer la mémoire à long terme.
class RecallExercise extends StatefulWidget {
  final Phrase targetPhrase;
  final bool isTtsPlaying;
  final VoidCallback onPlayAudio;
  final Function(ReviewOutcome) onEvaluate;

  const RecallExercise({
    super.key,
    required this.targetPhrase,
    required this.isTtsPlaying,
    required this.onPlayAudio,
    required this.onEvaluate,
  });

  @override
  State<RecallExercise> createState() => _RecallExerciseState();
}

class _RecallExerciseState extends State<RecallExercise> {
  bool _revealed = false;

  String _getContextPrompt(String topic) {
    switch (topic) {
      case 'restaurant':
        return 'Tu es au restaurant ou au café. Que dis-tu pour exprimer ceci ?';
      case 'salutations':
        return 'Tu croises quelqu’un en Allemagne. Que dis-tu naturellement ?';
      case 'se_presenter':
        return 'Tu te présentes lors d’une première rencontre. Que dis-tu ?';
      case 'comprendre':
        return 'Tu es en pleine conversation et tu as besoin d’échanger. Que dis-tu ?';
      case 'directions':
        return 'Tu te déplaces en ville et tu cherches ton chemin. Que dis-tu ?';
      case 'achats':
        return 'Tu fais des courses ou des achats dans une boutique. Que dis-tu ?';
      case 'transports':
        return 'Tu es à la gare ou dans le métro. Que dis-tu ?';
      case 'urgences':
        return 'Tu fais face à un imprévu ou une urgence. Que dis-tu ?';
      case 'quotidien':
        return 'Dans une situation du quotidien. Comment t’exprimes-tu ?';
      default:
        return 'Dans cette situation de la vie réelle. Comment dis-tu ceci ?';
    }
  }

  void _reveal() {
    setState(() => _revealed = true);
    widget.onPlayAudio();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topic = TopicInfo.getById(widget.targetPhrase.topic);
    final contextPrompt = _getContextPrompt(widget.targetPhrase.topic);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Column(
        children: [
          CustomCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // En-tête
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: topic.themeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(topic.icon, size: 16, color: topic.themeColor),
                          const SizedBox(width: 6),
                          Text(
                            topic.title,
                            style: TextStyle(
                              color: topic.themeColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Mise en situation',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Mise en situation
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1B2F22) : AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.place_rounded, color: AppColors.primary, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          contextPrompt,
                          style: AppTextStyles.caption(isDark: isDark).copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Idée à exprimer en français
                Text(
                  widget.targetPhrase.fr,
                  style: AppTextStyles.titleMedium(isDark: isDark).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 28),

                if (_revealed) ...[
                  // Réponse allemande révélée
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary, width: 1.5),
                    ),
                    child: Column(
                      children: [
                        GermanTextView(
                          text: widget.targetPhrase.de,
                          baseStyle: AppTextStyles.germanPhrase(isDark: isDark).copyWith(fontSize: 24),
                        ),
                        const SizedBox(height: 12),
                        AudioButton(
                          size: 52,
                          isPlaying: widget.isTtsPlaying,
                          onPressed: widget.onPlayAudio,
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  PrimaryButton(
                    label: 'Vérifier ma réponse',
                    icon: Icons.check_circle_outline_rounded,
                    onPressed: _reveal,
                  ),
                ],

                const SizedBox(height: 12),
              ],
            ),
          ),

          if (_revealed) ...[
            const SizedBox(height: 24),

            Text(
              'Comment s’est passé ce rappel ?',
              style: AppTextStyles.bodyMedium(isDark: isDark).copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => widget.onEvaluate(ReviewOutcome.mistake),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary.withValues(alpha: 0.15),
                      foregroundColor: AppColors.secondary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: AppColors.secondary, width: 1.5),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Difficile', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => widget.onEvaluate(ReviewOutcome.success),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent.withValues(alpha: 0.2),
                      foregroundColor: AppColors.accentDark,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: AppColors.accentDark, width: 1.5),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Bien', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => widget.onEvaluate(ReviewOutcome.easy),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                      foregroundColor: AppColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Maîtrisé !', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
