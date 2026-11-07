import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/duo_button.dart';
import '../media_player_controller.dart';

/// Barre de commandes audio inférieure pour le lecteur de médias
class MediaPlayerControls extends StatelessWidget {
  final MediaPlayerState state;
  final VoidCallback onPlayPause;
  final Function(Duration) onSeek;
  final Function(int) onSeekRelative;
  final VoidCallback onToggleSpeed;
  final VoidCallback onToggleLoop;
  final VoidCallback onCycleTranslation;
  final VoidCallback onToggleListenFirst;

  const MediaPlayerControls({
    super.key,
    required this.state,
    required this.onPlayPause,
    required this.onSeek,
    required this.onSeekRelative,
    required this.onToggleSpeed,
    required this.onToggleLoop,
    required this.onCycleTranslation,
    required this.onToggleListenFirst,
  });

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final posMs = state.position.inMilliseconds.toDouble();
    final durMs = state.duration.inMilliseconds.toDouble();
    final clampedPos = durMs > 0 ? posMs.clamp(0.0, durMs) : 0.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B26) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Barre d'options rapides : Traduction, Écoute d'abord, Vitesse, Boucle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Bascule de traduction
                _ControlButton(
                  icon: Icons.translate_rounded,
                  label: state.translationMode.id == 'arabe'
                      ? '🇸🇦 Arabe'
                      : (state.translationMode.id == 'francais' ? '🇫🇷 Français' : '🚫 Sans trad.'),
                  isActive: state.translationMode != TranslationDisplayMode.aucune,
                  activeColor: AppColors.primary,
                  onTap: onCycleTranslation,
                ),

                // Mode Écoute d'abord
                _ControlButton(
                  icon: Icons.headphones_rounded,
                  label: state.isListenFirstMode ? 'Écoute d\'abord' : 'Texte visible',
                  isActive: state.isListenFirstMode,
                  activeColor: const Color(0xFF8B5CF6),
                  onTap: onToggleListenFirst,
                ),

                // Vitesse audio
                _ControlButton(
                  icon: Icons.speed_rounded,
                  label: '${state.speed}x',
                  isActive: state.speed != 1.0,
                  activeColor: const Color(0xFFF59E0B),
                  onTap: onToggleSpeed,
                ),

                // Mode boucle
                _ControlButton(
                  icon: Icons.repeat_rounded,
                  label: 'Boucle',
                  isActive: state.isLooping,
                  activeColor: const Color(0xFF10B981),
                  onTap: onToggleLoop,
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Barre de progression (Slider)
            Row(
              children: [
                Text(
                  _formatDuration(state.position),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                      activeTrackColor: AppColors.primary,
                      inactiveTrackColor: isDark ? Colors.white12 : Colors.black12,
                      thumbColor: AppColors.primary,
                    ),
                    child: Slider(
                      value: clampedPos,
                      min: 0.0,
                      max: durMs > 0 ? durMs : 1.0,
                      onChanged: (val) {
                        onSeek(Duration(milliseconds: val.toInt()));
                      },
                    ),
                  ),
                ),
                Text(
                  _formatDuration(state.duration),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),

            // Commandes principales : -5s, Play/Pause 3D, +5s
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () => onSeekRelative(-5),
                  icon: const Icon(Icons.replay_5_rounded, size: 30),
                  tooltip: 'Reculer de 5 secondes',
                ),
                const SizedBox(width: 20),
                DuoButton(
                  label: state.isPlaying ? 'Pause' : 'Lecture',
                  icon: state.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  onPressed: onPlayPause,
                  isFullWidth: false,
                  height: 52,
                ),
                const SizedBox(width: 20),
                IconButton(
                  onPressed: () => onSeekRelative(5),
                  icon: const Icon(Icons.forward_5_rounded, size: 30),
                  tooltip: 'Avancer de 5 secondes',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: isDark ? 0.22 : 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? activeColor.withValues(alpha: 0.5)
                : (isDark ? Colors.white12 : Colors.black12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isActive
                  ? activeColor
                  : (isDark ? Colors.white70 : Colors.black87),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                color: isActive
                    ? activeColor
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
