import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Styles typographiques stricts de Deutsch Fast basés sur Google Fonts (Poppins & Nunito).
class AppTextStyles {
  AppTextStyles._();

  // --- Titres (Poppins) ---
  static TextStyle titleLarge({bool isDark = false}) => GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        height: 1.25,
      );

  static TextStyle titleMedium({bool isDark = false}) => GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        height: 1.3,
      );

  static TextStyle titleSmall({bool isDark = false}) => GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        height: 1.3,
      );

  // --- Cartes de phrases allemandes (Nunito Bold, 26-30px, très lisible) ---
  static TextStyle germanPhrase({bool isDark = false}) => GoogleFonts.nunito(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        height: 1.35,
      );

  static TextStyle germanPhraseSmall({bool isDark = false}) => GoogleFonts.nunito(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        height: 1.35,
      );

  // --- Traduction française (Nunito Regular 18px) ---
  static TextStyle translation({bool isDark = false}) => GoogleFonts.nunito(
        fontSize: 18,
        fontWeight: FontWeight.normal,
        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        height: 1.4,
      );

  // --- Corps de texte (Nunito Regular 16px) ---
  static TextStyle bodyLarge({bool isDark = false}) => GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        height: 1.5,
      );

  static TextStyle bodyMedium({bool isDark = false}) => GoogleFonts.nunito(
        fontSize: 15,
        fontWeight: FontWeight.normal,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        height: 1.5,
      );

  // --- Notes, métadonnées, légendes (minimum 14px pour accessibilité) ---
  static TextStyle caption({bool isDark = false}) => GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        height: 1.4,
      );

  // --- Boutons ---
  static TextStyle buttonPrimary = GoogleFonts.nunito(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    letterSpacing: 0.3,
  );

  static TextStyle buttonSecondary = GoogleFonts.nunito(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryDark,
  );

  // --- Typographie arabe élégante (GoogleFonts.cairo) harmonieuse avec l'allemand & français ---
  static TextStyle arabicPhrase({
    bool isDark = false,
    double fontSize = 21,
    FontWeight fontWeight = FontWeight.w700,
    Color? color,
  }) =>
      GoogleFonts.cairo(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color ?? (isDark ? AppColors.arabicPrimaryDark : AppColors.arabicPrimaryLight),
        height: 1.55,
        letterSpacing: 0.15,
      );

  static TextStyle arabicBody({
    bool isDark = false,
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w600,
    Color? color,
  }) =>
      GoogleFonts.cairo(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color ?? (isDark ? const Color(0xFF99F6E4) : const Color(0xFF134E4A)),
        height: 1.5,
      );

  static TextStyle arabicCaption({
    bool isDark = false,
    double fontSize = 13,
    FontWeight fontWeight = FontWeight.w600,
    Color? color,
  }) =>
      GoogleFonts.cairo(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color ?? (isDark ? const Color(0xFF5EEAD4).withValues(alpha: 0.8) : const Color(0xFF0F766E).withValues(alpha: 0.8)),
        height: 1.4,
      );
}
