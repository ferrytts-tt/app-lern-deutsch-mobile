import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../../core/services/pronunciation_service.dart';
import '../../../core/services/tts_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_progress_bar.dart';
import '../../../core/widgets/audio_button.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/duo_button.dart';
import '../../../core/widgets/duo_confetti.dart';
import '../../../core/widgets/duo_streak_widget.dart';
import '../../../core/widgets/german_text_annotator.dart';
import '../../../core/widgets/arabic_text_view.dart';
import '../../../core/widgets/mascot_widget.dart';
import '../../../data/database/app_database.dart';
import 'package:just_audio/just_audio.dart';
import '../../../domain/models/phrase.dart';
import '../../../domain/models/user_phrase.dart';
import '../../../domain/models/user_profile.dart';
import '../../media/data/media_repository.dart';
import '../../media/domain/media_unlock_manager.dart';
import '../../raetsel/domain/raetsel_manager.dart';
import '../../shop/presentation/shop_modal.dart';

class _DailyQuestItem {
  final String id;
  final String title;
  final IconData iconData;
  final Color iconColor;
  final Color iconBg;
  final int current;
  final int target;
  final String unit;
  final String rewardText;
  final bool isCompleted;

  const _DailyQuestItem({
    required this.id,
    required this.title,
    required this.iconData,
    required this.iconColor,
    required this.iconBg,
    required this.current,
    required this.target,
    required this.unit,
    required this.rewardText,
    required this.isCompleted,
  });

  double get fraction => target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
}

/// Page d'accueil (Accueil) connectée à la base de données locale.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isPlayingAudio = false;
  bool _showPhraseTranslation = false;
  bool _hasListenedPhraseOfTheDay = false;
  bool _isChestClaimedToday = false;
  bool _showAllTenPhrases = true;
  String? _currentlyPlayingPhraseId;
  int _currentBatchIndex = 0;
  int _totalGems = 0;
  bool _isAutoPlayingBatch = false;

  bool _isLoading = true;
  bool _isSessionDoneToday = false;
  int _todayXp = 0;
  int _todayAudioCount = 0;
  List<Phrase> _allPhrases = [];
  List<Phrase> _todayTenPhrases = [];
  Map<String, UserPhrase> _userProgress = {};
  Phrase? _phraseOfTheDay;
  int _streakDays = 0;
  UserProfile _profile = const UserProfile();
  SharedPreferences? _prefs;
  bool _isRaetselUnlocked = false;
  int _raetselLevelNum = 1;

  @override
  void initState() {
    super.initState();
    RaetselManager.instance.unlockNotifier.addListener(_onRaetselUnlockChanged);
    _loadDashboardData();
  }

  void _onRaetselUnlockChanged() {
    if (mounted) {
      _loadDashboardData();
    }
  }

  /// Détermine le lot débloqué maximum (les lots futurs restent strictement masqués & verrouillés)
  /// Règle stricte : tous les 30 phrases (Lot 3, Lot 6, Lot 9...), le candidat doit obligatoirement
  /// avoir validé le Grand Examen de fin de palier avec au moins 20/30 pour débloquer le lot suivant.
  int _calculateUnlockedBatchIndex() {
    return _calculateUnlockedBatchIndexWithData(_allPhrases, _userProgress, prefs: _prefs);
  }

  int _calculateUnlockedBatchIndexWithData(
    List<Phrase> phrases,
    Map<String, UserPhrase> progress, {
    SharedPreferences? prefs,
  }) {
    if (phrases.isEmpty) return 0;
    final totalBatches = (phrases.length / 10).ceil();
    final highest = MediaUnlockManager.getHighestUnlockedLot(
      progress: progress,
      allPhrases: phrases,
      prefs: prefs ?? _prefs,
    );
    return (highest - 1).clamp(0, totalBatches - 1);
  }

  /// Vérifie si les 3 lots d'un palier (ex: L1, L2, L3 pour P1 ; L4, L5, L6 pour P2...)
  /// sont tous validés à 100 % (toutes les 30 phrases ont été travaillées au moins 1 fois).
  bool _isPalierReadyForExam(int palierIndex) {
    if (_allPhrases.isEmpty) return false;
    final palierStart = (palierIndex - 1) * 30;
    final palierEnd = (palierIndex * 30).clamp(0, _allPhrases.length);
    if (palierEnd <= palierStart) return false;
    final palierPhrases = _allPhrases.sublist(palierStart, palierEnd);

    final completedInPalier = palierPhrases.where((p) {
      final prog = _userProgress[p.id];
      return prog != null && (prog.level > 0 || prog.reps > 0);
    }).length;

    return completedInPalier >= palierPhrases.length && palierPhrases.isNotEmpty;
  }

  void _changeBatch(int delta) async {
    if (_allPhrases.isEmpty) return;
    final maxUnlockedBatch = _calculateUnlockedBatchIndex();
    final newIndex = (_currentBatchIndex + delta).clamp(0, maxUnlockedBatch);
    if (newIndex != _currentBatchIndex) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('current_batch_index', newIndex);
      final start = newIndex * 10;
      final end = (start + 10).clamp(0, _allPhrases.length);
      setState(() {
        _currentBatchIndex = newIndex;
        _todayTenPhrases = _allPhrases.sublist(start, end);
      });
    }
  }

  /// Sélectionne directement un lot depuis le carrousel interactif du parcours
  void _selectBatch(int targetIndex) async {
    if (_allPhrases.isEmpty) return;
    final maxUnlockedBatch = _calculateUnlockedBatchIndex();
    if (targetIndex > maxUnlockedBatch) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.lock_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Lot verrouillé ! Valide d\'abord l\'Examen du Palier avec au moins 20/30 pour débloquer.',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF0F172A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }
    if (targetIndex != _currentBatchIndex) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('current_batch_index', targetIndex);
      final start = targetIndex * 10;
      final end = (start + 10).clamp(0, _allPhrases.length);
      setState(() {
        _currentBatchIndex = targetIndex;
        _todayTenPhrases = _allPhrases.sublist(start, end);
      });
    }
  }

  AudioPlayer? _autoPlayDialoguePlayer;

  /// Écoute automatique et continue des 10 phrases pour un entraînement facile à l'oreille.
  /// Intègre également la lecture du dialogue associé au lot si activé dans l'Écoute auto 🎧.
  Future<void> _toggleAutoPlayBatch() async {
    if (_isAutoPlayingBatch) {
      await TtsService.instance.stop();
      if (_autoPlayDialoguePlayer != null) {
        try {
          await _autoPlayDialoguePlayer!.stop();
          await _autoPlayDialoguePlayer!.dispose();
        } catch (_) {}
        _autoPlayDialoguePlayer = null;
      }
      if (mounted) {
        setState(() {
          _isAutoPlayingBatch = false;
          _currentlyPlayingPhraseId = null;
        });
      }
      return;
    }

    if (_todayTenPhrases.isEmpty) return;

    setState(() {
      _isAutoPlayingBatch = true;
    });

    for (int i = 0; i < _todayTenPhrases.length; i++) {
      if (!mounted || !_isAutoPlayingBatch) break;
      final phrase = _todayTenPhrases[i];
      if (mounted) {
        setState(() {
          _currentlyPlayingPhraseId = phrase.id;
        });
      }

      await TtsService.instance.stop();
      await TtsService.instance.speak(phrase.de, phraseId: phrase.id);
      await Future.delayed(const Duration(milliseconds: 2400));
    }

    // Après les 10 phrases : vérifier si le dialogue du lot actif est débloqué ET activé en Écoute auto
    final batchNum = _currentBatchIndex + 1;
    final isLotUnlocked = MediaUnlockManager.isLotUnlocked(
      lotId: batchNum,
      progress: _userProgress,
      lotPhraseIds: _todayTenPhrases.map((p) => p.id).toList(),
      maxUnlockedBatchIndex: _currentBatchIndex,
      prefs: _prefs,
    );
    final isDialogueInAuto = await MediaUnlockManager.isDialogueInAutoListening(batchNum, prefs: _prefs);
    if (isLotUnlocked && isDialogueInAuto && mounted && _isAutoPlayingBatch) {
      try {
        final repo = MediaRepository();
        final dialogueItem = await repo.getDialogueForLot(batchNum);
        if (dialogueItem != null && mounted && _isAutoPlayingBatch) {
          if (mounted) {
            setState(() {
              _currentlyPlayingPhraseId = 'dialogue_$batchNum';
            });
          }
          final player = AudioPlayer();
          _autoPlayDialoguePlayer = player;
          final assetPath = MediaRepository.getAudioAssetPath(dialogueItem.audioFile);
          await player.setAsset(assetPath);
          if (mounted && _isAutoPlayingBatch) {
            await player.play();
          }
        }
      } catch (e) {
        debugPrint('Erreur lecture dialogue écoute auto: $e');
      } finally {
        if (_autoPlayDialoguePlayer != null) {
          try {
            await _autoPlayDialoguePlayer!.dispose();
          } catch (_) {}
          _autoPlayDialoguePlayer = null;
        }
      }
    }

    if (mounted) {
      setState(() {
        _isAutoPlayingBatch = false;
        _currentlyPlayingPhraseId = null;
      });
    }
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() => _isLoading = true);

      final db = AppDatabase.instance;
      final phrases = await db.getAllPhrases();
      final progress = await db.getAllUserPhrases();
      final profile = await db.getUserProfile();

      // Phrase du jour : sélection déterministe basée sur la date (change chaque nuit à minuit)
      Phrase? phraseOfTheDay;
      if (phrases.isNotEmpty) {
        final now = DateTime.now();
        final daySeed = now.year * 1000 + now.month * 32 + now.day;
        phraseOfTheDay = phrases[daySeed % phrases.length];
      }

      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final todayDateKey = '${now.year}_${now.month}_${now.day}';
      final lastDateKey = prefs.getString('last_active_quest_date');

      // Nettoyage unique pour corriger l'ancienne persistance infinie des quêtes
      if (prefs.getBool('has_cleaned_quest_bug_v2') != true) {
        await prefs.remove('master_xp_available');
        await prefs.remove('last_master_xp_earned');
        await prefs.remove('session_done_$todayDateKey');
        await prefs.remove('daily_xp_$todayDateKey');
        await prefs.remove('chest_claimed_$todayDateKey');
        await prefs.remove('listened_phrase_$todayDateKey');
        await prefs.remove('audio_count_$todayDateKey');
        await prefs.setBool('has_cleaned_quest_bug_v2', true);
      }

      // Si c'est un nouveau jour (minuit passé), réinitialiser les flags temporaires de la veille
      if (lastDateKey != null && lastDateKey != todayDateKey) {
        await prefs.remove('master_xp_available');
        await prefs.remove('last_master_xp_earned');
      }
      await prefs.setString('last_active_quest_date', todayDateKey);

      final hasListened = prefs.getBool('listened_phrase_$todayDateKey') ?? false;
      final bool chestClaimed = prefs.getBool('chest_claimed_$todayDateKey') ?? false;

      // Détection stricte si la séance quotidienne a été effectuée aujourd'hui
      final bool sessionDonePref = prefs.getBool('session_done_$todayDateKey') ?? false;
      final String? lastSessionDateStr = prefs.getString('last_session_completed_date');
      DateTime? parsedLastSession;
      if (lastSessionDateStr != null) {
        try {
          parsedLastSession = DateTime.parse(lastSessionDateStr);
        } catch (_) {}
      }
      final bool profileSessionToday = (profile.derniereSession != null &&
          profile.derniereSession!.year == now.year &&
          profile.derniereSession!.month == now.month &&
          profile.derniereSession!.day == now.day) ||
          (parsedLastSession != null &&
          parsedLastSession.year == now.year &&
          parsedLastSession.month == now.month &&
          parsedLastSession.day == now.day);

      final bool isSessionDone = sessionDonePref || profileSessionToday;

      // Gestion du lot courant (200 phrases = 20 lots de 10 phrases)
      _prefs = prefs;
      final int maxUnlocked = _calculateUnlockedBatchIndexWithData(phrases, progress, prefs: prefs);
      int batchIndex = prefs.getInt('current_batch_index') ?? 0;
      final int totalBatches = (phrases.length / 10).ceil().clamp(1, 100);
      if (batchIndex > maxUnlocked) {
        batchIndex = maxUnlocked;
        await prefs.setInt('current_batch_index', batchIndex);
      }
      batchIndex = batchIndex.clamp(0, totalBatches - 1);

      // Récupération des 10 phrases selon le batchIndex
      final start = batchIndex * 10;
      final end = (start + 10).clamp(0, phrases.length);
      final List<Phrase> todayTenPhrases = (phrases.isNotEmpty && start < phrases.length)
          ? phrases.sublist(start, end)
          : [];

      // Récupération des XP et du compteur d'écoutes audio du jour
      final dayKey = 'daily_xp_$todayDateKey';
      final int todayXp = prefs.getInt(dayKey) ?? 0;
      final int todayAudioCount = prefs.getInt('audio_count_$todayDateKey') ?? (hasListened ? 1 : 0);
      final int totalGems = prefs.getInt('total_gems') ?? 0;
      final bool isRaetselUnlocked = await RaetselManager.instance.isUnlocked(prefs: prefs);
      final int raetselLevel = await RaetselManager.instance.getCurrentLevelNumber(prefs: prefs);

      if (mounted) {
        setState(() {
          _prefs = prefs;
          _currentBatchIndex = batchIndex;
          _allPhrases = phrases;
          _todayTenPhrases = todayTenPhrases;
          _isChestClaimedToday = chestClaimed;
          _userProgress = progress;
          _phraseOfTheDay = phraseOfTheDay;
          _hasListenedPhraseOfTheDay = hasListened;
          _streakDays = profile.serieJours > 0 ? profile.serieJours : (isSessionDone ? 1 : 0);
          _profile = profile;
          _isSessionDoneToday = isSessionDone;
          _todayXp = todayXp;
          _todayAudioCount = todayAudioCount;
          _totalGems = totalGems;
          _isRaetselUnlocked = isRaetselUnlocked;
          _raetselLevelNum = raetselLevel;
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      debugPrint('Erreur lors du chargement de l\'écran d\'accueil: $e\n$stack');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _speakPhrase(String text, {bool isPhraseOfTheDay = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayKey = '${now.year}_${now.month}_${now.day}';

    if (isPhraseOfTheDay && !_hasListenedPhraseOfTheDay) {
      if (mounted) setState(() => _hasListenedPhraseOfTheDay = true);
      await prefs.setBool('listened_phrase_$todayKey', true);
    }

    final audioKey = 'audio_count_$todayKey';
    final currentAudio = prefs.getInt(audioKey) ?? 0;
    await prefs.setInt(audioKey, currentAudio + 1);
    if (mounted) setState(() => _todayAudioCount = currentAudio + 1);

    if (_isPlayingAudio) {
      await TtsService.instance.stop();
      if (mounted) setState(() => _isPlayingAudio = false);
    } else {
      if (mounted) setState(() => _isPlayingAudio = true);
      await TtsService.instance.speak(
        text,
        phraseId: _phraseOfTheDay?.id,
        onDone: () {
          if (mounted) setState(() => _isPlayingAudio = false);
        },
      );
    }
  }

  /// Réinitialise les quêtes du jour pour tester (remet à 0 les compteurs du jour)
  Future<void> _resetDailyQuestsForTesting() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayKey = '${now.year}_${now.month}_${now.day}';
    await prefs.remove('daily_xp_$todayKey');
    await prefs.remove('session_done_$todayKey');
    await prefs.remove('listened_phrase_$todayKey');
    await prefs.remove('chest_claimed_$todayKey');
    await prefs.remove('audio_count_$todayKey');
    await prefs.remove('master_xp_available');
    await prefs.remove('last_master_xp_earned');
    await prefs.setString('last_active_quest_date', todayKey);
    await _loadDashboardData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(child: Text('Quêtes du jour réinitialisées à 0 ! Prêtes pour la journée.')),
            ],
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Liste dynamique et renouvelée chaque jour des 3 quêtes quotidiennes
  List<_DailyQuestItem> _getDailyQuests(DateTime now, int learnedCount) {
    final daySeed = now.year * 10000 + now.month * 100 + now.day;
    final quests = <_DailyQuestItem>[];

    // Quête 1 : Objectif XP journalier (varie entre 20, 25, 30, 40 selon le jour)
    final xpTargets = [20, 30, 40, 25, 35, 30, 20];
    final xpTarget = xpTargets[now.weekday % xpTargets.length];
    final xpCompleted = _todayXp >= xpTarget;
    quests.add(
      _DailyQuestItem(
        id: 'xp_quest',
        title: 'Gagner $xpTarget XP',
        iconData: Icons.bolt_rounded,
        iconColor: const Color(0xFFD97706),
        iconBg: const Color(0xFFFFF3CD),
        current: _todayXp,
        target: xpTarget,
        unit: 'XP',
        rewardText: '+${(xpTarget ~/ 2).clamp(10, 20)}',
        isCompleted: xpCompleted,
      ),
    );

    // Quête 2 : Défi d'apprentissage & Pratique (tourne selon la graine du jour)
    final quest2Type = (daySeed % 3);
    if (quest2Type == 1) {
      // Étudier des phrases du lot actif
      const target = 5;
      final current = _todayTenPhrases.where((p) {
        final prog = _userProgress[p.id];
        return prog != null && (prog.level > 0 || prog.reps > 0);
      }).length.clamp(0, target);
      final isDone = current >= target;
      quests.add(
        _DailyQuestItem(
          id: 'phrases_quest',
          title: 'Étudier $target phrases du lot',
          iconData: Icons.menu_book_rounded,
          iconColor: const Color(0xFF16A34A),
          iconBg: const Color(0xFFE8F5E9),
          current: current,
          target: target,
          unit: 'phrases',
          rewardText: '+15',
          isCompleted: isDone,
        ),
      );
    } else {
      // Séance quotidienne standard
      final sessionProgress = _isSessionDoneToday ? 1 : 0;
      quests.add(
        _DailyQuestItem(
          id: 'session_quest',
          title: 'Terminer la séance quotidienne',
          iconData: Icons.school_rounded,
          iconColor: const Color(0xFF16A34A),
          iconBg: const Color(0xFFE8F5E9),
          current: sessionProgress,
          target: 1,
          unit: 'séance',
          rewardText: '+15',
          isCompleted: _isSessionDoneToday,
        ),
      );
    }

    // Quête 3 : Immersion audio & écoute (tourne selon la graine du jour)
    final quest3Type = (daySeed % 2);
    if (quest3Type == 1) {
      const target = 3;
      final current = _todayAudioCount.clamp(0, target);
      final isDone = current >= target;
      quests.add(
        _DailyQuestItem(
          id: 'audio_count_quest',
          title: 'Écouter $target phrases avec l\'audio',
          iconData: Icons.headphones_rounded,
          iconColor: const Color(0xFF0284C7),
          iconBg: const Color(0xFFE3F2FD),
          current: current,
          target: target,
          unit: 'écoutes',
          rewardText: '+10',
          isCompleted: isDone,
        ),
      );
    } else {
      final audioProgress = _hasListenedPhraseOfTheDay ? 1 : 0;
      quests.add(
        _DailyQuestItem(
          id: 'phrase_of_the_day_quest',
          title: 'Écouter la phrase du jour',
          iconData: Icons.volume_up_rounded,
          iconColor: const Color(0xFF0284C7),
          iconBg: const Color(0xFFE3F2FD),
          current: audioProgress,
          target: 1,
          unit: '',
          rewardText: '+5',
          isCompleted: _hasListenedPhraseOfTheDay,
        ),
      );
    }

    return quests;
  }

  void _claimDailyChest() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    await prefs.setBool('chest_claimed_${now.year}_${now.month}_${now.day}', true);

    final dayKey = 'daily_xp_${now.year}_${now.month}_${now.day}';
    final currentXp = prefs.getInt(dayKey) ?? 0;
    await prefs.setInt(dayKey, currentXp + 20);

    final totalGems = prefs.getInt('total_gems') ?? 0;
    await prefs.setInt('total_gems', totalGems + 25);

    PronunciationService.instance.playSuccessSound();

    setState(() {
      _isChestClaimedToday = true;
      _todayXp += 20;
      _totalGems += 25;
    });

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Stack(
          alignment: Alignment.center,
          children: [
            const Positioned.fill(
              child: DuoConfettiOverlay(
                isPlaying: true,
                child: SizedBox.expand(),
              ),
            ),
            AlertDialog(
              backgroundColor: Theme.of(dialogContext).brightness == Brightness.dark
                  ? AppColors.surfaceDark
                  : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  const MascotWidget(
                    mood: MascotMood.celebrating,
                    size: 90,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '🎁 Coffre du jour ouvert !',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Bravo ! Tu as complété toutes tes quêtes quotidiennes avec brio.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Row(
                          children: [
                            Text('💎', style: TextStyle(fontSize: 18)),
                            SizedBox(width: 6),
                            Text(
                              '+25 Gemmes',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0284C7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Row(
                          children: [
                            Text('⚡', style: TextStyle(fontSize: 18)),
                            SizedBox(width: 6),
                            Text(
                              '+20 XP',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFD97706),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  DuoButton(
                    label: 'Génial !',
                    variant: DuoButtonVariant.primary,
                    onPressed: () => Navigator.of(dialogContext).pop(),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    RaetselManager.instance.unlockNotifier.removeListener(_onRaetselUnlockChanged);
    _isAutoPlayingBatch = false;
    _autoPlayDialoguePlayer?.dispose();
    TtsService.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final learnedCount = _userProgress.values
        .where((p) => p.level > 0 || p.reps > 0)
        .length;
    final totalPhrases = _allPhrases.isEmpty ? 1000 : _allPhrases.length;
    final progressFraction = totalPhrases > 0 ? learnedCount / totalPhrases : 0.0;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. En-tête : Hoppla ! + Voix réelles Conrad/Katja + Gemmes + XP + Série flamme
                    _buildHeader(isDark: isDark),

                    const SizedBox(height: 10),

                    // 1.1 Bandeau Candidat & Synchronisation Cloud
                    _buildCandidateCloudBanner(isDark: isDark),

                    const SizedBox(height: 14),

                    // 2. Mon Parcours : Carrousel interactif des lots avec jalons d'examen
                    _buildLearningPathCarousel(isDark: isDark),

                    const SizedBox(height: 14),

                    // 3. Grande Carte Héros : Lot Actif (Lot X) avec progression X/10, Mascot et tactile DuoButton
                    _buildHeroBatchCard(isDark: isDark),

                    const SizedBox(height: 14),

                    // 4. Bento Hub : Grand Examen de Palier (20/30) & Répétitions SRS côté à côté
                    _buildBentoActionHub(isDark: isDark),

                    const SizedBox(height: 14),

                    // 4.1 Carte Hoppla Rätsel (Mots croisés à niveaux) si débloqué après l'Examen 1
                    if (_isRaetselUnlocked) ...[
                      _buildRaetselCard(isDark: isDark),
                      const SizedBox(height: 14),
                    ],

                    // 5. Les 10 phrases du lot actif (Interactif avec écoute audio Conrad/Katja et annotations)
                    _buildTodayTenPhrasesSection(isDark: isDark),

                    const SizedBox(height: 14),

                    // 6. Section "Quêtes du jour" & Coffre bonus
                    _buildDailyQuestsCard(
                      isDark: isDark,
                      learnedCount: learnedCount,
                    ),

                    const SizedBox(height: 14),

                    // 7. Bannière Boutique Hoppla ! (Échange de Diamants)
                    _buildShopBanner(isDark: isDark),

                    const SizedBox(height: 14),

                    // 8. Carte "Phrase du jour" (Interactive avec audio & révélation de traduction)
                    if (_phraseOfTheDay != null)
                      _buildPhraseOfTheDayCard(
                        isDark: isDark,
                        phrase: _phraseOfTheDay!,
                      ),

                    const SizedBox(height: 14),

                    // 9. Carte Progression Globale
                    _buildProgressCard(
                      isDark: isDark,
                      learned: learnedCount,
                      total: totalPhrases,
                      fraction: progressFraction,
                    ),

                    const SizedBox(height: 14),

                    // 10. Emplacement Google Ads (AdMob)
                    _buildGoogleAdsBanner(isDark: isDark),

                    const SizedBox(height: 24),

                    // Ligne de phase actuelle
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.spa_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Phase actuelle : Écoute active & Ancrage',
                              style: AppTextStyles.caption(isDark: isDark).copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader({required bool isDark}) {
    final voicePref = TtsService.instance.voiceGenderPreference;
    final String voiceLabel;
    final IconData voiceIcon;
    if (voicePref == 'male') {
      voiceLabel = 'Conrad 👨';
      voiceIcon = Icons.record_voice_over_rounded;
    } else if (voicePref == 'female') {
      voiceLabel = 'Katja 👩';
      voiceIcon = Icons.record_voice_over_rounded;
    } else {
      voiceLabel = 'Duo 🎙️';
      voiceIcon = Icons.people_alt_rounded;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Hoppla !',
                  style: AppTextStyles.titleLarge(isDark: isDark).copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 26,
                    color: isDark ? const Color(0xFFFACC15) : const Color(0xFFCA8A04),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'DE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              _formatTodayDate(),
              style: AppTextStyles.caption(isDark: isDark),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sélecteur de Voix Réelle Native (Conrad 👨 / Katja 👩 / Duo 🎙️)
            Tooltip(
              message: 'Voix studio native : $voiceLabel (Toucher pour basculer)',
              child: InkWell(
                onTap: () async {
                  final next = voicePref == 'alternate' ? 'male' : (voicePref == 'male' ? 'female' : 'alternate');
                  await TtsService.instance.setVoiceGenderPreference(next);
                  if (mounted) setState(() {});
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(voiceIcon, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        voiceLabel,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          color: isDark ? Colors.white70 : const Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            // Gemmes (Ouvre la Boutique)
            Tooltip(
              message: 'Boutique Hoppla ! (Échanger mes diamants)',
              child: InkWell(
                onTap: () => ShopModal.show(context, onPurchased: _loadDashboardData),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0C243B) : const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.45),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.diamond_rounded, size: 15, color: Color(0xFF0284C7)),
                      const SizedBox(width: 4),
                      Text(
                        '$_totalGems',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            // XP du jour
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF332005) : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt_rounded, size: 16, color: Color(0xFFD97706)),
                  const SizedBox(width: 2),
                  Text(
                    '$_todayXp XP',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 11.5,
                      color: Color(0xFFD97706),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            // Badge Série de jours animé flamme
            DuoStreakWidget(
              streakDays: _streakDays,
              isCompact: true,
              hasFreeze: _profile.gelSerieDisponible,
            ),
          ],
        ),
      ],
    );
  }

  /// Bandeau profil candidat et synchronisation Cloud Supabase
  Widget _buildCandidateCloudBanner({required bool isDark}) {
    return Consumer(
      builder: (context, ref, child) {
        final authState = ref.watch(authControllerProvider);
        final isAuth = authState.isAuthenticated;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isAuth
                ? (isDark ? const Color(0xFF0F2E23) : const Color(0xFFECFDF5))
                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isAuth
                  ? AppColors.primary.withValues(alpha: 0.4)
                  : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: isAuth
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : Colors.grey.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isAuth ? Icons.cloud_done_rounded : Icons.cloud_outlined,
                  size: 20,
                  color: isAuth ? AppColors.primary : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAuth
                          ? 'Candidat : ${authState.candidateName}'
                          : 'Mode Hors-ligne (Invité)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      isAuth
                          ? (authState.isSyncing
                              ? 'Synchronisation en cours...'
                              : (authState.syncStatusMessage ?? 'Synchronisé avec Supabase ☁️'))
                          : 'Connectez-vous pour synchroniser vos 1000+ phrases',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white60 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isAuth)
                IconButton(
                  icon: const Icon(Icons.sync_rounded, size: 20, color: AppColors.primary),
                  tooltip: 'Synchroniser',
                  onPressed: () async {
                    await ref.read(authControllerProvider.notifier).triggerSync();
                    _loadDashboardData();
                  },
                )
              else
                ElevatedButton.icon(
                  onPressed: () => context.push('/auth').then((_) => _loadDashboardData()),
                  icon: const Icon(Icons.login_rounded, size: 14),
                  label: const Text('Connexion', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Carrousel interactif horizontal du parcours d'apprentissage (Lots 1 à 30 avec jalons d'examen)
  Widget _buildLearningPathCarousel({required bool isDark}) {
    if (_allPhrases.isEmpty) return const SizedBox.shrink();

    final totalBatches = (_allPhrases.length / 10).ceil().clamp(1, 100);
    final maxUnlockedBatch = _calculateUnlockedBatchIndex();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.route_rounded, size: 18, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  'Mon Parcours',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            Text(
              'Lot ${_currentBatchIndex + 1} / $totalBatches',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 62,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: totalBatches,
            separatorBuilder: (_, index) {
              final isPalierEnd = (index + 1) % 3 == 0;
              if (isPalierEnd) {
                final palierIndex = (index + 1) ~/ 3;
                final isPassed = MediaUnlockManager.isPalierExamPassed(palierIndex, _prefs);

                final palierStart = (palierIndex - 1) * 30;
                final palierEnd = (palierIndex * 30).clamp(0, _allPhrases.length);
                final palierPhrases = _allPhrases.sublist(palierStart, palierEnd);
                final completedInPalier = palierPhrases.where((p) {
                  final prog = _userProgress[p.id];
                  return prog != null && (prog.level > 0 || prog.reps > 0);
                }).length;
                final bool are30PhrasesCompleted = _isPalierReadyForExam(palierIndex);
                final bool isPalierUnlocked = isPassed || are30PhrasesCompleted;

                final lotA = (palierIndex - 1) * 3 + 1;
                final lotB = lotA + 1;
                final lotC = lotA + 2;

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () {
                        if (!isPalierUnlocked) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.lock_rounded, color: Colors.orangeAccent),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Examen P$palierIndex verrouillé 🔒. Validez d\'abord les Lots L$lotA, L$lotB et L$lotC ($completedInPalier/30 phrases terminées).',
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: const Color(0xFF0F172A),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                          return;
                        }

                        context.push('/palier-exam?palier=$palierIndex', extra: palierPhrases).then((_) {
                          if (mounted) _loadDashboardData();
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: isPassed
                              ? (isDark ? const Color(0xFF14301E) : const Color(0xFFDCFCE7))
                              : (isPalierUnlocked
                                  ? (isDark ? const Color(0xFF332005) : const Color(0xFFFEF3C7))
                                  : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9))),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isPassed
                                ? AppColors.primary
                                : (isPalierUnlocked ? const Color(0xFFF59E0B) : Colors.transparent),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isPassed
                                  ? Icons.workspace_premium_rounded
                                  : (isPalierUnlocked ? Icons.school_rounded : Icons.lock_rounded),
                              size: 18,
                              color: isPassed
                                  ? AppColors.primary
                                  : (isPalierUnlocked ? const Color(0xFFD97706) : const Color(0xFF94A3B8)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Examen P$palierIndex',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: isPassed
                                    ? AppColors.primary
                                    : (isPalierUnlocked ? const Color(0xFFD97706) : const Color(0xFF94A3B8)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                );
              }
              return const SizedBox(width: 6);
            },
            itemBuilder: (context, index) {
              final isCurrent = index == _currentBatchIndex;
              final isUnlocked = index <= maxUnlockedBatch;
              final start = index * 10;
              final end = (start + 10).clamp(0, _allPhrases.length);
              final batchPhrases = _allPhrases.sublist(start, end);
              final completedCount = batchPhrases.where((p) {
                final prog = _userProgress[p.id];
                return prog != null && (prog.level > 0 || prog.reps > 0);
              }).length;
              final isCompleted = completedCount >= batchPhrases.length && batchPhrases.isNotEmpty;

              return InkWell(
                onTap: () => _selectBatch(index),
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 72,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? (isDark ? const Color(0xFF0F3622) : const Color(0xFFDCFCE7))
                        : (isCompleted
                            ? (isDark ? const Color(0xFF14241B) : const Color(0xFFF0FDF4))
                            : (isUnlocked
                                ? (isDark ? AppColors.surfaceDark : Colors.white)
                                : (isDark ? const Color(0xFF131D26) : const Color(0xFFF1F5F9)))),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isCurrent
                          ? AppColors.primary
                          : (isCompleted
                              ? AppColors.primary.withValues(alpha: 0.4)
                              : (isUnlocked
                                  ? (isDark ? AppColors.borderDark : const Color(0xFFCBD5E1))
                                  : Colors.transparent)),
                      width: isCurrent ? 2.0 : 1.0,
                    ),
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isCompleted)
                            const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.primary)
                          else if (!isUnlocked)
                            const Icon(Icons.lock_rounded, size: 14, color: Color(0xFF94A3B8))
                          else if (isCurrent)
                            const Icon(Icons.play_circle_fill_rounded, size: 14, color: AppColors.primary)
                          else
                            const Icon(Icons.circle_outlined, size: 12, color: Color(0xFF64748B)),
                          const SizedBox(width: 3),
                          Text(
                            'L${index + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: isCurrent
                                  ? AppColors.primary
                                  : (isCompleted
                                      ? AppColors.primary
                                      : (isUnlocked
                                          ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                          : const Color(0xFF94A3B8))),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$completedCount/10',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isCurrent
                              ? AppColors.primary
                              : (isCompleted
                                  ? AppColors.primary.withValues(alpha: 0.8)
                                  : (isUnlocked
                                      ? (isDark ? Colors.white60 : const Color(0xFF64748B))
                                      : const Color(0xFF94A3B8))),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Grande Carte Héros : Lot Actif (Lot X) avec statut clair, barre de progression et boutons directs
  Widget _buildHeroBatchCard({required bool isDark}) {
    if (_todayTenPhrases.isEmpty) return const SizedBox.shrink();

    final totalBatches = (_allPhrases.length / 10).ceil().clamp(1, 100);
    final batchNum = _currentBatchIndex + 1;
    final startPhraseNum = _currentBatchIndex * 10 + 1;
    final endPhraseNum = (_currentBatchIndex * 10 + _todayTenPhrases.length).clamp(1, _allPhrases.length);

    final completedCount = _todayTenPhrases.where((p) {
      final prog = _userProgress[p.id];
      return prog != null && (prog.level > 0 || prog.reps > 0);
    }).length;

    final isBatchCompleted = completedCount >= _todayTenPhrases.length && _todayTenPhrases.isNotEmpty;
    final progressFraction = _todayTenPhrases.isNotEmpty ? completedCount / _todayTenPhrases.length : 0.0;

    if (isBatchCompleted) {
      MediaUnlockManager.unlockLot(batchNum, prefs: _prefs);
    }

    // Détection de fin de palier (tous les 30 phrases : Lot 3, Lot 6, etc.)
    final isPalierEnd = batchNum % 3 == 0;
    final palierIndex = batchNum ~/ 3;
    final bool isPalierExamPassed = MediaUnlockManager.isPalierExamPassed(palierIndex, _prefs);
    final bool needsPalierExam = isBatchCompleted && isPalierEnd && !isPalierExamPassed;

    return CustomCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1B3828) : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.explore_rounded, size: 15, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      'LOT $batchNum SUR $totalBatches',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Phrases $startPhraseNum-$endPhraseNum',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              MascotWidget(
                mood: needsPalierExam
                    ? MascotMood.thinking
                    : (isBatchCompleted ? MascotMood.celebrating : MascotMood.happy),
                size: 74,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      needsPalierExam
                          ? 'Palier $palierIndex (30 phrases) ! 🎓'
                          : (isBatchCompleted
                              ? 'Lot $batchNum complété ! 🎉'
                              : 'Objectif : Lot $batchNum'),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      needsPalierExam
                          ? 'Grand Examen obligatoire (20/30 min.)'
                          : (isBatchCompleted
                              ? 'Toutes les phrases sont au vert !'
                              : '$completedCount sur 10 phrases maîtrisées'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progressFraction,
              minHeight: 8,
              backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                needsPalierExam
                    ? Colors.amber
                    : (isBatchCompleted ? const Color(0xFFFF9600) : AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Gros bouton d'action principal
          SizedBox(
            width: double.infinity,
            child: DuoButton(
              label: needsPalierExam
                  ? '🎓 GRAND EXAMEN DU PALIER $palierIndex (20/30 requis)'
                  : (isBatchCompleted
                      ? '🏆 DÉFI MASTER XP (Valider le Lot $batchNum)'
                      : (completedCount > 0
                          ? '▶️ CONTINUER LE LOT $batchNum ($completedCount/10)'
                          : '🚀 COMMENCER LE LOT $batchNum')),
              variant: (needsPalierExam || isBatchCompleted)
                  ? DuoButtonVariant.secondary
                  : DuoButtonVariant.primary,
              icon: needsPalierExam
                  ? Icons.school_rounded
                  : (isBatchCompleted ? Icons.workspace_premium_rounded : Icons.play_arrow_rounded),
              onPressed: () async {
                await TtsService.instance.stop();
                if (!mounted) return;
                setState(() => _isPlayingAudio = false);

                if (needsPalierExam) {
                  final palierStart = (palierIndex - 1) * 30;
                  final palierEnd = (palierIndex * 30).clamp(0, _allPhrases.length);
                  final palierPhrases = _allPhrases.sublist(palierStart, palierEnd);
                  context.push('/palier-exam?palier=$palierIndex', extra: palierPhrases).then((_) {
                    if (mounted) _loadDashboardData();
                  });
                  return;
                }

                final ids = _todayTenPhrases.map((p) => p.id).toList();
                if (isBatchCompleted) {
                  context.push('/master-xp', extra: ids.isNotEmpty ? ids : null);
                } else {
                  context.push('/session', extra: ids.isNotEmpty ? ids : null).then((_) {
                    if (mounted) _loadDashboardData();
                  });
                }
              },
            ),
          ),
          const SizedBox(height: 10),
          // Barre d'actions rapides (3 pilules d'action avec icônes élégantes)
          Row(
            children: [
              Expanded(
                child: _buildQuickActionPill(
                  isDark: isDark,
                  iconData: Icons.auto_stories_rounded,
                  iconColor: AppColors.primary,
                  label: 'Apprendre',
                  onTap: () async {
                    await TtsService.instance.stop();
                    if (!mounted) return;
                    setState(() => _isPlayingAudio = false);
                    final ids = _todayTenPhrases.map((p) => p.id).toList();
                    context.push('/session', extra: ids).then((_) {
                      if (mounted) _loadDashboardData();
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildQuickActionPill(
                  isDark: isDark,
                  iconData: _isAutoPlayingBatch ? Icons.stop_circle_rounded : Icons.headphones_rounded,
                  iconColor: const Color(0xFF0284C7),
                  label: _isAutoPlayingBatch ? 'Arrêter' : 'Écoute auto',
                  isActive: _isAutoPlayingBatch,
                  onTap: _toggleAutoPlayBatch,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildQuickActionPill(
                  isDark: isDark,
                  iconData: needsPalierExam ? Icons.school_rounded : Icons.bolt_rounded,
                  iconColor: needsPalierExam ? const Color(0xFFEA580C) : const Color(0xFFD97706),
                  label: needsPalierExam ? 'Examen' : 'Master XP',
                  onTap: () async {
                    await TtsService.instance.stop();
                    if (!mounted) return;
                    setState(() => _isPlayingAudio = false);
                    if (needsPalierExam) {
                      final palierStart = (palierIndex - 1) * 30;
                      final palierEnd = (palierIndex * 30).clamp(0, _allPhrases.length);
                      final palierPhrases = _allPhrases.sublist(palierStart, palierEnd);
                      context.push('/palier-exam?palier=$palierIndex', extra: palierPhrases).then((_) {
                        if (mounted) _loadDashboardData();
                      });
                    } else {
                      final ids = _todayTenPhrases.map((p) => p.id).toList();
                      context.push('/master-xp', extra: ids.isNotEmpty ? ids : null);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }



  Widget _buildQuickActionPill({
    required bool isDark,
    required IconData iconData,
    Color? iconColor,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    final effectiveIconColor = iconColor ?? (isActive ? Colors.redAccent : AppColors.primary);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark ? const Color(0xFF2E1B1B) : const Color(0xFFFEE2E2))
              : (isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? Colors.redAccent
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              iconData,
              size: 16,
              color: isActive ? Colors.redAccent : effectiveIconColor,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: isActive
                    ? Colors.redAccent
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Bento Hub : Regroupe le Grand Examen de Palier et la Spirale SRS dans un format moderne à 2 colonnes
  Widget _buildBentoActionHub({required bool isDark}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 440;
        if (isNarrow) {
          return Column(
            children: [
              _buildPalierExamTile(isDark: isDark),
              const SizedBox(height: 12),
              _buildRepetitionsTile(isDark: isDark),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildPalierExamTile(isDark: isDark)),
            const SizedBox(width: 12),
            Expanded(child: _buildRepetitionsTile(isDark: isDark)),
          ],
        );
      },
    );
  }

  /// Tuile Bento : Grand Examen de Palier (tous les 30 phrases, seuil 20/30)
  Widget _buildPalierExamTile({required bool isDark}) {
    if (_allPhrases.isEmpty) return const SizedBox.shrink();

    final palierIndex = (_currentBatchIndex ~/ 3) + 1;
    final palierStart = (palierIndex - 1) * 30;
    final palierEnd = (palierIndex * 30).clamp(0, _allPhrases.length);
    final palierPhrases = _allPhrases.sublist(palierStart, palierEnd);

    final completedInPalier = palierPhrases.where((p) {
      final prog = _userProgress[p.id];
      return prog != null && (prog.level > 0 || prog.reps > 0);
    }).length;

    final bool isExamPassed = MediaUnlockManager.isPalierExamPassed(palierIndex, _prefs);
    final int? lastScore = _prefs?.getInt('palier_exam_${palierIndex}_score');
    final bool are30PhrasesCompleted = _isPalierReadyForExam(palierIndex);

    final lotA = (palierIndex - 1) * 3 + 1;
    final lotB = lotA + 1;
    final lotC = lotA + 2;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isExamPassed
              ? AppColors.primary.withValues(alpha: 0.4)
              : (are30PhrasesCompleted
                  ? const Color(0xFFF59E0B).withValues(alpha: 0.5)
                  : (isDark ? AppColors.borderDark : AppColors.borderLight)),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isExamPassed
                      ? (isDark ? const Color(0xFF14301E) : const Color(0xFFDCFCE7))
                      : (are30PhrasesCompleted
                          ? (isDark ? const Color(0xFF332005) : const Color(0xFFFEF3C7))
                          : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9))),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isExamPassed
                          ? Icons.workspace_premium_rounded
                          : (are30PhrasesCompleted ? Icons.school_rounded : Icons.lock_rounded),
                      size: 14,
                      color: isExamPassed
                          ? AppColors.primary
                          : (are30PhrasesCompleted ? const Color(0xFFD97706) : const Color(0xFF94A3B8)),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'PALIER $palierIndex',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: isExamPassed
                            ? AppColors.primary
                            : (are30PhrasesCompleted ? const Color(0xFFD97706) : const Color(0xFF94A3B8)),
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: isExamPassed
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : (lastScore != null ? Colors.red.withValues(alpha: 0.12) : (isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9))),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  lastScore != null ? '$lastScore/30 pts' : 'Seuil 20/30',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: isExamPassed
                        ? AppColors.primary
                        : (lastScore != null ? Colors.redAccent : (isDark ? Colors.white60 : const Color(0xFF64748B))),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isExamPassed
                ? 'Examen Validé ! 🎓'
                : (are30PhrasesCompleted ? 'Examen Prêt ! 🏆' : 'Grand Examen (30 Q) · Verrouillé 🔒'),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            isExamPassed
                ? 'Note : ${lastScore ?? 20}/30 · Approuvé'
                : (are30PhrasesCompleted
                    ? 'Note min. 20/30 requise · Lots L$lotA, L$lotB, L$lotC validés'
                    : '$completedInPalier / 30 phrases prêtes (Requis : Lots L$lotA, L$lotB, L$lotC)'),
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: palierPhrases.isNotEmpty ? (completedInPalier / palierPhrases.length).clamp(0.0, 1.0) : 0.0,
              minHeight: 5,
              backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                isExamPassed ? AppColors.primary : (are30PhrasesCompleted ? const Color(0xFFF59E0B) : const Color(0xFF94A3B8)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: DuoButton(
              label: isExamPassed
                  ? '🔄 Repasser'
                  : (are30PhrasesCompleted ? '🎓 Passer l\'Examen' : '🔒 Verrouillé ($completedInPalier/30)'),
              variant: (!isExamPassed && are30PhrasesCompleted)
                  ? DuoButtonVariant.secondary
                  : DuoButtonVariant.outline,
              icon: isExamPassed
                  ? Icons.replay_rounded
                  : (are30PhrasesCompleted ? Icons.school_rounded : Icons.lock_rounded),
              onPressed: (isExamPassed || are30PhrasesCompleted)
                  ? () async {
                      await TtsService.instance.stop();
                      if (!mounted) return;
                      setState(() => _isPlayingAudio = false);
                      context.push('/palier-exam?palier=$palierIndex', extra: palierPhrases).then((_) {
                        if (mounted) _loadDashboardData();
                      });
                    }
                  : () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.lock_rounded, color: Colors.orangeAccent),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Examen P$palierIndex verrouillé 🔒. Validez d\'abord les Lots L$lotA, L$lotB et L$lotC ($completedInPalier/30 phrases terminées).',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: const Color(0xFF0F172A),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    },
            ),
          ),
        ],
      ),
    );
  }

  /// Construit la liste des phrases pour "Répétitions & Ancrage" selon la règle utilisateur :
  /// 1. Priorité aux phrases où le candidat a commis des erreurs (lapses > 0, lastResult == false, fragile)
  /// 2. Pioche aléatoire parmi TOUS les lots précédents (du premier Lot 1 de 10 jusqu'au lot actuel à l'infini)
  List<String> _buildRepetitionPhraseIds({int targetCount = 10}) {
    if (_allPhrases.isEmpty) return [];

    final maxUnlockedBatch = _calculateUnlockedBatchIndex();
    // Vivier englobant tous les lots débloqués depuis le premier Lot 1 (phrases 1 à 10) jusqu'au lot courant
    final maxPhraseIndex = ((maxUnlockedBatch + 1) * 10).clamp(0, _allPhrases.length);
    final poolPhrases = _allPhrases.sublist(0, maxPhraseIndex);

    // 1. Détecter les vraies erreurs (fautes réelles) et les phrases en cours d'assimilation
    final List<Phrase> realErrorPhrases = [];
    final List<Phrase> inProgressPhrases = [];
    final List<Phrase> otherLearnedPhrases = [];

    for (final phrase in poolPhrases) {
      final prog = _userProgress[phrase.id];
      if (prog == null) continue;

      final bool hasRealError = prog.lastResult == false ||
          prog.consecutiveErrors > 0 ||
          (prog.lapses > 0 && prog.level <= 1) ||
          prog.isDifficult;

      final bool isFragile = prog.level == 1 && !hasRealError;
      final bool isLearned = prog.level > 1 || (prog.reps > 0 && prog.lastResult == true);

      if (hasRealError) {
        realErrorPhrases.add(phrase);
      } else if (isFragile) {
        inProgressPhrases.add(phrase);
      } else if (isLearned) {
        otherLearnedPhrases.add(phrase);
      }
    }

    // Trier les erreurs : les erreurs actives non corrigées (lastResult == false) en priorité absolue
    realErrorPhrases.sort((a, b) {
      final progA = _userProgress[a.id];
      final progB = _userProgress[b.id];
      if ((progA?.lastResult == false) != (progB?.lastResult == false)) {
        return (progA?.lastResult == false) ? -1 : 1;
      }
      return (progB?.lapses ?? 0).compareTo(progA?.lapses ?? 0);
    });

    inProgressPhrases.shuffle();
    otherLearnedPhrases.shuffle();

    final List<String> selectedIds = [];

    // Priorité 1 : phrases avec fautes réelles captées
    for (final phrase in realErrorPhrases) {
      if (selectedIds.length >= targetCount) break;
      selectedIds.add(phrase.id);
    }

    // Priorité 2 : phrases en cours d'assimilation (niveau 1)
    if (selectedIds.length < targetCount) {
      for (final phrase in inProgressPhrases) {
        if (selectedIds.length >= targetCount) break;
        if (!selectedIds.contains(phrase.id)) {
          selectedIds.add(phrase.id);
        }
      }
    }

    // Priorité 3 : piocher aléatoirement parmi TOUS les lots précédents (du Lot 1 jusqu'au lot actuel à l'infini)
    if (selectedIds.length < targetCount) {
      for (final phrase in otherLearnedPhrases) {
        if (selectedIds.length >= targetCount) break;
        if (!selectedIds.contains(phrase.id)) {
          selectedIds.add(phrase.id);
        }
      }
    }

    // Fallback si le candidat commence tout juste le Lot 1
    if (selectedIds.isEmpty) {
      selectedIds.addAll(_todayTenPhrases.map((p) => p.id));
    }

    return selectedIds;
  }

  /// Tuile Bento : Répétitions & Ancrage (SRS)
  Widget _buildRepetitionsTile({required bool isDark}) {
    final maxUnlockedBatch = _calculateUnlockedBatchIndex();
    final maxPhraseIndex = ((maxUnlockedBatch + 1) * 10).clamp(0, _allPhrases.length);
    final poolPhrases = _allPhrases.sublist(0, maxPhraseIndex);

    final realErrorPhrases = poolPhrases.where((p) {
      final prog = _userProgress[p.id];
      return prog != null && (
          prog.lastResult == false ||
          prog.consecutiveErrors > 0 ||
          (prog.lapses > 0 && prog.level <= 1) ||
          prog.isDifficult
      );
    }).toList();

    final currentLotNum = _currentBatchIndex + 1;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: realErrorPhrases.isNotEmpty
              ? const Color(0xFFF59E0B).withValues(alpha: 0.5)
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0C243B) : const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sync_rounded, size: 14, color: Color(0xFF0284C7)),
                    SizedBox(width: 4),
                    Text(
                      'SRS SPIRALE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0284C7),
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: realErrorPhrases.isNotEmpty
                      ? const Color(0xFFFEF3C7)
                      : (isDark ? const Color(0xFF14301E) : const Color(0xFFDCFCE7)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  realErrorPhrases.isNotEmpty ? '${realErrorPhrases.length} erreurs' : '✨ Au top',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: realErrorPhrases.isNotEmpty ? const Color(0xFFB45309) : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Répétitions & Ancrage',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            realErrorPhrases.isNotEmpty
                ? '⚠️ ${realErrorPhrases.length} phrase${realErrorPhrases.length > 1 ? 's' : ''} avec erreur à refaire'
                : 'Vivier Lots 1 à $currentLotNum (${poolPhrases.length} phrases)',
            style: TextStyle(
              fontSize: 11,
              color: realErrorPhrases.isNotEmpty
                  ? (isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309))
                  : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: realErrorPhrases.isEmpty ? 1.0 : (1.0 - (realErrorPhrases.length / poolPhrases.length.clamp(1, 100))).clamp(0.1, 1.0),
              minHeight: 5,
              backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                realErrorPhrases.isNotEmpty ? const Color(0xFFF59E0B) : const Color(0xFF0284C7),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: DuoButton(
              label: realErrorPhrases.isNotEmpty ? '🔁 Refaire les erreurs (${realErrorPhrases.length})' : '🔁 Réviser',
              variant: realErrorPhrases.isNotEmpty ? DuoButtonVariant.secondary : DuoButtonVariant.outline,
              icon: Icons.repeat_rounded,
              onPressed: () async {
                await TtsService.instance.stop();
                if (!mounted) return;
                setState(() => _isPlayingAudio = false);
                final repIds = _buildRepetitionPhraseIds(targetCount: 10);
                context.push('/session', extra: repIds).then((_) => _loadDashboardData());
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Carte interactive Hoppla Rätsel (Mots croisés à niveaux)
  /// Débloquée immédiatement après la réussite de l'Examen 1 (20/30)
  Widget _buildRaetselCard({required bool isDark}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0F766E), const Color(0xFF134E4A)]
              : [const Color(0xFF14B8A6), const Color(0xFF0D9488)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D9488).withValues(alpha: isDark ? 0.35 : 0.25),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            context.go('/raetsel');
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Badge icône puzzle
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.extension_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 14),
                // Titre et détails
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'HOPPLA RÄTSEL',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.bolt_rounded, size: 14, color: AppColors.accentLight),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Jouer au Niveau $_raetselLevelNum',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Mots croisés avec tes phrases apprises',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                // Bouton Jouer
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Jouer',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F766E),
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.play_arrow_rounded,
                        size: 18,
                        color: Color(0xFF0F766E),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCard({
    required bool isDark,
    required int learned,
    required int total,
    required double fraction,
  }) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progression',
                style: AppTextStyles.bodyLarge(isDark: isDark).copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$learned / $total phrases',
                style: AppTextStyles.bodyMedium(isDark: isDark).copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppProgressBar(
            value: fraction > 0 ? fraction : 0.05,
            height: 10,
          ),
        ],
      ),
    );
  }

  /// Bannière d'accès direct à la Boutique Hoppla ! (Échange de diamants)
  Widget _buildShopBanner({required bool isDark}) {
    return InkWell(
      onTap: () => ShopModal.show(context, onPurchased: _loadDashboardData),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF0C243B), const Color(0xFF1E293B)]
                : [const Color(0xFFE0F2FE), const Color(0xFFF0F9FF)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFF0284C7).withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.storefront_rounded, size: 24, color: Color(0xFF0284C7)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Boutique Hoppla !',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : const Color(0xFF0369A1),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.diamond_rounded, size: 11, color: Colors.white),
                            const SizedBox(width: 3),
                            Text(
                              '$_totalGems',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Échange tes diamants : Gel de série, Joker d\'examen, Double XP...',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF0284C7),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  /// Emplacement dédié et balisé pour les bannières Google Ads / AdMob
  ///
  /// Pour activer de vraies bannières :
  /// 1. Ajouter le package `google_mobile_ads: ^5.1.0` dans pubspec.yaml
  /// 2. Initialiser dans main.dart : `await MobileAds.instance.initialize();`
  /// 3. Remplacer ce widget par : `AdWidget(ad: myBannerAd)`
  Widget _buildGoogleAdsBanner({required bool isDark}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131F18) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF23382B) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: const Icon(
              Icons.campaign_outlined,
              color: AppColors.secondary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'ANNONCE SPONSORISÉE',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: AppColors.secondary,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Google AdMob',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Emplacement bannière publicitaire (320x50 ou Adaptative)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Carte interactive "Phrase du jour" avec audio, audio-feedback et révélation progressive
  Widget _buildPhraseOfTheDayCard({
    required bool isDark,
    required Phrase phrase,
  }) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF263228) : AppColors.secondaryLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.secondary.withValues(alpha: 0.4),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, size: 15, color: AppColors.secondary),
                    SizedBox(width: 5),
                    Text(
                      'Phrase du jour',
                      style: TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              if (phrase.theme.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    phrase.theme.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Phrase allemande mise en valeur avec articles colorés
          Center(
            child: GermanTextView(
              text: phrase.de,
              baseStyle: AppTextStyles.germanPhraseSmall(isDark: isDark).copyWith(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Bloc interactif Révélation de la traduction
          InkWell(
            onTap: () {
              setState(() => _showPhraseTranslation = !_showPhraseTranslation);
            },
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF14241B) : const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  width: 1.2,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _showPhraseTranslation
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _showPhraseTranslation
                            ? 'Masquer la traduction'
                            : 'Appuyer pour révéler la traduction',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  if (_showPhraseTranslation) ...[
                    const SizedBox(height: 10),
                    Text(
                      phrase.fr,
                      style: AppTextStyles.bodyMedium(isDark: isDark).copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (phrase.ar != null && phrase.ar!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      ArabicTextView(
                        text: phrase.ar!,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.arabicPrimaryDark : AppColors.arabicPrimaryLight,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Bouton d'écoute audio TTS & Sélecteur de voix native (Homme / Femme / Alterné)
          Center(
            child: Column(
              children: [
                AudioButton(
                  onPressed: () => _speakPhrase(phrase.de, isPhraseOfTheDay: true),
                  isPlaying: _isPlayingAudio,
                  size: 56,
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final current = TtsService.instance.voiceGenderPreference;
                    final next = (current == 'alternate')
                        ? 'male'
                        : (current == 'male' ? 'female' : 'alternate');
                    await TtsService.instance.setVoiceGenderPreference(next);
                    setState(() {});
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          TtsService.instance.voiceGenderPreference == 'male'
                              ? Icons.face_rounded
                              : (TtsService.instance.voiceGenderPreference == 'female'
                                  ? Icons.face_3_rounded
                                  : Icons.sync_rounded),
                          size: 14,
                          color: TtsService.instance.voiceGenderPreference == 'female'
                              ? const Color(0xFFE11D48)
                              : (TtsService.instance.voiceGenderPreference == 'male'
                                  ? const Color(0xFF0284C7)
                                  : AppColors.primary),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          TtsService.instance.voiceGenderPreference == 'male'
                              ? 'Voix : Conrad (Homme 👨)'
                              : (TtsService.instance.voiceGenderPreference == 'female'
                                  ? 'Voix : Katja (Femme 👩)'
                                  : 'Voix : Duo Alterné 🔄'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white70 : const Color(0xFF334155),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Section "Quêtes du jour" style Duolingo, renouvelée chaque jour
  Widget _buildDailyQuestsCard({
    required bool isDark,
    required int learnedCount,
  }) {
    final now = DateTime.now();
    final quests = _getDailyQuests(now, learnedCount);
    final completedCount = quests.where((q) => q.isCompleted).length;
    final allCompleted = completedCount == quests.length;

    // Temps restant avant le renouvellement automatique à minuit
    final hoursRemaining = 23 - now.hour;
    final minutesRemaining = 59 - now.minute;
    final renewalText = '${hoursRemaining}h ${minutesRemaining.toString().padLeft(2, '0')}m';

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF4E5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.track_changes_rounded, size: 20, color: Color(0xFFD97706)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quêtes du jour',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.titleSmall(isDark: isDark).copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                size: 11,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  'Renouvellement dans $renewalText',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.refresh_rounded,
                      size: 18,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                    tooltip: 'Réinitialiser les quêtes du jour pour tester',
                    visualDensity: VisualDensity.compact,
                    onPressed: _resetDailyQuestsForTesting,
                  ),
                  const SizedBox(width: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: allCompleted
                          ? AppColors.primaryLight
                          : (isDark ? AppColors.surfaceDark : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: allCompleted
                            ? AppColors.primary
                            : (isDark ? AppColors.borderDark : AppColors.borderLight),
                      ),
                    ),
                    child: Text(
                      '$completedCount / ${quests.length} complétées',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: allCompleted
                            ? AppColors.primary
                            : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (allCompleted) ...[
            const SizedBox(height: 14),
            _isChestClaimedToday
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF162B1D) : const Color(0xFFEFFDF5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_rounded, size: 16, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text(
                          'Coffre bonus du jour réclamé (+25 💎 & +20 XP)',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  )
                : InkWell(
                    onTap: _claimDailyChest,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF9600), Color(0xFFFFB700)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF9600).withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.card_giftcard_rounded, size: 20, color: Colors.white),
                          SizedBox(width: 10),
                          Text(
                            'Ouvrir mon Coffre Bonus (+25 💎 & +20 XP)',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ],
          const SizedBox(height: 14),
          for (int i = 0; i < quests.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _buildQuestRow(
              isDark: isDark,
              iconData: quests[i].iconData,
              iconColor: quests[i].iconColor,
              iconBg: quests[i].iconBg,
              title: quests[i].title,
              current: quests[i].current,
              target: quests[i].target,
              unit: quests[i].unit,
              fraction: quests[i].fraction,
              rewardText: quests[i].rewardText,
              isCompleted: quests[i].isCompleted,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuestRow({
    required bool isDark,
    required IconData iconData,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required int current,
    required int target,
    required String unit,
    required double fraction,
    required String rewardText,
    required bool isCompleted,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14221A) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCompleted
              ? AppColors.primary.withValues(alpha: 0.5)
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(iconData, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      unit.isNotEmpty ? '$current / $target $unit' : '$current / $target',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isCompleted
                            ? AppColors.primary
                            : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: fraction,
                    minHeight: 7,
                    backgroundColor: isDark ? const Color(0xFF263A2E) : const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isCompleted ? AppColors.primary : AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : (isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC)),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isCompleted
                    ? AppColors.primary.withValues(alpha: 0.4)
                    : (isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
            ),
            child: isCompleted
                ? const Text(
                    '✓ Fait',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        rewardText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isDark ? const Color(0xFF90CAF9) : const Color(0xFF0284C7),
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(
                        Icons.diamond_rounded,
                        size: 11,
                        color: isDark ? const Color(0xFF90CAF9) : const Color(0xFF0284C7),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  /// Section interactive : Les 10 phrases de la séance du jour (avec navigation par lot)
  Widget _buildTodayTenPhrasesSection({required bool isDark}) {
    if (_todayTenPhrases.isEmpty) return const SizedBox.shrink();

    final totalBatches = (_allPhrases.length / 10).ceil().clamp(1, 100);
    final maxUnlockedBatch = _calculateUnlockedBatchIndex();
    final batchNum = _currentBatchIndex + 1;
    final startPhraseNum = _currentBatchIndex * 10 + 1;
    final endPhraseNum = (_currentBatchIndex * 10 + _todayTenPhrases.length).clamp(1, _allPhrases.length);

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1B3828) : AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.translate_rounded, size: 18, color: AppColors.primary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lot $batchNum sur $totalBatches (Phrases $startPhraseNum-$endPhraseNum)',
                            style: AppTextStyles.titleSmall(isDark: isDark).copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            'Écoute, répète et valide ce lot',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded, size: 16),
                    color: _currentBatchIndex > 0 ? AppColors.primary : Colors.grey.withValues(alpha: 0.3),
                    onPressed: _currentBatchIndex > 0 ? () => _changeBatch(-1) : null,
                    tooltip: 'Lot précédent',
                  ),
                  IconButton(
                    icon: Icon(
                      _currentBatchIndex < maxUnlockedBatch ? Icons.arrow_forward_ios_rounded : Icons.lock_rounded,
                      size: 16,
                    ),
                    color: _currentBatchIndex < maxUnlockedBatch ? AppColors.primary : Colors.grey.withValues(alpha: 0.3),
                    onPressed: _currentBatchIndex < maxUnlockedBatch ? () => _changeBatch(1) : null,
                    tooltip: _currentBatchIndex < maxUnlockedBatch ? 'Lot suivant' : 'Lot suivant verrouillé 🔒',
                  ),
                  IconButton(
                    icon: Icon(
                      _showAllTenPhrases ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      color: AppColors.primary,
                    ),
                    onPressed: () {
                      setState(() => _showAllTenPhrases = !_showAllTenPhrases);
                    },
                  ),
                ],
              ),
            ],
          ),
          if (_showAllTenPhrases) ...[
            const SizedBox(height: 14),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _todayTenPhrases.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final phrase = _todayTenPhrases[index];
                final isPlaying = _currentlyPlayingPhraseId == phrase.id;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF14241B) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isPlaying
                          ? AppColors.primary
                          : (isDark ? AppColors.borderDark : AppColors.borderLight),
                      width: isPlaying ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.4),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: GermanTextView(
                                    text: phrase.de,
                                    baseStyle: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Builder(
                                  builder: (context) {
                                    final prog = _userProgress[phrase.id];
                                    final bool isMastered = prog != null && prog.level >= 2;
                                    final bool isInProgress = prog != null && (prog.level == 1 || prog.reps > 0);
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isMastered
                                            ? const Color(0xFFE8F5E9)
                                            : (isInProgress ? const Color(0xFFFFF3E0) : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9))),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        isMastered ? '✓ Maîtrisée' : (isInProgress ? 'En cours' : 'Nouvelle'),
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: isMastered
                                              ? const Color(0xFF2E7D32)
                                              : (isInProgress ? const Color(0xFFE65100) : (isDark ? Colors.white60 : const Color(0xFF64748B))),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              phrase.fr,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                            if (phrase.ar != null && phrase.ar!.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              ArabicTextView(
                                text: phrase.ar!,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.arabicPrimaryDark : AppColors.arabicPrimaryLight,
                                textAlign: TextAlign.start,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Bouton d'écoute audio TTS individuel avec sécurité anti-doublon vocal
                      IconButton(
                        icon: Icon(
                          isPlaying ? Icons.stop_circle_rounded : Icons.volume_up_rounded,
                          color: isPlaying ? AppColors.secondary : AppColors.primary,
                          size: 24,
                        ),
                        onPressed: () async {
                          if (isPlaying) {
                            await TtsService.instance.stop();
                            if (mounted) setState(() => _currentlyPlayingPhraseId = null);
                          } else {
                            await TtsService.instance.stop();
                            if (mounted) setState(() => _currentlyPlayingPhraseId = phrase.id);
                            await TtsService.instance.speak(
                              phrase.de,
                              phraseId: phrase.id,
                              onDone: () {
                                if (mounted) setState(() => _currentlyPlayingPhraseId = null);
                              },
                            );
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: DuoButton(
                    label: 'Démarrer le Lot $batchNum ➔',
                    icon: Icons.play_arrow_rounded,
                    variant: DuoButtonVariant.primary,
                    onPressed: () {
                      final ids = _todayTenPhrases.map((p) => p.id).toList();
                      context.push('/session', extra: ids).then((_) => _loadDashboardData());
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: DuoButton(
                    label: 'Master XP',
                    icon: Icons.workspace_premium_rounded,
                    variant: DuoButtonVariant.secondary,
                    onPressed: () {
                      final ids = _todayTenPhrases.map((p) => p.id).toList();
                      context.push('/master-xp', extra: ids.isNotEmpty ? ids : null);
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatTodayDate() {
    final now = DateTime.now();
    final months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    final days = [
      'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'
    ];
    return '${days[now.weekday - 1]} ${now.day} ${months[now.month - 1]}';
  }
}
