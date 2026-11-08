import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_lern_deutsch_mobile/data/database/app_database.dart';
import 'package:app_lern_deutsch_mobile/domain/models/phrase.dart';
import 'package:app_lern_deutsch_mobile/features/media/domain/media_unlock_manager.dart';
import 'package:app_lern_deutsch_mobile/core/services/subscription_service.dart';
import '../data/raetsel_generator.dart';
import 'models/raetsel_level.dart';
import 'raetsel_constants.dart';

/// Gestionnaire central du mode Hoppla Rätsel (mots croisés / Crostic).
/// Gère le statut de déblocage, la persistance des niveaux en cours,
/// le pool des phrases terminées, et la progression.
class RaetselManager {
  RaetselManager._();
  static final RaetselManager instance = RaetselManager._();

  static const String keyCurrentLevel = 'raetsel_current_level_num';
  static const String keySavedLevelJson = 'raetsel_saved_level_json';
  static const String keySavedEnteredLetters = 'raetsel_saved_entered_letters';
  static const String keyJustUnlocked = 'raetsel_just_unlocked_flag';

  /// Notifier réactif pour signaler le déblocage en direct sans redémarrer
  final ValueNotifier<bool> unlockNotifier = ValueNotifier<bool>(false);

  /// Vérifie si Hoppla Rätsel est débloqué (Examen 1 réussi >= 20/30)
  Future<bool> isUnlocked({SharedPreferences? prefs}) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    final exam1Passed = MediaUnlockManager.isPalierExamPassed(1, p);
    final explicitlyUnlocked = p.getBool('raetsel_unlocked') ?? false;
    final unlocked = exam1Passed || explicitlyUnlocked;
    if (unlockNotifier.value != unlocked) {
      unlockNotifier.value = unlocked;
    }
    return unlocked;
  }

  /// Débloque explicitement Hoppla Rätsel (appelé lors de la réussite de l'Examen 1)
  Future<void> onExam1Passed({SharedPreferences? prefs}) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    await p.setBool('raetsel_unlocked', true);
    await p.setBool(keyJustUnlocked, true);
    unlockNotifier.value = true;
  }

  /// Vérifie si le mode vient tout juste d'être débloqué (pour animation & message)
  Future<bool> checkAndClearJustUnlocked({SharedPreferences? prefs}) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    final justUnlocked = p.getBool(keyJustUnlocked) ?? false;
    if (justUnlocked) {
      await p.setBool(keyJustUnlocked, false);
    }
    return justUnlocked;
  }

  /// Nombre de phrases apprises dans le Palier 1 (x / 30)
  Future<int> getPalier1LearnedCount(AppDatabase db) async {
    try {
      final allPhrases = await db.getAllPhrases();
      final palier1Phrases = allPhrases.take(30).toList();
      if (palier1Phrases.isEmpty) return 0;

      int completed = 0;
      for (final p in palier1Phrases) {
        final up = await db.getProgressionForPhrase(p.id);
        if (up != null && up.level > 0) {
          completed++;
        }
      }
      return completed.clamp(0, 30);
    } catch (_) {
      return 0;
    }
  }

  /// Récupère le numéro de niveau actuel (défaut: 1)
  Future<int> getCurrentLevelNumber({SharedPreferences? prefs}) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    return p.getInt(keyCurrentLevel) ?? 1;
  }

  /// Sauvegarde l'état d'un niveau commencé et abandonné
  Future<void> saveInProgressLevel({
    required RaetselLevel level,
    required Map<int, String> enteredLetters,
    SharedPreferences? prefs,
  }) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    await p.setString(keySavedLevelJson, jsonEncode(level.toJson()));
    final lettersMap = enteredLetters.map((k, v) => MapEntry(k.toString(), v));
    await p.setString(keySavedEnteredLetters, jsonEncode(lettersMap));
  }

  /// Restaure un niveau commencé s'il correspond au niveau actif
  Future<({RaetselLevel level, Map<int, String> enteredLetters})?> loadInProgressLevel({
    required int expectedLevelNumber,
    SharedPreferences? prefs,
  }) async {
    try {
      final p = prefs ?? await SharedPreferences.getInstance();
      final levelJsonStr = p.getString(keySavedLevelJson);
      if (levelJsonStr == null || levelJsonStr.isEmpty) return null;

      final levelMap = jsonDecode(levelJsonStr) as Map<String, dynamic>;
      final level = RaetselLevel.fromJson(levelMap);
      if (level.levelNumber != expectedLevelNumber) {
        // Niveau obsolète ou achevé
        await clearSavedInProgressLevel(prefs: p);
        return null;
      }

      final lettersJsonStr = p.getString(keySavedEnteredLetters) ?? '{}';
      final lettersRaw = jsonDecode(lettersJsonStr) as Map<String, dynamic>;
      final enteredLetters = lettersRaw.map((k, v) => MapEntry(int.parse(k), v as String));

      return (level: level, enteredLetters: enteredLetters);
    } catch (e) {
      debugPrint('[RaetselManager] Erreur restauration niveau en cours: $e');
      return null;
    }
  }

  /// Efface la sauvegarde du niveau en cours (après complétion)
  Future<void> clearSavedInProgressLevel({SharedPreferences? prefs}) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    await p.remove(keySavedLevelJson);
    await p.remove(keySavedEnteredLetters);
  }

  /// Charge le pool de phrases disponibles pour le joueur :
  /// Toutes les phrases terminées (au déblocage : les 30 du palier 1, puis +10 par lot terminé)
  Future<List<Phrase>> loadPhrasesPool(AppDatabase db) async {
    var allPhrases = await db.getAllPhrases();
    if (allPhrases.isEmpty) {
      await db.importPhrasesFromJson();
      allPhrases = await db.getAllPhrases();
    }
    if (allPhrases.isEmpty) return [];

    final List<Phrase> pool = [];
    for (final phrase in allPhrases) {
      final up = await db.getProgressionForPhrase(phrase.id);
      if (up != null && up.level > 0) {
        pool.add(phrase);
      }
    }

    // Sécurité : si moins de 10 phrases trouvées dans la progression mais examen 1 passé,
    // on inclut les 30 phrases du palier 1 comme pool de départ garanti.
    if (pool.length < 10 && allPhrases.length >= 30) {
      return allPhrases.take(30).toList();
    }

    if (pool.isEmpty && allPhrases.isNotEmpty) {
      return allPhrases.take(30.clamp(0, allPhrases.length)).toList();
    }

    return pool;
  }

  /// Génère un nouveau niveau déterministe pour un numéro donné
  RaetselLevel generateLevel({
    required int levelNumber,
    required List<Phrase> pool,
  }) {
    return RaetselGenerator.generateLevel(
      levelNumber: levelNumber,
      availablePhrases: pool,
    );
  }

  /// Calcule les étoiles selon les indices et erreurs
  static int calculateStars({required int hintsUsed, required int mistakes}) {
    if (hintsUsed == 0 && mistakes <= RaetselConstants.maxMistakesFor3Stars) return 3;
    if (hintsUsed <= RaetselConstants.maxHintsFor2Stars || mistakes <= RaetselConstants.maxMistakesFor2Stars) {
      return 2;
    }
    return 1;
  }

  /// Calcule l'XP du niveau selon les mots, indices et étoiles
  static int calculateTotalXp({
    required int wordsCount,
    required int hintsUsed,
    required int stars,
  }) {
    final wordsXp = (wordsCount * RaetselConstants.xpPerWordNoHint) -
        (hintsUsed * (RaetselConstants.xpPerWordNoHint - RaetselConstants.xpPerWordWithHint))
            .clamp(0, wordsCount * 2);
    final baseXp = RaetselConstants.xpLevelCompletionBase + wordsXp;
    double multiplier = RaetselConstants.xpMultiplierStar1;
    if (stars == 2) multiplier = RaetselConstants.xpMultiplierStar2;
    if (stars == 3) multiplier = RaetselConstants.xpMultiplierStar3;
    return (baseXp * multiplier).round();
  }

  /// Calcule les diamants selon les étoiles
  static int calculateDiamonds({required int stars}) {
    return (stars == 3) ? RaetselConstants.diamonds3Stars : RaetselConstants.diamondsBase;
  }

  /// Enregistre la complétion d'un mot dans le système de répétition espacée Leitner :
  /// - Sans indice et sans erreur préalable : Leitner +1 (au plus une fois par jour par phrase)
  /// - Avec indice ou après erreur : aucun changement (ne descend jamais)
  Future<void> onWordFoundSuccess({
    required String phraseId,
    required bool usedHint,
    required bool hadMistake,
    AppDatabase? db,
    SharedPreferences? prefs,
  }) async {
    final database = db ?? AppDatabase.instance;
    final p = prefs ?? await SharedPreferences.getInstance();

    // Répétition espacée : seulement si sans aide
    if (!usedHint && !hadMistake) {
      final now = DateTime.now();
      final todayDateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final srsReviewKey = 'raetsel_srs_reviewed_${phraseId}_$todayDateStr';

      // Au plus une fois par jour et par phrase
      final alreadyReviewedToday = p.getBool(srsReviewKey) ?? false;
      if (!alreadyReviewedToday) {
        final existing = await database.getProgressionForPhrase(phraseId);
        if (existing != null) {
          final newLevel = (existing.level + 1).clamp(0, 7);
          final updated = existing.copyWith(
            level: newLevel,
            reps: existing.reps + 1,
            lastReviewedAt: now,
            lastResult: true,
          );
          await database.saveProgression(updated);
          await p.setBool(srsReviewKey, true);
        }
      }
    }
  }

  /// Enregistre une erreur sur un mot :
  /// Si la phrase cumule 3 échecs au total dans Rätsel, elle rejoint « Phrases résistantes ».
  /// Une erreur ne fait JAMAIS descendre le niveau Leitner existant.
  Future<void> onWordMistake({
    required String phraseId,
    AppDatabase? db,
    SharedPreferences? prefs,
  }) async {
    final database = db ?? AppDatabase.instance;
    final p = prefs ?? await SharedPreferences.getInstance();

    final mistakeKey = 'raetsel_mistakes_count_$phraseId';
    final currentMistakes = (p.getInt(mistakeKey) ?? 0) + 1;
    await p.setInt(mistakeKey, currentMistakes);

    if (currentMistakes >= RaetselConstants.mistakesThresholdForResistantPhrase) {
      final existing = await database.getProgressionForPhrase(phraseId);
      if (existing != null && !existing.isDifficult) {
        final updated = existing.copyWith(isDifficult: true);
        await database.saveProgression(updated);
      }
    }
  }

  /// Valide l'activité quotidienne pour la série de jours de l'utilisateur.
  /// Terminer un niveau, ou trouver au moins 3 mots, compte comme activité du jour.
  Future<void> markDailyStreakActivity({
    AppDatabase? db,
    SharedPreferences? prefs,
  }) async {
    final database = db ?? AppDatabase.instance;
    final p = prefs ?? await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayKey = '${now.year}_${now.month}_${now.day}';

    final alreadyMarked = p.getBool('raetsel_streak_marked_$todayKey') ?? false;
    if (alreadyMarked) return;

    await p.setBool('raetsel_streak_marked_$todayKey', true);
    await p.setBool('session_done_$todayKey', true);

    try {
      final profile = await database.getUserProfile();
      final lastSession = profile.derniereSession;
      int newStreak = profile.serieJours;

      if (lastSession == null) {
        newStreak = profile.serieJours > 0 ? profile.serieJours : 1;
      } else {
        final diffDays = now.difference(DateTime(lastSession.year, lastSession.month, lastSession.day)).inDays;
        if (diffDays == 1) {
          newStreak += 1;
        } else if (diffDays == 0) {
          if (newStreak == 0) newStreak = 1;
        } else {
          newStreak = 1;
        }
      }

      final updatedProfile = profile.copyWith(
        serieJours: newStreak,
        derniereSession: now,
      );
      await database.saveUserProfile(updatedProfile);
      await p.setInt('streak_days', newStreak);
      await p.setInt('user_streak_days', newStreak);
    } catch (e) {
      debugPrint('[RaetselManager] Erreur mise à jour série: $e');
    }
  }

  /// Récupère le nombre de niveaux terminés aujourd'hui (pour le plafond anti-abus)
  Future<int> getTodayCompletedLevelsCount({SharedPreferences? prefs}) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayKey = '${now.year}_${now.month}_${now.day}';
    return p.getInt('raetsel_completed_levels_$todayKey') ?? 0;
  }

  /// Applique les récompenses de fin de niveau (XP, diamants, plafond quotidien, série)
  Future<({int xpAwarded, int diamondsAwarded, bool isCapped, int stars})> applyLevelCompletionRewards({
    required int wordsCount,
    required int hintsUsed,
    required int mistakes,
    AppDatabase? db,
    SharedPreferences? prefs,
  }) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    final database = db ?? AppDatabase.instance;
    final now = DateTime.now();
    final todayKey = '${now.year}_${now.month}_${now.day}';

    final stars = calculateStars(hintsUsed: hintsUsed, mistakes: mistakes);
    final rawXp = calculateTotalXp(wordsCount: wordsCount, hintsUsed: hintsUsed, stars: stars);
    final rawDiamonds = calculateDiamonds(stars: stars);

    // Incrémenter le compteur de niveaux du jour
    final completedCountKey = 'raetsel_completed_levels_$todayKey';
    final completedToday = (p.getInt(completedCountKey) ?? 0) + 1;
    await p.setInt(completedCountKey, completedToday);

    // Vérifier le plafond anti-abus
    final isCapped = completedToday > RaetselConstants.dailyRewardMaxLevels;
    final xpAwarded = isCapped ? 0 : rawXp;
    final diamondsAwarded = isCapped ? 0 : rawDiamonds;

    if (!isCapped) {
      // 1. Ajouter l'XP du jour
      final dayXpKey = 'daily_xp_$todayKey';
      final currentDayXp = p.getInt(dayXpKey) ?? 0;
      await p.setInt(dayXpKey, currentDayXp + xpAwarded);

      // 2. Ajouter l'XP totale
      final currentTotalXp = p.getInt('total_xp') ?? 0;
      await p.setInt('total_xp', currentTotalXp + xpAwarded);

      // 3. Ajouter les diamants
      final currentGems = p.getInt('total_gems') ?? 0;
      await p.setInt('total_gems', currentGems + diamondsAwarded);
    }

    // 4. Valider l'activité pour la série
    await markDailyStreakActivity(db: database, prefs: p);

    return (
      xpAwarded: xpAwarded,
      diamondsAwarded: diamondsAwarded,
      isCapped: isCapped,
      stars: stars,
    );
  }

  /// Attribue une récompense bonus immédiate (ex: Mot d'Or trouvé)
  Future<void> awardBonusReward({
    required int xp,
    required int diamonds,
    SharedPreferences? prefs,
  }) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayKey = '${now.year}_${now.month}_${now.day}';

    // 1. XP du jour
    final dayXpKey = 'daily_xp_$todayKey';
    final currentDayXp = p.getInt(dayXpKey) ?? 0;
    await p.setInt(dayXpKey, currentDayXp + xp);

    // 2. XP totale
    final currentTotalXp = p.getInt('total_xp') ?? 0;
    await p.setInt('total_xp', currentTotalXp + xp);

    // 3. Diamants
    final currentGems = p.getInt('total_gems') ?? 0;
    await p.setInt('total_gems', currentGems + diamonds);
  }

  /// Récupère le solde actuel de diamants
  Future<int> getDiamondsBalance({SharedPreferences? prefs}) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    return p.getInt('total_gems') ?? 0;
  }

  /// Déduit des diamants pour l'achat d'un indice
  Future<bool> spendDiamonds(int amount, {SharedPreferences? prefs}) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    final current = p.getInt('total_gems') ?? 0;
    if (current >= amount) {
      await p.setInt('total_gems', current - amount);
      return true;
    }
    return false;
  }

  /// Détermine si une publicité interstitielle doit être affichée (max tous les 3 niveaux complétés)
  /// Toujours désactivée pour les membres Hoppla Pro et l'Administrateur
  Future<bool> shouldShowInterstitialAd({SharedPreferences? prefs}) async {
    if (SubscriptionService.instance.isPremium) {
      return false; // Zéro publicité pour les abonnés et l'administrateur
    }
    final p = prefs ?? await SharedPreferences.getInstance();
    final levelsSinceLastAd = (p.getInt('raetsel_levels_since_last_ad') ?? 0) + 1;
    if (levelsSinceLastAd >= RaetselConstants.interstitialAdLevelInterval) {
      await p.setInt('raetsel_levels_since_last_ad', 0);
      return true;
    } else {
      await p.setInt('raetsel_levels_since_last_ad', levelsSinceLastAd);
      return false;
    }
  }

  /// Marque un niveau comme terminé et avance au suivant
  Future<int> advanceToNextLevel({SharedPreferences? prefs}) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    final current = await getCurrentLevelNumber(prefs: p);
    final next = current + 1;
    await p.setInt(keyCurrentLevel, next);
    await clearSavedInProgressLevel(prefs: p);
    return next;
  }
}

