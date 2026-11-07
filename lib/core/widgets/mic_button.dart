import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Bouton microphone circulaire (80px) jaune soleil pour le shadowing et la parole.
/// Inclut une animation respirante (pulsation douce) lors de l'enregistrement actif.
class MicButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isRecording;
  final String? label;

  const MicButton({
    super.key,
    required this.onPressed,
    this.isRecording = false,
    this.label,
  });

  @override
  State<MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<MicButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.10).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant MicButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isRecording && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: widget.isRecording ? _scaleAnimation.value : 1.0,
              child: child,
            );
          },
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(
                    alpha: widget.isRecording ? 0.6 : 0.25,
                  ),
                  blurRadius: widget.isRecording ? 24 : 12,
                  spreadRadius: widget.isRecording ? 4 : 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: widget.onPressed,
                child: Center(
                  child: Icon(
                    widget.isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                    size: 38,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (widget.label != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.label!,
            style: AppTextStyles.caption(isDark: isDark).copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
