import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_lern_deutsch_mobile/core/constants/app_constants.dart';
import 'package:app_lern_deutsch_mobile/core/services/tts_service.dart';
import 'package:app_lern_deutsch_mobile/core/widgets/duo_button.dart';
import 'package:app_lern_deutsch_mobile/core/widgets/duo_confetti.dart';
import 'package:app_lern_deutsch_mobile/core/widgets/mascot_widget.dart';
import 'package:app_lern_deutsch_mobile/data/database/app_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_lern_deutsch_mobile/features/onboarding/presentation/onboarding_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase appDb;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    TtsService.instance.onSpeakForTesting = (text, {bool slow = false, double? rate}) {};
    MascotWidget.enableAnimations = false;
    DuoConfettiOverlay.enableAnimations = false;

    AppDatabase.useInMemoryStore = true;
    appDb = AppDatabase.forTesting();
    AppDatabase.setInstanceForTesting(appDb);
  });

  tearDown(() async {
    MascotWidget.enableAnimations = true;
    DuoConfettiOverlay.enableAnimations = true;
    AppDatabase.useInMemoryStore = false;
    AppDatabase.setInstanceForTesting(null);
  });

  group('Étape 5 : Parcours d\'entrée (Onboarding) — Section 2 du plan', () {
    testWidgets('Critère de validation : Déroulement complet des 8 étapes et mini-démo de 3 phrases', (tester) async {
      tester.view.physicalSize = const Size(600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: OnboardingScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // ── 1. Écran d'accueil (Section 2.1) ──────────────────────────────────
      expect(find.text('Comprends l\'allemand que les Allemands parlent vraiment 🇩🇪'), findsOneWidget);
      expect(find.text('COMMENCER'), findsOneWidget);
      await tester.tap(find.text('COMMENCER'));
      await tester.pumpAndSettle();

      // ── 2. Choix de la langue de traduction (Section 2.2) ────────────────
      expect(find.textContaining('Langue principale'), findsOneWidget);
      expect(find.textContaining('العربية (Arabe)'), findsWidgets);
      // Sélectionner l'arabe pour correspondre aux réponses de démo attendues
      await tester.tap(find.textContaining('العربية (Arabe)').first);
      await tester.pumpAndSettle();
      final step2Scroll1 = find.byType(SingleChildScrollView).first;
      final continuerInStep21 = find.descendant(of: step2Scroll1, matching: find.text('CONTINUER'));
      await tester.dragUntilVisible(continuerInStep21, step2Scroll1, const Offset(0, -300));
      await tester.pumpAndSettle();
      await tester.tap(continuerInStep21);
      await tester.pumpAndSettle();

      // ── 3. Choix de l'objectif quotidien (Section 2.4) ────────────────────
      expect(find.text('Choix de l\'objectif quotidien'), findsOneWidget);
      expect(find.text('Normal (10 phrases)'), findsOneWidget);
      await tester.tap(find.text('CONTINUER'));
      await tester.pumpAndSettle();

      // ── 5. Choix des thèmes prioritaires (Section 2.5) ───────────────────
      expect(find.text('Thèmes prioritaires'), findsOneWidget);
      expect(find.text('PASSER À LA MINI-DÉMO'), findsOneWidget);
      await tester.tap(find.text('PASSER À LA MINI-DÉMO'));
      await tester.pumpAndSettle();

      // ── 6. Mini-démo de 3 phrases (Section 2.6) ───────────────────────────
      // Phrase 1 : Na, wie läuft's?
      expect(find.text('Démo : Phrase 1 sur 3'), findsOneWidget);
      expect(find.text('Na, wie läuft\'s?'), findsOneWidget);
      // Choisir la bonne réponse en arabe
      await tester.tap(find.text('طيب، كيف الأحوال؟'));
      await tester.pumpAndSettle();
      expect(find.text('PHRASE SUIVANTE'), findsOneWidget);
      await tester.tap(find.text('PHRASE SUIVANTE'));
      await tester.pumpAndSettle();

      // Phrase 2 : Mensch, lange nicht gesehen!
      expect(find.text('Démo : Phrase 2 sur 3'), findsOneWidget);
      expect(find.text('Mensch, lange nicht gesehen!'), findsOneWidget);
      await tester.tap(find.text('يا رجل، من زمان ما شفتك!'));
      await tester.pumpAndSettle();
      expect(find.text('PHRASE SUIVANTE'), findsOneWidget);
      await tester.tap(find.text('PHRASE SUIVANTE'));
      await tester.pumpAndSettle();

      // Phrase 3 : Was gibt's Neues?
      expect(find.text('Démo : Phrase 3 sur 3'), findsOneWidget);
      expect(find.text('Was gibt\'s Neues?'), findsOneWidget);
      await tester.tap(find.text('شو الجديد؟'));
      await tester.pumpAndSettle();
      expect(find.text('TERMINER LA DÉMO'), findsOneWidget);
      await tester.tap(find.text('TERMINER LA DÉMO'));
      await tester.pumpAndSettle();

      // Victoire et félicitations après les 3 phrases
      expect(find.text('Bravo ! 🎉'), findsOneWidget);
      expect(find.text('SAUVEGARDER MA PROGRESSION'), findsOneWidget);
      await tester.tap(find.text('SAUVEGARDER MA PROGRESSION'));
      await tester.pumpAndSettle();

      // ── 7. Création du compte (Section 2.7) ───────────────────────────────
      expect(find.text('Sauvegarde ta progression'), findsOneWidget);
      expect(find.text('Continuer en invité (local uniquement)'), findsOneWidget);
      await tester.tap(find.text('Continuer en invité (local uniquement)'));
      await tester.pumpAndSettle();

      // ── 8. Rappels quotidiens (Section 2.8) ───────────────────────────────
      expect(find.text('Reste régulier'), findsOneWidget);
      expect(find.text('ACTIVER LE RAPPEL QUOTIDIEN'), findsOneWidget);
      await tester.tap(find.text('ACTIVER LE RAPPEL QUOTIDIEN'));
      await tester.pumpAndSettle();

      // ── Vérification de la persistance (Critère Étape 5) ─────────────────
      // 1. Profil utilisateur : Réglages enregistrés
      final user = await appDb.getUserProfile();
      expect(user.langueTraduction, equals('ar'));
      expect(user.objectifQuotidien, equals(10));
      expect(user.niveauDeclare, equals('B2'));
      expect(user.heureRappel, equals('19:00'));

      // 2. Progression : Les 3 phrases de la démo sont ajoutées à la file de révision
      final progressMap = await appDb.getAllProgression();
      expect(progressMap.length, equals(3));
      expect(progressMap.keys, containsAll(['phrase_001', 'phrase_002', 'phrase_003']));

      // Vérifier que chaque phrase est bien au niveau 1 avec 1 bonne réponse
      for (final p in progressMap.values) {
        expect(p.level, equals(1));
        expect(p.reps, equals(1));
        expect(p.dueAt, isNotNull);
      }

      // 3. SharedPreferences : Onboarding marqué comme complété
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(AppConstants.prefHasCompletedOnboarding), isTrue);
    });

    testWidgets('Choix de la langue française et sauvegarde correspondante', (tester) async {
      tester.view.physicalSize = const Size(600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: OnboardingScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Écran 1
      await tester.tap(find.text('COMMENCER'));
      await tester.pumpAndSettle();

      // Écran 2 : Choisir le Français
      await tester.tap(find.textContaining('Français').first);
      await tester.pumpAndSettle();
      final step2Scroll2 = find.byType(SingleChildScrollView).first;
      final continuerInStep22 = find.descendant(of: step2Scroll2, matching: find.text('CONTINUER'));
      await tester.dragUntilVisible(continuerInStep22, step2Scroll2, const Offset(0, -300));
      await tester.pumpAndSettle();
      await tester.tap(continuerInStep22);
      await tester.pumpAndSettle();

      // Écran 3 : Choisir Léger (5 phrases)
      expect(find.text('Choix de l\'objectif quotidien'), findsOneWidget);
      expect(find.text('Léger (5 phrases)').hitTestable(), findsOneWidget);
      await tester.tap(find.text('Léger (5 phrases)').hitTestable());
      await tester.pumpAndSettle();
      await tester.tap(find.text('CONTINUER').hitTestable());
      await tester.pumpAndSettle();

      // Écran 4 : Passer à la démo
      await tester.tap(find.text('PASSER À LA MINI-DÉMO'));
      await tester.pumpAndSettle();

      // Démo en Français : Phrase 1
      expect(find.text('Comment ça va ?'), findsOneWidget);
      await tester.tap(find.text('Comment ça va ?'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('PHRASE SUIVANTE'));
      await tester.pumpAndSettle();

      // Phrase 2
      await tester.tap(find.text('Ça fait un bail qu\'on s\'est pas vus !'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('PHRASE SUIVANTE'));
      await tester.pumpAndSettle();

      // Phrase 3
      await tester.tap(find.text('Quoi de neuf ?'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('TERMINER LA DÉMO'));
      await tester.pumpAndSettle();

      // Sauvegarde
      await tester.tap(find.text('SAUVEGARDER MA PROGRESSION'));
      await tester.pumpAndSettle();

      // Compte invité
      await tester.tap(find.text('Continuer en invité (local uniquement)'));
      await tester.pumpAndSettle();

      // Rappel à 21:00
      await tester.tap(find.text('21:00'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ACTIVER LE RAPPEL QUOTIDIEN'));
      await tester.pumpAndSettle();

      // Vérifier enregistrement avec langue française et objectif 5
      final user = await appDb.getUserProfile();
      expect(user.langueTraduction, equals('fr'));
      expect(user.objectifQuotidien, equals(5));
      expect(user.niveauDeclare, equals('B2'));
      expect(user.heureRappel, equals('21:00'));
    });
  });
}
