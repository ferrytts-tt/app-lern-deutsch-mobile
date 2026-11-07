import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/arabic_text_view.dart';
import '../../../../../core/widgets/custom_card.dart';
import '../../../../../core/widgets/primary_button.dart';
import '../../../../../data/database/app_database.dart';
import '../../../../../domain/models/phrase.dart';
import '../../../../../domain/models/topic.dart';

/// Exercice d'assimilation : « Crée tes propres exemples » (2 à 3 exemples).
/// Conforme à la consigne : « puis faire deux a trois exemple autre que cette phrase ».
class CreateExamplesExercise extends StatefulWidget {
  final Phrase phrase;
  final VoidCallback onComplete;

  const CreateExamplesExercise({
    super.key,
    required this.phrase,
    required this.onComplete,
  });

  @override
  State<CreateExamplesExercise> createState() => _CreateExamplesExerciseState();
}

class _CreateExamplesExerciseState extends State<CreateExamplesExercise> {
  final TextEditingController _ex1Controller = TextEditingController();
  final TextEditingController _ex2Controller = TextEditingController();
  final TextEditingController _ex3Controller = TextEditingController();

  bool _showThirdExample = false;
  bool _isSaving = false;
  String? _errorMessage;

  late final String _keyword;

  @override
  void initState() {
    super.initState();
    _keyword = _extractKeyword(widget.phrase.de);
  }

  String _extractKeyword(String german) {
    const stopWords = {
      'der', 'die', 'das', 'den', 'dem', 'des', 'ein', 'eine', 'einen',
      'einem', 'einer', 'eines', 'ich', 'du', 'er', 'sie', 'es', 'wir',
      'ihr', 'und', 'oder', 'aber', 'in', 'an', 'auf', 'zu', 'mit',
      'von', 'bei', 'nach', 'aus', 'ist', 'bin', 'bist', 'sind', 'seid',
      'hat', 'habe', 'hast', 'haben', 'habt', 'nicht', 'wie', 'sehr'
    };

    final rawWords = german
        .replaceAll(RegExp(r'[.,!?;:\"«»]'), '')
        .split(' ')
        .where((w) => w.trim().isNotEmpty)
        .toList();

    // Chercher le mot le plus long qui n'est pas un stop-word
    String best = '';
    for (final word in rawWords) {
      final clean = word.trim();
      if (!stopWords.contains(clean.toLowerCase()) && clean.length > best.length) {
        best = clean;
      }
    }

    return best.isNotEmpty ? best : (rawWords.isNotEmpty ? rawWords.first : 'Deutsch');
  }

  void _insertSpecialChar(TextEditingController controller, String char) {
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

  Future<void> _submit() async {
    final ex1 = _ex1Controller.text.trim();
    final ex2 = _ex2Controller.text.trim();
    final ex3 = _ex3Controller.text.trim();

    if (ex1.isEmpty && ex2.isEmpty) {
      setState(() {
        _errorMessage = 'Veuillez écrire au moins 1 ou 2 exemples en allemand.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final db = AppDatabase.instance;
      if (ex1.isNotEmpty) {
        await db.saveExample(phraseId: widget.phrase.id, exampleDe: ex1);
      }
      if (ex2.isNotEmpty) {
        await db.saveExample(phraseId: widget.phrase.id, exampleDe: ex2);
      }
      if (ex3.isNotEmpty) {
        await db.saveExample(phraseId: widget.phrase.id, exampleDe: ex3);
      }
    } catch (_) {}

    if (mounted) {
      widget.onComplete();
    }
  }

  @override
  void dispose() {
    _ex1Controller.dispose();
    _ex2Controller.dispose();
    _ex3Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topic = TopicInfo.getById(widget.phrase.topic);

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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.edit_note_rounded, size: 16, color: AppColors.primary),
                          SizedBox(width: 4),
                          Text(
                            '2 à 3 Exemples',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Phrase de référence
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Modèle original :',
                        style: AppTextStyles.caption(isDark: isDark),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.phrase.de,
                        style: AppTextStyles.bodyLarge(isDark: isDark).copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.phrase.fr,
                        style: AppTextStyles.caption(isDark: isDark),
                        textAlign: TextAlign.center,
                      ),
                      if (widget.phrase.ar != null && widget.phrase.ar!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Center(
                          child: ArabicTextView(
                            text: widget.phrase.ar!,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Instruction & Mot clé suggéré
                Text(
                  'Écris 2 à 3 phrases différentes inspirées de cette structure ou avec le mot clé :',
                  style: AppTextStyles.bodyMedium(isDark: isDark).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.accent, width: 1.2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.key_rounded, size: 16, color: AppColors.accentDark),
                      const SizedBox(width: 6),
                      Text(
                        'Mot suggéré : $_keyword',
                        style: const TextStyle(
                          color: AppColors.accentDark,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Exemple 1
                _buildExampleInput(
                  controller: _ex1Controller,
                  label: 'Exemple 1 (obligatoire) :',
                  hint: 'ex: Ich lerne jeden Tag...',
                  isDark: isDark,
                ),

                const SizedBox(height: 12),

                // Exemple 2
                _buildExampleInput(
                  controller: _ex2Controller,
                  label: 'Exemple 2 (recommandé) :',
                  hint: 'ex: Wie geht es deiner Familie ?',
                  isDark: isDark,
                ),

                // Exemple 3 (optionnel)
                if (_showThirdExample) ...[
                  const SizedBox(height: 12),
                  _buildExampleInput(
                    controller: _ex3Controller,
                    label: 'Exemple 3 (optionnel) :',
                    hint: 'ex: Schönen Abend noch !',
                    isDark: isDark,
                  ),
                ] else ...[
                  const SizedBox(height: 6),
                  TextButton.icon(
                    onPressed: () => setState(() => _showThirdExample = true),
                    icon: const Icon(Icons.add_rounded, size: 18, color: AppColors.secondary),
                    label: const Text(
                      'Ajouter un 3ème exemple',
                      style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],

                if (_errorMessage != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppColors.gentleError, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          PrimaryButton(
            label: _isSaving ? 'Enregistrement...' : 'Valider mes exemples',
            icon: Icons.check_circle_rounded,
            onPressed: _isSaving ? null : _submit,
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildExampleInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            // Raccourcis mini pour caractères spéciaux
            Row(
              children: ['ä', 'ö', 'ü', 'ß'].map((char) {
                return Padding(
                  padding: const EdgeInsets.only(left: 3.0),
                  child: InkWell(
                    onTap: () => _insertSpecialChar(controller, char),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF22352B) : AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        char,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          autocorrect: false,
          enableSuggestions: false,
          style: AppTextStyles.bodyMedium(isDark: isDark),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}
