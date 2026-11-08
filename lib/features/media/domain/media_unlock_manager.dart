import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/subscription_service.dart';
import '../../../domain/models/media_content.dart';
import '../../../domain/models/phrase.dart';
import '../../../domain/models/user_phrase.dart';

/// Statut détaillé de déblocage d'un lot et de son dialogue
class LotLockStatus {
  final int lotId;
  final bool isUnlocked;
  final bool isCompleted;
  final bool isDialogueActive;
  final bool isPalierStart;
  final int? requiredPalierExam; // Ex: 1 pour Lot 4, 2 pour Lot 7, 4 pour Lot 13
  final int? requiredPreviousLot; // Ex: 1 pour Lot 2, 7 pour Lot 8
  final bool isExamReady; // Vrai si les 3 lots du palier d'examen sont tous achevés
  final int highestUnlockedLot;

  const LotLockStatus({
    required this.lotId,
    required this.isUnlocked,
    required this.isCompleted,
    required this.isDialogueActive,
    required this.isPalierStart,
    this.requiredPalierExam,
    this.requiredPreviousLot,
    this.isExamReady = false,
    required this.highestUnlockedLot,
  });
}

/// Gestionnaire central des règles de progression, de déblocage des lots
/// et d'activation des dialogues et chansons.
class MediaUnlockManager {
  static const String _autoListeningKey = 'auto_listening_dialogue_lot_ids';
  static const String _playedPrefix = 'media_played_lot_';
  static const String _unlockedPrefix = 'media_unlocked_lot_';

  /// Vérifie si le Grand Examen d'un palier donné (30 questions)
  /// a été réussi avec au moins 20/30.
  static bool isPalierExamPassed(int palierIndex, SharedPreferences? prefs) {
    if (prefs == null) return false;
    final isPassed = prefs.getBool('palier_exam_${palierIndex}_passed') ?? false;
    final score = prefs.getInt('palier_exam_${palierIndex}_score') ?? 0;
    return isPassed || score >= 20;
  }

  /// Vérifie si les examens de tous les paliers antérieurs à un lot donné sont validés.
  static bool arePrerequisitePaliersPassed(int lotId, SharedPreferences? prefs) {
    final currentPalier = ((lotId - 1) ~/ 3) + 1;
    if (currentPalier <= 1) return true;
    for (int p = 1; p < currentPalier; p++) {
      if (!isPalierExamPassed(p, prefs)) {
        return false;
      }
    }
    return true;
  }

  /// Vérifie si les 10 phrases d'un lot ont été travaillées/achevées par le candidat.
  static bool isLotCompleted({
    required int lotId,
    Map<String, UserPhrase> progress = const {},
    List<Phrase> allPhrases = const [],
    SharedPreferences? prefs,
  }) {
    // 1. Si le lot est explicitement marqué complété dans les préférences
    if (prefs != null && prefs.getBool('batch_${lotId - 1}_completed') == true) {
      return true;
    }

    if (allPhrases.isEmpty) return false;
    final start = (lotId - 1) * 10;
    final end = (start + 10).clamp(0, allPhrases.length);
    if (start >= allPhrases.length) return false;

    final lotPhrases = allPhrases.sublist(start, end);
    if (lotPhrases.isEmpty) return false;

    // Toutes les phrases du lot doivent avoir au moins un niveau ou une répétition
    return lotPhrases.every((p) {
      final up = progress[p.id];
      return up != null && (up.level > 0 || up.reps > 0);
    });
  }

  /// Vérifie si les 3 lots d'un palier donné sont tous complétés
  static bool isPalierReadyForExam(
    int palierIndex, {
    Map<String, UserPhrase> progress = const {},
    List<Phrase> allPhrases = const [],
    SharedPreferences? prefs,
  }) {
    final lotA = (palierIndex - 1) * 3 + 1;
    final lotB = lotA + 1;
    final lotC = lotA + 2;
    return isLotCompleted(lotId: lotA, progress: progress, allPhrases: allPhrases, prefs: prefs) &&
           isLotCompleted(lotId: lotB, progress: progress, allPhrases: allPhrases, prefs: prefs) &&
           isLotCompleted(lotId: lotC, progress: progress, allPhrases: allPhrases, prefs: prefs);
  }

  /// Calcule le numéro du lot débloqué le plus élevé (de 1 à 30).
  /// Règle séquentielle stricte :
  /// - Admin : Tous les 30 lots immédiatement ouverts et accessibles.
  /// - Gratuit (Free) : Lots 1 à 3 uniquement (Palier 1).
  /// - Premium : Lots 4 à 30 s'ouvrent au fur et à mesure des réussites d'examen.
  static int getHighestUnlockedLot({
    Map<String, UserPhrase> progress = const {},
    List<Phrase> allPhrases = const [],
    SharedPreferences? prefs,
  }) {
    if (SubscriptionService.instance.isAdmin) {
      return 30; // Accès total immédiat pour l'administrateur
    }

    int highest = 1;

    for (int lot = 1; lot < 30; lot++) {
      // Si le candidat n'est pas premium, il ne peut pas dépasser le Lot 3
      if (lot >= 3 && !SubscriptionService.instance.isPremium) {
        break;
      }

      final completed = isLotCompleted(
        lotId: lot,
        progress: progress,
        allPhrases: allPhrases,
        prefs: prefs,
      );

      if (!completed) {
        // Le lot en cours n'est pas encore terminé : la progression s'arrête ici
        break;
      }

      // Le lot actuel est achevé.
      // S'il termine un Palier (Lot 3 = P1, Lot 6 = P2, Lot 9 = P3...) :
      if (lot % 3 == 0) {
        final palierIndex = lot ~/ 3;
        final examPassed = isPalierExamPassed(palierIndex, prefs);
        if (!examPassed) {
          // L'examen obligatoire de palier n'est pas encore validé (min 20/30) :
          // Le lot suivant (Lot 4, Lot 7, etc.) reste strictement verrouillé !
          break;
        }
      }

      highest = lot + 1;
    }

    return highest;
  }

  /// Retourne le statut complet (déblocage du lot, activation du dialogue, prérequis exacts)
  static LotLockStatus getLotStatus({
    required int lotId,
    Map<String, UserPhrase> progress = const {},
    List<Phrase> allPhrases = const [],
    SharedPreferences? prefs,
  }) {
    final highestUnlocked = getHighestUnlockedLot(
      progress: progress,
      allPhrases: allPhrases,
      prefs: prefs,
    );

    final bool isUnlocked = lotId <= highestUnlocked;
    final bool completed = isLotCompleted(
      lotId: lotId,
      progress: progress,
      allPhrases: allPhrases,
      prefs: prefs,
    );

    final currentPalier = ((lotId - 1) ~/ 3) + 1;
    final isPalierStart = (lotId - 1) % 3 == 0 && lotId > 1;
    final requiredExam = isPalierStart ? (currentPalier - 1) : null;
    final requiredLot = isPalierStart ? null : (lotId - 1);
    final examReady = requiredExam != null && isPalierReadyForExam(
      requiredExam,
      progress: progress,
      allPhrases: allPhrases,
      prefs: prefs,
    );

    return LotLockStatus(
      lotId: lotId,
      isUnlocked: isUnlocked,
      isCompleted: completed,
      isDialogueActive: completed, // Dialogue activé dès que le candidat a complété ce lot
      isPalierStart: isPalierStart,
      requiredPalierExam: requiredExam,
      requiredPreviousLot: requiredLot,
      isExamReady: examReady,
      highestUnlockedLot: highestUnlocked,
    );
  }

  /// Détermine si un lot est débloqué pour l'apprentissage
  static bool isLotUnlocked({
    required int lotId,
    Map<String, UserPhrase> progress = const {},
    List<Phrase> allPhrases = const [],
    SharedPreferences? prefs,
    List<String> lotPhraseIds = const [],
    int maxUnlockedBatchIndex = 0,
  }) {
    return lotId <= getHighestUnlockedLot(
      progress: progress,
      allPhrases: allPhrases,
      prefs: prefs,
    );
  }

  /// Détermine si le dialogue d'un lot est actif (écoutable)
  static bool isDialogueActive({
    required int lotId,
    Map<String, UserPhrase> progress = const {},
    List<Phrase> allPhrases = const [],
    SharedPreferences? prefs,
  }) {
    return getLotStatus(
      lotId: lotId,
      progress: progress,
      allPhrases: allPhrases,
      prefs: prefs,
    ).isDialogueActive;
  }

  /// Enregistre le déblocage forcé (si nécessaire)
  static Future<void> unlockLot(int lotId, {SharedPreferences? prefs}) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    await p.setBool('$_unlockedPrefix$lotId', true);
  }

  /// Indique si un média a déjà été écouté
  static Future<bool> isMediaPlayed(int lotId, MediaType type, {SharedPreferences? prefs}) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    return p.getBool('$_playedPrefix${lotId}_${type.value}') ?? false;
  }

  /// Marque un média comme écouté
  static Future<void> markMediaPlayed(int lotId, MediaType type, {SharedPreferences? prefs}) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    await p.setBool('$_playedPrefix${lotId}_${type.value}', true);
  }

  /// Liste des IDs de lots dont les dialogues sont dans l'Écoute auto
  static Future<List<int>> getAutoListeningLotIds({SharedPreferences? prefs}) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    final stringList = p.getStringList(_autoListeningKey) ?? [];
    return stringList.map((s) => int.tryParse(s) ?? 0).where((id) => id > 0).toList();
  }

  /// Vérifie si un dialogue de lot est dans l'Écoute auto
  static Future<bool> isDialogueInAutoListening(int lotId, {SharedPreferences? prefs}) async {
    final list = await getAutoListeningLotIds(prefs: prefs);
    return list.contains(lotId);
  }

  /// Ajoute/retire un dialogue de l'Écoute auto
  static Future<bool> toggleDialogueInAutoListening(int lotId, {SharedPreferences? prefs}) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    final list = (p.getStringList(_autoListeningKey) ?? []).toSet();
    final idStr = lotId.toString();
    final bool willBeInPlaylist;

    if (list.contains(idStr)) {
      list.remove(idStr);
      willBeInPlaylist = false;
    } else {
      list.add(idStr);
      willBeInPlaylist = true;
    }

    await p.setStringList(_autoListeningKey, list.toList());
    return willBeInPlaylist;
  }
}
