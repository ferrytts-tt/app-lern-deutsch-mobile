import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../../core/widgets/duo_button.dart';
import '../../../../core/widgets/duo_confetti.dart';
import '../../../../core/widgets/mascot_widget.dart';

/// Carte de bilan de fin de séance avec ajustement adaptatif du rythme et célébration Duolingo.
class SessionSummaryCard extends StatelessWidget {
  final int reviewedCount;
  final int newCount;
  final int elapsedMinutes;
  final int successRate;
  final int streakDays;
  final bool streakFreezeUsed;
  final bool streakReset;
  final DateTime? nextReviewDate;
  final String? selectedFeedback;
  final Function(String) onSelectFeedback;
  final VoidCallback? onAddTenMore;
  final VoidCallback? onAddFiveMore;
  final VoidCallback? onStartMasterXp;
  final VoidCallback onFinish;

  const SessionSummaryCard({
    super.key,
    required this.reviewedCount,
    required this.newCount,
    required this.elapsedMinutes,
    this.successRate = 100,
    this.streakDays = 1,
    this.streakFreezeUsed = false,
    this.streakReset = false,
    this.nextReviewDate,
    required this.selectedFeedback,
    required this.onSelectFeedback,
    this.onAddTenMore,
    this.onAddFiveMore,
    this.onStartMasterXp,
    required this.onFinish,
  });

  String _formatNextReview(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now);
    if (diff.isNegative) {
      return 'Disponible maintenant';
    } else if (diff.inMinutes < 60) {
      return 'Dans ${diff.inMinutes.clamp(1, 60)} min';
    } else if (diff.inHours < 24) {
      return 'Dans ${diff.inHours} h';
    } else if (diff.inDays == 1) {
      return 'Demain';
    } else {
      return 'Dans ${diff.inDays} jours';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DuoConfettiOverlay(
      isPlaying: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          children: [
            // Mascotte en fête style Duolingo
            const MascotWidget(
              mood: MascotMood.celebrating,
              size: 96,
            ),

            const SizedBox(height: 16),

            Text(
              'Séance terminée ! 🎉',
              style: AppTextStyles.titleMedium(isDark: isDark).copyWith(
                fontWeight: FontWeight.w900,
                fontSize: 24,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            Text(
              'Beau travail. Ta régularité est la clé de la réussite.',
              style: AppTextStyles.bodyMedium(isDark: isDark).copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Résumé des 4 métriques Section 3.5 (Révisées, Nouvelles, Réussite %, Série)
            CustomCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _SummaryStatItem(
                    icon: Icons.sync_rounded,
                    iconColor: AppColors.primary,
                    value: '$reviewedCount',
                    label: 'Révisées',
                  ),
                  Container(height: 36, width: 1, color: isDark ? AppColors.borderDark : AppColors.borderLight),
                  _SummaryStatItem(
                    icon: Icons.add_circle_outline_rounded,
                    iconColor: AppColors.secondary,
                    value: '$newCount',
                    label: 'Nouvelles',
                  ),
                  Container(height: 36, width: 1, color: isDark ? AppColors.borderDark : AppColors.borderLight),
                  _SummaryStatItem(
                    icon: Icons.check_circle_outline_rounded,
                    iconColor: AppColors.primary,
                    value: '$successRate %',
                    label: 'Réussite',
                  ),
                  Container(height: 36, width: 1, color: isDark ? AppColors.borderDark : AppColors.borderLight),
                  _SummaryStatItem(
                    icon: Icons.local_fire_department_rounded,
                    iconColor: AppColors.accentDark,
                    value: '$streakDays j',
                    label: 'Série',
                  ),
                ],
              ),
            ),

            if (streakFreezeUsed) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF10283A) : const Color(0xFFE1F5FE),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF0288D1).withValues(alpha: 0.4)),
                ),
                child: const Row(
                  children: [
                    Text('❄️', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Gel de série utilisé ! Ta flamme a été protégée hier. Tu restes sur ta lancée !',
                        style: TextStyle(
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

            if (streakReset) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2B1D0E) : const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFF9600).withValues(alpha: 0.4)),
                ),
                child: const Row(
                  children: [
                    Text('🐿️', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Chaque jour est un nouveau départ ! Ta nouvelle série commence aujourd\'hui.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFE65100),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Indication de la prochaine révision (Section 3.5)
            if (nextReviewDate != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1B2F22) : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.schedule_rounded, size: 20, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Prochaine révision : ${_formatNextReview(nextReviewDate!)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Question : Comment c'était ?
            Text(
              'Comment c’était ?',
              style: AppTextStyles.bodyLarge(isDark: isDark).copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'Ta réponse adapte automatiquement le quota de demain.',
              style: AppTextStyles.caption(isDark: isDark),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // 3 boutons de feedback adaptatif
            Row(
              children: [
                Expanded(
                  child: _FeedbackOption(
                    label: 'Trop dur',
                    subtitle: '-2 demain',
                    isSelected: selectedFeedback == 'too_hard',
                    onTap: () => onSelectFeedback('too_hard'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _FeedbackOption(
                    label: 'Parfait',
                    subtitle: 'Même rythme',
                    isSelected: selectedFeedback == 'perfect',
                    onTap: () => onSelectFeedback('perfect'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _FeedbackOption(
                    label: 'Trop facile',
                    subtitle: '+2 demain',
                    isSelected: selectedFeedback == 'too_easy',
                    onTap: () => onSelectFeedback('too_easy'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Option : « Passer aux 10 phrases suivantes »
            if (onAddTenMore != null) ...[
              DuoButton(
                label: 'Passer aux 10 phrases suivantes ➔',
                icon: Icons.fast_forward_rounded,
                variant: DuoButtonVariant.primary,
                onPressed: onAddTenMore,
              ),
              const SizedBox(height: 12),
            ],

            // Défi Master XP pour valider les phrases apprises
            if (onStartMasterXp != null) ...[
              DuoButton(
                label: '👑 DÉFI MASTER XP (SUR CES PHRASES)',
                icon: Icons.workspace_premium_rounded,
                variant: DuoButtonVariant.secondary,
                onPressed: onStartMasterXp,
              ),
              const SizedBox(height: 12),
            ],

            // Option non imposée : « 5 phrases de plus »
            if (onAddFiveMore != null) ...[
              DuoButton(
                label: '+ 5 phrases légères',
                icon: Icons.add_circle_outline_rounded,
                variant: DuoButtonVariant.outline,
                onPressed: onAddFiveMore,
              ),
              const SizedBox(height: 12),
            ],

            // Bouton Retour à l'accueil
            DuoButton(
              label: "Terminer et aller à l'accueil",
              icon: Icons.home_rounded,
              variant: onAddTenMore != null ? DuoButtonVariant.outline : DuoButtonVariant.primary,
              onPressed: onFinish,
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _SummaryStatItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _SummaryStatItem({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 12),
        ),
      ],
    );
  }
}

class _FeedbackOption extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _FeedbackOption({
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: isSelected
                    ? Colors.white70
                    : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
