import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/custom_card.dart';
import '../../../../../core/widgets/german_text_annotator.dart';
import '../../../../../core/widgets/mic_button.dart';
import '../../../../../core/widgets/primary_button.dart';
import '../../../../../domain/engine/srs_engine.dart';
import '../../../../../domain/models/phrase.dart';
import '../../../../../domain/models/topic.dart';

/// Exercice de Niveau 3 : « Dis-le ».
/// Phrase française affichée, répétition à voix haute (micro), révélation de la phrase allemande,
/// puis auto-évaluation à 3 boutons (« Facile » / « Moyen » / « Difficile »).
class SpeakItExercise extends StatefulWidget {
  final Phrase targetPhrase;
  final bool isRecording;
  final bool isTtsPlaying;
  final VoidCallback onToggleRecord;
  final VoidCallback onPlayModel;
  final Function(ReviewOutcome) onEvaluate;

  const SpeakItExercise({
    super.key,
    required this.targetPhrase,
    required this.isRecording,
    required this.isTtsPlaying,
    required this.onToggleRecord,
    required this.onPlayModel,
    required this.onEvaluate,
  });

  @override
  State<SpeakItExercise> createState() => _SpeakItExerciseState();
}

class _SpeakItExerciseState extends State<SpeakItExercise> {
  bool _revealed = false;

  void _revealAnswer() {
    setState(() => _revealed = true);
    widget.onPlayModel();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topic = TopicInfo.getById(widget.targetPhrase.topic);

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
                        color: AppColors.accentLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Parole libre',
                        style: TextStyle(
                          color: AppColors.accentDark,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                Text(
                  'Comment dis-tu cela en allemand ?',
                  style: AppTextStyles.caption(isDark: isDark).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 12),

                // Phrase française affichée
                Text(
                  widget.targetPhrase.fr,
                  style: AppTextStyles.titleMedium(isDark: isDark).copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 28),

                // Bouton micro optionnel
                MicButton(
                  isRecording: widget.isRecording,
                  onPressed: widget.onToggleRecord,
                  label: widget.isRecording ? 'Enregistrement...' : 'Dis-le à voix haute',
                ),

                const SizedBox(height: 28),

                // Réponse révélée
                if (_revealed) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF142E1F) : AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Phrase modèle :',
                          style: AppTextStyles.caption(isDark: isDark),
                        ),
                        const SizedBox(height: 8),
                        GermanTextView(
                          text: widget.targetPhrase.de,
                          baseStyle: AppTextStyles.germanPhraseSmall(isDark: isDark),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  PrimaryButton(
                    label: 'Vérifier la réponse',
                    icon: Icons.visibility_rounded,
                    onPressed: _revealAnswer,
                  ),
                ],
              ],
            ),
          ),

          if (_revealed) ...[
            const SizedBox(height: 24),

            Text(
              'Comment tu t’es évalué ?',
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
                    child: const Text('Moyen', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    child: const Text('Facile !', style: TextStyle(fontWeight: FontWeight.bold)),
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
