import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';

/// Widget de série (streak) style flamme Duolingo avec pulsation continue.
class DuoStreakWidget extends StatelessWidget {
  static bool enableAnimations = true;

  final int streakDays;
  final bool isCompact;
  final bool animate;
  final bool hasFreeze;

  const DuoStreakWidget({
    super.key,
    required this.streakDays,
    this.isCompact = false,
    this.animate = true,
    this.hasFreeze = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget flameIcon = const Icon(
      Icons.local_fire_department_rounded,
      color: Color(0xFFFF9600),
      size: 26,
    );

    if (animate && enableAnimations) {
      flameIcon = flameIcon
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(1.0, 1.0),
            end: const Offset(1.18, 1.18),
            duration: 900.ms,
            curve: Curves.easeInOut,
          );
    }

    if (isCompact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2B1D0E) : const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFFF9600).withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            flameIcon,
            const SizedBox(width: 4),
            Text(
              '$streakDays',
              style: const TextStyle(
                color: Color(0xFFFF8B00),
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
            if (hasFreeze) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF10283A) : const Color(0xFFE1F5FE),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF0288D1).withValues(alpha: 0.4),
                  ),
                ),
                child: const Icon(Icons.ac_unit_rounded, size: 12, color: Color(0xFF0288D1)),
              ),
            ],
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF26190D) : const Color(0xFFFFF8EC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFF9600).withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9600).withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          flameIcon,
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$streakDays JOURS D\'AFFILÉE !',
                style: const TextStyle(
                  color: Color(0xFFFF7A00),
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                hasFreeze
                    ? '❄️ 1 gel de série actif cette semaine'
                    : 'Continue chaque jour pour garder la flamme',
                style: TextStyle(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
