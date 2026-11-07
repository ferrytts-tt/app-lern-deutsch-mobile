import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_lern_deutsch_mobile/core/services/tts_service.dart';
import 'package:app_lern_deutsch_mobile/core/theme/app_colors.dart';
import 'package:app_lern_deutsch_mobile/features/raetsel/data/raetsel_definitions.dart';
import 'package:app_lern_deutsch_mobile/features/raetsel/domain/models/raetsel_level.dart';
import 'package:app_lern_deutsch_mobile/features/raetsel/domain/raetsel_manager.dart';

/// Écran modal de fin de niveau Hoppla Rätsel (style Crostic).
/// Affiche la phrase secrète résolue, toutes les phrases captées avec leur « fait intéressant »,
/// les étoiles, les récompenses d'XP et de diamants, et le bouton « Niveau suivant ».
class RaetselVictoryScreen extends StatelessWidget {
  final RaetselLevel level;
  final int mistakesCount;
  final int hintsUsedCount;
  final VoidCallback onNextLevel;
  final VoidCallback? onReplay;
  final String supportLanguage;
  final bool isDark;
  final bool isCapped;

  const RaetselVictoryScreen({
    super.key,
    required this.level,
    required this.mistakesCount,
    required this.hintsUsedCount,
    required this.onNextLevel,
    this.onReplay,
    this.supportLanguage = 'fr',
    this.isDark = true,
    this.isCapped = false,
  });

  /// Calcule le nombre d'étoiles gagnées
  int get stars => RaetselManager.calculateStars(hintsUsed: hintsUsedCount, mistakes: mistakesCount);

  /// Calcule l'XP totale gagnée (0 si plafond dépassé)
  int get totalXp => isCapped
      ? 0
      : RaetselManager.calculateTotalXp(
          wordsCount: level.clues.length,
          hintsUsed: hintsUsedCount,
          stars: stars,
        );

  /// Calcule les diamants gagnés (0 si plafond dépassé)
  int get diamonds => isCapped ? 0 : RaetselManager.calculateDiamonds(stars: stars);

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final isArabic = supportLanguage == 'ar';

    return Dialog.fullscreen(
      backgroundColor: bgColor,
      child: SafeArea(
        child: Column(
          children: [
            // En-tête avec bouton fermer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 24),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Contenu défilable
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  // Animation / Icône de victoire
                  Center(
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, Color(0xFF059669)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.4),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.military_tech_rounded,
                        size: 44,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Titre
                  Center(
                    child: Text(
                      'NIVEAU ${level.levelNumber} RÉUSSI !',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Étoiles animées (1 à 3)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      final isEarned = index < stars;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Icon(
                          Icons.star_rounded,
                          size: 38,
                          color: isEarned ? const Color(0xFFF59E0B) : const Color(0xFF475569),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),

                  // Récompenses : XP et Diamants
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Badge XP
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.accent.withOpacity(0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.bolt_rounded, size: 20, color: AppColors.accent),
                            const SizedBox(width: 6),
                            Text(
                              '+$totalXp XP',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: AppColors.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Badge Diamants
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.secondary.withOpacity(0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.diamond_rounded, size: 18, color: AppColors.secondary),
                            const SizedBox(width: 6),
                            Text(
                              '+$diamonds Diamants',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (isCapped) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.withOpacity(0.3)),
                      ),
                      child: const Text(
                        'Plafond quotidien atteint (10 niveaux max/jour) - Pas de gains XP/💎',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.amber,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Carte Phrase Secrète
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF1B4D33), const Color(0xFF1E293B)]
                            : [const Color(0xFFD1FAE5), Colors.white],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.auto_awesome_rounded, size: 18, color: AppColors.primary),
                            const SizedBox(width: 8),
                            const Text(
                              'PHRASE SECRÈTE RÉSOLUE',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: AppColors.primary,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.volume_up_rounded, size: 22),
                              color: AppColors.primary,
                              onPressed: () {
                                TtsService.instance.speak(
                                  level.secretPhraseDe,
                                  phraseId: level.secretPhraseId,
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          level.secretPhraseDe,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isArabic ? level.secretPhraseAr : level.secretPhraseFr,
                          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontStyle: isArabic ? FontStyle.normal : FontStyle.italic,
                            color: isDark ? Colors.white70 : const Color(0xFF334155),
                          ),
                        ),
                        if (level.secretPhraseNote.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.lightbulb_outline_rounded, size: 16, color: AppColors.accent),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    level.secretPhraseNote,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Carte spéciale : Kultur-Perle 🇩🇪 (Pépite culturelle & linguistique du niveau)
                  Builder(
                    builder: (context) {
                      final perle = RaetselDefinitions.getKulturPerle(level.levelNumber);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark
                                ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                                : [const Color(0xFFF0FDF4), const Color(0xFFDCFCE7)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF10B981).withValues(alpha: 0.5),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    perle['tag'] ?? 'CULTURE ALLEMANDE',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.6,
                                      color: Color(0xFF10B981),
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                const Text('🇩🇪', style: TextStyle(fontSize: 18)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              perle['title'] ?? '',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              perle['text'] ?? '',
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  // Titre de section : Phrases captées et Faits intéressants
                  Text(
                    'PHRASES CAPTÉES & FAITS INTÉRESSANTS (${level.clues.length})',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Liste de toutes les phrases du niveau avec leur note
                  ...level.clues.map((clue) {
                    final translation = isArabic ? clue.fullPhraseAr : clue.fullPhraseFr;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'MOT : ${clue.word}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.volume_up_rounded, size: 20),
                                color: AppColors.secondary,
                                onPressed: () {
                                  TtsService.instance.speak(
                                    clue.fullPhraseDe,
                                    phraseId: clue.phraseId,
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            clue.fullPhraseDe,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            translation,
                            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              fontStyle: isArabic ? FontStyle.normal : FontStyle.italic,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                          if (clue.note.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))
                                    .withOpacity(0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.tips_and_updates_outlined,
                                    size: 15,
                                    color: AppColors.accent,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      clue.note,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white70 : const Color(0xFF334155),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            // Bouton Niveau suivant fixé en bas
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: bgColor,
                border: Border(
                  top: BorderSide(color: borderColor, width: 1),
                ),
              ),
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  Navigator.of(context).pop();
                  onNextLevel();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Niveau suivant',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
