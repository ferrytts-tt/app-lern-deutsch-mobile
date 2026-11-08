import 'package:flutter/material.dart';
import '../../../../core/services/pronunciation_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../../core/widgets/duo_button.dart';
import '../../../../core/widgets/duo_character_speaker.dart';
import '../../../../core/widgets/duolingo_word_composer.dart';
import '../../../../core/widgets/german_text_annotator.dart';
import '../../../../core/widgets/arabic_text_view.dart';
import '../../../../core/widgets/mascot_widget.dart';
import '../../../../core/utils/text_similarity.dart';
import '../../../../domain/models/phrase.dart';
import '../../../../domain/models/topic.dart';
import '../session_controller.dart';

/// Carte interactive « Présentation d'une nouvelle phrase » en 4 écrans courts (Section 3.3 du plan) :
/// (a) la forme parlée avec audio et la traduction ;
/// (b) la forme standard et la note d'explication (note) ;
/// (c) l'audio à écouter deux fois, vitesse normale puis lente, et répétition au micro (reconnaissance vocale) ;
/// (d) un premier exercice facile pour valider la compréhension.
class NewPhraseCard extends StatefulWidget {
  final Phrase phrase;
  final int shadowingStep;
  final ShadowingPhase shadowingPhase;
  final bool isTtsPlaying;
  final bool isRecording;
  final bool isPlayingUserVoice;
  final VoidCallback onPlayNormal;
  final VoidCallback onPlaySlow;
  final VoidCallback? onPlayVerySlow;
  final VoidCallback? onToggleRecord;
  final VoidCallback onNextStep;
  final VoidCallback? onPreviousStep;
  final int learningStep; // 1, 2, 3, ou 4
  final Function(int)? onLearningStepChanged;
  final int testSubStep; // 0: Recomposer, 1: Trous clavier, 2: QCM
  final Function(int)? onTestSubStepChanged;
  final List<String> choices;
  final Function(bool isCorrect)? onValidate;

  const NewPhraseCard({
    super.key,
    required this.phrase,
    this.shadowingStep = 1,
    this.shadowingPhase = ShadowingPhase.listenModel,
    required this.isTtsPlaying,
    this.isRecording = false,
    this.isPlayingUserVoice = false,
    required this.onPlayNormal,
    required this.onPlaySlow,
    this.onPlayVerySlow,
    this.onToggleRecord,
    required this.onNextStep,
    this.onPreviousStep,
    this.learningStep = 1,
    this.onLearningStepChanged,
    this.testSubStep = 0,
    this.onTestSubStepChanged,
    this.choices = const [],
    this.onValidate,
  });

  @override
  State<NewPhraseCard> createState() => _NewPhraseCardState();
}

class _NewPhraseCardState extends State<NewPhraseCard> {
  String? _selectedChoice;
  bool? _isCorrectChoice;
  bool _isListening = false;
  String _spokenText = '';
  PronunciationEvaluation? _pronunciationEvaluation;

  // Exercice Écran 4 : Remplir les vides (Clavier) & QCM
  int _testExerciseType = 0; // 0: Remplir les vides au clavier, 1: QCM de sens
  late final TextEditingController _blankInputController1;
  late final TextEditingController _blankInputController2;
  late final FocusNode _blankFocusNode1;
  late final FocusNode _blankFocusNode2;
  int _activeBlankField = 1;
  String _blankExpectedWord1 = '';
  String _blankExpectedWord2 = '';
  String _blankDisplayPhrase = '';
  bool? _isBlankCorrect;
  bool? _isField1Correct;
  bool? _isField2Correct;
  bool _showHint = false;

  @override
  void initState() {
    super.initState();
    _testExerciseType = widget.testSubStep;
    _blankInputController1 = TextEditingController();
    _blankInputController2 = TextEditingController();
    _blankFocusNode1 = FocusNode();
    _blankFocusNode2 = FocusNode();
    _setupBlankExercise();
  }

  @override
  void dispose() {
    _blankInputController1.dispose();
    _blankInputController2.dispose();
    _blankFocusNode1.dispose();
    _blankFocusNode2.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant NewPhraseCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.testSubStep != oldWidget.testSubStep) {
      _testExerciseType = widget.testSubStep;
    }
    if (oldWidget.phrase.id != widget.phrase.id) {
      _selectedChoice = null;
      _isCorrectChoice = null;
      _isListening = false;
      _spokenText = '';
      _pronunciationEvaluation = null;
      _setupBlankExercise();
    }
  }

  String _extractPunctuation(String word) {
    final match = RegExp(r'([.,!?;:\"«»]+)$').firstMatch(word);
    return match?.group(1) ?? '';
  }

  String _cleanWord(String word) {
    return word.replaceAll(RegExp(r'[.,!?;:\"«»]'), '');
  }

  void _setupBlankExercise() {
    _blankInputController1.clear();
    _blankInputController2.clear();
    _isBlankCorrect = null;
    _isField1Correct = null;
    _isField2Correct = null;
    _showHint = false;
    _activeBlankField = 1;

    final words = widget.phrase.deParle.split(' ');
    if (words.isEmpty) {
      _blankExpectedWord1 = '';
      _blankExpectedWord2 = '';
      _blankDisplayPhrase = '';
      return;
    }

    if (words.length == 1) {
      _blankExpectedWord1 = _cleanWord(words[0]);
      _blankExpectedWord2 = '';
      _blankDisplayPhrase = '(1) ______';
      return;
    }

    if (words.length == 2) {
      _blankExpectedWord1 = _cleanWord(words[0]);
      _blankExpectedWord2 = _cleanWord(words[1]);
      final p1 = _extractPunctuation(words[0]);
      final p2 = _extractPunctuation(words[1]);
      _blankDisplayPhrase = '(1) ______$p1  (2) ______$p2';
      return;
    }

    // Pour phrases >= 3 mots : sélectionner 2 mots distincts significatifs
    int idx1 = -1;
    int idx2 = -1;

    if (words.length == 3) {
      idx1 = 1;
      idx2 = 2;
    } else {
      // Pour >= 4 mots :
      // Trou 1 : chercher le mot le plus significatif dans la première moitié (indices 1 .. length ~/ 2)
      int maxLen1 = 0;
      for (int i = 1; i <= words.length ~/ 2; i++) {
        final c = _cleanWord(words[i]);
        if (c.length > maxLen1) {
          maxLen1 = c.length;
          idx1 = i;
        }
      }
      if (idx1 == -1) idx1 = 1;

      // Trou 2 : chercher le mot le plus significatif dans la seconde moitié
      int maxLen2 = 0;
      for (int i = words.length ~/ 2 + 1; i < words.length; i++) {
        if (i == idx1) continue;
        final c = _cleanWord(words[i]);
        if (c.length > maxLen2) {
          maxLen2 = c.length;
          idx2 = i;
        }
      }
      if (idx2 == -1) {
        for (int i = words.length - 1; i >= 0; i--) {
          if (i != idx1) {
            idx2 = i;
            break;
          }
        }
      }
      if (idx2 == -1) idx2 = (idx1 + 1).clamp(0, words.length - 1);
    }

    if (idx1 > idx2) {
      final tmp = idx1;
      idx1 = idx2;
      idx2 = tmp;
    }

    _blankExpectedWord1 = _cleanWord(words[idx1]);
    _blankExpectedWord2 = idx2 != -1 ? _cleanWord(words[idx2]) : '';

    final displayWords = List<String>.from(words);
    final p1 = _extractPunctuation(words[idx1]);
    displayWords[idx1] = '(1) ______$p1';

    if (idx2 != -1 && idx2 != idx1) {
      final p2 = _extractPunctuation(words[idx2]);
      displayWords[idx2] = '(2) ______$p2';
    }

    _blankDisplayPhrase = displayWords.join(' ');
  }

  void _insertSpecialChar(String char) {
    final controller = _activeBlankField == 1 ? _blankInputController1 : _blankInputController2;
    final focusNode = _activeBlankField == 1 ? _blankFocusNode1 : _blankFocusNode2;
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
      controller.selection = TextSelection.collapsed(offset: controller.text.length);
    }
    focusNode.requestFocus();
  }

  void _verifyBlankAnswer() {
    final input1 = _blankInputController1.text.trim();
    final input2 = _blankInputController2.text.trim();

    if (input1.isEmpty && input2.isEmpty) return;

    final eval1 = TextSimilarity.evaluate(input1, _blankExpectedWord1);
    final eval2 = _blankExpectedWord2.isNotEmpty
        ? TextSimilarity.evaluate(input2, _blankExpectedWord2)
        : null;

    final word1Correct = eval1.isCorrect;
    final word2Correct = eval2 == null || eval2.isCorrect;

    // Tolérances intelligentes :
    final evalFull1 = TextSimilarity.evaluate(input1, widget.phrase.deParle);
    final evalFull2 = TextSimilarity.evaluate(input2, widget.phrase.deParle);
    final isFullPhrase = evalFull1.isCorrect || evalFull2.isCorrect;

    final combined = '$input1 $input2'.trim();
    final expectedCombined = '$_blankExpectedWord1 $_blankExpectedWord2'.trim();
    final isCombinedMatch = TextSimilarity.evaluate(combined, expectedCombined).isCorrect;

    final isInvertedMatch = _blankExpectedWord2.isNotEmpty &&
        TextSimilarity.evaluate(input1, _blankExpectedWord2).isCorrect &&
        TextSimilarity.evaluate(input2, _blankExpectedWord1).isCorrect;

    final isCorrect = (word1Correct && word2Correct) || isFullPhrase || isCombinedMatch || isInvertedMatch;

    setState(() {
      _isBlankCorrect = isCorrect;
      _isField1Correct = isCorrect || word1Correct;
      _isField2Correct = isCorrect || word2Correct;
    });

    if (isCorrect) {
      PronunciationService.instance.playSuccessSound();
    } else {
      PronunciationService.instance.playFailureSound();
    }
  }

  int get _currentStep => widget.learningStep.clamp(1, 4);

  void _toggleListening() {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  void _startListening() async {
    setState(() {
      _isListening = true;
      _spokenText = '';
      _pronunciationEvaluation = null;
    });

    final started = PronunciationService.instance.startListening(
      onResult: (text, isFinal) {
        if (mounted) {
          setState(() {
            _spokenText = text;
          });
          if (isFinal && text.trim().isNotEmpty) {
            _evaluateSpoken(text);
          }
        }
      },
      onError: (error) {
        debugPrint('[Pronunciation] error: $error');
      },
      onEnd: (finalText) {
        if (_isListening && mounted) {
          final t = finalText.isNotEmpty ? finalText : _spokenText;
          _evaluateSpoken(t);
        }
      },
    );

    if (!started) {
      debugPrint('[Pronunciation] Web Speech non disponible ou en attente d\'autorisation');
    }
  }

  void _stopListening() {
    PronunciationService.instance.stopListening();
    if (!mounted) return;
    setState(() {
      _isListening = false;
    });
    if (_pronunciationEvaluation == null) {
      _evaluateSpoken(_spokenText);
    }
  }

  void _evaluateSpoken(String text) {
    PronunciationService.instance.stopListening();
    final eval = PronunciationService.instance.evaluate(
      spoken: text,
      targetParle: widget.phrase.deParle,
      targetStandard: widget.phrase.deStandard,
    );

    if (!mounted) return;

    setState(() {
      _isListening = false;
      _spokenText = text;
      _pronunciationEvaluation = eval;
    });

    if (eval.isSuccess) {
      PronunciationService.instance.playSuccessSound();
    } else {
      PronunciationService.instance.playFailureSound();
    }
  }

  bool get _isPronunciationValidated =>
      _pronunciationEvaluation != null && _pronunciationEvaluation!.isSuccess;

  void _confirmSkipSpeaking() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.mic_off_rounded, color: Color(0xFFF59E0B)),
            SizedBox(width: 8),
            Text('Passer l\'étape orale ?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Pour progresser efficacement en allemand parlé, la prononciation correcte est primordiale.\n\nVeux-tu exceptionnellement passer cette étape ?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Non, je vais répéter', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gentleError,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              if (_currentStep < 4) {
                if (widget.onLearningStepChanged != null) {
                  widget.onLearningStepChanged!(_currentStep + 1);
                } else {
                  widget.onNextStep();
                }
              }
            },
            child: const Text('Passer'),
          ),
        ],
      ),
    );
  }

  void _goToNextStep() {
    // RÈGLE STRICTE : à l'étape 3 (Audio/Prononciation), le candidat DOIT prononcer correctement
    if (_currentStep == 3 && !_isPronunciationValidated) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '⚠️ Prononciation requise : clique sur le micro et prononce correctement la phrase pour débloquer le mini-test !',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Color(0xFFC2410C),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (_currentStep < 4) {
      if (widget.onLearningStepChanged != null) {
        widget.onLearningStepChanged!(_currentStep + 1);
      } else {
        widget.onNextStep();
      }
    } else {
      widget.onNextStep();
    }
  }

  void _goToPreviousStep() {
    if (_currentStep > 1) {
      if (widget.onLearningStepChanged != null) {
        widget.onLearningStepChanged!(_currentStep - 1);
      } else if (widget.onPreviousStep != null) {
        widget.onPreviousStep!();
      }
    }
  }

  void _goToStep(int step) {
    // Verrouillage de l'étape 4 si la prononciation n'est pas encore validée
    if (step == 4 && !_isPronunciationValidated) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '⚠️ Prononciation requise : valide d\'abord l\'étape audio en prononçant correctement la phrase au micro !',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Color(0xFFC2410C),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final target = step.clamp(1, 4);
    if (widget.onLearningStepChanged != null) {
      widget.onLearningStepChanged!(target);
    }
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
                // ── Stepper 4 écrans (Section 3.3) ───────────────────
                _build4StepsIndicator(isDark: isDark),

                const SizedBox(height: 18),

                // ── En-tête : Thème + Badge Nouveau ──────────────────
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
                        'Nouveau',
                        style: TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Contenu spécifique selon l'écran 1..4 ────────────
                if (_currentStep == 1) _buildScreenA(isDark),
                if (_currentStep == 2) _buildScreenB(isDark),
                if (_currentStep == 3) _buildScreenC(isDark),
                if (_currentStep == 4) _buildScreenD(isDark),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // ── Bouton(s) d'action (Navigation Avant / Arrière) ────────
          if (_currentStep == 1)
            DuoButton(
              label: 'Voir la forme standard (2/4)',
              icon: Icons.arrow_forward_rounded,
              variant: DuoButtonVariant.primary,
              onPressed: _goToNextStep,
            )
          else if (_currentStep == 2 || _currentStep == 3)
            Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: DuoButton(
                      label: 'Retour',
                      icon: Icons.arrow_back_rounded,
                      variant: DuoButtonVariant.outline,
                      onPressed: _goToPreviousStep,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: _currentStep == 2
                        ? DuoButton(
                            label: 'Audio (3/4)',
                            icon: Icons.arrow_forward_rounded,
                            variant: DuoButtonVariant.primary,
                            onPressed: _goToNextStep,
                          )
                        : DuoButton(
                            label: _isPronunciationValidated
                                ? 'Suivant (4/4)'
                                : 'Prononcer',
                            icon: _isPronunciationValidated
                                ? Icons.arrow_forward_rounded
                                : Icons.mic_rounded,
                            variant: _isPronunciationValidated
                                ? DuoButtonVariant.primary
                                : DuoButtonVariant.outline,
                            onPressed: _goToNextStep,
                          ),
                  ),
                ],
              ),
            )
          else if (_currentStep == 4)
            DuoButton(
              label: 'Revoir la phrase & l\'audio (3/4)',
              icon: Icons.arrow_back_rounded,
              variant: DuoButtonVariant.outline,
              onPressed: _goToPreviousStep,
            ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Stepper visuel 4 étapes interactif (permet de revenir aux étapes précédentes)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _build4StepsIndicator({required bool isDark}) {
    final titles = ['Parlé', 'Standard', 'Audio', 'Test'];
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        children: [
          if (_currentStep > 1) ...[
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, size: 20),
              tooltip: 'Revenir à l\'étape précédente',
              color: isDark ? Colors.white70 : AppColors.textPrimaryLight,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: _goToPreviousStep,
            ),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Row(
              children: List.generate(4, (index) {
                final stepNum = index + 1;
                final isDone = stepNum < _currentStep;
                final isCurrent = stepNum == _currentStep;

                return Expanded(
                  child: InkWell(
                    onTap: () => _goToStep(stepNum),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Container(
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: isDone || isCurrent
                                        ? AppColors.primary
                                        : (isDark ? AppColors.borderDark : AppColors.borderLight),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (isDone) ...[
                                      const Icon(
                                        Icons.check_rounded,
                                        size: 11,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 2),
                                    ] else if (stepNum == 4 && !_isPronunciationValidated) ...[
                                      const Icon(
                                        Icons.lock_outline_rounded,
                                        size: 10,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 2),
                                    ],
                                    Flexible(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          titles[index],
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                                            color: isCurrent
                                                ? AppColors.primary
                                                : (isDone
                                                    ? (isDark ? Colors.white70 : Colors.black87)
                                                    : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                                          ),
                                          maxLines: 1,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (index < 3) const SizedBox(width: 6),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // (a) Forme parlée avec audio et traduction (Section 3.3a)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildScreenA(bool isDark) {
    return Column(
      children: [
        Text(
          'Écoute et découvre ce que disent les Allemands :',
          style: AppTextStyles.caption(isDark: isDark),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 18),

        // Personnage Duolingo animé avec bulle de parole et haut-parleur
        DuoCharacterSpeaker(
          germanText: widget.phrase.deParle,
          isPlaying: widget.isTtsPlaying,
          onPlayAudio: widget.onPlayNormal,
          characterHeight: 125,
        ),

        const SizedBox(height: 22),

        // Traduction Arabe élégante en harmonie avec le français
        if (widget.phrase.ar != null && widget.phrase.ar!.isNotEmpty)
          ElegantArabicCard(
            arabicText: widget.phrase.ar!,
            frenchSubtitle: widget.phrase.fr.isNotEmpty ? widget.phrase.fr : null,
          )
        else if (widget.phrase.fr.isNotEmpty)
          Text(
            widget.phrase.fr,
            style: AppTextStyles.translation(isDark: isDark).copyWith(fontSize: 16),
            textAlign: TextAlign.center,
          ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // (b) Forme standard et note d'explication (Section 3.3b)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildScreenB(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Le pont avec ce que tu connais déjà (B2) :',
          style: AppTextStyles.caption(isDark: isDark),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 18),

        // Boîte comparaison standard vs parlé
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🇩🇪 ', style: TextStyle(fontSize: 18)),
                  Text(
                    'Forme standard des manuels (B2) :',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              GermanTextView(
                text: widget.phrase.deStandard,
                textAlign: TextAlign.start,
                baseStyle: AppTextStyles.bodyLarge(isDark: isDark).copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              const Divider(height: 24),
              Row(
                children: [
                  const Text('🗣️ ', style: TextStyle(fontSize: 18)),
                  const Text(
                    'Forme parlée naturelle (cible) :',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              GermanTextView(
                text: widget.phrase.deParle,
                textAlign: TextAlign.start,
                baseStyle: AppTextStyles.bodyLarge(isDark: isDark).copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),

        // Note d'explication
        if (widget.phrase.note != null && widget.phrase.note!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B2F22) : AppColors.primaryLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Astuce de langue',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.phrase.note!,
                        style: AppTextStyles.caption(isDark: isDark).copyWith(
                          color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // (c) Audio deux vitesses et répétition au micro (Section 3.3c)
  // ─────────────────────────────────────────────────────────────────────────
  // (c) Audio deux vitesses et répétition au micro (Style Duolingo)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildScreenC(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Titre Duolingo
        Text(
          'Prononce cette phrase',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.start,
        ),
        const SizedBox(height: 18),

        // Falstaff l'ours de Duolingo avec sa bulle de dialogue
        DuoCharacterSpeaker(
          germanText: widget.phrase.deParle,
          character: DuoSpeakerCharacter.bear,
          isPlaying: widget.isTtsPlaying,
          onPlayAudio: widget.onPlayNormal,
          onPlaySlow: widget.onPlaySlow,
          characterHeight: 125,
        ),

        const SizedBox(height: 24),

        // ── Répétition au micro & Évaluation de prononciation ──────
        _buildPronunciationSection(isDark),

        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildPronunciationSection(bool isDark) {
    final eval = _pronunciationEvaluation;

    return Column(
      children: [
        // Bouton large 3D Duolingo : [ 🎙️ CLIQUE POUR PARLER ]
        GestureDetector(
          onTap: _toggleListening,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 54,
            width: double.infinity,
            decoration: BoxDecoration(
              color: _isListening
                  ? const Color(0xFFFF4B4B)
                  : (isDark ? const Color(0xFF1E293B) : Colors.white),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isListening
                    ? const Color(0xFFE53935)
                    : const Color(0xFF1CB0F6),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _isListening
                      ? const Color(0xFFB71C1C)
                      : (isDark ? const Color(0xFF0F172A) : const Color(0xFF1899D6).withValues(alpha: 0.35)),
                  offset: const Offset(0, 3.5),
                  blurRadius: 0,
                ),
              ],
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isListening ? Icons.graphic_eq_rounded : Icons.mic_rounded,
                  color: _isListening ? Colors.white : const Color(0xFF1CB0F6),
                  size: 22,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _isListening
                          ? 'ÉCOUTE EN COURS... (CLIQUER POUR FINIR)'
                          : (eval == null ? 'CLIQUER POUR PARLER' : 'RÉESSAYER AU MICRO'),
                      style: TextStyle(
                        color: _isListening ? Colors.white : const Color(0xFF1CB0F6),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Bouton discret "Je ne peux pas parler maintenant" avec confirmation obligatoire
        Center(
          child: TextButton.icon(
            onPressed: _confirmSkipSpeaking,
            icon: const Icon(Icons.volume_off_rounded, size: 17, color: Color(0xFFAFAFAF)),
            label: const Text(
              'JE NE PEUX PAS PARLER MAINTENANT',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: Color(0xFFAFAFAF),
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),

        // Transcription en direct pendant que l'utilisateur parle
        if (_isListening && _spokenText.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '« $_spokenText »',
              style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
            ),
          ),
        ],

        // ── RÉSULTAT : Validation réussie ou Échec avec grimace inquiète ──
        if (eval != null) ...[
          const SizedBox(height: 16),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: eval.isSuccess
                  ? (isDark ? const Color(0xFF142E1F) : const Color(0xFFE8F5E9))
                  : (isDark ? const Color(0xFF2E1A17) : const Color(0xFFFFEBEE)),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: eval.isSuccess ? AppColors.primary : AppColors.gentleError,
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Mascotte écureuil Duolingo :
                    // Heureux si validé, Inquiet/perplexe (confused) si échoué
                    MascotWidget(
                      mood: eval.isSuccess ? MascotMood.happy : MascotMood.confused,
                      size: 68,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                eval.isSuccess ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                color: eval.isSuccess ? AppColors.primary : AppColors.gentleError,
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  eval.isSuccess ? 'Prononciation validée !' : 'Prononciation non validée',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: eval.isSuccess ? AppColors.primary : AppColors.gentleError,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (eval.isSuccess ? AppColors.primary : AppColors.gentleError)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${eval.scorePercent}%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: eval.isSuccess ? AppColors.primary : AppColors.gentleError,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            eval.spokenText.isNotEmpty
                                ? 'Tu as dit : « ${eval.spokenText} »'
                                : 'Rien entendu distinctement.',
                            style: TextStyle(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            eval.feedbackMessage,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: eval.isSuccess
                                  ? (isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32))
                                  : (isDark ? const Color(0xFFE57373) : const Color(0xFFC62828)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // ── Découpage mot à mot : vert si bien articulé, rouge barré si manqué ──
                if (eval.wordMatches.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text(
                    'Analyse mot par mot :',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: eval.wordMatches.map((m) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: m.isMatched
                              ? (isDark ? const Color(0xFF1B382B) : const Color(0xFFE8F5E9))
                              : (isDark ? const Color(0xFF421D1D) : const Color(0xFFFFEBEE)),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: m.isMatched ? AppColors.primary : AppColors.gentleError,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              m.isMatched ? Icons.check_circle_rounded : Icons.cancel_rounded,
                              size: 13,
                              color: m.isMatched ? AppColors.primary : AppColors.gentleError,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              m.word,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: m.isMatched
                                    ? (isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32))
                                    : (isDark ? const Color(0xFFE57373) : const Color(0xFFC62828)),
                                decoration: m.isMatched ? null : TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],

                // ── Actions de remédiation en cas d'échec ──
                if (!eval.isSuccess) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF3B1E1E) : const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 16, color: AppColors.gentleError),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Étape 4 verrouillée : prononce correctement pour continuer !',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.gentleError,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            foregroundColor: const Color(0xFF1CB0F6),
                            side: const BorderSide(color: Color(0xFF1CB0F6)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.speed_rounded, size: 16),
                          label: const Text(
                            'Écouter (0.65x)',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          onPressed: widget.onPlaySlow,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            backgroundColor: AppColors.gentleError,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.mic_rounded, size: 16),
                          label: const Text(
                            'Répéter au micro',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          onPressed: _startListening,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // (d) Premier exercice facile pour valider (Section 3.3d)
  // ─────────────────────────────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────────────────────
  // (d) Premier exercice pour valider la phrase : Remplir les vides au clavier ou QCM
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildScreenD(bool isDark) {
    final choices = widget.choices.isNotEmpty
        ? widget.choices
        : [
            widget.phrase.ar ?? widget.phrase.fr,
            'Bonjour, comment ça va ?',
            'À plus tard !'
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Sélecteur d'exercice : 1. Recomposer (Duolingo) | 2. Remplir les vides (Clavier) | 3. QCM de sens
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() => _testExerciseType = 0);
                    widget.onTestSubStepChanged?.call(0);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _testExerciseType == 0
                          ? const Color(0xFF58CC02)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.extension_rounded,
                          size: 15,
                          color: _testExerciseType == 0
                              ? Colors.white
                              : (isDark ? Colors.white70 : AppColors.textPrimaryLight),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Recomposer',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: _testExerciseType == 0
                                ? FontWeight.bold
                                : FontWeight.w600,
                            color: _testExerciseType == 0
                                ? Colors.white
                                : (isDark ? Colors.white70 : AppColors.textPrimaryLight),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() => _testExerciseType = 1);
                    widget.onTestSubStepChanged?.call(1);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _testExerciseType == 1
                          ? AppColors.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.keyboard_alt_rounded,
                          size: 15,
                          color: _testExerciseType == 1
                              ? Colors.white
                              : (isDark ? Colors.white70 : AppColors.textPrimaryLight),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Trous clavier',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: _testExerciseType == 1
                                ? FontWeight.bold
                                : FontWeight.w600,
                            color: _testExerciseType == 1
                                ? Colors.white
                                : (isDark ? Colors.white70 : AppColors.textPrimaryLight),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() => _testExerciseType = 2);
                    widget.onTestSubStepChanged?.call(2);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _testExerciseType == 2
                          ? AppColors.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.quiz_rounded,
                          size: 15,
                          color: _testExerciseType == 2
                              ? Colors.white
                              : (isDark ? Colors.white70 : AppColors.textPrimaryLight),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'QCM',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: _testExerciseType == 2
                                ? FontWeight.bold
                                : FontWeight.w600,
                            color: _testExerciseType == 2
                                ? Colors.white
                                : (isDark ? Colors.white70 : AppColors.textPrimaryLight),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        if (_testExerciseType == 0)
          DuolingoWordComposer(
            targetPhrase: widget.phrase,
            isTtsPlaying: widget.isTtsPlaying,
            onPlayAudio: widget.onPlayNormal,
            onPlaySlow: widget.onPlaySlow,
            showDirectionSwitch: true,
            embeddedInCard: true,
            onValidate: (isCorrect) {
              if (widget.onValidate != null) {
                widget.onValidate!(isCorrect);
              }
            },
          )
        else if (_testExerciseType == 1)
          _buildClozeSection(isDark)
        else
          _buildQcmSection(isDark, choices),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Exercice « Remplir les vides au clavier » (avec écureuil maladroit/heureux)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildClozeSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.edit_note_rounded, size: 18, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              'Remplis les vides au clavier ⌨️',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDark ? AppColors.primaryLight : AppColors.primary,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.volume_up_rounded, color: AppColors.primary, size: 20),
              tooltip: 'Réécouter la phrase',
              onPressed: widget.onPlayNormal,
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Carte affichant la phrase avec les vides
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B2F22) : AppColors.primaryLight.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isBlankCorrect == true
                  ? AppColors.primary
                  : (_isBlankCorrect == false ? AppColors.gentleError : AppColors.primary.withValues(alpha: 0.3)),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              GermanTextView(
                text: _blankDisplayPhrase,
                baseStyle: AppTextStyles.germanPhrase(isDark: isDark).copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              if (widget.phrase.ar != null && widget.phrase.ar!.isNotEmpty) ...[
                ArabicTextView(
                  text: widget.phrase.ar!,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  textAlign: TextAlign.center,
                ),
                if (widget.phrase.fr.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.phrase.fr,
                    style: AppTextStyles.translation(isDark: isDark).copyWith(fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ] else if (widget.phrase.fr.isNotEmpty) ...[
                Text(
                  widget.phrase.fr,
                  style: AppTextStyles.translation(isDark: isDark).copyWith(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Deux champs de saisie au clavier (Trou 1 et Trou 2)
        Column(
          children: [
            // Champ 1
            TextField(
              controller: _blankInputController1,
              focusNode: _blankFocusNode1,
              enabled: _isBlankCorrect != true,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: _blankExpectedWord2.isNotEmpty ? TextInputAction.next : TextInputAction.done,
              onTap: () => setState(() => _activeBlankField = 1),
              onSubmitted: (_) {
                if (_blankExpectedWord2.isNotEmpty) {
                  setState(() => _activeBlankField = 2);
                  _blankFocusNode2.requestFocus();
                } else {
                  _verifyBlankAnswer();
                }
              },
              style: AppTextStyles.bodyLarge(isDark: isDark).copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 12, right: 8),
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: _isField1Correct == true
                        ? AppColors.primary
                        : (_isField1Correct == false ? AppColors.gentleError : AppColors.primary),
                    child: const Text('1', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                hintText: 'Mot (1)... (${_blankExpectedWord1.length} lettres)',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white38 : AppColors.textSecondaryLight,
                ),
                filled: true,
                fillColor: isDark ? AppColors.surfaceDark : Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: _isField1Correct == true
                        ? AppColors.primary
                        : (_isField1Correct == false ? AppColors.gentleError : (isDark ? AppColors.borderDark : AppColors.borderLight)),
                    width: _isField1Correct != null ? 2 : 1,
                  ),
                ),
              ),
            ),

            if (_blankExpectedWord2.isNotEmpty) ...[
              const SizedBox(height: 10),

              // Champ 2
              TextField(
                controller: _blankInputController2,
                focusNode: _blankFocusNode2,
                enabled: _isBlankCorrect != true,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.done,
                onTap: () => setState(() => _activeBlankField = 2),
                onSubmitted: (_) => _verifyBlankAnswer(),
                style: AppTextStyles.bodyLarge(isDark: isDark).copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 12, right: 8),
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: _isField2Correct == true
                          ? AppColors.primary
                          : (_isField2Correct == false ? AppColors.gentleError : AppColors.primary),
                      child: const Text('2', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  hintText: 'Mot (2)... (${_blankExpectedWord2.length} lettres)',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white38 : AppColors.textSecondaryLight,
                  ),
                  filled: true,
                  fillColor: isDark ? AppColors.surfaceDark : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: _isField2Correct == true
                          ? AppColors.primary
                          : (_isField2Correct == false ? AppColors.gentleError : (isDark ? AppColors.borderDark : AppColors.borderLight)),
                      width: _isField2Correct != null ? 2 : 1,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),

        const SizedBox(height: 10),

        // Raccourcis caractères spéciaux allemands (ä, ö, ü, ß, ...)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: ['ä', 'ö', 'ü', 'ß', 'Ä', 'Ö', 'Ü'].map((char) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3.0),
              child: InkWell(
                onTap: _isBlankCorrect == true ? null : () => _insertSpecialChar(char),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
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
                      fontSize: 14,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.primaryDark,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 16),

        // État : En attente de validation
        if (_isBlankCorrect == null) ...[
          DuoButton(
            label: 'Vérifier ma réponse',
            icon: Icons.check_circle_outline_rounded,
            variant: DuoButtonVariant.primary,
            onPressed: _verifyBlankAnswer,
          ),
        ],

        // État : VALIDÉ AVEC SUCCÈS (Écureuil heureux)
        if (_isBlankCorrect == true) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF142E1F) : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary, width: 1.5),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Mascotte écureuil Heureux
                    const MascotWidget(
                      mood: MascotMood.happy,
                      size: 68,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
                              SizedBox(width: 6),
                              Text(
                                'Phrase validée ! 🎉',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Excellente saisie au clavier ! Les deux mots sont exacts.',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.phrase.deParle,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                DuoButton(
                  label: 'Valider et continuer',
                  icon: Icons.check_circle_rounded,
                  variant: DuoButtonVariant.primary,
                  onPressed: () {
                    if (widget.onValidate != null) {
                      widget.onValidate!(true);
                    } else {
                      widget.onNextStep();
                    }
                  },
                ),
              ],
            ),
          ),
        ],

        // État : RÉPONSE FALSCH (Écureuil maladroit)
        if (_isBlankCorrect == false) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2E1A17) : const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.gentleError, width: 1.5),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Mascotte écureuil maladroit (confused)
                    const MascotWidget(
                      mood: MascotMood.confused,
                      size: 68,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.cancel_rounded, color: AppColors.gentleError, size: 20),
                              SizedBox(width: 6),
                              Text(
                                'Réponse Falsch !',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.gentleError,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isField1Correct == true && _isField2Correct == false
                                ? 'Mot (1) est bon, mais mot (2) est inexact ! L\'écureuil est perplexe...'
                                : (_isField2Correct == true && _isField1Correct == false
                                    ? 'Mot (2) est bon, mais mot (1) est inexact ! L\'écureuil est perplexe...'
                                    : 'L\'écureuil est un peu maladroit... Corrige ta saisie et réessaie !'),
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                          if (_showHint) ...[
                            const SizedBox(height: 4),
                            Text(
                              _blankExpectedWord2.isNotEmpty
                                  ? '💡 Mots attendus : (1) « $_blankExpectedWord1 »  •  (2) « $_blankExpectedWord2 »'
                                  : '💡 Mot attendu : « $_blankExpectedWord1 »',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.gentleError,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.gentleError,
                          side: const BorderSide(color: AppColors.gentleError),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Réessayer au clavier'),
                        onPressed: () {
                          setState(() {
                            _isBlankCorrect = null;
                            _isField1Correct = null;
                            _isField2Correct = null;
                          });
                          _blankFocusNode1.requestFocus();
                        },
                      ),
                    ),
                    if (!_showHint) ...[
                      const SizedBox(width: 8),
                      TextButton.icon(
                        icon: const Icon(Icons.lightbulb_outline, size: 18),
                        label: const Text('Indice'),
                        onPressed: () {
                          setState(() {
                            _showHint = true;
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Exercice « QCM de sens » (avec mascotte et sons)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildQcmSection(bool isDark, List<String> choices) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: GermanTextView(
                text: widget.phrase.deParle,
                baseStyle: AppTextStyles.germanPhrase(isDark: isDark).copyWith(fontSize: 22),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.volume_up_rounded, color: AppColors.primary),
              onPressed: widget.onPlayNormal,
            ),
          ],
        ),

        const SizedBox(height: 18),

        Text(
          'Quelle est la bonne signification ?',
          style: AppTextStyles.bodyMedium(isDark: isDark).copyWith(
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 16),

        // Choix QCM
        ...choices.map((choice) {
          final isSelected = _selectedChoice == choice;
          Color? bgColor;
          Color? borderColor;

          if (isSelected && _isCorrectChoice != null) {
            bgColor = _isCorrectChoice!
                ? AppColors.primaryLight
                : AppColors.gentleErrorBackground;
            borderColor = _isCorrectChoice!
                ? AppColors.primary
                : AppColors.gentleError;
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                if (_selectedChoice != null) return;
                final isCorrect = (choice.trim() == (widget.phrase.ar ?? '').trim()) ||
                    (choice.trim() == widget.phrase.fr.trim());
                setState(() {
                  _selectedChoice = choice;
                  _isCorrectChoice = isCorrect;
                });

                if (widget.onValidate != null) {
                  widget.onValidate!(isCorrect);
                } else {
                  widget.onNextStep();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: bgColor ?? (isDark ? AppColors.surfaceDark : Colors.white),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: borderColor ?? (isDark ? AppColors.borderDark : AppColors.borderLight),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: isArabicString(choice)
                    ? ArabicTextView(
                        text: choice,
                        fontSize: 17,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      )
                    : Text(
                        choice,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                        textAlign: TextAlign.center,
                      ),
              ),
            ),
          );
        }),

        // Mascotte feedback pour le QCM
        if (_isCorrectChoice != null) ...[
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MascotWidget(
                mood: _isCorrectChoice! ? MascotMood.happy : MascotMood.confused,
                size: 60,
              ),
              const SizedBox(width: 10),
              Text(
                _isCorrectChoice!
                    ? 'Bravo ! Bonne réponse !'
                    : 'Falsch ! L\'écureuil est un peu maladroit...',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _isCorrectChoice! ? AppColors.primary : AppColors.gentleError,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
