import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_lern_deutsch_mobile/core/widgets/mascot_widget.dart';
import 'package:app_lern_deutsch_mobile/data/database/app_database.dart';
import 'package:app_lern_deutsch_mobile/domain/models/phrase.dart';
import 'package:app_lern_deutsch_mobile/domain/models/user_phrase.dart';
import 'package:app_lern_deutsch_mobile/domain/models/user_profile.dart';
import 'package:app_lern_deutsch_mobile/features/library/presentation/library_controller.dart';
import 'package:app_lern_deutsch_mobile/features/library/presentation/library_screen.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    MascotWidget.enableAnimations = false;
    AppDatabase.useInMemoryStore = true;
  });

  tearDown(() {
    MascotWidget.enableAnimations = true;
    AppDatabase.useInMemoryStore = false;
  });

  final testPhrases = [
    const Phrase(
      id: 'p1',
      theme: 'smalltalk',
      topic: 'smalltalk',
      deStandard: 'Wie geht es dir?',
      deParle: 'Na, wie läuft\'s?',
      de: 'Na, wie läuft\'s?',
      fr: 'Comment ça va ?',
      ar: 'كيف الأحوال؟',
      note: 'Salutation décontractée typique.',
      cefr: 'B1',
    ),
    const Phrase(
      id: 'p2',
      theme: 'travail',
      topic: 'travail',
      deStandard: 'Ich habe viel zu tun.',
      deParle: 'Hab voll viel zu tun.',
      de: 'Hab voll viel zu tun.',
      fr: 'J\'ai énormément de boulot.',
      ar: 'عندي شغل كتير فوق راسي.',
      note: 'voll = très/beaucoup en allemand parlé.',
      cefr: 'B2',
    ),
    const Phrase(
      id: 'p3',
      theme: 'administration',
      topic: 'administration',
      deStandard: 'Geben Sie mir bitte Bescheid.',
      deParle: 'Sag mir einfach Bescheid.',
      de: 'Sag mir einfach Bescheid.',
      fr: 'Fais-moi signe / tiens-moi au courant.',
      ar: 'خليني على علم.',
      note: 'Bescheid sagen = informer/tenir au courant.',
      cefr: 'B2',
    ),
    const Phrase(
      id: 'p4',
      theme: 'sante',
      topic: 'sante',
      deStandard: 'Gute Besserung!',
      deParle: 'Werd schnell wieder fit!',
      de: 'Werd schnell wieder fit!',
      fr: 'Rétablis-toi vite !',
      ar: 'بالشفاء العاجل!',
      note: 'wieder fit werden = redevenir en forme.',
      cefr: 'B1',
    ),
  ];

  group('Étape 6 : Bibliothèque et thèmes (Workflow Plan)', () {
    test('1. Recherche multilingue : Allemand parlé, standard, arabe, français', () {
      final state = LibraryState(
        allPhrases: testPhrases,
        userProgress: const {},
        searchQuery: '',
        selectedStatusFilter: 'all',
      );

      // Recherche par forme parlée
      final searchSpoken = state.copyWith(searchQuery: 'läuft\'s');
      expect(searchSpoken.filteredPhrases.length, 1);
      expect(searchSpoken.filteredPhrases.first.id, 'p1');

      // Recherche par forme standard
      final searchStandard = state.copyWith(searchQuery: 'Wie geht es');
      expect(searchStandard.filteredPhrases.length, 1);
      expect(searchStandard.filteredPhrases.first.id, 'p1');

      // Recherche en arabe
      final searchArabic = state.copyWith(searchQuery: 'شغل كتير');
      expect(searchArabic.filteredPhrases.length, 1);
      expect(searchArabic.filteredPhrases.first.id, 'p2');

      // Recherche en français
      final searchFrench = state.copyWith(searchQuery: 'tiens-moi au courant');
      expect(searchFrench.filteredPhrases.length, 1);
      expect(searchFrench.filteredPhrases.first.id, 'p3');
    });

    test('2. Filtres par statut SRS (Section 4 & 6 du plan)', () {
      final now = DateTime.now();
      final progressMap = {
        // p1: Fragile / En cours (niveau 1)
        'p1': UserPhrase(phraseId: 'p1', level: 1, reps: 1, dueAt: now.add(const Duration(days: 1))),
        // p2: Solide (niveau 4)
        'p2': UserPhrase(phraseId: 'p2', level: 4, reps: 4, dueAt: now.add(const Duration(days: 7))),
        // p3: Acquise / Maîtrisée (niveau 7)
        'p3': UserPhrase(phraseId: 'p3', level: 7, reps: 7, dueAt: now.add(const Duration(days: 90))),
        // p4: Difficile (4 erreurs)
        'p4': UserPhrase(phraseId: 'p4', level: 1, reps: 2, lapses: 4, isDifficult: true, dueAt: now),
      };

      final state = LibraryState(
        allPhrases: testPhrases,
        userProgress: progressMap,
      );

      // Filtre 'in_progress' (niveaux 1 à 3)
      final inProgress = state.copyWith(selectedStatusFilter: 'in_progress');
      expect(inProgress.filteredPhrases.map((p) => p.id), contains('p1'));
      expect(inProgress.filteredPhrases.map((p) => p.id), isNot(contains('p2')));

      // Filtre 'solid' (niveaux 4 à 6)
      final solid = state.copyWith(selectedStatusFilter: 'solid');
      expect(solid.filteredPhrases.map((p) => p.id), contains('p2'));

      // Filtre 'mastered' (niveau 7)
      final mastered = state.copyWith(selectedStatusFilter: 'mastered');
      expect(mastered.filteredPhrases.map((p) => p.id), contains('p3'));

      // Filtre 'difficult'
      final difficult = state.copyWith(selectedStatusFilter: 'difficult');
      expect(difficult.filteredPhrases.map((p) => p.id), contains('p4'));
    });

    test('3. Déblocage doux des thèmes et thèmes prioritaires', () {
      // Déclarer 'travail' comme thème prioritaire (normalement verrouillé à l'index 9)
      const profile = UserProfile(
        id: 'user_1',
        themesPrioritaires: ['travail'],
      );

      final state = LibraryState(
        allPhrases: testPhrases,
        userProfile: profile,
      );

      final stats = state.topicStatsList;
      // Les 3 premiers thèmes sont toujours débloqués
      expect(stats[0].isUnlocked, isTrue);
      expect(stats[1].isUnlocked, isTrue);
      expect(stats[2].isUnlocked, isTrue);

      // Le thème prioritaire 'travail' (index 9) est débloqué grâce au profil utilisateur
      final travailTopic = stats.firstWhere((s) => s.topic.id == 'travail');
      expect(travailTopic.isUnlocked, isTrue);
    });

    test('4. Règle 4 : Marquer comme connue (« Trop facile ») saute au niveau 4 avec délai 7 jours', () async {
      final db = AppDatabase.instance;
      final phrase = testPhrases.first;
      await db.saveUserProfileAndDemoPhrases(
        profile: const UserProfile(id: 'test_user'),
        demoPhrases: [phrase],
      );

      final initialProgress = await db.getAllProgression();
      expect(initialProgress[phrase.id]?.level, 1);

      // Création du contrôleur
      final controller = LibraryController();
      await controller.loadData();

      // Marquer connue
      await controller.markPhraseAsKnown(phrase.id);

      final updatedProgress = await db.getAllProgression();
      final updatedPhrase = updatedProgress[phrase.id];

      expect(updatedPhrase, isNotNull);
      expect(updatedPhrase!.level, 4); // Règle 4 : saute au niveau 4 (jamais 7)
      expect(updatedPhrase.status, UserPhraseStatus.assezSolide);

      // Vérifier le délai de 7 jours
      final daysDiff = updatedPhrase.dueAt.difference(DateTime.now()).inDays;
      expect(daysDiff, inInclusiveRange(6, 7));
    });

    testWidgets('5. Rendu de l\'écran LibraryScreen avec mascotte et liste des thèmes', (tester) async {
      final db = AppDatabase.instance;
      for (final p in testPhrases) {
        await db.savePhrase(p);
      }

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LibraryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Vérifier le titre
      expect(find.text('Mes Phrases'), findsOneWidget);

      // Vérifier la présence de la barre de recherche
      expect(find.byType(TextField), findsOneWidget);

      // Vérifier les filtres par statut
      expect(find.text('Toutes'), findsOneWidget);
      expect(find.text('Nouvelles (Niv. 0)'), findsOneWidget);
      expect(find.text('En cours (Niv. 1-3)'), findsOneWidget);
      expect(find.text('Solides (Niv. 4-6)'), findsOneWidget);
      expect(find.text('Acquises (Niv. 7)'), findsOneWidget);
      expect(find.text('Difficiles ⚠️'), findsOneWidget);

      // Vérifier la présence de la mascotte écureuil
      expect(find.byType(MascotWidget), findsOneWidget);
    });
  });
}
