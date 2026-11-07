import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/supabase_client.dart';
import '../../../core/services/audio_recording_service.dart';
import '../../../core/services/pronunciation_service.dart';
import '../../../core/services/tts_service.dart';
import '../../../data/database/app_database.dart';
import '../../../domain/engine/session_builder.dart';
import '../../../domain/engine/srs_engine.dart';
import '../../../domain/models/phrase.dart';
import '../../../domain/models/topic.dart';
import '../../../domain/models/user_phrase.dart';

/// Statut du déroulement de la séance.
enum SessionStatus {
  loading,
  inProgress,
  completed,
}

/// Étape de shadowing pour une nouvelle phrase.
enum ShadowingPhase {
  listenModel,
  userRepeating,
  reviewingPlayback,
  completed,
}

class SessionState {
  final SessionStatus status;
  final DailySession? session;
  final int currentIndex;
  final int shadowingStep;
  final ShadowingPhase shadowingPhase;
  final bool isTtsPlaying;
  final bool isRecording;
  final bool isPlayingUserVoice;
  final DateTime startTime;
  final int reviewedCount;
  final int newLearnedCount;
  final bool isShowingFeedback;
  final bool lastAnswerSuccess;
  final bool lastAnswerHasMinorTypo;
  final String? feedbackRating;

  /// Étape courante de présentation d'une nouvelle phrase (1–4, Section 3.3).
  final int currentLearningStep;

  /// Sous-étape du mini-test de l'écran 4 (0: Recomposer, 1: Trous clavier, 2: QCM).
  final int currentTestSubStep;

  /// Mode Express (2 min, uniquement les révisions dues, Section 3).
  final bool isExpressMode;

  /// Phase Erreurs active (rejoue les cartes manquées à la fin jusqu'à succès, Section 3.4).
  final bool isErrorPhase;

  /// File d'attente des erreurs de la session à repasser.
  final List<SessionItem> errorQueue;

  /// Compteurs de tentatives pour le taux de réussite (Section 3.5).
  final int totalAttempts;
  final int correctAttempts;

  /// Série de jours consécutifs sauvegardée (Section 3.5 & 7).
  final int streakDays;

  /// Indique si le gel de série a été utilisé pour sauver la série (Section 7.1).
  final bool streakFreezeUsed;

  /// Indique si la série a été brisée et recommence sans culpabiliser (Section 7.1).
  final bool streakReset;

  /// Date de la prochaine révision calculée (Section 3.5).
  final DateTime? nextReviewDate;

  const SessionState({
    required this.status,
    this.session,
    this.currentIndex = 0,
    this.shadowingStep = 1,
    this.shadowingPhase = ShadowingPhase.listenModel,
    this.isTtsPlaying = false,
    this.isRecording = false,
    this.isPlayingUserVoice = false,
    required this.startTime,
    this.reviewedCount = 0,
    this.newLearnedCount = 0,
    this.isShowingFeedback = false,
    this.lastAnswerSuccess = true,
    this.lastAnswerHasMinorTypo = false,
    this.feedbackRating,
    this.currentLearningStep = 1,
    this.currentTestSubStep = 0,
    this.isExpressMode = false,
    this.isErrorPhase = false,
    this.errorQueue = const [],
    this.totalAttempts = 0,
    this.correctAttempts = 0,
    this.streakDays = 0,
    this.streakFreezeUsed = false,
    this.streakReset = false,
    this.nextReviewDate,
  });

  SessionItem? get currentItem {
    if (session == null || currentIndex >= session!.items.length) return null;
    return session!.items[currentIndex];
  }

  double get progressRatio {
    if (session == null || session!.totalCount == 0) return 0.0;
    return currentIndex / session!.totalCount;
  }

  int get elapsedMinutes {
    final diff = DateTime.now().difference(startTime).inSeconds;
    return (diff / 60).ceil().clamp(1, 120);
  }

  int get successRate {
    if (totalAttempts <= 0) return 100;
    return ((correctAttempts / totalAttempts) * 100).round().clamp(0, 100);
  }

  SessionState copyWith({
    SessionStatus? status,
    DailySession? session,
    int? currentIndex,
    int? shadowingStep,
    ShadowingPhase? shadowingPhase,
    bool? isTtsPlaying,
    bool? isRecording,
    bool? isPlayingUserVoice,
    DateTime? startTime,
    int? reviewedCount,
    int? newLearnedCount,
    bool? isShowingFeedback,
    bool? lastAnswerSuccess,
    bool? lastAnswerHasMinorTypo,
    String? feedbackRating,
    int? currentLearningStep,
    int? currentTestSubStep,
    bool? isExpressMode,
    bool? isErrorPhase,
    List<SessionItem>? errorQueue,
    int? totalAttempts,
    int? correctAttempts,
    int? streakDays,
    bool? streakFreezeUsed,
    bool? streakReset,
    DateTime? nextReviewDate,
  }) {
    return SessionState(
      status: status ?? this.status,
      session: session ?? this.session,
      currentIndex: currentIndex ?? this.currentIndex,
      shadowingStep: shadowingStep ?? this.shadowingStep,
      shadowingPhase: shadowingPhase ?? this.shadowingPhase,
      isTtsPlaying: isTtsPlaying ?? this.isTtsPlaying,
      isRecording: isRecording ?? this.isRecording,
      isPlayingUserVoice: isPlayingUserVoice ?? this.isPlayingUserVoice,
      startTime: startTime ?? this.startTime,
      reviewedCount: reviewedCount ?? this.reviewedCount,
      newLearnedCount: newLearnedCount ?? this.newLearnedCount,
      isShowingFeedback: isShowingFeedback ?? this.isShowingFeedback,
      lastAnswerSuccess: lastAnswerSuccess ?? this.lastAnswerSuccess,
      lastAnswerHasMinorTypo: lastAnswerHasMinorTypo ?? this.lastAnswerHasMinorTypo,
      feedbackRating: feedbackRating ?? this.feedbackRating,
      currentLearningStep: currentLearningStep ?? this.currentLearningStep,
      currentTestSubStep: currentTestSubStep ?? this.currentTestSubStep,
      isExpressMode: isExpressMode ?? this.isExpressMode,
      isErrorPhase: isErrorPhase ?? this.isErrorPhase,
      errorQueue: errorQueue ?? this.errorQueue,
      totalAttempts: totalAttempts ?? this.totalAttempts,
      correctAttempts: correctAttempts ?? this.correctAttempts,
      streakDays: streakDays ?? this.streakDays,
      streakFreezeUsed: streakFreezeUsed ?? this.streakFreezeUsed,
      streakReset: streakReset ?? this.streakReset,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
    );
  }
}

class SessionController extends StateNotifier<SessionState> {
  final AppDatabase _database = AppDatabase.instance;
  final SrsEngine _srsEngine = const SrsEngine();
  final TtsService _tts = TtsService.instance;
  final AudioRecordingService _audio = AudioRecordingService.instance;
  final List<SessionItem> _internalErrorQueue = [];

  SessionController({bool isExpressMode = false})
      : super(SessionState(
          status: SessionStatus.loading,
          startTime: DateTime.now(),
          isExpressMode: isExpressMode,
        )) {
    // Note: initSession() est appelé explicitement avec les targetPhraseIds par SessionScreen
    _listenAudioState();
  }

  int _sessionInitCounter = 0;

  void _listenAudioState() {
    _tts.isPlayingNotifier.addListener(() {
      state = state.copyWith(isTtsPlaying: _tts.isPlaying);
    });
    _audio.isRecordingNotifier.addListener(() {
      state = state.copyWith(isRecording: _audio.isRecording);
    });
    _audio.isPlayingRecordingNotifier.addListener(() {
      state = state.copyWith(isPlayingUserVoice: _audio.isPlayingRecording);
    });
  }

  /// Initialise la séance quotidienne selon les règles de la Section 3 du plan :
  /// 1. Phase Révision (due, plafonnée à 60).
  /// 2. Phase Nouveautés (5, 10, 20 selon objectif quotidien, désactivée en mode express ou rattrapage).
  Future<void> initSession({bool isExpressMode = false, List<String>? targetPhraseIds}) async {
    final currentInitId = ++_sessionInitCounter;
    // Arrêter immédiatement tout audio résiduel avant d'initialiser la nouvelle séance
    await _tts.stop();
    await _audio.stopPlayback();

    state = state.copyWith(status: SessionStatus.loading, isExpressMode: isExpressMode);

    final profile = await _database.getUserProfile();
    final phrases = await _database.getAllPhrases();
    final progress = await _database.getAllUserPhrases();

    final DailySession dailySession;
    if (targetPhraseIds != null && targetPhraseIds.isNotEmpty) {
      final phraseMap = {for (final p in phrases) p.id: p};
      final targetPhrases = targetPhraseIds.map((id) => phraseMap[id]).whereType<Phrase>().toList();
      final builder = const SessionBuilder();
      int reviewCount = 0;
      int newCount = 0;
      final items = targetPhrases.map((phrase) {
        final userProg = progress[phrase.id] ??
            UserPhrase(
              phraseId: phrase.id,
              level: 0,
              dueAt: DateTime.now(),
              status: UserPhraseStatus.nouvelle,
            );
        final bool isAlreadyLearned = userProg.level > 0 || userProg.reps > 0 || userProg.lapses > 0;
        final itemType = isAlreadyLearned ? SessionItemType.review : SessionItemType.newPhrase;
        if (isAlreadyLearned) {
          reviewCount++;
        } else {
          newCount++;
        }
        final exType = isAlreadyLearned
            ? builder.resolveExerciseType(userProg.level, SessionItemType.review)
            : ExerciseType.newPhrase;
        final choices = builder.buildChoices(phrase, phrases);
        return SessionItem(
          phrase: phrase,
          userPhrase: userProg,
          itemType: itemType,
          exerciseType: exType,
          choices: choices,
        );
      }).toList();
      dailySession = DailySession(
        items: items,
        warmupCount: 0,
        reviewCount: reviewCount,
        newCount: newCount,
        isExpressMode: isExpressMode,
      );
    } else {
      final dailyNew = isExpressMode ? 0 : profile.objectifQuotidien;
      final sessionBuilder = const SessionBuilder();
      dailySession = sessionBuilder.buildSession(
        allPhrases: phrases,
        progressMap: progress,
        dailyNewTarget: dailyNew,
        priorityThemes: profile.themesPrioritaires,
        isExpressMode: isExpressMode,
      );
    }

    _internalErrorQueue.clear();

    if (dailySession.items.isEmpty) {
      state = state.copyWith(
        status: SessionStatus.completed,
        session: dailySession,
        streakDays: profile.serieJours,
      );
      return;
    }

    if (currentInitId != _sessionInitCounter) return;

    state = state.copyWith(
      status: SessionStatus.inProgress,
      session: dailySession,
      currentIndex: 0,
      shadowingStep: 1,
      shadowingPhase: ShadowingPhase.listenModel,
      currentLearningStep: 1,
      startTime: DateTime.now(),
      streakDays: profile.serieJours,
      isExpressMode: isExpressMode,
      isErrorPhase: false,
      errorQueue: const [],
      totalAttempts: 0,
      correctAttempts: 0,
      reviewedCount: 0,
      newLearnedCount: 0,
    );

    if (currentInitId != _sessionInitCounter) return;
    _playCurrentModel();
  }

  /// Écouter la phrase courante en allemand.
  Future<void> playTts({bool slow = false, VoidCallback? onDone}) async {
    final item = state.currentItem;
    if (item == null) return;
    await _tts.speak(
      item.phrase.de,
      phraseId: item.phrase.id,
      slow: slow,
      onDone: onDone,
    );
  }

  /// Joue la phrase à une vitesse exacte.
  Future<void> playTtsAtSpeed(double speed) async {
    final item = state.currentItem;
    if (item == null) return;
    await _tts.speak(
      item.phrase.de,
      phraseId: item.phrase.id,
      customRate: speed,
    );
  }

  /// Avance d'un écran dans le tunnel de présentation d'une nouvelle phrase (1..4, Section 3.3).
  void advanceLearningStep() {
    final step = state.currentLearningStep;
    if (step < 4) {
      setLearningStep(step + 1);
    }
  }

  /// Recule d'un écran dans le tunnel de présentation d'une nouvelle phrase (1..4, Section 3.3).
  void previousLearningStep() {
    final step = state.currentLearningStep;
    if (step > 1) {
      setLearningStep(step - 1);
    }
  }

  /// Change directement l'écran dans le tunnel de présentation d'une nouvelle phrase (1..4).
  void setLearningStep(int targetStep) {
    if (targetStep >= 1 && targetStep <= 4) {
      state = state.copyWith(
        currentLearningStep: targetStep,
        currentTestSubStep: 0,
      );
      if (targetStep == 3) {
        // Étape audio : jouer automatiquement le modèle
        playTts(slow: false);
      }
    }
  }

  /// Change le sous-test de l'écran 4 (0: Recomposer, 1: Trous clavier, 2: QCM).
  void setTestSubStep(int subStep) {
    state = state.copyWith(currentTestSubStep: subStep.clamp(0, 2));
  }

  void _playCurrentModel() {
    final item = state.currentItem;
    if (item == null) return;
    playTts(slow: false);
  }

  /// Démarre ou arrête l'enregistrement micro du shadowing.
  Future<void> toggleRecording() async {
    if (state.isRecording) {
      final path = await _audio.stopRecording();
      state = state.copyWith(shadowingPhase: ShadowingPhase.reviewingPlayback);

      if (path != null) {
        await _audio.playRecording(
          path: path,
          onDone: () async {
            await Future.delayed(const Duration(milliseconds: 300));
            await playTts(slow: false);
          },
        );
      }
    } else {
      await _tts.stop();
      final started = await _audio.startRecording();
      if (started) {
        state = state.copyWith(shadowingPhase: ShadowingPhase.userRepeating);
      }
    }
  }

  /// Passe à l'étape suivante de shadowing (1 -> 2 -> 3) ou termine la phrase.
  void nextShadowingStep() {
    if (state.shadowingStep < 3) {
      state = state.copyWith(
        shadowingStep: state.shadowingStep + 1,
        shadowingPhase: ShadowingPhase.listenModel,
      );
      _playCurrentModel();
    } else {
      _completeCurrentPhrase(ReviewOutcome.success);
    }
  }

  ReviewOutcome? _pendingOutcome;

  /// Évalue la réponse à un exercice interactif, déclenche le retour doux et rejoue le modèle.
  Future<void> evaluateExerciseAnswer({
    required bool isSuccess,
    bool hasMinorTypo = false,
    ReviewOutcome? customOutcome,
  }) async {
    _pendingOutcome = customOutcome ??
        (isSuccess ? ReviewOutcome.success : ReviewOutcome.mistake);

    state = state.copyWith(
      isShowingFeedback: true,
      lastAnswerSuccess: isSuccess,
      lastAnswerHasMinorTypo: hasMinorTypo,
      totalAttempts: state.totalAttempts + 1,
      correctAttempts: isSuccess ? state.correctAttempts + 1 : state.correctAttempts,
    );

    // Jouer le carillon de validation ou le son d'échec (falsch)
    if (isSuccess) {
      PronunciationService.instance.playSuccessSound();
    } else {
      PronunciationService.instance.playFailureSound();
    }
    // Note: L'écoute de la phrase reste disponible à la demande via le bouton audio du FeedbackSheet,
    // sans auto-lecture pour éviter tout chevauchement avec la phrase suivante au clic sur "Continuer".
  }

  /// Ferme la feuille de feedback sans forcer l'avancement
  void dismissFeedback() {
    _tts.stop();
    state = state.copyWith(isShowingFeedback: false);
  }

  bool _isAdvancingPhrase = false;

  /// Poursuit la séance après la prise de connaissance du retour bienveillant.
  Future<void> continueAfterFeedback() async {
    if (_isAdvancingPhrase) return;
    _isAdvancingPhrase = true;
    try {
      // 1. Coupure immédiate et absolue de tout son résiduel
      await _tts.stop();
      await _audio.stopPlayback();

      final outcome = _pendingOutcome ?? ReviewOutcome.success;
      state = state.copyWith(isShowingFeedback: false);

      // Enchaînement automatique des 3 sous-tests de l'écran 4 (Mini-test) :
      // 0: Recomposer -> 1: Trous clavier -> 2: QCM -> phrase suivante
      final item = state.currentItem;
      if (item != null &&
          item.exerciseType == ExerciseType.newPhrase &&
          state.currentLearningStep == 4 &&
          state.currentTestSubStep < 2) {
        state = state.copyWith(currentTestSubStep: state.currentTestSubStep + 1);
        return;
      }

      await answerPhrase(outcome, alreadyCountedAttempt: true);
    } finally {
      _isAdvancingPhrase = false;
    }
  }

  /// Évalue la réponse courante et avance dans la séance.
  Future<void> answerPhrase(
    ReviewOutcome outcome, {
    bool alreadyCountedAttempt = false,
  }) async {
    await _tts.stop();
    await _audio.stopPlayback();

    if (!alreadyCountedAttempt) {
      final isSuccess = outcome == ReviewOutcome.success || outcome == ReviewOutcome.easy;
      state = state.copyWith(
        totalAttempts: state.totalAttempts + 1,
        correctAttempts: isSuccess ? state.correctAttempts + 1 : state.correctAttempts,
      );
    }

    await _completeCurrentPhrase(outcome);
  }

  Future<void> _completeCurrentPhrase(ReviewOutcome outcome) async {
    final item = state.currentItem;
    if (item == null) return;

    final isSuccess = outcome == ReviewOutcome.success || outcome == ReviewOutcome.easy;

    // 1. Mise à jour du moteur SRS
    final updated = _srsEngine.processAttempt(item.userPhrase, outcome);
    await _database.saveUserPhrase(updated);

    // 1.1 Enregistrement de l'essai dans la table des tentatives
    await _database.recordAttempt(
      phraseId: item.phrase.id,
      exerciseType: item.exerciseType.name,
      success: isSuccess,
    );

    // 1.2 Synchronisation Cloud immédiate pour le candidat connecté
    if (AppSupabase.isInitialized) {
      final currentUser = AppSupabase.client.auth.currentUser;
      if (currentUser != null) {
        AppSupabase.client.from('user_phrase_progress').upsert({
          'user_id': currentUser.id,
          'phrase_id': updated.phraseId,
          'level': updated.level,
          'reps': updated.reps,
          'lapses': updated.lapses,
          'last_result': updated.lastResult,
          'next_review': updated.dueAt.toIso8601String(),
        }, onConflict: 'user_id, phrase_id').ignore();
      }
    }

    // 2. Gestion de la Phase Erreurs (Section 3.4 & 4.3) :
    // "Les phrases ratées pendant la session reviennent à la fin, une fois chacune, jusqu'à une réponse juste."
    if (!isSuccess) {
      if (!_internalErrorQueue.any((e) => e.phrase.id == item.phrase.id)) {
        _internalErrorQueue.add(item);
      }
    } else if (state.isErrorPhase) {
      // Résolue avec succès dans la phase d'erreurs
      _internalErrorQueue.removeWhere((e) => e.phrase.id == item.phrase.id);
    }

    final isNew = item.itemType == SessionItemType.newPhrase;
    final nextIndex = state.currentIndex + 1;
    final totalInitialCount = state.session?.items.length ?? 0;

    // Mise à jour des compteurs (dans la phase d'erreurs, les révisions ne sont pas recomptées)
    final int updatedReviewed;
    final int updatedNew;
    if (state.isErrorPhase) {
      updatedReviewed = state.reviewedCount;
      updatedNew = state.newLearnedCount + (isNew && isSuccess ? 1 : 0);
    } else {
      updatedReviewed = state.reviewedCount + (isNew ? 0 : 1);
      updatedNew = state.newLearnedCount + (isNew && isSuccess ? 1 : 0);
    }

    // 3. Vérifier s'il reste des cartes dans la séance courante
    if (nextIndex < totalInitialCount) {
      await _tts.stop();
      await _audio.stopPlayback();
      await Future.delayed(const Duration(milliseconds: 120));

      state = state.copyWith(
        currentIndex: nextIndex,
        currentLearningStep: 1,
        currentTestSubStep: 0,
        shadowingStep: 1,
        shadowingPhase: ShadowingPhase.listenModel,
        reviewedCount: updatedReviewed,
        newLearnedCount: updatedNew,
        errorQueue: List.unmodifiable(_internalErrorQueue),
      );
      _playCurrentModel();
    } else {
      // Fin de la file normale : vérifier s'il reste des erreurs à rattraper (Phase Erreurs, Section 3.4)
      if (_internalErrorQueue.isNotEmpty) {
        final errorItems = _internalErrorQueue.map((err) {
          return SessionItem(
            phrase: err.phrase,
            userPhrase: err.userPhrase,
            itemType: err.itemType, // Conserver le type d'origine
            exerciseType: ExerciseType.listenAndChoose,
            choices: err.choices.isNotEmpty
                ? err.choices
                : [
                    err.phrase.ar ?? err.phrase.fr,
                    'Option différente 1',
                    'Option différente 2'
                  ],
          );
        }).toList();

        // Ajouter les erreurs à la fin de la liste des items
        state.session?.items.addAll(errorItems);

        await _tts.stop();
        await _audio.stopPlayback();
        await Future.delayed(const Duration(milliseconds: 120));

        state = state.copyWith(
          isErrorPhase: true,
          currentIndex: nextIndex,
          currentLearningStep: 1,
          reviewedCount: updatedReviewed,
          newLearnedCount: updatedNew,
          errorQueue: List.unmodifiable(_internalErrorQueue),
        );
        _playCurrentModel();
      } else {
        // Séance entièrement terminée !
        state = state.copyWith(
          reviewedCount: updatedReviewed,
          newLearnedCount: updatedNew,
        );
        await _finishSession();
      }
    }
  }

  /// Finalise la séance, met à jour la série de jours consécutifs et journalise les statistiques.
  Future<void> _finishSession() async {
    final now = DateTime.now();
    var profile = await _database.getUserProfile();
    final last = profile.derniereSession;
    int newStreak = profile.serieJours;
    bool gelUsed = false;
    bool streakReset = false;

    if (last == null) {
      newStreak = 1;
    } else {
      final diffDays = DateTime(now.year, now.month, now.day)
          .difference(DateTime(last.year, last.month, last.day))
          .inDays;
      if (diffDays == 0) {
        newStreak = profile.serieJours <= 0 ? 1 : profile.serieJours;
      } else if (diffDays == 1) {
        newStreak = profile.serieJours + 1;
      } else if (diffDays == 2 && profile.gelSerieDisponible) {
        newStreak = profile.serieJours + 1;
        gelUsed = true;
      } else {
        newStreak = 1;
        if (diffDays > 1) {
          streakReset = true;
        }
      }
    }

    final updatedProfile = profile.copyWith(
      serieJours: newStreak,
      derniereSession: now,
      gelSerieDisponible: gelUsed ? false : profile.gelSerieDisponible,
      dateGelUtilise: gelUsed ? now : profile.dateGelUtilise,
    );
    await _database.saveUserProfile(updatedProfile);

    // Calcul de la date de prochaine révision
    final allProgress = await _database.getAllUserPhrases();
    DateTime? nextDate;
    for (final p in allProgress.values) {
      if (nextDate == null || p.dueAt.isBefore(nextDate)) {
        nextDate = p.dueAt;
      }
    }

    // Journal de session SQLite
    try {
      final db = await _database.database;
      await db.insert('session_logs', {
        'session_date': now.toIso8601String(),
        'duration_sec': now.difference(state.startTime).inSeconds,
        'new_count': state.newLearnedCount,
        'review_count': state.reviewedCount,
        'feeling': state.feedbackRating,
      });
    } catch (_) {}

    // Rendre disponible le mode Master XP pour le lot de phrases complété et valider la séance du jour
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('master_xp_available', true);
      await prefs.setBool('session_done_${now.year}_${now.month}_${now.day}', true);
      await prefs.setString('last_session_completed_date', now.toIso8601String());
      final sessionPhraseIds = state.session?.items.map((i) => i.phrase.id).toList() ?? [];
      if (sessionPhraseIds.isNotEmpty) {
        await prefs.setStringList('last_session_phrases', sessionPhraseIds);
        final currentBatch = prefs.getInt('current_batch_index') ?? 0;
        await prefs.setInt('current_batch_index', (currentBatch + 1).clamp(0, 19));
      }
    } catch (_) {}

    state = state.copyWith(
      status: SessionStatus.completed,
      streakDays: newStreak,
      streakFreezeUsed: gelUsed,
      streakReset: streakReset,
      nextReviewDate: nextDate,
    );
  }

  /// Option : Passer aux 10 phrases suivantes (Lot suivant de 10 phrases)
  Future<void> addTenMorePhrases() async {
    final phrases = await _database.getAllPhrases();
    final progress = await _database.getAllUserPhrases();
    final profile = await _database.getUserProfile();
    final currentIds = state.session?.items.map((i) => i.phrase.id).toSet() ?? {};

    // Trouver les 10 nouvelles phrases suivantes non commencées
    final unstarted = phrases.where((p) {
      if (currentIds.contains(p.id)) return false;
      final prog = progress[p.id];
      return prog == null || (prog.level == 0 && prog.reps == 0 && prog.lapses == 0);
    }).toList();

    if (unstarted.isEmpty) return;

    // Prioriser selon thèmes et ordre pédagogique
    unstarted.sort((a, b) {
      final aInPriority = profile.themesPrioritaires.any((t) =>
          a.theme.toLowerCase() == t.toLowerCase() ||
          a.topic.toLowerCase() == t.toLowerCase());
      final bInPriority = profile.themesPrioritaires.any((t) =>
          b.theme.toLowerCase() == t.toLowerCase() ||
          b.topic.toLowerCase() == t.toLowerCase());
      if (aInPriority != bInPriority) return aInPriority ? -1 : 1;
      final orderA = TopicInfo.getById(a.topic).order;
      final orderB = TopicInfo.getById(b.topic).order;
      return orderA.compareTo(orderB);
    });

    final picked = unstarted.take(10).toList();
    final newItems = picked.map((phrase) {
      final userProg = progress[phrase.id] ??
          UserPhrase(
            phraseId: phrase.id,
            level: 0,
            dueAt: DateTime.now(),
            status: UserPhraseStatus.nouvelle,
          );
      return SessionItem(
        phrase: phrase,
        userPhrase: userProg,
        itemType: SessionItemType.newPhrase,
        exerciseType: ExerciseType.newPhrase,
        choices: [phrase.ar ?? phrase.fr, 'Option 1', 'Option 2'],
      );
    }).toList();

    final startIndex = state.session?.items.length ?? 0;
    state.session?.items.addAll(newItems);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('last_session_phrases', picked.map((p) => p.id).toList());
    } catch (_) {}

    state = state.copyWith(
      status: SessionStatus.inProgress,
      currentIndex: startIndex,
      currentLearningStep: 1,
    );

    _playCurrentModel();
  }

  /// Option Section 3.5 : « 5 phrases de plus », jamais imposées.
  Future<void> addFiveMorePhrases() async {
    final phrases = await _database.getAllPhrases();
    final progress = await _database.getAllUserPhrases();
    final profile = await _database.getUserProfile();
    final currentIds = state.session?.items.map((i) => i.phrase.id).toSet() ?? {};

    // Trouver 5 nouvelles phrases non commencées
    final unstarted = phrases.where((p) {
      if (currentIds.contains(p.id)) return false;
      final prog = progress[p.id];
      return prog == null || (prog.level == 0 && prog.reps == 0 && prog.lapses == 0);
    }).toList();

    if (unstarted.isEmpty) return;

    // Prioriser les thèmes prioritaires
    unstarted.sort((a, b) {
      final aInPriority = profile.themesPrioritaires.any((t) =>
          a.theme.toLowerCase() == t.toLowerCase() ||
          a.topic.toLowerCase() == t.toLowerCase());
      final bInPriority = profile.themesPrioritaires.any((t) =>
          b.theme.toLowerCase() == t.toLowerCase() ||
          b.topic.toLowerCase() == t.toLowerCase());
      if (aInPriority != bInPriority) return aInPriority ? -1 : 1;
      return 0;
    });

    final picked = unstarted.take(5).toList();
    final newItems = picked.map((phrase) {
      final userProg = progress[phrase.id] ??
          UserPhrase(
            phraseId: phrase.id,
            level: 0,
            dueAt: DateTime.now(),
            status: UserPhraseStatus.nouvelle,
          );
      return SessionItem(
        phrase: phrase,
        userPhrase: userProg,
        itemType: SessionItemType.newPhrase,
        exerciseType: ExerciseType.newPhrase,
        choices: [phrase.ar ?? phrase.fr, 'Autre option 1', 'Autre option 2'],
      );
    }).toList();

    final startIndex = state.session?.items.length ?? 0;
    state.session?.items.addAll(newItems);

    state = state.copyWith(
      status: SessionStatus.inProgress,
      currentIndex: startIndex,
      currentLearningStep: 1,
    );

    _playCurrentModel();
  }

  /// Enregistre le retour utilisateur (« Trop dur », « Parfait », « Trop facile »)
  /// et ajuste automatiquement le volume de nouvelles phrases quotidiennes (±2, entre 3 et 15).
  Future<void> submitSessionFeedback(String rating) async {
    state = state.copyWith(feedbackRating: rating);

    final prefs = await SharedPreferences.getInstance();
    int currentDaily = prefs.getInt(AppConstants.prefDailyNewPhrases) ??
        AppConstants.defaultDailyNewPhrases;

    if (rating == 'too_hard') {
      currentDaily = (currentDaily - 2).clamp(3, 15);
    } else if (rating == 'too_easy') {
      currentDaily = (currentDaily + 2).clamp(3, 15);
    }

    await prefs.setInt(AppConstants.prefDailyNewPhrases, currentDaily);

    try {
      final db = await _database.database;
      await db.insert('session_logs', {
        'session_date': DateTime.now().toIso8601String(),
        'duration_sec': DateTime.now().difference(state.startTime).inSeconds,
        'new_count': state.newLearnedCount,
        'review_count': state.reviewedCount,
        'feeling': rating,
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _tts.stop();
    _audio.stopPlayback();
    super.dispose();
  }
}

final sessionControllerProvider =
    StateNotifierProvider.autoDispose<SessionController, SessionState>((ref) {
  return SessionController();
});
