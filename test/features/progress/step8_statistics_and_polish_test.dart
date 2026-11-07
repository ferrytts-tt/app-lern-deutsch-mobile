import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_lern_deutsch_mobile/core/services/tts_service.dart';
import 'package:app_lern_deutsch_mobile/core/widgets/mascot_widget.dart';
import 'package:app_lern_deutsch_mobile/data/database/app_database.dart';
import 'package:app_lern_deutsch_mobile/domain/models/phrase.dart';
import 'package:app_lern_deutsch_mobile/domain/models/user_phrase.dart';
import 'package:app_lern_deutsch_mobile/features/progress/presentation/progress_controller.dart';
import 'package:app_lern_deutsch_mobile/features/progress/presentation/progress_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database sqliteDb;
  late AppDatabase appDb;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    TtsService.instance.onSpeakForTesting = (text, {bool slow = false, double? rate}) {};
    MascotWidget.enableAnimations = false;
    sqliteDb = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    appDb = AppDatabase.forTesting(testDb: sqliteDb);
    AppDatabase.setInstanceForTesting(appDb);
    await appDb.createSchema(sqliteDb);
  });

  tearDown(() async {
    MascotWidget.enableAnimations = true;
    AppDatabase.setInstanceForTesting(null);
    await sqliteDb.close();
  });

  group('Étape 8 : Statistiques, Phrases acquises par thème & Polish final', () {
    test('8.1 Critère de validation : Les chiffres correspondent strictement à la table progression', () async {
      // 1. Insérer un jeu de phrases dans la base
      final phrases = [
        const Phrase(id: 'p1', theme: 'travail', topic: 'travail', deStandard: 'Wie geht es?', deParle: 'Wie gehts?', ar: 'كيف الحال؟'),
        const Phrase(id: 'p2', theme: 'travail', topic: 'travail', deStandard: 'Ich habe keine Zeit.', deParle: 'Keine Zeit.', ar: 'ما عندي وقت'),
        const Phrase(id: 'p3', theme: 'smalltalk', topic: 'salutations', deStandard: 'Schönen Tag noch!', deParle: 'Schönen Tag noch!', ar: 'يوماً سعيداً'),
        const Phrase(id: 'p4', theme: 'smalltalk', topic: 'salutations', deStandard: 'Bis später!', deParle: 'Bis später!', ar: 'أراك لاحقاً'),
        const Phrase(id: 'p5', theme: 'sante', topic: 'urgences', deStandard: 'Gute Besserung!', deParle: 'Gute Besserung!', ar: 'بالشفاء'),
      ];

      for (final p in phrases) {
        await appDb.insertPhrase(p);
      }

      // 2. Insérer une progression variée dans la table progression
      // p1 : Niveau 7 (Acquise)
      await appDb.saveProgression(UserPhrase(
        phraseId: 'p1',
        level: 7,
        reps: 8,
        lapses: 0,
        dueAt: DateTime.now().add(const Duration(days: 90)),
        status: UserPhraseStatus.maitrisee,
      ));

      // p2 : Niveau 6 (Maîtrisée, non encore niveau 7)
      await appDb.saveProgression(UserPhrase(
        phraseId: 'p2',
        level: 6,
        reps: 6,
        lapses: 1,
        dueAt: DateTime.now().add(const Duration(days: 30)),
        status: UserPhraseStatus.tresSolide,
      ));

      // p3 : Niveau 2 (En cours) avec 4 échecs (Phrase difficile / à surveiller)
      await appDb.saveProgression(UserPhrase(
        phraseId: 'p3',
        level: 2,
        reps: 2,
        lapses: 4,
        isDifficult: true,
        dueAt: DateTime.now().add(const Duration(days: 2)),
        status: UserPhraseStatus.aSurveiller,
      ));

      // 3. Charger le contrôleur de statistiques
      final controller = ProgressController(database: appDb);
      await controller.loadProgress();
      final state = controller.state;

      // Vérifications rigoureuses avec la table progression :
      expect(state.totalPhrasesCount, equals(5));
      expect(state.startedCount, equals(3), reason: '3 phrases ont été commencées (p1, p2, p3)');
      expect(state.newUnstartedCount, equals(2), reason: '2 phrases non démarrées (p4, p5)');
      expect(state.acquiredCount, equals(1), reason: '1 seule phrase au niveau 7 (p1)');
      expect(state.masteredCount, equals(2), reason: '2 phrases au niveau >= 6 (p1, p2)');
      expect(state.inProgressCount, equals(1), reason: '1 phrase en cours aux niveaux 1-5 (p3)');
      expect(state.watchlistPhrases.length, equals(1), reason: 'p3 est marquée difficile/à surveiller');
    });

    test('8.2 Phrases acquises par thème (Section 8 du plan)', () async {
      // Deux phrases dans le thème 'travail'
      await appDb.insertPhrase(const Phrase(id: 'p_tr_1', theme: 'travail', topic: 'travail', deStandard: 'Std 1', deParle: 'Spk 1'));
      await appDb.insertPhrase(const Phrase(id: 'p_tr_2', theme: 'travail', topic: 'travail', deStandard: 'Std 2', deParle: 'Spk 2'));

      // Une phrase dans le thème 'smalltalk'
      await appDb.insertPhrase(const Phrase(id: 'p_sm_1', theme: 'smalltalk', topic: 'salutations', deStandard: 'Std 3', deParle: 'Spk 3'));

      // p_tr_1 acquise au Niveau 7
      await appDb.saveProgression(UserPhrase(
        phraseId: 'p_tr_1',
        level: 7,
        reps: 7,
        lapses: 0,
        dueAt: DateTime.now().add(const Duration(days: 90)),
        status: UserPhraseStatus.maitrisee,
      ));

      // p_tr_2 en cours (Niveau 3)
      await appDb.saveProgression(UserPhrase(
        phraseId: 'p_tr_2',
        level: 3,
        reps: 3,
        lapses: 1,
        dueAt: DateTime.now().add(const Duration(days: 4)),
        status: UserPhraseStatus.enCours,
      ));

      final controller = ProgressController(database: appDb);
      await controller.loadProgress();

      final travailItem = controller.state.topicProgress.firstWhere((t) => t.topic.id == 'travail');
      expect(travailItem.totalCount, equals(2));
      expect(travailItem.startedCount, equals(2));
      expect(travailItem.acquiredCount, equals(1), reason: 'Strictement 1 phrase acquise au niveau 7');
      expect(travailItem.progressRatio, equals(1.0));
      expect(travailItem.acquiredRatio, equals(0.5));
    });

    test('8.3 « Quelle phrase échoue le plus souvent ? » (Section 8 du plan)', () async {
      await appDb.insertPhrase(const Phrase(id: 'f1', theme: 'travail', topic: 'travail', deStandard: 'Phrase facile', deParle: 'Phrase facile'));
      await appDb.insertPhrase(const Phrase(id: 'f2', theme: 'travail', topic: 'travail', deStandard: 'Phrase moyenne', deParle: 'Phrase moyenne'));
      await appDb.insertPhrase(const Phrase(id: 'f3', theme: 'travail', topic: 'travail', deStandard: 'Phrase résistante', deParle: 'Phrase résistante'));

      // f1 : 0 échec
      await appDb.saveProgression(UserPhrase(phraseId: 'f1', level: 4, reps: 4, lapses: 0, dueAt: DateTime.now()));
      // f2 : 2 échecs
      await appDb.saveProgression(UserPhrase(phraseId: 'f2', level: 2, reps: 3, lapses: 2, dueAt: DateTime.now()));
      // f3 : 5 échecs (phrase qui échoue le plus souvent, difficile)
      await appDb.saveProgression(UserPhrase(phraseId: 'f3', level: 1, reps: 2, lapses: 5, isDifficult: true, dueAt: DateTime.now()));

      final controller = ProgressController(database: appDb);
      await controller.loadProgress();

      final mostFailed = controller.state.mostFailedPhrases;
      expect(mostFailed.length, equals(2), reason: 'Seules f2 et f3 ont des échecs');
      // La première doit être la phrase ayant le plus d'échecs (f3 avec 5 échecs)
      expect(mostFailed.first.phrase.id, equals('f3'));
      expect(mostFailed.first.lapses, equals(5));
      expect(mostFailed.first.isDifficult, isTrue);
      // La seconde est f2 avec 2 échecs
      expect(mostFailed[1].phrase.id, equals('f2'));
      expect(mostFailed[1].lapses, equals(2));
    });

    test('8.4 Import d\'un lot quotidien : Déduplication stricte et préservation de la progression', () async {
      // 1. Initialiser une phrase et sa progression
      await appDb.insertPhrase(const Phrase(
        id: 'initial_p1',
        theme: 'travail',
        topic: 'travail',
        deStandard: 'Guten Morgen allerseits',
        deParle: 'Morgen zusammen!',
      ));

      await appDb.saveProgression(UserPhrase(
        phraseId: 'initial_p1',
        level: 5,
        reps: 5,
        lapses: 0,
        dueAt: DateTime.now().add(const Duration(days: 14)),
      ));

      // 2. Nouveau lot quotidien fourni par l'utilisateur (avec 1 doublon et 2 nouveautés, ids numériques ou absents)
      final newLotJson = jsonEncode([
        // Doublon identique sur de_standard (doit être ignoré)
        {
          "id": 1,
          "theme": "travail",
          "de_standard": "Guten Morgen allerseits",
          "de_parle": "Morgen zusammen!",
          "ar": "صباح الخير جميعاً",
        },
        // Nouvelle phrase 1 (sans id explicite)
        {
          "theme": "travail",
          "de_standard": "Ich bin gleich fertig.",
          "de_parle": "Bin gleich durch.",
          "ar": "أنا على وشك الانتهاء",
          "note": "durch sein = fertig sein"
        },
        // Nouvelle phrase 2 (id répété pouvant entrer en collision)
        {
          "id": 1,
          "theme": "amis",
          "de_standard": "Kommst du heute Abend?",
          "de_parle": "Kommste heut Abend?",
          "ar": "هل ستأتي الليلة؟",
        }
      ]);

      final importedCount = await appDb.importPhrasesFromJson(jsonContent: newLotJson);
      expect(importedCount, equals(2), reason: '2 nouvelles phrases importées, 1 doublon de_standard ignoré');

      final allPhrases = await appDb.getAllPhrases();
      expect(allPhrases.length, equals(3), reason: 'Total de 3 phrases en base');

      // Vérifier que la progression de l'ancienne phrase n'a PAS été altérée
      final progressionMap = await appDb.getAllProgression();
      expect(progressionMap.containsKey('initial_p1'), isTrue);
      expect(progressionMap['initial_p1']!.level, equals(5));
      expect(progressionMap['initial_p1']!.reps, equals(5));
    });

    testWidgets('8.5 Rendu de ProgressScreen : Mascotte écureuil, Paliers, Thèmes et Phrases résistantes', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      SharedPreferences.setMockInitialValues({});
      MascotWidget.enableAnimations = false;
      TtsService.instance.onSpeakForTesting = (text, {bool slow = false, double? rate}) {};

      AppDatabase.setInstanceForTesting(null);
      AppDatabase.useInMemoryStore = true;
      final memDb = AppDatabase.instance;
      memDb.clearInMemoryStore();

      await memDb.insertPhrase(const Phrase(
        id: 'p_render_1',
        theme: 'travail',
        topic: 'travail',
        deStandard: 'Ich schaffe das.',
        deParle: 'Ich pack das schon.',
        ar: 'سأتدبر الأمر',
      ));

      await memDb.saveProgression(UserPhrase(
        phraseId: 'p_render_1',
        level: 1,
        reps: 1,
        lapses: 5,
        isDifficult: true,
        dueAt: DateTime.now(),
      ));

      final testController = ProgressController(database: memDb);
      await testController.loadProgress();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            progressControllerProvider.overrideWith((ref) => testController),
          ],
          child: const MaterialApp(
            home: ProgressScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Mes Progrès'), findsOneWidget);
      expect(find.byType(MascotWidget), findsWidgets);

      // Vérifier la présence de la section Phrases résistantes & Fréquence d'échecs
      expect(find.textContaining('Phrases résistantes'), findsOneWidget);
      expect(find.textContaining('5 échecs'), findsOneWidget);

      // Vérifier la présence de la section Maîtrise par Thème
      expect(find.text('Maîtrise par Thème'), findsOneWidget);

      AppDatabase.useInMemoryStore = false;
    });
  });
}
