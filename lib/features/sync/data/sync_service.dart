import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/supabase_client.dart';
import '../../../data/database/app_database.dart';
import '../../../domain/models/phrase.dart';
import '../../../domain/models/user_phrase.dart';

import '../../media/domain/media_unlock_manager.dart';

/// Résultat d'une synchronisation
class SyncResult {
  final bool success;
  final int phrasesDownloaded;
  final int progressPushed;
  final int progressPulled;
  final String? errorMessage;

  const SyncResult({
    required this.success,
    this.phrasesDownloaded = 0,
    this.progressPushed = 0,
    this.progressPulled = 0,
    this.errorMessage,
  });
}

/// Service de synchronisation bidirectionnelle entre SQLite local et Supabase PostgreSQL.
class SyncService {
  final SupabaseClient? _client;
  final AppDatabase _db;

  SyncService({SupabaseClient? client, AppDatabase? db})
      : _client = client ?? (AppSupabase.isInitialized ? AppSupabase.client : null),
        _db = db ?? AppDatabase.instance;

  SupabaseClient get _safeClient => _client!;

  /// Lance une synchronisation complète (Catalogue + Progression utilisateur + Examens + Stats)
  Future<SyncResult> syncAll() async {
    final client = _client;
    if (!AppSupabase.isInitialized || client == null) {
      return const SyncResult(
        success: false,
        errorMessage: 'Supabase non initialisé (mode hors-ligne actif).',
      );
    }

    int phrasesDownloaded = 0;
    int progressPushed = 0;
    int progressPulled = 0;

    try {
      // 1. Synchronisation du catalogue de phrases (Cloud -> Local)
      phrasesDownloaded = await syncPhrasesCatalog();

      // 2. Synchronisation de la progression si un utilisateur est connecté
      final user = _safeClient.auth.currentUser;
      if (user != null) {
        final progressRes = await syncUserProgress(user.id);
        progressPushed = progressRes.$1;
        progressPulled = progressRes.$2;
        await syncPalierExams(user.id);
        await syncProfileStats(user.id);
      }

      return SyncResult(
        success: true,
        phrasesDownloaded: phrasesDownloaded,
        progressPushed: progressPushed,
        progressPulled: progressPulled,
      );
    } catch (e) {
      debugPrint('[SyncService] Erreur pendant syncAll: $e');
      return SyncResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Télécharge les nouvelles phrases du Cloud vers la base de données locale
  Future<int> syncPhrasesCatalog() async {
    try {
      final List<dynamic> cloudPhrasesData = await _safeClient
          .from('phrases')
          .select()
          .order('id');

      if (cloudPhrasesData.isEmpty) return 0;

      final localPhrases = await _db.getAllPhrases();
      final localIds = localPhrases.map((p) => p.id).toSet();

      int newlyAdded = 0;
      for (final row in cloudPhrasesData) {
        final id = row['id'] as String;
        if (!localIds.contains(id)) {
          final phrase = Phrase(
            id: id,
            theme: row['theme'] as String? ?? 'general',
            topic: row['topic'] as String? ?? 'general',
            deStandard: row['de_standard'] as String? ?? (row['de'] as String? ?? ''),
            deParle: row['de_parle'] as String? ?? (row['de'] as String? ?? ''),
            de: row['de'] as String? ?? '',
            fr: row['fr'] as String? ?? '',
            ar: row['ar'] as String?,
            note: row['note'] as String?,
            cefr: row['cefr'] as String? ?? 'B1',
            audioUrl: row['audio_url'] as String?,
          );
          await _db.savePhrase(phrase);
          newlyAdded++;
        }
      }

      debugPrint('[SyncService] Catalogue synchronisé : $newlyAdded nouvelles phrases importées');
      return newlyAdded;
    } catch (e) {
      debugPrint('[SyncService] Erreur syncPhrasesCatalog: $e');
      return 0;
    }
  }

  /// Synchronise la progression SRS d'un utilisateur entre Local et Cloud
  Future<(int pushed, int pulled)> syncUserProgress(String userId) async {
    int pushed = 0;
    int pulled = 0;

    try {
      // A. Pousser la progression locale vers Supabase
      final localMap = await _db.getAllProgression(userId: userId);
      if (localMap.isNotEmpty) {
        final List<Map<String, dynamic>> payload = localMap.values.map((up) {
          return {
            'user_id': userId,
            'phrase_id': up.phraseId,
            'level': up.level,
            'reps': up.reps,
            'lapses': up.lapses,
            'last_result': up.lastResult,
            'next_review': up.dueAt.toIso8601String(),
          };
        }).toList();

        await _safeClient.from('user_phrase_progress').upsert(
          payload,
          onConflict: 'user_id, phrase_id',
        );
        pushed = payload.length;
      }

      // B. Récupérer la progression cloud la plus récente pour cet utilisateur
      final List<dynamic> cloudProgress = await _safeClient
          .from('user_phrase_progress')
          .select()
          .eq('user_id', userId);

      for (final row in cloudProgress) {
        final phraseId = row['phrase_id'] as String;
        final cloudLevel = row['level'] as int? ?? 0;
        final cloudReps = row['reps'] as int? ?? 0;
        final cloudLapses = row['lapses'] as int? ?? 0;
        final cloudLastResult = row['last_result'] as bool? ?? true;
        final cloudNextReviewStr = row['next_review'] as String?;
        final cloudNextReview = cloudNextReviewStr != null
            ? DateTime.tryParse(cloudNextReviewStr) ?? DateTime.now()
            : DateTime.now();

        final localUp = localMap[phraseId];
        // Si le cloud a une version plus avancée ou inexistante localement, mettre à jour le local
        if (localUp == null || cloudLevel > localUp.level || cloudReps > localUp.reps) {
          final updated = UserPhrase(
            phraseId: phraseId,
            level: cloudLevel,
            dueAt: cloudNextReview,
            reps: cloudReps,
            lapses: cloudLapses,
            lastResult: cloudLastResult,
          );
          await _db.saveProgression(updated, userId: userId);
          pulled++;
        }
      }

      debugPrint('[SyncService] Progression synchronisée: $pushed envoyés, $pulled mis à jour');
      return (pushed, pulled);
    } catch (e) {
      debugPrint('[SyncService] Erreur syncUserProgress: $e');
      return (pushed, pulled);
    }
  }

  /// Synchronise les examens de palier réussis (Local <-> Cloud)
  Future<void> syncPalierExams(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Envoyer les examens locaux réussis vers Supabase
      for (int palier = 1; palier <= 10; palier++) {
        final passed = prefs.getBool('palier_exam_${palier}_passed') ?? false;
        final score = prefs.getInt('palier_exam_${palier}_score') ?? 0;
        if (passed || score >= 20) {
          await _safeClient.from('palier_exams').upsert({
            'user_id': userId,
            'palier_index': palier,
            'score': score > 0 ? score : 20,
            'total_questions': 30,
            'passed': true,
            'completed_at': DateTime.now().toIso8601String(),
          }, onConflict: 'user_id, palier_index');
        }
      }

      // 2. Télécharger les examens réussis du Cloud vers le Local
      final List<dynamic> cloudExams = await _safeClient
          .from('palier_exams')
          .select()
          .eq('user_id', userId);

      for (final row in cloudExams) {
        final palierIndex = row['palier_index'] as int? ?? 0;
        final passed = row['passed'] as bool? ?? false;
        final score = row['score'] as int? ?? 0;
        if (palierIndex > 0 && (passed || score >= 20)) {
          await prefs.setBool('palier_exam_${palierIndex}_passed', true);
          await prefs.setInt('palier_exam_${palierIndex}_score', score);
        }
      }
      debugPrint('[SyncService] Examens de paliers synchronisés avec succès');
    } catch (e) {
      debugPrint('[SyncService] Erreur syncPalierExams: $e');
    }
  }

  /// Synchronise les statistiques de profil (XP, gemmes, série, plus haut lot)
  Future<void> syncProfileStats(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allPhrases = await _db.getAllPhrases();
      final progress = await _db.getAllProgression(userId: userId);

      final highestUnlocked = MediaUnlockManager.getHighestUnlockedLot(
        progress: progress,
        allPhrases: allPhrases,
        prefs: prefs,
      );

      final totalXp = prefs.getInt('total_xp') ?? 0;
      final totalGems = prefs.getInt('total_gems') ?? 50;

      // 1. Récupérer le profil cloud
      final cloudProfile = await _safeClient
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      int streak = 0;
      int cloudXp = 0;
      int cloudGems = 50;
      int cloudHighest = 1;

      if (cloudProfile != null) {
        streak = cloudProfile['streak_days'] as int? ?? 0;
        cloudXp = cloudProfile['total_xp'] as int? ?? 0;
        cloudGems = cloudProfile['total_gems'] as int? ?? 50;
        cloudHighest = cloudProfile['highest_unlocked_lot'] as int? ?? 1;
      }

      final finalXp = totalXp > cloudXp ? totalXp : cloudXp;
      final finalGems = totalGems > cloudGems ? totalGems : cloudGems;
      final finalHighest = highestUnlocked > cloudHighest ? highestUnlocked : cloudHighest;

      await prefs.setInt('total_xp', finalXp);
      await prefs.setInt('total_gems', finalGems);

      // 2. Mettre à jour le profil Supabase
      await _safeClient.from('profiles').update({
        'highest_unlocked_lot': finalHighest,
        'total_xp': finalXp,
        'total_gems': finalGems,
        'streak_days': streak,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      debugPrint('[SyncService] Profil et stats synchronisés (Lot max: $finalHighest, XP: $finalXp)');
    } catch (e) {
      debugPrint('[SyncService] Erreur syncProfileStats: $e');
    }
  }

  /// Enregistre le résultat d'un grand examen réussi sur le cloud
  Future<void> recordPalierExamSuccess({
    required int palierIndex,
    required int score,
    required int totalQuestions,
    required bool passed,
  }) async {
    final client = _client;
    final user = client?.auth.currentUser;
    if (user == null || client == null) return;

    try {
      await client.from('palier_exams').upsert({
        'user_id': user.id,
        'palier_index': palierIndex,
        'score': score,
        'total_questions': totalQuestions,
        'passed': passed,
        'completed_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id, palier_index');
      debugPrint('[SyncService] Examen Palier $palierIndex enregistré sur le cloud');
    } catch (e) {
      debugPrint('[SyncService] Erreur recordPalierExamSuccess: $e');
    }
  }
}
