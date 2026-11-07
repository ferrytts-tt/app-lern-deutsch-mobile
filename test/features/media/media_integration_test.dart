import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_lern_deutsch_mobile/domain/models/media_content.dart';
import 'package:app_lern_deutsch_mobile/domain/models/phrase.dart';
import 'package:app_lern_deutsch_mobile/domain/models/user_phrase.dart';
import 'package:app_lern_deutsch_mobile/data/database/app_database.dart';
import 'package:app_lern_deutsch_mobile/features/media/domain/media_unlock_manager.dart';
import 'package:app_lern_deutsch_mobile/features/media/presentation/media_section_screen.dart';
import 'package:app_lern_deutsch_mobile/features/library/presentation/library_screen.dart';
import 'package:app_lern_deutsch_mobile/features/home/presentation/home_screen.dart';

import 'package:app_lern_deutsch_mobile/core/widgets/mascot_widget.dart';

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

  group('Étape 3 : Tests d\'Intégration Chansons & Dialogues', () {
    test('1. MediaUnlockManager : règles de déblocage et écoute auto', () async {
      final prefs = await SharedPreferences.getInstance();

      // Au départ, le lot 1 n'est pas explicitement débloqué
      final isUnlockedInitial = MediaUnlockManager.isLotUnlocked(
        lotId: 1,
        progress: {},
        lotPhraseIds: ['phrase_001', 'phrase_002'],
        maxUnlockedBatchIndex: 0,
        prefs: prefs,
      );
      expect(isUnlockedInitial, isFalse);

      // Si le candidat a terminé le lot 1 (toutes les phrases ont level > 0)
      final now = DateTime.now();
      final Map<String, UserPhrase> progressMap = {
        'phrase_001': UserPhrase(phraseId: 'phrase_001', level: 1, dueAt: now),
        'phrase_002': UserPhrase(phraseId: 'phrase_002', level: 2, dueAt: now),
      };
      final isUnlockedCompleted = MediaUnlockManager.isLotUnlocked(
        lotId: 1,
        progress: progressMap,
        lotPhraseIds: ['phrase_001', 'phrase_002'],
        maxUnlockedBatchIndex: 0,
        prefs: prefs,
      );
      expect(isUnlockedCompleted, isTrue);

      // Déblocage explicite via unlockLot
      await MediaUnlockManager.unlockLot(1, prefs: prefs);
      expect(MediaUnlockManager.isLotUnlocked(lotId: 1, prefs: prefs), isTrue);

      // Gestion de l'Écoute auto 🎧
      expect(await MediaUnlockManager.isDialogueInAutoListening(1, prefs: prefs), isFalse);
      final toggledOn = await MediaUnlockManager.toggleDialogueInAutoListening(1, prefs: prefs);
      expect(toggledOn, isTrue);
      expect(await MediaUnlockManager.isDialogueInAutoListening(1, prefs: prefs), isTrue);

      final toggledOff = await MediaUnlockManager.toggleDialogueInAutoListening(1, prefs: prefs);
      expect(toggledOff, isFalse);
      expect(await MediaUnlockManager.isDialogueInAutoListening(1, prefs: prefs), isFalse);
    });

    test('2. MediaUnlockManager : suivi d\'écoute d\'un contenu', () async {
      final prefs = await SharedPreferences.getInstance();

      expect(await MediaUnlockManager.isMediaPlayed(1, MediaType.dialogue, prefs: prefs), isFalse);
      await MediaUnlockManager.markMediaPlayed(1, MediaType.dialogue, prefs: prefs);
      expect(await MediaUnlockManager.isMediaPlayed(1, MediaType.dialogue, prefs: prefs), isTrue);
      expect(await MediaUnlockManager.isMediaPlayed(1, MediaType.chanson, prefs: prefs), isFalse);
    });

    testWidgets('3. MediaSectionScreen : affichage et présence des composants', (tester) async {
      final prefs = await SharedPreferences.getInstance();
      await MediaUnlockManager.unlockLot(1, prefs: prefs);

      final db = AppDatabase.instance;
      await db.savePhrase(const Phrase(
        id: 'phrase_001',
        de: 'Hallo!',
        ar: 'أهلاً',
        fr: 'Salut !',
      ));

      const testManifest = MediaManifest(
        version: 1,
        updatedAt: '2026-11-01',
        contents: [
          MediaItem(
            lotId: 1,
            type: MediaType.dialogue,
            audioFile: 'lot_001_dialogue.mp3',
            contentJsonFile: 'lot_001_dialogue.json',
            durationSeconds: 28,
            sizeBytes: 446607,
            checksum: 'abc',
            version: 1,
            statutLicence: MediaLicenseStatus.approuve,
            source: 'test',
            createdAt: '2026-11-01',
          ),
          MediaItem(
            lotId: 1,
            type: MediaType.chanson,
            audioFile: 'lot_001_chanson.mp3',
            contentJsonFile: 'lot_001_chanson.json',
            durationSeconds: 20,
            sizeBytes: 319005,
            checksum: 'def',
            version: 1,
            statutLicence: MediaLicenseStatus.approuve,
            source: 'test',
            createdAt: '2026-11-01',
          ),
        ],
      );

      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: MediaSectionScreen(initialManifest: testManifest),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      // Vérifier le titre AppBar
      expect(find.text('Chansons & Dialogues'), findsWidgets);
      // Vérifier la présence des contenus du lot 1 et lot 2 débloqués
      expect(find.textContaining(RegExp(r'lot 1', caseSensitive: false)), findsWidgets);
      expect(find.textContaining(RegExp(r'lot 2', caseSensitive: false)), findsWidgets);
    });

    testWidgets('4. LibraryScreen : affiche directement la rubrique Chansons & Dialogues dédiée', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LibraryScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Vérifier que l'écran Chansons & Dialogues est affiché directement
      expect(find.text('Chansons & Dialogues'), findsWidgets);
      expect(find.textContaining(RegExp(r'lot 1', caseSensitive: false)), findsWidgets);
    });

    testWidgets('5. HomeScreen : absence de Chansons & Dialogues (réservé à l\'onglet dédié)', (tester) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('current_batch_index', 0);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      // Vérifier que Chansons & Dialogues n'est PAS affiché sur l'accueil
      expect(find.text('Chansons & Dialogues'), findsNothing);
    });
  });
}
