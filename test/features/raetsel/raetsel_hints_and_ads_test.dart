import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_lern_deutsch_mobile/core/services/tts_service.dart';
import 'package:app_lern_deutsch_mobile/data/database/app_database.dart';
import 'package:app_lern_deutsch_mobile/features/raetsel/domain/models/raetsel_level.dart';
import 'package:app_lern_deutsch_mobile/features/raetsel/domain/raetsel_manager.dart';
import 'package:app_lern_deutsch_mobile/features/raetsel/presentation/raetsel_game_screen.dart';
import 'package:app_lern_deutsch_mobile/features/raetsel/presentation/widgets/raetsel_banner_ad_widget.dart';
import 'package:app_lern_deutsch_mobile/features/raetsel/presentation/widgets/raetsel_hints_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RaetselLevel mockLevel;
  late AppDatabase appDb;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'total_gems': 10,
    });
    TtsService.instance.onSpeakForTesting = (text, {bool slow = false, double? rate}) {};

    AppDatabase.useInMemoryStore = true;
    appDb = AppDatabase.forTesting();
    AppDatabase.setInstanceForTesting(appDb);

    mockLevel = const RaetselLevel(
      id: 1,
      levelNumber: 1,
      seed: 42,
      secretPhraseId: 'p_secret',
      secretPhraseDe: 'GUT',
      secretPhraseFr: 'Bien',
      secretPhraseAr: 'جيد',
      secretPhraseNote: 'Bravo pour vos efforts.',
      secretWords: [
        RaetselSecretWord(
          rawWord: 'GUT',
          chars: [
            RaetselSecretChar(char: 'G', letterNumber: 1, isLetter: true),
            RaetselSecretChar(char: 'U', letterNumber: 2, isLetter: true),
            RaetselSecretChar(char: 'T', letterNumber: 3, isLetter: true),
          ],
        ),
      ],
      clues: [
        RaetselClueWord(
          phraseId: 'p_clue_1',
          word: 'GUT',
          letterNumbers: [1, 2, 3],
          clueType: 'definition',
          clueQuestionFr: 'Synonyme de bon',
          clueQuestionAr: 'جيد',
          fullPhraseDe: 'Das ist gut.',
          fullPhraseFr: 'C\'est bien.',
          fullPhraseAr: 'هذا جيد.',
          note: 'Adverbe essentiel',
        ),
      ],
      numberToLetterMap: {
        1: 'G',
        2: 'U',
        3: 'T',
      },
    );
  });

  tearDown(() {
    AppDatabase.useInMemoryStore = false;
    AppDatabase.setInstanceForTesting(null);
  });

  group('Étape 6 : Indices, Économie des diamants et Publicités', () {
    testWidgets('L\'écran de jeu affiche la bannière publicitaire et le bouton indice 💡', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: RaetselGameScreen(level: mockLevel),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Vérifier le bouton d'indices (💡)
      expect(find.byIcon(Icons.lightbulb_rounded), findsOneWidget);

      // Vérifier la bannière publicitaire
      expect(find.byType(RaetselBannerAdWidget), findsOneWidget);
    });

    testWidgets('Appuyer sur 💡 ouvre la feuille modale des indices avec le solde de diamants', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: RaetselGameScreen(level: mockLevel),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Taper sur le bouton indice
      await tester.tap(find.byIcon(Icons.lightbulb_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // La feuille d'indices est affichée
      expect(find.byType(RaetselHintsSheet), findsOneWidget);
      expect(find.text('Indices disponibles 💡'), findsOneWidget);
      expect(find.text('Révéler une lettre'), findsOneWidget);
      expect(find.text('Révéler tout le mot'), findsOneWidget);
      expect(find.text('Écouter la phrase source'), findsOneWidget);
      expect(find.text('Vidéo publicitaire récompensée'), findsOneWidget);

      // Vérifier le solde affiché (10)
      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('Révéler une lettre déduit 2 diamants et remplit la case', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: RaetselGameScreen(level: mockLevel),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Ouvrir la feuille
      await tester.tap(find.byIcon(Icons.lightbulb_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Taper sur 'Révéler une lettre'
      await tester.tap(find.text('Révéler une lettre'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Le solde doit maintenant être 8 (10 - 2)
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('total_gems'), 8);

      // La lettre G est révélée
      expect(find.text('G'), findsWidgets);
    });

    test('Logique de publicité interstitielle : au plus tous les 3 niveaux', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('raetsel_levels_since_last_ad', 0);

      // Niveau 1 complété : pas d'interstitiel (1/3)
      expect(await RaetselManager.instance.shouldShowInterstitialAd(prefs: prefs), false);

      // Niveau 2 complété : pas d'interstitiel (2/3)
      expect(await RaetselManager.instance.shouldShowInterstitialAd(prefs: prefs), false);

      // Niveau 3 complété : interstitiel déclenché ! (3/3 -> reset à 0)
      expect(await RaetselManager.instance.shouldShowInterstitialAd(prefs: prefs), true);

      // Niveau 4 complété : pas d'interstitiel (1/3)
      expect(await RaetselManager.instance.shouldShowInterstitialAd(prefs: prefs), false);
    });
  });
}
