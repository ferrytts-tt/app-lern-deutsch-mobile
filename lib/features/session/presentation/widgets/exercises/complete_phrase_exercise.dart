import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/text_similarity.dart';
import '../../../../../core/widgets/arabic_text_view.dart';
import '../../../../../core/widgets/audio_button.dart';
import '../../../../../core/widgets/custom_card.dart';
import '../../../../../core/widgets/primary_button.dart';
import '../../../../../domain/models/phrase.dart';
import '../../../../../domain/models/topic.dart';

/// Exercice de mémoire : « Compléter la phrase » (Sentence completion).
/// L'apprenant voit le début de la phrase et doit écrire la suite.
class CompletePhraseExercise extends StatefulWidget {
  final Phrase targetPhrase;
  final bool isTtsPlaying;
  final VoidCallback onPlayAudio;
  final Function(bool isCorrect) onValidate;

  const CompletePhraseExercise({
    super.key,
    required this.targetPhrase,
    required this.isTtsPlaying,
    required this.onPlayAudio,
    required this.onValidate,
  });

  @override
  State<CompletePhraseExercise> createState() => _CompletePhraseExerciseState();
}

class _CompletePhraseExerciseState extends State<CompletePhraseExercise> {
  late final String _promptPrefix;
  late final String _expectedCompletion;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    final words = widget.targetPhrase.de.split(' ');
    if (words.length <= 2) {
      _promptPrefix = words.first;
      _expectedCompletion = words.length > 1 ? words.sublist(1).join(' ') : '';
    } else {
      // Afficher les premiers 40-50% des mots (minimum 1, max words.length - 1)
      final prefixCount = (words.length * 0.45).ceil().clamp(1, words.length - 1);
      _promptPrefix = words.sublist(0, prefixCount).join(' ');
      _expectedCompletion = words.sublist(prefixCount).join(' ');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
    final userInput = _controller.text.trim();
    final eval = TextSimilarity.evaluate(userInput, _expectedCompletion);
    widget.onValidate(eval.isCorrect);
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Compléter',
                            style: TextStyle(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        AudioButton(
                          size: 40,
                          icon: Icons.volume_up_rounded,
                          isPlaying: widget.isTtsPlaying,
                          onPressed: widget.onPlayAudio,
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Text(
                  'Complète la suite de la phrase :',
                  style: AppTextStyles.caption(isDark: isDark).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 14),

                // Début de la phrase mis en avant
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2F23) : const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '$_promptPrefix ',
                          style: AppTextStyles.germanPhraseSmall(isDark: isDark).copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        TextSpan(
                          text: '... ?',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.accentLight : AppColors.accentDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Traduction française
                Text(
                  widget.targetPhrase.fr,
                  style: AppTextStyles.translation(isDark: isDark),
                  textAlign: TextAlign.center,
                ),

                // Traduction arabe si disponible
                if (widget.targetPhrase.ar != null && widget.targetPhrase.ar!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: ArabicTextView(
                      text: widget.targetPhrase.ar!,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],

                const SizedBox(height: 22),

                // Champ de saisie pour la fin de la phrase
                TextField(
                  controller: _controller,
                  autocorrect: false,
                  enableSuggestions: false,
                  textCapitalization: TextCapitalization.none,
                  style: AppTextStyles.bodyLarge(isDark: isDark).copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Écris la fin de la phrase...',
                    filled: true,
                    fillColor: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  onSubmitted: (_) => _submit(),
                ),

                const SizedBox(height: 16),

                // Raccourcis caractères spéciaux
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: ['ä', 'ö', 'ü', 'ß', 'Ä', 'Ö', 'Ü'].map((char) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: InkWell(
                        onTap: () => _insertSpecialChar(char),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF22352B) : AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark ? AppColors.borderDark : AppColors.borderLight,
                            ),
                          ),
                          child: Text(
                            char,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          PrimaryButton(
            label: 'Vérifier la réponse',
            icon: Icons.check_circle_outline_rounded,
            onPressed: _submit,
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
