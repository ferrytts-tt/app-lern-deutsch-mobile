import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Bouton audio circulaire tactile (64px / 52px) en bleu ciel avec animation douce lors de la lecture.
class AudioButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isPlaying;
  final double size;
  final String? label;
  final IconData icon;

  const AudioButton({
    super.key,
    required this.onPressed,
    this.isPlaying = false,
    this.size = 64,
    this.label,
    this.icon = Icons.volume_up_rounded,
  });

  @override
  State<AudioButton> createState() => _AudioButtonState();
}

class _AudioButtonState extends State<AudioButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant AudioButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isPlaying && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
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
              scale: widget.isPlaying ? _scaleAnimation.value : 1.0,
              child: child,
            );
          },
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.secondary,
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondary.withValues(
                    alpha: widget.isPlaying ? 0.4 : 0.2,
                  ),
                  blurRadius: widget.isPlaying ? 16 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: widget.onPressed,
                splashColor: AppColors.secondaryLight.withValues(alpha: 0.3),
                child: Center(
                  child: Icon(
                    widget.icon,
                    size: widget.size * 0.48,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (widget.label != null) ...[
          const SizedBox(height: 6),
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
