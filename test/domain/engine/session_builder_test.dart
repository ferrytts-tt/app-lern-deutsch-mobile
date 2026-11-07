import 'package:flutter_test/flutter_test.dart';
import 'package:app_lern_deutsch_mobile/domain/engine/session_builder.dart';
import 'package:app_lern_deutsch_mobile/domain/models/phrase.dart';
import 'package:app_lern_deutsch_mobile/domain/models/user_phrase.dart';

void main() {
  group('SessionBuilder Tests', () {
    const builder = SessionBuilder();
    final now = DateTime(2026, 10, 10, 10, 0, 0);

    final mockPhrases = [
      const Phrase(id: 'p1', topic: 'salutations', cefr: 'A1', de: 'Hallo', fr: 'Salut'),
      const Phrase(id: 'p2', topic: 'salutations', cefr: 'A1', de: 'Guten Tag', fr: 'Bonjour'),
      const Phrase(id: 'p3', topic: 'se_presenter', cefr: 'A1', de: 'Ich bin Tom', fr: 'Je suis Tom'),
      const Phrase(id: 'p4', topic: 'comprendre', cefr: 'A1', de: 'Ich verstehe', fr: 'Je comprends'),
      const Phrase(id: 'p5', topic: 'restaurant', cefr: 'A1', de: 'Wasser bitte', fr: 'De l eau svp'),
    ];

    test('Session normale avec nouvelles phrases et révisions dues', () {
      final progressMap = <String, UserPhrase>{
        'p1': UserPhrase(
          phraseId: 'p1',
          level: 2,
          dueAt: now.subtract(const Duration(hours: 2)), // En retard
        ),
        'p2': UserPhrase(
          phraseId: 'p2',
          level: 3,
          dueAt: now.add(const Duration(days: 2)), // Pas en retard
        ),
      };

      final session = builder.buildSession(
        allPhrases: mockPhrases,
        progressMap: progressMap,
        dailyNewTarget: 2,
        now: now,
      );

      // p1 est en révision due
      expect(session.reviewCount, 1);
      // p3 et p4 sont de nouvelles phrases prioritaires (salutations et se_presenter avant restaurant)
      expect(session.newCount, 2);
      expect(session.isCatchupMode, false);
      expect(session.items.isNotEmpty, true);
    });

    test('Mode rattrapage désactive les nouvelles phrases si > 40 révisions en retard', () {
      final manyOverdue = <String, UserPhrase>{};
      final bigList = <Phrase>[];

      for (int i = 0; i < 45; i++) {
        final id = 'overdue_$i';
        bigList.add(Phrase(id: id, topic: 'salutations', cefr: 'A1', de: 'D $i', fr: 'F $i'));
        manyOverdue[id] = UserPhrase(
          phraseId: id,
          level: 1,
          dueAt: now.subtract(Duration(days: i + 1)),
        );
      }

      // Ajouter des phrases non démarrées
      bigList.add(const Phrase(id: 'new_1', topic: 'se_presenter', cefr: 'A1', de: 'Neu', fr: 'Nouveau'));

      final session = builder.buildSession(
        allPhrases: bigList,
        progressMap: manyOverdue,
        dailyNewTarget: 5,
        now: now,
      );

      expect(session.isCatchupMode, true);
      expect(session.newCount, 0); // Aucune nouvelle phrase en mode rattrapage
      expect(session.reviewCount, 45);
    });
  });
}
