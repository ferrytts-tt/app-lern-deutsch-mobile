import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/tts_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/arabic_text_view.dart';
import '../../../core/widgets/app_progress_bar.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/duo_button.dart';
import '../../../core/widgets/german_text_annotator.dart';
import '../../../core/widgets/mascot_widget.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../domain/models/discreet_badge.dart';
import '../../../domain/models/phrase.dart';
import 'progress_controller.dart';
import 'widgets/weekly_summary_sheet.dart';

/// Écran complet Mes Progrès avec statistiques globales, graphique 7 jours et phrases à surveiller.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(progressControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (state.isLoading) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('Mes Progrès', style: AppTextStyles.titleMedium(isDark: isDark)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Carte Flamme & Régularité
            _buildStreakCard(state, isDark),

            const SizedBox(height: 16),

            // 2. Grille des 4 métriques clés
            _buildMetricsGrid(state, isDark),

            const SizedBox(height: 16),

            // 3. Carte Progression Globale des 1000 phrases
            _buildGlobalProgressCard(state, isDark),

            const SizedBox(height: 16),

            // 4. Activité des 7 derniers jours & Bilan hebdomadaire (Section 7.3)
            _buildWeeklyActivityCard(context, state, isDark),

            const SizedBox(height: 16),

            // 5. Répartition par niveau SRS
            _buildSrsLevelDistributionCard(state, isDark),

            const SizedBox(height: 16),

            // 6. Paliers & Badges discrets (Section 7.4)
            _buildDiscreetBadgesSection(context, state.badges, isDark),

            const SizedBox(height: 16),

            // 7. Section « Phrases résistantes & Fréquence d'échecs »
            _buildWatchlistSection(context, state.watchlistPhrases, state.mostFailedPhrases, isDark),

            const SizedBox(height: 16),

            // 8. Progression par Thème (13 thèmes)
            _buildTopicsBreakdown(context, state.topicProgress, isDark),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCard(ProgressState state, bool isDark) {
    return CustomCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: AppColors.accentLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: AppColors.accentDark,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${state.streakDays} jours d’affilée 🔥',
                      style: AppTextStyles.titleSmall(isDark: isDark).copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Chaque séance consolide ta mémoire à long terme.',
                      style: AppTextStyles.caption(isDark: isDark),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF10283A) : const Color(0xFFE1F5FE),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF0288D1).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Text('❄️', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.freezeAvailable
                        ? 'Gel de série actif cette semaine (protège 1 jour manqué)'
                        : 'Gel de série utilisé cette semaine (se recharge chaque dimanche)',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0277BD),
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

  Widget _buildMetricsGrid(ProgressState state, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            label: 'Commencées',
            value: '${state.startedCount}',
            icon: Icons.auto_stories_rounded,
            iconColor: AppColors.secondary,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            label: 'Maîtrisées',
            value: '${state.masteredCount}',
            icon: Icons.star_rounded,
            iconColor: AppColors.primary,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            label: 'Pratique',
            value: '${state.totalPracticeMinutes} min',
            icon: Icons.timer_rounded,
            iconColor: AppColors.accentDark,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildGlobalProgressCard(ProgressState state, bool isDark) {
    final percent = (state.globalProgressRatio * 100).toInt();

    return CustomCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Objectif 1000 phrases',
                style: AppTextStyles.bodyLarge(isDark: isDark).copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$percent %',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppProgressBar(
            value: state.globalProgressRatio,
            height: 12,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${state.startedCount} / ${state.totalPhrasesCount} phrases en cours',
                style: AppTextStyles.caption(isDark: isDark),
              ),
              Text(
                '${state.masteredCount} maîtrisées ⭐',
                style: AppTextStyles.caption(isDark: isDark).copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyActivityCard(BuildContext context, ProgressState state, bool isDark) {
    final dayLabels = ['J-6', 'J-5', 'J-4', 'J-3', 'J-2', 'Hier', 'Auj.'];

    return CustomCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Activité des 7 derniers jours',
                style: AppTextStyles.bodyLarge(isDark: isDark).copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.textSecondaryLight),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (index) {
              final isActive = state.last7DaysActive[index];
              final isToday = index == 6;

              return Column(
                children: [
                  Container(
                    width: 34,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.primary
                          : (isDark ? AppColors.surfaceDark : AppColors.backgroundLight),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isToday
                            ? AppColors.accentDark
                            : (isActive ? AppColors.primary : (isDark ? AppColors.borderDark : AppColors.borderLight)),
                        width: isToday ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        isActive ? Icons.check_rounded : Icons.remove_rounded,
                        color: isActive
                            ? Colors.white
                            : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    dayLabels[index],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      color: isToday
                          ? (isDark ? Colors.white : AppColors.textPrimaryLight)
                          : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                    ),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 16),
          DuoButton(
            label: 'Voir mon bilan hebdomadaire 📊',
            icon: Icons.insights_rounded,
            variant: DuoButtonVariant.outline,
            onPressed: () => WeeklySummarySheet.show(context, state),
          ),
        ],
      ),
    );
  }

  Widget _buildSrsLevelDistributionCard(ProgressState state, bool isDark) {
    return CustomCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Répartition de votre apprentissage',
            style: AppTextStyles.bodyLarge(isDark: isDark).copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _SrsDistRow(
            label: 'Nouvelles (à découvrir)',
            count: state.newUnstartedCount,
            color: AppColors.secondary,
            icon: Icons.fiber_new_rounded,
          ),
          const SizedBox(height: 10),
          _SrsDistRow(
            label: 'En apprentissage (Niveaux 1-5)',
            count: state.inProgressCount,
            color: AppColors.accentDark,
            icon: Icons.sync_rounded,
          ),
          const SizedBox(height: 10),
          _SrsDistRow(
            label: 'Maîtrisées (Niveau 6+)',
            count: state.masteredCount,
            color: AppColors.primary,
            icon: Icons.star_rounded,
          ),
          const SizedBox(height: 10),
          _SrsDistRow(
            label: 'À surveiller (consolidation douce)',
            count: state.watchlistPhrases.length,
            color: AppColors.gentleError,
            icon: Icons.remove_red_eye_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildDiscreetBadgesSection(BuildContext context, List<DiscreetBadge> badges, bool isDark) {
    final unlockedCount = badges.where((b) => b.isUnlocked).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.military_tech_rounded, color: AppColors.accentDark, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Paliers & Récompenses discrètes',
                  style: AppTextStyles.bodyLarge(isDark: isDark).copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Text(
              '$unlockedCount / ${badges.length}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: badges.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.5,
          ),
          itemBuilder: (context, index) {
            final badge = badges[index];
            return CustomCard(
              padding: const EdgeInsets.all(12),
              onTap: () => _showBadgeDialog(context, badge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: badge.isUnlocked
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          badge.icon,
                          size: 18,
                          color: badge.isUnlocked ? AppColors.primary : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          badge.title,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: badge.isUnlocked
                                ? (isDark ? Colors.white : AppColors.textPrimaryLight)
                                : Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (badge.isUnlocked)
                        const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.primary),
                    ],
                  ),
                  Text(
                    badge.description,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            badge.isUnlocked ? 'Acquis ⭐' : '${badge.current} / ${badge.target}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: badge.isUnlocked ? AppColors.primary : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      AppProgressBar(
                        value: badge.progressRatio,
                        height: 4,
                        fillColor: badge.isUnlocked ? AppColors.primary : AppColors.secondary,
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  void _showBadgeDialog(BuildContext context, DiscreetBadge badge) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MascotWidget(
              mood: badge.isUnlocked ? MascotMood.happy : MascotMood.thinking,
              size: 80,
            ),
            const SizedBox(height: 12),
            Text(
              badge.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 6),
            Text(
              badge.description,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            Text(
              badge.isUnlocked
                  ? 'Palier atteint ! Bravo pour ta constance 🐿️'
                  : 'Progression : ${badge.current} / ${badge.target}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: badge.isUnlocked ? AppColors.primary : AppColors.secondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildWatchlistSection(
    BuildContext context,
    List<Phrase> watchlist,
    List<PhraseFailureStat> mostFailed,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.gentleError, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Phrases résistantes & Fréquence d’échecs',
                  style: AppTextStyles.bodyLarge(isDark: isDark).copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (mostFailed.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.gentleError.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${mostFailed.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gentleError,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (watchlist.isEmpty && mostFailed.isEmpty)
          CustomCard(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                const MascotWidget(mood: MascotMood.happy, size: 48),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Zéro phrase fragile !',
                        style: AppTextStyles.bodyLarge(isDark: isDark).copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Toutes tes phrases sont bien ancrées en mémoire à long terme.',
                        style: AppTextStyles.caption(isDark: isDark),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else ...[
          // Conseil de l'écureuil coach
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF261D15) : const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFFB300).withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                const MascotWidget(mood: MascotMood.thinking, size: 42),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Ces phrases résistent ? Le moteur SRS les propose deux fois plus souvent jusqu’à ce qu’elles deviennent naturelles.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFFFFE082) : const Color(0xFF795548),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: mostFailed.isNotEmpty ? mostFailed.take(5).length : watchlist.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              if (mostFailed.isNotEmpty) {
                final stat = mostFailed[index];
                final phrase = stat.phrase;
                return CustomCard(
                  padding: const EdgeInsets.all(14),
                  onTap: () {
                    context.push('/library/phrase/${phrase.id}');
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.gentleError.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '❌ ${stat.lapses} échec${stat.lapses > 1 ? 's' : ''}',
                                  style: const TextStyle(
                                    color: AppColors.gentleError,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.accentDark.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Niveau ${stat.level}/7',
                                  style: const TextStyle(
                                    color: AppColors.accentDark,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              if (stat.isDifficult) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Difficile',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.volume_up_rounded, color: AppColors.primary, size: 22),
                            tooltip: 'Écouter la prononciation',
                            onPressed: () => TtsService.instance.speak(phrase.deParle),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      GermanTextView(
                        text: phrase.deParle,
                        textAlign: TextAlign.start,
                        baseStyle: AppTextStyles.germanPhraseSmall(isDark: isDark),
                      ),
                      if (phrase.deStandard.isNotEmpty && phrase.deStandard != phrase.deParle) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Standard : ${phrase.deStandard}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      if (phrase.ar != null && phrase.ar!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        ArabicTextView(
                          text: phrase.ar!,
                          fontSize: 13,
                        ),
                      ],
                    ],
                  ),
                );
              } else {
                final phrase = watchlist[index];
                return CustomCard(
                  padding: const EdgeInsets.all(16),
                  onTap: () {
                    context.push('/library/phrase/${phrase.id}');
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const StatusBadge(status: PhraseStatus.aSurveiller),
                          IconButton(
                            icon: const Icon(Icons.volume_up_rounded, color: AppColors.primary, size: 20),
                            onPressed: () => TtsService.instance.speak(phrase.deParle),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      GermanTextView(
                        text: phrase.de,
                        textAlign: TextAlign.start,
                        baseStyle: AppTextStyles.germanPhraseSmall(isDark: isDark),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        phrase.fr,
                        style: AppTextStyles.translation(isDark: isDark).copyWith(fontSize: 14),
                      ),
                      if (phrase.ar != null && phrase.ar!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        ArabicTextView(
                          text: phrase.ar!,
                          fontSize: 13,
                        ),
                      ],
                    ],
                  ),
                );
              }
            },
          ),
        ],
      ],
    );
  }

  Widget _buildTopicsBreakdown(
    BuildContext context,
    List<TopicProgressItem> topics,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Maîtrise par Thème',
              style: AppTextStyles.bodyLarge(isDark: isDark).copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Phrases acquises (Niveau 7)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...topics.map((t) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: CustomCard(
              padding: const EdgeInsets.all(14),
              onTap: () {
                context.push('/library/topic/${t.topic.id}');
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(t.topic.icon, color: t.topic.themeColor, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          t.topic.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${t.acquiredCount} acquise${t.acquiredCount > 1 ? 's' : ''} ⭐',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${t.startedCount} / ${t.totalCount} vues',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AppProgressBar(
                    value: t.progressRatio,
                    height: 6,
                    fillColor: t.topic.themeColor,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final bool isDark;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SrsDistRow extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _SrsDistRow({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
