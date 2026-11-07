import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_lern_deutsch_mobile/core/services/tts_service.dart';
import 'package:app_lern_deutsch_mobile/features/raetsel/domain/models/raetsel_level.dart';
import 'package:app_lern_deutsch_mobile/features/raetsel/presentation/raetsel_game_screen.dart';
import 'package:app_lern_deutsch_mobile/features/raetsel/presentation/widgets/raetsel_keyboard.dart';
import 'package:app_lern_deutsch_mobile/features/raetsel/presentation/widgets/raetsel_secret_card.dart';
import 'package:app_lern_deutsch_mobile/features/raetsel/presentation/widgets/raetsel_captured_sheet.dart';
import 'package:app_lern_deutsch_mobile/data/database/app_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RaetselLevel sampleLevel;
  late AppDatabase appDb;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    TtsService.instance.onSpeakForTesting = (text, {bool slow = false, double? rate}) {};

    AppDatabase.useInMemoryStore = true;
    appDb = AppDatabase.forTesting();
    AppDatabase.setInstanceForTesting(appDb);

    // Création d'un niveau de test simple
    // Mot 1 : TAG (lettres: T=1, A=2, G=3)
    // Mot 2 : GUT (lettres: G=3, U=4, T=1) -> Partage les lettres 1 (T) et 3 (G) avec le mot 1 !
    // Phrase secrète : "GUT" (G=3, U=4, T=1)
    sampleLevel = const RaetselLevel(
      id: 1,
      levelNumber: 1,
      seed: 42,
      secretPhraseId: 'p1',
      secretPhraseDe: 'GUT',
      secretPhraseFr: 'Bien',
      secretPhraseAr: 'جيد',
      secretPhraseNote: 'Adverbe essentiel',
      secretWords: [
        RaetselSecretWord(
          rawWord: 'GUT',
          chars: [
            RaetselSecretChar(char: 'G', isLetter: true, letterNumber: 3),
            RaetselSecretChar(char: 'U', isLetter: true, letterNumber: 4),
            RaetselSecretChar(char: 'T', isLetter: true, letterNumber: 1),
          ],
        ),
      ],
      clues: [
        RaetselClueWord(
          phraseId: 'p2',
          word: 'TAG',
          clueType: 'definition',
          clueQuestionFr: 'Le contraire de la nuit',
          clueQuestionAr: 'عكس الليل',
          fullPhraseDe: 'Guten Tag!',
          fullPhraseFr: 'Bonjour !',
          fullPhraseAr: 'طاب يومك !',
          note: 'Salutation courante',
          letterNumbers: [1, 2, 3], // T, A, G
        ),
        RaetselClueWord(
          phraseId: 'p1',
          word: 'GUT',
          clueType: 'definition',
          clueQuestionFr: 'Bien ou bon en allemand',
          clueQuestionAr: 'جيد بالألمانية',
          fullPhraseDe: 'Alles gut!',
          fullPhraseFr: 'Tout va bien !',
          fullPhraseAr: 'كل شيء على ما يرام !',
          note: 'Mot de base',
          letterNumbers: [3, 4, 1], // G, U, T
        ),
      ],
      numberToLetterMap: {
        1: 'T',
        2: 'A',
        3: 'G',
        4: 'U',
      },
    );
  });

  tearDown(() async {
    AppDatabase.useInMemoryStore = false;
    AppDatabase.setInstanceForTesting(null);
  });

  testWidgets('RaetselGameScreen affiche la phrase secrète, les questions et le clavier virtuel', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: RaetselGameScreen(
            level: sampleLevel,
            initialSupportLanguage: 'fr',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Niveau 1'), findsOneWidget);
    expect(find.byType(RaetselSecretCard), findsOneWidget);
    expect(find.text('Le contraire de la nuit'), findsOneWidget);
    expect(find.text('Bien ou bon en allemand'), findsOneWidget);
    expect(find.byType(RaetselKeyboard), findsOneWidget);
    expect(find.text('Q'), findsOneWidget);
    expect(find.text('Ä'), findsOneWidget);
    expect(find.text('Ö'), findsOneWidget);
    expect(find.text('Ü'), findsOneWidget);
    expect(find.text('ß'), findsOneWidget);
  });

  testWidgets('Taper une lettre sur le clavier synchronise toutes les cases portant le même numéro', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: RaetselGameScreen(
            level: sampleLevel,
            initialSupportLanguage: 'fr',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Au départ, la case active est la première du 1er mot (lettre T, numéro 1)
    // Taper sur 'T' sur le clavier virtuel
    final keyT = find.descendant(of: find.byType(RaetselKeyboard), matching: find.text('T'));
    expect(keyT, findsOneWidget);
    await tester.tap(keyT);
    await tester.pumpAndSettle();

    // La lettre 'T' doit maintenant apparaître dans :
    // - Le mot 1 (TAG) à la position 0 (numéro 1)
    // - Le mot 2 (GUT) à la position 2 (numéro 1)
    // - La phrase secrète (GUT) à la position 2 (numéro 1)
    expect(find.text('T'), findsWidgets);

    // Taper sur 'A' -> passe à la position suivante (numéro 2)
    final keyA = find.descendant(of: find.byType(RaetselKeyboard), matching: find.text('A'));
    await tester.tap(keyA);
    await tester.pumpAndSettle();
    expect(find.text('A'), findsWidgets);

    // Taper sur 'G' -> remplit la position suivante (numéro 3)
    final keyG = find.descendant(of: find.byType(RaetselKeyboard), matching: find.text('G'));
    await tester.tap(keyG);
    await tester.pumpAndSettle();

    // Le mot 'TAG' est maintenant complet et validé (verrouillé en vert) !
    expect(find.text('1/2'), findsOneWidget); // 1 mot trouvé sur 2
  });

  testWidgets('Compléter tous les mots valide le niveau complet', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    bool levelCompletedCalled = false;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: RaetselGameScreen(
            level: sampleLevel,
            initialSupportLanguage: 'fr',
            onLevelCompleted: () {
              levelCompletedCalled = true;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Taper T, A, G pour le mot 1
    await tester.tap(find.descendant(of: find.byType(RaetselKeyboard), matching: find.text('T')));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(RaetselKeyboard), matching: find.text('A')));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(RaetselKeyboard), matching: find.text('G')));
    await tester.pumpAndSettle();

    // Puisque G et T sont déjà remplis par synchronisation, il ne reste que U (numéro 4) pour GUT !
    await tester.tap(find.descendant(of: find.byType(RaetselKeyboard), matching: find.text('U')));
    await tester.pumpAndSettle();

    // Vérifier que les 2 mots sont résolus : 2/2
    expect(find.text('2/2'), findsOneWidget);
    expect(find.text('PHRASE MYSTÈRE RÉSOLUE !'), findsOneWidget);
    expect(levelCompletedCalled, isTrue);

    // Attendre le déclenchement du modal de victoire
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    // Vérifier l'écran de victoire RaetselVictoryScreen
    expect(find.text('NIVEAU 1 RÉUSSI !'), findsOneWidget);
    expect(find.text('Niveau suivant'), findsOneWidget);
    expect(find.textContaining('XP'), findsWidgets);
    expect(find.textContaining('Diamants'), findsWidgets);
    expect(find.text('PHRASE SECRÈTE RÉSOLUE'), findsOneWidget);
    expect(find.text('Adverbe essentiel'), findsOneWidget); // Fait intéressant de la phrase secrète
    expect(find.text('Salutation courante'), findsOneWidget); // Fait intéressant du mot 1
  });

  testWidgets('Un mot trouvé joue l\'audio et s\'affiche dans le bandeau Phrases captées', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    String? lastSpokenText;
    TtsService.instance.onSpeakForTesting = (text, {bool slow = false, double? rate}) {
      lastSpokenText = text;
    };

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: RaetselGameScreen(
            level: sampleLevel,
            initialSupportLanguage: 'fr',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Compléter TAG (T, A, G)
    await tester.tap(find.descendant(of: find.byType(RaetselKeyboard), matching: find.text('T')));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(RaetselKeyboard), matching: find.text('A')));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(RaetselKeyboard), matching: find.text('G')));
    await tester.pumpAndSettle();

    // Vérifier que l'audio de la phrase "Guten Tag!" a été joué
    expect(lastSpokenText, equals('Guten Tag!'));

    // Vérifier le bandeau Phrases captées
    expect(find.textContaining('Phrases captées (1/3)'), findsOneWidget);

    // Taper sur le bandeau pour ouvrir la feuille modale
    await tester.tap(find.textContaining('Phrases captées (1/3)'));
    await tester.pumpAndSettle();

    // Vérifier que la feuille s'affiche avec la phrase, la traduction et le mot trouvé
    expect(find.descendant(of: find.byType(RaetselCapturedSheet), matching: find.text('MOT : TAG')), findsOneWidget);
    expect(find.descendant(of: find.byType(RaetselCapturedSheet), matching: find.text('Guten Tag!')), findsOneWidget);
    expect(find.descendant(of: find.byType(RaetselCapturedSheet), matching: find.text('Bonjour !')), findsOneWidget);
    expect(find.descendant(of: find.byType(RaetselCapturedSheet), matching: find.text('Salutation courante')), findsOneWidget);
  });
}
