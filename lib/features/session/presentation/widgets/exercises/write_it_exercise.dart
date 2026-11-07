import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/text_similarity.dart';
import '../../../../../core/widgets/audio_button.dart';
import '../../../../../core/widgets/custom_card.dart';
import '../../../../../core/widgets/primary_button.dart';
import '../../../../../domain/models/phrase.dart';
import '../../../../../domain/models/topic.dart';

/// Exercice de Niveau 4 : « Écris-le ».
/// Saisie de la phrase en allemand avec tolérance bienveillante et touches pour ä, ö, ü, ß.
class WriteItExercise extends StatefulWidget {
  final Phrase targetPhrase;
  final bool isTtsPlaying;
  final VoidCallback onPlayAudio;
  final Function(TextEvaluationResult result) onValidate;

  const WriteItExercise({
    super.key,
    required this.targetPhrase,
    required this.isTtsPlaying,
    required this.onPlayAudio,
    required this.onValidate,
  });

  @override
  State<WriteItExercise> createState() => _WriteItExerciseState();
}

class _WriteItExerciseState extends State<WriteItExercise> {
  final TextEditingController _controller = TextEditingController();

  void _insertSpecialChar(String char) {
    final text = _controller.text;
    final selection = _controller.selection;
    if (selection.start >= 0) {
      final newText = text.replaceRange(selection.start, selection.end, char);
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start + char.length),
      );
    } else {
      _controller.text += char;
    }
  }

  void _submit() {
    final result = TextSimilarity.evaluate(_controller.text, widget.targetPhrase.de);
    widget.onValidate(result);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
            padding: const EdgeInsets.all(22),
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
                    AudioButton(
                      size: 44,
                      icon: Icons.volume_up_rounded,
                      isPlaying: widget.isTtsPlaying,
                      onPressed: widget.onPlayAudio,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Text(
                  'Écris cette phrase en allemand :',
                  style: AppTextStyles.caption(isDark: isDark).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 8),

                // Phrase française
                Text(
                  widget.targetPhrase.fr,
                  style: AppTextStyles.titleSmall(isDark: isDark).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                // Champ de saisie
                TextField(
                  controller: _controller,
                  autocorrect: false,
                  enableSuggestions: false,
                  textCapitalization: TextCapitalization.sentences,
                  style: AppTextStyles.bodyLarge(isDark: isDark).copyWith(fontSize: 18),
                  decoration: InputDecoration(
                    hintText: 'Tape la phrase ici...',
                    filled: true,
                    fillColor: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                    contentPadding: const EdgeInsets.all(18),
                  ),
                  onSubmitted: (_) => _submit(),
                ),

                const SizedBox(height: 16),

                // Barre de caractères spéciaux allemands (ä, ö, ü, ß)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: ['ä', 'ö', 'ü', 'ß', 'Ä', 'Ö', 'Ü'].map((char) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: InkWell(
                        onTap: () => _insertSpecialChar(char),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF22352B) : AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark ? AppColors.borderDark : AppColors.borderLight,
                            ),
                          ),
                          child: Text(
                            char,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),

          const SizedBox(height: 20),

          PrimaryButton(
            label: 'Vérifier',
            icon: Icons.check_circle_outline_rounded,
            onPressed: _submit,
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
