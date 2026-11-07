import 'package:flutter/material.dart';
import '../../../core/services/audio_recording_service.dart';
import '../../../core/services/tts_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_progress_bar.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/mic_button.dart';
import '../../../core/widgets/spoken_phrase_card.dart';
import '../../../data/database/app_database.dart';
import '../../../domain/engine/srs_engine.dart';
import '../../../domain/models/phrase.dart';
import '../../../domain/models/topic.dart';
import '../../../domain/models/user_phrase.dart';

/// Écran complet de détail d'une phrase allemande.
class PhraseDetailScreen extends StatefulWidget {
  final String phraseId;

  const PhraseDetailScreen({
    super.key,
    required this.phraseId,
  });

  @override
  State<PhraseDetailScreen> createState() => _PhraseDetailScreenState();
}

class _PhraseDetailScreenState extends State<PhraseDetailScreen> {
  final AppDatabase _database = AppDatabase.instance;
  final TtsService _tts = TtsService.instance;
  final AudioRecordingService _audio = AudioRecordingService.instance;

  bool _isLoading = true;
  Phrase? _phrase;
  UserPhrase? _userPhrase;
  List<Map<String, dynamic>> _attempts = [];
  List<Map<String, dynamic>> _examples = [];

  bool _isRecording = false;
  bool _isPlayingUserVoice = false;

  @override
  void initState() {
    super.initState();
    _loadPhraseData();
    _listenAudio();
  }

  void _listenAudio() {
    _audio.isRecordingNotifier.addListener(() {
      if (mounted) setState(() => _isRecording = _audio.isRecording);
    });
    _audio.isPlayingRecordingNotifier.addListener(() {
      if (mounted) setState(() => _isPlayingUserVoice = _audio.isPlayingRecording);
    });
  }

  Future<void> _loadPhraseData() async {
    setState(() => _isLoading = true);
    final phrase = await _database.getPhraseById(widget.phraseId);
    final allProgress = await _database.getAllUserPhrases();
    final attempts = await _database.getAttemptsForPhrase(widget.phraseId);
    final examples = await _database.getExamplesForPhrase(widget.phraseId);

    if (mounted) {
      setState(() {
        _phrase = phrase;
        _userPhrase = allProgress[widget.phraseId];
        _attempts = attempts;
        _examples = examples;
        _isLoading = false;
      });
    }
  }

  Future<void> _speak({bool slow = false, double? rate}) async {
    if (_phrase == null) return;
    await _tts.speak(_phrase!.de, phraseId: _phrase!.id, slow: slow, customRate: rate);
  }

  Future<void> _toggleShadowing() async {
    if (_phrase == null) return;
    if (_isRecording) {
      final path = await _audio.stopRecording();
      if (path != null) {
        await _audio.playRecording(
          path: path,
          onDone: () async {
            await Future.delayed(const Duration(milliseconds: 300));
            await _speak(slow: false);
          },
        );
      }
    } else {
      await _tts.stop();
      await _audio.startRecording();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_phrase == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Phrase introuvable.')),
      );
    }

    final phrase = _phrase!;
    final topic = TopicInfo.getById(phrase.topic);
    final userPhrase = _userPhrase;
    final level = userPhrase?.level ?? 0;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(topic.title, style: AppTextStyles.titleMedium(isDark: isDark)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          children: [
            // Grande carte principale de la phrase parlée (Étape 2)
            SpokenPhraseCard(
              phrase: phrase,
              preferredTranslationLanguage: 'ar',
              initialShowTranslation: true,
              initialShowStandard: true,
              onPlayNormal: () => _speak(slow: false),
              onPlaySlow: () => _speak(slow: true),
              onTooEasy: () async {
                final messenger = ScaffoldMessenger.of(context);
                final current = _userPhrase ?? UserPhrase(phraseId: phrase.id, dueAt: DateTime.now());
                final updated = const SrsEngine().markAsTooEasy(current);
                await _database.saveProgression(updated);
                if (mounted) {
                  setState(() => _userPhrase = updated);
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Phrase marquée comme connue (Niveau 4, révision dans 7 jours) !'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                }
              },
            ),

            const SizedBox(height: 20),

            // Section Shadowing à la demande
            CustomCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.record_voice_over_rounded, color: AppColors.accentDark, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        'Shadowing à la demande',
                        style: AppTextStyles.bodyLarge(isDark: isDark).copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Entraîne-toi à répéter la phrase avec le bon rythme et réécoute-toi.',
                    style: AppTextStyles.caption(isDark: isDark),
                  ),
                  const SizedBox(height: 18),
                  MicButton(
                    isRecording: _isRecording,
                    onPressed: _toggleShadowing,
                    label: _isRecording
                        ? 'Enregistrement en cours...'
                        : (_isPlayingUserVoice ? 'Réécoute de ta voix...' : 'Appuie pour t’enregistrer'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Carte Niveau SRS et prochaine révision
            CustomCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Maîtrise de la phrase',
                        style: AppTextStyles.bodyLarge(isDark: isDark).copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        level >= 6 ? 'Maîtrisée ⭐' : 'Niveau $level / 6',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AppProgressBar(
                    value: (level / 6).clamp(0.05, 1.0),
                    height: 10,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.event_repeat_rounded, size: 18, color: AppColors.textSecondaryLight),
                      const SizedBox(width: 8),
                      Text(
                        _formatNextReview(userPhrase?.dueAt),
                        style: AppTextStyles.bodyMedium(isDark: isDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        '${userPhrase?.reps ?? 0} répétitions réussies · ${userPhrase?.lapses ?? 0} erreurs douces',
                        style: AppTextStyles.caption(isDark: isDark),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (_examples.isNotEmpty) ...[
              const SizedBox(height: 20),
              CustomCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'Mes exemples créés (${_examples.length})',
                          style: AppTextStyles.bodyLarge(isDark: isDark).copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._examples.map((ex) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1B2F22) : AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '• ${ex['example_de'] ?? ''}',
                          style: AppTextStyles.bodyMedium(isDark: isDark).copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Historique des passages
            if (_attempts.isNotEmpty)
              CustomCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Historique des révisions',
                      style: AppTextStyles.bodyLarge(isDark: isDark).copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ..._attempts.map((att) {
                      final success = (att['success'] as int) == 1;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          children: [
                            Icon(
                              success ? Icons.check_circle_rounded : Icons.replay_rounded,
                              color: success ? AppColors.primary : AppColors.gentleError,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                att['exercise_type'] ?? 'Exercice',
                                style: AppTextStyles.bodyMedium(isDark: isDark),
                              ),
                            ),
                            Text(
                              success ? 'Réussi' : 'À revoir',
                              style: TextStyle(
                                color: success ? AppColors.primary : AppColors.gentleError,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _formatNextReview(DateTime? dueAt) {
    if (dueAt == null) return 'Prochaine révision : non planifiée';
    final now = DateTime.now();
    if (dueAt.isBefore(now)) {
      return 'Prochaine révision : Disponible maintenant !';
    }
    final diffDays = dueAt.difference(now).inDays;
    if (diffDays == 0) {
      return 'Prochaine révision : Aujourd’hui';
    } else if (diffDays == 1) {
      return 'Prochaine révision : Demain';
    }
    return 'Prochaine révision : Dans $diffDays jours';
  }
}
