import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_progress_bar.dart';

/// En-tête de séance avec bouton fermer bienveillant et barre de progression.
class SessionProgressHeader extends StatelessWidget {
  final double progress;
  final int current;
  final int total;

  const SessionProgressHeader({
    super.key,
    required this.progress,
    required this.current,
    required this.total,
  });

  void _confirmClose(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Faire une pause ?'),
        content: const Text(
          'Ta progression sur les phrases vues est déjà sauvegardée. Tu peux reprendre quand tu veux !',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Continuer'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.pop();
            },
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close_rounded),
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            onPressed: () => _confirmClose(context),
            tooltip: 'Fermer la séance',
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AppProgressBar(
              value: progress,
              height: 10,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$current/$total',
            style: AppTextStyles.caption(isDark: isDark).copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
