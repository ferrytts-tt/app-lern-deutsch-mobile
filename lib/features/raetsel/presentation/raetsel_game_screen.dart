import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_lern_deutsch_mobile/core/theme/app_colors.dart';
import 'package:app_lern_deutsch_mobile/core/services/tts_service.dart';
import 'package:app_lern_deutsch_mobile/core/services/pronunciation_service.dart';
import 'package:app_lern_deutsch_mobile/features/settings/presentation/settings_controller.dart';
import 'package:app_lern_deutsch_mobile/features/raetsel/domain/models/raetsel_level.dart';
import 'package:app_lern_deutsch_mobile/features/raetsel/domain/raetsel_constants.dart';
import 'package:app_lern_deutsch_mobile/features/raetsel/domain/raetsel_manager.dart';
import 'package:app_lern_deutsch_mobile/core/services/subscription_service.dart';
import 'widgets/raetsel_banner_ad_widget.dart';
import 'widgets/raetsel_captured_sheet.dart';
import 'widgets/raetsel_clue_item.dart';
import 'widgets/raetsel_hints_sheet.dart';
import 'widgets/raetsel_interstitial_ad_dialog.dart';
import 'widgets/raetsel_keyboard.dart';
import 'widgets/raetsel_secret_card.dart';
import 'widgets/raetsel_victory_screen.dart';

/// Écran principal du jeu Hoppla Rätsel (mots croisés / Crostic).
/// Gère la sélection, la saisie au clavier virtuel/physique, la synchronisation
/// des lettres partagées par numéro, l'auto-avancement et le verrouillage en vert.
class RaetselGameScreen extends ConsumerStatefulWidget {
  final RaetselLevel level;
  final VoidCallback? onLevelCompleted;
  final String? initialSupportLanguage;
  final Map<int, String>? initialEnteredLetters;

  const RaetselGameScreen({
    super.key,
    required this.level,
    this.onLevelCompleted,
    this.initialSupportLanguage,
    this.initialEnteredLetters,
  });

  @override
  ConsumerState<RaetselGameScreen> createState() => _RaetselGameScreenState();
}

class _RaetselGameScreenState extends ConsumerState<RaetselGameScreen> {
  // Lettres saisies indexées par numéro de lettre (100% synchronisées entre phrase secrète et indices)
  final Map<int, String> _enteredLetters = {};

  // Mots validés et verrouillés
  final Set<String> _lockedWords = {};

  // Phrases captées avec audio et notes pédagogiques
  final List<CapturedPhraseItem> _capturedPhrases = [];

  // Mots ayant subi une erreur ou ayant utilisé un indice
  final Set<String> _wordsWithMistakes = {};
  final Set<String> _wordsWithHints = {};
  final Set<String> _goldWordsRewarded = {};

  // État de sélection courante
  int? _selectedClueIndex;
  int? _selectedCharIndex;
  int? _selectedLetterNumber;

  bool _isSecretSolved = false;
  bool _isLevelComplete = false;
  int _mistakeCount = 0;
  int _hintsUsed = 0;

  int get mistakeCount => _mistakeCount;
  int get hintsUsed => _hintsUsed;

  final ScrollController _scrollController = ScrollController();
  final FocusNode _keyboardFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.initialEnteredLetters != null) {
      _enteredLetters.addAll(widget.initialEnteredLetters!);
    }
    // Sélectionner automatiquement la 1ère case du 1er indice par défaut
    if (widget.level.clues.isNotEmpty && widget.level.clues.first.letterNumbers.isNotEmpty) {
      _selectedClueIndex = 0;
      _selectedCharIndex = 0;
      _selectedLetterNumber = widget.level.clues.first.letterNumbers.first;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  /// Gestion de la frappe d'une lettre (virtuelle ou physique)
  void _onLetterInput(String letter) {
    if (_isLevelComplete || _selectedLetterNumber == null) return;

    final char = letter.toUpperCase();
    final letterNum = _selectedLetterNumber!;

    // Si cette lettre fait partie d'un mot déjà verrouillé, on n'écrase pas
    final isAlreadyLocked = _isNumberInLockedWord(letterNum);
    if (isAlreadyLocked) {
      _autoAdvance();
      return;
    }

    setState(() {
      _enteredLetters[letterNum] = char;
      // Vérifier si la lettre saisie est fausse pour le mot sélectionné
      _checkMistakeOnInput(letterNum, char);
      _checkWordValidation();
      _autoAdvance();
    });
  }

  /// Détecte si la lettre saisie est erronée
  void _checkMistakeOnInput(int letterNum, String char) {
    if (_selectedClueIndex != null) {
      final clue = widget.level.clues[_selectedClueIndex!];
      final charIndex = clue.letterNumbers.indexOf(letterNum);
      if (charIndex >= 0 && charIndex < clue.word.length) {
        final expectedChar = clue.word[charIndex].toUpperCase();
        if (char != expectedChar) {
          _mistakeCount++;
          _wordsWithMistakes.add(clue.word);
          RaetselManager.instance.onWordMistake(phraseId: clue.phraseId);
          // Effet sonore d'erreur bienveillant
          PronunciationService.instance.playFailureSound();
        }
      }
    } else if (_selectedLetterNumber != null) {
      // Dans la phrase secrète
      for (final word in widget.level.secretWords) {
        for (final c in word.chars) {
          if (c.letterNumber == letterNum) {
            if (char != c.char.toUpperCase()) {
              _mistakeCount++;
              PronunciationService.instance.playFailureSound();
            }
            return;
          }
        }
      }
    }
  }

  /// Gestion du retour arrière (Backspace)
  void _onBackspace() {
    if (_isLevelComplete || _selectedLetterNumber == null) return;

    final letterNum = _selectedLetterNumber!;
    final isAlreadyLocked = _isNumberInLockedWord(letterNum);

    setState(() {
      if (!isAlreadyLocked && _enteredLetters.containsKey(letterNum)) {
        _enteredLetters.remove(letterNum);
      } else {
        // Reculer le curseur
        _retreatCursor();
      }
    });
  }

  /// Vérifie si un numéro de lettre appartient à un mot déjà verrouillé
  bool _isNumberInLockedWord(int letterNumber) {
    if (_isSecretSolved) {
      for (final word in widget.level.secretWords) {
        if (word.chars.any((c) => c.letterNumber == letterNumber)) return true;
      }
    }
    for (final clue in widget.level.clues) {
      if (_lockedWords.contains(clue.word) && clue.letterNumbers.contains(letterNumber)) {
        return true;
      }
    }
    return false;
  }

  /// Auto-avancement du curseur vers la prochaine case vide
  void _autoAdvance() {
    if (_selectedClueIndex != null && _selectedCharIndex != null) {
      final clue = widget.level.clues[_selectedClueIndex!];
      // 1. Chercher une case vide suivante dans le mot courant (vers l'avant)
      for (int i = _selectedCharIndex! + 1; i < clue.letterNumbers.length; i++) {
        final num = clue.letterNumbers[i];
        if (!_enteredLetters.containsKey(num)) {
          _selectedCharIndex = i;
          _selectedLetterNumber = num;
          return;
        }
      }

      // 2. Si le mot courant n'est pas encore verrouillé, chercher une case vide antérieure
      if (!_lockedWords.contains(clue.word)) {
        for (int i = 0; i < _selectedCharIndex!; i++) {
          final num = clue.letterNumbers[i];
          if (!_enteredLetters.containsKey(num)) {
            _selectedCharIndex = i;
            _selectedLetterNumber = num;
            return;
          }
        }
      }

      // 3. Passer au prochain indice incomplet
      for (int c = 0; c < widget.level.clues.length; c++) {
        final nextClue = widget.level.clues[c];
        if (!_lockedWords.contains(nextClue.word)) {
          for (int i = 0; i < nextClue.letterNumbers.length; i++) {
            final num = nextClue.letterNumbers[i];
            if (!_enteredLetters.containsKey(num)) {
              _selectedClueIndex = c;
              _selectedCharIndex = i;
              _selectedLetterNumber = num;
              _scrollToClue(c);
              return;
            }
          }
        }
      }

      // 4. Si tous les indices sont résolus mais la phrase secrète ne l'est pas encore
      if (!_isSecretSolved) {
        for (final word in widget.level.secretWords) {
          for (final c in word.chars) {
            if (c.isLetter && c.letterNumber != null && !_enteredLetters.containsKey(c.letterNumber!)) {
              _selectedClueIndex = null;
              _selectedCharIndex = null;
              _selectedLetterNumber = c.letterNumber!;
              return;
            }
          }
        }
      }
    } else {
      // Dans la phrase secrète : chercher la prochaine case vide
      for (final word in widget.level.secretWords) {
        for (final c in word.chars) {
          if (c.isLetter && c.letterNumber != null && !_enteredLetters.containsKey(c.letterNumber!)) {
            _selectedClueIndex = null;
            _selectedCharIndex = null;
            _selectedLetterNumber = c.letterNumber!;
            return;
          }
        }
      }

      // Si la phrase secrète est remplie, chercher dans les indices incomplets
      for (int c = 0; c < widget.level.clues.length; c++) {
        final clue = widget.level.clues[c];
        if (!_lockedWords.contains(clue.word)) {
          for (int i = 0; i < clue.letterNumbers.length; i++) {
            final num = clue.letterNumbers[i];
            if (!_enteredLetters.containsKey(num)) {
              _selectedClueIndex = c;
              _selectedCharIndex = i;
              _selectedLetterNumber = num;
              _scrollToClue(c);
              return;
            }
          }
        }
      }
    }
  }

  /// Recul du curseur en cas de retour arrière
  void _retreatCursor() {
    if (_selectedClueIndex != null && _selectedCharIndex != null) {
      if (_selectedCharIndex! > 0) {
        _selectedCharIndex = _selectedCharIndex! - 1;
        _selectedLetterNumber = widget.level.clues[_selectedClueIndex!].letterNumbers[_selectedCharIndex!];
        if (!_isNumberInLockedWord(_selectedLetterNumber!)) {
          _enteredLetters.remove(_selectedLetterNumber!);
        }
      }
    }
  }

  /// Vérifie si des mots ou la phrase secrète sont validés
  void _checkWordValidation() {
    // 1. Vérifier chaque mot d'indice
    for (final clue in widget.level.clues) {
      if (!_lockedWords.contains(clue.word)) {
        final isFilled = clue.letterNumbers.every((lNum) => _enteredLetters.containsKey(lNum));
        if (isFilled) {
          final candidate = clue.letterNumbers.map((lNum) => _enteredLetters[lNum] ?? '').join();
          if (candidate.toUpperCase() == clue.word.toUpperCase()) {
            _lockedWords.add(clue.word);

            // Effet sonore de bonne réponse
            PronunciationService.instance.playSuccessSound();

            // Intégration répétition espacée (SRS Leitner +1 si sans indice et sans erreur)
            final hadMistake = _wordsWithMistakes.contains(clue.word);
            final usedHint = _wordsWithHints.contains(clue.word);
            RaetselManager.instance.onWordFoundSuccess(
              phraseId: clue.phraseId,
              usedHint: usedHint,
              hadMistake: hadMistake,
            );

            // Intégration série si au moins 3 mots trouvés
            if (_lockedWords.length >= RaetselConstants.wordsCountForStreakActivity) {
              RaetselManager.instance.markDailyStreakActivity();
            }

            // Sauvegarder l'état en cours
            RaetselManager.instance.saveInProgressLevel(
              level: widget.level,
              enteredLetters: _enteredLetters,
            );

            // Ajouter à la liste des phrases captées
            if (!_capturedPhrases.any((item) => item.wordFound == clue.word)) {
              _capturedPhrases.add(CapturedPhraseItem(
                phraseId: clue.phraseId,
                wordFound: clue.word,
                fullPhraseDe: clue.fullPhraseDe,
                fullPhraseFr: clue.fullPhraseFr,
                fullPhraseAr: clue.fullPhraseAr,
                note: clue.note,
              ));
            }

            // Jouer l'audio de la phrase trouvée
            TtsService.instance.speak(clue.fullPhraseDe, phraseId: clue.phraseId);

            // Bonus pour le Mot d'Or (Gold-Wort) ✨
            if (clue.isGoldWord && !_goldWordsRewarded.contains(clue.word)) {
              _goldWordsRewarded.add(clue.word);
              _onGoldWordFound(clue);
            }
          }
        }
      }
    }

    // 2. Vérifier la phrase secrète
    if (!_isSecretSolved) {
      bool secretMatch = true;
      for (final word in widget.level.secretWords) {
        for (final c in word.chars) {
          if (c.isLetter && c.letterNumber != null) {
            final entered = _enteredLetters[c.letterNumber!];
            if (entered == null || entered.toUpperCase() != c.char.toUpperCase()) {
              secretMatch = false;
              break;
            }
          }
        }
        if (!secretMatch) break;
      }

      if (secretMatch) {
        _isSecretSolved = true;

        // Effet sonore de validation pour la phrase secrète
        PronunciationService.instance.playSuccessSound();

        // Ajouter la phrase secrète en tête des phrases captées
        if (!_capturedPhrases.any((item) => item.isSecret)) {
          _capturedPhrases.insert(0, CapturedPhraseItem(
            phraseId: widget.level.secretPhraseId,
            wordFound: widget.level.secretPhraseDe,
            fullPhraseDe: widget.level.secretPhraseDe,
            fullPhraseFr: widget.level.secretPhraseFr,
            fullPhraseAr: widget.level.secretPhraseAr,
            note: widget.level.secretPhraseNote,
            isSecret: true,
          ));
        }

        // Jouer la prononciation de la phrase secrète
        TtsService.instance.speak(widget.level.secretPhraseDe, phraseId: widget.level.secretPhraseId);
      }
    }

    // 3. Vérifier si le niveau entier est achevé
    if (_isSecretSolved && _lockedWords.length == widget.level.clues.length) {
      _isLevelComplete = true;
      // Note: Ne pas appeler widget.onLevelCompleted ici pour éviter le déphasage
      // (l'avancement au niveau suivant se fait lors du clic sur 'Niveau suivant' dans le modal de victoire)
      _onLevelFullyCompleted();
    }
  }

  Future<void> _onLevelFullyCompleted() async {
    // Effet sonore de niveau terminé avec succès !
    PronunciationService.instance.playSuccessSound();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.emoji_events_rounded, color: Colors.amber),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Niveau ${widget.level.levelNumber} terminé avec succès ! 🎉',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF059669),
          duration: const Duration(seconds: 3),
        ),
      );
    }

    // Appliquer les récompenses d'XP, diamants, plafond quotidien et série
    final rewardResult = await RaetselManager.instance.applyLevelCompletionRewards(
      wordsCount: widget.level.clues.length,
      hintsUsed: _hintsUsed,
      mistakes: _mistakeCount,
    );

    // Déclencher le dialogue de victoire
    _triggerVictoryModal(isCapped: rewardResult.isCapped);
  }

  void _triggerVictoryModal({bool isCapped = false}) {
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      final isDark = Theme.of(context).brightness == Brightness.dark;
      String supportLanguage = widget.initialSupportLanguage ?? 'fr';
      if (widget.initialSupportLanguage == null) {
        try {
          final settings = ref.read(settingsControllerProvider);
          supportLanguage = settings.primaryLanguage;
        } catch (_) {}
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => RaetselVictoryScreen(
          level: widget.level,
          mistakesCount: _mistakeCount,
          hintsUsedCount: _hintsUsed,
          supportLanguage: supportLanguage,
          isDark: isDark,
          isCapped: isCapped,
          onNextLevel: () async {
            Navigator.of(ctx).pop();
            // Vérifier si une publicité interstitielle doit être affichée (max tous les 3 niveaux, jamais pendant)
            final shouldShowAd = await RaetselManager.instance.shouldShowInterstitialAd();
            if (shouldShowAd && mounted) {
              await RaetselInterstitialAdDialog.show(
                context,
                isDark: isDark,
                onDismissed: () {
                  widget.onLevelCompleted?.call();
                },
              );
            } else {
              widget.onLevelCompleted?.call();
            }
          },
        ),
      );
    });
  }

  /// Déclenché quand le candidat résout le Mot d'Or (Gold-Wort)
  void _onGoldWordFound(RaetselClueWord clue) {
    RaetselManager.instance.awardBonusReward(
      xp: RaetselConstants.xpBonusGoldWord,
      diamonds: RaetselConstants.diamondsBonusGoldWord,
    );

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1E1B13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFFFD700), width: 1.2),
        ),
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Color(0xFFFFD700), size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '✨ DAS GOLD-WORT GEFUNDEN !',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFFFD700),
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    '+${RaetselConstants.xpBonusGoldWord} XP & +${RaetselConstants.diamondsBonusGoldWord} Diamant 💎 bonus accordés !',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTierColor(String label) {
    switch (label) {
      case 'FACILE':
        return const Color(0xFF10B981);
      case 'INTERMÉDIAIRE':
        return const Color(0xFF06B6D4);
      case 'AVANCÉ':
        return const Color(0xFFF59E0B);
      case 'EXPERT':
        return const Color(0xFFA855F7);
      default:
        return AppColors.primary;
    }
  }

  /// Ouvre la feuille modale des indices
  Future<void> _openHintsSheet() async {
    if (_isLevelComplete) return;

    final balance = await RaetselManager.instance.getDiamondsBalance();
    if (!mounted) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String currentWord = '';
    String currentPhrase = '';
    if (_selectedClueIndex != null) {
      final clue = widget.level.clues[_selectedClueIndex!];
      currentWord = clue.word;
      currentPhrase = clue.fullPhraseDe;
    } else {
      currentWord = widget.level.secretPhraseDe;
      currentPhrase = widget.level.secretPhraseDe;
    }

    if (!mounted) return;
    RaetselHintsSheet.show(
      context,
      diamondsBalance: balance,
      currentClueWord: currentWord,
      currentPhraseDe: currentPhrase,
      isDark: isDark,
      onSelectHint: (type) => _handleHintSelection(type),
    );
  }

  /// Exécute l'action d'indice sélectionnée
  Future<void> _handleHintSelection(RaetselHintType type) async {
    switch (type) {
      case RaetselHintType.revealLetter:
        await _applyRevealLetterHint();
        break;
      case RaetselHintType.revealWord:
        await _applyRevealWordHint();
        break;
      case RaetselHintType.listenPhrase:
        _playCurrentClueAudio();
        break;
      case RaetselHintType.watchAdForHint:
        await _applyRewardedAdHint();
        break;
    }
  }

  /// Écouter la phrase source (gratuit)
  void _playCurrentClueAudio() {
    if (_selectedClueIndex != null) {
      final clue = widget.level.clues[_selectedClueIndex!];
      TtsService.instance.speak(clue.fullPhraseDe, phraseId: clue.phraseId);
    } else {
      TtsService.instance.speak(widget.level.secretPhraseDe, phraseId: widget.level.secretPhraseId);
    }
  }

  /// Révéler une lettre contre des diamants
  Future<void> _applyRevealLetterHint() async {
    final success = await RaetselManager.instance.spendDiamonds(RaetselConstants.diamondCostRevealLetter);
    if (!success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pas assez de diamants 💎 !')),
        );
      }
      return;
    }

    _revealSelectedLetter();
  }

  /// Révéler une lettre via vidéo publicitaire récompensée
  Future<void> _applyRewardedAdHint() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    await RaetselInterstitialAdDialog.show(
      context,
      isDark: isDark,
      onDismissed: () {
        _revealSelectedLetter();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('🎉 Indice débloqué grâce à la vidéo !')),
          );
        }
      },
    );
  }

  void _revealSelectedLetter() {
    if (_selectedClueIndex != null && _selectedCharIndex != null && _selectedLetterNumber != null) {
      final clue = widget.level.clues[_selectedClueIndex!];
      final correctChar = clue.word[_selectedCharIndex!].toUpperCase();

      setState(() {
        _hintsUsed++;
        _wordsWithHints.add(clue.word);
        _enteredLetters[_selectedLetterNumber!] = correctChar;
        _checkWordValidation();
        _autoAdvance();
      });
    } else if (_selectedLetterNumber != null) {
      // Dans la phrase secrète
      for (final word in widget.level.secretWords) {
        for (final c in word.chars) {
          if (c.letterNumber == _selectedLetterNumber) {
            setState(() {
              _hintsUsed++;
              _enteredLetters[_selectedLetterNumber!] = c.char.toUpperCase();
              _checkWordValidation();
              _autoAdvance();
            });
            return;
          }
        }
      }
    }
  }

  /// Révéler tout le mot sélectionné contre des diamants
  Future<void> _applyRevealWordHint() async {
    final success = await RaetselManager.instance.spendDiamonds(RaetselConstants.diamondCostRevealWord);
    if (!success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pas assez de diamants 💎 !')),
        );
      }
      return;
    }

    if (_selectedClueIndex != null) {
      final clue = widget.level.clues[_selectedClueIndex!];
      setState(() {
        _hintsUsed++;
        _wordsWithHints.add(clue.word);
        for (int i = 0; i < clue.word.length; i++) {
          final lNum = clue.letterNumbers[i];
          _enteredLetters[lNum] = clue.word[i].toUpperCase();
        }
        _checkWordValidation();
        _autoAdvance();
      });
    }
  }

  void _scrollToClue(int clueIndex) {
    if (_scrollController.hasClients) {
      final targetOffset = 180.0 + (clueIndex * 90.0);
      _scrollController.animateTo(
        targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String supportLanguage = widget.initialSupportLanguage ?? 'fr';
    if (widget.initialSupportLanguage == null) {
      try {
        final settings = ref.watch(settingsControllerProvider);
        supportLanguage = settings.primaryLanguage;
      } catch (_) {}
    }

    return Focus(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          final logicalKey = event.logicalKey;
          if (logicalKey == LogicalKeyboardKey.backspace) {
            _onBackspace();
            return KeyEventResult.handled;
          }
          final label = event.character;
          if (label != null && RegExp(r'^[a-zA-ZäöüßÄÖÜẞ]$').hasMatch(label)) {
            _onLetterInput(label);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Builder(
            builder: (context) {
              final tier = RaetselConstants.getTierForLevel(widget.level.levelNumber);
              final tierColor = _getTierColor(tier.difficultyLabel);
              return FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Niveau ${widget.level.levelNumber}',
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: tierColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: tierColor.withValues(alpha: 0.4), width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            tier.iconEmoji,
                            style: const TextStyle(fontSize: 10),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            tier.difficultyLabel,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                              color: tierColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            // Bouton Indice (💡)
            IconButton(
              icon: const Icon(Icons.lightbulb_rounded, size: 22),
              color: const Color(0xFFF59E0B),
              tooltip: 'Indices',
              onPressed: _openHintsSheet,
            ),
            // Bouton Phrases captées
            IconButton(
              icon: const Icon(Icons.collections_bookmark_rounded, size: 20),
              color: AppColors.primary,
              tooltip: 'Phrases captées',
              onPressed: () {
                RaetselCapturedSheet.show(
                  context,
                  capturedPhrases: _capturedPhrases,
                  totalCount: widget.level.clues.length + 1,
                  supportLanguage: supportLanguage,
                  isDark: isDark,
                );
              },
            ),
            // Indicateur de mots résolus
            Container(
              margin: const EdgeInsets.only(right: 14),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.primary),
                  const SizedBox(width: 5),
                  Text(
                    '${_lockedWords.length}/${widget.level.clues.length}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Zone défilante : Carte phrase secrète en haut + Liste des indices
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.only(bottom: 20),
                children: [
                  // Carte phrase secrète
                  RaetselSecretCard(
                    level: widget.level,
                    enteredLetters: _enteredLetters,
                    selectedLetterNumber: _selectedLetterNumber,
                    isSecretSolved: _isSecretSolved,
                    supportLanguage: supportLanguage,
                    isDark: isDark,
                    onSelectLetter: (lNum) {
                      setState(() {
                        _selectedClueIndex = null;
                        _selectedCharIndex = null;
                        _selectedLetterNumber = lNum;
                      });
                    },
                  ),

                  // Séparateur discret
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Row(
                      children: [
                        Text(
                          'QUESTIONS & DÉFINITIONS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Divider(
                            color: isDark ? const Color(0xFF243247) : const Color(0xFFE2E8F0),
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Liste des indices
                  ...List.generate(widget.level.clues.length, (idx) {
                    final clue = widget.level.clues[idx];
                    final isWordLocked = _lockedWords.contains(clue.word);

                    return RaetselClueItem(
                      index: idx,
                      clue: clue,
                      enteredLetters: _enteredLetters,
                      selectedLetterNumber: _selectedLetterNumber,
                      selectedClueIndex: _selectedClueIndex,
                      selectedCharIndex: _selectedCharIndex,
                      isWordLocked: isWordLocked,
                      supportLanguage: supportLanguage,
                      isDark: isDark,
                      onSelectBox: (clueIdx, charIdx, letterNum) {
                        setState(() {
                          _selectedClueIndex = clueIdx;
                          _selectedCharIndex = charIdx;
                          _selectedLetterNumber = letterNum;
                        });
                      },
                    );
                  }),
                ],
              ),
            ),

            // Bandeau interactif Phrases captées (n/N)
            _buildCapturedBanner(supportLanguage, isDark),

            // Bannière publicitaire (désactivée pour les membres Pro et Admin)
            if (!SubscriptionService.instance.isPremium)
              RaetselBannerAdWidget(isDark: isDark),

            // Clavier virtuel spécial allemand en bas
            RaetselKeyboard(
              isDark: isDark,
              onKeyPressed: _onLetterInput,
              onBackspace: _onBackspace,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapturedBanner(String supportLanguage, bool isDark) {
    final totalPhrases = widget.level.clues.length + 1;
    final count = _capturedPhrases.length;
    final lastPhrase = _capturedPhrases.isNotEmpty ? _capturedPhrases.last.fullPhraseDe : '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            RaetselCapturedSheet.show(
              context,
              capturedPhrases: _capturedPhrases,
              totalCount: totalPhrases,
              supportLanguage: supportLanguage,
              isDark: isDark,
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.collections_bookmark_rounded,
                    size: 15,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Phrases captées ($count/$totalPhrases)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (lastPhrase.isNotEmpty)
                  Expanded(
                    child: Text(
                      lastPhrase,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontStyle: FontStyle.italic,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  )
                else
                  const Spacer(),
                const Icon(
                  Icons.expand_less_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
