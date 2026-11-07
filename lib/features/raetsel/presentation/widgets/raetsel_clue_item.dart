import 'package:flutter/material.dart';
import 'package:app_lern_deutsch_mobile/core/theme/app_colors.dart';
import 'package:app_lern_deutsch_mobile/core/services/tts_service.dart';
import 'package:app_lern_deutsch_mobile/features/raetsel/data/raetsel_definitions.dart';
import 'package:app_lern_deutsch_mobile/features/raetsel/domain/models/raetsel_level.dart';
import 'raetsel_letter_box.dart';

/// Un élément de question / indice dans la liste (style Crostic).
/// Affiche la question/définition et les cases de lettres avec leurs numéros respectifs.
class RaetselClueItem extends StatelessWidget {
  final int index;
  final RaetselClueWord clue;
  final Map<int, String> enteredLetters;
  final int? selectedLetterNumber;
  final int? selectedClueIndex;
  final int? selectedCharIndex;
  final bool isWordLocked;
  final void Function(int clueIndex, int charIndex, int letterNumber) onSelectBox;
  final String supportLanguage;
  final bool isDark;

  const RaetselClueItem({
    super.key,
    required this.index,
    required this.clue,
    required this.enteredLetters,
    required this.selectedLetterNumber,
    required this.selectedClueIndex,
    required this.selectedCharIndex,
    required this.isWordLocked,
    required this.onSelectBox,
    this.supportLanguage = 'fr',
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    final isSelectedRow = selectedClueIndex == index;
    final itemBg = isDark
        ? (isSelectedRow ? const Color(0xFF1E293B) : const Color(0xFF151F2E))
        : (isSelectedRow ? const Color(0xFFF8FAFC) : Colors.white);
    final borderColor = isSelectedRow
        ? (isDark ? AppColors.primary.withOpacity(0.5) : AppColors.primary)
        : (isDark ? const Color(0xFF243247) : const Color(0xFFE2E8F0));

    // Question en allemand résolue en priorité absolue depuis le dictionnaire sémantique
    final def = RaetselDefinitions.getDefinition(clue.word);

    final String germanClueText;
    final String effectiveType;

    if (def != null && def['de'] != null && def['de']!.isNotEmpty) {
      germanClueText = def['de']!;
      effectiveType = def['type'] ?? clue.clueType;
    } else if (clue.clueQuestionDe.isNotEmpty && clue.clueQuestionDe != clue.clueQuestionFr) {
      germanClueText = clue.clueQuestionDe;
      effectiveType = clue.clueType;
    } else {
      final generated = RaetselDefinitions.generateDefinitionForWord(
        word: clue.word,
        phraseFr: clue.clueQuestionFr,
        phraseAr: clue.clueQuestionAr,
        phraseDe: clue.fullPhraseDe,
        note: clue.note,
      );
      germanClueText = generated['de'] ?? (clue.clueQuestionDe.isNotEmpty ? clue.clueQuestionDe : clue.fullPhraseDe);
      effectiveType = generated['type'] ?? clue.clueType;
    }

    final supportHintText = supportLanguage == 'ar'
        ? (clue.clueQuestionAr.isNotEmpty ? clue.clueQuestionAr : (def?['ar'] ?? ''))
        : (clue.clueQuestionFr.isNotEmpty ? clue.clueQuestionFr : (def?['fr'] ?? ''));
    final isArabic = supportLanguage == 'ar';

    // Type d'indice avec badge coloré : GEGENTEIL, SYNONYM, REDEWENDUNG, RÄTSEL, DEFINITION, AUDIO
    String? typeBadge;
    Color badgeColor = AppColors.primary;
    if (effectiveType == 'gegenteil') {
      typeBadge = 'GEGENTEIL 🔥';
      badgeColor = Colors.orangeAccent;
    } else if (effectiveType == 'synonym') {
      typeBadge = 'SYNONYM 💎';
      badgeColor = Colors.cyanAccent;
    } else if (effectiveType == 'redewendung') {
      typeBadge = 'REDEWENDUNG ⚡';
      badgeColor = Colors.purpleAccent;
    } else if (effectiveType == 'raetsel') {
      typeBadge = 'RÄTSEL 🕵️‍♂️';
      badgeColor = const Color(0xFFEC4899);
    } else if (effectiveType == 'audio') {
      typeBadge = 'HÖR-RÄTSEL 🎧';
      badgeColor = const Color(0xFF38BDF8);
    } else if (effectiveType == 'definition') {
      typeBadge = 'DEFINITION';
      badgeColor = const Color(0xFF10B981);
    }

    final isGold = clue.isGoldWord;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isGold
            ? (isDark ? const Color(0xFF261D0C) : const Color(0xFFFFFBEB))
            : itemBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isGold
              ? (isWordLocked ? const Color(0xFFFFD700) : const Color(0xFFF59E0B))
              : (isWordLocked ? AppColors.primary.withValues(alpha: 0.6) : borderColor),
          width: isGold ? 1.8 : (isSelectedRow || isWordLocked ? 1.5 : 1.0),
        ),
        boxShadow: isGold
            ? [
                BoxShadow(
                  color: const Color(0xFFFFD700).withValues(alpha: isDark ? 0.2 : 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // En-tête : Badge (1, 2, 3...) + Question / Définition EN ALLEMAND
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge de numéro d'indice
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isGold
                      ? const Color(0xFFF59E0B)
                      : (isWordLocked
                          ? AppColors.primary
                          : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                  shape: BoxShape.circle,
                ),
                child: isWordLocked
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : (isGold
                        ? const Icon(Icons.auto_awesome, size: 13, color: Colors.black87)
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white70 : const Color(0xFF334155),
                            ),
                          )),
              ),
              const SizedBox(width: 10),

              // Question / Définition en ALLEMAND
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge Mot d'Or (Das Gold-Wort)
                    if (isGold) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFF59E0B)],
                          ),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withValues(alpha: 0.35),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome, size: 10, color: Colors.black87),
                            SizedBox(width: 4),
                            Text(
                              '✨ DAS GOLD-WORT (+10 XP & 1 💎)',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    if (typeBadge != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: badgeColor.withValues(alpha: 0.4), width: 0.8),
                        ),
                        child: Text(
                          typeBadge,
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            color: badgeColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                    ],
                    Text(
                      germanClueText,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelectedRow ? FontWeight.w700 : FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        height: 1.3,
                      ),
                    ),
                    if (supportHintText.isNotEmpty && supportHintText != germanClueText) ...[
                      const SizedBox(height: 3),
                      Text(
                        supportHintText,
                        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontStyle: FontStyle.italic,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Si indice audio : bouton d'écoute
              if (clue.clueType == 'audio')
                IconButton(
                  icon: const Icon(Icons.volume_up_rounded, size: 20),
                  color: AppColors.secondary,
                  tooltip: 'Écouter',
                  onPressed: () {
                    TtsService.instance.speak(
                      clue.fullPhraseDe,
                      phraseId: clue.phraseId,
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Ligne des cases de lettres du mot
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(clue.word.length, (charIdx) {
                final letterNum = clue.letterNumbers[charIdx];
                final entered = enteredLetters[letterNum] ?? '';
                final isCurrentSelectedBox =
                    selectedClueIndex == index && selectedCharIndex == charIdx;
                final isShared = selectedLetterNumber == letterNum;

                return RaetselLetterBox(
                  char: entered,
                  letterNumber: letterNum,
                  isSelected: isCurrentSelectedBox,
                  isSharedHighlighted: isShared,
                  isLocked: isWordLocked,
                  width: 32,
                  height: 44,
                  isDark: isDark,
                  onTap: isWordLocked
                      ? null
                      : () => onSelectBox(index, charIdx, letterNum),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
