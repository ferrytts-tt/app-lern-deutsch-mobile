import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_lern_deutsch_mobile/domain/models/media_content.dart';
import 'package:app_lern_deutsch_mobile/features/media/data/media_repository.dart';
import 'package:app_lern_deutsch_mobile/features/media/presentation/media_player_controller.dart';
import 'package:app_lern_deutsch_mobile/features/media/presentation/widgets/synchronized_transcript_view.dart';
import 'package:app_lern_deutsch_mobile/features/media/presentation/widgets/media_player_controls.dart';

void main() {
  final sampleTranscript = MediaTranscript(
    lotId: 1,
    type: MediaType.dialogue,
    titleDe: 'Zufälliges Treffen',
    titleAr: 'لقاء بالصدفة',
    titleFr: 'Rencontre fortuite',
    lignes: const [
      TranscriptLine(
        locuteur: 'Conrad',
        de: 'Hallo Katja! Na, wie läuft\'s?',
        ar: 'أهلاً كاتيا! طيب، كيف الأحوال؟',
        fr: 'Salut Katja ! Alors, comment ça roule ?',
        debutMs: 0,
        finMs: 2500,
        phraseId: 'phrase_001',
      ),
      TranscriptLine(
        locuteur: 'Katja',
        de: 'Mensch, lange nicht gesehen!',
        ar: 'يا رجل، من زمان ما شفتك!',
        fr: 'Ça fait un bail qu\'on s\'est pas vus !',
        debutMs: 2700,
        finMs: 5200,
        phraseId: 'phrase_002',
      ),
      TranscriptLine(
        locuteur: 'Katja',
        de: 'Alles gut.',
        ar: 'كل شيء بخير.',
        fr: 'Tout va bien.',
        debutMs: 5400,
        finMs: 7000,
      ),
    ],
  );

  group('MediaPlayerController Unit Tests', () {
    test('Cycle les modes de traduction (arabe -> français -> aucune -> arabe)', () {
      final controller = MediaPlayerController(MediaRepository());

      expect(controller.state.translationMode, TranslationDisplayMode.arabe);

      controller.cycleTranslationMode();
      expect(controller.state.translationMode, TranslationDisplayMode.francais);

      controller.cycleTranslationMode();
      expect(controller.state.translationMode, TranslationDisplayMode.aucune);

      controller.cycleTranslationMode();
      expect(controller.state.translationMode, TranslationDisplayMode.arabe);

      controller.dispose();
    });

    test('Bascule de vitesse et de mode Écoute d\'abord', () async {
      final controller = MediaPlayerController(MediaRepository());

      expect(controller.state.speed, 1.0);
      await controller.toggleSpeed();
      expect(controller.state.speed, 0.75);
      await controller.toggleSpeed();
      expect(controller.state.speed, 1.0);

      expect(controller.state.isListenFirstMode, isFalse);
      controller.toggleListenFirstMode();
      expect(controller.state.isListenFirstMode, isTrue);
      expect(controller.state.isGermanRevealed, isFalse);

      controller.revealGermanText();
      expect(controller.state.isGermanRevealed, isTrue);

      controller.dispose();
    });

    test('Bascule du mode boucle', () {
      final controller = MediaPlayerController(MediaRepository());
      expect(controller.state.isLooping, isFalse);
      controller.toggleLoop();
      expect(controller.state.isLooping, isTrue);
      controller.toggleLoop();
      expect(controller.state.isLooping, isFalse);
      controller.dispose();
    });
  });

  group('SynchronizedTranscriptView Widget Tests', () {
    testWidgets('Affiche les locuteurs, surligne la ligne active et détecte le tap', (tester) async {
      int tappedIndex = -1;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SynchronizedTranscriptView(
              transcript: sampleTranscript,
              activeLineIndex: 0,
              translationMode: TranslationDisplayMode.arabe,
              isListenFirstMode: false,
              isGermanRevealed: true,
              onLineTap: (idx) => tappedIndex = idx,
              onRevealGerman: () {},
            ),
          ),
        ),
      );

      // Vérifie locuteurs
      expect(find.text('Conrad'), findsOneWidget);
      expect(find.text('Katja'), findsNWidgets(2));

      // Vérifie texte allemand et statut en cours
      expect(find.text('Hallo Katja! Na, wie läuft\'s?'), findsOneWidget);
      expect(find.text('En cours'), findsOneWidget);

      // Vérifie badge phrase du lot
      expect(find.text('Phrase du lot'), findsNWidgets(2)); // phrase_001 et phrase_002

      // Tap sur la deuxième ligne
      await tester.tap(find.text('Mensch, lange nicht gesehen!'));
      await tester.pump();
      expect(tappedIndex, 1);
    });

    testWidgets('Mode Écoute d\'abord masque le texte allemand et permet de le dévoiler', (tester) async {
      bool revealTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SynchronizedTranscriptView(
              transcript: sampleTranscript,
              activeLineIndex: 0,
              translationMode: TranslationDisplayMode.arabe,
              isListenFirstMode: true,
              isGermanRevealed: false,
              onLineTap: (_) {},
              onRevealGerman: () => revealTriggered = true,
            ),
          ),
        ),
      );

      // Le texte allemand ne doit pas être visible directement
      expect(find.text('Hallo Katja! Na, wie läuft\'s?'), findsNothing);
      expect(find.text('🎧 Écoute active... Touche pour afficher'), findsWidgets);

      // Tap sur le voile déclenche le dévoilement
      await tester.tap(find.text('🎧 Écoute active... Touche pour afficher').first);
      await tester.pump();
      expect(revealTriggered, isTrue);
    });

    testWidgets('Bascule traduction française', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SynchronizedTranscriptView(
              transcript: sampleTranscript,
              activeLineIndex: 0,
              translationMode: TranslationDisplayMode.francais,
              isListenFirstMode: false,
              isGermanRevealed: true,
              onLineTap: (_) {},
              onRevealGerman: () {},
            ),
          ),
        ),
      );

      expect(find.text('Salut Katja ! Alors, comment ça roule ?'), findsOneWidget);
      expect(find.text('Ça fait un bail qu\'on s\'est pas vus !'), findsOneWidget);
    });
  });

  group('MediaPlayerControls Widget Tests', () {
    testWidgets('Affiche les boutons de contrôle, vitesse et boucle', (tester) async {
      bool playPauseCalled = false;
      bool speedCalled = false;
      bool loopCalled = false;

      const state = MediaPlayerState(
        isPlaying: false,
        duration: Duration(seconds: 28),
        position: Duration(seconds: 10),
        speed: 1.0,
        isLooping: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaPlayerControls(
              state: state,
              onPlayPause: () => playPauseCalled = true,
              onSeek: (_) {},
              onSeekRelative: (_) {},
              onToggleSpeed: () => speedCalled = true,
              onToggleLoop: () => loopCalled = true,
              onCycleTranslation: () {},
              onToggleListenFirst: () {},
            ),
          ),
        ),
      );

      // Vérifie affichage des durées
      expect(find.text('00:10'), findsOneWidget);
      expect(find.text('00:28'), findsOneWidget);

      // Tap Play/Pause
      await tester.tap(find.byIcon(Icons.play_arrow_rounded));
      await tester.pump();
      expect(playPauseCalled, isTrue);

      // Tap Vitesse
      await tester.tap(find.text('1.0x'));
      await tester.pump();
      expect(speedCalled, isTrue);

      // Tap Boucle
      await tester.tap(find.text('Boucle'));
      await tester.pump();
      expect(loopCalled, isTrue);
    });
  });
}
