import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/database/app_database.dart';
import '../../../domain/models/phrase.dart';
import '../../../domain/models/topic.dart';
import '../../../domain/models/user_phrase.dart';

import '../../../domain/models/discreet_badge.dart';

/// Statistique de performance sur une phrase ayant échoué (Section 8 du plan).
class PhraseFailureStat {
  final Phrase phrase;
  final int lapses; // nb_erreurs dans la table progression
  final int reps; // nb_bonnes dans la table progression
  final int level; // niveau de maîtrise (0 à 7)
  final bool isDifficult; // >= 4 erreurs

  const PhraseFailureStat({
    required this.phrase,
    required this.lapses,
    required this.reps,
    required this.level,
    required this.isDifficult,
  });
}

class TopicProgressItem {
  final TopicInfo topic;
  final int totalCount;
  final int startedCount;
  final int masteredCount;
  final int acquiredCount; // Phrases Niveau 7 (Section 8 du plan)

  const TopicProgressItem({
    required this.topic,
    required this.totalCount,
    required this.startedCount,
    required this.masteredCount,
    this.acquiredCount = 0,
  });

  double get progressRatio => totalCount > 0 ? startedCount / totalCount : 0.0;
  double get acquiredRatio => totalCount > 0 ? acquiredCount / totalCount : 0.0;
}

class ProgressState {
  final bool isLoading;
  final int totalPhrasesCount;
  final int startedCount;
  final int inProgressCount;
  final int masteredCount;
  final int acquiredCount; // Phrases Niveau 7 (Section 4 & 7.4)
  final int newUnstartedCount;
  final List<Phrase> watchlistPhrases;
  final int streakDays;
  final bool freezeAvailable; // Gel de série disponible cette semaine
  final int totalPracticeMinutes;
  final List<bool> last7DaysActive; // 7 jours passés (true si au moins une séance ce jour-là)
  final List<TopicProgressItem> topicProgress;
  final List<DiscreetBadge> badges; // 5 badges discrets (Section 7.4)
  final List<PhraseFailureStat> mostFailedPhrases; // Phrases qui échouent le plus souvent (Section 8)
  final bool userActiveDay3; // Rétention Jour 3 (Section 8)
  final bool userActiveDay7; // Rétention Jour 7 (Section 8)
  final int weeklyReviewedCount; // Phrases révisées cette semaine (Section 7.3)
  final int weeklyPromotedCount; // Phrases montées en niveau cette semaine (Section 7.3)
  final int weeklyPracticeMinutes; // Temps de pratique cette semaine (Section 7.3)

  const ProgressState({
    this.isLoading = true,
    this.totalPhrasesCount = 0,
    this.startedCount = 0,
    this.inProgressCount = 0,
    this.masteredCount = 0,
    this.acquiredCount = 0,
    this.newUnstartedCount = 0,
    this.watchlistPhrases = const [],
    this.streakDays = 1,
    this.freezeAvailable = true,
    this.totalPracticeMinutes = 0,
    this.last7DaysActive = const [false, false, false, false, false, false, true],
    this.topicProgress = const [],
    this.badges = const [],
    this.mostFailedPhrases = const [],
    this.userActiveDay3 = false,
    this.userActiveDay7 = false,
    this.weeklyReviewedCount = 0,
    this.weeklyPromotedCount = 0,
    this.weeklyPracticeMinutes = 0,
  });

  double get globalProgressRatio =>
      totalPhrasesCount > 0 ? startedCount / totalPhrasesCount : 0.0;

  double get masteryRatio =>
      totalPhrasesCount > 0 ? masteredCount / totalPhrasesCount : 0.0;

  ProgressState copyWith({
    bool? isLoading,
    int? totalPhrasesCount,
    int? startedCount,
    int? inProgressCount,
    int? masteredCount,
    int? acquiredCount,
    int? newUnstartedCount,
    List<Phrase>? watchlistPhrases,
    int? streakDays,
    bool? freezeAvailable,
    int? totalPracticeMinutes,
    List<bool>? last7DaysActive,
    List<TopicProgressItem>? topicProgress,
    List<DiscreetBadge>? badges,
    List<PhraseFailureStat>? mostFailedPhrases,
    bool? userActiveDay3,
    bool? userActiveDay7,
    int? weeklyReviewedCount,
    int? weeklyPromotedCount,
    int? weeklyPracticeMinutes,
  }) {
    return ProgressState(
      isLoading: isLoading ?? this.isLoading,
      totalPhrasesCount: totalPhrasesCount ?? this.totalPhrasesCount,
      startedCount: startedCount ?? this.startedCount,
      inProgressCount: inProgressCount ?? this.inProgressCount,
      masteredCount: masteredCount ?? this.masteredCount,
      acquiredCount: acquiredCount ?? this.acquiredCount,
      newUnstartedCount: newUnstartedCount ?? this.newUnstartedCount,
      watchlistPhrases: watchlistPhrases ?? this.watchlistPhrases,
      streakDays: streakDays ?? this.streakDays,
      freezeAvailable: freezeAvailable ?? this.freezeAvailable,
      totalPracticeMinutes: totalPracticeMinutes ?? this.totalPracticeMinutes,
      last7DaysActive: last7DaysActive ?? this.last7DaysActive,
      topicProgress: topicProgress ?? this.topicProgress,
      badges: badges ?? this.badges,
      mostFailedPhrases: mostFailedPhrases ?? this.mostFailedPhrases,
      userActiveDay3: userActiveDay3 ?? this.userActiveDay3,
      userActiveDay7: userActiveDay7 ?? this.userActiveDay7,
      weeklyReviewedCount: weeklyReviewedCount ?? this.weeklyReviewedCount,
      weeklyPromotedCount: weeklyPromotedCount ?? this.weeklyPromotedCount,
      weeklyPracticeMinutes: weeklyPracticeMinutes ?? this.weeklyPracticeMinutes,
    );
  }
}

class ProgressController extends StateNotifier<ProgressState> {
  final AppDatabase _database;

  ProgressController({AppDatabase? database})
      : _database = database ?? AppDatabase.instance,
        super(const ProgressState()) {
    loadProgress();
  }

  Future<void> loadProgress() async {
    state = state.copyWith(isLoading: true);

    final phrases = await _database.getAllPhrases();
    final progressMap = await _database.getAllUserPhrases();
    final sessionLogs = await _database.getSessionLogs();
    final totalSec = await _database.getTotalPracticeSeconds();
    final profile = await _database.getUserProfile();

    final streak = profile.serieJours;
    final freezeAvailable = profile.gelSerieDisponible;

    int started = 0;
    int inProgress = 0;
    int mastered = 0;
    int acquired = 0;
    final watchlist = <Phrase>[];

    for (final phrase in phrases) {
      final prog = progressMap[phrase.id];
      if (prog != null) {
        if (prog.level > 0 || prog.reps > 0) {
          started++;
          if (prog.level >= 7) {
            acquired++;
            mastered++;
          } else if (prog.level >= 6) {
            mastered++;
          } else {
            inProgress++;
          }
        }
        if (prog.status == UserPhraseStatus.aSurveiller ||
            prog.isDifficult ||
            prog.lapses >= 4 ||
            prog.lastResult == false ||
            prog.consecutiveErrors > 0) {
          watchlist.add(phrase);
        }
      }
    }

    final newCount = (phrases.length - started).clamp(0, phrases.length);

    // Activité des 7 derniers jours
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final last7Days = List.generate(7, (i) {
      final targetDate = now.subtract(Duration(days: 6 - i));
      final dateStr =
          "${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}";
      return sessionLogs.any((log) =>
          (log['session_date'] as String?)?.startsWith(dateStr) ?? false);
    });

    if (last7Days.every((active) => !active)) {
      last7Days[6] = true;
    }

    // Statistiques de la semaine passée (Section 7.3)
    final weeklyLogs = sessionLogs.where((log) {
      final dateStr = log['session_date'] as String?;
      if (dateStr == null) return false;
      final date = DateTime.tryParse(dateStr);
      return date != null && date.isAfter(sevenDaysAgo);
    }).toList();

    final weeklyReviews = weeklyLogs.fold<int>(
        0, (sum, log) => sum + ((log['review_count'] as int?) ?? 0));
    final weeklySec = weeklyLogs.fold<int>(
        0, (sum, log) => sum + ((log['duration_sec'] as int?) ?? 0));
    final weeklyMinutes = (weeklySec / 60).ceil();
    final weeklyPromoted = progressMap.values.where((p) => p.level >= 2).length;

    // Badges discrets (Section 7.4)
    final badges = DiscreetBadge.evaluateAll(
      acquiredPhrasesCount: acquired,
      streakDays: streak,
    );

    // Répartition par thème avec phrases acquises au Niveau 7 (Section 8)
    final topicItems = TopicInfo.allTopics.map((topic) {
      final topicPhrases = phrases.where((p) => p.topic == topic.id).toList();
      int tStarted = 0;
      int tMastered = 0;
      int tAcquired = 0;
      for (final p in topicPhrases) {
        final prog = progressMap[p.id];
        if (prog != null && (prog.level > 0 || prog.reps > 0)) {
          tStarted++;
          if (prog.level >= 7) tAcquired++;
          if (prog.level >= 6) tMastered++;
        }
      }
      return TopicProgressItem(
        topic: topic,
        totalCount: topicPhrases.length,
        startedCount: tStarted,
        masteredCount: tMastered,
        acquiredCount: tAcquired,
      );
    }).toList();

    // Top des phrases qui échouent le plus souvent (Section 8)
    final failureStats = <PhraseFailureStat>[];
    for (final phrase in phrases) {
      final prog = progressMap[phrase.id];
      if (prog != null && prog.lapses > 0) {
        failureStats.add(PhraseFailureStat(
          phrase: phrase,
          lapses: prog.lapses,
          reps: prog.reps,
          level: prog.level,
          isDifficult: prog.isDifficult || prog.lapses >= 4,
        ));
      }
    }
    failureStats.sort((a, b) => b.lapses.compareTo(a.lapses));

    // Rétention Jour 3 et Jour 7 (Section 8)
    final bool activeDay3 = streak >= 3 || sessionLogs.length >= 3;
    final bool activeDay7 = streak >= 7 || sessionLogs.length >= 7;

    state = state.copyWith(
      isLoading: false,
      totalPhrasesCount: phrases.length,
      startedCount: started,
      inProgressCount: inProgress,
      masteredCount: mastered,
      acquiredCount: acquired,
      newUnstartedCount: newCount,
      watchlistPhrases: watchlist,
      streakDays: streak,
      freezeAvailable: freezeAvailable,
      totalPracticeMinutes: (totalSec / 60).ceil(),
      last7DaysActive: last7Days,
      topicProgress: topicItems,
      badges: badges,
      mostFailedPhrases: failureStats,
      userActiveDay3: activeDay3,
      userActiveDay7: activeDay7,
      weeklyReviewedCount: weeklyReviews,
      weeklyPromotedCount: weeklyPromoted,
      weeklyPracticeMinutes: weeklyMinutes,
    );
  }
}

final progressControllerProvider =
    StateNotifierProvider.autoDispose<ProgressController, ProgressState>((ref) {
  return ProgressController();
});
