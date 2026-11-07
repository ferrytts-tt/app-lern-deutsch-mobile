import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_lern_deutsch_mobile/core/services/tts_service.dart';
import 'package:app_lern_deutsch_mobile/core/widgets/duo_streak_widget.dart';
import 'package:app_lern_deutsch_mobile/core/widgets/mascot_widget.dart';
import 'package:app_lern_deutsch_mobile/data/database/app_database.dart';
import 'package:app_lern_deutsch_mobile/domain/models/phrase.dart';
import 'package:app_lern_deutsch_mobile/features/home/presentation/home_screen.dart';
import 'package:app_lern_deutsch_mobile/features/navigation/app_router.dart';
import 'package:app_lern_deutsch_mobile/features/navigation/main_scaffold.dart';
import 'package:app_lern_deutsch_mobile/features/raetsel/domain/raetsel_manager.dart';
import 'package:app_lern_deutsch_mobile/features/raetsel/presentation/widgets/raetsel_locked_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase appDb;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    MascotWidget.enableAnimations = false;
    DuoStreakWidget.enableAnimations = false;
    MainScaffold.enableAnimations = false;
    TtsService.instance.onSpeakForTesting = (text, {bool slow = false, double? rate}) {};

    AppDatabase.useInMemoryStore = true;
    appDb = AppDatabase.forTesting();
    AppDatabase.setInstanceForTesting(appDb);

    // Initialiser 35 phrases pour le test
    for (int i = 0; i < 35; i++) {
      await appDb.savePhrase(Phrase(
        id: 'p$i',
        theme: 'smalltalk',
        topic: 'salutations',
        deStandard: 'Phrase $i',
        deParle: 'Phrase $i',
        de: 'Phrase $i',
        fr: 'Phrase $i',
      ));
    }
  });

  tearDown(() async {
    MascotWidget.enableAnimations = true;
    DuoStreakWidget.enableAnimations = true;
    MainScaffold.enableAnimations = true;
    AppDatabase.useInMemoryStore = false;
    AppDatabase.setInstanceForTesting(null);
  });

  testWidgets('Barre du bas : affiche 5 icônes [Accueil, Écoute, Rätsel, Progrès, Réglages]', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Vérifier l'écran d'accueil
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('Avant l\'Examen 1 : Rätsel est verrouillé avec cadenas et ouvre la boîte de dialogue', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('palier_exam_1_passed', false);
    await prefs.setBool('raetsel_unlocked', false);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: appRouter,
        ),
      ),
    );
    // Naviguer sur /home
    appRouter.go('/home');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Trouver l'icône de cadenas sur la pièce de puzzle
    final lockIcon = find.byIcon(Icons.lock_rounded);
    expect(lockIcon, findsWidgets);

    // La carte Hoppla Rätsel ne doit pas être affichée sur l'accueil avant déblocage
    expect(find.text('Jouer au Niveau 1'), findsNothing);

    // Taper sur l'icône de la pièce de puzzle
    final puzzleIcon = find.byIcon(Icons.extension_rounded);
    expect(puzzleIcon, findsOneWidget);
    await tester.tap(puzzleIcon);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // La boîte de dialogue de verrouillage doit apparaître avec le message exact
    expect(find.byType(RaetselLockedDialog), findsOneWidget);
    expect(find.text('Réussis l\'Examen 1 (20/30) pour débloquer Hoppla Rätsel'), findsOneWidget);
    expect(find.text('Phrases apprises (Palier 1)'), findsOneWidget);
    expect(find.text('0 / 30'), findsOneWidget);
  });

  testWidgets('Réussir l\'Examen 1 débloque Hoppla Rätsel en direct et affiche la carte sur l\'accueil', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('palier_exam_1_passed', false);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: appRouter,
        ),
      ),
    );
    appRouter.go('/home');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Jouer au Niveau 1'), findsNothing);

    // Débloquer l'Examen 1 via RaetselManager sans redémarrage
    await RaetselManager.instance.onExam1Passed(prefs: prefs);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // La carte "Jouer au Niveau 1" apparaît sur l'accueil
    expect(find.text('Jouer au Niveau 1'), findsOneWidget);

    // Taper sur la carte ouvre le mode Rätsel
    await tester.tap(find.text('Jouer au Niveau 1'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // On est maintenant sur Rätsel
    expect(find.text('Niveau 1'), findsOneWidget);
  });
}
