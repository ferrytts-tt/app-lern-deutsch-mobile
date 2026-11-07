import 'package:flutter_test/flutter_test.dart';
import 'package:app_lern_deutsch_mobile/core/utils/text_similarity.dart';

void main() {
  group('TextSimilarity Tests', () {
    test('Correspondance exacte (insensible casse et ponctuation)', () {
      final res = TextSimilarity.evaluate(
        'Guten Morgen, wie geht es Ihnen?',
        'guten morgen wie geht es ihnen',
      );
      expect(res.isCorrect, true);
      expect(res.hasMinorTypo, false);
      expect(res.distance, 0);
    });

    test('Faute de frappe mineure tolérée (1 lettre de différence)', () {
      // "Kaffee" tapé "Kafee" (distance 1)
      final res = TextSimilarity.evaluate(
        'der Kafee schmeckt gut',
        'der Kaffee schmeckt gut',
      );
      expect(res.isCorrect, true);
      expect(res.hasMinorTypo, true);
      expect(res.distance, 1);
    });

    test('Erreur trop importante refusée', () {
      final res = TextSimilarity.evaluate(
        'ich will schlafen',
        'der Kaffee schmeckt gut',
      );
      expect(res.isCorrect, false);
      expect(res.distance > 3, true);
    });
  });
}
