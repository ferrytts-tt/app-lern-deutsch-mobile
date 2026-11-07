/// Statut de maîtrise d'une phrase par l'apprenant selon les 8 boîtes (0 à 7).
enum UserPhraseStatus {
  nouvelle, // Niveau 0 (vient d'être vue)
  fragile, // Niveau 1 (1 jour)
  enCours, // Niveaux 2 et 3 (2 à 4 jours)
  assezSolide, // Niveau 4 (7 jours)
  solide, // Niveau 5 (14 jours)
  tresSolide, // Niveau 6 (30 jours)
  maitrisee, // Niveau 7 (90 jours, acquise)
  aSurveiller, // Phrase difficile (4+ erreurs ou 3 erreurs consécutives)
}

/// Progression de l'utilisateur sur une phrase (Table progression du plan).
class UserPhrase {
  final String userId;
  final String phraseId;
  final int level; // 0 à 7 (Niveau de maîtrise du moteur)
  final DateTime dueAt; // Prochaine date d'échéance de révision (prochaine_revision)
  final int reps; // Nombre de réponses justes (nb_bonnes)
  final int lapses; // Nombre d'erreurs totales (nb_erreurs)
  final DateTime? lastReviewedAt; // Date de dernière révision (derniere_revision)
  final bool isDifficult; // Phrase marquée difficile (difficile : >= 4 erreurs)
  final double ease; // Facteur de répétition
  final UserPhraseStatus status;
  final bool? lastResult; // Dernier résultat (true = succès, false = erreur)
  final int consecutiveErrors;

  // Accesseurs selon la nomenclature du workflow plan (Section 6)
  int get niveau => level;
  DateTime get prochaineRevision => dueAt;
  int get nbBonnes => reps;
  int get nbErreurs => lapses;
  DateTime? get derniereRevision => lastReviewedAt;
  bool get difficile => isDifficult;

  const UserPhrase({
    this.userId = 'default_user',
    required this.phraseId,
    this.level = 0,
    required this.dueAt,
    this.reps = 0,
    this.lapses = 0,
    this.lastReviewedAt,
    this.isDifficult = false,
    this.ease = 2.5,
    this.status = UserPhraseStatus.nouvelle,
    this.lastResult,
    this.consecutiveErrors = 0,
  });

  bool get isDue => DateTime.now().isAfter(dueAt);

  UserPhrase copyWith({
    String? userId,
    String? phraseId,
    int? level,
    DateTime? dueAt,
    int? reps,
    int? lapses,
    DateTime? lastReviewedAt,
    bool? isDifficult,
    double? ease,
    UserPhraseStatus? status,
    bool? lastResult,
    int? consecutiveErrors,
  }) {
    return UserPhrase(
      userId: userId ?? this.userId,
      phraseId: phraseId ?? this.phraseId,
      level: level ?? this.level,
      dueAt: dueAt ?? this.dueAt,
      reps: reps ?? this.reps,
      lapses: lapses ?? this.lapses,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      isDifficult: isDifficult ?? this.isDifficult,
      ease: ease ?? this.ease,
      status: status ?? this.status,
      lastResult: lastResult ?? this.lastResult,
      consecutiveErrors: consecutiveErrors ?? this.consecutiveErrors,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'phrase_id': phraseId,
      'niveau': level,
      'prochaine_revision': dueAt.toIso8601String(),
      'nb_bonnes': reps,
      'nb_erreurs': lapses,
      'derniere_revision': lastReviewedAt?.toIso8601String(),
      'difficile': isDifficult ? 1 : 0,
      // Champs de compatibilité
      'phraseId': phraseId,
      'level': level,
      'dueAt': dueAt.toIso8601String(),
      'ease': ease,
      'reps': reps,
      'lapses': lapses,
      'status': status.name,
      'lastResult': lastResult == null ? null : (lastResult! ? 1 : 0),
      'consecutiveErrors': consecutiveErrors,
    };
  }

  factory UserPhrase.fromMap(Map<String, dynamic> map) {
    final phraseId = (map['phrase_id'] ?? map['phraseId']) as String;
    final level = (map['niveau'] ?? map['level']) as int? ?? 0;
    final dueAtStr = (map['prochaine_revision'] ?? map['dueAt']) as String;
    final dueAt = DateTime.parse(dueAtStr);
    final reps = (map['nb_bonnes'] ?? map['reps']) as int? ?? 0;
    final lapses = (map['nb_erreurs'] ?? map['lapses']) as int? ?? 0;
    final lastReviewedStr = map['derniere_revision'] as String?;
    final lastReviewedAt = lastReviewedStr != null ? DateTime.tryParse(lastReviewedStr) : null;
    final isDifficult = (map['difficile'] as int? ?? 0) == 1 || lapses >= 4;

    return UserPhrase(
      userId: map['user_id'] as String? ?? 'default_user',
      phraseId: phraseId,
      level: level,
      dueAt: dueAt,
      reps: reps,
      lapses: lapses,
      lastReviewedAt: lastReviewedAt,
      isDifficult: isDifficult,
      ease: (map['ease'] as num?)?.toDouble() ?? 2.5,
      status: UserPhraseStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => _levelToStatus(level, lapses),
      ),
      lastResult: map['lastResult'] == null
          ? null
          : (map['lastResult'] as int) == 1,
      consecutiveErrors: map['consecutiveErrors'] as int? ?? 0,
    );
  }

  static UserPhraseStatus _levelToStatus(int level, int lapses) {
    if (lapses >= 4) return UserPhraseStatus.aSurveiller;
    switch (level) {
      case 0:
        return UserPhraseStatus.nouvelle;
      case 1:
        return UserPhraseStatus.fragile;
      case 2:
      case 3:
        return UserPhraseStatus.enCours;
      case 4:
        return UserPhraseStatus.assezSolide;
      case 5:
        return UserPhraseStatus.solide;
      case 6:
        return UserPhraseStatus.tresSolide;
      case 7:
      default:
        return UserPhraseStatus.maitrisee;
    }
  }
}
