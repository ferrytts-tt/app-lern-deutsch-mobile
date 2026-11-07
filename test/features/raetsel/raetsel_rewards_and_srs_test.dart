import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_lern_deutsch_mobile/data/database/app_database.dart';
import 'package:app_lern_deutsch_mobile/domain/models/phrase.dart';
import 'package:app_lern_deutsch_mobile/domain/models/user_phrase.dart';
import 'package:app_lern_deutsch_mobile/domain/models/user_profile.dart';
import 'package:app_lern_deutsch_mobile/features/raetsel/domain/raetsel_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase appDb;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();

    AppDatabase.useInMemoryStore = true;
    appDb = AppDatabase.forTesting();
    AppDatabase.setInstanceForTesting(appDb);

    // Initialiser 5 phrases
    for (int i = 0; i < 5; i++) {
      await appDb.savePhrase(Phrase(
        id: 'phrase_$i',
        theme: 'general',
        topic: 'topic_$i',
        deStandard: 'Wort $i',
        deParle: 'Wort $i',
        de: 'Wort $i',
        fr: 'Mot $i',
      ));
      await appDb.saveProgression(UserPhrase(
        phraseId: 'phrase_$i',
        level: 1,
        dueAt: DateTime.now(),
        reps: 1,
      ));
    }
  });

  tearDown(() {
    AppDatabase.useInMemoryStore = false;
    AppDatabase.setInstanceForTesting(null);
  });

  group('Étape 5 : XP, Étoiles, Diamants et Plafond anti-abus', () {
    test('Calcul des étoiles selon indices et erreurs', () {
      // 3 étoiles : 0 indice et <= 2 erreurs
      expect(RaetselManager.calculateStars(hintsUsed: 0, mistakes: 0), 3);
      expect(RaetselManager.calculateStars(hintsUsed: 0, mistakes: 2), 3);

      // 2 étoiles : <= 2 indices ou <= 5 erreurs
      expect(RaetselManager.calculateStars(hintsUsed: 1, mistakes: 0), 2);
      expect(RaetselManager.calculateStars(hintsUsed: 2, mistakes: 3), 2);
      expect(RaetselManager.calculateStars(hintsUsed: 0, mistakes: 4), 2);

      // 1 étoile : autrement
      expect(RaetselManager.calculateStars(hintsUsed: 3, mistakes: 6), 1);
    });

    test('Calcul de l\'XP avec multiplicateur d\'étoiles', () {
      // 5 mots, 0 indice, 3 étoiles : (25 + 5*5) * 1.5 = 50 * 1.5 = 75 XP
      expect(RaetselManager.calculateTotalXp(wordsCount: 5, hintsUsed: 0, stars: 3), 75);

      // 5 mots, 0 indice, 2 étoiles : (25 + 25) * 1.2 = 60 XP
      expect(RaetselManager.calculateTotalXp(wordsCount: 5, hintsUsed: 0, stars: 2), 60);

      // 5 mots, 0 indice, 1 étoile : (25 + 25) * 1.0 = 50 XP
      expect(RaetselManager.calculateTotalXp(wordsCount: 5, hintsUsed: 0, stars: 1), 50);

      // 5 mots, 1 indice (mot avec indice = 3 XP au lieu de 5), 3 étoiles : (25 + (25 - 2)) * 1.5 = 48 * 1.5 = 72 XP
      expect(RaetselManager.calculateTotalXp(wordsCount: 5, hintsUsed: 1, stars: 3), 72);
    });

    test('Calcul des diamants : +2 de base, +4 si 3 étoiles', () {
      expect(RaetselManager.calculateDiamonds(stars: 3), 4);
      expect(RaetselManager.calculateDiamonds(stars: 2), 2);
      expect(RaetselManager.calculateDiamonds(stars: 1), 2);
    });

    test('Plafond anti-abus : après 10 niveaux, les récompenses deviennent 0', () async {
      // Jouer 10 niveaux
      for (int i = 1; i <= 10; i++) {
        final result = await RaetselManager.instance.applyLevelCompletionRewards(
          wordsCount: 5,
          hintsUsed: 0,
          mistakes: 0,
          db: appDb,
          prefs: prefs,
        );
        expect(result.isCapped, false);
        expect(result.xpAwarded, 75);
        expect(result.diamondsAwarded, 4);
      }

      // 11ème niveau le même jour : plafonné
      final result11 = await RaetselManager.instance.applyLevelCompletionRewards(
        wordsCount: 5,
        hintsUsed: 0,
        mistakes: 0,
        db: appDb,
        prefs: prefs,
      );
      expect(result11.isCapped, true);
      expect(result11.xpAwarded, 0);
      expect(result11.diamondsAwarded, 0);
    });
  });

  group('Étape 5 : Répétition espacée (SRS) et Série', () {
    test('Mot trouvé sans aide avance Leitner (+1, max 1 fois par jour)', () async {
      final initial = await appDb.getProgressionForPhrase('phrase_0');
      expect(initial!.level, 1);

      // Succès sans aide
      await RaetselManager.instance.onWordFoundSuccess(
        phraseId: 'phrase_0',
        usedHint: false,
        hadMistake: false,
        db: appDb,
        prefs: prefs,
      );

      final afterFirst = await appDb.getProgressionForPhrase('phrase_0');
      expect(afterFirst!.level, 2);

      // Deuxième fois le même jour : pas de double incrément
      await RaetselManager.instance.onWordFoundSuccess(
        phraseId: 'phrase_0',
        usedHint: false,
        hadMistake: false,
        db: appDb,
        prefs: prefs,
      );

      final afterSecond = await appDb.getProgressionForPhrase('phrase_0');
      expect(afterSecond!.level, 2);
    });

    test('Avec indice ou après erreur : aucun changement de niveau Leitner', () async {
      final initial = await appDb.getProgressionForPhrase('phrase_1');
      expect(initial!.level, 1);

      // Avec indice
      await RaetselManager.instance.onWordFoundSuccess(
        phraseId: 'phrase_1',
        usedHint: true,
        hadMistake: false,
        db: appDb,
        prefs: prefs,
      );
      expect((await appDb.getProgressionForPhrase('phrase_1'))!.level, 1);

      // Après erreur
      await RaetselManager.instance.onWordFoundSuccess(
        phraseId: 'phrase_1',
        usedHint: false,
        hadMistake: true,
        db: appDb,
        prefs: prefs,
      );
      expect((await appDb.getProgressionForPhrase('phrase_1'))!.level, 1);
    });

    test('3 erreurs au total sur une phrase -> ajout à Phrases résistantes', () async {
      final initial = await appDb.getProgressionForPhrase('phrase_2');
      expect(initial!.isDifficult, false);

      await RaetselManager.instance.onWordMistake(phraseId: 'phrase_2', db: appDb, prefs: prefs);
      expect((await appDb.getProgressionForPhrase('phrase_2'))!.isDifficult, false);

      await RaetselManager.instance.onWordMistake(phraseId: 'phrase_2', db: appDb, prefs: prefs);
      expect((await appDb.getProgressionForPhrase('phrase_2'))!.isDifficult, false);

      // 3ème erreur
      await RaetselManager.instance.onWordMistake(phraseId: 'phrase_2', db: appDb, prefs: prefs);
      expect((await appDb.getProgressionForPhrase('phrase_2'))!.isDifficult, true);
    });

    test('Trouver 3 mots ou terminer un niveau valide la série du jour', () async {
      await appDb.saveUserProfile(const UserProfile(serieJours: 3));

      await RaetselManager.instance.markDailyStreakActivity(db: appDb, prefs: prefs);

      final profile = await appDb.getUserProfile();
      expect(profile.serieJours, greaterThanOrEqualTo(3));
      final now = DateTime.now();
      expect(prefs.getBool('session_done_${now.year}_${now.month}_${now.day}'), true);
    });
  });
}
