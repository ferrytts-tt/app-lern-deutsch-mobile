import 'package:flutter/material.dart';
import 'package:app_lern_deutsch_mobile/core/theme/app_colors.dart';

/// Case individuelle d'une lettre dans Hoppla Rätsel (format Crostic).
/// Affiche la lettre en grand et son numéro d'association global en bas.
class RaetselLetterBox extends StatelessWidget {
  final String char; // Lettre saisie ou vide
  final int? letterNumber; // Numéro attribué (ex: 7)
  final bool isSelected; // Est-ce la case active en cours de frappe
  final bool isSharedHighlighted; // Partage le même numéro que la case active
  final bool isLocked; // Mot résolu et verrouillé en vert
  final VoidCallback? onTap;
  final double width;
  final double height;
  final bool isDark;

  const RaetselLetterBox({
    super.key,
    required this.char,
    required this.letterNumber,
    this.isSelected = false,
    this.isSharedHighlighted = false,
    this.isLocked = false,
    this.onTap,
    this.width = 30,
    this.height = 42,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    // Calcul des couleurs selon l'état
    Color bgColor;
    Color borderColor;
    Color textColor;
    Color numberColor;

    if (isLocked) {
      // Verrouillé en vert (mot trouvé !)
      bgColor = AppColors.primary;
      borderColor = AppColors.primaryDark;
      textColor = Colors.white;
      numberColor = Colors.white70;
    } else if (isSelected) {
      // Case active en cours de saisie
      bgColor = AppColors.primary.withOpacity(isDark ? 0.25 : 0.2);
      borderColor = AppColors.primary;
      textColor = isDark ? Colors.white : AppColors.textPrimaryLight;
      numberColor = AppColors.primary;
    } else if (isSharedHighlighted) {
      // Même numéro que la case sélectionnée (surbrillance synchronisée Crostic)
      bgColor = AppColors.accent.withOpacity(isDark ? 0.25 : 0.2);
      borderColor = AppColors.accent;
      textColor = isDark ? Colors.white : AppColors.textPrimaryLight;
      numberColor = AppColors.accentDark;
    } else {
      // État normal
      bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
      borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
      textColor = isDark ? Colors.white : AppColors.textPrimaryLight;
      numberColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: width,
        height: height,
        margin: const EdgeInsets.symmetric(horizontal: 1.5, vertical: 2),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 2.0 : (isSharedHighlighted ? 1.5 : 1.0),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Lettre
            Expanded(
              child: Center(
                child: Text(
                  char.toUpperCase(),
                  style: TextStyle(
                    fontSize: width > 32 ? 16 : 14,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    height: 1.1,
                  ),
                ),
              ),
            ),
            // Numéro de la lettre en bas
            if (letterNumber != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 2.0),
                child: Text(
                  letterNumber.toString(),
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    color: numberColor,
                    height: 1.0,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
