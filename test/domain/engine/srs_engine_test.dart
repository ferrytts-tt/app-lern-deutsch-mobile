import 'package:flutter_test/flutter_test.dart';
import 'package:app_lern_deutsch_mobile/domain/engine/srs_engine.dart';
import 'package:app_lern_deutsch_mobile/domain/models/user_phrase.dart';

void main() {
  group('SrsEngine Tests — Système Leitner Section 4', () {
    const engine = SrsEngine();
    final baseTime = DateTime(2026, 10, 10, 10, 0, 0);

    test('Calcul des intervalles de révision selon le niveau (Section 4)', () {
      expect(engine.getNextInterval(0, isFirstNewStep: true), const Duration(minutes: 10));
      expect(engine.getNextInterval(0, isFirstNewStep: false), const Duration(hours: 1));
      expect(engine.getNextInterval(1), const Duration(days: 1));
      expect(engine.getNextInterval(2), const Duration(days: 2));
      expect(engine.getNextInterval(3), const Duration(days: 4));
      expect(engine.getNextInterval(4), const Duration(days: 7));
      expect(engine.getNextInterval(5), const Duration(days: 14));
      expect(engine.getNextInterval(6), const Duration(days: 30));
      expect(engine.getNextInterval(7), const Duration(days: 90));
    });

    test('Succès standard : monte de +1 niveau avec nouveau délai selon Section 4', () {
      final initial = UserPhrase(
        phraseId: 'p1',
        level: 1,
        dueAt: baseTime,
      );

      final updated = engine.processAttempt(initial, ReviewOutcome.success, now: baseTime);

      expect(updated.level, 2);
      expect(updated.dueAt, baseTime.add(const Duration(days: 2)));
      expect(updated.reps, 1);
      expect(updated.lastResult, true);
      expect(updated.status, UserPhraseStatus.enCours);
    });

    test('Réponse Facile / Trop facile : saute au niveau 4 (7 jours)', () {
      final initial = UserPhrase(
        phraseId: 'p1',
        level: 1,
        dueAt: baseTime,
      );

      final updated = engine.processAttempt(initial, ReviewOutcome.easy, now: baseTime);

      expect(updated.level, 4);
      expect(updated.dueAt, baseTime.add(const Duration(days: 7)));
      expect(updated.status, UserPhraseStatus.assezSolide);
      expect(updated.reps, 1);
    });

    test('Erreur : recule de 2 niveaux (min 1) et revient le jour même (Règle 3)', () {
      final initial = UserPhrase(
        phraseId: 'p1',
        level: 3,
        dueAt: baseTime,
      );

      final updated = engine.processAttempt(initial, ReviewOutcome.mistake, now: baseTime);

      expect(updated.level, 1, reason: 'Niveau 3 - 2 = 1');
      expect(updated.dueAt, baseTime.add(const Duration(minutes: 10))); // Revient le jour même
      expect(updated.lapses, 1);
      expect(updated.lastResult, false);
      expect(updated.consecutiveErrors, 1);
      expect(updated.status, UserPhraseStatus.fragile);
    });

    test('Erreur sur niveau 2 recule à 1 (minimum 1, Règle 3)', () {
      final initial = UserPhrase(
        phraseId: 'p1',
        level: 2,
        dueAt: baseTime,
      );

      final updated = engine.processAttempt(initial, ReviewOutcome.mistake, now: baseTime);
      expect(updated.level, 1, reason: 'Le niveau minimum après erreur est 1');
    });

    test('3 erreurs consécutives déclenchent le statut À surveiller', () {
      var phrase = UserPhrase(
        phraseId: 'p1',
        level: 2,
        dueAt: baseTime,
      );

      phrase = engine.processAttempt(phrase, ReviewOutcome.mistake, now: baseTime);
      expect(phrase.consecutiveErrors, 1);
      expect(phrase.status, isNot(UserPhraseStatus.aSurveiller));

      phrase = engine.processAttempt(phrase, ReviewOutcome.mistake, now: baseTime);
      expect(phrase.consecutiveErrors, 2);
      expect(phrase.status, isNot(UserPhraseStatus.aSurveiller));

      phrase = engine.processAttempt(phrase, ReviewOutcome.mistake, now: baseTime);
      expect(phrase.consecutiveErrors, 3);
      expect(phrase.status, UserPhraseStatus.aSurveiller);
    });

    test('Règle 6 : après 4 échecs au total, phrase marquée difficile et révisée 2x plus souvent', () {
      var phrase = UserPhrase(
        phraseId: 'p1',
        level: 3,
        lapses: 3,
        dueAt: baseTime,
      );

      // 4ème échec
      phrase = engine.processAttempt(phrase, ReviewOutcome.mistake, now: baseTime);
      expect(phrase.lapses, 4);
      expect(phrase.isDifficult, isTrue);

      // Test de l'intervalle avec isDifficult = true au niveau 4 (7 jours / 2 = 3.5 jours = 302400 sec)
      final interval = engine.getNextInterval(4, isDifficult: true);
      expect(interval.inHours, 84); // 7 jours = 168h / 2 = 84h
    });

    test('Niveau 7 devient Maîtrisée (Acquise)', () {
      final initial = UserPhrase(
        phraseId: 'p1',
        level: 6,
        dueAt: baseTime,
      );

      final updated = engine.processAttempt(initial, ReviewOutcome.success, now: baseTime);

      expect(updated.level, 7);
      expect(updated.status, UserPhraseStatus.maitrisee);
      expect(updated.dueAt, baseTime.add(const Duration(days: 90)));
    });

    test('Mode rattrapage activé si plus de 40 révisions en retard', () {
      expect(engine.isCatchupModeActive(39), false);
      expect(engine.isCatchupModeActive(40), false);
      expect(engine.isCatchupModeActive(41), true);
    });
  });
}
