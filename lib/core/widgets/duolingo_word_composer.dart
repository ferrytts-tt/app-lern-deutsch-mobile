import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/pronunciation_service.dart';
import '../theme/app_colors.dart';
import '../../domain/models/phrase.dart';
import 'arabic_text_view.dart';
import 'duo_character_speaker.dart';

/// Sens de composition de l'exercice inspiré de Duolingo.
enum ReconstructDirection {
  toGerman, // Ex: Français/Arabe -> Allemand ("Écris ceci en allemand")
  toFrench, // Ex: Allemand -> Français ("Écris ceci en français")
  toArabic, // Ex: Allemand -> Arabe ("اكتب هذا بالعربية")
}

/// Élément individuel de la banque de mots avec suivi d'emplacement vide style Duolingo.
class WordBankItem {
  final int originalIndex;
  final String word;
  bool isUsed;

  WordBankItem({
    required this.originalIndex,
    required this.word,
    this.isUsed = false,
  });
}

/// Widget complet de composition de phrase avec banque de tuiles de mots 3D style Duolingo,
/// supportant la bidirectionnalité (Allemand <-> Français / Arabe), les lignes d'écriture,
/// le personnage parlant et le mode clavier.
class DuolingoWordComposer extends StatefulWidget {
  final Phrase targetPhrase;
  final bool isTtsPlaying;
  final VoidCallback onPlayAudio;
  final VoidCallback? onPlaySlow;
  final Function(bool isCorrect) onValidate;
  final ReconstructDirection? initialDirection;
  final bool showDirectionSwitch;
  final bool embeddedInCard;

  const DuolingoWordComposer({
    super.key,
    required this.targetPhrase,
    required this.isTtsPlaying,
    required this.onPlayAudio,
    this.onPlaySlow,
    required this.onValidate,
    this.initialDirection,
    this.showDirectionSwitch = true,
    this.embeddedInCard = false,
  });

  @override
  State<DuolingoWordComposer> createState() => _DuolingoWordComposerState();
}

class _DuolingoWordComposerState extends State<DuolingoWordComposer> {
  late ReconstructDirection _currentDirection;
  bool _useKeyboard = false;
  late final TextEditingController _keyboardController;

  // Banque de mots et mots sélectionnés
  List<WordBankItem> _bankItems = [];
  final List<WordBankItem> _selectedItems = [];

  bool? _isCorrect;
  String _expectedSentence = '';

  @override
  void initState() {
    super.initState();
    _keyboardController = TextEditingController();
    _currentDirection = widget.initialDirection ?? ReconstructDirection.toGerman;
    _setupExercise();
  }

  @override
  void didUpdateWidget(covariant DuolingoWordComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetPhrase.id != widget.targetPhrase.id) {
      _setupExercise();
    }
  }

  @override
  void dispose() {
    _keyboardController.dispose();
    super.dispose();
  }

  void _switchDirection(ReconstructDirection dir) {
    if (_currentDirection == dir) return;
    setState(() {
      _currentDirection = dir;
      _setupExercise();
    });
  }

  void _setupExercise() {
    _isCorrect = null;
    _selectedItems.clear();
    _keyboardController.clear();

    // 1. Déterminer la phrase cible attendue selon la direction
    switch (_currentDirection) {
      case ReconstructDirection.toGerman:
        _expectedSentence = widget.targetPhrase.deParle.isNotEmpty
            ? widget.targetPhrase.deParle
            : widget.targetPhrase.deStandard;
        break;
      case ReconstructDirection.toFrench:
        _expectedSentence = widget.targetPhrase.fr;
        break;
      case ReconstructDirection.toArabic:
        _expectedSentence = widget.targetPhrase.ar ?? widget.targetPhrase.fr;
        break;
    }

    // 2. Extraire les mots de la phrase cible
    final targetWords = _cleanTokens(_expectedSentence);

    // 3. Générer 2 à 4 distracteurs réalistes
    final distractors = _generateDistractors(_currentDirection, targetWords);

    // 4. Mélanger les mots cibles et les distracteurs
    final allWords = [...targetWords, ...distractors]..shuffle();

    _bankItems = List.generate(
      allWords.length,
      (i) => WordBankItem(originalIndex: i, word: allWords[i]),
    );
  }

  List<String> _cleanTokens(String text) {
    return text
        .trim()
        .split(RegExp(r'\s+'))
        .map((w) => w.replaceAll(RegExp(r'[.,!?;:\"«»؟،]'), '').trim())
        .where((w) => w.isNotEmpty)
        .toList();
  }

  List<String> _generateDistractors(ReconstructDirection dir, List<String> targetWords) {
    final lowerTargets = targetWords.map((w) => w.toLowerCase()).toSet();
    final List<String> pool;

    switch (dir) {
      case ReconstructDirection.toGerman:
        pool = const [
          'nicht', 'sehr', 'auch', 'und', 'aber', 'ist', 'hat', 'ein', 'eine',
          'wir', 'sie', 'hier', 'jetzt', 'immer', 'noch', 'gut', 'bitte', 'dein',
          'mein', 'gerne', 'schon', 'wirklich', 'heute', 'doch', 'mal'
        ];
        break;
      case ReconstructDirection.toFrench:
        pool = const [
          'pas', 'très', 'aussi', 'et', 'mais', 'est', 'a', 'un', 'une', 'du',
          'nous', 'ils', 'ici', 'bien', 'de', 'ne', 'se', 'ce', 'mon', 'ton',
          'propre', 'vrai', 'maintenant', 'toujours', 'encore', 'avec'
        ];
        break;
      case ReconstructDirection.toArabic:
        pool = const [
          'لا', 'جدا', 'أيضا', 'و', 'لكن', 'هو', 'هي', 'نحن', 'هنا', 'الآن',
          'دائما', 'ليس', 'كثيرا', 'مع', 'في', 'من', 'طاهر', 'نظيف', 'نعم'
        ];
        break;
    }

    final filtered = pool.where((w) => !lowerTargets.contains(w.toLowerCase())).toList()
      ..shuffle();

    return filtered.take(3).toList();
  }

  void _selectWord(int bankIndex) {
    final item = _bankItems[bankIndex];
    if (item.isUsed) return;
    setState(() {
      item.isUsed = true;
      _selectedItems.add(item);
      _isCorrect = null;
    });
  }

  void _unselectWord(int selectedIndex) {
    setState(() {
      final item = _selectedItems.removeAt(selectedIndex);
      item.isUsed = false;
      _isCorrect = null;
    });
  }

  String _normalizeString(String str, bool isArabic) {
    if (isArabic) {
      return str
          .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '') // enlève tashkeel
          .replaceAll(RegExp(r'[.,!?;:\"«»؟،\s]'), '')
          .trim();
    }
    return str.replaceAll(RegExp(r'[.,!?;:\"«»\s]'), '').trim().toLowerCase();
  }

  void _verify() {
    final isArabic = _currentDirection == ReconstructDirection.toArabic;
    final String userStr;

    if (_useKeyboard) {
      userStr = _keyboardController.text.trim();
    } else {
      userStr = _selectedItems.map((e) => e.word).join(' ').trim();
    }

    if (userStr.isEmpty) return;

    final normUser = _normalizeString(userStr, isArabic);
    final normExpected = _normalizeString(_expectedSentence, isArabic);

    // Vérification avec tolérance pour le standard vs parlé en allemand
    bool isMatch = normUser == normExpected;
    if (!isMatch && _currentDirection == ReconstructDirection.toGerman) {
      final normStandard = _normalizeString(widget.targetPhrase.deStandard, false);
      if (normUser == normStandard) {
        isMatch = true;
      }
    }

    setState(() {
      _isCorrect = isMatch;
    });

    if (isMatch) {
      PronunciationService.instance.playSuccessSound();
    } else {
      PronunciationService.instance.playFailureSound();
    }

    widget.onValidate(isMatch);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasArabic = widget.targetPhrase.ar != null && widget.targetPhrase.ar!.isNotEmpty;

    // Titre d'instruction style Duolingo
    final String titleText;
    switch (_currentDirection) {
      case ReconstructDirection.toGerman:
        titleText = 'Écris ceci en allemand';
        break;
      case ReconstructDirection.toFrench:
        titleText = 'Écris ceci en français';
        break;
      case ReconstructDirection.toArabic:
        titleText = 'Écris ceci en arabe';
        break;
    }

    final bool isAnswerReady = _useKeyboard
        ? _keyboardController.text.trim().isNotEmpty
        : _selectedItems.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── 1. Sélecteur de direction d'apprentissage ────────────────
        if (widget.showDirectionSwitch) ...[
          _buildDirectionSelector(isDark: isDark, hasArabic: hasArabic),
          const SizedBox(height: 14),
        ],

        // ── 2. Titre de l'exercice (Gras style Duolingo) ──────────────
        Text(
          titleText,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.start,
        ),

        const SizedBox(height: 16),

        // ── 3. Personnage Duolingo & Bulle de dialogue ────────────────
        if (_currentDirection == ReconstructDirection.toGerman) ...[
          // En mode "vers l'allemand", le personnage affiche la phrase source en français (ou arabe)
          DuoCharacterSpeaker(
            germanText: widget.targetPhrase.fr,
            arabicText: widget.targetPhrase.ar,
            isPlaying: false,
            onPlayAudio: () {},
            characterHeight: 110,
            phraseStyle: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
        ] else ...[
          // En mode "vers le français / arabe", le personnage prononce la phrase allemande native avec audio
          DuoCharacterSpeaker(
            germanText: widget.targetPhrase.deParle,
            isPlaying: widget.isTtsPlaying,
            onPlayAudio: widget.onPlayAudio,
            onPlaySlow: widget.onPlaySlow,
            characterHeight: 110,
          ),
        ],

        const SizedBox(height: 20),

        // ── 4. Zone d'écriture : Lignes de cahier + Tuiles ou Clavier ──
        if (_useKeyboard)
          _buildKeyboardInput(isDark: isDark)
        else
          _buildNotebookSlotsArea(isDark: isDark),

        const SizedBox(height: 24),

        // ── 5. Banque de tuiles de mots 3D Duolingo ───────────────────
        if (!_useKeyboard) ...[
          Wrap(
            spacing: 8,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: List.generate(_bankItems.length, (index) {
              final item = _bankItems[index];
              if (item.isUsed) {
                // Emplacement vide grisé [   ] conservant l'espacement exact Duolingo
                return _DuolingoPlaceholderTile(
                  label: item.word,
                  isDark: isDark,
                );
              }
              // Tuile active 3D cliquable
              return _DuolingoWordTile(
                label: item.word,
                isDark: isDark,
                isPlaced: false,
                onTap: () => _selectWord(index),
              );
            }),
          ),
          const SizedBox(height: 20),
        ],

        // ── 6. Bouton bascule Clavier / Tuiles ────────────────────────
        Center(
          child: TextButton.icon(
            onPressed: () {
              setState(() {
                _useKeyboard = !_useKeyboard;
                _isCorrect = null;
              });
            },
            icon: Icon(
              _useKeyboard ? Icons.grid_view_rounded : Icons.keyboard_alt_outlined,
              size: 18,
              color: const Color(0xFF1CB0F6),
            ),
            label: Text(
              _useKeyboard ? 'UTILISER LA BANQUE DE MOTS' : 'UTILISER LE CLAVIER',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: Color(0xFF1CB0F6),
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // ── 7. Message de retour après validation ─────────────────────
        if (_isCorrect != null) _buildFeedbackBanner(isDark: isDark),

        const SizedBox(height: 16),

        // ── 8. Gros bouton 3D Valider Duolingo (#58CC02) ──────────────
        _buildDuolingoVerifyButton(
          isDark: isDark,
          isEnabled: isAnswerReady,
          onPressed: isAnswerReady ? _verify : null,
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Barre de sélection de direction (Allemand <-> Français / Arabe)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildDirectionSelector({required bool isDark, required bool hasArabic}) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildDirectionTab(
              label: '🇩🇪 En allemand',
              isSelected: _currentDirection == ReconstructDirection.toGerman,
              isDark: isDark,
              onTap: () => _switchDirection(ReconstructDirection.toGerman),
            ),
          ),
          Expanded(
            child: _buildDirectionTab(
              label: '🇫🇷 En français',
              isSelected: _currentDirection == ReconstructDirection.toFrench,
              isDark: isDark,
              onTap: () => _switchDirection(ReconstructDirection.toFrench),
            ),
          ),
          if (hasArabic)
            Expanded(
              child: _buildDirectionTab(
                label: '🇸🇦 En arabe',
                isSelected: _currentDirection == ReconstructDirection.toArabic,
                isDark: isDark,
                onTap: () => _switchDirection(ReconstructDirection.toArabic),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDirectionTab({
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final isArabicTab = label.contains('arabe');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isArabicTab
                  ? (isDark ? const Color(0xFF0D281E) : const Color(0xFFDCFCE7))
                  : (isDark ? const Color(0xFF2C3E50) : Colors.white))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected && isArabicTab
              ? Border.all(
                  color: isDark ? const Color(0xFF10B981).withValues(alpha: 0.6) : const Color(0xFF059669).withValues(alpha: 0.5),
                  width: 1.2,
                )
              : null,
          boxShadow: isSelected && !isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? (isArabicTab
                    ? (isDark ? const Color(0xFF5EEAD4) : const Color(0xFF0F766E))
                    : AppColors.primary)
                : (isDark ? Colors.white60 : const Color(0xFF6B7280)),
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Zone des lignes d'écriture de cahier avec tuiles placées
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildNotebookSlotsArea({required bool isDark}) {
    final isRtl = _currentDirection == ReconstructDirection.toArabic;

    return CustomPaint(
      painter: _NotebookLinesPainter(isDark: isDark),
      child: Container(
        constraints: const BoxConstraints(minHeight: 110),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: _selectedItems.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 26.0),
                  child: isRtl
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDark
                                  ? [const Color(0xFF0B261A), const Color(0xFF133B29)]
                                  : [const Color(0xFFF0FDF4), const Color(0xFFDCFCE7)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF10B981).withValues(alpha: 0.4)
                                  : const Color(0xFF059669).withValues(alpha: 0.3),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.15 : 0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            'المس الكلمات أدناه لترتيب الجملة',
                            style: GoogleFonts.cairo(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF065F46),
                            ),
                          ),
                        )
                      : Text(
                          'Touche les mots ci-dessous pour composer la phrase',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                ),
              )
            : Directionality(
                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 14,
                  children: List.generate(_selectedItems.length, (index) {
                    final item = _selectedItems[index];
                    return _DuolingoWordTile(
                      label: item.word,
                      isDark: isDark,
                      isPlaced: true,
                      onTap: () => _unselectWord(index),
                    );
                  }),
                ),
              ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Saisie au clavier alternatif
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildKeyboardInput({required bool isDark}) {
    final isRtl = _currentDirection == ReconstructDirection.toArabic;

    return TextField(
      controller: _keyboardController,
      autofocus: true,
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      onChanged: (_) => setState(() => _isCorrect = null),
      style: isRtl
          ? GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFF5EEAD4) : const Color(0xFF0F766E),
            )
          : TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
      decoration: InputDecoration(
        hintText: isRtl ? 'اكتب الترجمة هنا...' : 'Tape ta réponse ici...',
        hintStyle: isRtl
            ? GoogleFonts.cairo(
                color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
                fontSize: 16,
              )
            : TextStyle(
                color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
                fontSize: 16,
              ),
        filled: true,
        fillColor: isRtl
            ? (isDark ? const Color(0xFF0B2418) : const Color(0xFFF0FDF4))
            : (isDark ? AppColors.surfaceDark : Colors.white),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isRtl
                ? (isDark ? const Color(0xFF10B981).withValues(alpha: 0.5) : const Color(0xFF86EFAC))
                : (isDark ? AppColors.borderDark : const Color(0xFFE5E7EB)),
            width: 2,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isRtl
                ? (isDark ? const Color(0xFF10B981).withValues(alpha: 0.5) : const Color(0xFF86EFAC))
                : (isDark ? AppColors.borderDark : const Color(0xFFE5E7EB)),
            width: 2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isRtl ? const Color(0xFF10B981) : const Color(0xFF1CB0F6),
            width: 2.5,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Bannière de feedback après validation (Succès ou Correction)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildFeedbackBanner({required bool isDark}) {
    final success = _isCorrect == true;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: success
            ? (isDark ? const Color(0xFF142E1F) : const Color(0xFFD7FFB8))
            : (isDark ? const Color(0xFF3B1E1E) : const Color(0xFFFFDFE0)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: success ? const Color(0xFF58CC02) : const Color(0xFFFF4B4B),
          width: 2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            success ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: success ? const Color(0xFF58CC02) : const Color(0xFFFF4B4B),
            size: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  success ? 'Excellent !' : 'Bonne solution :',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: success
                        ? (isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32))
                        : (isDark ? const Color(0xFFEF9A9A) : const Color(0xFFC62828)),
                  ),
                ),
                if (!success) ...[
                  const SizedBox(height: 4),
                  Text(
                    _expectedSentence,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Gros bouton 3D Valider Duolingo (#58CC02)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildDuolingoVerifyButton({
    required bool isDark,
    required bool isEnabled,
    required VoidCallback? onPressed,
  }) {
    final bgColor = isEnabled
        ? const Color(0xFF58CC02)
        : (isDark ? const Color(0xFF2D3748) : const Color(0xFFE5E7EB));
    final shadowColor = isEnabled
        ? const Color(0xFF46A302)
        : (isDark ? const Color(0xFF1A202C) : const Color(0xFFD1D5DB));
    final textColor = isEnabled
        ? Colors.white
        : (isDark ? Colors.white38 : const Color(0xFFA0AEC0));

    return GestureDetector(
      onTap: isEnabled ? onPressed : null,
      child: Container(
        height: 52,
        width: double.infinity,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              offset: const Offset(0, 4),
              blurRadius: 0,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          'VALIDER',
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tuile de mot 3D style Duolingo
// ─────────────────────────────────────────────────────────────────────────────
class _DuolingoWordTile extends StatelessWidget {
  final String label;
  final bool isDark;
  final bool isPlaced;
  final VoidCallback onTap;

  const _DuolingoWordTile({
    required this.label,
    required this.isDark,
    required this.isPlaced,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = isArabicString(label);

    final Color bgColor;
    final Color borderColor;
    final Color shadowColor;
    final TextStyle textStyle;

    if (isArabic) {
      // 🌙 Fond élégant spécifique pour les mots arabes
      bgColor = isDark ? const Color(0xFF0D281E) : const Color(0xFFF0FDF4);
      borderColor = isDark ? const Color(0xFF10B981) : const Color(0xFF059669);
      shadowColor = isDark ? const Color(0xFF061A11) : const Color(0xFF86EFAC);
      textStyle = GoogleFonts.cairo(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: isDark ? const Color(0xFF5EEAD4) : const Color(0xFF065F46),
        height: 1.35,
      );
    } else {
      bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
      borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB);
      shadowColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFD1D5DB);
      textStyle = TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: isDark ? Colors.white : const Color(0xFF1F2937),
        letterSpacing: -0.2,
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isArabic ? 16 : 14,
            vertical: isArabic ? 7 : 9,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isArabic
                  ? borderColor.withValues(alpha: isDark ? 0.75 : 0.65)
                  : borderColor,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                offset: const Offset(0, 3),
                blurRadius: 0,
              ),
            ],
          ),
          child: Text(
            label,
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            style: textStyle,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Emplacement vide grisé [   ] conservant la position dans la banque
// ─────────────────────────────────────────────────────────────────────────────
class _DuolingoPlaceholderTile extends StatelessWidget {
  final String label;
  final bool isDark;

  const _DuolingoPlaceholderTile({
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = isArabicString(label);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isArabic ? 16 : 14,
        vertical: isArabic ? 7 : 9,
      ),
      decoration: BoxDecoration(
        color: isArabic
            ? (isDark ? const Color(0xFF0B1F17) : const Color(0xFFE6F7EC))
            : (isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isArabic
              ? (isDark ? const Color(0xFF134E35) : const Color(0xFFBBEFCE))
              : (isDark ? const Color(0xFF374151) : const Color(0xFFD1D5DB)),
          width: 2,
        ),
      ),
      child: Text(
        label,
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        style: TextStyle(
          fontSize: isArabic ? 18 : 16,
          fontWeight: FontWeight.w800,
          color: Colors.transparent, // Texte invisible pour garder exactement la taille
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Lignes horizontales de cahier style Duolingo
// ─────────────────────────────────────────────────────────────────────────────
class _NotebookLinesPainter extends CustomPainter {
  final bool isDark;

  const _NotebookLinesPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB)
      ..strokeWidth = 2.0;

    // Ligne 1
    final y1 = size.height * 0.46;
    canvas.drawLine(Offset(0, y1), Offset(size.width, y1), linePaint);

    // Ligne 2
    final y2 = size.height * 0.94;
    canvas.drawLine(Offset(0, y2), Offset(size.width, y2), linePaint);
  }

  @override
  bool shouldRepaint(covariant _NotebookLinesPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}
