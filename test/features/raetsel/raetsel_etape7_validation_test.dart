import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_lern_deutsch_mobile/core/services/tts_service.dart';
import 'package:app_lern_deutsch_mobile/data/database/app_database.dart';
import 'package:app_lern_deutsch_mobile/domain/models/phrase.dart';
import 'package:app_lern_deutsch_mobile/features/raetsel/data/raetsel_generator.dart';
import 'package:app_lern_deutsch_mobile/features/raetsel/domain/raetsel_manager.dart';
import 'package:app_lern_deutsch_mobile/features/raetsel/presentation/raetsel_game_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase appDb;

  final samplePhrases = [
    const Phrase(
      id: 'p1',
      theme: 'general',
      topic: 'retard',
      deStandard: 'Ich bin spät dran.',
      deParle: 'Ich bin spät dran.',
      de: 'Ich bin spät dran.',
      fr: 'Je suis en retard.',
      ar: 'أنا متأخر.',
      note: 'spät dran sein = être en retard',
    ),
    const Phrase(
      id: 'p2',
      theme: 'general',
      topic: 'aide',
      deStandard: 'Du hast mir den Tag gerettet.',
      deParle: 'Du hast mir den Tag gerettet.',
      de: 'Du hast mir den Tag gerettet.',
      fr: 'Tu m\'as sauvé la journée.',
      ar: 'لقد أنقذت يومي.',
      note: 'den Tag retten',
    ),
    const Phrase(
      id: 'p3',
      theme: 'general',
      topic: 'week-end',
      deStandard: 'Schönes Wochenende!',
      deParle: 'Schönes Wochenende!',
      de: 'Schönes Wochenende!',
      fr: 'Bon week-end !',
      ar: 'عطلة نهاية أسبوع سعيدة!',
      note: 'Wochenende',
    ),
    const Phrase(
      id: 'p4',
      theme: 'general',
      topic: 'salutation',
      deStandard: 'Wie geht es dir heute?',
      deParle: 'Wie geht es dir heute?',
      de: 'Wie geht es dir heute?',
      fr: 'Comment vas-tu aujourd\'hui ?',
      ar: 'كيف حالك اليوم؟',
      note: 'heute',
    ),
    const Phrase(
      id: 'p5',
      theme: 'general',
      topic: 'service',
      deStandard: 'Kannst du mir einen Gefallen tun?',
      deParle: 'Kannst du mir einen Gefallen tun?',
      de: 'Kannst du mir einen Gefallen tun?',
      fr: 'Peux-tu me rendre un service ?',
      ar: 'هل يمكنك تقديم خدمة لي؟',
      note: 'Gefallen tun',
    ),
    const Phrase(
      id: 'p6',
      theme: 'general',
      topic: 'rendez-vous',
      deStandard: 'Wir können das Treffen verschieben.',
      deParle: 'Wir können das Treffen verschieben.',
      de: 'Wir können das Treffen verschieben.',
      fr: 'Nous pouvons reporter la réunion.',
      ar: 'يمكننا تأجيل الموعد.',
      note: 'verschieben',
    ),
  ];

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    TtsService.instance.onSpeakForTesting = (text, {bool slow = false, double? rate}) {};

    AppDatabase.useInMemoryStore = true;
    appDb = AppDatabase.forTesting();
    AppDatabase.setInstanceForTesting(appDb);
    for (final p in samplePhrases) {
      await appDb.savePhrase(p);
    }
  });

  tearDown(() async {
    AppDatabase.useInMemoryStore = false;
  });

  group('Étape 7 : Tests de validation finale Hoppla Rätsel', () {
    test('1. Génération déterministe (Même graine = Même niveau)', () {
      final levelA = RaetselGenerator.generateLevel(
        levelNumber: 1,
        availablePhrases: samplePhrases,
        customSeed: 12345,
      );
      final levelB = RaetselGenerator.generateLevel(
        levelNumber: 1,
        availablePhrases: samplePhrases,
        customSeed: 12345,
      );

      expect(levelA.secretPhraseDe, equals(levelB.secretPhraseDe));
      expect(levelA.secretWords.length, equals(levelB.secretWords.length));
      expect(levelA.clues.length, equals(levelB.clues.length));
      for (int i = 0; i < levelA.clues.length; i++) {
        expect(levelA.clues[i].word, equals(levelB.clues[i].word));
        expect(levelA.clues[i].letterNumbers, equals(levelB.clues[i].letterNumbers));
      }
    });

    test('2. Reprise d\'un niveau abandonné (sauvegarde et restauration)', () async {
      final manager = RaetselManager.instance;
      final level = RaetselGenerator.generateLevel(
        levelNumber: 1,
        availablePhrases: samplePhrases,
        customSeed: 999,
      );

      // Simuler l'enregistrement des lettres saisies dans un niveau abandonné
      await manager.saveInProgressLevel(
        level: level,
        enteredLetters: {1: 'S', 2: 'P', 3: 'A'},
      );

      // Restaurer le niveau abandonné
      final restored = await manager.loadInProgressLevel(expectedLevelNumber: 1);
      expect(restored, isNotNull);
      expect(restored!.level.id, equals(level.id));
      expect(restored.enteredLetters[1], equals('S'));
      expect(restored.enteredLetters[2], equals('P'));
      expect(restored.enteredLetters[3], equals('A'));

      // Test de purge lors de la complétion du niveau
      await manager.clearSavedInProgressLevel();
      final afterClear = await manager.loadInProgressLevel(expectedLevelNumber: 1);
      expect(afterClear, isNull);
    });

    testWidgets('3. Android d\'entrée de gamme (360x640) sans débordement de layout', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final level = RaetselGenerator.generateLevel(
        levelNumber: 1,
        availablePhrases: samplePhrases,
        customSeed: 101,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: RaetselGameScreen(
              level: level,
              initialSupportLanguage: 'fr',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Vérifier qu'aucun RenderFlex overflow n'est survenu
      expect(tester.takeException(), isNull);
      expect(find.byType(RaetselGameScreen), findsOneWidget);
      expect(find.text('Niveau 1'), findsOneWidget);
    });

    testWidgets('4. Support bilingue Arabe (RTL) et caractères allemands (Ä, Ö, Ü, ß)', (tester) async {
      final level = RaetselGenerator.generateLevel(
        levelNumber: 1,
        availablePhrases: samplePhrases,
        customSeed: 202,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: RaetselGameScreen(
              level: level,
              initialSupportLanguage: 'ar',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Vérifier le bon chargement sans crash en langue arabe
      expect(find.byType(RaetselGameScreen), findsOneWidget);

      // Vérifier la présence du clavier virtuel avec ä, ö, ü, ß
      expect(find.text('Ä'), findsOneWidget);
      expect(find.text('Ö'), findsOneWidget);
      expect(find.text('Ü'), findsOneWidget);
      expect(find.text('ß'), findsOneWidget);
    });
  });
}
