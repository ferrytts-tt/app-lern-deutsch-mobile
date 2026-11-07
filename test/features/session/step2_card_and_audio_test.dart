import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_lern_deutsch_mobile/core/services/tts_service.dart';
import 'package:app_lern_deutsch_mobile/core/widgets/spoken_phrase_card.dart';
import 'package:app_lern_deutsch_mobile/domain/engine/srs_engine.dart';
import 'package:app_lern_deutsch_mobile/domain/models/phrase.dart';
import 'package:app_lern_deutsch_mobile/domain/models/user_phrase.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final samplePhrase = Phrase(
    id: 'phrase_001',
    theme: 'smalltalk',
    topic: 'salutations',
    deStandard: 'Wie geht es dir?',
    deParle: 'Na, wie läuft\'s?',
    ar: 'طيب، كيف الأحوال؟',
    fr: 'Alors, comment ça roule ?',
    note: 'läuft\'s = läuft es. كلمة Na تفتح الحديث.',
    cefr: 'B1',
  );

  group('Étape 2 : Carte et audio — SpokenPhraseCard', () {
    testWidgets('Critère de validation : La traduction arabe est masquée puis s\'affiche au clic', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SpokenPhraseCard(
                phrase: samplePhrase,
                preferredTranslationLanguage: 'ar',
                initialShowTranslation: false,
              ),
            ),
          ),
        ),
      );

      // 1. La forme parlée (de_parle) est bien affichée en grand
      expect(find.text('Na, wie läuft\'s?'), findsOneWidget);

      // 2. La traduction arabe n'est PAS encore affichée
      expect(find.byKey(const Key('text_translation_ar')), findsNothing);
      expect(find.byKey(const Key('btn_show_translation')), findsOneWidget);

      // 3. Clic sur le bouton discret de traduction
      await tester.tap(find.byKey(const Key('btn_show_translation')));
      await tester.pumpAndSettle();

      // 4. La traduction arabe est maintenant affichée avec son texte RTL
      expect(find.byKey(const Key('text_translation_ar')), findsOneWidget);
      expect(find.text('طيب، كيف الأحوال؟'), findsOneWidget);
    });

    testWidgets('Critère de validation : Écoute de la phrase à vitesse normale et vitesse lente', (tester) async {
      String? spokenText;
      bool? isSlowSpeed;
      double? speechRate;

      // Interception synchrone du service TTS pour test unitaire
      TtsService.instance.onSpeakForTesting = (text, {bool slow = false, double? rate}) {
        spokenText = text;
        isSlowSpeed = slow;
        speechRate = rate;
      };

      addTearDown(() {
        TtsService.instance.onSpeakForTesting = null;
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SpokenPhraseCard(
                phrase: samplePhrase,
              ),
            ),
          ),
        ),
      );

      // 1. Clic sur le bouton Audio Vitesse Normale (1.0x)
      final normalAudioButton = find.byKey(const Key('btn_audio_normal'));
      expect(normalAudioButton, findsOneWidget);
      await tester.tap(normalAudioButton);
      await tester.pumpAndSettle();

      expect(spokenText, equals('Na, wie läuft\'s?'));
      expect(isSlowSpeed, isFalse, reason: 'L\'écoute normale doit avoir slow = false');
      expect(speechRate, equals(1.0));

      // 2. Clic sur le bouton Audio Vitesse Lente (0.65x)
      final slowAudioButton = find.byKey(const Key('btn_audio_slow'));
      expect(slowAudioButton, findsOneWidget);
      await tester.tap(slowAudioButton);
      await tester.pumpAndSettle();

      expect(spokenText, equals('Na, wie läuft\'s?'));
      expect(isSlowSpeed, isTrue, reason: 'L\'écoute lente doit avoir slow = true');
      expect(speechRate, equals(0.65));
    });

    testWidgets('Forme standard masquée par défaut et dépliable au clic', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SpokenPhraseCard(
                phrase: samplePhrase,
                initialShowStandard: false,
              ),
            ),
          ),
        ),
      );

      // La forme standard n'est pas dépliée initialement
      expect(find.byKey(const Key('text_standard_phrase')), findsNothing);
      expect(find.byKey(const Key('btn_toggle_standard')), findsOneWidget);

      // Clic pour déplier la forme standard
      await tester.tap(find.byKey(const Key('btn_toggle_standard')));
      await tester.pumpAndSettle();

      // La forme standard Hochdeutsch est maintenant visible
      expect(find.byKey(const Key('text_standard_phrase')), findsOneWidget);
      expect(find.text('Wie geht es dir?'), findsOneWidget);
    });

    testWidgets('Note d\'explication présente avec l\'astuce de langue', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SpokenPhraseCard(
                phrase: samplePhrase,
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('container_phrase_note')), findsOneWidget);
      expect(find.textContaining('läuft\'s = läuft es'), findsOneWidget);
    });

    testWidgets('Bouton « Trop facile » saute au niveau 4 avec délai de 7 jours', (tester) async {
      bool tooEasyTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SpokenPhraseCard(
                phrase: samplePhrase,
                onTooEasy: () => tooEasyTriggered = true,
              ),
            ),
          ),
        ),
      );

      final tooEasyButton = find.byKey(const Key('btn_too_easy'));
      expect(tooEasyButton, findsOneWidget);

      await tester.tap(tooEasyButton);
      await tester.pumpAndSettle();

      expect(tooEasyTriggered, isTrue);

      // Vérification du moteur SRS : saut direct au Niveau 4 (7 jours)
      final initialUserPhrase = UserPhrase(
        phraseId: samplePhrase.id,
        level: 0,
        dueAt: DateTime(2026, 10, 25, 10, 0),
      );

      final updated = const SrsEngine().markAsTooEasy(
        initialUserPhrase,
        now: DateTime(2026, 10, 25, 10, 0),
      );

      expect(updated.level, equals(4), reason: 'La phrase doit sauter au niveau 4');
      expect(updated.status, equals(UserPhraseStatus.assezSolide));
      expect(
        updated.dueAt.difference(DateTime(2026, 10, 25, 10, 0)).inDays,
        equals(7),
        reason: 'Le délai de révision du niveau 4 doit être de 7 jours',
      );
    });
  });
}
