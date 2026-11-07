import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_lern_deutsch_mobile/core/widgets/mascot_widget.dart';
import 'package:app_lern_deutsch_mobile/domain/models/phrase.dart';
import 'package:app_lern_deutsch_mobile/features/session/presentation/widgets/new_phrase_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final samplePhrase = Phrase(
    id: 'phrase_cloze_01',
    theme: 'travail',
    topic: 'bureau',
    deStandard: 'Ich bin gleich fertig.',
    deParle: 'Bin gleich durch.',
    ar: 'سأنتهي بعد قليل.',
    fr: 'J\'ai presque fini.',
  );

  setUp(() {
    MascotWidget.enableAnimations = false;
  });

  tearDown(() {
    MascotWidget.enableAnimations = true;
  });

  testWidgets('NewPhraseCard Écran 4 : Exercice Remplir les vides au clavier', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    bool validated = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: NewPhraseCard(
              phrase: samplePhrase,
              learningStep: 4,
              testSubStep: 1,
              isTtsPlaying: false,
              onPlayNormal: () {},
              onPlaySlow: () {},
              onNextStep: () {},
              onValidate: (isCorrect) {
                validated = isCorrect;
              },
            ),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 300));

    // 1. Vérification de la présence du sélecteur d'exercice
    expect(find.text('Trous clavier'), findsOneWidget);
    expect(find.text('QCM'), findsOneWidget);

    // 2. Le mode « Remplir les vides » est affiché par défaut avec 2 vides
    expect(find.text('Remplis les vides au clavier ⌨️'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('VÉRIFIER MA RÉPONSE'), findsOneWidget);

    // 3. Saisie d'une réponse incorrecte (falsch)
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'falsch1');
    await tester.enterText(fields.at(1), 'falsch2');
    await tester.tap(find.text('VÉRIFIER MA RÉPONSE'));
    await tester.pump(const Duration(milliseconds: 300));

    // L'écureuil sort maladroit (MascotMood.confused) et le message Falsch s'affiche
    expect(find.text('Réponse Falsch !'), findsOneWidget);
    expect(find.textContaining('maladroit'), findsOneWidget);
    final confusedMascotFinder = find.byWidgetPredicate(
      (widget) => widget is MascotWidget && widget.mood == MascotMood.confused,
    );
    expect(confusedMascotFinder, findsOneWidget);

    // 4. Saisie des deux bonnes réponses (« gleich » et « durch »)
    await tester.tap(find.text('Réessayer au clavier'));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(fields.at(0), 'gleich');
    await tester.enterText(fields.at(1), 'durch');
    await tester.tap(find.text('VÉRIFIER MA RÉPONSE'));
    await tester.pump(const Duration(milliseconds: 300));

    // L'écureuil sort heureux (MascotMood.happy) et la validation s'affiche
    expect(find.text('Phrase validée ! 🎉'), findsOneWidget);
    final happyMascotFinder = find.byWidgetPredicate(
      (widget) => widget is MascotWidget && widget.mood == MascotMood.happy,
    );
    expect(happyMascotFinder, findsOneWidget);

    // 5. Clic sur Valider et continuer
    expect(find.text('VALIDER ET CONTINUER'), findsOneWidget);
    await tester.tap(find.text('VALIDER ET CONTINUER'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(validated, isTrue);
  });
}
