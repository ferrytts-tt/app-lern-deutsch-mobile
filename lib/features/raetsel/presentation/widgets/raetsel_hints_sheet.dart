import 'package:flutter/material.dart';
import 'package:app_lern_deutsch_mobile/core/theme/app_colors.dart';
import '../../domain/raetsel_constants.dart';

enum RaetselHintType {
  revealLetter,
  revealWord,
  listenPhrase,
  watchAdForHint,
}

/// Feuille modale des indices dans le jeu Hoppla Rätsel :
/// - Révéler une lettre (2 diamants)
/// - Révéler un mot entier (6 diamants)
/// - Écouter la phrase source (gratuit)
/// - Regarder une vidéo publicitaire pour obtenir un indice gratuit
class RaetselHintsSheet extends StatelessWidget {
  final int diamondsBalance;
  final String currentClueWord;
  final String currentPhraseDe;
  final ValueChanged<RaetselHintType> onSelectHint;
  final bool isDark;

  const RaetselHintsSheet({
    super.key,
    required this.diamondsBalance,
    required this.currentClueWord,
    required this.currentPhraseDe,
    required this.onSelectHint,
    this.isDark = true,
  });

  static Future<void> show(
    BuildContext context, {
    required int diamondsBalance,
    required String currentClueWord,
    required String currentPhraseDe,
    required ValueChanged<RaetselHintType> onSelectHint,
    bool isDark = true,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RaetselHintsSheet(
        diamondsBalance: diamondsBalance,
        currentClueWord: currentClueWord,
        currentPhraseDe: currentPhraseDe,
        onSelectHint: (type) {
          Navigator.of(ctx).pop();
          onSelectHint(type);
        },
        isDark: isDark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final itemBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final canAffordLetter = diamondsBalance >= RaetselConstants.diamondCostRevealLetter;
    final canAffordWord = diamondsBalance >= RaetselConstants.diamondCostRevealWord;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: borderColor, width: 1.5)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // En-tête : Titre et solde de diamants
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Indices disponibles 💡',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.diamond_rounded, size: 16, color: AppColors.secondary),
                    const SizedBox(width: 4),
                    Text(
                      '$diamondsBalance',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Option 1 : Révéler une lettre
          _buildHintOption(
            icon: Icons.lightbulb_outline_rounded,
            title: 'Révéler une lettre',
            subtitle: 'Révèle la lettre sélectionnée dans le mot',
            costText: '-${RaetselConstants.diamondCostRevealLetter} 💎',
            isEnabled: canAffordLetter,
            bgColor: itemBg,
            borderColor: borderColor,
            onTap: () => onSelectHint(RaetselHintType.revealLetter),
          ),
          const SizedBox(height: 10),

          // Option 2 : Révéler un mot entier
          _buildHintOption(
            icon: Icons.auto_fix_high_rounded,
            title: 'Révéler tout le mot',
            subtitle: 'Complète et verrouille le mot sélectionné',
            costText: '-${RaetselConstants.diamondCostRevealWord} 💎',
            isEnabled: canAffordWord,
            bgColor: itemBg,
            borderColor: borderColor,
            onTap: () => onSelectHint(RaetselHintType.revealWord),
          ),
          const SizedBox(height: 10),

          // Option 3 : Écouter la phrase source (Gratuit)
          _buildHintOption(
            icon: Icons.volume_up_rounded,
            title: 'Écouter la phrase source',
            subtitle: 'Audio haute clarté Conrad & Katja',
            costText: 'Gratuit',
            isEnabled: true,
            isFree: true,
            bgColor: itemBg,
            borderColor: borderColor,
            onTap: () => onSelectHint(RaetselHintType.listenPhrase),
          ),
          const SizedBox(height: 10),

          // Option 4 : Publicité récompensée (+1 indice gratuit)
          _buildHintOption(
            icon: Icons.play_circle_fill_rounded,
            title: 'Vidéo publicitaire récompensée',
            subtitle: 'Regarde une courte vidéo pour révéler une lettre sans dépenser de diamants',
            costText: 'Pub 🎬',
            isEnabled: true,
            isRewardAd: true,
            bgColor: itemBg,
            borderColor: borderColor,
            onTap: () => onSelectHint(RaetselHintType.watchAdForHint),
          ),
        ],
      ),
    );
  }

  Widget _buildHintOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required String costText,
    required bool isEnabled,
    required Color bgColor,
    required Color borderColor,
    required VoidCallback onTap,
    bool isFree = false,
    bool isRewardAd = false,
  }) {
    Color costColor = AppColors.secondary;
    if (isFree) costColor = AppColors.primary;
    if (isRewardAd) costColor = const Color(0xFFF59E0B);

    return InkWell(
      onTap: isEnabled ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.45,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: costColor.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: costColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: costColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: costColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  costText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: costColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
