import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_lern_deutsch_mobile/core/widgets/duo_button.dart';
import 'package:app_lern_deutsch_mobile/core/widgets/duo_confetti.dart';
import 'package:app_lern_deutsch_mobile/core/widgets/duo_streak_widget.dart';
import 'package:app_lern_deutsch_mobile/core/widgets/mascot_widget.dart';

void main() {
  group('Duolingo Animation & UI Components Tests', () {
    testWidgets('DuoButton s\'affiche et réagit au clic', (tester) async {
      bool clicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DuoButton(
              label: 'Continuer',
              onPressed: () => clicked = true,
            ),
          ),
        ),
      );

      expect(find.text('CONTINUER'), findsOneWidget);

      await tester.tap(find.byType(DuoButton));
      await tester.pumpAndSettle();

      expect(clicked, isTrue);
    });

    testWidgets('MascotWidget s\'affiche correctement dans ses différents états', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                MascotWidget(mood: MascotMood.idle, size: 80, animate: false),
                MascotWidget(mood: MascotMood.happy, size: 80, animate: false),
                MascotWidget(mood: MascotMood.sad, size: 80, animate: false),
                MascotWidget(mood: MascotMood.celebrating, size: 80, animate: false),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(MascotWidget), findsNWidgets(4));
    });

    testWidgets('DuoStreakWidget affiche la série et la flamme', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DuoStreakWidget(
              streakDays: 14,
              isCompact: true,
              animate: false,
            ),
          ),
        ),
      );

      expect(find.text('14'), findsOneWidget);
      expect(find.byIcon(Icons.local_fire_department_rounded), findsOneWidget);
    });

    testWidgets('DuoConfettiOverlay enveloppe le contenu sans bloquer le rendu', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DuoConfettiOverlay(
              isPlaying: false,
              child: Text('Contenu protégé'),
            ),
          ),
        ),
      );

      expect(find.text('Contenu protégé'), findsOneWidget);
      expect(find.byType(DuoConfettiOverlay), findsOneWidget);
    });
  });
}
