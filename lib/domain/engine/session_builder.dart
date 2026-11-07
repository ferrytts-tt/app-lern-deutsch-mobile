import '../models/phrase.dart';
import '../models/user_phrase.dart';
import '../models/topic.dart';
import 'srs_engine.dart';

/// Élément individuel d'une séance d'apprentissage avec son type d'exercice.
enum SessionItemType {
  warmup, // Échauffement (phrase déjà bien connue)
  review, // Révision due
  newPhrase, // Nouvelle phrase découverte
}

/// Type précis de l'exercice interactif selon le niveau de maîtrise de la phrase.
enum ExerciseType {
  newPhrase, // Niveau 0 : découverte et shadowing ×3
  listenAndChoose, // Niveau 1 : écouter et choisir la bonne traduction
  reconstruct, // Niveau 2 : reconstituer la phrase avec des blocs de mots
  speakIt, // Niveau 3 : dis-le à voix haute
  writeIt, // Niveau 4 : écris-le (saisie de la phrase avec tolérance)
  recall, // Niveaux 5-6 : rappel contextualisé en situation réelle
  fillBlank, // Remplir les trous dans la phrase
  completePhrase, // Compléter la phrase (début donné, suite à écrire)
  createExamples, // Créer 2-3 exemples avec le mot-clé
}

/// Les 7 étapes du tunnel d'apprentissage d'une nouvelle phrase.
enum LearningStep {
  watch, // Étape 1: Regarder la phrase
  translate, // Étape 2: Voir les traductions FR + AR
  listenNormal, // Étape 3: Écouter vitesse normale
  listenSlow, // Étape 4: Écouter à 3 vitesses
  writeIt, // Étape 5: Écrire de mémoire
  examples, // Étape 6: Créer 2-3 exemples
  validate, // Étape 7: Valider
}

class SessionItem {
  final Phrase phrase;
  final UserPhrase userPhrase;
  final SessionItemType itemType;
  final ExerciseType exerciseType;
  final List<String> choices; // Pour l'exercice listenAndChoose

  const SessionItem({
    required this.phrase,
    required this.userPhrase,
    required this.itemType,
    required this.exerciseType,
    this.choices = const [],
  });
}

/// Planification complète d'une séance du jour.
class DailySession {
  final List<SessionItem> items;
  final int warmupCount;
  final int reviewCount;
  final int newCount;
  final bool isCatchupMode;
  final bool isExpressMode;

  const DailySession({
    required this.items,
    required this.warmupCount,
    required this.reviewCount,
    required this.newCount,
    this.isCatchupMode = false,
    this.isExpressMode = false,
  });

  int get totalCount => items.length;
  int get estimatedDurationMinutes => isExpressMode ? 2 : (totalCount * 1.5).ceil();
}

/// Générateur intelligent de séance d'apprentissage.
/// Respecte la cible pédagogique de 75 % de connu / 25 % de nouveau.
class SessionBuilder {
  final SrsEngine srsEngine;

  const SessionBuilder({this.srsEngine = const SrsEngine()});

  DailySession buildSession({
    required List<Phrase> allPhrases,
    required Map<String, UserPhrase> progressMap,
    int dailyNewTarget = 8,
    List<String>? priorityThemes,
    bool isExpressMode = false,
    bool includeWarmup = false,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();

    // 1. Identifier les révisions dues triées par retard décroissant
    final overduePhrases = <MapEntry<Phrase, UserPhrase>>[];
    final masteredOrKnownPhrases = <MapEntry<Phrase, UserPhrase>>[];
    final unstartedPhrases = <Phrase>[];

    for (final phrase in allPhrases) {
      final userProg = progressMap[phrase.id];
      if (userProg == null || (userProg.level == 0 && userProg.reps == 0 && userProg.lapses == 0)) {
        unstartedPhrases.add(phrase);
      } else {
        if (userProg.dueAt.isBefore(currentTime)) {
          overduePhrases.add(MapEntry(phrase, userProg));
        } else if (userProg.level >= 2) {
          masteredOrKnownPhrases.add(MapEntry(phrase, userProg));
        }
      }
    }

    // Trier la file de révision selon le plan Section 4 :
    // "L'ordre de présentation est toujours : phrases en retard d'abord, puis les plus fragiles (niveau 1 et 2), puis le reste.
    // Plafond de 60 révisions par session ; le surplus passe au lendemain."
    overduePhrases.sort((a, b) {
      final isLateA = currentTime.difference(a.value.dueAt).inHours >= 24;
      final isLateB = currentTime.difference(b.value.dueAt).inHours >= 24;

      // 1. Phrases en retard (> 24h) d'abord
      if (isLateA != isLateB) {
        return isLateA ? -1 : 1;
      }

      if (isLateA && isLateB) {
        return a.value.dueAt.compareTo(b.value.dueAt);
      }

      // 2. Puis les plus fragiles (niveaux 1 et 2)
      final isFragileA = a.value.level == 1 || a.value.level == 2;
      final isFragileB = b.value.level == 1 || b.value.level == 2;
      if (isFragileA != isFragileB) {
        return isFragileA ? -1 : 1;
      }

      // 3. Puis le reste, par date due croissante
      return a.value.dueAt.compareTo(b.value.dueAt);
    });

    // 2. Détection du mode rattrapage (> 40 révisions en retard)
    final isCatchup = srsEngine.isCatchupModeActive(overduePhrases.length);
    // Mode Express (Section 3) : 0 nouvelles phrases, révisions seules
    final allowedNewPhrases = isExpressMode ? 0 : (isCatchup ? 0 : dailyNewTarget);

    // Plafond strict de 60 révisions par session (Section 3.1 & Étape 3)
    final cappedOverdue = overduePhrases.take(60).toList();

    // 3. Échauffement optionnel (désactivé par défaut selon l'ordre strict de la Section 3 : réviser d'abord, apprendre ensuite)
    final warmupItems = <SessionItem>[];
    if (includeWarmup && !isExpressMode) {
      masteredOrKnownPhrases.shuffle();
      final warmupCandidates = masteredOrKnownPhrases.take(4).toList();
      for (final entry in warmupCandidates) {
        final exType = _resolveExerciseType(entry.value.level, SessionItemType.warmup);
        warmupItems.add(
          SessionItem(
            phrase: entry.key,
            userPhrase: entry.value,
            itemType: SessionItemType.warmup,
            exerciseType: exType,
            choices: exType == ExerciseType.listenAndChoose
                ? _buildChoices(entry.key, allPhrases)
                : const [],
          ),
        );
      }
    }

    // 4. Révisions dues (plafonnées à 60)
    final reviewItems = <SessionItem>[];
    for (final entry in cappedOverdue) {
      final exType = _resolveExerciseType(entry.value.level, SessionItemType.review);
      reviewItems.add(
        SessionItem(
          phrase: entry.key,
          userPhrase: entry.value,
          itemType: SessionItemType.review,
          exerciseType: exType,
          choices: exType == ExerciseType.listenAndChoose
              ? _buildChoices(entry.key, allPhrases)
              : const [],
        ),
      );
    }

    // 5. Nouvelles phrases sélectionnées selon les thèmes prioritaires (Section 2.5 & 3.2)
    final newItems = <SessionItem>[];
    if (allowedNewPhrases > 0 && unstartedPhrases.isNotEmpty) {
      // Prioriser les thèmes choisis par l'utilisateur
      unstartedPhrases.sort((a, b) {
        if (priorityThemes != null && priorityThemes.isNotEmpty) {
          final aInPriority = priorityThemes.any((t) =>
              a.theme.toLowerCase() == t.toLowerCase() ||
              a.topic.toLowerCase() == t.toLowerCase());
          final bInPriority = priorityThemes.any((t) =>
              b.theme.toLowerCase() == t.toLowerCase() ||
              b.topic.toLowerCase() == t.toLowerCase());
          if (aInPriority != bInPriority) {
            return aInPriority ? -1 : 1;
          }
        }
        final orderA = TopicInfo.getById(a.topic).order;
        final orderB = TopicInfo.getById(b.topic).order;
        if (orderA != orderB) {
          return orderA.compareTo(orderB);
        }
        return a.id.compareTo(b.id);
      });

      final pickedNew = unstartedPhrases.take(allowedNewPhrases);
      for (final phrase in pickedNew) {
        final userProg = progressMap[phrase.id] ??
            UserPhrase(
              phraseId: phrase.id,
              level: 0,
              dueAt: currentTime,
              status: UserPhraseStatus.nouvelle,
            );
        newItems.add(
          SessionItem(
            phrase: phrase,
            userPhrase: userProg,
            itemType: SessionItemType.newPhrase,
            exerciseType: ExerciseType.newPhrase,
            choices: _buildChoices(phrase, allPhrases),
          ),
        );
      }
    }

    // Assemblage final : échauffement -> révisions -> nouvelles
    final allItems = [
      ...warmupItems,
      ...reviewItems,
      ...newItems,
    ];

    return DailySession(
      items: allItems,
      warmupCount: warmupItems.length,
      reviewCount: reviewItems.length,
      newCount: newItems.length,
      isCatchupMode: isCatchup,
      isExpressMode: isExpressMode,
    );
  }

  /// Détermine publiquement le type d'exercice selon le niveau de maîtrise
  ExerciseType resolveExerciseType(int level, SessionItemType itemType) => _resolveExerciseType(level, itemType);

  /// Construit publiquement les choix de réponse (QCM) avec distracteurs
  List<String> buildChoices(Phrase target, List<Phrase> allPhrases) => _buildChoices(target, allPhrases);

  ExerciseType _resolveExerciseType(int level, SessionItemType itemType) {
    if (itemType == SessionItemType.newPhrase || level <= 0) {
      return ExerciseType.newPhrase;
    }
    switch (level) {
      case 1:
        return ExerciseType.listenAndChoose;
      case 2:
        return ExerciseType.reconstruct;
      case 3:
        // 50% speakIt, 50% fillBlank
        return (DateTime.now().millisecond % 2 == 0)
            ? ExerciseType.speakIt
            : ExerciseType.fillBlank;
      case 4:
        // 50% writeIt, 50% completePhrase
        return (DateTime.now().millisecond % 2 == 0)
            ? ExerciseType.writeIt
            : ExerciseType.completePhrase;
      case 5:
      case 6:
      default:
        return ExerciseType.recall;
    }
  }

  List<String> _buildChoices(Phrase target, List<Phrase> allPhrases) {
    final distractorPool = allPhrases
        .where((p) => p.id != target.id && p.fr != target.fr)
        .map((p) => p.fr)
        .toSet()
        .toList();
    distractorPool.shuffle();
    final pickedDistractors = distractorPool.take(2).toList();
    final choices = [target.fr, ...pickedDistractors];
    choices.shuffle();
    return choices;
  }

  /// Génère les données pour l'exercice fillBlank : retourne la phrase avec
  /// des blancs et les mots manquants.
  ///
  /// [germanPhrase] – la phrase allemande source.
  /// Returns a map with:
  ///   - `display`  : la phrase avec les mots remplacés par '_____'
  ///   - `blanks`   : les indices (0-based) des mots masqués
  ///   - `answers`  : les mots corrects dans l'ordre des indices
  Map<String, dynamic> buildFillBlankData(String germanPhrase) {
    final words = germanPhrase.split(' ');
    if (words.length <= 2) {
      return {'display': germanPhrase, 'blanks': <int>[], 'answers': <String>[]};
    }

    // Sélectionner 1 ou 2 mots importants à masquer (pas le premier mot)
    final blankCount = words.length > 5 ? 2 : 1;
    final indices = <int>[];

    // Préférer les mots du milieu/fin pour masquer
    for (int i = 0; i < blankCount; i++) {
      int idx;
      do {
        idx = 1 + (DateTime.now().microsecond + i * 7) % (words.length - 1);
      } while (indices.contains(idx));
      indices.add(idx);
    }
    indices.sort();

    final answers = indices.map((i) => words[i]).toList();
    final displayWords = List<String>.from(words);
    for (final i in indices) {
      displayWords[i] = '_____';
    }

    return {
      'display': displayWords.join(' '),
      'blanks': indices,
      'answers': answers,
    };
  }
}
