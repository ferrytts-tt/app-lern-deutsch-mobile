import 'package:flutter_test/flutter_test.dart';
import 'package:app_lern_deutsch_mobile/domain/models/phrase.dart';
import 'package:app_lern_deutsch_mobile/domain/models/topic.dart';
import 'package:app_lern_deutsch_mobile/features/progress/presentation/progress_controller.dart';

void main() {
  group('ProgressState Tests', () {
    test('Calcul des ratios globaux et de maîtrise', () {
      const state = ProgressState(
        totalPhrasesCount: 100,
        startedCount: 40,
        masteredCount: 15,
        inProgressCount: 25,
      );

      expect(state.globalProgressRatio, 0.40);
      expect(state.masteryRatio, 0.15);
    });

    test('TopicProgressItem calcul de ratio par thème', () {
      final topic = TopicInfo.getById('salutations');
      final item = TopicProgressItem(
        topic: topic,
        totalCount: 20,
        startedCount: 10,
        masteredCount: 5,
      );

      expect(item.progressRatio, 0.50);
    });

    test('Watchlist et répartition SRS cohérentes', () {
      const mockPhrase = Phrase(
        id: 'p1',
        topic: 'restaurant',
        cefr: 'A1',
        de: 'Wasser bitte',
        fr: 'De l eau svp',
      );

      final state = const ProgressState(
        totalPhrasesCount: 411,
        startedCount: 50,
        inProgressCount: 40,
        masteredCount: 10,
        newUnstartedCount: 361,
        watchlistPhrases: [mockPhrase],
        streakDays: 5,
      );

      expect(state.watchlistPhrases.length, 1);
      expect(state.streakDays, 5);
      expect(state.newUnstartedCount + state.startedCount, 411);
    });
  });
}
