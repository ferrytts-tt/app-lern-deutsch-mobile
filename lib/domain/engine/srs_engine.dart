import '../models/user_phrase.dart';

/// Type de réponse de l'utilisateur à un exercice (Section 4).
enum ReviewOutcome {
  success, // Réponse juste du premier coup (+1 niveau)
  hintUsed, // Réponse juste après un indice (audio ou première lettre) : niveau identique
  easy, // Phrase « trop facile » : saut au niveau 4 (7 jours de révision)
  mistake, // Réponse fausse : recul de 2 niveaux (min 1, rappel même jour)
}

/// Moteur de répétition espacée (Section 4 du plan : Système Leitner 8 boîtes 0 à 7).
///
/// Règles fondamentales :
/// 1. Réponse juste du premier coup : le niveau monte de 1.
/// 2. Réponse juste après un indice : le niveau reste identique.
/// 3. Réponse fausse : le niveau redescend de 2 (minimum 1) et revient le jour même (10 min).
/// 4. Phrase « trop facile » : saute au niveau 4 (7 jours), jamais directement à 7.
/// 5. Retard : pas de pénalité supplémentaire, seule la réponse compte.
/// 6. Phrases résistantes : après 4 échecs au total, marquée difficile et révisée 2× plus souvent.
/// 7. Acquise (niveau 7) : 90 jours d'intervalle, arrêt des révisions actives.
class SrsEngine {
  const SrsEngine();

  /// Calcule l'intervalle jusqu'à la prochaine révision selon le niveau de maîtrise (Table Section 4).
  Duration getNextInterval(
    int level, {
    bool isDifficult = false,
    bool isFirstNewStep = false,
  }) {
    final Duration base;
    switch (level) {
      case 0:
        // Niveau 0 (nouvelle phrase) : revient le jour même (10 min à 1 h)
        base = isFirstNewStep
            ? const Duration(minutes: 10)
            : const Duration(hours: 1);
        break;
      case 1:
        base = const Duration(days: 1); // Fragile : 1 jour
        break;
      case 2:
        base = const Duration(days: 2); // En cours : 2 jours
        break;
      case 3:
        base = const Duration(days: 4); // En cours : 4 jours
        break;
      case 4:
        base = const Duration(days: 7); // Assez solide : 7 jours
        break;
      case 5:
        base = const Duration(days: 14); // Solide : 14 jours
        break;
      case 6:
        base = const Duration(days: 30); // Très solide : 30 jours
        break;
      case 7:
      default:
        base = const Duration(days: 90); // Acquise : 90 jours
        break;
    }

    // Règle 6 : Phrases résistantes révisées deux fois plus souvent
    if (isDifficult && level >= 2) {
      return Duration(seconds: base.inSeconds ~/ 2);
    }
    return base;
  }

  /// Met à jour la progression de la phrase après un essai (Règles 1 à 7).
  UserPhrase processAttempt(
    UserPhrase current,
    ReviewOutcome outcome, {
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();

    switch (outcome) {
      case ReviewOutcome.success:
        // Règle 1 : Réponse juste du premier coup : le niveau monte de 1
        final nextLevel = (current.level + 1).clamp(0, 7);
        final nextInterval = getNextInterval(nextLevel, isDifficult: current.isDifficult);

        return current.copyWith(
          level: nextLevel,
          dueAt: currentTime.add(nextInterval),
          reps: current.reps + 1,
          consecutiveErrors: 0,
          lastResult: true,
          lastReviewedAt: currentTime,
          status: levelToStatus(nextLevel, current.lapses, current.isDifficult),
        );

      case ReviewOutcome.hintUsed:
        // Règle 2 : Réponse juste après un indice : le niveau reste identique
        final nextInterval = getNextInterval(current.level, isDifficult: current.isDifficult);

        return current.copyWith(
          dueAt: currentTime.add(nextInterval),
          reps: current.reps + 1,
          consecutiveErrors: 0,
          lastResult: true,
          lastReviewedAt: currentTime,
        );

      case ReviewOutcome.easy:
        // Règle 4 : Phrase « trop facile » : saute au niveau 4, jamais directement à 7
        return markAsTooEasy(current, now: currentTime);

      case ReviewOutcome.mistake:
        // Règle 3 : Réponse fausse : le niveau redescend de 2 (minimum 1, ou 0 si niveau 0)
        final nextLevel = current.level == 0 ? 0 : (current.level - 2).clamp(1, 7);
        final newLapses = current.lapses + 1;
        final newConsecutiveErrors = current.consecutiveErrors + 1;
        // Règle 6 : Phrases résistantes : après 4 échecs au total, marquée difficile
        final isDifficult = current.isDifficult || newLapses >= 4;

        // La phrase revient dans la même session (rappel le jour même à +10 min)
        final retryInterval = const Duration(minutes: 10);

        return current.copyWith(
          level: nextLevel,
          dueAt: currentTime.add(retryInterval),
          lapses: newLapses,
          consecutiveErrors: newConsecutiveErrors,
          isDifficult: isDifficult,
          lastResult: false,
          lastReviewedAt: currentTime,
          status: isDifficult || newConsecutiveErrors >= 3
              ? UserPhraseStatus.aSurveiller
              : levelToStatus(nextLevel, newLapses, isDifficult),
        );
    }
  }

  /// Règle 4 de Leitner : Phrase « trop facile » marquée connue.
  /// Elle saute directement au niveau 4 (Assez solide, révision dans 7 jours), jamais directement à 7.
  UserPhrase markAsTooEasy(UserPhrase current, {DateTime? now}) {
    final currentTime = now ?? DateTime.now();
    return current.copyWith(
      level: 4,
      dueAt: currentTime.add(const Duration(days: 7)),
      reps: current.reps + 1,
      consecutiveErrors: 0,
      lastResult: true,
      lastReviewedAt: currentTime,
      status: UserPhraseStatus.assezSolide,
    );
  }

  /// Détermine le statut d'une phrase selon son niveau et ses erreurs.
  static UserPhraseStatus levelToStatus(int level, int lapses, bool isDifficult) {
    if (isDifficult || lapses >= 4) return UserPhraseStatus.aSurveiller;
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

  /// Détermine si le mode rattrapage doit être activé (si file de retard > 40 ou 60).
  bool isCatchupModeActive(int overdueCount, [int threshold = 40]) {
    return overdueCount > threshold;
  }
}
