import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Carte standardisée Deutsch Fast (coins 20px, ombre très douce, padding 20px).
class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;

  const CustomCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = backgroundColor ??
        (isDark ? AppColors.surfaceDark : AppColors.surfaceLight);
    final border = borderColor ??
        (isDark ? AppColors.borderDark : AppColors.borderLight);

    final cardContent = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 1),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: AppColors.textPrimaryLight.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}
