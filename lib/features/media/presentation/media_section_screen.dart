import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/database/app_database.dart';
import '../../../domain/models/media_content.dart';
import '../../../domain/models/phrase.dart';
import '../../../domain/models/user_phrase.dart';
import '../data/media_repository.dart';
import '../domain/media_unlock_manager.dart';

/// Écran principal de la rubrique « Chansons & Dialogues ».
/// Affiche les 30 lots de l'application, leur état de déblocage,
/// les dialogues de Conrad & Katja, et les chansons mémorielles.
class MediaSectionScreen extends StatefulWidget {
  final MediaManifest? initialManifest;
  final MediaRepository? repository;
  final bool isEmbeddedInTab;

  const MediaSectionScreen({
    super.key,
    this.initialManifest,
    this.repository,
    this.isEmbeddedInTab = false,
  });

  @override
  State<MediaSectionScreen> createState() => _MediaSectionScreenState();
}

class _MediaSectionScreenState extends State<MediaSectionScreen> {
  final MediaRepository _repository = MediaRepository();
  final AppDatabase _db = AppDatabase.instance;

  bool _isLoading = true;
  MediaManifest? _manifest;
  Map<String, UserPhrase> _userProgress = {};
  List<Phrase> _allPhrases = [];
  SharedPreferences? _prefs;
  List<int> _autoListeningLotIds = [];
  Map<String, bool> _playedStatus = {};
  String _selectedFilter = 'all'; // 'all', 'unlocked', 'ready'

  static const int totalLotsCount = 30;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final repo = widget.repository ?? _repository;
      final manifest = widget.initialManifest ?? await repo.getApprovedManifest();
      final phrases = await _db.getAllPhrases();
      final progress = await _db.getAllProgression();
      final autoIds = await MediaUnlockManager.getAutoListeningLotIds(prefs: prefs);

      // Charger statuts d'écoute
      final playedMap = <String, bool>{};
      for (final item in manifest.contents) {
        final played = await MediaUnlockManager.isMediaPlayed(item.lotId, item.type, prefs: prefs);
        playedMap['${item.lotId}_${item.type.value}'] = played;
      }

      if (mounted) {
        setState(() {
          _prefs = prefs;
          _manifest = manifest;
          _allPhrases = phrases;
          _userProgress = progress;
          _autoListeningLotIds = autoIds;
          _playedStatus = playedMap;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement MediaSectionScreen: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  LotLockStatus _getLotStatus(int lotId) {
    return MediaUnlockManager.getLotStatus(
      lotId: lotId,
      progress: _userProgress,
      allPhrases: _allPhrases,
      prefs: _prefs,
    );
  }


  Future<void> _toggleAutoListening(int lotId) async {
    final nextState = await MediaUnlockManager.toggleDialogueInAutoListening(lotId, prefs: _prefs);
    setState(() {
      if (nextState) {
        _autoListeningLotIds.add(lotId);
      } else {
        _autoListeningLotIds.remove(lotId);
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nextState
                ? '🎧 Dialogue du Lot $lotId ajouté à l\'Écoute auto !'
                : 'Dialogue du Lot $lotId retiré de l\'Écoute auto.',
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openMediaPlayer(MediaItem item) async {
    await context.push('/media-player', extra: item);
    _loadAllData();
  }

  void _showPendingMediaDialog({
    required int lotId,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '✨ Lot $lotId Débloqué avec succès',
                style: const TextStyle(
                  color: Color(0xFF10B981),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Compris', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Column(
          children: [
            const Text(
              'Chansons & Dialogues',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            const SizedBox(height: 2),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                'أغاني ومحادثات ألمانية بالصوت الحقيقي',
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF065F46),
                ),
              ),
            ),
          ],
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF131B26) : Colors.white,
        automaticallyImplyLeading: !widget.isEmbeddedInTab,
        leading: widget.isEmbeddedInTab
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(isDark),
    );
  }

  Widget _buildBody(bool isDark) {
    final contents = _manifest?.contents ?? [];

    // Calculer les statistiques
    int unlockedLotsCount = 0;
    int readyContentsCount = 0;
    for (int i = 1; i <= totalLotsCount; i++) {
      final st = _getLotStatus(i);
      if (st.isUnlocked) unlockedLotsCount++;
      if (st.isDialogueActive) readyContentsCount++;
    }

    // Filtrage des lots
    final allLotIds = List.generate(totalLotsCount, (i) => i + 1);
    final displayedLotIds = allLotIds.where((lotId) {
      final st = _getLotStatus(lotId);
      if (_selectedFilter == 'unlocked') {
        return st.isUnlocked;
      } else if (_selectedFilter == 'ready') {
        return st.isDialogueActive;
      }
      return true;
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 40),
      children: [
        // 1. Carte Héro d'en-tête immersive
        _buildHeroIntroCard(isDark, unlockedLotsCount, readyContentsCount),

        const SizedBox(height: 16),

        // 2. Filtres rapides
        _buildFilterChips(isDark, unlockedLotsCount, readyContentsCount),

        const SizedBox(height: 18),

        // 3. Liste des 30 lots
        ...displayedLotIds.map((lotId) {
          final status = _getLotStatus(lotId);
          final lotContents = contents.where((c) => c.lotId == lotId).toList();
          final dialogue = lotContents.where((c) => c.type == MediaType.dialogue).firstOrNull;
          final chanson = lotContents.where((c) => c.type == MediaType.chanson).firstOrNull;

          if (!status.isUnlocked) {
            return _buildLockedLotCard(lotId, status, isDark);
          } else {
            return _buildUnlockedLotCard(
              lotId: lotId,
              status: status,
              dialogue: dialogue,
              chanson: chanson,
              isDark: isDark,
            );
          }
        }),
      ],
    );
  }

  /// Carte Héro d'en-tête avec métriques et résumé visuel
  Widget _buildHeroIntroCard(bool isDark, int unlockedLots, int readyAudio) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFFEEF2FF), const Color(0xFFE0E7FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF6366F1).withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: isDark ? 0.2 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.headphones_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Immersion Audio & Musique',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : const Color(0xFF312E81),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'ACTIF',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Écoute Conrad & Katja en situation réelle et mémorise les phrases grâce aux chansons de chaque lot.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? Colors.white70 : const Color(0xFF4338CA),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Statistiques rapides
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricItem(
                  label: 'Lots débloqués',
                  value: '$unlockedLots / $totalLotsCount',
                  icon: Icons.lock_open_rounded,
                  color: const Color(0xFF10B981),
                  isDark: isDark,
                ),
                Container(height: 24, width: 1, color: isDark ? Colors.white24 : Colors.black12),
                _buildMetricItem(
                  label: 'Audios prêts',
                  value: '$readyAudio en écoute',
                  icon: Icons.play_circle_fill_rounded,
                  color: const Color(0xFF6366F1),
                  isDark: isDark,
                ),
                Container(height: 24, width: 1, color: isDark ? Colors.white24 : Colors.black12),
                _buildMetricItem(
                  label: 'Chansons',
                  value: 'Refrains chantés',
                  icon: Icons.music_note_rounded,
                  color: const Color(0xFFEC4899),
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Filtres rapides
  Widget _buildFilterChips(bool isDark, int unlockedLots, int readyAudio) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(
            id: 'all',
            label: 'Tous les 30 lots',
            count: totalLotsCount,
            isSelected: _selectedFilter == 'all',
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            id: 'unlocked',
            label: 'Débloqués ✨',
            count: unlockedLots,
            isSelected: _selectedFilter == 'unlocked',
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            id: 'ready',
            label: 'Prêts à écouter 🎧',
            count: 1,
            isSelected: _selectedFilter == 'ready',
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String id,
    required String label,
    required int count,
    required bool isSelected,
    required bool isDark,
  }) {
    return InkWell(
      onTap: () => setState(() => _selectedFilter = id),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : (isDark ? Colors.white12 : const Color(0xFFF1F5F9)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Carte pour Lot Débloqué (avec vrais audios OU statut en attente)
  /// Carte pour Lot Débloqué (avec dialogue actif ou en attente d'apprentissage)
  Widget _buildUnlockedLotCard({
    required int lotId,
    required LotLockStatus status,
    required MediaItem? dialogue,
    required MediaItem? chanson,
    required bool isDark,
  }) {
    final startIdx = (lotId - 1) * 10;
    final endIdx = (startIdx + 10).clamp(0, _allPhrases.length);
    final lotPhrases = (startIdx < _allPhrases.length)
        ? _allPhrases.sublist(startIdx, endIdx)
        : <Phrase>[];
    final completedInLot = lotPhrases.where((p) {
      final prog = _userProgress[p.id];
      return prog != null && (prog.level > 0 || prog.reps > 0);
    }).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161F2E) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.28),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête du Lot
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'LOT $lotId',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Row(
                    children: [
                      Icon(
                        status.isCompleted ? Icons.check_circle_rounded : Icons.lock_open_rounded,
                        color: status.isCompleted ? const Color(0xFF10B981) : AppColors.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        status.isCompleted ? 'Complété ✨' : 'En cours 🚀',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: status.isCompleted ? const Color(0xFF10B981) : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                'Phrases ${(lotId - 1) * 10 + 1} à ${lotId * 10}',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white38 : Colors.black45,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 1. DIALOGUE (Actif uniquement si les 10 phrases sont complétées)
          if (dialogue != null && status.isDialogueActive)
            _buildMediaContentTile(
              item: dialogue,
              lotId: lotId,
              isDark: isDark,
              accentColor: const Color(0xFF0284C7),
              icon: Icons.forum_rounded,
              typeLabel: 'Dialogue Allemand Parlé',
              speakersLabel: 'Conrad 👨 & Katja 👩',
              isInAutoListening: _autoListeningLotIds.contains(lotId),
              onToggleAutoListening: () => _toggleAutoListening(lotId),
            )
          else if (dialogue != null && !status.isDialogueActive)
            _buildInactiveDialogueTile(
              lotId: lotId,
              isDark: isDark,
              completedCount: completedInLot,
              totalPhrases: lotPhrases.length,
              phraseIds: lotPhrases.map((p) => p.id).toList(),
            )
          else
            _buildPendingMediaTile(
              lotId: lotId,
              typeLabel: 'Dialogue Allemand Parlé',
              titleDe: 'Dialogue du Lot $lotId',
              titleAr: 'محادثة المجموعة $lotId قريباً',
              subtitle: 'En cours d\'enregistrement • Voix réelles Conrad & Katja',
              badgeLabel: '⏳ Bientôt disponible',
              icon: Icons.forum_rounded,
              accentColor: const Color(0xFF0284C7),
              isDark: isDark,
              onTap: () => _showPendingMediaDialog(
                lotId: lotId,
                title: 'Dialogue du Lot $lotId',
                description: 'Le dialogue en allemand parlé entre Conrad et Katja reprenant les 10 phrases de ce lot est en cours d\'enregistrement.',
                icon: Icons.forum_rounded,
                color: const Color(0xFF0284C7),
              ),
            ),

          const SizedBox(height: 12),

          // 2. CHANSON
          if (chanson != null)
            _buildMediaContentTile(
              item: chanson,
              lotId: lotId,
              isDark: isDark,
              accentColor: const Color(0xFFEC4899),
              icon: Icons.music_note_rounded,
              typeLabel: 'Chanson & Refrain',
              speakersLabel: 'Refrain mémoriel chanté',
            )
          else
            _buildPendingMediaTile(
              lotId: lotId,
              typeLabel: 'Chanson & Refrain',
              titleDe: 'Chanson du Lot $lotId',
              titleAr: 'أغنية الحفظ قريباً',
              subtitle: 'Refrain mémoriel • Prêt à recevoir votre audio MP3',
              badgeLabel: '🎵 Chanson à venir',
              icon: Icons.music_note_rounded,
              accentColor: const Color(0xFFEC4899),
              isDark: isDark,
              onTap: () => _showPendingMediaDialog(
                lotId: lotId,
                title: 'Chanson du Lot $lotId',
                description: 'Le Lot $lotId est bien débloqué ! L\'application est prête à recevoir le fichier audio MP3 pour ce lot afin de l\'intégrer avec transcription karaoké.',
                icon: Icons.music_note_rounded,
                color: const Color(0xFFEC4899),
              ),
            ),
        ],
      ),
    );
  }

  /// Tuile pour média déjà disponible et prêt à l'écoute
  Widget _buildMediaContentTile({
    required MediaItem item,
    required int lotId,
    required bool isDark,
    required Color accentColor,
    required IconData icon,
    required String typeLabel,
    required String speakersLabel,
    bool isInAutoListening = false,
    VoidCallback? onToggleAutoListening,
  }) {
    final playedKey = '${lotId}_${item.type.value}';
    final isPlayed = _playedStatus[playedKey] ?? false;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.3),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          typeLabel,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                            color: accentColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isPlayed
                                ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                : const Color(0xFFF59E0B).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isPlayed ? '✓ Écouté' : '✨ Nouveau',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: isPlayed ? const Color(0xFF10B981) : const Color(0xFFD97706),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.titleDe ?? (item.type == MediaType.dialogue ? 'Dialogue' : 'Chanson'),
                      style: AppTextStyles.bodyMedium(isDark: isDark).copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    if (item.titleAr != null && item.titleAr!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: Text(
                          item.titleAr!,
                          style: GoogleFonts.cairo(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF065F46),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Pied de tuile
          Row(
            children: [
              Expanded(
                child: Text(
                  '⏱ ${item.durationSeconds}s • $speakersLabel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Bouton Écoute auto
              if (onToggleAutoListening != null) ...[
                IconButton(
                  onPressed: onToggleAutoListening,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  tooltip: isInAutoListening ? 'Retirer de l\'Écoute auto' : 'Ajouter à l\'Écoute auto',
                  icon: Icon(
                    isInAutoListening ? Icons.headset_rounded : Icons.headset_off_rounded,
                    size: 19,
                    color: isInAutoListening ? const Color(0xFF8B5CF6) : Colors.grey,
                  ),
                ),
                const SizedBox(width: 6),
              ],

              // Bouton Écouter
              ElevatedButton.icon(
                onPressed: () => _openMediaPlayer(item),
                icon: const Icon(Icons.play_arrow_rounded, size: 17),
                label: const Text('Écouter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Tuile pour média en attente (Lot 2 ou lots suivants sans audio)
  Widget _buildPendingMediaTile({
    required int lotId,
    required String typeLabel,
    required String titleDe,
    required String titleAr,
    required String subtitle,
    required String badgeLabel,
    required IconData icon,
    required Color accentColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141C29) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accentColor.withValues(alpha: 0.7), size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          typeLabel,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: accentColor.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badgeLabel,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFD97706),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      titleDe,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        titleAr,
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? const Color(0xFF6EE7B7).withValues(alpha: 0.8)
                              : const Color(0xFF065F46).withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white38 : Colors.black45,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.info_outline_rounded, size: 16),
                label: const Text('Info'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: accentColor,
                  side: BorderSide(color: accentColor.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInactiveDialogueTile({
    required int lotId,
    required bool isDark,
    required int completedCount,
    required int totalPhrases,
    required List<String> phraseIds,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_clock_rounded, color: Color(0xFFD97706), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Dialogue Allemand Parlé',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFD97706),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            '🔒 En attente',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFD97706),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Dialogue du Lot $lotId',
                      style: AppTextStyles.bodyMedium(isDark: isDark).copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Conrad 👨 & Katja 👩 • Voix réelles natives',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Ce dialogue en immersion réelle s\'activera dès que tu auras achevé les 10 phrases de ce lot ($completedCount / $totalPhrases terminées).',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white60 : Colors.black54,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                context.push('/session', extra: phraseIds).then((_) => _loadAllData());
              },
              icon: const Icon(Icons.school_rounded, size: 18),
              label: Text('S\'entraîner sur le Lot $lotId ($completedCount/$totalPhrases)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLockedLotSheet(int lotId, LotLockStatus status, bool isDark) {
    final currentPalier = ((lotId - 1) ~/ 3) + 1;

    if (status.isPalierStart) {
      final requiredPalier = status.requiredPalierExam ?? (currentPalier - 1);
      final bool isReady = status.isExamReady;

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEA580C).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.school_rounded, size: 36, color: Color(0xFFEA580C)),
              ),
              const SizedBox(height: 14),
              Text(
                'Grand Examen du Palier $requiredPalier requis 🎓',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEA580C).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Score requis : 20/30 minimum',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFEA580C),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isReady
                    ? 'Tu as complété les lots du Palier $requiredPalier !\n\nPour ouvrir le Lot $lotId (Palier $currentPalier) et son dialogue, tu dois d\'abord passer et réussir le Grand Examen du Palier $requiredPalier (Phrases ${(requiredPalier - 1) * 30 + 1} à ${requiredPalier * 30}) avec au moins 20/30.'
                    : 'Le Lot $lotId fait partie du Palier $currentPalier.\n\nPour débloquer ce palier, tu devras d\'abord progresser jusqu\'au Palier $requiredPalier (Phrases ${(requiredPalier - 1) * 30 + 1} à ${requiredPalier * 30}) et réussir son Grand Examen avec au moins 20/30.\n\nTon lot actif actuel est le Lot ${status.highestUnlockedLot}.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : Colors.black54,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              if (isReady)
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    final palierStart = (requiredPalier - 1) * 30;
                    final palierEnd = (requiredPalier * 30).clamp(0, _allPhrases.length);
                    final palierPhrases = _allPhrases.sublist(palierStart, palierEnd);
                    context.push('/palier-exam?palier=$requiredPalier', extra: palierPhrases).then((_) => _loadAllData());
                  },
                  icon: const Icon(Icons.school_rounded),
                  label: Text('🎓 Passer le Grand Examen du Palier $requiredPalier (20/30)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEA580C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    final startIdx = (status.highestUnlockedLot - 1) * 10;
                    final endIdx = (startIdx + 10).clamp(0, _allPhrases.length);
                    final lotPhrases = (startIdx < _allPhrases.length)
                        ? _allPhrases.sublist(startIdx, endIdx).map((p) => p.id).toList()
                        : <String>[];
                    context.push('/session', extra: lotPhrases).then((_) => _loadAllData());
                  },
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text('🚀 S\'entraîner sur le Lot ${status.highestUnlockedLot} (En cours)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                ),
            ],
          ),
        ),
      );
      return;
    }

    final requiredLot = status.requiredPreviousLot ?? (lotId - 1);
    final isNextLot = requiredLot == status.highestUnlockedLot;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.black26 : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_rounded, size: 36, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 14),
            Text(
              'Lot $lotId Verrouillé 🔒',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              isNextLot
                  ? 'Pour accéder au Lot $lotId, tu dois d\'abord achever les 10 phrases du Lot $requiredLot dans ton apprentissage.'
                  : 'Le Lot $lotId fait partie du Palier $currentPalier. Il nécessite d\'avoir validé le Lot $requiredLot.\n\nTon lot actif actuel est le Lot ${status.highestUnlockedLot}.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : Colors.black54,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                final targetLot = isNextLot ? requiredLot : status.highestUnlockedLot;
                final startIdx = (targetLot - 1) * 10;
                final endIdx = (startIdx + 10).clamp(0, _allPhrases.length);
                final phrases = (startIdx < _allPhrases.length)
                    ? _allPhrases.sublist(startIdx, endIdx).map((p) => p.id).toList()
                    : <String>[];
                context.push('/session', extra: phrases).then((_) => _loadAllData());
              },
              icon: const Icon(Icons.school_rounded),
              label: Text(
                isNextLot
                    ? 'S\'entraîner sur le Lot $requiredLot'
                    : 'S\'entraîner sur le Lot ${status.highestUnlockedLot} (En cours)',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Carte épurée pour lot verrouillé
  Widget _buildLockedLotCard(int lotId, LotLockStatus status, bool isDark) {
    final bool isPalierBoundary = status.isPalierStart;
    final requiredExam = status.requiredPalierExam;
    final requiredLot = status.requiredPreviousLot;

    return InkWell(
      onTap: () => _showLockedLotSheet(lotId, status, isDark),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131923) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isPalierBoundary
                ? const Color(0xFFEA580C).withValues(alpha: 0.35)
                : (isDark ? const Color(0xFF232D3B) : const Color(0xFFE2E8F0)),
            width: isPalierBoundary ? 1.4 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isPalierBoundary
                    ? const Color(0xFFEA580C).withValues(alpha: 0.12)
                    : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04)),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPalierBoundary ? Icons.school_rounded : Icons.lock_rounded,
                color: isPalierBoundary
                    ? const Color(0xFFEA580C)
                    : (isDark ? Colors.white38 : Colors.black38),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'LOT $lotId',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: isPalierBoundary
                              ? (isDark ? Colors.white70 : const Color(0xFF9A3412))
                              : (isDark ? Colors.white54 : Colors.black54),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isPalierBoundary
                              ? const Color(0xFFEA580C).withValues(alpha: 0.15)
                              : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isPalierBoundary ? '🎓 Examen $requiredExam (20/30 requis)' : 'Verrouillé',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isPalierBoundary
                                ? const Color(0xFFEA580C)
                                : (isDark ? Colors.white38 : Colors.black38),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isPalierBoundary
                        ? 'Passe le Grand Examen du Palier $requiredExam (20/30 min.) pour débloquer le Lot $lotId.'
                        : 'Termine d\'abord le Lot $requiredLot pour débloquer le Lot $lotId.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isPalierBoundary
                          ? (isDark ? const Color(0xFFFDBA74) : const Color(0xFFC2410C))
                          : (isDark ? Colors.white38 : Colors.black38),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isPalierBoundary ? const Color(0xFFEA580C) : Colors.grey,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
