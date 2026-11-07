import 'package:flutter/material.dart';

/// Palette de couleurs officielle de l'application Deutsch Fast.
/// Conçue pour inspirer la sérénité, la bienveillance et la progression sans punition.
class AppColors {
  AppColors._();

  // --- Verts (croissance, action principale, das) ---
  static const Color primary = Color(0xFF10B981);
  static const Color primaryDark = Color(0xFF059669);
  static const Color primaryLight = Color(0xFFD1FAE5);

  // --- Bleus (information, écoute audio, der) ---
  static const Color secondary = Color(0xFF3B82F6);
  static const Color secondaryDark = Color(0xFF1D4ED8);
  static const Color secondaryLight = Color(0xFFDBEAFE);

  // --- Jaunes & Or (récompenses, séries, micro shadowing, die) ---
  static const Color accent = Color(0xFFF59E0B);
  static const Color accentDark = Color(0xFFD97706);
  static const Color accentLight = Color(0xFFFEF3C7);

  // --- Neutres & Surfaces (Thème Clair) ---
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color borderLight = Color(0xFFE2E8F0);

  // --- Thème Sombre (Sleek Slate Moderne) ---
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color borderDark = Color(0xFF334155);

  // --- Erreur Douce (jamais de rouge agressif) ---
  static const Color gentleError = Color(0xFFF59E4B);
  static const Color gentleErrorBackground = Color(0xFFFFF1E2);
  static const Color gentleErrorBackgroundDark = Color(0xFF332014);

  // --- Articles allemands (genres grammaticaux) ---
  static const Color articleDer = Color(0xFF2F80ED); // Masculin : Bleu
  static const Color articleDie = Color(0xFFE0A800); // Féminin : Jaune foncé / Or
  static const Color articleDas = Color(0xFF2FA866); // Neutre : Vert

  // --- Verbes allemands (Action & Grammaire pédagogique) ---
  static const Color verbColor = Color(0xFFFF7043); // Corail / Orange lumineux
  static const Color verbColorDark = Color(0xFFFF8A65); // Mode sombre : Corail chaleureux
  static const Color verbColorLight = Color(0xFFE65100); // Mode clair : Ambre / Terracotta profond

  // --- Typographie & Surfaces Arabes élégantes ---
  static const Color arabicPrimaryLight = Color(0xFF0F766E); // Émeraude / Sarcelle profond
  static const Color arabicPrimaryDark = Color(0xFF5EEAD4); // Menthe lumineuse
  static const Color arabicCardBgLight = Color(0xFFF0FDF4); // Fond doux menthe clair
  static const Color arabicCardBgDark = Color(0xFF0B291B); // Fond doux émeraude profond
  static const Color arabicCardBorderLight = Color(0xFF86EFAC); // Bordure menthe subtile
  static const Color arabicCardBorderDark = Color(0xFF059669); // Bordure émeraude raffinée
}
