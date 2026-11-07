import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../domain/models/media_content.dart';
import 'media_player_controller.dart';
import 'widgets/media_player_controls.dart';
import 'widgets/synchronized_transcript_view.dart';

/// Écran complet du lecteur audio avec transcription synchronisée,
/// surlignage dynamique, bascule trilingue et intégration des phrases.
class MediaPlayerScreen extends ConsumerStatefulWidget {
  final MediaItem item;

  const MediaPlayerScreen({
    super.key,
    required this.item,
  });

  @override
  ConsumerState<MediaPlayerScreen> createState() => _MediaPlayerScreenState();
}

class _MediaPlayerScreenState extends ConsumerState<MediaPlayerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mediaPlayerControllerProvider.notifier).loadContent(widget.item, autoPlay: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mediaPlayerControllerProvider);
    final notifier = ref.read(mediaPlayerControllerProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final titleDe = state.transcript?.titleDe ?? widget.item.titleDe ?? (widget.item.type == MediaType.dialogue ? 'Dialogue' : 'Chanson');
    final titleAr = state.transcript?.titleAr ?? widget.item.titleAr ?? '';
    final titleFr = state.transcript?.titleFr ?? widget.item.titleFr ?? '';

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF131B26) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Lot ${widget.item.lotId} • ${widget.item.type == MediaType.dialogue ? 'Dialogue' : 'Chanson'}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              titleDe,
              style: AppTextStyles.bodyMedium(isDark: isDark).copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            if (titleAr.isNotEmpty)
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  titleAr,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF065F46),
                  ),
                ),
              ),
          ],
        ),
        centerTitle: true,
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
                        const SizedBox(height: 16),
                        Text(
                          state.errorMessage!,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium(isDark: isDark),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () => notifier.loadContent(widget.item, autoPlay: true),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                )
              : state.transcript == null
                  ? const Center(child: Text('Transcription introuvable.'))
                  : Column(
                      children: [
                        // Sous-titre français discret en haut si disponible
                        if (titleFr.isNotEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                            color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
                            child: Text(
                              titleFr,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                          ),

                        // Vue de transcription synchronisée
                        Expanded(
                          child: SynchronizedTranscriptView(
                            transcript: state.transcript!,
                            activeLineIndex: state.activeLineIndex,
                            translationMode: state.translationMode,
                            isListenFirstMode: state.isListenFirstMode,
                            isGermanRevealed: state.isGermanRevealed,
                            onLineTap: (idx) => notifier.seekToLine(idx),
                            onRevealGerman: () => notifier.revealGermanText(),
                          ),
                        ),

                        // Commandes audio en bas
                        MediaPlayerControls(
                          state: state,
                          onPlayPause: () => notifier.togglePlayPause(),
                          onSeek: (pos) => notifier.seek(pos),
                          onSeekRelative: (sec) => notifier.seekRelative(sec),
                          onToggleSpeed: () => notifier.toggleSpeed(),
                          onToggleLoop: () => notifier.toggleLoop(),
                          onCycleTranslation: () => notifier.cycleTranslationMode(),
                          onToggleListenFirst: () => notifier.toggleListenFirstMode(),
                        ),
                      ],
                    ),
    );
  }
}
