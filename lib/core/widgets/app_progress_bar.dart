import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Barre de progression pilule (hauteur 10px, fond vert très clair, remplissage vert forêt).
class AppProgressBar extends StatelessWidget {
  /// Valeur entre 0.0 et 1.0
  final double value;
  final double height;
  final Color? fillColor;
  final Color? trackColor;

  const AppProgressBar({
    super.key,
    required this.value,
    this.height = 10,
    this.fillColor,
    this.trackColor,
  });

  @override
  Widget build(BuildContext context) {
    final clampedValue = value.clamp(0.0, 1.0);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final defaultTrack = isDark
        ? const Color(0xFF1B3828)
        : AppColors.primaryLight;
    final defaultFill = AppColors.primary;

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: trackColor ?? defaultTrack,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                width: constraints.maxWidth * clampedValue,
                height: height,
                decoration: BoxDecoration(
                  color: fillColor ?? defaultFill,
                  borderRadius: BorderRadius.circular(height / 2),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
