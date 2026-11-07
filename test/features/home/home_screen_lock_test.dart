import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_lern_deutsch_mobile/core/services/tts_service.dart';
import 'package:app_lern_deutsch_mobile/core/widgets/duo_streak_widget.dart';
import 'package:app_lern_deutsch_mobile/core/widgets/mascot_widget.dart';
import 'package:app_lern_deutsch_mobile/data/database/app_database.dart';
import 'package:app_lern_deutsch_mobile/domain/models/phrase.dart';
import 'package:app_lern_deutsch_mobile/domain/models/user_phrase.dart';
import 'package:app_lern_deutsch_mobile/features/home/presentation/home_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase appDb;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    MascotWidget.enableAnimations = false;
    DuoStreakWidget.enableAnimations = false;
    TtsService.instance.onSpeakForTesting = (text, {bool slow = false, double? rate}) {};

    AppDatabase.useInMemoryStore = true;
    appDb = AppDatabase.forTesting();
    AppDatabase.setInstanceForTesting(appDb);

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
    AppDatabase.useInMemoryStore = false;
    AppDatabase.setInstanceForTesting(null);
  });

  testWidgets('Au démarrage (0 phrase apprise), le Lot 1 est prêt et le Palier 1 affiche la jauge', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Vérifie que le bouton pour commencer le Lot 1 est disponible
    expect(find.text('🚀 COMMENCER LE LOT 1'), findsOneWidget);

    // Vérifie la présence de la carte d'Examen de Palier
    expect(find.textContaining('PALIER 1'), findsOneWidget);
  });

  testWidgets('Progression partielle : affiche le bouton Continuer le Lot', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;

    for (int i = 0; i < 4; i++) {
      await appDb.saveProgression(UserPhrase(
        userId: 'default_user',
        phraseId: 'p$i',
        level: 1,
        reps: 1,
        dueAt: DateTime.now().add(const Duration(days: 1)),
      ));
    }

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('▶️ CONTINUER LE LOT 1 (4/10)'), findsOneWidget);
  });
}
