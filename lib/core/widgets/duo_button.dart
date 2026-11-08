import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

enum DuoButtonVariant {
  primary,
  secondary,
  accent,
  outline,
}

/// Bouton tactile 3D style Duolingo avec effet d'enfoncement physique.
class DuoButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final DuoButtonVariant variant;
  final Color? customColor;
  final Color? customShadowColor;
  final double height;
  final double depth;
  final double borderRadius;
  final bool isFullWidth;

  const DuoButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.variant = DuoButtonVariant.primary,
    this.customColor,
    this.customShadowColor,
    this.height = 54,
    this.depth = 4.5,
    this.borderRadius = 16,
    this.isFullWidth = true,
  });

  @override
  State<DuoButton> createState() => _DuoButtonState();
}

class _DuoButtonState extends State<DuoButton> {
  bool _isPressed = false;

  bool get _isEnabled => widget.onPressed != null && !widget.isLoading;

  Color _getBaseColor(bool isDark) {
    if (!_isEnabled) {
      return isDark ? const Color(0xFF2B3A32) : const Color(0xFFE2E8F0);
    }
    if (widget.customColor != null) return widget.customColor!;

    switch (widget.variant) {
      case DuoButtonVariant.primary:
        return AppColors.primary;
      case DuoButtonVariant.secondary:
        return AppColors.secondary;
      case DuoButtonVariant.accent:
        return AppColors.accent;
      case DuoButtonVariant.outline:
        return isDark ? AppColors.surfaceDark : Colors.white;
    }
  }

  Color _getShadowColor(bool isDark) {
    if (!_isEnabled) {
      return isDark ? const Color(0xFF1E2822) : const Color(0xFFCBD5E1);
    }
    if (widget.customShadowColor != null) return widget.customShadowColor!;

    switch (widget.variant) {
      case DuoButtonVariant.primary:
        return AppColors.primaryDark;
      case DuoButtonVariant.secondary:
        return AppColors.secondaryDark;
      case DuoButtonVariant.accent:
        return AppColors.accentDark;
      case DuoButtonVariant.outline:
        return isDark ? const Color(0xFF101B14) : const Color(0xFFE2E8F0);
    }
  }

  Color _getTextColor(bool isDark) {
    if (!_isEnabled) {
      return isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    }
    if (widget.variant == DuoButtonVariant.outline) {
      return isDark ? Colors.white : AppColors.textPrimaryLight;
    }
    if (widget.variant == DuoButtonVariant.accent) {
      return const Color(0xFF4A3500);
    }
    return Colors.white;
  }

  void _handleTapDown(TapDownDetails details) {
    if (!_isEnabled) return;
    HapticFeedback.lightImpact();
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails details) {
    if (!_isEnabled) return;
    setState(() => _isPressed = false);
    widget.onPressed?.call();
  }

  void _handleTapCancel() {
    if (!_isEnabled) return;
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = _getBaseColor(isDark);
    final shadowColor = _getShadowColor(isDark);
    final textColor = _getTextColor(isDark);
    final depth = _isEnabled ? widget.depth : 2.0;

    Widget buttonContent = GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        curve: Curves.easeOutQuad,
        height: widget.height,
        margin: EdgeInsets.only(
          top: _isPressed ? depth : 0,
          bottom: _isPressed ? 0 : depth,
        ),
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: widget.variant == DuoButtonVariant.outline
              ? Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  width: 2,
                )
              : null,
          boxShadow: _isPressed || !_isEnabled
              ? []
              : [
                  BoxShadow(
                    color: shadowColor,
                    offset: Offset(0, depth),
                    blurRadius: 0,
                    spreadRadius: 0,
                  ),
                ],
        ),
        child: Center(
          child: widget.isLoading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(textColor),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, size: 20, color: textColor),
                        const SizedBox(width: 6),
                      ],
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            widget.label.toUpperCase(),
                            style: AppTextStyles.buttonPrimary.copyWith(
                              color: textColor,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );

    if (widget.isFullWidth) {
      return SizedBox(
        width: double.infinity,
        child: buttonContent,
      );
    }
    return buttonContent;
  }
}
