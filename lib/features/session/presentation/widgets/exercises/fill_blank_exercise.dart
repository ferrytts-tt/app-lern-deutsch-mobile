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

/// Exercice de mémoire : « Remplir les trous » (Fill in the blanks).
/// L'apprenant doit deviner et écrire le ou les mots manquants de la phrase.
class FillBlankExercise extends StatefulWidget {
  final Phrase targetPhrase;
  final bool isTtsPlaying;
  final VoidCallback onPlayAudio;
  final Function(bool isCorrect) onValidate;

  const FillBlankExercise({
    super.key,
    required this.targetPhrase,
    required this.isTtsPlaying,
    required this.onPlayAudio,
    required this.onValidate,
  });

  @override
  State<FillBlankExercise> createState() => _FillBlankExerciseState();
}

class _FillBlankExerciseState extends State<FillBlankExercise> {
  late final List<String> _words;
  late final List<int> _blankIndices;
  late final List<String> _expectedAnswers;
  late final List<TextEditingController> _controllers;
  int _activeControllerIndex = 0;

  @override
  void initState() {
    super.initState();
    _words = widget.targetPhrase.de.split(' ');
    _blankIndices = [];
    _expectedAnswers = [];

    if (_words.length <= 2) {
      _blankIndices.add(0);
      _expectedAnswers.add(_words[0]);
    } else {
      // Masquer 1 mot si <= 5 mots, 2 mots sinon (en évitant le premier mot)
      final count = _words.length > 5 ? 2 : 1;
      final step = (_words.length - 1) ~/ count;
      for (int i = 0; i < count; i++) {
        final idx = (1 + i * step).clamp(1, _words.length - 1);
        if (!_blankIndices.contains(idx)) {
          _blankIndices.add(idx);
          // Nettoyer la ponctuation du mot attendu
          final rawWord = _words[idx].replaceAll(RegExp(r'[.,!?;:\"«»]'), '');
          _expectedAnswers.add(rawWord);
        }
      }
    }

    _controllers = List.generate(
      _blankIndices.length,
      (_) => TextEditingController(),
    );
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _insertSpecialChar(String char) {
    if (_controllers.isEmpty) return;
    final controller = _controllers[_activeControllerIndex.clamp(0, _controllers.length - 1)];
    final text = controller.text;
    final selection = controller.selection;
    if (selection.start >= 0) {
      final newText = text.replaceRange(selection.start, selection.end, char);
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start + char.length),
      );
    } else {
      controller.text += char;
    }
  }

  void _submit() {
    bool allCorrect = true;
    for (int i = 0; i < _expectedAnswers.length; i++) {
      final input = _controllers[i].text.trim();
      final expected = _expectedAnswers[i].trim();
      final eval = TextSimilarity.evaluate(input, expected);
      if (!eval.isCorrect) {
        allCorrect = false;
        break;
      }
    }
    widget.onValidate(allCorrect);
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
                            color: AppColors.accentLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Texte à trous',
                            style: TextStyle(
                              color: AppColors.accentDark,
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
                  'Complète le ou les mots manquants :',
                  style: AppTextStyles.caption(isDark: isDark).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 16),

                // Phrase avec trous
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 8,
                  children: List.generate(_words.length, (idx) {
                    final isBlank = _blankIndices.contains(idx);
                    if (isBlank) {
                      final blankPos = _blankIndices.indexOf(idx) + 1;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.accentDark, width: 1.5),
                        ),
                        child: Text(
                          '($blankPos) _____',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.accentLight : AppColors.accentDark,
                          ),
                        ),
                      );
                    } else {
                      return Text(
                        _words[idx],
                        style: AppTextStyles.germanPhraseSmall(isDark: isDark),
                      );
                    }
                  }),
                ),

                const SizedBox(height: 16),

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

                const SizedBox(height: 24),

                // Champs de saisie pour chaque trou
                Column(
                  children: List.generate(_blankIndices.length, (i) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: TextField(
                        controller: _controllers[i],
                        autocorrect: false,
                        enableSuggestions: false,
                        onTap: () => setState(() => _activeControllerIndex = i),
                        textCapitalization: TextCapitalization.none,
                        style: AppTextStyles.bodyLarge(isDark: isDark).copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: InputDecoration(
                          prefixIcon: CircleAvatar(
                            radius: 12,
                            backgroundColor: AppColors.accent,
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          hintText: 'Mot n°${i + 1}...',
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
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    );
                  }),
                ),

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
