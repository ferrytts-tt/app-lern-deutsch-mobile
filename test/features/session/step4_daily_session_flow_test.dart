import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:app_lern_deutsch_mobile/core/services/tts_service.dart';
import 'package:app_lern_deutsch_mobile/data/database/app_database.dart';
import 'package:app_lern_deutsch_mobile/domain/engine/srs_engine.dart';
import 'package:app_lern_deutsch_mobile/domain/models/phrase.dart';
import 'package:app_lern_deutsch_mobile/domain/models/user_phrase.dart';
import 'package:app_lern_deutsch_mobile/domain/models/user_profile.dart';
import 'package:app_lern_deutsch_mobile/features/session/presentation/session_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database inMemoryDb;
  late AppDatabase appDb;

  final samplePhrases = [
    Phrase(
      id: 'rev_01',
      theme: 'smalltalk',
      topic: 'salutations',
      deStandard: 'Wie geht es dir?',
      deParle: 'Na, wie läuft\'s?',
      ar: 'كيف الأحوال؟',
      fr: 'Comment ça va ?',
      note: 'Na ouvre la conversation.',
    ),
    Phrase(
      id: 'new_01',
      theme: 'travail',
      topic: 'bureau',
      deStandard: 'Ich bin gleich fertig.',
      deParle: 'Bin gleich durch.',
      ar: 'سأنتهي بعد قليل.',
      fr: 'J\'ai presque fini.',
      note: 'durch sein = avoir fini.',
    ),
    Phrase(
      id: 'new_02',
      theme: 'travail',
      topic: 'collegues',
      deStandard: 'Hast du kurz Zeit?',
      deParle: 'Haste kurz Zeit?',
      ar: 'هل عندك دقيقة؟',
      fr: 'Tu as une minute ?',
      note: 'Haste = Hast du.',
    ),
    Phrase(
      id: 'extra_01',
      theme: 'travail',
      topic: 'bureau',
      deStandard: 'Können wir das verschieben?',
      deParle: 'Könn\'wa das schieben?',
      ar: 'هل يمكننا تأجيل ذلك؟',
      fr: 'On peut décaler ?',
    ),
    Phrase(
      id: 'extra_02',
      theme: 'amis',
      topic: 'soiree',
      deStandard: 'Gehen wir etwas trinken?',
      deParle: 'Geh\'n wir was trinken?',
      ar: 'هل نذهب لنشرب شيئاً؟',
      fr: 'On va boire un verre ?',
    ),
    Phrase(
      id: 'extra_03',
      theme: 'sante',
      topic: 'medecin',
      deStandard: 'Ich fühle mich nicht wohl.',
      deParle: 'Ich fühl mich nicht fit.',
      ar: 'لا أشعر أنني بخير.',
      fr: 'Je ne me sens pas très en forme.',
    ),
    Phrase(
      id: 'extra_04',
      theme: 'administration',
      topic: 'mairie',
      deStandard: 'Ich brauche eine Bestätigung.',
      deParle: 'Brauche \'ne Bestätigung.',
      ar: 'أحتاج إلى إفادة.',
      fr: 'J\'ai besoin d\'une attestation.',
    ),
    Phrase(
      id: 'extra_05',
      theme: 'transports',
      topic: 'train',
      deStandard: 'Der Zug hat Verspätung.',
      deParle: 'Der Zug ist zu spät.',
      ar: 'القطار متأخر.',
      fr: 'Le train a du retard.',
    ),
  ];

  setUp(() async {
    TtsService.instance.onSpeakForTesting = (text, {bool slow = false, double? rate}) {};

    inMemoryDb = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    appDb = AppDatabase.forTesting(testDb: inMemoryDb);
    await appDb.createSchema(inMemoryDb);
    AppDatabase.setInstanceForTesting(appDb);

    // Insérer les phrases dans la base
    final batch = inMemoryDb.batch();
    for (final p in samplePhrases) {
      batch.insert('phrases', {
        'id': p.id,
        'theme': p.theme,
        'topic': p.topic,
        'de_standard': p.deStandard,
        'de_parle': p.deParle,
        'de': p.deParle,
        'fr': p.fr,
        'ar': p.ar,
        'note': p.note,
        'cefr': p.cefr,
      });
    }
    await batch.commit(noResult: true);

    // Initialiser le profil utilisateur (Section 6)
    // Série = 3 jours, dernière session = hier
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    await appDb.saveUserProfile(UserProfile(
      id: 'default_user',
      objectifQuotidien: 2, // 2 nouvelles phrases par session
      themesPrioritaires: const ['smalltalk', 'travail'],
      serieJours: 3,
      derniereSession: yesterday,
    ));

    // Initialiser une phrase de révision en retard (overdue)
    final dueYesterday = DateTime.now().subtract(const Duration(days: 1));
    await appDb.saveProgression(UserPhrase(
      phraseId: 'rev_01',
      level: 2,
      dueAt: dueYesterday,
      reps: 2,
      status: UserPhraseStatus.enCours,
    ));
  });

  tearDown(() async {
    await inMemoryDb.close();
    AppDatabase.setInstanceForTesting(null);
  });

  group('Étape 4 : Session quotidienne complète (Workflow Plan)', () {
    test('Critère de validation : Déroulement complet Révisions -> Nouveautés -> Erreurs -> Écran de fin', () async {
      final controller = SessionController();
      await controller.initSession(targetPhraseIds: ['rev_01', 'new_01', 'new_02']);

      final state = controller.state;
      expect(state.status, equals(SessionStatus.inProgress));
      expect(state.session, isNotNull);

      // La session contient : 1 révision due ('rev_01') et 2 nouvelles phrases ('new_01', 'new_02')
      expect(state.session!.reviewCount, equals(1));
      expect(state.session!.newCount, equals(2));

      // ── 1. Phase Révision : Répondre avec succès à la phrase due ──────────
      expect(controller.state.currentItem?.phrase.id, equals('rev_01'));
      await controller.answerPhrase(ReviewOutcome.success);

      expect(controller.state.reviewedCount, equals(1));

      // ── 2. Phase Nouveautés : Premier écran, avancement et simulation erreur
      expect(controller.state.currentItem?.phrase.id, equals('new_01'));
      // Avancer dans le tunnel 4 écrans (Section 3.3)
      controller.advanceLearningStep(); // vers 2
      controller.advanceLearningStep(); // vers 3
      controller.advanceLearningStep(); // vers 4

      // Simulation d'une erreur sur new_01 (devra revenir dans la phase d'erreurs)
      await controller.answerPhrase(ReviewOutcome.mistake);

      // Carte suivante : new_02
      expect(controller.state.currentItem?.phrase.id, equals('new_02'));
      // Réponse juste à new_02
      await controller.answerPhrase(ReviewOutcome.success);

      // ── 3. Phase Erreurs : La phrase ratée new_01 revient automatiquement à la fin
      expect(controller.state.isErrorPhase, isTrue);
      expect(controller.state.currentItem?.phrase.id, equals('new_01'));

      // Cette fois, l'utilisateur réussit le rattrapage
      await controller.answerPhrase(ReviewOutcome.success);

      // ── 4. Phase Écran de fin : La session est terminée ────────────────────
      expect(controller.state.status, equals(SessionStatus.completed));
      expect(controller.state.reviewedCount, equals(1));
      expect(controller.state.newLearnedCount, equals(2)); // rev_01 (revue) + new_01 et new_02 (apprises)
      expect(controller.state.streakDays, equals(4)); // Passé de 3 à 4 jours consécutifs !
      expect(controller.state.successRate, greaterThan(0));
      expect(controller.state.nextReviewDate, isNotNull);
    });

    test('Critère de validation : Vérification de l\'enregistrement en base SQLite', () async {
      final controller = SessionController();
      await controller.initSession();

      // 1. Réviser rev_01 avec succès
      await controller.answerPhrase(ReviewOutcome.success);

      // 2. Apprendre new_01 avec succès
      await controller.answerPhrase(ReviewOutcome.success);

      // 3. Apprendre new_02 avec succès
      await controller.answerPhrase(ReviewOutcome.success);

      // Session complétée
      expect(controller.state.status, equals(SessionStatus.completed));

      // Vérification dans la table progression de SQLite
      final progressRows = await inMemoryDb.query('progression');
      expect(progressRows.length, greaterThanOrEqualTo(3));

      // rev_01 : niveau monté de 2 à 3
      final rev01 = progressRows.firstWhere((r) => r['phrase_id'] == 'rev_01');
      expect(rev01['niveau'], equals(3));
      expect(rev01['nb_bonnes'], equals(3));

      // new_01 : niveau monté de 0 à 1
      final new01 = progressRows.firstWhere((r) => r['phrase_id'] == 'new_01');
      expect(new01['niveau'], equals(1));
      expect(new01['nb_bonnes'], equals(1));

      // Vérification dans la table utilisateur de SQLite
      final userRows = await inMemoryDb.query('utilisateur');
      expect(userRows.isNotEmpty, isTrue);
      final user = userRows.first;
      expect(user['serie_jours'], equals(4)); // Série incrémentée à 4
      expect(user['derniere_session'], isNotNull);

      // Vérification dans la table session_logs
      final sessionLogs = await inMemoryDb.query('session_logs');
      expect(sessionLogs.isNotEmpty, isTrue);
      expect(sessionLogs.first['new_count'], equals(2));
      expect(sessionLogs.first['review_count'], equals(1));
    });

    test('Critère de validation : Mode Express (2 min, uniquement révisions sans nouveautés)', () async {
      // Lance le controller en mode express
      final controller = SessionController(isExpressMode: true);
      await controller.initSession(isExpressMode: true);

      final state = controller.state;
      expect(state.isExpressMode, isTrue);
      // Contient uniquement la révision due (0 nouvelle phrase)
      expect(state.session!.reviewCount, equals(1));
      expect(state.session!.newCount, equals(0));
      expect(state.session!.items.length, equals(1));

      // Répondre à l'unique révision
      await controller.answerPhrase(ReviewOutcome.success);

      // Fin de la session express
      expect(controller.state.status, equals(SessionStatus.completed));
      expect(controller.state.streakDays, equals(4)); // La série est maintenue !
    });

    test('Critère de validation : Option « 5 phrases de plus » ajoute 5 phrases et reprend la session', () async {
      final controller = SessionController();
      await controller.initSession();

      // Compléter rapidement la session initiale
      await controller.answerPhrase(ReviewOutcome.success);
      await controller.answerPhrase(ReviewOutcome.success);
      await controller.answerPhrase(ReviewOutcome.success);

      expect(controller.state.status, equals(SessionStatus.completed));
      final initialCount = controller.state.session!.items.length;

      // Déclencher l'option non imposée « 5 phrases de plus »
      await controller.addFiveMorePhrases();

      // La session a repris avec 5 cartes supplémentaires
      expect(controller.state.status, equals(SessionStatus.inProgress));
      expect(controller.state.session!.items.length, equals(initialCount + 5));

      // La carte active est bien la première des nouvelles phrases ajoutées
      expect(controller.state.currentIndex, equals(initialCount));
      expect(controller.state.currentItem, isNotNull);
    });
  });
}
