import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:app_lern_deutsch_mobile/core/services/tts_service.dart';
import 'package:app_lern_deutsch_mobile/core/widgets/mascot_widget.dart';
import 'package:app_lern_deutsch_mobile/data/database/app_database.dart';
import 'package:app_lern_deutsch_mobile/domain/engine/german_master_scenarios.dart';
import 'package:app_lern_deutsch_mobile/domain/models/phrase.dart';
import 'package:app_lern_deutsch_mobile/features/master_xp/presentation/master_xp_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late Database inMemoryDb;
  late AppDatabase appDb;

  final samplePhrases = [
    const Phrase(
      id: 'phrase_001',
      theme: 'smalltalk',
      topic: 'salutations',
      deStandard: 'Wie geht es dir?',
      deParle: "Na, wie läuft's?",
      de: "Na, wie läuft's?",
      ar: 'طيب، كيف الأحوال؟',
      fr: 'Alors, comment ça roule ?',
      note: "läuft's = läuft es.",
    ),
    const Phrase(
      id: 'phrase_002',
      theme: 'smalltalk',
      topic: 'salutations',
      deStandard: 'Wir haben uns lange nicht gesehen!',
      deParle: 'Mensch, lange nicht gesehen!',
      de: 'Mensch, lange nicht gesehen!',
      ar: 'يا رجل، من زمان ما شفتك!',
      fr: "Ça fait un bail qu'on s'est pas vus !",
    ),
    const Phrase(
      id: 'phrase_003',
      theme: 'smalltalk',
      topic: 'salutations',
      deStandard: 'Gibt es etwas Neues?',
      deParle: "Was gibt's Neues?",
      de: "Was gibt's Neues?",
      ar: 'شو الجديد؟',
      fr: 'Quoi de neuf ?',
    ),
    const Phrase(
      id: 'phrase_004',
      theme: 'smalltalk',
      topic: 'salutations',
      deStandard: 'Ich muss jetzt gehen.',
      deParle: 'Ich muss los.',
      de: 'Ich muss los.',
      ar: 'لازم أمشي الآن',
      fr: "Faut que j'y aille.",
    ),
    const Phrase(
      id: 'phrase_005',
      theme: 'smalltalk',
      topic: 'salutations',
      deStandard: 'Wie war dein Wochenende?',
      deParle: "Na, wie war's am Wochenende?",
      de: "Na, wie war's am Wochenende?",
      ar: 'كيف كانت عطلة نهاية الأسبوع؟',
      fr: "Alors, c'était comment ton week-end ?",
    ),
    const Phrase(
      id: 'phrase_006',
      theme: 'smalltalk',
      topic: 'salutations',
      deStandard: 'Es freut mich, dich zu sehen.',
      deParle: 'Schön, dich mal wieder zu sehen!',
      de: 'Schön, dich mal wieder zu sehen!',
      ar: 'حلو أشوفك مرة ثانية',
      fr: 'Ça fait plaisir de te revoir !',
    ),
    const Phrase(
      id: 'phrase_007',
      theme: 'smalltalk',
      topic: 'salutations',
      deStandard: 'Das Wetter ist heute schrecklich.',
      deParle: 'Das Wetter ist heute echt mies.',
      de: 'Das Wetter ist heute echt mies.',
      ar: 'الجو اليوم سيئ جداً',
      fr: "Le temps est vraiment pourri aujourd'hui.",
    ),
    const Phrase(
      id: 'phrase_008',
      theme: 'smalltalk',
      topic: 'salutations',
      deStandard: 'Es regnet sehr stark.',
      deParle: 'Es schüttet wie aus Eimern.',
      de: 'Es schüttet wie aus Eimern.',
      ar: 'المطر ينهمر بغزارة',
      fr: 'Il pleut des cordes.',
    ),
    const Phrase(
      id: 'phrase_009',
      theme: 'smalltalk',
      topic: 'salutations',
      deStandard: 'Wissen Sie, wie spät es ist?',
      deParle: 'Hast du mal die Uhrzeit?',
      de: 'Hast du mal die Uhrzeit?',
      ar: 'تعرف كم الساعة؟',
      fr: "T'aurais l'heure s'il te plaît ?",
    ),
    const Phrase(
      id: 'phrase_010',
      theme: 'smalltalk',
      topic: 'salutations',
      deStandard: 'Auf Wiedersehen, pass auf dich auf!',
      deParle: "Mach's gut, bis bald!",
      de: "Mach's gut, bis bald!",
      ar: 'مع السلامة، اعتنِ بنفسك',
      fr: 'Prends soin de toi, à bientôt !',
    ),
  ];

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'master_xp_available': true,
      'last_session_phrases': [
        'phrase_001',
        'phrase_002',
        'phrase_003',
        'phrase_004',
        'phrase_005',
        'phrase_006',
        'phrase_007',
        'phrase_008',
        'phrase_009',
        'phrase_010',
      ],
    });
    MascotWidget.enableAnimations = false;
    TtsService.instance.onSpeakForTesting = (text, {bool slow = false, double? rate}) {};

    inMemoryDb = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    appDb = AppDatabase.forTesting(testDb: inMemoryDb);
    await appDb.createSchema(inMemoryDb);
    AppDatabase.setInstanceForTesting(appDb);

    final batch = inMemoryDb.batch();
    for (final p in samplePhrases) {
      batch.insert('phrases', {
        'id': p.id,
        'theme': p.theme,
        'topic': p.topic,
        'de_standard': p.deStandard,
        'de_parle': p.deParle,
        'de': p.de,
        'fr': p.fr,
        'ar': p.ar,
        'note': p.note,
        'cefr': p.cefr,
      });
    }
    await batch.commit(noResult: true);
  });

  tearDown(() async {
    MascotWidget.enableAnimations = true;
    await inMemoryDb.close();
  });

  group('GermanMasterScenariosCatalog Tests', () {
    test('Retourne le scénario expert pour phrase_001 (Na, wie läuft\'s?)', () {
      const phrase = Phrase(
        id: 'phrase_001',
        theme: 'smalltalk',
        topic: 'salutations',
        deStandard: 'Wie geht es dir?',
        deParle: "Na, wie läuft's?",
        de: "Na, wie läuft's?",
        fr: 'Alors, comment ça roule ?',
        ar: 'طيب، كيف الأحوال؟',
      );

      final scenario = GermanMasterScenariosCatalog.getScenarioFor(phrase);
      expect(scenario.phraseId, 'phrase_001');
      expect(scenario.speakerName, contains('Markus'));
      expect(scenario.dialogueGerman, contains('Thomas'));
      expect(scenario.situationArabic, contains('تقابل'));
      expect(scenario.explanationGerman, contains('Na, wie läuft\'s?'));
    });

    test('Génère un scénario de repli expert pour une phrase personnalisée', () {
      const customPhrase = Phrase(
        id: 'phrase_999',
        theme: 'restaurant',
        topic: 'commande',
        deStandard: 'Ich möchte bestellen.',
        deParle: 'Ich hätte gern die Karte.',
        de: 'Ich hätte gern die Karte.',
        fr: 'Je voudrais le menu.',
        ar: 'أريد قائمة الطعام',
      );

      final scenario = GermanMasterScenariosCatalog.getScenarioFor(customPhrase);
      expect(scenario.phraseId, 'phrase_999');
      expect(scenario.speakerName, contains('Kellner'));
      expect(scenario.dialogueGerman, contains('Guten Tag'));
    });
  });

  group('MasterXpScreen Widget Tests', () {
    testWidgets('Rendu initial de MasterXpScreen avec barre de progression et onglets', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: MasterXpScreen(initialPhrases: samplePhrases),
        ),
      );

      await tester.pumpAndSettle();

      // Vérifie la présence de la barre et des onglets
      expect(find.textContaining('Lot de 10 phrases'), findsOneWidget);
      expect(find.text('🌟 Défi Mixte'), findsOneWidget);
      expect(find.text('🇩🇪 Ex. 1 : Arabe ➔ Allemand'), findsOneWidget);
      expect(find.text('💬 Ex. 2 : Situations & Réponses'), findsOneWidget);
    });

    testWidgets('Exercice 1 : Affiche la phrase en arabe et valide le choix parmi la liste', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: MasterXpScreen(initialPhrases: samplePhrases),
        ),
      );

      await tester.pumpAndSettle();

      // Basculer sur l'onglet Exercice 1 (Arabe -> Allemand)
      await tester.tap(find.text('🇩🇪 Ex. 1 : Arabe ➔ Allemand'));
      await tester.pumpAndSettle();

      // Vérifie l'en-tête de l'exercice 1
      expect(find.text('EXERCICE 1 · TRADUCTION'), findsOneWidget);
      expect(find.text('Comment dit-on cette phrase en allemand ?'), findsOneWidget);

      // Trouve l'option qui correspond à la bonne réponse pour phrase_001 ("Na, wie läuft's?")
      final correctFinder = find.text("Na, wie läuft's?");
      expect(correctFinder, findsWidgets);

      // Clique sur la réponse correcte
      await tester.tap(correctFinder.last);
      await tester.pumpAndSettle();

      // Vérifie que le feedback positif s'affiche
      expect(find.textContaining('Richtig!'), findsOneWidget);
      expect(find.text('CONTINUER'), findsOneWidget);
    });

    testWidgets('Exercice 1 : Bascule vers le mode clavier et tape la phrase', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: MasterXpScreen(initialPhrases: samplePhrases),
        ),
      );

      await tester.pumpAndSettle();

      // Basculer sur l'onglet Exercice 1
      await tester.tap(find.text('🇩🇪 Ex. 1 : Arabe ➔ Allemand'));
      await tester.pumpAndSettle();

      // Clique sur l'icône clavier
      await tester.tap(find.byIcon(Icons.keyboard_rounded));
      await tester.pumpAndSettle();

      // Champ de texte présent
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      // Tape la réponse
      await tester.enterText(textField, "Na, wie lauft's?");
      await tester.pumpAndSettle();

      // Bouton vérifier ma réponse
      final verifyButton = find.text('VÉRIFIER MA RÉPONSE');
      expect(verifyButton, findsOneWidget);
      await tester.tap(verifyButton);
      await tester.pumpAndSettle();

      // Tolérance et validation acceptée
      expect(find.textContaining('Bien joué !'), findsOneWidget);
    });

    testWidgets('Exercice 2 : Affiche le dialogue et la situation en arabe pour répondre parmi les 10 phrases', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: MasterXpScreen(initialPhrases: samplePhrases),
        ),
      );

      await tester.pumpAndSettle();

      // Basculer sur l'onglet Exercice 2 (Situations & Réponses)
      await tester.tap(find.text('💬 Ex. 2 : Situations & Réponses'));
      await tester.pumpAndSettle();

      // Vérifie les éléments de l'exercice 2
      expect(find.text('EXERCICE 2 · SITUATION RÉELLE'), findsOneWidget);
      expect(find.textContaining('Quelle est la réponse la plus adaptée'), findsOneWidget);
      expect(find.textContaining('Markus (Kollege)'), findsOneWidget);

      // Clique sur la réponse adaptée ("Na, wie läuft's?")
      final target = find.text("Na, wie läuft's?");
      expect(target, findsWidgets);
      await tester.tap(target.last);
      await tester.pumpAndSettle();

      // Vérifie la validation et l'explication experte
      expect(find.textContaining('Richtig!'), findsOneWidget);
      expect(find.textContaining('Na, wie läuft\'s?'), findsWidgets);
    });
  });
}
