import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../../core/widgets/duo_button.dart';
import '../../../../core/widgets/mascot_widget.dart';
import '../progress_controller.dart';

/// Modal / Feuille du Bilan Hebdomadaire (Section 7.3 du plan de workflow).
/// Résume : phrases révisées, phrases passées au niveau supérieur, et temps total passé.
class WeeklySummarySheet extends StatelessWidget {
  final ProgressState state;

  const WeeklySummarySheet({
    super.key,
    required this.state,
  });

  static Future<void> show(BuildContext context, ProgressState state) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => WeeklySummarySheet(state: state),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeDaysCount = state.last7DaysActive.where((a) => a).length;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
          children: [
            // Poignée de glissement
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Mascotte écureuil fière avec ses résultats
            const MascotWidget(
              mood: MascotMood.proud,
              size: 88,
            ),

            const SizedBox(height: 14),

            Text(
              'Bilan Hebdomadaire 📊',
              style: AppTextStyles.titleMedium(isDark: isDark).copyWith(
                fontWeight: FontWeight.w900,
                fontSize: 22,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 6),

            Text(
              'Voici tes résultats sur les 7 derniers jours.',
              style: AppTextStyles.caption(isDark: isDark),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            // Grille des 3 métriques clés du plan (Section 7.3)
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    icon: Icons.sync_rounded,
                    iconColor: AppColors.primary,
                    value: '${state.weeklyReviewedCount}',
                    label: 'Phrases révisées',
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricCard(
                    icon: Icons.trending_up_rounded,
                    iconColor: AppColors.secondary,
                    value: '${state.weeklyPromotedCount}',
                    label: 'Niveau supérieur',
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricCard(
                    icon: Icons.timer_outlined,
                    iconColor: AppColors.accentDark,
                    value: '${state.weeklyPracticeMinutes}m',
                    label: 'Temps passé',
                    isDark: isDark,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Régularité des 7 jours
            CustomCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Régularité de la semaine',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                      Text(
                        '$activeDaysCount / 7 jours',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(7, (i) {
                      final isActive = state.last7DaysActive[i];
                      return Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.primary
                              : (isDark ? const Color(0xFF1E2822) : const Color(0xFFF1F5F2)),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isActive ? AppColors.primary : (isDark ? AppColors.borderDark : AppColors.borderLight),
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            isActive ? Icons.check_rounded : Icons.remove_rounded,
                            color: isActive ? Colors.white : AppColors.textSecondaryLight,
                            size: 16,
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Statut du gel de série
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF10283A) : const Color(0xFFE1F5FE),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF0288D1).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Text('❄️', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      state.freezeAvailable
                          ? '1 gel de série disponible cette semaine pour protéger ta flamme.'
                          : 'Gel de série utilisé. Un nouveau gel sera accordé dimanche !',
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

            const SizedBox(height: 20),

            DuoButton(
              label: 'Continuer',
              icon: Icons.thumb_up_rounded,
              variant: DuoButtonVariant.primary,
              onPressed: () => Navigator.of(context).pop(),
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final bool isDark;

  const _MetricCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2420) : const Color(0xFFF7FAF8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
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
