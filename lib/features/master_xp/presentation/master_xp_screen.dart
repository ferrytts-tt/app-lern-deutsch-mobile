import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/pronunciation_service.dart';
import '../../../core/services/tts_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/text_similarity.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/duo_button.dart';
import '../../../core/widgets/duo_confetti.dart';
import '../../../core/widgets/mascot_widget.dart';
import '../../../data/database/app_database.dart';
import '../../../domain/engine/german_master_scenarios.dart';
import '../../../domain/models/phrase.dart';

enum MasterXpTab {
  allChallenges,
  arabicToGerman,
  situationResponse,
}

enum ExerciseTypeInMaster {
  translateArabicToGerman,
  respondToSituation,
}

class MasterQuestion {
  final int index;
  final Phrase phrase;
  final ExerciseTypeInMaster type;
  final List<String> choices;
  final GermanMasterScenario scenario;

  MasterQuestion({
    required this.index,
    required this.phrase,
    required this.type,
    required this.choices,
    required this.scenario,
  });
}

/// Page Master XP : Défi de maîtrise du lot des 10 phrases.
/// - Exercice 1 : « Comment dire en allemand ? » (Phrase en arabe -> écriture au clavier ou choix dans la liste)
/// - Exercice 2 : « Comment répondre à une question / situation ? » (Réponse parmi les 10 phrases, pensé par un expert en allemand)
class MasterXpScreen extends StatefulWidget {
  final List<String>? initialPhraseIds;
  final List<Phrase>? initialPhrases;

  const MasterXpScreen({
    super.key,
    this.initialPhraseIds,
    this.initialPhrases,
  });

  @override
  State<MasterXpScreen> createState() => _MasterXpScreenState();
}

class _MasterXpScreenState extends State<MasterXpScreen> {
  bool _isLoading = true;
  List<Phrase> _tenPhrases = [];
  List<MasterQuestion> _questions = [];

  MasterXpTab _currentTab = MasterXpTab.allChallenges;
  int _currentIndex = 0;
  int _xpEarned = 0;
  int _score = 0;
  bool _isAnswerChecked = false;
  bool _isCurrentCorrect = false;
  String? _selectedChoice;
  bool _useKeyboardForExercise1 = false; // toggle entre clavier et liste

  final TextEditingController _keyboardController = TextEditingController();
  final FocusNode _keyboardFocusNode = FocusNode();

  MascotMood _mascotMood = MascotMood.idle;
  String? _feedbackMessage;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _loadMasterData();
  }

  Future<void> _loadMasterData() async {
    if (widget.initialPhrases != null && widget.initialPhrases!.isNotEmpty) {
      _tenPhrases = widget.initialPhrases!;
      _buildQuestions();
      if (mounted) {
        setState(() {
          _isLoading = false;
          _resetQuestionState();
        });
      }
      return;
    }

    setState(() => _isLoading = true);

    final db = AppDatabase.instance;
    final allPhrases = await db.getAllPhrases();

    List<Phrase> selectedBatch = [];

    // 1. Chercher d'abord les IDs passés en paramètre ou stockés dans SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final savedIds = widget.initialPhraseIds ?? prefs.getStringList('last_session_phrases');

    if (savedIds != null && savedIds.isNotEmpty) {
      final map = {for (final p in allPhrases) p.id: p};
      for (final id in savedIds) {
        if (map.containsKey(id)) {
          selectedBatch.add(map[id]!);
        }
      }
    }

    // 2. Fallback : si moins de 10 phrases trouvées, compléter avec les phrases de la base
    if (selectedBatch.length < 10) {
      final existingIds = selectedBatch.map((p) => p.id).toSet();
      for (final p in allPhrases) {
        if (!existingIds.contains(p.id)) {
          selectedBatch.add(p);
          if (selectedBatch.length >= 10) break;
        }
      }
    }

    if (selectedBatch.isEmpty && allPhrases.isNotEmpty) {
      selectedBatch = allPhrases.take(10).toList();
    }

    _tenPhrases = selectedBatch;
    _buildQuestions();

    if (mounted) {
      setState(() {
        _isLoading = false;
        _resetQuestionState();
      });
    }
  }

  void _buildQuestions() {
    if (_tenPhrases.isEmpty) return;

    final random = Random(42); // seed reproductible ou aléatoire
    final List<MasterQuestion> generated = [];

    // Tous les textes en allemand pour les choix distracteurs
    final allDeTexts = _tenPhrases.map((p) => p.deParle.isNotEmpty ? p.deParle : p.de).toList();

    for (int i = 0; i < _tenPhrases.length; i++) {
      final phrase = _tenPhrases[i];
      final targetDe = phrase.deParle.isNotEmpty ? phrase.deParle : phrase.de;
      final scenario = GermanMasterScenariosCatalog.getScenarioFor(phrase);

      // Générer 4 choix parmi les 10 phrases
      final distractors = allDeTexts.where((text) => text != targetDe).toList()..shuffle(random);
      final choices = [targetDe, ...distractors.take(3)]..shuffle(random);

      // Répartition selon l'onglet :
      ExerciseTypeInMaster type;
      if (_currentTab == MasterXpTab.arabicToGerman) {
        type = ExerciseTypeInMaster.translateArabicToGerman;
      } else if (_currentTab == MasterXpTab.situationResponse) {
        type = ExerciseTypeInMaster.respondToSituation;
      } else {
        // Défi Complet : alterne entre Exercice 1 et Exercice 2 pour chaque phrase
        type = (i % 2 == 0)
            ? ExerciseTypeInMaster.translateArabicToGerman
            : ExerciseTypeInMaster.respondToSituation;
      }

      generated.add(MasterQuestion(
        index: i,
        phrase: phrase,
        type: type,
        choices: choices,
        scenario: scenario,
      ));
    }

    _questions = generated;
  }

  void _switchTab(MasterXpTab tab) {
    if (_currentTab == tab) return;
    setState(() {
      _currentTab = tab;
      _currentIndex = 0;
      _score = 0;
      _xpEarned = 0;
      _isCompleted = false;
      _buildQuestions();
      _resetQuestionState();
    });
  }

  void _resetQuestionState() {
    _isAnswerChecked = false;
    _isCurrentCorrect = false;
    _selectedChoice = null;
    _feedbackMessage = null;
    _keyboardController.clear();
    _mascotMood = MascotMood.idle;
  }

  void _insertSpecialChar(String char) {
    final text = _keyboardController.text;
    final selection = _keyboardController.selection;
    if (selection.start >= 0) {
      final newText = text.replaceRange(selection.start, selection.end, char);
      _keyboardController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start + char.length),
      );
    } else {
      _keyboardController.text += char;
    }
  }

  Future<void> _speak(String text, {String? phraseId}) async {
    try {
      await TtsService.instance.speak(text, phraseId: phraseId);
    } catch (_) {}
  }

  Future<void> _recordXp(int amount) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final dayKey = 'daily_xp_${now.year}_${now.month}_${now.day}';
      final current = prefs.getInt(dayKey) ?? 0;
      await prefs.setInt(dayKey, current + amount);
      final total = prefs.getInt('total_xp') ?? 0;
      await prefs.setInt('total_xp', total + amount);
      await prefs.setInt('last_master_xp_earned', _xpEarned);
    } catch (_) {}
  }

  Future<void> _saveFinalMasterXp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_master_xp_score', _score);
      await prefs.setInt('last_master_xp_earned', _xpEarned);
    } catch (_) {}
  }

  void _verifyChoice(String selected) {
    if (_isAnswerChecked) return;

    final question = _questions[_currentIndex];
    final targetDe = question.phrase.deParle.isNotEmpty
        ? question.phrase.deParle
        : question.phrase.de;

    final isCorrect = selected.trim() == targetDe.trim();

    setState(() {
      _isAnswerChecked = true;
      _selectedChoice = selected;
      _isCurrentCorrect = isCorrect;

      if (isCorrect) {
        _score++;
        _xpEarned += 10;
        _recordXp(10);
        _mascotMood = question.type == ExerciseTypeInMaster.respondToSituation
            ? MascotMood.celebrating
            : MascotMood.happy;
        _feedbackMessage = 'Richtig! Sehr gut gemacht.';
        PronunciationService.instance.playSuccessSound();
      } else {
        _mascotMood = MascotMood.confused; // Écureuil maladroit
        _feedbackMessage = 'Falsch! Pas tout à fait.';
        PronunciationService.instance.playFailureSound();
      }
    });

    // Prononce automatiquement la bonne réponse en allemand pour l'oreille
    _speak(targetDe, phraseId: question.phrase.id);
  }

  void _verifyKeyboardInput() {
    if (_isAnswerChecked) return;

    final question = _questions[_currentIndex];
    final input = _keyboardController.text.trim();
    if (input.isEmpty) return;

    final targetDe = question.phrase.deParle.isNotEmpty
        ? question.phrase.deParle
        : question.phrase.de;
    final targetStandard = question.phrase.deStandard;

    // Évaluation bienveillante avec TextSimilarity
    final result1 = TextSimilarity.evaluate(input, targetDe);
    final result2 = TextSimilarity.evaluate(input, targetStandard);
    final isCorrect = result1.isCorrect || result2.isCorrect;

    setState(() {
      _isAnswerChecked = true;
      _isCurrentCorrect = isCorrect;

      if (isCorrect) {
        _score++;
        _xpEarned += 10;
        _recordXp(10);
        _mascotMood = MascotMood.happy;
        _feedbackMessage = result1.hasMinorTypo
            ? 'Bien joué ! (Légère faute de frappe tolérée)'
            : 'Parfait ! Phrase écrite exactement.';
        PronunciationService.instance.playSuccessSound();
      } else {
        _mascotMood = MascotMood.confused; // Écureuil maladroit
        _feedbackMessage = 'Falsch! Regarde la correction ci-dessous :';
        PronunciationService.instance.playFailureSound();
      }
    });

    _speak(targetDe, phraseId: question.phrase.id);
  }

  void _goToNextQuestion() {
    if (_currentIndex + 1 < _questions.length) {
      setState(() {
        _currentIndex++;
        _resetQuestionState();
      });
    } else {
      setState(() {
        _isCompleted = true;
        _mascotMood = MascotMood.celebrating;
      });
      PronunciationService.instance.playSuccessSound();
      _saveFinalMasterXp();
    }
  }

  @override
  void dispose() {
    _keyboardController.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_isCompleted) {
      return _buildCompletionView(isDark: isDark);
    }

    final question = _questions[_currentIndex];

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Barre supérieure : Quitter, Titre Master XP, XP accumulé
            _buildTopBar(isDark: isDark),

            // Sélecteur d'onglets (Défi Complet / Exercice 1 / Exercice 2)
            _buildTabBar(isDark: isDark),

            const SizedBox(height: 8),

            // Contenu défilant de la question
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Mascotte avec humeur réactive en haut
                    Center(
                      child: MascotWidget(
                        mood: _mascotMood,
                        size: 88,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Carte d'exercice selon le type
                    if (question.type == ExerciseTypeInMaster.translateArabicToGerman)
                      _buildExercise1Card(question, isDark: isDark)
                    else
                      _buildExercise2Card(question, isDark: isDark),

                    const SizedBox(height: 16),

                    // Encadré de feedback après validation
                    if (_isAnswerChecked) _buildFeedbackCard(question, isDark: isDark),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Barre d'action inférieure (Valider ou Continuer)
            _buildBottomActionBar(question, isDark: isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar({required bool isDark}) {
    final progress = (_currentIndex + 1) / _questions.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => context.pop(),
                tooltip: 'Quitter le Master XP',
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 12,
                    backgroundColor: isDark ? AppColors.surfaceDark : AppColors.borderLight,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF9600)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9600).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFF9600).withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt_rounded, size: 16, color: Color(0xFFFF9600)),
                    const SizedBox(width: 4),
                    Text(
                      '$_xpEarned XP',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFFF9600),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Question ${_currentIndex + 1} / ${_questions.length} • Lot de 10 phrases',
            style: AppTextStyles.caption(isDark: isDark).copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar({required bool isDark}) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          _buildTabChip(
            label: '🌟 Défi Mixte',
            tab: MasterXpTab.allChallenges,
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _buildTabChip(
            label: '🇩🇪 Ex. 1 : Arabe ➔ Allemand',
            tab: MasterXpTab.arabicToGerman,
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _buildTabChip(
            label: '💬 Ex. 2 : Situations & Réponses',
            tab: MasterXpTab.situationResponse,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildTabChip({
    required String label,
    required MasterXpTab tab,
    required bool isDark,
  }) {
    final isSelected = _currentTab == tab;
    return InkWell(
      onTap: () => _switchTab(tab),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFF9600)
              : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF9600)
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // EXERCICE 1 : Comment dire en allemand ?
  // ==========================================
  Widget _buildExercise1Card(MasterQuestion question, {required bool isDark}) {
    final phrase = question.phrase;
    final arabicText = phrase.ar ?? 'طيب، كيف الأحوال؟';

    return CustomCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Badge d'instruction
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🇩🇪', style: TextStyle(fontSize: 12)),
                    SizedBox(width: 4),
                    Text(
                      'EXERCICE 1 · TRADUCTION',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Toggle Clavier / Liste
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => setState(() => _useKeyboardForExercise1 = false),
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        color: !_useKeyboardForExercise1
                            ? AppColors.primary.withValues(alpha: 0.2)
                            : Colors.transparent,
                        child: Icon(
                          Icons.list_alt_rounded,
                          size: 16,
                          color: !_useKeyboardForExercise1 ? AppColors.primary : Colors.grey,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => setState(() => _useKeyboardForExercise1 = true),
                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(14)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        color: _useKeyboardForExercise1
                            ? AppColors.primary.withValues(alpha: 0.2)
                            : Colors.transparent,
                        child: Icon(
                          Icons.keyboard_rounded,
                          size: 16,
                          color: _useKeyboardForExercise1 ? AppColors.primary : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            'Comment dit-on cette phrase en allemand ?',
            style: AppTextStyles.bodyMedium(isDark: isDark).copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 14),

          // Encart phrase en arabe (callout mise en valeur)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF14241B) : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
            ),
            child: Column(
              children: [
                Text(
                  arabicText,
                  style: const TextStyle(
                    fontFamily: 'NotoSansArabic',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                ),
                if (phrase.fr.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    '(${phrase.fr})',
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Choix A : Saisie au clavier
          if (_useKeyboardForExercise1) ...[
            TextField(
              controller: _keyboardController,
              focusNode: _keyboardFocusNode,
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.sentences,
              enabled: !_isAnswerChecked,
              style: AppTextStyles.bodyLarge(isDark: isDark),
              decoration: InputDecoration(
                hintText: 'Écris la phrase en allemand...',
                filled: true,
                fillColor: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              onSubmitted: (_) => _verifyKeyboardInput(),
            ),
            const SizedBox(height: 10),
            // Touches de caractères spéciaux allemands
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['ä', 'ö', 'ü', 'ß', 'Ä', 'Ö', 'Ü'].map((char) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: InkWell(
                      onTap: () => _insertSpecialChar(char),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          ),
                        ),
                        child: Text(
                          char,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ]
          // Choix B : Choix parmi une liste (QCM)
          else ...[
            Text(
              'Choisis parmi les 10 phrases apprises :',
              style: AppTextStyles.caption(isDark: isDark),
            ),
            const SizedBox(height: 8),
            ...question.choices.map((choice) => _buildChoiceTile(choice, question, isDark: isDark)),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // EXERCICE 2 : Comment répondre à une question ?
  // ==========================================
  Widget _buildExercise2Card(MasterQuestion question, {required bool isDark}) {
    final scenario = question.scenario;

    return CustomCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // En-tête Situation
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9600).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('💬', style: TextStyle(fontSize: 12)),
                    SizedBox(width: 4),
                    Text(
                      'EXERCICE 2 · SITUATION RÉELLE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF9600),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.volume_up_rounded, color: Color(0xFFFF9600)),
                onPressed: () => _speak(scenario.dialogueGerman),
                tooltip: 'Écouter la question en allemand',
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Bulle de dialogue du locuteur allemand
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2213) : const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFF9600).withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.record_voice_over_rounded, size: 16, color: Color(0xFFFF9600)),
                    const SizedBox(width: 6),
                    Text(
                      scenario.speakerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: Color(0xFFFF9600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  scenario.dialogueGerman,
                  style: AppTextStyles.titleSmall(isDark: isDark).copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Divider(
                  height: 1,
                  color: (isDark ? Colors.white12 : Colors.black12),
                ),
                const SizedBox(height: 8),
                Text(
                  scenario.situationArabic,
                  style: const TextStyle(
                    fontFamily: 'NotoSansArabic',
                    fontSize: 14,
                    color: Color(0xFFE65100),
                    height: 1.4,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'Quelle est la réponse la plus adaptée parmi vos 10 phrases ?',
            style: AppTextStyles.bodyMedium(isDark: isDark).copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 10),

          // Les 4 choix
          ...question.choices.map((choice) => _buildChoiceTile(choice, question, isDark: isDark)),
        ],
      ),
    );
  }

  Widget _buildChoiceTile(String choice, MasterQuestion question, {required bool isDark}) {
    final targetDe = question.phrase.deParle.isNotEmpty
        ? question.phrase.deParle
        : question.phrase.de;
    final isSelected = _selectedChoice == choice;
    final isTarget = choice == targetDe;

    Color tileColor;
    Color borderColor;
    Color textColor;

    if (!_isAnswerChecked) {
      tileColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
      borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
      textColor = isDark ? Colors.white : Colors.black87;
    } else {
      if (isTarget) {
        tileColor = const Color(0xFF1B5E20).withValues(alpha: isDark ? 0.3 : 0.15);
        borderColor = AppColors.primary;
        textColor = isDark ? AppColors.primaryLight : AppColors.primaryDark;
      } else if (isSelected && !isTarget) {
        tileColor = Colors.red.withValues(alpha: isDark ? 0.25 : 0.12);
        borderColor = Colors.red;
        textColor = Colors.red;
      } else {
        tileColor = isDark ? AppColors.surfaceDark.withValues(alpha: 0.5) : Colors.grey.shade100;
        borderColor = Colors.transparent;
        textColor = Colors.grey;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: _isAnswerChecked ? null : () => _verifyChoice(choice),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: tileColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: isSelected || isTarget ? 2 : 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  choice,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
              if (_isAnswerChecked && isTarget)
                const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 22)
              else if (_isAnswerChecked && isSelected && !isTarget)
                const Icon(Icons.cancel_rounded, color: Colors.red, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // FEEDBACK APRES VALIDATION
  // ==========================================
  Widget _buildFeedbackCard(MasterQuestion question, {required bool isDark}) {
    final phrase = question.phrase;
    final targetDe = phrase.deParle.isNotEmpty ? phrase.deParle : phrase.de;
    final scenario = question.scenario;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isCurrentCorrect
            ? (isDark ? const Color(0xFF132B1E) : const Color(0xFFE8F5E9))
            : (isDark ? const Color(0xFF2C1315) : const Color(0xFFFFEBEE)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isCurrentCorrect ? AppColors.primary : Colors.red,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isCurrentCorrect ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                color: _isCurrentCorrect ? AppColors.primary : Colors.red,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _feedbackMessage ?? '',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _isCurrentCorrect ? AppColors.primary : Colors.red,
                    fontSize: 15,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.volume_up_rounded),
                color: _isCurrentCorrect ? AppColors.primary : Colors.red,
                onPressed: () => _speak(targetDe, phraseId: phrase.id),
                tooltip: 'Écouter la prononciation',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Réponse correcte : $targetDe',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          if (question.type == ExerciseTypeInMaster.respondToSituation) ...[
            const SizedBox(height: 6),
            Text(
              '💡 ${scenario.explanationGerman}',
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              scenario.explanationArabic,
              style: const TextStyle(
                fontFamily: 'NotoSansArabic',
                fontSize: 13,
                color: Color(0xFF2E7D32),
              ),
              textDirection: TextDirection.rtl,
            ),
          ] else if (phrase.note != null && phrase.note!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '💡 ${phrase.note}',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // BARRE D'ACTION INFERIEURE
  // ==========================================
  Widget _buildBottomActionBar(MasterQuestion question, {required bool isDark}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        border: Border(top: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (!_isAnswerChecked &&
                question.type == ExerciseTypeInMaster.translateArabicToGerman &&
                _useKeyboardForExercise1)
              Expanded(
                child: DuoButton(
                  label: 'Vérifier ma réponse',
                  icon: Icons.check_circle_outline_rounded,
                  variant: DuoButtonVariant.primary,
                  onPressed: _verifyKeyboardInput,
                ),
              )
            else if (_isAnswerChecked)
              Expanded(
                child: DuoButton(
                  label: _currentIndex + 1 < _questions.length ? 'Continuer' : 'Voir mon bilan',
                  icon: Icons.arrow_forward_rounded,
                  variant: _isCurrentCorrect ? DuoButtonVariant.primary : DuoButtonVariant.secondary,
                  onPressed: _goToNextQuestion,
                ),
              )
            else
              Expanded(
                child: Text(
                  'Sélectionne une réponse parmi tes 10 phrases ci-dessus',
                  style: AppTextStyles.caption(isDark: isDark),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // ÉCRAN DE FIN DE MASTER XP (Célébration)
  // ==========================================
  Widget _buildCompletionView({required bool isDark}) {
    final successPercent = ((_score / _questions.length) * 100).round();

    return DuoConfettiOverlay(
      isPlaying: true,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              children: [
                const SizedBox(height: 20),
                const MascotWidget(
                  mood: MascotMood.celebrating,
                  size: 110,
                ),
                const SizedBox(height: 20),
                Text(
                  'Félicitations Master XP ! 🏆',
                  style: AppTextStyles.titleMedium(isDark: isDark).copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 26,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tu as validé la maîtrise de ton lot de 10 phrases avec brio.',
                  style: AppTextStyles.bodyMedium(isDark: isDark),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                CustomCard(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 28),
                          const SizedBox(height: 6),
                          Text(
                            '$_score / ${_questions.length}',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                          ),
                          const Text('Score', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                      Container(height: 40, width: 1, color: isDark ? AppColors.borderDark : AppColors.borderLight),
                      Column(
                        children: [
                          const Icon(Icons.bolt_rounded, color: Color(0xFFFF9600), size: 28),
                          const SizedBox(height: 6),
                          Text(
                            '+$_xpEarned XP',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFFFF9600)),
                          ),
                          const Text('Points XP', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                      Container(height: 40, width: 1, color: isDark ? AppColors.borderDark : AppColors.borderLight),
                      Column(
                        children: [
                          const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFB700), size: 28),
                          const SizedBox(height: 6),
                          Text(
                            '$successPercent %',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                          ),
                          const Text('Réussite', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                DuoButton(
                  label: 'Rejouer le Master XP',
                  icon: Icons.refresh_rounded,
                  variant: DuoButtonVariant.outline,
                  onPressed: () {
                    setState(() {
                      _currentIndex = 0;
                      _score = 0;
                      _xpEarned = 0;
                      _isCompleted = false;
                      _buildQuestions();
                      _resetQuestionState();
                    });
                  },
                ),
                const SizedBox(height: 12),
                DuoButton(
                  label: "Retour à l'accueil",
                  icon: Icons.home_rounded,
                  variant: DuoButtonVariant.primary,
                  onPressed: () => context.go('/home'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
