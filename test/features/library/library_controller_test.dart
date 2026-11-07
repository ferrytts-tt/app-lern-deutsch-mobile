import 'package:flutter_test/flutter_test.dart';
import 'package:app_lern_deutsch_mobile/domain/models/phrase.dart';
import 'package:app_lern_deutsch_mobile/domain/models/topic.dart';
import 'package:app_lern_deutsch_mobile/domain/models/user_phrase.dart';
import 'package:app_lern_deutsch_mobile/features/library/presentation/library_controller.dart';

void main() {
  group('LibraryState & Filtering Tests', () {
    final mockPhrases = [
      const Phrase(
        id: 'p1',
        topic: 'salutations',
        cefr: 'A1',
        de: 'Guten Tag',
        fr: 'Bonjour',
        note: 'Formel polie',
      ),
      const Phrase(
        id: 'p2',
        topic: 'restaurant',
        cefr: 'A1',
        de: 'Ein Glas Wasser, bitte',
        fr: 'Un verre d’eau, s’il vous plaît',
      ),
      const Phrase(
        id: 'p3',
        topic: 'restaurant',
        cefr: 'A1',
        de: 'Die Rechnung, bitte',
        fr: 'L’addition, s’il vous plaît',
      ),
    ];

    test('Recherche textuelle sur de, fr et note', () {
      final state = LibraryState(
        allPhrases: mockPhrases,
        searchQuery: 'wasser',
      );
      final results = state.filteredPhrases;
      expect(results.length, 1);
      expect(results.first.id, 'p2');

      // Recherche par note
      final stateNote = LibraryState(
        allPhrases: mockPhrases,
        searchQuery: 'polie',
      );
      expect(stateNote.filteredPhrases.length, 1);
      expect(stateNote.filteredPhrases.first.id, 'p1');
    });

    test('Filtres par statut (Nouvelles, En cours, Maîtrisées)', () {
      final now = DateTime.now();
      final progressMap = <String, UserPhrase>{
        'p1': UserPhrase(
          phraseId: 'p1',
          level: 6,
          dueAt: now,
          status: UserPhraseStatus.maitrisee,
        ),
        'p2': UserPhrase(
          phraseId: 'p2',
          level: 2,
          dueAt: now,
          status: UserPhraseStatus.enCours,
        ),
      };

      // p3 est nouvelle (pas dans progressMap)
      final stateNew = LibraryState(
        allPhrases: mockPhrases,
        userProgress: progressMap,
        selectedStatusFilter: 'new',
      );
      expect(stateNew.filteredPhrases.length, 1);
      expect(stateNew.filteredPhrases.first.id, 'p3');

      // p2 est en cours
      final stateProgress = LibraryState(
        allPhrases: mockPhrases,
        userProgress: progressMap,
        selectedStatusFilter: 'in_progress',
      );
      expect(stateProgress.filteredPhrases.length, 1);
      expect(stateProgress.filteredPhrases.first.id, 'p2');

      // p1 est maîtrisée (niveau 6)
      final stateMastered = LibraryState(
        allPhrases: mockPhrases,
        userProgress: progressMap,
        selectedStatusFilter: 'mastered',
      );
      expect(stateMastered.filteredPhrases.length, 1);
      expect(stateMastered.filteredPhrases.first.id, 'p1');
    });

    test('Déblocage doux des thèmes : les 3 premiers toujours débloqués', () {
      const state = LibraryState(
        allPhrases: [],
        unlockedTopicIds: {},
      );
      final stats = state.topicStatsList;
      expect(stats.length, TopicInfo.defaultTopics.length);
      expect(stats[0].isUnlocked, true); // salutations
      expect(stats[1].isUnlocked, true); // se_presenter
      expect(stats[2].isUnlocked, true); // comprendre
      expect(stats[3].isUnlocked, false); // restaurant (verrouillé doucement si non débloqué)
    });

    test('Déblocage manuel explicite sans blocage frustrant', () {
      const state = LibraryState(
        allPhrases: [],
        unlockedTopicIds: {'restaurant'},
      );
      final stats = state.topicStatsList;
      final restaurant = stats.firstWhere((s) => s.topic.id == 'restaurant');
      expect(restaurant.isUnlocked, true);
    });
  });
}
