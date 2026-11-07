import 'package:flutter_test/flutter_test.dart';
import 'package:app_lern_deutsch_mobile/core/services/pronunciation_service.dart';

void main() {
  group('PronunciationService - Évaluation de la prononciation allemande', () {
    final service = PronunciationService.instance;

    test('Prononciation exacte validée avec score élevé', () {
      final result = service.evaluate(
        spoken: 'Ich hab heute echt viel um die Ohren',
        targetParle: 'Ich hab heute echt viel um die Ohren.',
        targetStandard: 'Ich habe heute wirklich viel zu tun.',
      );

      expect(result.isSuccess, isTrue);
      expect(result.score, greaterThanOrEqualTo(0.85));
      expect(result.scorePercent, greaterThanOrEqualTo(85));
      expect(result.feedbackMessage, contains('Excellente prononciation'));
    });

    test('Prononciation avec contraction allemande parlée (hab vs habe)', () {
      final result = service.evaluate(
        spoken: 'Ich habe heute echt viel um die Ohren',
        targetParle: 'Ich hab heute echt viel um die Ohren.',
        targetStandard: 'Ich habe heute wirklich viel zu tun.',
      );

      expect(result.isSuccess, isTrue);
      expect(result.score, greaterThanOrEqualTo(0.80));
    });

    test('Prononciation avec salutation Mach\'s gut, bis bald', () {
      final result = service.evaluate(
        spoken: 'Machs gut bis bald',
        targetParle: 'Mach\'s gut, bis bald!',
        targetStandard: 'Auf Wiedersehen, bis bald!',
      );

      expect(result.isSuccess, isTrue);
      expect(result.scorePercent, greaterThanOrEqualTo(85));
    });

    test('Prononciation incorrecte non validée avec score bas', () {
      final result = service.evaluate(
        spoken: 'Das ist ein ganz anderer Satz',
        targetParle: 'Ich hab heute echt viel um die Ohren.',
        targetStandard: 'Ich habe heute wirklich viel zu tun.',
      );

      expect(result.isSuccess, isFalse);
      expect(result.score, lessThan(0.60));
      expect(result.feedbackMessage, contains('L\'écureuil'));
    });

    test('Parole vide non validée', () {
      final result = service.evaluate(
        spoken: '',
        targetParle: 'Ich hab heute echt viel um die Ohren.',
      );

      expect(result.isSuccess, isFalse);
      expect(result.score, equals(0.0));
      expect(result.feedbackMessage, contains('Aucune parole détectée'));
    });
  });
}
