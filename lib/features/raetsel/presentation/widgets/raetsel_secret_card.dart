import 'package:flutter/material.dart';
import 'package:app_lern_deutsch_mobile/core/theme/app_colors.dart';
import 'package:app_lern_deutsch_mobile/features/raetsel/domain/models/raetsel_level.dart';
import 'raetsel_letter_box.dart';

/// Carte affichant la phrase secrète en haut (style Crostic).
/// Les lettres se remplissent au fur et à mesure de la saisie ou de la résolution des indices.
class RaetselSecretCard extends StatelessWidget {
  final RaetselLevel level;
  final Map<int, String> enteredLetters;
  final int? selectedLetterNumber;
  final bool isSecretSolved;
  final void Function(int letterNumber) onSelectLetter;
  final bool isDark;
  final String supportLanguage;

  const RaetselSecretCard({
    super.key,
    required this.level,
    required this.enteredLetters,
    required this.selectedLetterNumber,
    required this.isSecretSolved,
    required this.onSelectLetter,
    this.isDark = true,
    this.supportLanguage = 'fr',
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSecretSolved ? AppColors.primary : cardBorder,
          width: isSecretSolved ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // En-tête de la carte
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: (isSecretSolved ? AppColors.primary : AppColors.accent).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isSecretSolved ? Icons.check_circle_rounded : Icons.auto_awesome_rounded,
                  size: 16,
                  color: isSecretSolved ? AppColors.primary : AppColors.accent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isSecretSolved ? 'PHRASE MYSTÈRE RÉSOLUE !' : 'PHRASE SECRÈTE À DÉCOUVRIR',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: isSecretSolved ? AppColors.primary : AppColors.accent,
                  ),
                ),
              ),
              if (isSecretSolved) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.lock_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // Grille des mots de la phrase secrète
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8.0, // Espace entre les mots
            runSpacing: 8.0, // Espace entre les lignes de mots
            children: level.secretWords.map((secretWord) {
              return FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                children: secretWord.chars.map((charItem) {
                  if (!charItem.isLetter || charItem.letterNumber == null) {
                    // Ponctuation ou espace
                    if (charItem.char == ' ') {
                      return const SizedBox(width: 6);
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                      child: Text(
                        charItem.char,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    );
                  }

                  final num = charItem.letterNumber!;
                  final entered = enteredLetters[num] ?? '';
                  final isShared = selectedLetterNumber == num;

                  return RaetselLetterBox(
                    char: entered,
                    letterNumber: num,
                    isSelected: isShared,
                    isSharedHighlighted: isShared,
                    isLocked: isSecretSolved,
                    width: 28,
                    height: 40,
                    isDark: isDark,
                    onTap: () => onSelectLetter(num),
                  );
                }).toList(),
              ),
            );
          }).toList(),
          ),

          // Si la phrase est résolue, on affiche sa traduction pour la récompense
          if (isSecretSolved) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                supportLanguage == 'ar' ? level.secretPhraseAr : level.secretPhraseFr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.italic,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
