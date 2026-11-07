import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:app_lern_deutsch_mobile/data/database/app_database.dart';
import 'package:app_lern_deutsch_mobile/data/repositories/phrase_repository.dart';
import 'package:app_lern_deutsch_mobile/domain/models/user_phrase.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Initialisation FFI pour tests SQLite natifs en mémoire
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database sqliteDb;
  late AppDatabase appDb;
  late PhraseRepository repository;
  late String realPhrasesJson;

  setUpAll(() {
    // Lire le lot réel de 100 phrases depuis les assets
    final file = File('assets/data/phrases.json');
    expect(file.existsSync(), isTrue, reason: 'assets/data/phrases.json doit exister');
    realPhrasesJson = file.readAsStringSync();
  });

  setUp(() async {
    // Ouvrir une base SQLite neuve en mémoire pour chaque test
    sqliteDb = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    appDb = AppDatabase.forTesting(testDb: sqliteDb);
    await appDb.createSchema(sqliteDb);
    repository = PhraseRepository(database: appDb);
  });

  tearDown(() async {
    await sqliteDb.close();
  });

  group('Étape 1 : Base de données & Déduplication (SQLite FFI)', () {
    test('Critère de validation : les phrases s\'importent et un second import ne crée aucun doublon', () async {
      final expectedTotal = (jsonDecode(realPhrasesJson) as List).length;
      // 1. Premier import du lot de phrases
      final countFirstImport = await repository.importBatch(jsonContent: realPhrasesJson);
      expect(countFirstImport, equals(expectedTotal), reason: 'Le premier import doit charger toutes les phrases');

      final totalInDbAfterFirst = await repository.countPhrases();
      expect(totalInDbAfterFirst, equals(expectedTotal), reason: 'La table phrases doit contenir exactement toutes les entrées');

      final allPhrases = await repository.getAllPhrases();
      expect(allPhrases.length, equals(expectedTotal));

      // Vérifier la conformité des champs d'une phrase importée
      final sample = allPhrases.firstWhere((p) => p.id == 'phrase_001');
      expect(sample.deStandard, equals('Wie geht es dir?'));
      expect(sample.deParle, equals('Na, wie läuft\'s?'));
      expect(sample.theme, isNotEmpty);
      expect(sample.ar, isNotNull);
      expect(sample.note, isNotNull);

      // 2. Second import du MÊME lot de phrases
      final countSecondImport = await repository.importBatch(jsonContent: realPhrasesJson);
      expect(countSecondImport, equals(0), reason: 'Le second import doit ignorer tous les doublons et retourner 0');

      final totalInDbAfterSecond = await repository.countPhrases();
      expect(totalInDbAfterSecond, equals(expectedTotal), reason: 'Le total doit rester strictement au même nombre (zéro doublon)');
    });

    test('Déduplication basée sur de_standard (clé anti-doublon même avec ID différent)', () async {
      await repository.importBatch(jsonContent: realPhrasesJson);

      // Création d'un mini-lot contenant :
      // - 1 doublon avec ID différent mais même de_standard ("Wie geht es dir?")
      // - 1 nouvelle phrase inédite
      final customBatch = jsonEncode([
        {
          "id": "phrase_duplicate_with_new_id",
          "theme": "smalltalk",
          "de_standard": "wie geht es dir?", // casse minuscule
          "de_parle": "Na, was geht?",
          "ar": "كيف الحال؟",
          "note": "Doublon de Wie geht es dir?",
          "cefr": "B1"
        },
        {
          "id": "phrase_brand_new_101",
          "theme": "travail",
          "de_standard": "Können wir das kurz besprechen?",
          "de_parle": "Könn' wir das kurz bequatschen?",
          "ar": "ممكن ندردش بالموضوع بسرعة؟",
          "note": "bequatschen = besprechen",
          "cefr": "B2"
        }
      ]);

      final inserted = await repository.importBatch(jsonContent: customBatch);
      expect(inserted, equals(1), reason: 'Seule la phrase inédite doit être insérée');

      final expectedTotal = (jsonDecode(realPhrasesJson) as List).length;
      final total = await repository.countPhrases();
      expect(total, equals(expectedTotal + 1));

      final newPhrase = await repository.getPhraseById('phrase_brand_new_101');
      expect(newPhrase, isNotNull);
      expect(newPhrase!.deStandard, equals('Können wir das kurz besprechen?'));
      expect(newPhrase.deParle, equals('Könn\' wir das kurz bequatschen?'));
    });

    test('La table progression ne doit JAMAIS être écrasée par un nouvel import', () async {
      // 1. Importer les 100 phrases
      await repository.importBatch(jsonContent: realPhrasesJson);

      // 2. Créer une progression utilisateur sur phrase_001
      final now = DateTime.now();
      final userPhrase = UserPhrase(
        userId: 'candidate_telc_b2',
        phraseId: 'phrase_001',
        level: 3,
        dueAt: now.add(const Duration(days: 4)),
        reps: 5,
        lapses: 1,
        lastReviewedAt: now,
        isDifficult: false,
      );

      await repository.saveProgression(userPhrase, userId: 'candidate_telc_b2');

      // 3. Ré-exécuter un import complet de lot
      await repository.importBatch(jsonContent: realPhrasesJson);

      // 4. Vérifier que la progression est intacte
      final progressionMap = await repository.getAllProgression(userId: 'candidate_telc_b2');
      expect(progressionMap.containsKey('phrase_001'), isTrue);

      final retrieved = progressionMap['phrase_001']!;
      expect(retrieved.level, equals(3));
      expect(retrieved.reps, equals(5));
      expect(retrieved.lapses, equals(1));
      expect(retrieved.userId, equals('candidate_telc_b2'));
    });

    test('Table utilisateur : enregistrement et récupération des préférences', () async {
      final defaultProfile = await repository.getUserProfile(userId: 'user_123');
      expect(defaultProfile.langueTraduction, equals('ar'));
      expect(defaultProfile.objectifQuotidien, equals(10));
      expect(defaultProfile.niveauDeclare, equals('B2'));
      expect(defaultProfile.heureRappel, equals('19:00'));
      expect(defaultProfile.serieJours, equals(0));
      expect(defaultProfile.gelSerieDisponible, isTrue);

      // Mise à jour du profil
      final updatedProfile = defaultProfile.copyWith(
        langueTraduction: 'fr',
        objectifQuotidien: 20,
        themesPrioritaires: ['travail', 'sante', 'administration'],
        niveauDeclare: 'B2 telc',
        heureRappel: '20:30',
        serieJours: 5,
      );

      await repository.saveUserProfile(updatedProfile);

      final reloaded = await repository.getUserProfile(userId: 'user_123');
      expect(reloaded.langueTraduction, equals('fr'));
      expect(reloaded.objectifQuotidien, equals(20));
      expect(reloaded.themesPrioritaires, equals(['travail', 'sante', 'administration']));
      expect(reloaded.niveauDeclare, equals('B2 telc'));
      expect(reloaded.heureRappel, equals('20:30'));
      expect(reloaded.serieJours, equals(5));
    });
  });
}
