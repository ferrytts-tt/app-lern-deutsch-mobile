import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/tts_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/arabic_text_view.dart';
import '../../../../core/widgets/duo_button.dart';
import '../../../../core/widgets/mascot_widget.dart';
import '../../../../domain/models/phrase.dart';
import '../../../../domain/models/user_phrase.dart';
import '../../../../domain/models/user_profile.dart';
import '../../../media/domain/media_unlock_manager.dart';

/// Type de galet / marche sur le sentier Duolingo
enum PathNodeType {
  lesson,      // ⭐ Découverte du Lot de 10 phrases
  listening,   // 🎧 Atelier Écoute & Shadowing natif
  srsReview,   // 🏋️ Haltères : Répétitions & Renforcement SRS
  composer,    // 📖 Livre : Recomposition & Écriture
  treasureChest, // 🎁 Coffre Master XP (Valide et débloque le lot suivant)
}

/// Modèle d'un nœud du Sentier
class PathNodeItem {
  final String id;
  final int batchIndex;
  final int stepInBatch; // 0..4
  final PathNodeType type;
  final String title;
  final String subtitle;
  final List<Phrase> phrases;
  final bool isCompleted;
  final bool isCurrent;
  final bool isLocked;

  const PathNodeItem({
    required this.id,
    required this.batchIndex,
    required this.stepInBatch,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.phrases,
    required this.isCompleted,
    required this.isCurrent,
    required this.isLocked,
  });
}

/// Sentier d'apprentissage sinueux ("Snake Path") inspiré de Duolingo.
/// - Présente la progression sous forme de galets 3D le long d'un chemin ondulé en S.
/// - Verrouille strictement les phrases futures (invisibles tant que le lot en cours n'est pas validé).
/// - Intègre des étapes de répétitions obligatoires (Audio 🎧, Répétition SRS 🏋️, Défi Master XP 🎁).
/// - Inclut la bannière d'unité avec bouton [📖 GUIDE] et des mascottes animées au bord du chemin.
class DuoLearningPath extends StatefulWidget {
  final List<Phrase> allPhrases;
  final Map<String, UserPhrase> userProgress;
  final UserProfile profile;
  final int currentBatchIndex;
  final VoidCallback onRefresh;

  const DuoLearningPath({
    super.key,
    required this.allPhrases,
    required this.userProgress,
    required this.profile,
    required this.currentBatchIndex,
    required this.onRefresh,
  });

  @override
  State<DuoLearningPath> createState() => _DuoLearningPathState();
}

class _DuoLearningPathState extends State<DuoLearningPath>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseScale;
  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseScale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    SharedPreferences.getInstance().then((p) {
      if (mounted) setState(() => _prefs = p);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// Détermine le lot débloqué maximum en fonction des phrases déjà complétées
  /// et de la réussite du Grand Examen (20/30) à chaque palier franchi
  int _calculateUnlockedBatchIndex() {
    if (widget.allPhrases.isEmpty) return 0;
    final totalBatches = (widget.allPhrases.length / 10).ceil();
    final highest = MediaUnlockManager.getHighestUnlockedLot(
      progress: widget.userProgress,
      allPhrases: widget.allPhrases,
      prefs: _prefs,
    );
    return (highest - 1).clamp(0, totalBatches - 1);
  }

  /// Construit les nœuds du sentier pour chaque lot de 10 phrases
  List<PathNodeItem> _buildPathNodes() {
    final nodes = <PathNodeItem>[];
    if (widget.allPhrases.isEmpty) return nodes;

    final totalBatches = (widget.allPhrases.length / 10).ceil();
    final unlockedBatchIndex = _calculateUnlockedBatchIndex();

    for (int b = 0; b < totalBatches; b++) {
      final start = b * 10;
      final end = (start + 10).clamp(0, widget.allPhrases.length);
      final batchPhrases = widget.allPhrases.sublist(start, end);

      final isBatchUnlocked = b <= unlockedBatchIndex;
      final isPastBatch = b < unlockedBatchIndex;

      // Détermine l'étape interne du lot (0: Leçon, 1: Audio, 2: Répétition SRS, 3: Recomposition, 4: Coffre)
      final completedCount = batchPhrases.where((p) {
        final prog = widget.userProgress[p.id];
        return prog != null && (prog.level > 0 || prog.reps > 0);
      }).length;

      // Calcul des sous-étapes complétées dans ce lot
      final bool step0Done = isPastBatch || completedCount >= (batchPhrases.length * 0.4).ceil();
      final bool step1Done = isPastBatch || completedCount >= (batchPhrases.length * 0.7).ceil();
      final bool step2Done = isPastBatch || completedCount >= batchPhrases.length;
      final bool step3Done = isPastBatch || (step2Done && completedCount >= batchPhrases.length);
      final bool step4Done = isPastBatch; // Le coffre final n'est validé que si le lot est passé

      // 1. Galet Étoile (⭐ Découverte du Lot de 10)
      nodes.add(PathNodeItem(
        id: 'node_${b}_0',
        batchIndex: b,
        stepInBatch: 0,
        type: PathNodeType.lesson,
        title: 'Lot ${b + 1} : Découverte',
        subtitle: '10 phrases clés (${start + 1}-$end)',
        phrases: batchPhrases,
        isCompleted: step0Done,
        isCurrent: isBatchUnlocked && !step0Done,
        isLocked: !isBatchUnlocked,
      ));

      // 2. Galet Casque (🎧 Répétition Audio & Shadowing)
      nodes.add(PathNodeItem(
        id: 'node_${b}_1',
        batchIndex: b,
        stepInBatch: 1,
        type: PathNodeType.listening,
        title: 'Atelier Écoute & Prononciation',
        subtitle: 'Répétition audio native',
        phrases: batchPhrases,
        isCompleted: step1Done,
        isCurrent: isBatchUnlocked && step0Done && !step1Done,
        isLocked: !isBatchUnlocked || !step0Done,
      ));

      // 3. Galet Haltère (🏋️ Répétition & Renforcement SRS)
      nodes.add(PathNodeItem(
        id: 'node_${b}_2',
        batchIndex: b,
        stepInBatch: 2,
        type: PathNodeType.srsReview,
        title: 'Répétitions & Ancrage SRS',
        subtitle: 'Musculation mnésique',
        phrases: batchPhrases,
        isCompleted: step2Done,
        isCurrent: isBatchUnlocked && step1Done && !step2Done,
        isLocked: !isBatchUnlocked || !step1Done,
      ));

      // 4. Galet Livre (📖 Compréhension & Recomposition)
      nodes.add(PathNodeItem(
        id: 'node_${b}_3',
        batchIndex: b,
        stepInBatch: 3,
        type: PathNodeType.composer,
        title: 'Recomposition de phrases',
        subtitle: 'Briques de mots Duolingo',
        phrases: batchPhrases,
        isCompleted: step3Done,
        isCurrent: isBatchUnlocked && step2Done && !step3Done,
        isLocked: !isBatchUnlocked || !step2Done,
      ));

      // 5. Galet Coffre (🎁 Grand Défi Master XP)
      nodes.add(PathNodeItem(
        id: 'node_${b}_4',
        batchIndex: b,
        stepInBatch: 4,
        type: PathNodeType.treasureChest,
        title: 'Coffre au Trésor Master XP',
        subtitle: 'Validation finale du Lot ${b + 1}',
        phrases: batchPhrases,
        isCompleted: step4Done,
        isCurrent: isBatchUnlocked && step3Done && !step4Done,
        isLocked: !isBatchUnlocked || !step3Done,
      ));
    }

    return nodes;
  }

  void _handleNodeTap(PathNodeItem node) {
    if (node.isLocked) {
      _showLockedDialog(node);
      return;
    }

    final phraseIds = node.phrases.map((p) => p.id).toList();

    switch (node.type) {
      case PathNodeType.lesson:
      case PathNodeType.listening:
      case PathNodeType.srsReview:
      case PathNodeType.composer:
        context.push('/session', extra: phraseIds).then((_) => widget.onRefresh());
        break;
      case PathNodeType.treasureChest:
        context.push('/master-xp', extra: phraseIds.isNotEmpty ? phraseIds : null).then((_) => widget.onRefresh());
        break;
    }
  }

  void _showLockedDialog(PathNodeItem node) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lotId = node.batchIndex + 1;
    final currentPalier = (node.batchIndex ~/ 3) + 1;
    final status = MediaUnlockManager.getLotStatus(
      lotId: lotId,
      progress: widget.userProgress,
      allPhrases: widget.allPhrases,
      prefs: _prefs,
    );

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
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEA580C).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.school_rounded, size: 40, color: Color(0xFFEA580C)),
              ),
              const SizedBox(height: 14),
              Text(
                'Grand Examen du Palier $requiredPalier requis 🎓',
                style: AppTextStyles.titleMedium(isDark: isDark).copyWith(
                  fontWeight: FontWeight.w900,
                ),
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
              const SizedBox(height: 10),
              Text(
                isReady
                    ? 'Tu as complété les lots du Palier $requiredPalier !\nPour débloquer le Lot $lotId (Palier $currentPalier), tu dois obligatoirement réussir le Grand Examen du Palier $requiredPalier avec au moins 20/30.'
                    : 'Le Lot $lotId fait partie du Palier $currentPalier.\nPour débloquer ce palier, tu devras d\'abord progresser jusqu\'au Palier $requiredPalier (Phrases ${(requiredPalier - 1) * 30 + 1} à ${requiredPalier * 30}) et réussir son Grand Examen avec au moins 20/30.\n\nTon lot actif actuel est le Lot ${status.highestUnlockedLot}.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              if (isReady)
                DuoButton(
                  label: '🎓 Passer le Grand Examen (20/30 requis)',
                  variant: DuoButtonVariant.secondary,
                  icon: Icons.school_rounded,
                  onPressed: () {
                    Navigator.pop(ctx);
                    final palierStart = (requiredPalier - 1) * 30;
                    final palierEnd = (requiredPalier * 30).clamp(0, widget.allPhrases.length);
                    final palierPhrases = widget.allPhrases.sublist(palierStart, palierEnd);
                    context.push('/palier-exam?palier=$requiredPalier', extra: palierPhrases).then((_) => widget.onRefresh());
                  },
                )
              else
                DuoButton(
                  label: 'Continuer le Lot ${status.highestUnlockedLot}',
                  variant: DuoButtonVariant.primary,
                  icon: Icons.play_arrow_rounded,
                  onPressed: () => Navigator.pop(ctx),
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_rounded, size: 40, color: Color(0xFFAFAFAF)),
            ),
            const SizedBox(height: 14),
            Text(
              'Lot $lotId Verrouillé 🔒',
              style: AppTextStyles.titleMedium(isDark: isDark).copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isNextLot
                  ? 'Pour accéder au Lot $lotId, termine d\'abord les 10 phrases du Lot $requiredLot dans ton apprentissage.'
                  : 'Le Lot $lotId fait partie du Palier $currentPalier. Il nécessite d\'avoir validé le Lot $requiredLot.\n\nTon lot actif actuel est le Lot ${status.highestUnlockedLot}.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            DuoButton(
              label: 'Compris !',
              icon: Icons.check_rounded,
              variant: DuoButtonVariant.primary,
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  void _showGuideSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentBatchPhrases = widget.allPhrases.take(10).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('📖', style: TextStyle(fontSize: 26)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GUIDE DE L\'UNITÉ 1',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          'Salutations, formules de politesse & verbes',
                          style: AppTextStyles.titleSmall(isDark: isDark).copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              // Règle 1 : L'ordre des mots en allemand
              _buildGuideSection(
                icon: '💡',
                title: 'La règle d\'or du verbe en 2e position (V2)',
                content:
                    'En allemand standard, le verbe conjugué se place TOUJOURS en deuxième position dans une phrase déclarative principale.\n\nExemple : « Heute lerne ich Deutsch » (Aujourd\'hui j\'apprends l\'allemand) et non « Heute ich lerne ».',
                isDark: isDark,
              ),

              const SizedBox(height: 14),

              // Règle 2 : Formules parlées vs standard
              _buildGuideSection(
                icon: '🗣️',
                title: 'Allemand parlé vs Allemand standard',
                content:
                    'Les Allemands raccourcissent souvent les mots à l\'oral :\n• « Wie geht\'s? » au lieu de « Wie geht es dir? »\n• « \'n » au lieu de « ein » ou « einen »\n• « Was gibt\'s? » pour dire « Quoi de neuf ? »',
                isDark: isDark,
              ),

              const SizedBox(height: 14),

              // Liste des phrases débloquées de l'unité
              Text(
                'Phrases clés du lot actuel :',
                style: AppTextStyles.titleSmall(isDark: isDark).copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              ...currentBatchPhrases.map((phrase) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.volume_up_rounded, color: AppColors.primary),
                        visualDensity: VisualDensity.compact,
                        onPressed: () => TtsService.instance.speak(phrase.de),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              phrase.de,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              phrase.fr,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                            if (phrase.ar != null && phrase.ar!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              ArabicTextView(
                                text: phrase.ar!,
                                fontSize: 13,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 16),
              DuoButton(
                label: 'Fermer le guide',
                icon: Icons.check_rounded,
                variant: DuoButtonVariant.primary,
                onPressed: () => Navigator.pop(ctx),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuideSection({
    required String icon,
    required String title,
    required String content,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF10283A) : const Color(0xFFE0F2FE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF0288D1).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF0288D1),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nodes = _buildPathNodes();

    return Column(
      children: [
        // 1. Barre de statut Duolingo supérieure (🇩🇪 Unité, 🔥 Série, 💎 Gemmes, ❤️ Cœurs)
        _buildDuoStatusBar(isDark),

        const SizedBox(height: 14),

        // 2. Bannière de l'Unité en cours avec bouton [📖 GUIDE]
        _buildUnitHeaderBanner(isDark),

        const SizedBox(height: 20),

        // 3. Le Sentier sinueux en S avec galets 3D et mascottes
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: nodes.length,
          itemBuilder: (context, index) {
            final node = nodes[index];
            final nextNode = index + 1 < nodes.length ? nodes[index + 1] : null;

            // Décalage sinusoïdal en S (-70px à +70px)
            final double xOffset = sin(index * 0.85) * 68;

            return _buildPathRow(
              node: node,
              nextNode: nextNode,
              index: index,
              xOffset: xOffset,
              isDark: isDark,
            );
          },
        ),

        const SizedBox(height: 30),
      ],
    );
  }

  /// Barre de statut supérieure style Duolingo (Drapeau, Flamme de série, Gemmes, Cœurs)
  Widget _buildDuoStatusBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 🇩🇪 Niveau / Langue
          Row(
            children: [
              const Text('🇩🇪', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Text(
                'Allemand A1',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),

          // 🔥 Flamme Série de jours
          Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 4),
              Text(
                '${widget.profile.serieJours}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: Color(0xFFFF9600), // Orange flamme Duolingo
                ),
              ),
            ],
          ),

          // 💎 Gemmes / Cristaux
          Row(
            children: [
              const Text('💎', style: TextStyle(fontSize: 17)),
              const SizedBox(width: 4),
              Text(
                '${widget.userProgress.values.where((p) => p.level > 0 || p.reps > 0).length * 15 + 500}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: Color(0xFF1CB0F6), // Bleu cristal Duolingo
                ),
              ),
            ],
          ),

          // ❤️ Cœurs pleins
          Row(
            children: [
              const Text('❤️', style: TextStyle(fontSize: 17)),
              const SizedBox(width: 4),
              Text(
                '5',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: Color(0xFFFF4B4B), // Rouge cœur Duolingo
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Bannière colorée d'unité (exactement comme sur la capture Duolingo)
  Widget _buildUnitHeaderBanner(bool isDark) {
    final unlockedBatch = _calculateUnlockedBatchIndex();
    final unitNum = unlockedBatch + 1;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1CB0F6), // Bleu ciel emblématique Duolingo
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF1899D6),
            offset: Offset(0, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.arrow_back_rounded, size: 14, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(
                      'CHAPITRE 1, UNITÉ $unitNum',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Phrases courantes & Répétition orale',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1CB0F6),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.menu_book_rounded, size: 16),
            label: const Text(
              'GUIDE',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
            ),
            onPressed: _showGuideSheet,
          ),
        ],
      ),
    );
  }

  /// Ligne d'un nœud sur le sentier sinueux avec décalage horizontal
  Widget _buildPathRow({
    required PathNodeItem node,
    required PathNodeItem? nextNode,
    required int index,
    required double xOffset,
    required bool isDark,
  }) {
    // Alternance de mascottes au bord du sentier
    final showMascotLeft = (index == 1); // Mascotte ours à gauche de l'étape 1
    final showMascotRight = (index == 6); // Mascotte à droite de l'étape 6

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Trait de liaison pointillé vers le nœud suivant
          if (nextNode != null)
            CustomPaint(
              size: const Size(200, 60),
              painter: _PathLinkPainter(
                startX: xOffset,
                endX: sin((index + 1) * 0.85) * 68,
                isCompleted: node.isCompleted,
                isDark: isDark,
              ),
            ),

          // Mascotte Falstaff l'ours au bord du chemin
          if (showMascotRight)
            Positioned(
              right: 12,
              top: -10,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const MascotWidget(
                      mood: MascotMood.happy,
                      size: 54,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '🔥 Continue !',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (showMascotLeft)
            Positioned(
              left: 12,
              top: -5,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🐻', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 4),
                    Text(
                      'Falstaff veille !',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),

          // Le bouton galet 3D décalé horizontalement
          Transform.translate(
            offset: Offset(xOffset, 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Bulle flottante 3D [ COMMENCER ] au-dessus du nœud actif
                if (node.isCurrent)
                  AnimatedBuilder(
                    animation: _pulseScale,
                    builder: (context, child) => Transform.scale(
                      scale: _pulseScale.value,
                      child: child,
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF1CB0F6), width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0xFF1899D6),
                            offset: Offset(0, 3),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Text(
                        node.stepInBatch == 0 ? 'COMMENCER' : 'CONTINUER',
                        style: const TextStyle(
                          color: Color(0xFF1CB0F6),
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),

                // Galet 3D circulaire
                GestureDetector(
                  onTap: () => _handleNodeTap(node),
                  child: _buildSteppingStone(node, isDark),
                ),

                const SizedBox(height: 4),

                // Titre discret sous le galet
                Container(
                  constraints: const BoxConstraints(maxWidth: 110),
                  child: Text(
                    node.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: node.isCurrent ? FontWeight.bold : FontWeight.w600,
                      color: node.isLocked
                          ? (isDark ? Colors.white38 : Colors.black38)
                          : (isDark ? Colors.white70 : Colors.black87),
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

  /// Nœud circulaire 3D (Stepping Stone) avec relief et icône
  Widget _buildSteppingStone(PathNodeItem node, bool isDark) {
    final double size = node.type == PathNodeType.treasureChest ? 76 : 66;

    // Couleurs selon l'état et le type
    final Color baseColor;
    final Color shadowColor;
    final Widget iconWidget;

    if (node.isLocked) {
      baseColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
      shadowColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1);
      iconWidget = Icon(
        Icons.lock_rounded,
        size: 24,
        color: isDark ? Colors.white24 : Colors.black26,
      );
    } else if (node.isCompleted) {
      baseColor = const Color(0xFF58CC02); // Vert Duolingo validé
      shadowColor = const Color(0xFF46A302);
      iconWidget = const Icon(
        Icons.check_rounded,
        size: 32,
        color: Colors.white,
      );
    } else {
      // Nœud en cours actif
      switch (node.type) {
        case PathNodeType.lesson:
          baseColor = const Color(0xFF1CB0F6); // Bleu vif
          shadowColor = const Color(0xFF1899D6);
          iconWidget = const Icon(Icons.star_rounded, size: 34, color: Colors.white);
          break;
        case PathNodeType.listening:
          baseColor = const Color(0xFF9333EA); // Violet
          shadowColor = const Color(0xFF7E22CE);
          iconWidget = const Icon(Icons.headphones_rounded, size: 30, color: Colors.white);
          break;
        case PathNodeType.srsReview:
          baseColor = const Color(0xFFFF9600); // Orange musculation SRS
          shadowColor = const Color(0xFFE07E00);
          iconWidget = const Icon(Icons.fitness_center_rounded, size: 28, color: Colors.white);
          break;
        case PathNodeType.composer:
          baseColor = const Color(0xFF00CD9C); // Turquoise livre
          shadowColor = const Color(0xFF00A880);
          iconWidget = const Icon(Icons.menu_book_rounded, size: 28, color: Colors.white);
          break;
        case PathNodeType.treasureChest:
          baseColor = const Color(0xFFFFC800); // Or coffre Master XP
          shadowColor = const Color(0xFFE0A800);
          iconWidget = const Icon(Icons.inventory_2_rounded, size: 32, color: Colors.white);
          break;
      }
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: baseColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            offset: const Offset(0, 6),
            blurRadius: 0,
          ),
          if (node.isCurrent)
            BoxShadow(
              color: baseColor.withValues(alpha: 0.35),
              blurRadius: 16,
              spreadRadius: 2,
            ),
        ],
      ),
      alignment: Alignment.center,
      child: iconWidget,
    );
  }
}

/// Peintre pour relier deux galets consécutifs par une courbe douce
class _PathLinkPainter extends CustomPainter {
  final double startX;
  final double endX;
  final bool isCompleted;
  final bool isDark;

  _PathLinkPainter({
    required this.startX,
    required this.endX,
    required this.isCompleted,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isCompleted
          ? const Color(0xFF58CC02).withValues(alpha: 0.45)
          : (isDark ? Colors.white12 : Colors.black12)
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    final centerW = size.width / 2;
    path.moveTo(centerW + startX, 35);
    path.cubicTo(
      centerW + startX,
      size.height,
      centerW + endX,
      0,
      centerW + endX,
      size.height + 25,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PathLinkPainter oldDelegate) =>
      oldDelegate.startX != startX ||
      oldDelegate.endX != endX ||
      oldDelegate.isCompleted != isCompleted;
}
