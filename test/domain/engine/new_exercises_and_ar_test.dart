import 'package:flutter_test/flutter_test.dart';
import 'package:app_lern_deutsch_mobile/domain/engine/session_builder.dart';
import 'package:app_lern_deutsch_mobile/domain/models/phrase.dart';
import 'package:app_lern_deutsch_mobile/core/utils/text_similarity.dart';

void main() {
  group('Trilingual Phrase Model & New Exercises Tests', () {
    test('Phrase model supporte le champ arabe (ar) en JSON et copyWith', () {
      const phrase = Phrase(
        id: 'p_test',
        topic: 'salutations',
        cefr: 'A1',
        de: 'Guten Morgen!',
        fr: 'Bonjour !',
        ar: 'صباح الخير!',
        note: 'Salutation matinale',
      );

      final json = phrase.toJson();
      expect(json['ar'], 'صباح الخير!');
      expect(json['de'], 'Guten Morgen!');
      expect(json['fr'], 'Bonjour !');

      final reconstructed = Phrase.fromJson(json);
      expect(reconstructed.ar, 'صباح الخير!');
      expect(reconstructed.id, 'p_test');

      final updated = phrase.copyWith(ar: 'مرحبا');
      expect(updated.ar, 'مرحبا');
      expect(updated.de, 'Guten Morgen!');
    });

    test('buildFillBlankData génère des trous et réponses pour phrase longue', () {
      const builder = SessionBuilder();
      const sentence = 'Guten Morgen wie geht es Ihnen heute';
      final data = builder.buildFillBlankData(sentence);

      expect(data['display'], isNotNull);
      expect(data['blanks'], isA<List<int>>());
      expect(data['answers'], isA<List<String>>());
      final answers = data['answers'] as List<String>;
      expect(answers.isNotEmpty, true);
      // Le premier mot n'est jamais masqué
      final blanks = data['blanks'] as List<int>;
      expect(blanks.contains(0), false);
    });

    test('TextSimilarity tolère les fautes douces (distance de Levenshtein <= 1)', () {
      // Correspondance exacte
      final exact = TextSimilarity.evaluate('Guten Morgen', 'Guten Morgen');
      expect(exact.isCorrect, true);
      expect(exact.hasMinorTypo, false);

      // Petite faute d'inattention (1 lettre)
      final minorTypo = TextSimilarity.evaluate('Guten Morgn', 'Guten Morgen');
      expect(minorTypo.isCorrect, true);
      expect(minorTypo.hasMinorTypo, true);

      // Réponse totalement erronée
      final wrong = TextSimilarity.evaluate('Bonsoir', 'Guten Morgen');
      expect(wrong.isCorrect, false);
    });

    test('LearningStep enum comporte bien les 7 étapes séquentielles', () {
      expect(LearningStep.values.length, 7);
      expect(LearningStep.values[0], LearningStep.watch);
      expect(LearningStep.values[1], LearningStep.translate);
      expect(LearningStep.values[2], LearningStep.listenNormal);
      expect(LearningStep.values[3], LearningStep.listenSlow);
      expect(LearningStep.values[4], LearningStep.writeIt);
      expect(LearningStep.values[5], LearningStep.examples);
      expect(LearningStep.values[6], LearningStep.validate);
    });
  });
}
