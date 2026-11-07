import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/database/app_database.dart';
import '../../../domain/engine/srs_engine.dart';
import '../../../domain/models/phrase.dart';
import '../../../domain/models/topic.dart';
import '../../../domain/models/user_phrase.dart';
import '../../../domain/models/user_profile.dart';

class TopicStats {
  final TopicInfo topic;
  final int totalCount;
  final int learnedCount;
  final int masteredCount;
  final bool isUnlocked;

  const TopicStats({
    required this.topic,
    required this.totalCount,
    required this.learnedCount,
    required this.masteredCount,
    required this.isUnlocked,
  });

  double get progressRatio => totalCount > 0 ? learnedCount / totalCount : 0.0;
}

class LibraryState {
  final bool isLoading;
  final List<Phrase> allPhrases;
  final Map<String, UserPhrase> userProgress;
  final String searchQuery;
  final String selectedStatusFilter; // 'all', 'new', 'in_progress', 'solid', 'mastered', 'watchlist' / 'difficult'
  final Set<String> unlockedTopicIds;
  final UserProfile userProfile;

  const LibraryState({
    this.isLoading = true,
    this.allPhrases = const [],
    this.userProgress = const {},
    this.searchQuery = '',
    this.selectedStatusFilter = 'all',
    this.unlockedTopicIds = const {},
    this.userProfile = const UserProfile(),
  });

  LibraryState copyWith({
    bool? isLoading,
    List<Phrase>? allPhrases,
    Map<String, UserPhrase>? userProgress,
    String? searchQuery,
    String? selectedStatusFilter,
    Set<String>? unlockedTopicIds,
    UserProfile? userProfile,
  }) {
    return LibraryState(
      isLoading: isLoading ?? this.isLoading,
      allPhrases: allPhrases ?? this.allPhrases,
      userProgress: userProgress ?? this.userProgress,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedStatusFilter: selectedStatusFilter ?? this.selectedStatusFilter,
      unlockedTopicIds: unlockedTopicIds ?? this.unlockedTopicIds,
      userProfile: userProfile ?? this.userProfile,
    );
  }

  /// Liste des phrases filtrées selon la recherche multilingue et le statut SRS.
  List<Phrase> get filteredPhrases {
    return allPhrases.where((phrase) {
      // 1. Filtre textuel multilingue (Allemand parlé, standard, arabe, français ou note)
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase().trim();
        final matchDeParle = phrase.deParle.toLowerCase().contains(query);
        final matchDeStandard = phrase.deStandard.toLowerCase().contains(query);
        final matchDe = phrase.de.toLowerCase().contains(query);
        final matchAr = (phrase.ar ?? '').toLowerCase().contains(query);
        final matchFr = phrase.fr.toLowerCase().contains(query);
        final matchNote = (phrase.note ?? '').toLowerCase().contains(query);
        if (!matchDeParle && !matchDeStandard && !matchDe && !matchAr && !matchFr && !matchNote) {
          return false;
        }
      }

      // 2. Filtre par statut SRS
      final progress = userProgress[phrase.id];
      final isDifficult = progress != null &&
          (progress.isDifficult || progress.lapses >= 4 || progress.status == UserPhraseStatus.aSurveiller);

      switch (selectedStatusFilter) {
        case 'new':
          return progress == null || (progress.level == 0 && progress.reps == 0);
        case 'in_progress':
          return progress != null &&
              progress.level >= 1 &&
              progress.level <= 3 &&
              !isDifficult;
        case 'solid':
          return progress != null &&
              progress.level >= 4 &&
              progress.level < 6 &&
              !isDifficult;
        case 'mastered':
          return progress != null && progress.level >= 6;
        case 'difficult':
        case 'watchlist':
          return isDifficult;
        case 'all':
        default:
          return true;
      }
    }).toList();
  }

  /// Statistiques par thème (compte, complétion et déblocage doux / thèmes prioritaires).
  List<TopicStats> get topicStatsList {
    final list = <TopicStats>[];

    for (int i = 0; i < TopicInfo.allTopics.length; i++) {
      final topic = TopicInfo.allTopics[i];
      final topicPhrases = allPhrases.where((p) => p.topic == topic.id).toList();
      final total = topicPhrases.length;

      int learned = 0;
      int mastered = 0;
      for (final p in topicPhrases) {
        final up = userProgress[p.id];
        if (up != null && (up.level > 0 || up.reps > 0)) {
          learned++;
          if (up.level >= 7) mastered++;
        }
      }

      // Déblocage doux (Section 6 & 7) :
      // - Les 3 premiers thèmes sont toujours débloqués dès le départ.
      // - Les thèmes prioritaires choisis par l'utilisateur sont débloqués.
      // - Débloqué si le thème précédent a au moins 3 phrases apprises
      //   OU si l'utilisateur a appuyé sur "Débloquer quand même".
      bool isUnlocked = i < 3 ||
          unlockedTopicIds.contains(topic.id) ||
          userProfile.priorityThemes.contains(topic.id);

      if (!isUnlocked && i > 0) {
        final prevStats = list[i - 1];
        if (prevStats.learnedCount >= 3 || prevStats.progressRatio >= 0.3) {
          isUnlocked = true;
        }
      }

      list.add(TopicStats(
        topic: topic,
        totalCount: total,
        learnedCount: learned,
        masteredCount: mastered,
        isUnlocked: isUnlocked,
      ));
    }

    return list;
  }
}

class LibraryController extends StateNotifier<LibraryState> {
  final AppDatabase _database = AppDatabase.instance;
  static const String _prefUnlockedTopicsKey = 'user_unlocked_topics';

  LibraryController() : super(const LibraryState()) {
    loadData();
  }

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true);
    final phrases = await _database.getAllPhrases();
    final progress = await _database.getAllProgression();
    final profile = await _database.getUserProfile();
    await _database.getAllTopics();

    final prefs = await SharedPreferences.getInstance();
    final unlockedList = prefs.getStringList(_prefUnlockedTopicsKey) ?? [];
    final unlockedSet = unlockedList.toSet()..addAll(profile.priorityThemes);

    state = state.copyWith(
      isLoading: false,
      allPhrases: phrases,
      userProgress: progress,
      unlockedTopicIds: unlockedSet,
      userProfile: profile,
    );
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setStatusFilter(String filter) {
    state = state.copyWith(selectedStatusFilter: filter);
  }

  Future<void> unlockTopic(String topicId) async {
    final updated = Set<String>.from(state.unlockedTopicIds)..add(topicId);
    state = state.copyWith(unlockedTopicIds: updated);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefUnlockedTopicsKey, updated.toList());
  }

  /// Marque une phrase comme connue / « Trop facile » (Règle 4 : saute au niveau 4, révision à 7 jours).
  Future<void> markPhraseAsKnown(String phraseId) async {
    final current = state.userProgress[phraseId] ??
        UserPhrase(phraseId: phraseId, dueAt: DateTime.now());
    final updated = const SrsEngine().markAsTooEasy(current);
    await _database.saveProgression(updated);

    final updatedMap = Map<String, UserPhrase>.from(state.userProgress);
    updatedMap[phraseId] = updated;
    state = state.copyWith(userProgress: updatedMap);
  }
}

final libraryControllerProvider =
    StateNotifierProvider.autoDispose<LibraryController, LibraryState>((ref) {
  return LibraryController();
});
