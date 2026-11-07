import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/engine/session_builder.dart';
import '../../../domain/engine/srs_engine.dart';
import 'session_controller.dart';
import 'widgets/exercises/feedback_sheet.dart';
import 'widgets/exercises/listen_and_choose_exercise.dart';
import 'widgets/exercises/reconstruct_exercise.dart';
import 'widgets/exercises/speak_it_exercise.dart';
import 'widgets/exercises/write_it_exercise.dart';
import 'widgets/exercises/fill_blank_exercise.dart';
import 'widgets/exercises/complete_phrase_exercise.dart';
import 'widgets/exercises/create_examples_exercise.dart';
import 'widgets/new_phrase_card.dart';
import 'widgets/review_card.dart';
import '../../settings/presentation/settings_controller.dart';
import 'widgets/session_progress_header.dart';
import 'widgets/session_summary_card.dart';

/// Écran complet de séance d'apprentissage (Section 3 du plan) :
/// Phase 1 : Révision
/// Phase 2 : Nouveautés
/// Phase 3 : Erreurs
/// Phase 4 : Écran de fin
class SessionScreen extends ConsumerStatefulWidget {
  final bool isExpressMode;
  final List<String>? targetPhraseIds;

  const SessionScreen({
    super.key,
    this.isExpressMode = false,
    this.targetPhraseIds,
  });

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(sessionControllerProvider.notifier).initSession(
            isExpressMode: widget.isExpressMode,
            targetPhraseIds: widget.targetPhraseIds,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sessionControllerProvider);
    final controller = ref.read(sessionControllerProvider.notifier);
    final settings = ref.watch(settingsControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (state.status == SessionStatus.loading) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (state.status == SessionStatus.completed) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        body: SafeArea(
          child: SessionSummaryCard(
            reviewedCount: state.reviewedCount,
            newCount: state.newLearnedCount,
            elapsedMinutes: state.elapsedMinutes,
            successRate: state.successRate,
            streakDays: state.streakDays,
            streakFreezeUsed: state.streakFreezeUsed,
            streakReset: state.streakReset,
            nextReviewDate: state.nextReviewDate,
            selectedFeedback: state.feedbackRating,
            onSelectFeedback: (rating) {
              controller.submitSessionFeedback(rating);
            },
            onAddTenMore: () {
              controller.addTenMorePhrases();
            },
            onAddFiveMore: () {
              controller.addFiveMorePhrases();
            },
            onStartMasterXp: () {
              final phraseIds = state.session?.items.map((i) => i.phrase.id).toList();
              context.push('/master-xp', extra: phraseIds);
            },
            onFinish: () {
              context.go('/home');
            },
          ),
        ),
      );
    }

    final currentItem = state.currentItem;
    if (currentItem == null) {
      return Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => context.go('/home'),
            child: const Text("Retour à l'accueil"),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Barre de progression en haut avec bouton fermer
            SessionProgressHeader(
              progress: state.progressRatio,
              current: state.currentIndex + 1,
              total: state.session?.totalCount ?? 1,
            ),

            // Indicateur de Phase Erreurs (Section 3.4)
            if (state.isErrorPhase)
              Container(
                margin: const EdgeInsets.only(top: 4, bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accentDark.withValues(alpha: 0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded, size: 14, color: AppColors.accentDark),
                    SizedBox(width: 6),
                    Text(
                      'Phase Erreurs • Rattrapage bienveillant',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentDark,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 8),

            // Contenu principal selon le type d'exercice
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildExerciseWidget(currentItem, state, controller, settings),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: state.isShowingFeedback
          ? FeedbackSheet(
              isSuccess: state.lastAnswerSuccess,
              phrase: currentItem.phrase,
              hasMinorTypo: state.lastAnswerHasMinorTypo,
              isTtsPlaying: state.isTtsPlaying,
              onPlayAudio: () => controller.playTts(slow: false),
              onContinue: () => controller.continueAfterFeedback(),
              onClose: () => controller.dismissFeedback(),
            )
          : null,
    );
  }

  Widget _buildExerciseWidget(
    SessionItem item,
    SessionState state,
    SessionController controller,
    SettingsState settings,
  ) {
    switch (item.exerciseType) {
      case ExerciseType.newPhrase:
        return NewPhraseCard(
          key: ValueKey('new_${item.phrase.id}_${state.currentLearningStep}'),
          phrase: item.phrase,
          learningStep: state.currentLearningStep,
          testSubStep: state.currentTestSubStep,
          onTestSubStepChanged: (sub) => controller.setTestSubStep(sub),
          choices: item.choices,
          isTtsPlaying: state.isTtsPlaying,
          onPlayNormal: () => controller.playTts(slow: false),
          onPlaySlow: () => controller.playTts(slow: true),
          onNextStep: () => controller.advanceLearningStep(),
          onPreviousStep: () => controller.previousLearningStep(),
          onLearningStepChanged: (step) => controller.setLearningStep(step),
          onValidate: (isCorrect) {
            controller.evaluateExerciseAnswer(isSuccess: isCorrect);
          },
        );

      case ExerciseType.listenAndChoose:
        return ListenAndChooseExercise(
          key: ValueKey('choose_${item.phrase.id}'),
          targetPhrase: item.phrase,
          choices: item.choices,
          isTtsPlaying: state.isTtsPlaying,
          onPlayAudio: () => controller.playTts(slow: false),
          onSelected: (choice) {
            final isCorrect = choice.trim() == item.phrase.fr.trim() ||
                choice.trim() == (item.phrase.ar ?? '').trim();
            controller.evaluateExerciseAnswer(isSuccess: isCorrect);
          },
        );

      case ExerciseType.reconstruct:
        return ReconstructExercise(
          key: ValueKey('reconstruct_${item.phrase.id}'),
          targetPhrase: item.phrase,
          isTtsPlaying: state.isTtsPlaying,
          onPlayAudio: () => controller.playTts(slow: false),
          onPlaySlow: () => controller.playTts(slow: true),
          onValidate: (isCorrect) {
            controller.evaluateExerciseAnswer(isSuccess: isCorrect);
          },
        );

      case ExerciseType.speakIt:
        return SpeakItExercise(
          key: ValueKey('speak_${item.phrase.id}'),
          targetPhrase: item.phrase,
          isRecording: state.isRecording,
          isTtsPlaying: state.isTtsPlaying,
          onToggleRecord: () => controller.toggleRecording(),
          onPlayModel: () => controller.playTts(slow: false),
          onEvaluate: (outcome) {
            controller.answerPhrase(outcome);
          },
        );

      case ExerciseType.writeIt:
        return WriteItExercise(
          key: ValueKey('write_${item.phrase.id}'),
          targetPhrase: item.phrase,
          isTtsPlaying: state.isTtsPlaying,
          onPlayAudio: () => controller.playTts(slow: false),
          onValidate: (result) {
            controller.evaluateExerciseAnswer(
              isSuccess: result.isCorrect,
              hasMinorTypo: result.hasMinorTypo,
            );
          },
        );

      case ExerciseType.fillBlank:
        return FillBlankExercise(
          key: ValueKey('fill_${item.phrase.id}'),
          targetPhrase: item.phrase,
          isTtsPlaying: state.isTtsPlaying,
          onPlayAudio: () => controller.playTts(slow: false),
          onValidate: (isCorrect) {
            controller.evaluateExerciseAnswer(isSuccess: isCorrect);
          },
        );

      case ExerciseType.completePhrase:
        return CompletePhraseExercise(
          key: ValueKey('complete_${item.phrase.id}'),
          targetPhrase: item.phrase,
          isTtsPlaying: state.isTtsPlaying,
          onPlayAudio: () => controller.playTts(slow: false),
          onValidate: (isCorrect) {
            controller.evaluateExerciseAnswer(isSuccess: isCorrect);
          },
        );

      case ExerciseType.createExamples:
        return CreateExamplesExercise(
          key: ValueKey('examples_${item.phrase.id}'),
          phrase: item.phrase,
          onComplete: () {
            controller.answerPhrase(ReviewOutcome.success);
          },
        );

      case ExerciseType.recall:
        // Si l'utilisateur est sur une carte de révision de phrases parlées (Étape 2)
        return ReviewCard(
          key: ValueKey('review_${item.phrase.id}'),
          phrase: item.phrase,
          preferredTranslationLanguage: settings.primaryLanguage,
          isTtsPlaying: state.isTtsPlaying,
          onPlayNormal: () => controller.playTts(slow: false),
          onAnswer: (outcome) {
            controller.answerPhrase(outcome);
          },
        );
    }
  }
}
