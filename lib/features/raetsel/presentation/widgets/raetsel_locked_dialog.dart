import 'package:flutter/material.dart';
import 'package:app_lern_deutsch_mobile/core/theme/app_colors.dart';

/// Dialogue informatif affiché lorsqu'un utilisateur clique sur l'icône Rätsel verrouillée
/// avant la réussite de l'Examen 1 (20/30).
class RaetselLockedDialog extends StatelessWidget {
  final int learnedCount; // Nombre de phrases apprises dans le Palier 1 (x/30)
  final bool isDark;

  const RaetselLockedDialog({
    super.key,
    required this.learnedCount,
    this.isDark = true,
  });

  static Future<void> show(BuildContext context, {required int learnedCount, required bool isDark}) {
    return showDialog(
      context: context,
      builder: (ctx) => RaetselLockedDialog(
        learnedCount: learnedCount,
        isDark: isDark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final progressRatio = (learnedCount / 30.0).clamp(0.0, 1.0);

    return Dialog(
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(22.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Icône Pièce de puzzle + Cadenas
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.extension_rounded,
                      size: 38,
                      color: AppColors.accent,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
                      size: 18,
                      color: AppColors.accentDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Titre
            const Center(
              child: Text(
                'Hoppla Rätsel Verrouillé',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Message officiel
            Text(
              'Réussis l\'Examen 1 (20/30) pour débloquer Hoppla Rätsel',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : const Color(0xFF334155),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),

            // Carte de progression du Palier 1 (x/30)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Phrases apprises (Palier 1)',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        '$learnedCount / 30',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progressRatio,
                      minHeight: 8,
                      backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Description incitative
            Text(
              'Un jeu de mots croisés à niveaux captivant avec vos phrases réelles et leurs vraies voix natives !',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 20),

            // Bouton d'action
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              child: const Text(
                'Continuer mon apprentissage',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
