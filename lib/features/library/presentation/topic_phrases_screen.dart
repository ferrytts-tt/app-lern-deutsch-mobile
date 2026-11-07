import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/arabic_text_view.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/german_text_annotator.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../domain/models/topic.dart';
import '../../../domain/models/user_phrase.dart';
import 'library_controller.dart';

/// Écran listant les phrases d'un thème spécifique.
class TopicPhrasesScreen extends ConsumerWidget {
  final String topicId;

  const TopicPhrasesScreen({
    super.key,
    required this.topicId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(libraryControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topic = TopicInfo.getById(topicId);

    final topicPhrases = state.allPhrases.where((p) => p.topic == topicId).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(topic.title, style: AppTextStyles.titleMedium(isDark: isDark)),
      ),
      body: topicPhrases.isEmpty
          ? Center(
              child: Text(
                'Aucune phrase pour ce thème pour le moment.',
                style: AppTextStyles.bodyMedium(isDark: isDark),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              itemCount: topicPhrases.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final phrase = topicPhrases[index];
                final progress = state.userProgress[phrase.id];
                final badgeStatus = _mapToBadgeStatus(progress?.status);

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
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: topic.themeColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  phrase.cefr,
                                  style: TextStyle(
                                    color: topic.themeColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                                  ),
                                ),
                                child: Text(
                                  'Niv. ${progress?.level ?? 0}/7',
                                  style: TextStyle(
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          StatusBadge(status: badgeStatus),
                        ],
                      ),
                      const SizedBox(height: 10),
                      GermanTextView(
                        text: phrase.deParle,
                        textAlign: TextAlign.start,
                        baseStyle: AppTextStyles.germanPhraseSmall(isDark: isDark).copyWith(fontSize: 18),
                      ),
                      if (phrase.deStandard.isNotEmpty && phrase.deStandard != phrase.deParle) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Text('🇩🇪 Standard : ', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                            Expanded(
                              child: Text(
                                phrase.deStandard,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 4),
                      if (phrase.ar != null && phrase.ar!.trim().isNotEmpty) ...[
                        ArabicTextView(
                          text: phrase.ar!,
                          fontSize: 14,
                        ),
                        const SizedBox(height: 6),
                      ],
                      Text(
                        phrase.fr,
                        style: AppTextStyles.translation(isDark: isDark).copyWith(fontSize: 13),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  PhraseStatus _mapToBadgeStatus(UserPhraseStatus? status) {
    switch (status) {
      case UserPhraseStatus.enCours:
      case UserPhraseStatus.fragile:
      case UserPhraseStatus.assezSolide:
      case UserPhraseStatus.solide:
      case UserPhraseStatus.tresSolide:
        return PhraseStatus.enCours;
      case UserPhraseStatus.maitrisee:
        return PhraseStatus.maitrisee;
      case UserPhraseStatus.aSurveiller:
        return PhraseStatus.aSurveiller;
      case UserPhraseStatus.nouvelle:
      default:
        return PhraseStatus.nouvelle;
    }
  }
}
