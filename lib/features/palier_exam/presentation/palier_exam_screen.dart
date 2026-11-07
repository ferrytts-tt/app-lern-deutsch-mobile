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
import '../../../core/widgets/german_text_annotator.dart';
import '../../../core/widgets/mascot_widget.dart';
import '../../../data/database/app_database.dart';
import '../../../domain/engine/palier_exam_generator.dart';
import '../../../domain/models/phrase.dart';
import '../../raetsel/domain/raetsel_manager.dart';
import '../../sync/data/sync_service.dart';

/// Grand Examen de Palier (Tous les 30 phrases).
/// - 30 questions couvrant les 30 phrases du palier
/// - Barème : sur 30 points
/// - Seuil de passage : 20/30 minimum pour être approuvé
/// - Si < 20/30 : recalé, le lot suivant reste verrouillé et le candidat doit réessayer
class PalierExamScreen extends StatefulWidget {
  final int palierIndex; // 1 pour phrases 1-30, 2 pour phrases 31-60, etc.
  final List<Phrase>? phrases; // Si passées directement

  const PalierExamScreen({
    super.key,
    required this.palierIndex,
    this.phrases,
  });

  @override
  State<PalierExamScreen> createState() => _PalierExamScreenState();
}

class _PalierExamScreenState extends State<PalierExamScreen> {
  bool _isLoading = true;
  bool _isLocked = false;
  int _completedPhrasesCount = 0;
  List<Phrase> _thirtyPhrases = [];
  List<PalierExamQuestion> _questions = [];

  int _currentIndex = 0;
  int _score = 0;
  final List<bool> _answersResults = []; // true si correct, false sinon
  final List<PalierExamQuestion> _failedQuestions = [];

  bool _isAnswerChecked = false;
  bool _isCurrentCorrect = false;
  String? _selectedQcmChoice;

  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();

  bool _isListening = false;
  bool _isCompleted = false;
  int _examJokers = 0;

  // ── State pour les nouveaux types d'exercices d'examen ─────────────
  // 1. Système Duolingo (Recomposition par blocs de mots)
  List<String> _duoSelectedWords = [];
  List<bool> _duoWordUsed = [];

  // 2. Phrases à trous multiples (2 à 3 vides)
  List<String?> _multiBlankAnswers = [];
  List<bool> _multiBlankOptionUsed = [];
  int _activeBlankIndex = 0;

  // 3. Compréhension Orale (Hörverstehen)
  bool _isAudioPlaying = false;

  @override
  void initState() {
    super.initState();
    _loadExamData();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _inputFocusNode.dispose();
    TtsService.instance.stop();
    PronunciationService.instance.stopListening();
    super.dispose();
  }

  Future<void> _loadExamData() async {
    final prefs = await SharedPreferences.getInstance();
    final jokers = prefs.getInt('exam_joker_count') ?? 0;

    List<Phrase> candidatePhrases = [];

    if (widget.phrases != null && widget.phrases!.isNotEmpty) {
      candidatePhrases = widget.phrases!;
    } else {
      final all = await AppDatabase.instance.getAllPhrases();
      final startIndex = (widget.palierIndex - 1) * 30;
      final endIndex = (startIndex + 30).clamp(0, all.length);

      if (startIndex < all.length) {
        candidatePhrases = all.sublist(startIndex, endIndex);
      }
    }

    if (candidatePhrases.isEmpty) {
      final all = await AppDatabase.instance.getAllPhrases();
      candidatePhrases = all.take(30).toList();
    }

    _thirtyPhrases = candidatePhrases;

    // Vérification stricte des prérequis :
    // Tous les 3 lots du palier doivent être validés (les 30 phrases terminées)
    // ou l'examen doit déjà avoir été réussi.
    final allUserPhrases = await AppDatabase.instance.getAllUserPhrases();
    int completedCount = 0;
    for (final p in candidatePhrases) {
      final prog = allUserPhrases[p.id];
      if (prog != null && (prog.level > 0 || prog.reps > 0)) {
        completedCount++;
      }
    }

    final isPassed = prefs.getBool('palier_exam_${widget.palierIndex}_passed') ?? false;
    final bool isLocked = !isPassed && (candidatePhrases.isNotEmpty && completedCount < candidatePhrases.length);

    if (!isLocked) {
      _questions = PalierExamGenerator.generate30Questions(
        thirtyPhrases: _thirtyPhrases,
        palierIndex: widget.palierIndex,
      );
    }

    if (mounted) {
      setState(() {
        _examJokers = jokers;
        _isLocked = isLocked;
        _completedPhrasesCount = completedCount;
        _isLoading = false;
        if (!_isLocked) {
          _resetForQuestion(0);
        }
      });
    }
  }

  void _resetForQuestion(int index) {
    _currentIndex = index;
    _isAnswerChecked = false;
    _isCurrentCorrect = false;
    _selectedQcmChoice = null;
    _inputController.clear();
    _isListening = false;
    _isAudioPlaying = false;

    if (index < _questions.length) {
      final q = _questions[index];

      // Réinitialisation Système Duolingo
      _duoSelectedWords = [];
      _duoWordUsed = List.filled(q.wordBank.length, false);

      // Réinitialisation Trous Multiples (2 à 3 vides)
      _multiBlankAnswers = List.filled(q.expectedBlanks.length, null);
      _multiBlankOptionUsed = List.filled(q.blankBankOptions.length, false);
      _activeBlankIndex = 0;

      // Lecture audio automatique douce pour la compréhension orale
      if (q.type == PalierQuestionType.audioListening) {
        Future.delayed(const Duration(milliseconds: 350), () {
          if (mounted && _currentIndex == index && !_isAnswerChecked) {
            _playQuestionAudio(isSlow: false);
          }
        });
      }
    }
  }

  void _playQuestionAudio({bool isSlow = false}) async {
    if (_currentIndex >= _questions.length) return;
    final phrase = _questions[_currentIndex].phrase;
    setState(() => _isAudioPlaying = true);
    if (isSlow) {
      await TtsService.instance.speak(phrase.deParle, slow: true);
    } else {
      await TtsService.instance.speak(phrase.deParle);
    }
    if (mounted) setState(() => _isAudioPlaying = false);
  }

  bool get _canValidateCurrentQuestion {
    if (_isAnswerChecked || _currentIndex >= _questions.length) return false;
    final q = _questions[_currentIndex];
    switch (q.type) {
      case PalierQuestionType.contextualQcm:
      case PalierQuestionType.standardToSpoken:
      case PalierQuestionType.audioListening:
        return _selectedQcmChoice != null;
      case PalierQuestionType.duolingoWordRebuild:
        return _duoSelectedWords.isNotEmpty;
      case PalierQuestionType.multiBlankFill:
        return !_multiBlankAnswers.any((a) => a == null || a.isEmpty);
      case PalierQuestionType.singleBlankFill:
        return _inputController.text.trim().isNotEmpty;
    }
  }

  void _validateAnswer() {
    if (_isAnswerChecked || _currentIndex >= _questions.length) return;

    final q = _questions[_currentIndex];
    bool isCorrect = false;

    switch (q.type) {
      case PalierQuestionType.contextualQcm:
      case PalierQuestionType.standardToSpoken:
      case PalierQuestionType.audioListening:
        if (_selectedQcmChoice == null) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Sélectionne une réponse avant de valider !'),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
        isCorrect = TextSimilarity.normalize(_selectedQcmChoice!) ==
            TextSimilarity.normalize(q.expectedAnswer);
        break;

      case PalierQuestionType.duolingoWordRebuild:
        final userSentence = _duoSelectedWords.join(' ').trim();
        if (userSentence.isEmpty) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Touche les blocs de mots pour former la phrase !'),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
        final evalMain = TextSimilarity.evaluate(userSentence, q.expectedAnswer);
        isCorrect = evalMain.isCorrect;
        if (!isCorrect) {
          for (final alt in q.alternativeAnswers) {
            if (TextSimilarity.evaluate(userSentence, alt).isCorrect) {
              isCorrect = true;
              break;
            }
          }
        }
        break;

      case PalierQuestionType.multiBlankFill:
        if (_multiBlankAnswers.any((ans) => ans == null || ans.isEmpty)) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Remplis tous les trous avant de valider !'),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
        int matched = 0;
        for (int i = 0; i < q.expectedBlanks.length; i++) {
          final userWord = _multiBlankAnswers[i] ?? '';
          final targetWord = q.expectedBlanks[i];
          if (TextSimilarity.normalize(userWord) == TextSimilarity.normalize(targetWord)) {
            matched++;
          }
        }
        // Tous les trous doivent être corrects (tolérance 2/3 si 3 trous)
        isCorrect = matched == q.expectedBlanks.length ||
            (q.expectedBlanks.length == 3 && matched >= 2);
        break;

      case PalierQuestionType.singleBlankFill:
        final userInput = _inputController.text.trim();
        if (userInput.isEmpty) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Tape ou dicte ta réponse avant de valider !'),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }

        final evalMain = TextSimilarity.evaluate(userInput, q.expectedAnswer);
        isCorrect = evalMain.isCorrect;

        if (!isCorrect) {
          for (final alt in q.alternativeAnswers) {
            if (TextSimilarity.evaluate(userInput, alt).isCorrect) {
              isCorrect = true;
              break;
            }
          }
        }
        break;
    }

    if (isCorrect) {
      PronunciationService.instance.playSuccessSound();
      _score++;
    } else {
      PronunciationService.instance.playFailureSound();
      _failedQuestions.add(q);
    }

    _answersResults.add(isCorrect);

    setState(() {
      _isAnswerChecked = true;
      _isCurrentCorrect = isCorrect;
    });

    // Prononciation audio naturelle du corrigé
    TtsService.instance.speak(q.phrase.deParle);
  }

  void _goToNextQuestion() {
    if (_currentIndex + 1 < _questions.length) {
      setState(() {
        _resetForQuestion(_currentIndex + 1);
      });
    } else {
      _finishExam();
    }
  }

  Future<void> _finishExam() async {
    final passed = _score >= 20;
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt('palier_exam_${widget.palierIndex}_score', _score);
    await prefs.setString(
      'palier_exam_${widget.palierIndex}_date',
      DateTime.now().toIso8601String(),
    );

    if (passed) {
      await prefs.setBool('palier_exam_${widget.palierIndex}_passed', true);

      // Débloquer le lot suivant
      final currentUnlocked = prefs.getInt('unlocked_palier_max') ?? 1;
      if (widget.palierIndex >= currentUnlocked) {
        await prefs.setInt('unlocked_palier_max', widget.palierIndex + 1);
      }

      // Débloquer Hoppla Rätsel au même moment que l'ouverture du Lot 4 (Palier 1)
      if (widget.palierIndex == 1) {
        await RaetselManager.instance.onExam1Passed(prefs: prefs);
      }

      // Bonus XP (+100) et Diamants (+25) pour réussite du Grand Examen
      final currentXp = prefs.getInt('total_xp') ?? 0;
      await prefs.setInt('total_xp', currentXp + 100);
      final currentGems = prefs.getInt('total_gems') ?? 0;
      await prefs.setInt('total_gems', currentGems + 25);
    }

    // Synchroniser le résultat de l'examen avec le cloud Supabase
    SyncService().recordPalierExamSuccess(
      palierIndex: widget.palierIndex,
      score: _score,
      totalQuestions: _questions.length,
      passed: passed,
    );

    setState(() {
      _isCompleted = true;
    });
  }

  Future<void> _useJokerSecondeChance() async {
    if (_examJokers <= 0) return;
    final prefs = await SharedPreferences.getInstance();
    final newJokers = _examJokers - 1;
    await prefs.setInt('exam_joker_count', newJokers);

    PronunciationService.instance.playSuccessSound();

    setState(() {
      _examJokers = newJokers;
      _score = 20;
    });

    await _finishExam();
  }

  void _toggleListening() {
    if (_isListening) {
      PronunciationService.instance.stopListening();
      if (mounted) setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      final started = PronunciationService.instance.startListening(
        onResult: (text, isFinal) {
          if (mounted) {
            setState(() {
              _inputController.text = text;
              if (isFinal) {
                _isListening = false;
              }
            });
          }
        },
        onError: (err) {
          if (mounted) setState(() => _isListening = false);
        },
        onEnd: (text) {
          if (mounted) setState(() => _isListening = false);
        },
      );
      if (!started && mounted) {
        setState(() => _isListening = false);
      }
    }
  }

  void _restartExam() {
    setState(() {
      _isLoading = true;
      _score = 0;
      _answersResults.clear();
      _failedQuestions.clear();
      _isCompleted = false;
    });
    _loadExamData();
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

    if (_isLocked) {
      return _buildLockedScreen(isDark);
    }

    if (_isCompleted) {
      return _buildResultScreen(isDark);
    }

    final currentQuestion = _questions[_currentIndex];
    final progressFraction = (_currentIndex + 1) / _questions.length;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: _showExitConfirmationDialog,
        ),
        title: Column(
          children: [
            Text(
              'EXAMEN DU PALIER ${widget.palierIndex}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Barème : $_score / 30 · Min. 20/30 pour approuver',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _score >= 20 ? const Color(0xFF16A34A) : Colors.grey,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── 1. Barre de progression 1 à 30 ───────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Question ${_currentIndex + 1} sur ${_questions.length}',
                        style: AppTextStyles.caption(isDark: isDark).copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _score >= 20
                              ? const Color(0xFF16A34A).withValues(alpha: 0.15)
                              : (isDark ? Colors.white10 : Colors.black12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Score : $_score/30',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _score >= 20 ? const Color(0xFF16A34A) : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progressFraction,
                      minHeight: 8,
                      backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _score >= 20 ? const Color(0xFF16A34A) : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── 2. Corps de la question ──────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Badge du type de question
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1B2F23) : const Color(0xFFE8F5EC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          currentQuestion.titlePrompt,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Carte principale de la situation / question
                    CustomCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentQuestion.contextSituation,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          if (currentQuestion.blankPhrase != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F1A14) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Text(
                                currentQuestion.blankPhrase!,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                  color: AppColors.primary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── 3. Interface de réponse selon le type (6 variantes stimulantes) ──
                    if (currentQuestion.type == PalierQuestionType.contextualQcm ||
                        currentQuestion.type == PalierQuestionType.standardToSpoken)
                      _buildQcmInterface(currentQuestion, isDark)
                    else if (currentQuestion.type == PalierQuestionType.duolingoWordRebuild)
                      _buildDuolingoInterface(currentQuestion, isDark)
                    else if (currentQuestion.type == PalierQuestionType.multiBlankFill)
                      _buildMultiBlankInterface(currentQuestion, isDark)
                    else if (currentQuestion.type == PalierQuestionType.audioListening)
                      _buildAudioListeningInterface(currentQuestion, isDark)
                    else
                      _buildSingleBlankInterface(currentQuestion, isDark),
                  ],
                ),
              ),
            ),

            // ── 4. Barre d'action inférieure (Validation ou Suivant) ───
            _buildBottomBar(isDark),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Type 1 & 5 : QCM contextuel & Standard vers Parlé
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildQcmInterface(PalierExamQuestion q, bool isDark) {
    return Column(
      children: q.qcmChoices.map((choice) {
        final isSelected = _selectedQcmChoice == choice;
        final isCorrectChoice = TextSimilarity.normalize(choice) ==
            TextSimilarity.normalize(q.expectedAnswer);

        Color? bgColor;
        Color? borderColor;

        if (_isAnswerChecked) {
          if (isCorrectChoice) {
            bgColor = const Color(0xFF16A34A).withValues(alpha: 0.2);
            borderColor = const Color(0xFF16A34A);
          } else if (isSelected && !_isCurrentCorrect) {
            bgColor = Colors.red.withValues(alpha: 0.2);
            borderColor = Colors.red;
          }
        } else if (isSelected) {
          bgColor = AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.15);
          borderColor = AppColors.primary;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: _isAnswerChecked ? null : () => setState(() => _selectedQcmChoice = choice),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: bgColor ?? (isDark ? const Color(0xFF1E293B) : Colors.white),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: borderColor ?? (isDark ? Colors.white12 : Colors.black12),
                  width: isSelected || (_isAnswerChecked && isCorrectChoice) ? 2 : 1,
                ),
                boxShadow: isSelected && !_isAnswerChecked
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          offset: const Offset(0, 3),
                          blurRadius: 0,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GermanTextView(
                      text: choice,
                      baseStyle: TextStyle(
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  if (_isAnswerChecked && isCorrectChoice)
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 22)
                  else if (_isAnswerChecked && isSelected && !_isCurrentCorrect)
                    const Icon(Icons.cancel_rounded, color: Colors.red, size: 22)
                  else if (isSelected)
                    const Icon(Icons.radio_button_checked_rounded, color: AppColors.primary, size: 20),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Type 2 : Système Duolingo (Recomposition de phrase par blocs de mots 3D)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildDuolingoInterface(PalierExamQuestion q, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Zone de dépôt des mots choisis (Ligne de composition Duolingo)
        Container(
          constraints: const BoxConstraints(minHeight: 100),
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
              width: 2,
            ),
          ),
          child: _duoSelectedWords.isEmpty
              ? Center(
                  child: Text(
                    'Touche les blocs de mots ci-dessous pour former la phrase...',
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 10,
                  children: List.generate(_duoSelectedWords.length, (idx) {
                    final word = _duoSelectedWords[idx];
                    return GestureDetector(
                      onTap: _isAnswerChecked ? null : () => _unselectDuoWord(idx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF334155) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              offset: const Offset(0, 3),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              word,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            if (!_isAnswerChecked) ...[
                              const SizedBox(width: 6),
                              Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: isDark ? Colors.white54 : Colors.black45,
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
                ),
        ),

        const SizedBox(height: 10),

        // Bouton pour tout effacer rapidement si besoin
        if (!_isAnswerChecked && _duoSelectedWords.isNotEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _duoSelectedWords.clear();
                  _duoWordUsed = List.filled(q.wordBank.length, false);
                });
              },
              icon: const Icon(Icons.refresh_rounded, size: 16, color: Colors.grey),
              label: const Text(
                'Réinitialiser les mots',
                style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
              ),
            ),
          ),

        const SizedBox(height: 12),

        // Banque de tuiles de mots style Duolingo
        Wrap(
          spacing: 8,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: List.generate(q.wordBank.length, (i) {
            final word = q.wordBank[i];
            final isUsed = i < _duoWordUsed.length ? _duoWordUsed[i] : false;

            if (isUsed) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.black12,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  word,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.transparent, // Effet vide style Duolingo
                  ),
                ),
              );
            }

            return GestureDetector(
              onTap: _isAnswerChecked ? null : () => _selectDuoWord(i, word),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF1CB0F6),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1899D6).withValues(alpha: 0.35),
                      offset: const Offset(0, 3),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Text(
                  word,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  void _selectDuoWord(int bankIndex, String word) {
    setState(() {
      _duoWordUsed[bankIndex] = true;
      _duoSelectedWords.add(word);
    });
  }

  void _unselectDuoWord(int selectedIndex) {
    final word = _duoSelectedWords[selectedIndex];
    final bankIndex = _questions[_currentIndex].wordBank.indexOf(word);
    setState(() {
      _duoSelectedWords.removeAt(selectedIndex);
      if (bankIndex != -1 && bankIndex < _duoWordUsed.length) {
        _duoWordUsed[bankIndex] = false;
      }
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Type 3 : Phrase à plusieurs trous (2 à 3 vides)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildMultiBlankInterface(PalierExamQuestion q, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Carte visuelle montrant les 2 ou 3 cases de trous numérotées
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trous à compléter (${q.expectedBlanks.length} vides) :',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: List.generate(q.expectedBlanks.length, (blankIdx) {
                  final filledWord = blankIdx < _multiBlankAnswers.length
                      ? _multiBlankAnswers[blankIdx]
                      : null;
                  final isCurrentActive = _activeBlankIndex == blankIdx;

                  return GestureDetector(
                    onTap: _isAnswerChecked
                        ? null
                        : () {
                            if (filledWord != null) {
                              _clearMultiBlank(blankIdx);
                            } else {
                              setState(() => _activeBlankIndex = blankIdx);
                            }
                          },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: filledWord != null
                            ? (isDark ? const Color(0xFF1B382B) : const Color(0xFFE8F5E9))
                            : (isCurrentActive
                                ? AppColors.primary.withValues(alpha: 0.15)
                                : (isDark ? Colors.white10 : const Color(0xFFF1F5F9))),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: filledWord != null
                              ? AppColors.primary
                              : (isCurrentActive ? AppColors.primary : Colors.grey.withValues(alpha: 0.5)),
                          width: isCurrentActive || filledWord != null ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${blankIdx + 1}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            filledWord ?? '______',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: filledWord != null
                                  ? (isDark ? Colors.white : AppColors.primaryDark)
                                  : Colors.grey,
                            ),
                          ),
                          if (filledWord != null && !_isAnswerChecked) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.close_rounded, size: 16, color: Colors.grey),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Banque d'options cliquables pour remplir les trous
        Text(
          'Mots disponibles (clique pour insérer dans le trou) :',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        const SizedBox(height: 10),

        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: List.generate(q.blankBankOptions.length, (optIdx) {
            final word = q.blankBankOptions[optIdx];
            final isUsed = optIdx < _multiBlankOptionUsed.length
                ? _multiBlankOptionUsed[optIdx]
                : false;

            if (isUsed) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.transparent),
                ),
                child: Text(
                  word,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.transparent,
                  ),
                ),
              );
            }

            return GestureDetector(
              onTap: _isAnswerChecked ? null : () => _fillBlankWithWord(optIdx, word),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF1CB0F6),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1899D6).withValues(alpha: 0.35),
                      offset: const Offset(0, 3),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Text(
                  word,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
            );
          }),
        ),

        if (!_isAnswerChecked && _multiBlankAnswers.any((a) => a != null)) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _multiBlankAnswers = List.filled(q.expectedBlanks.length, null);
                  _multiBlankOptionUsed = List.filled(q.blankBankOptions.length, false);
                  _activeBlankIndex = 0;
                });
              },
              icon: const Icon(Icons.refresh_rounded, size: 16, color: Colors.grey),
              label: const Text(
                'Vider tous les trous',
                style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _fillBlankWithWord(int optionIndex, String word) {
    int targetBlank = _activeBlankIndex;
    if (targetBlank >= _multiBlankAnswers.length || _multiBlankAnswers[targetBlank] != null) {
      targetBlank = _multiBlankAnswers.indexWhere((a) => a == null || a.isEmpty);
    }
    if (targetBlank == -1) targetBlank = 0;

    setState(() {
      _multiBlankOptionUsed[optionIndex] = true;
      _multiBlankAnswers[targetBlank] = word;
      // Passer au trou vide suivant
      final nextEmpty = _multiBlankAnswers.indexWhere((a) => a == null || a.isEmpty);
      _activeBlankIndex = nextEmpty != -1 ? nextEmpty : 0;
    });
  }

  void _clearMultiBlank(int blankIdx) {
    final word = _multiBlankAnswers[blankIdx];
    if (word == null) return;
    final optIdx = _questions[_currentIndex].blankBankOptions.indexOf(word);
    setState(() {
      _multiBlankAnswers[blankIdx] = null;
      if (optIdx != -1 && optIdx < _multiBlankOptionUsed.length) {
        _multiBlankOptionUsed[optIdx] = false;
      }
      _activeBlankIndex = blankIdx;
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Type 4 : Compréhension Orale / Écoute Audio (Hörverstehen)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildAudioListeningInterface(PalierExamQuestion q, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Panneau Audio interactif (Style Duolingo / Goethe Hörverstehen)
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFF1CB0F6).withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      backgroundColor: const Color(0xFF1CB0F6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 3,
                    ),
                    icon: Icon(
                      _isAudioPlaying ? Icons.graphic_eq_rounded : Icons.volume_up_rounded,
                      size: 24,
                    ),
                    label: Text(
                      _isAudioPlaying ? 'Lecture...' : 'Écouter l\'audio',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => _playQuestionAudio(isSlow: false),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      foregroundColor: const Color(0xFF1CB0F6),
                      side: const BorderSide(color: Color(0xFF1CB0F6), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.speed_rounded, size: 20),
                    label: const Text(
                      '0.65x Lent',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => _playQuestionAudio(isSlow: true),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Choisis ci-dessous la phrase exacte prononcée :',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Choix QCM de compréhension orale
        _buildQcmInterface(q, isDark),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Type 6 : Mot manquant ciblé (Clavier ou Dictée vocale)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSingleBlankInterface(PalierExamQuestion q, bool isDark) {
    return _buildTextOrVoiceInterface(q, isDark);
  }

  Widget _buildTextOrVoiceInterface(PalierExamQuestion q, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Champ texte
        TextField(
          controller: _inputController,
          focusNode: _inputFocusNode,
          enabled: !_isAnswerChecked,
          autofocus: true,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: 'Tape ou dicte ta réponse en allemand...',
            hintStyle: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isDark ? Colors.white12 : Colors.black12,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                color: _isListening ? Colors.red : AppColors.primary,
                size: 26,
              ),
              tooltip: 'Répondre à la voix',
              onPressed: _isAnswerChecked ? null : _toggleListening,
            ),
          ),
          onSubmitted: (_) {
            if (!_isAnswerChecked && _inputController.text.trim().isNotEmpty) {
              _validateAnswer();
            }
          },
        ),

        const SizedBox(height: 12),

        // Indication d'écoute vocale
        if (_isListening)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
                ),
                SizedBox(width: 8),
                Text(
                  'Écoute en cours... Parle en allemand.',
                  style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildBottomBar(bool isDark) {
    final canValidate = _canValidateCurrentQuestion;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1A14) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white10 : Colors.black12,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Feedback après vérification
          if (_isAnswerChecked) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isCurrentCorrect
                    ? const Color(0xFF16A34A).withValues(alpha: 0.15)
                    : Colors.red.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isCurrentCorrect ? const Color(0xFF16A34A) : Colors.red,
                  width: 1.2,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _isCurrentCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: _isCurrentCorrect ? const Color(0xFF16A34A) : Colors.red,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isCurrentCorrect ? 'Correct ! (+1 point)' : 'Incorrect (0 point)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _isCurrentCorrect ? const Color(0xFF16A34A) : Colors.red,
                          ),
                        ),
                        if (!_isCurrentCorrect) ...[
                          const SizedBox(height: 4),
                          const Text(
                            'Bonne réponse attendue :',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          const SizedBox(height: 2),
                          GermanTextView(
                            text: _questions[_currentIndex].phrase.deParle,
                            baseStyle: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.volume_up_rounded, color: AppColors.primary),
                    tooltip: 'Réécouter la prononciation',
                    onPressed: () => TtsService.instance.speak(
                      _questions[_currentIndex].phrase.deParle,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Bouton principal
          SizedBox(
            width: double.infinity,
            child: DuoButton(
              label: _isAnswerChecked
                  ? (_currentIndex + 1 < _questions.length
                      ? 'Question suivante (${_currentIndex + 2}/30)'
                      : 'Voir les résultats de l\'examen')
                  : 'Valider ma réponse',
              icon: _isAnswerChecked ? Icons.arrow_forward_rounded : Icons.check_rounded,
              variant: _isAnswerChecked
                  ? DuoButtonVariant.primary
                  : (canValidate ? DuoButtonVariant.primary : DuoButtonVariant.outline),
              onPressed: _isAnswerChecked ? _goToNextQuestion : _validateAnswer,
            ),
          ),
        ],
      ),
    );
  }

  /// Écran d'état verrouillé lorsque les 3 lots du palier ne sont pas encore validés à 100%
  Widget _buildLockedScreen(bool isDark) {
    final lotA = (widget.palierIndex - 1) * 3 + 1;
    final lotB = lotA + 1;
    final lotC = lotA + 2;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'EXAMEN DU PALIER ${widget.palierIndex}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
            color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const MascotWidget(size: 130),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  size: 44,
                  color: Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Examen Verrouillé',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Pour débloquer cet examen, vous devez obligatoirement valider l\'ensemble des 3 lots du palier :\nLots L$lotA, L$lotB et L$lotC.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF14241B) : const Color(0xFFE8F5EC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.school_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Progression : $_completedPhrasesCount / ${_thirtyPhrases.length} phrases terminées',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: DuoButton(
                  label: 'Retour au parcours',
                  icon: Icons.arrow_back_rounded,
                  variant: DuoButtonVariant.primary,
                  onPressed: () => context.pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Écran final : Bilan officiel sur 30 points
  Widget _buildResultScreen(bool isDark) {
    final passed = _score >= 20;

    return DuoConfettiOverlay(
      isPlaying: passed,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                  // Mascotte
                  MascotWidget(
                    mood: passed ? MascotMood.celebrating : MascotMood.confused,
                    size: 110,
                  ),

                  const SizedBox(height: 20),

                  // Titre de statut
                  Text(
                    passed ? 'EXAMEN APPROUVÉ ! 🎉' : 'EXAMEN NON VALIDÉ ❌',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: passed ? const Color(0xFF16A34A) : Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  Text(
                    passed
                        ? 'Félicitations ! Tu as validé le Palier ${widget.palierIndex}. Le lot suivant est officiellement débloqué !'
                        : 'Il te faut au moins 20/30 pour débloquer le lot suivant. Tu dois repasser le test.',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 24),

                  // Carte de score sur 30
                  CustomCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          '$_score / 30',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: passed ? const Color(0xFF16A34A) : Colors.red,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: passed
                                ? const Color(0xFF16A34A).withValues(alpha: 0.15)
                                : Colors.red.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            passed
                                ? 'Seuil 20/30 atteint (${((_score / 30) * 100).round()}%)'
                                : 'Échec : seuil de 20/30 non atteint (${((_score / 30) * 100).round()}%)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: passed ? const Color(0xFF16A34A) : Colors.red,
                            ),
                          ),
                        ),
                        if (passed) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('🎁', style: TextStyle(fontSize: 14)),
                                SizedBox(width: 6),
                                Text(
                                  '+25 💎  et  +100 XP ajoutés à ton solde !',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    color: Color(0xFF0284C7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Option Joker Seconde Chance (Boutique)
                  if (!passed && _score >= 18 && _examJokers > 0) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2E1A0C) : const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFFEA580C).withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('☕', style: TextStyle(fontSize: 20)),
                              SizedBox(width: 8),
                              Text(
                                'JOKER SECONDE CHANCE DISPONIBLE',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                  color: Color(0xFFEA580C),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tu as obtenu $_score/30. Ton Joker de la Boutique efface tes fautes et te permet de valider le palier à 20/30 !',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.35,
                              color: isDark ? Colors.white70 : const Color(0xFF7C2D12),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          DuoButton(
                            label: '☕ Utiliser mon Joker & Valider (20/30) !',
                            variant: DuoButtonVariant.secondary,
                            icon: Icons.auto_awesome_rounded,
                            onPressed: _useJokerSecondeChance,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Boutons d'action
                  if (passed) ...[
                    DuoButton(
                      label: 'Débloquer et continuer vers le lot suivant',
                      icon: Icons.check_circle_outline_rounded,
                      variant: DuoButtonVariant.primary,
                      onPressed: () {
                        context.go('/home');
                      },
                    ),
                  ] else ...[
                    DuoButton(
                      label: '🔄 Réessayer l\'examen (30 questions)',
                      icon: Icons.refresh_rounded,
                      variant: DuoButtonVariant.primary,
                      onPressed: _restartExam,
                    ),
                    const SizedBox(height: 12),
                    DuoButton(
                      label: '📚 Revoir les phrases d\'abord',
                      icon: Icons.menu_book_rounded,
                      variant: DuoButtonVariant.outline,
                      onPressed: () {
                        context.go('/home');
                      },
                    ),
                  ],

                  // Phrases à retravailler si échec
                  if (_failedQuestions.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Phrases à réviser (${_failedQuestions.length}) :',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._failedQuestions.map((q) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark ? Colors.white10 : Colors.black12,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.help_outline_rounded,
                                    size: 16, color: Colors.orange),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        q.phrase.deParle,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      if (q.phrase.fr.isNotEmpty)
                                        Text(
                                          q.phrase.fr,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.volume_up_rounded, size: 20),
                                  onPressed: () => TtsService.instance.speak(q.phrase.deParle),
                                ),
                              ],
                            ),
                          ),
                        )),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
  }

  void _showExitConfirmationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Quitter l\'examen en cours ?'),
        content: const Text(
          'Si tu quittes maintenant, l\'examen sera annulé et le palier suivant restera strictement verrouillé.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Continuer l\'examen'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.pop();
            },
            child: const Text('Quitter', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
