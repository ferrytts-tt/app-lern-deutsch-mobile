import 'package:flutter/material.dart';
import 'package:app_lern_deutsch_mobile/core/services/tts_service.dart';
import 'package:app_lern_deutsch_mobile/core/theme/app_colors.dart';

/// Élément représentant une phrase captée au fil de la résolution
class CapturedPhraseItem {
  final String phraseId;
  final String wordFound;
  final String fullPhraseDe;
  final String fullPhraseFr;
  final String fullPhraseAr;
  final String note;
  final bool isSecret;

  const CapturedPhraseItem({
    required this.phraseId,
    required this.wordFound,
    required this.fullPhraseDe,
    required this.fullPhraseFr,
    required this.fullPhraseAr,
    required this.note,
    this.isSecret = false,
  });
}

/// Feuille modale (Bottom Sheet) affichant les phrases captées du niveau.
class RaetselCapturedSheet extends StatelessWidget {
  final List<CapturedPhraseItem> capturedPhrases;
  final int totalCount;
  final String supportLanguage;
  final bool isDark;

  const RaetselCapturedSheet({
    super.key,
    required this.capturedPhrases,
    required this.totalCount,
    this.supportLanguage = 'fr',
    this.isDark = true,
  });

  static Future<void> show(
    BuildContext context, {
    required List<CapturedPhraseItem> capturedPhrases,
    required int totalCount,
    required String supportLanguage,
    required bool isDark,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RaetselCapturedSheet(
        capturedPhrases: capturedPhrases,
        totalCount: totalCount,
        supportLanguage: supportLanguage,
        isDark: isDark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final isArabic = supportLanguage == 'ar';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Barre de drag supérieure
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // En-tête
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.collections_bookmark_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Phrases captées',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${capturedPhrases.length} sur $totalCount débloquées',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Liste des phrases
          Expanded(
            child: capturedPhrases.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.auto_awesome_outlined,
                            size: 40,
                            color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Aucune phrase captée pour le moment.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Résolvez les mots pour écouter et capter leurs phrases !',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: capturedPhrases.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = capturedPhrases[index];
                      final translation = isArabic ? item.fullPhraseAr : item.fullPhraseFr;

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: item.isSecret
                                ? AppColors.accent.withOpacity(0.5)
                                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                            width: item.isSecret ? 1.5 : 1.0,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // En-tête : Badge mot trouvé + bouton audio
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: (item.isSecret ? AppColors.accent : AppColors.primary)
                                        .withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    item.isSecret ? '★ PHRASE SECRÈTE' : 'MOT : ${item.wordFound}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                      color: item.isSecret ? AppColors.accent : AppColors.primary,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.volume_up_rounded, size: 22),
                                  color: AppColors.secondary,
                                  onPressed: () {
                                    TtsService.instance.speak(
                                      item.fullPhraseDe,
                                      phraseId: item.phraseId,
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),

                            // Phrase allemande
                            Text(
                              item.fullPhraseDe,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 4),

                            // Traduction
                            Text(
                              translation,
                              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                fontStyle: isArabic ? FontStyle.normal : FontStyle.italic,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),

                            // Fait intéressant si présent
                            if (item.note.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.primary.withOpacity(0.2),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.lightbulb_outline_rounded,
                                      size: 15,
                                      color: AppColors.accent,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        item.note,
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
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
