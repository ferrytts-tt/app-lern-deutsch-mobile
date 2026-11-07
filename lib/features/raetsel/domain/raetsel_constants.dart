/// Constantes réglables pour le mode Hoppla Rätsel (mots croisés / Crostic).
/// Centralise les valeurs d'XP, d'étoiles, de diamants et les plafonds anti-abus.
class RaetselConstants {
  RaetselConstants._();

  // --- XP ---
  /// XP gagnée par mot trouvé sans indice
  static const int xpPerWordNoHint = 5;

  /// XP gagnée par mot trouvé avec indice
  static const int xpPerWordWithHint = 3;

  /// XP de base accordée à la fin d'un niveau résolu
  static const int xpLevelCompletionBase = 25;

  /// Multiplicateur d'XP pour 1 étoile
  static const double xpMultiplierStar1 = 1.0;

  /// Multiplicateur d'XP pour 2 étoiles
  static const double xpMultiplierStar2 = 1.2;

  /// Multiplicateur d'XP pour 3 étoiles
  static const double xpMultiplierStar3 = 1.5;

  // --- ÉTOILES ---
  /// Critère 3 étoiles : indices utilisés = 0 et erreurs <= 2
  static const int maxMistakesFor3Stars = 2;

  /// Critère 2 étoiles : indices utilisés <= 2 ou erreurs <= 5
  static const int maxHintsFor2Stars = 2;
  static const int maxMistakesFor2Stars = 5;

  // --- DIAMANTS (💎) ---
  /// Diamants par niveau terminé (base)
  static const int diamondsBase = 2;

  /// Diamants par niveau terminé avec 3 étoiles
  static const int diamonds3Stars = 4;

  // --- PLAFOND ANTI-ABUS QUOTIDIEN ---
  /// Nombre maximum de niveaux par jour donnant droit à l'XP et aux diamants.
  /// Au-delà de ce plafond, les niveaux restent jouables mais sans récompense.
  static const int dailyRewardMaxLevels = 10;

  // --- INTÉGRATION SÉRIE ---
  /// Nombre minimum de mots trouvés pour valider l'activité quotidienne de la série
  static const int wordsCountForStreakActivity = 3;

  // --- RÉPÉTITION ESPACÉE & PHRASES RÉSISTANTES ---
  /// Seuil d'échecs cumulés sur un mot pour classer la phrase source en « Phrase résistante »
  static const int mistakesThresholdForResistantPhrase = 3;

  // --- ÉCONOMIE DES INDICES (💎) ---
  /// Coût en diamants pour révéler une lettre
  static const int diamondCostRevealLetter = 2;

  /// Coût en diamants pour révéler un mot entier
  static const int diamondCostRevealWord = 6;

  // --- MOT D'OR (DAS GOLD-WORT ✨) ---
  /// Bonus d'XP pour avoir trouvé le mot d'or d'un niveau sans indice
  static const int xpBonusGoldWord = 10;

  /// Diamant bonus pour avoir trouvé le mot d'or
  static const int diamondsBonusGoldWord = 1;

  // --- PUBLICITÉS (ADS) ---
  /// Intervalle d'apparition des publicités plein écran (interstitiel) : au maximum tous les N niveaux
  /// (uniquement après la fin d'un niveau, JAMAIS pendant un niveau)
  static const int interstitialAdLevelInterval = 3;

  /// Retourne le palier de difficulté et rang de joueur pour un niveau donné
  static RaetselTierInfo getTierForLevel(int levelNumber) {
    if (levelNumber <= 4) {
      return const RaetselTierInfo(
        titleDe: 'Wort-Lehrling',
        titleFr: 'Apprenti des Mots',
        titleAr: 'مبتدئ الكلمات',
        badgeLabel: '🥉 LEHRLING',
        difficultyLabel: 'FACILE',
        minLevel: 1,
        maxLevel: 4,
        wordCount: 8,
        iconEmoji: '🥉',
      );
    } else if (levelNumber <= 9) {
      return const RaetselTierInfo(
        titleDe: 'Rätsel-Sucher',
        titleFr: 'Chercheur d’Énigmes',
        titleAr: 'باحث الألغاز',
        badgeLabel: '🥈 SUCHER',
        difficultyLabel: 'INTERMÉDIAIRE',
        minLevel: 5,
        maxLevel: 9,
        wordCount: 10,
        iconEmoji: '🥈',
      );
    } else if (levelNumber <= 15) {
      return const RaetselTierInfo(
        titleDe: 'Sprach-Detektiv',
        titleFr: 'Détective de la Langue',
        titleAr: 'محقق اللغة',
        badgeLabel: '🥇 DETEKTIV',
        difficultyLabel: 'AVANCÉ',
        minLevel: 10,
        maxLevel: 15,
        wordCount: 11,
        iconEmoji: '🥇',
      );
    } else {
      return const RaetselTierInfo(
        titleDe: 'Hoppla Rätselmeister',
        titleFr: 'Grand Maître des Énigmes',
        titleAr: 'خبير الألغاز الألمانية',
        badgeLabel: '👑 MEISTER',
        difficultyLabel: 'EXPERT',
        minLevel: 16,
        maxLevel: 9999,
        wordCount: 12,
        iconEmoji: '👑',
      );
    }
  }
}

/// Informations sur le rang et palier de difficulté d'un niveau
class RaetselTierInfo {
  final String titleDe;
  final String titleFr;
  final String titleAr;
  final String badgeLabel;
  final String difficultyLabel;
  final int minLevel;
  final int maxLevel;
  final int wordCount;
  final String iconEmoji;

  const RaetselTierInfo({
    required this.titleDe,
    required this.titleFr,
    required this.titleAr,
    required this.badgeLabel,
    required this.difficultyLabel,
    required this.minLevel,
    required this.maxLevel,
    required this.wordCount,
    required this.iconEmoji,
  });
}
