import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../../domain/models/phrase.dart';
import '../../domain/models/topic.dart';
import '../../domain/models/user_phrase.dart';
import '../../domain/models/user_profile.dart';

/// Gestionnaire SQLite local pour Deutsch Fast (avec fallback mémoire transparent sur le Web).
class AppDatabase {
  static const String _dbName = 'deutsch_fast.db';
  static const int _dbVersion = 4;

  static AppDatabase? _instance;
  Database? _db;

  /// Permet d'activer le stockage en mémoire sans SQLite natif pour les tests de widgets
  static bool useInMemoryStore = false;

  bool get _isInMemory => (kIsWeb || useInMemoryStore) && _db == null;

  // Stockage Web en mémoire pour tester sur localhost / Chrome sans configuration FFI complexe
  final Map<String, Phrase> _webPhrases = {};
  final Map<String, UserPhrase> _webUserPhrases = {};
  final List<Map<String, dynamic>> _webAttempts = [];
  final List<Map<String, dynamic>> _webSessionLogs = [];
  final List<Map<String, dynamic>> _webPhraseExamples = [];
  final Map<String, TopicInfo> _webTopics = {};
  UserProfile _webUserProfile = const UserProfile();

  AppDatabase._();

  @visibleForTesting
  AppDatabase.forTesting({Database? testDb}) : _db = testDb;

  static AppDatabase get instance {
    _instance ??= AppDatabase._();
    return _instance!;
  }

  @visibleForTesting
  static void setInstanceForTesting(AppDatabase? testInstance) {
    _instance = testInstance;
  }

  /// Réinitialise les collections en mémoire pour les tests unitaires / widget
  @visibleForTesting
  void clearInMemoryStore() {
    _webPhrases.clear();
    _webUserPhrases.clear();
    _webAttempts.clear();
    _webSessionLogs.clear();
    _webPhraseExamples.clear();
    _webTopics.clear();
    _webUserProfile = const UserProfile();
  }

  /// Crée le schéma complet sur une instance SQLite (notamment pour les tests en mémoire).
  Future<void> createSchema(Database db) async {
    await _onCreate(db, _dbVersion);
  }

  Future<Database> get database async {
    if (_db != null) return _db!;
    if (_isInMemory) {
      throw UnsupportedError('SQLite natif non disponible en mode mémoire/web, utilisation du stockage mémoire.');
    }
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE phrases ADD COLUMN ar TEXT');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS phrase_examples (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              phrase_id TEXT NOT NULL,
              example_de TEXT NOT NULL,
              created_at TEXT NOT NULL,
              FOREIGN KEY (phrase_id) REFERENCES phrases (id) ON DELETE CASCADE
            )
          ''');
        }
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS topics (
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              german_title TEXT NOT NULL,
              icon_code INTEGER NOT NULL,
              color_value INTEGER NOT NULL,
              topic_order INTEGER NOT NULL
            )
          ''');
        }
        if (oldVersion < 4) {
          try {
            await db.execute('ALTER TABLE phrases ADD COLUMN theme TEXT DEFAULT ""');
            await db.execute('ALTER TABLE phrases ADD COLUMN de_standard TEXT DEFAULT ""');
            await db.execute('ALTER TABLE phrases ADD COLUMN de_parle TEXT DEFAULT ""');
          } catch (_) {}

          // Table progression (Section 6)
          await db.execute('''
            CREATE TABLE IF NOT EXISTS progression (
              user_id TEXT NOT NULL,
              phrase_id TEXT NOT NULL,
              niveau INTEGER NOT NULL DEFAULT 0,
              prochaine_revision TEXT NOT NULL,
              nb_bonnes INTEGER NOT NULL DEFAULT 0,
              nb_erreurs INTEGER NOT NULL DEFAULT 0,
              derniere_revision TEXT,
              difficile INTEGER NOT NULL DEFAULT 0,
              PRIMARY KEY (user_id, phrase_id),
              FOREIGN KEY (phrase_id) REFERENCES phrases (id) ON DELETE CASCADE
            )
          ''');

          // Table utilisateur (Section 6)
          await db.execute('''
            CREATE TABLE IF NOT EXISTS utilisateur (
              id TEXT PRIMARY KEY,
              langue_traduction TEXT NOT NULL DEFAULT 'ar',
              primary_language TEXT NOT NULL DEFAULT 'fr',
              secondary_language TEXT,
              objectif_quotidien INTEGER NOT NULL DEFAULT 10,
              themes_prioritaires TEXT NOT NULL DEFAULT '["smalltalk", "travail"]',
              niveau_declare TEXT NOT NULL DEFAULT 'B2',
              heure_rappel TEXT NOT NULL DEFAULT '19:00',
              serie_jours INTEGER NOT NULL DEFAULT 0,
              derniere_session TEXT,
              gel_serie_disponible INTEGER NOT NULL DEFAULT 1,
              date_gel_utilise TEXT
            )
          ''');
          try {
            await db.execute('ALTER TABLE utilisateur ADD COLUMN date_gel_utilise TEXT');
          } catch (_) {}
          try {
            await db.execute("ALTER TABLE utilisateur ADD COLUMN primary_language TEXT DEFAULT 'fr'");
          } catch (_) {}
          try {
            await db.execute('ALTER TABLE utilisateur ADD COLUMN secondary_language TEXT');
          } catch (_) {}
        }
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Table phrases (Contenu commun à tous, clé anti-doublon de_standard)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS phrases (
        id TEXT PRIMARY KEY,
        theme TEXT NOT NULL,
        topic TEXT NOT NULL,
        de_standard TEXT NOT NULL UNIQUE,
        de_parle TEXT NOT NULL,
        de TEXT NOT NULL,
        fr TEXT,
        ar TEXT,
        note TEXT,
        cefr TEXT NOT NULL DEFAULT 'B1',
        audio_url TEXT
      )
    ''');

    // 2. Table progression (Une ligne par utilisateur et par phrase)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS progression (
        user_id TEXT NOT NULL,
        phrase_id TEXT NOT NULL,
        niveau INTEGER NOT NULL DEFAULT 0,
        prochaine_revision TEXT NOT NULL,
        nb_bonnes INTEGER NOT NULL DEFAULT 0,
        nb_erreurs INTEGER NOT NULL DEFAULT 0,
        derniere_revision TEXT,
        difficile INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (user_id, phrase_id),
        FOREIGN KEY (phrase_id) REFERENCES phrases (id) ON DELETE CASCADE
      )
    ''');

    // 3. Table utilisateur (Réglages et profil)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS utilisateur (
        id TEXT PRIMARY KEY,
        langue_traduction TEXT NOT NULL DEFAULT 'ar',
        primary_language TEXT NOT NULL DEFAULT 'ar',
        secondary_language TEXT,
        objectif_quotidien INTEGER NOT NULL DEFAULT 10,
        themes_prioritaires TEXT NOT NULL DEFAULT '["smalltalk", "travail"]',
        niveau_declare TEXT NOT NULL DEFAULT 'B2',
        heure_rappel TEXT NOT NULL DEFAULT '19:00',
        serie_jours INTEGER NOT NULL DEFAULT 0,
        derniere_session TEXT,
        gel_serie_disponible INTEGER NOT NULL DEFAULT 1,
        date_gel_utilise TEXT
      )
    ''');

    // 4. Table user_phrases (Compatibilité existante)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_phrases (
        phrase_id TEXT PRIMARY KEY,
        level INTEGER NOT NULL DEFAULT 0,
        due_at TEXT NOT NULL,
        ease REAL NOT NULL DEFAULT 2.5,
        reps INTEGER NOT NULL DEFAULT 0,
        lapses INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'nouvelle',
        last_result INTEGER,
        consecutive_errors INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (phrase_id) REFERENCES phrases (id) ON DELETE CASCADE
      )
    ''');

    // 3. Table Attempts
    await db.execute('''
      CREATE TABLE attempts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        phrase_id TEXT NOT NULL,
        exercise_type TEXT NOT NULL,
        success INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (phrase_id) REFERENCES phrases (id) ON DELETE CASCADE
      )
    ''');

    // 4. Table Shadow Recordings
    await db.execute('''
      CREATE TABLE shadow_recordings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        phrase_id TEXT NOT NULL,
        file_path TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (phrase_id) REFERENCES phrases (id) ON DELETE CASCADE
      )
    ''');

    // 5. Table Session Logs
    await db.execute('''
      CREATE TABLE session_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_date TEXT NOT NULL,
        duration_sec INTEGER NOT NULL,
        new_count INTEGER NOT NULL,
        review_count INTEGER NOT NULL,
        feeling TEXT
      )
    ''');

    // 6. Table Settings
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // 7. Table Phrase Examples (user-created example sentences)
    await db.execute('''
      CREATE TABLE phrase_examples (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        phrase_id TEXT NOT NULL,
        example_de TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (phrase_id) REFERENCES phrases (id) ON DELETE CASCADE
      )
    ''');

    // 8. Table Topics (catégories personnalisables par l'administrateur)
    await db.execute('''
      CREATE TABLE topics (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        german_title TEXT NOT NULL,
        icon_code INTEGER NOT NULL,
        color_value INTEGER NOT NULL,
        topic_order INTEGER NOT NULL
      )
    ''');
  }

  /// Importe ou synchronise le lot de phrases sans écraser la progression utilisateur.
  /// Règle Section 6 : pour chaque phrase du lot, ignorer si de_standard existe déjà, sinon insérer.
  /// Le fichier de progression n'est jamais écrasé par un nouvel import.
  /// Retourne le nombre de phrases nouvellement ajoutées.
  Future<int> importPhrasesFromJson({String? jsonContent}) async {
    try {
      final List<dynamic> list;
      if (jsonContent != null) {
        list = jsonDecode(jsonContent) as List<dynamic>;
      } else {
        final jsonString = await rootBundle.loadString('assets/data/phrases.json');
        list = jsonDecode(jsonString) as List<dynamic>;
      }

      if (_isInMemory) {
        final existingStandards = _webPhrases.values
            .map((p) => p.deStandard.trim().toLowerCase())
            .where((s) => s.isNotEmpty)
            .toSet();
        int importedCount = 0;
        for (final item in list) {
          final phrase = Phrase.fromJson(item as Map<String, dynamic>);
          final key = phrase.deStandard.trim().toLowerCase();
          if (key.isNotEmpty && existingStandards.contains(key)) {
            continue; // Déjà présent, ignorer le doublon
          }
          if (key.isNotEmpty) existingStandards.add(key);
          var assignedId = phrase.id;
          if (_webPhrases.containsKey(assignedId)) {
            assignedId = '${assignedId}_${DateTime.now().millisecondsSinceEpoch}_$importedCount';
          }
          _webPhrases[assignedId] = phrase.copyWith(id: assignedId);
          importedCount++;
        }
        return importedCount;
      }

      final db = await database;
      // Clé anti-doublon : de_standard (Section 6)
      final existingRows = await db.query('phrases', columns: ['id', 'de_standard']);
      final existingIds = existingRows.map((r) => r['id'].toString()).toSet();
      final existingStandards = existingRows
          .map((r) => (r['de_standard'] as String? ?? '').trim().toLowerCase())
          .where((s) => s.isNotEmpty)
          .toSet();

      final batch = db.batch();
      int importedCount = 0;

      for (final item in list) {
        final map = item as Map<String, dynamic>;
        final phrase = Phrase.fromJson(map);
        final key = phrase.deStandard.trim().toLowerCase();

        // Ignorer si la forme standard existe déjà dans la base
        if (key.isNotEmpty && existingStandards.contains(key)) {
          continue;
        }

        if (key.isNotEmpty) existingStandards.add(key);

        var assignedId = phrase.id;
        if (existingIds.contains(assignedId)) {
          assignedId = '${assignedId}_${DateTime.now().millisecondsSinceEpoch}_$importedCount';
        }
        existingIds.add(assignedId);

        batch.insert(
          'phrases',
          {
            'id': assignedId,
            'theme': phrase.theme,
            'topic': phrase.topic,
            'de_standard': phrase.deStandard,
            'de_parle': phrase.deParle,
            'de': phrase.deParle,
            'fr': phrase.fr,
            'ar': phrase.ar,
            'note': phrase.note,
            'cefr': phrase.cefr,
            'audio_url': phrase.audioUrl,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
        importedCount++;
      }

      await batch.commit(noResult: true);
      return importedCount;
    } catch (e) {
      debugPrint('importPhrasesFromJson warning: $e');
      return 0;
    }
  }

  /// Insère une phrase unique en ignorant les conflits d'ID ou de doublon.
  Future<void> insertPhrase(Phrase phrase) async {
    if (_isInMemory) {
      _webPhrases[phrase.id] = phrase;
      return;
    }

    final db = await database;
    await db.insert(
      'phrases',
      {
        'id': phrase.id,
        'theme': phrase.theme,
        'topic': phrase.topic,
        'de_standard': phrase.deStandard,
        'de_parle': phrase.deParle,
        'de': phrase.deParle,
        'fr': phrase.fr,
        'ar': phrase.ar,
        'note': phrase.note,
        'cefr': phrase.cefr,
        'audio_url': phrase.audioUrl,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Compte le nombre total de phrases stockées dans la base de données.
  Future<int> countPhrases() async {
    if (_isInMemory) {
      return _webPhrases.length;
    }
    final db = await database;
    final res = await db.rawQuery('SELECT COUNT(*) as count FROM phrases');
    return Sqflite.firstIntValue(res) ?? 0;
  }

  /// Récupère toutes les phrases.
  Future<List<Phrase>> getAllPhrases() async {
    if (_isInMemory) {
      if (_webPhrases.isEmpty) await importPhrasesFromJson();
      return _webPhrases.values.toList();
    }

    final db = await database;
    final rows = await db.query('phrases');
    return rows
        .map((r) => Phrase(
              id: r['id'].toString(),
              theme: (r['theme'] ?? r['topic']) as String? ?? 'general',
              topic: (r['topic'] ?? r['theme']) as String? ?? 'general',
              deStandard: (r['de_standard'] ?? r['de']) as String? ?? '',
              deParle: (r['de_parle'] ?? r['de']) as String? ?? '',
              de: (r['de_parle'] ?? r['de']) as String? ?? '',
              fr: (r['fr'] as String?) ?? '',
              ar: r['ar'] as String?,
              note: r['note'] as String?,
              cefr: (r['cefr'] as String?) ?? 'B1',
              audioUrl: r['audio_url'] as String?,
            ))
        .toList();
  }

  /// Récupère le profil utilisateur (Table utilisateur).
  Future<UserProfile> getUserProfile({String userId = 'default_user'}) async {
    if (_isInMemory) {
      if (_webUserProfile.derniereSession == null) {
        try {
          final prefs = await SharedPreferences.getInstance();
          final jsonStr = prefs.getString('web_user_profile');
          if (jsonStr != null) {
            _webUserProfile = UserProfile.fromMap(jsonDecode(jsonStr) as Map<String, dynamic>);
          }
        } catch (_) {}
      }
      _webUserProfile = _webUserProfile.checkWeeklyStreakFreeze();
      return _webUserProfile;
    }

    final db = await database;
    final rows = await db.query(
      'utilisateur',
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty) {
      final defaultProfile = UserProfile(id: userId);
      await saveUserProfile(defaultProfile);
      return defaultProfile;
    }
    final profile = UserProfile.fromMap(rows.first);
    final checkedProfile = profile.checkWeeklyStreakFreeze();
    if (checkedProfile.gelSerieDisponible != profile.gelSerieDisponible) {
      await saveUserProfile(checkedProfile);
    }
    return checkedProfile;
  }

  /// Enregistre ou met à jour le profil utilisateur (Table utilisateur).
  Future<void> saveUserProfile(UserProfile profile) async {
    if (_isInMemory) {
      _webUserProfile = profile;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('web_user_profile', jsonEncode(profile.toMap()));
      } catch (_) {}
      return;
    }

    final db = await database;
    await db.insert(
      'utilisateur',
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Sauvegarde atomique par batch du profil et des 3 phrases de démonstration lors de l'onboarding.
  Future<void> saveUserProfileAndDemoPhrases({
    required UserProfile profile,
    required List<Phrase> demoPhrases,
  }) async {
    if (_isInMemory) {
      _webUserProfile = profile;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('web_user_profile', jsonEncode(profile.toMap()));
      } catch (_) {}
      final now = DateTime.now();
      for (final p in demoPhrases) {
        _webPhrases[p.id] = p;
        _webUserPhrases[p.id] = UserPhrase(
          userId: profile.id,
          phraseId: p.id,
          level: 1,
          dueAt: now.add(const Duration(days: 1)),
          reps: 1,
          lapses: 0,
          status: UserPhraseStatus.fragile,
          lastReviewedAt: now,
        );
      }
      return;
    }

    final db = await database;
    final batch = db.batch();
    batch.insert('utilisateur', profile.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

    final now = DateTime.now();
    for (final p in demoPhrases) {
      batch.insert(
        'phrases',
        {
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
          'audio_url': p.audioUrl,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      batch.insert(
        'progression',
        {
          'user_id': profile.id,
          'phrase_id': p.id,
          'niveau': 1,
          'prochaine_revision': now.add(const Duration(days: 1)).toIso8601String(),
          'nb_bonnes': 1,
          'nb_erreurs': 0,
          'derniere_revision': now.toIso8601String(),
          'difficile': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      batch.insert(
        'user_phrases',
        {
          'phrase_id': p.id,
          'level': 1,
          'due_at': now.add(const Duration(days: 1)).toIso8601String(),
          'ease': 2.5,
          'reps': 1,
          'lapses': 0,
          'status': 'fragile',
          'last_result': 1,
          'consecutive_errors': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// Enregistre ou met à jour la progression d'une phrase (Table progression + user_phrases).
  Future<void> saveProgression(UserPhrase phrase, {String userId = 'default_user'}) async {
    if (_isInMemory) {
      _webUserPhrases[phrase.phraseId] = phrase;
      try {
        final prefs = await SharedPreferences.getInstance();
        final list = _webUserPhrases.values.map((p) => jsonEncode({
          'phraseId': p.phraseId,
          'level': p.level,
          'dueAt': p.dueAt.toIso8601String(),
          'ease': p.ease,
          'reps': p.reps,
          'lapses': p.lapses,
          'status': p.status.name,
          'lastReviewedAt': p.lastReviewedAt?.toIso8601String(),
          'isDifficult': p.isDifficult,
          'lastResult': p.lastResult,
          'consecutiveErrors': p.consecutiveErrors,
        })).toList();
        await prefs.setStringList('web_user_phrases_list', list);
      } catch (_) {}
      return;
    }

    final db = await database;
    await db.insert(
      'progression',
      {
        'user_id': userId,
        'phrase_id': phrase.phraseId,
        'niveau': phrase.level,
        'prochaine_revision': phrase.dueAt.toIso8601String(),
        'nb_bonnes': phrase.reps,
        'nb_erreurs': phrase.lapses,
        'derniere_revision': phrase.lastReviewedAt?.toIso8601String(),
        'difficile': (phrase.isDifficult || phrase.lapses >= 4) ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Synchronisation avec user_phrases pour rétro-compatibilité
    await db.insert(
      'user_phrases',
      {
        'phrase_id': phrase.phraseId,
        'level': phrase.level,
        'due_at': phrase.dueAt.toIso8601String(),
        'ease': phrase.ease,
        'reps': phrase.reps,
        'lapses': phrase.lapses,
        'status': phrase.status.name,
        'last_result': phrase.lastResult == null
            ? null
            : (phrase.lastResult! ? 1 : 0),
        'consecutive_errors': phrase.consecutiveErrors,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Charge les phrases utilisateur depuis SharedPreferences sur le Web si nécessaire.
  Future<void> _loadWebUserPhrasesIfNeeded() async {
    if (_webUserPhrases.isEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final list = prefs.getStringList('web_user_phrases_list');
        if (list != null && list.isNotEmpty) {
          for (final item in list) {
            final map = jsonDecode(item) as Map<String, dynamic>;
            final p = UserPhrase(
              phraseId: map['phraseId'] as String,
              level: map['level'] as int? ?? 0,
              dueAt: DateTime.tryParse(map['dueAt'] as String? ?? '') ?? DateTime.now(),
              ease: (map['ease'] as num?)?.toDouble() ?? 2.5,
              reps: map['reps'] as int? ?? 0,
              lapses: map['lapses'] as int? ?? 0,
              status: UserPhraseStatus.values.firstWhere(
                (s) => s.name == map['status'],
                orElse: () => UserPhraseStatus.nouvelle,
              ),
              lastReviewedAt: map['lastReviewedAt'] != null
                  ? DateTime.tryParse(map['lastReviewedAt'] as String)
                  : null,
              isDifficult: map['isDifficult'] as bool? ?? false,
              lastResult: map['lastResult'] as bool?,
              consecutiveErrors: map['consecutiveErrors'] as int? ?? 0,
            );
            _webUserPhrases[p.phraseId] = p;
          }
        }

        // Récupérer aussi les phrases terminées lors de la dernière session si non encore enregistrées
        final lastSession = prefs.getStringList('last_session_phrases');
        if (lastSession != null && lastSession.isNotEmpty) {
          bool added = false;
          for (final id in lastSession) {
            if (!_webUserPhrases.containsKey(id)) {
              _webUserPhrases[id] = UserPhrase(
                phraseId: id,
                level: 1,
                dueAt: DateTime.now().add(const Duration(days: 1)),
                status: UserPhraseStatus.fragile,
                reps: 1,
                lastResult: true,
                lastReviewedAt: DateTime.now(),
              );
              added = true;
            }
          }
          if (added) {
            final listToSave = _webUserPhrases.values.map((p) => jsonEncode({
              'phraseId': p.phraseId,
              'level': p.level,
              'dueAt': p.dueAt.toIso8601String(),
              'ease': p.ease,
              'reps': p.reps,
              'lapses': p.lapses,
              'status': p.status.name,
              'lastReviewedAt': p.lastReviewedAt?.toIso8601String(),
              'isDifficult': p.isDifficult,
            })).toList();
            await prefs.setStringList('web_user_phrases_list', listToSave);
          }
        }
      } catch (_) {}
    }
  }

  /// Récupère toute la progression utilisateur (Table progression).
  Future<Map<String, UserPhrase>> getAllProgression({String userId = 'default_user'}) async {
    if (_isInMemory) {
      await _loadWebUserPhrasesIfNeeded();
      return Map.from(_webUserPhrases);
    }

    final db = await database;
    final rows = await db.query(
      'progression',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    if (rows.isEmpty) {
      // Fallback vers user_phrases si progression est vide (migration en douceur)
      final legacyRows = await db.query('user_phrases');
      final map = <String, UserPhrase>{};
      for (final r in legacyRows) {
        final phraseId = r['phrase_id'] as String;
        map[phraseId] = UserPhrase(
          userId: userId,
          phraseId: phraseId,
          level: r['level'] as int,
          dueAt: DateTime.parse(r['due_at'] as String),
          ease: (r['ease'] as num).toDouble(),
          reps: r['reps'] as int,
          lapses: r['lapses'] as int,
          status: UserPhraseStatus.values.firstWhere(
            (s) => s.name == r['status'],
            orElse: () => UserPhraseStatus.nouvelle,
          ),
          lastResult: r['last_result'] == null ? null : (r['last_result'] as int) == 1,
          consecutiveErrors: r['consecutive_errors'] as int,
        );
      }
      return map;
    }

    final map = <String, UserPhrase>{};
    for (final r in rows) {
      final phraseId = r['phrase_id'] as String;
      map[phraseId] = UserPhrase.fromMap(r);
    }
    return map;
  }

  /// Récupère la progression d'une phrase spécifique.
  Future<UserPhrase?> getProgressionForPhrase(String phraseId, {String userId = 'default_user'}) async {
    if (_isInMemory) {
      await _loadWebUserPhrasesIfNeeded();
      return _webUserPhrases[phraseId];
    }

    final db = await database;
    final rows = await db.query(
      'progression',
      where: 'user_id = ? AND phrase_id = ?',
      whereArgs: [userId, phraseId],
      limit: 1,
    );
    if (rows.isNotEmpty) {
      return UserPhrase.fromMap(rows.first);
    }
    final oldRows = await db.query('user_phrases', where: 'phrase_id = ?', whereArgs: [phraseId], limit: 1);
    if (oldRows.isNotEmpty) {
      return UserPhrase.fromMap(oldRows.first);
    }
    return null;
  }

  /// Récupère toute la progression utilisateur sous forme de `Map<phraseId, UserPhrase>`.
  Future<Map<String, UserPhrase>> getAllUserPhrases() async {
    return getAllProgression();
  }

  /// Enregistre ou met à jour la progression d'une phrase.
  Future<void> saveUserPhrase(UserPhrase userPhrase) async {
    await saveProgression(userPhrase);
  }

  /// Récupère une phrase par son ID.
  Future<Phrase?> getPhraseById(String id) async {
    if (_isInMemory) {
      return _webPhrases[id];
    }

    final db = await database;
    final rows = await db.query('phrases', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    final r = rows.first;
    return Phrase(
      id: r['id'].toString(),
      theme: (r['theme'] ?? r['topic']) as String? ?? 'general',
      topic: (r['topic'] ?? r['theme']) as String? ?? 'general',
      deStandard: (r['de_standard'] ?? r['de']) as String? ?? '',
      deParle: (r['de_parle'] ?? r['de']) as String? ?? '',
      de: (r['de_parle'] ?? r['de']) as String? ?? '',
      fr: (r['fr'] as String?) ?? '',
      ar: r['ar'] as String?,
      note: r['note'] as String?,
      cefr: (r['cefr'] as String?) ?? 'B1',
      audioUrl: r['audio_url'] as String?,
    );
  }

  /// Insère ou remplace une phrase (utilisé par le panneau d'administration CRUD).
  Future<void> savePhrase(Phrase phrase) async {
    if (_isInMemory) {
      _webPhrases[phrase.id] = phrase;
      return;
    }

    final db = await database;
    await db.insert(
      'phrases',
      {
        'id': phrase.id,
        'theme': phrase.theme,
        'topic': phrase.topic,
        'de_standard': phrase.deStandard,
        'de_parle': phrase.deParle,
        'de': phrase.deParle,
        'fr': phrase.fr,
        'ar': phrase.ar,
        'note': phrase.note,
        'cefr': phrase.cefr,
        'audio_url': phrase.audioUrl,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Supprime une phrase par son ID (et ses données liées via CASCADE).
  Future<void> deletePhrase(String id) async {
    if (_isInMemory) {
      _webPhrases.remove(id);
      _webPhraseExamples.removeWhere((e) => e['phrase_id'] == id);
      return;
    }

    final db = await database;
    await db.delete('phrases', where: 'id = ?', whereArgs: [id]);
  }

  /// Enregistre un exemple de phrase créé par l'utilisateur dans phrase_examples.
  Future<void> saveExample({
    required String phraseId,
    required String exampleDe,
  }) async {
    final now = DateTime.now().toIso8601String();

    if (_isInMemory) {
      _webPhraseExamples.add({
        'phrase_id': phraseId,
        'example_de': exampleDe,
        'created_at': now,
      });
      return;
    }

    final db = await database;
    await db.insert('phrase_examples', {
      'phrase_id': phraseId,
      'example_de': exampleDe,
      'created_at': now,
    });
  }

  /// Récupère tous les exemples d'une phrase (triés du plus récent au plus ancien).
  Future<List<Map<String, dynamic>>> getExamplesForPhrase(String phraseId) async {
    if (_isInMemory) {
      final results = _webPhraseExamples
          .where((e) => e['phrase_id'] == phraseId)
          .toList()
          .reversed
          .toList();
      return results;
    }

    final db = await database;
    return await db.query(
      'phrase_examples',
      where: 'phrase_id = ?',
      whereArgs: [phraseId],
      orderBy: 'created_at DESC',
    );
  }

  /// Enregistre un passage/essai sur une phrase.
  Future<void> recordAttempt({
    required String phraseId,
    required String exerciseType,
    required bool success,
  }) async {
    if (_isInMemory) {
      _webAttempts.insert(0, {
        'phrase_id': phraseId,
        'exercise_type': exerciseType,
        'success': success ? 1 : 0,
        'created_at': DateTime.now().toIso8601String(),
      });
      return;
    }

    final db = await database;
    await db.insert('attempts', {
      'phrase_id': phraseId,
      'exercise_type': exerciseType,
      'success': success ? 1 : 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Récupère l'historique des essais d'une phrase.
  Future<List<Map<String, dynamic>>> getAttemptsForPhrase(String phraseId) async {
    if (_isInMemory) {
      return _webAttempts.where((a) => a['phrase_id'] == phraseId).take(10).toList();
    }

    final db = await database;
    return await db.query(
      'attempts',
      where: 'phrase_id = ?',
      whereArgs: [phraseId],
      orderBy: 'created_at DESC',
      limit: 10,
    );
  }

  /// Enregistre un log de session (Web fallback).
  void recordWebSessionLog(Map<String, dynamic> log) {
    _webSessionLogs.insert(0, log);
  }

  /// Récupère l'historique de toutes les séances enregistrées.
  Future<List<Map<String, dynamic>>> getSessionLogs() async {
    if (_isInMemory) {
      return List.from(_webSessionLogs);
    }

    final db = await database;
    return await db.query(
      'session_logs',
      orderBy: 'session_date DESC',
    );
  }

  /// Calcule le temps total d'apprentissage en secondes.
  Future<int> getTotalPracticeSeconds() async {
    if (_isInMemory) {
      return _webSessionLogs.fold<int>(0, (sum, log) => sum + ((log['duration_sec'] as int?) ?? 0));
    }

    final db = await database;
    final result = await db.rawQuery('SELECT SUM(duration_sec) as total FROM session_logs');
    if (result.isNotEmpty && result.first['total'] != null) {
      return (result.first['total'] as num).toInt();
    }
    return 0;
  }

  /// Réinitialise complètement la progression utilisateur (conserve les phrases intactes).
  Future<void> resetUserProgress({bool resetPreferences = true}) async {
    _webUserPhrases.clear();
    _webAttempts.clear();
    _webSessionLogs.clear();
    _webUserProfile = const UserProfile(serieJours: 0);

    if (!_isInMemory) {
      try {
        final db = await database;
        await db.delete('progression');
        await db.delete('user_phrases');
        await db.delete('attempts');
        await db.delete('session_logs');
        try {
          await db.delete('shadow_recordings');
          await db.delete('utilisateur');
        } catch (_) {}
      } catch (e) {
        debugPrint('[AppDatabase] Erreur resetUserProgress: $e');
      }
    }

    if (resetPreferences) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final allKeys = prefs.getKeys().toList();
        for (final key in allKeys) {
          if (key.startsWith('palier_exam_') ||
              key.startsWith('batch_') ||
              key.startsWith('media_played_lot_') ||
              key.startsWith('media_unlocked_lot_') ||
              key.startsWith('chest_claimed_') ||
              key.startsWith('session_done_') ||
              key.startsWith('daily_xp_') ||
              key.startsWith('streak') ||
              key == 'web_user_phrases_list' ||
              key == 'last_session_phrases' ||
              key == 'current_batch_index' ||
              key == 'auto_listening_dialogue_lot_ids' ||
              key == 'unlocked_palier_max' ||
              key == 'exam_joker_count' ||
              key == 'last_session_completed_date' ||
              key == 'last_master_xp_earned' ||
              key == 'phrase_of_the_day_listened_date' ||
              key == 'master_xp_unlocked_today' ||
              key == 'user_total_xp' ||
              key == 'user_total_gems' ||
              key == 'user_streak_days') {
            await prefs.remove(key);
          }
        }
        await prefs.setInt('total_xp', 0);
        await prefs.setInt('total_gems', 50);
        await prefs.setInt('current_batch_index', 0);
        await prefs.setInt('unlocked_palier_max', 1);
        await prefs.setInt('streak_days', 0);
      } catch (e) {
        debugPrint('[AppDatabase] Erreur reset SharedPreferences: $e');
      }
    }
  }

  /// Récupère toutes les catégories/thématiques (depuis la base ou fallback).
  Future<List<TopicInfo>> getAllTopics() async {
    if (_isInMemory) {
      if (_webTopics.isEmpty) {
        for (final t in TopicInfo.defaultTopics) {
          _webTopics[t.id] = t;
        }
      }
      final list = _webTopics.values.toList()
        ..sort((a, b) => a.order.compareTo(b.order));
      TopicInfo.allTopics = list;
      return list;
    }

    final db = await database;
    final rows = await db.query('topics', orderBy: 'topic_order ASC');
    if (rows.isEmpty) {
      // Pré-remplir avec les 13 catégories initiales
      final batch = db.batch();
      for (final t in TopicInfo.defaultTopics) {
        batch.insert('topics', t.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
      TopicInfo.allTopics = List.from(TopicInfo.defaultTopics);
      return List.from(TopicInfo.defaultTopics);
    }

    final list = rows.map((r) => TopicInfo.fromMap(r)).toList();
    TopicInfo.allTopics = list;
    return list;
  }

  /// Ajoute ou met à jour une catégorie thématique.
  Future<void> saveTopic(TopicInfo topic) async {
    if (_isInMemory) {
      _webTopics[topic.id] = topic;
      TopicInfo.allTopics = _webTopics.values.toList()
        ..sort((a, b) => a.order.compareTo(b.order));
      return;
    }

    final db = await database;
    await db.insert(
      'topics',
      topic.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await getAllTopics(); // Met à jour TopicInfo.allTopics
  }

  /// Supprime une catégorie par son identifiant.
  Future<void> deleteTopic(String id) async {
    if (_isInMemory) {
      _webTopics.remove(id);
      TopicInfo.allTopics = _webTopics.values.toList()
        ..sort((a, b) => a.order.compareTo(b.order));
      return;
    }

    final db = await database;
    await db.delete('topics', where: 'id = ?', whereArgs: [id]);
    await getAllTopics(); // Met à jour TopicInfo.allTopics
  }
}
