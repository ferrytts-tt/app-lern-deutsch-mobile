import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/custom_card.dart';
import '../../../../../core/widgets/duo_character_speaker.dart';
import '../../../../../domain/models/phrase.dart';
import '../../../../../domain/models/topic.dart';

/// Exercice de Niveau 1 : « Écouter et choisir ».
/// Audio joué, 3 traductions proposées, réponse immédiate.
class ListenAndChooseExercise extends StatefulWidget {
  final Phrase targetPhrase;
  final List<String> choices; // 3 choix de traduction en français dont la bonne
  final bool isTtsPlaying;
  final VoidCallback onPlayAudio;
  final Function(String selectedChoice) onSelected;

  const ListenAndChooseExercise({
    super.key,
    required this.targetPhrase,
    required this.choices,
    required this.isTtsPlaying,
    required this.onPlayAudio,
    required this.onSelected,
  });

  @override
  State<ListenAndChooseExercise> createState() => _ListenAndChooseExerciseState();
}

class _ListenAndChooseExerciseState extends State<ListenAndChooseExercise> {
  String? _selectedChoice;

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
              children: [
                // Badge Thème
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
                        color: AppColors.secondaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Écoute & Choix',
                        style: TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                Text(
                  'Écoute et choisis la bonne traduction :',
                  style: AppTextStyles.bodyMedium(isDark: isDark).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                // Personnage animé Duolingo pour l'écoute
                DuoCharacterSpeaker(
                  germanText: widget.targetPhrase.de,
                  audioOnly: true,
                  isPlaying: widget.isTtsPlaying,
                  onPlayAudio: widget.onPlayAudio,
                  characterHeight: 110,
                ),

                const SizedBox(height: 28),

                // 3 Choix de traduction
                ...widget.choices.map((choice) {
                  final isSelected = _selectedChoice == choice;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: InkWell(
                      onTap: () {
                        setState(() => _selectedChoice = choice);
                        widget.onSelected(choice);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark ? const Color(0xFF1B3D2A) : AppColors.primaryLight)
                              : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : (isDark ? AppColors.borderDark : AppColors.borderLight),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          choice,
                          style: AppTextStyles.bodyLarge(isDark: isDark).copyWith(
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? AppColors.primary
                                : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
