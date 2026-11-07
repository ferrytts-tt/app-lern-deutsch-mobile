import 'package:flutter/material.dart';

/// Identifiants des récompenses discrètes (Section 7.4 du plan de workflow).
enum BadgeId {
  acquired10,
  acquired50,
  acquired100,
  streak7,
  streak30,
}

/// Modèle pour un palier / badge discret d'apprentissage.
class DiscreetBadge {
  final BadgeId id;
  final String title;
  final String description;
  final IconData icon;
  final int target;
  final int current;
  final bool isUnlocked;

  const DiscreetBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.target,
    required this.current,
    required this.isUnlocked,
  });

  double get progressRatio =>
      target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;

  /// Évalue et génère la liste des 5 badges discrets à partir des métriques réelles.
  static List<DiscreetBadge> evaluateAll({
    required int acquiredPhrasesCount, // Phrases de niveau 7 (Section 4)
    required int streakDays,
  }) {
    return [
      DiscreetBadge(
        id: BadgeId.acquired10,
        title: 'Premiers Pas',
        description: '10 phrases acquises (Niveau 7)',
        icon: Icons.filter_1_rounded,
        target: 10,
        current: acquiredPhrasesCount,
        isUnlocked: acquiredPhrasesCount >= 10,
      ),
      DiscreetBadge(
        id: BadgeId.acquired50,
        title: 'Pratique Régulière',
        description: '50 phrases acquises (Niveau 7)',
        icon: Icons.filter_2_rounded,
        target: 50,
        current: acquiredPhrasesCount,
        isUnlocked: acquiredPhrasesCount >= 50,
      ),
      DiscreetBadge(
        id: BadgeId.acquired100,
        title: 'Maître du Parlé',
        description: '100 phrases acquises (Niveau 7)',
        icon: Icons.filter_3_rounded,
        target: 100,
        current: acquiredPhrasesCount,
        isUnlocked: acquiredPhrasesCount >= 100,
      ),
      DiscreetBadge(
        id: BadgeId.streak7,
        title: 'Flamme d\'une Semaine',
        description: 'Série de 7 jours consécutifs',
        icon: Icons.local_fire_department_rounded,
        target: 7,
        current: streakDays,
        isUnlocked: streakDays >= 7,
      ),
      DiscreetBadge(
        id: BadgeId.streak30,
        title: 'Habitude Ancrée',
        description: 'Série de 30 jours consécutifs',
        icon: Icons.military_tech_rounded,
        target: 30,
        current: streakDays,
        isUnlocked: streakDays >= 30,
      ),
    ];
  }
}
