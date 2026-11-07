import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum PhraseStatus {
  nouvelle,
  enCours,
  maitrisee,
  aSurveiller,
}

/// Badge pilule indiquant le statut d'une phrase (Nouvelle / En cours / Maîtrisée / À surveiller).
class StatusBadge extends StatelessWidget {
  final PhraseStatus status;

  const StatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color textColor;
    String label;

    switch (status) {
      case PhraseStatus.nouvelle:
        bg = AppColors.secondaryLight;
        textColor = AppColors.secondary;
        label = 'Nouvelle';
        break;
      case PhraseStatus.enCours:
        bg = AppColors.accentLight;
        textColor = AppColors.accentDark;
        label = 'En cours';
        break;
      case PhraseStatus.maitrisee:
        bg = AppColors.primaryLight;
        textColor = AppColors.primary;
        label = 'Maîtrisée';
        break;
      case PhraseStatus.aSurveiller:
        bg = AppColors.gentleErrorBackground;
        textColor = AppColors.gentleError;
        label = 'À surveiller';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
