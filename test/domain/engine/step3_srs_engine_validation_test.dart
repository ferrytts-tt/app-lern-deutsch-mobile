import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:app_lern_deutsch_mobile/data/database/app_database.dart';
import 'package:app_lern_deutsch_mobile/data/repositories/phrase_repository.dart';
import 'package:app_lern_deutsch_mobile/domain/engine/srs_engine.dart';
import 'package:app_lern_deutsch_mobile/domain/engine/session_builder.dart';
import 'package:app_lern_deutsch_mobile/domain/models/phrase.dart';
import 'package:app_lern_deutsch_mobile/domain/models/user_phrase.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  const engine = SrsEngine();
  final fixedNow = DateTime(2026, 10, 25, 10, 0, 0);

  group('Étape 3 : Moteur SRS — Algorithme complet Section 4', () {
    test('Critère de validation : Une bonne réponse allonge l\'intervalle selon le tableau de la section 4', () {
      // 0 (Nouvelle) -> 1 (1 jour)
      var phrase = UserPhrase(phraseId: 'p1', level: 0, dueAt: fixedNow);
      phrase = engine.processAttempt(phrase, ReviewOutcome.success, now: fixedNow);
      expect(phrase.level, equals(1));
      expect(phrase.dueAt, equals(fixedNow.add(const Duration(days: 1))));
      expect(phrase.status, equals(UserPhraseStatus.fragile));

      // 1 (Fragile) -> 2 (2 jours)
      phrase = engine.processAttempt(phrase, ReviewOutcome.success, now: fixedNow);
      expect(phrase.level, equals(2));
      expect(phrase.dueAt, equals(fixedNow.add(const Duration(days: 2))));
      expect(phrase.status, equals(UserPhraseStatus.enCours));

      // 2 -> 3 (4 jours)
      phrase = engine.processAttempt(phrase, ReviewOutcome.success, now: fixedNow);
      expect(phrase.level, equals(3));
      expect(phrase.dueAt, equals(fixedNow.add(const Duration(days: 4))));
      expect(phrase.status, equals(UserPhraseStatus.enCours));

      // 3 -> 4 (7 jours, Assez solide)
      phrase = engine.processAttempt(phrase, ReviewOutcome.success, now: fixedNow);
      expect(phrase.level, equals(4));
      expect(phrase.dueAt, equals(fixedNow.add(const Duration(days: 7))));
      expect(phrase.status, equals(UserPhraseStatus.assezSolide));

      // 4 -> 5 (14 jours, Solide)
      phrase = engine.processAttempt(phrase, ReviewOutcome.success, now: fixedNow);
      expect(phrase.level, equals(5));
      expect(phrase.dueAt, equals(fixedNow.add(const Duration(days: 14))));
      expect(phrase.status, equals(UserPhraseStatus.solide));

      // 5 -> 6 (30 jours, Très solide)
      phrase = engine.processAttempt(phrase, ReviewOutcome.success, now: fixedNow);
      expect(phrase.level, equals(6));
      expect(phrase.dueAt, equals(fixedNow.add(const Duration(days: 30))));
      expect(phrase.status, equals(UserPhraseStatus.tresSolide));

      // 6 -> 7 (90 jours, Acquise)
      phrase = engine.processAttempt(phrase, ReviewOutcome.success, now: fixedNow);
      expect(phrase.level, equals(7));
      expect(phrase.dueAt, equals(fixedNow.add(const Duration(days: 90))));
      expect(phrase.status, equals(UserPhraseStatus.maitrisee));
    });

    test('Critère de validation : Une mauvaise réponse réduit le niveau (-2, min 1) et remet la phrase le jour même', () {
      // 1. Phrase de niveau 5 : recule à 3, revient à +10 min
      final p5 = UserPhrase(phraseId: 'p5', level: 5, dueAt: fixedNow);
      final p5AfterFail = engine.processAttempt(p5, ReviewOutcome.mistake, now: fixedNow);

      expect(p5AfterFail.level, equals(3), reason: '5 - 2 = 3');
      expect(p5AfterFail.dueAt, equals(fixedNow.add(const Duration(minutes: 10))), reason: 'Rappel le jour même');
      expect(p5AfterFail.lapses, equals(1));
      expect(p5AfterFail.lastResult, isFalse);

      // 2. Phrase de niveau 2 : recule à 1 (minimum 1 selon Section 4)
      final p2 = UserPhrase(phraseId: 'p2', level: 2, dueAt: fixedNow);
      final p2AfterFail = engine.processAttempt(p2, ReviewOutcome.mistake, now: fixedNow);
      expect(p2AfterFail.level, equals(1), reason: 'Minimum 1');

      // 3. Phrase de niveau 1 : reste au niveau 1 (minimum 1)
      final p1 = UserPhrase(phraseId: 'p1', level: 1, dueAt: fixedNow);
      final p1AfterFail = engine.processAttempt(p1, ReviewOutcome.mistake, now: fixedNow);
      expect(p1AfterFail.level, equals(1), reason: 'Reste au niveau 1');
      expect(p1AfterFail.dueAt, equals(fixedNow.add(const Duration(minutes: 10))));
    });

    test('Règle 4 : « Trop facile » saute directement au niveau 4 (7 jours), jamais à 7', () {
      final initial = UserPhrase(phraseId: 'p_easy', level: 0, dueAt: fixedNow);
      final tooEasy = engine.markAsTooEasy(initial, now: fixedNow);

      expect(tooEasy.level, equals(4));
      expect(tooEasy.status, equals(UserPhraseStatus.assezSolide));
      expect(tooEasy.dueAt, equals(fixedNow.add(const Duration(days: 7))));
    });

    test('Règle 6 : Phrases résistantes (4 échecs) marquées difficile et révisées 2× plus souvent', () {
      var phrase = UserPhrase(phraseId: 'p_hard', level: 3, lapses: 3, dueAt: fixedNow);
      expect(phrase.isDifficult, isFalse);

      // 4ème échec
      phrase = engine.processAttempt(phrase, ReviewOutcome.mistake, now: fixedNow);
      expect(phrase.lapses, equals(4));
      expect(phrase.isDifficult, isTrue);
      expect(phrase.status, equals(UserPhraseStatus.aSurveiller));

      // L'intervalle de niveau 4 normal est 7 jours (168 h) ; pour une phrase difficile c'est divisé par 2 (84 h)
      final normalInterval = engine.getNextInterval(4, isDifficult: false);
      final difficultInterval = engine.getNextInterval(4, isDifficult: true);
      expect(normalInterval, equals(const Duration(days: 7)));
      expect(difficultInterval.inHours, equals(84));
    });

    test('Persistance de la progression dans la table progression de la base SQLite', () async {
      final sqliteDb = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      final appDb = AppDatabase.forTesting(testDb: sqliteDb);
      await appDb.createSchema(sqliteDb);
      final repo = PhraseRepository(database: appDb);

      final p = UserPhrase(
        userId: 'candidate_telc',
        phraseId: 'phrase_001',
        level: 4,
        dueAt: fixedNow.add(const Duration(days: 7)),
        reps: 8,
        lapses: 1,
        lastReviewedAt: fixedNow,
        isDifficult: false,
      );

      await repo.saveProgression(p, userId: 'candidate_telc');

      final progressionMap = await repo.getAllProgression(userId: 'candidate_telc');
      expect(progressionMap.containsKey('phrase_001'), isTrue);

      final retrieved = progressionMap['phrase_001']!;
      expect(retrieved.level, equals(4));
      expect(retrieved.reps, equals(8));
      expect(retrieved.lapses, equals(1));
      expect(retrieved.isDifficult, isFalse);

      await sqliteDb.close();
    });

    test('File de révision : plafond de 60 et ordre (retard d\'abord, fragiles 1-2 ensuite, reste)', () {
      const builder = SessionBuilder();

      // Générer 75 phrases de révision dues :
      // - 10 phrases en grand retard (> 24h, niveau 3)
      // - 20 phrases fragiles (niveau 1 ou 2, dues aujourd'hui)
      // - 45 phrases solides (niveau 4, dues aujourd'hui)
      final allPhrases = <Phrase>[];
      final progressMap = <String, UserPhrase>{};

      // 10 en grand retard (triées par ancienneté)
      for (int i = 0; i < 10; i++) {
        final id = 'late_$i';
        allPhrases.add(Phrase(id: id, topic: 'travail', de: 'L $i', deParle: 'L $i', deStandard: 'L $i', fr: 'F'));
        progressMap[id] = UserPhrase(
          phraseId: id,
          level: 3,
          dueAt: fixedNow.subtract(Duration(days: 10 - i)), // de 10 jours à 1 jour de retard
        );
      }

      // 20 fragiles (niveau 1 et 2)
      for (int i = 0; i < 20; i++) {
        final id = 'fragile_$i';
        allPhrases.add(Phrase(id: id, topic: 'travail', de: 'Fr $i', deParle: 'Fr $i', deStandard: 'Fr $i', fr: 'F'));
        progressMap[id] = UserPhrase(
          phraseId: id,
          level: (i % 2) + 1, // Niveau 1 ou 2
          dueAt: fixedNow.subtract(const Duration(hours: 2)), // Dues il y a 2h
        );
      }

      // 45 solides (niveau 4)
      for (int i = 0; i < 45; i++) {
        final id = 'solid_$i';
        allPhrases.add(Phrase(id: id, topic: 'travail', de: 'S $i', deParle: 'S $i', deStandard: 'S $i', fr: 'F'));
        progressMap[id] = UserPhrase(
          phraseId: id,
          level: 4,
          dueAt: fixedNow.subtract(const Duration(hours: 1)),
        );
      }

      final session = builder.buildSession(
        allPhrases: allPhrases,
        progressMap: progressMap,
        now: fixedNow,
      );

      // Plafond strict de 60 révisions par session
      expect(session.reviewCount, equals(60), reason: 'Plafond strict de 60 révisions par session');

      final reviewItems = session.items.where((it) => it.itemType == SessionItemType.review).toList();
      expect(reviewItems.length, equals(60));

      // 1. Les 10 premières doivent être les phrases en grand retard (> 24h)
      for (int i = 0; i < 10; i++) {
        expect(reviewItems[i].phrase.id.startsWith('late_'), isTrue, reason: 'Les phrases en grand retard passent en premier');
      }

      // 2. Les 20 suivantes doivent être les fragiles (niveaux 1 et 2)
      for (int i = 10; i < 30; i++) {
        expect(reviewItems[i].phrase.id.startsWith('fragile_'), isTrue, reason: 'Les phrases fragiles passent en deuxième');
      }

      // 3. Les 30 dernières révisions (pour atteindre 60) sont les solides
      for (int i = 30; i < 60; i++) {
        expect(reviewItems[i].phrase.id.startsWith('solid_'), isTrue);
      }
    });
  });
}
