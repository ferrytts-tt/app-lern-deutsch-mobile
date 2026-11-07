import 'package:flutter/material.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/arabic_text_view.dart';
import '../../../../domain/models/media_content.dart';
import '../media_player_controller.dart';
import 'phrase_quick_detail_sheet.dart';

/// Vue de transcription synchronisée avec surlignage dynamique,
/// rejeu direct au tap, masquage "Écoute d'abord", et liens vers les phrases du lot.
class SynchronizedTranscriptView extends StatefulWidget {
  final MediaTranscript transcript;
  final int activeLineIndex;
  final TranslationDisplayMode translationMode;
  final bool isListenFirstMode;
  final bool isGermanRevealed;
  final Function(int lineIndex) onLineTap;
  final VoidCallback onRevealGerman;

  const SynchronizedTranscriptView({
    super.key,
    required this.transcript,
    required this.activeLineIndex,
    required this.translationMode,
    required this.isListenFirstMode,
    required this.isGermanRevealed,
    required this.onLineTap,
    required this.onRevealGerman,
  });

  @override
  State<SynchronizedTranscriptView> createState() => _SynchronizedTranscriptViewState();
}

class _SynchronizedTranscriptViewState extends State<SynchronizedTranscriptView> {
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _lineKeys = {};

  @override
  void didUpdateWidget(covariant SynchronizedTranscriptView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeLineIndex != oldWidget.activeLineIndex && widget.activeLineIndex >= 0) {
      _scrollToActiveLine(widget.activeLineIndex);
    }
  }

  void _scrollToActiveLine(int index) {
    final key = _lineKeys[index];
    if (key == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = key.currentContext;
      if (context != null && mounted) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          alignment: 0.35, // Positionne la ligne au premier tiers de l'écran
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lines = widget.transcript.lignes;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
      itemCount: lines.length,
      itemBuilder: (context, index) {
        _lineKeys.putIfAbsent(index, () => GlobalKey());
        final line = lines[index];
        final isActive = index == widget.activeLineIndex;

        return _TranscriptLineCard(
          key: _lineKeys[index],
          line: line,
          lineIndex: index,
          isActive: isActive,
          translationMode: widget.translationMode,
          isListenFirstMode: widget.isListenFirstMode,
          isGermanRevealed: widget.isGermanRevealed,
          isDark: isDark,
          onTap: () => widget.onLineTap(index),
          onReveal: widget.onRevealGerman,
        );
      },
    );
  }
}

class _TranscriptLineCard extends StatelessWidget {
  final TranscriptLine line;
  final int lineIndex;
  final bool isActive;
  final TranslationDisplayMode translationMode;
  final bool isListenFirstMode;
  final bool isGermanRevealed;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onReveal;

  const _TranscriptLineCard({
    super.key,
    required this.line,
    required this.lineIndex,
    required this.isActive,
    required this.translationMode,
    required this.isListenFirstMode,
    required this.isGermanRevealed,
    required this.isDark,
    required this.onTap,
    required this.onReveal,
  });

  Color _getSpeakerColor(String speaker) {
    final s = speaker.toLowerCase();
    if (s.contains('conrad')) return const Color(0xFF3B82F6);
    if (s.contains('katja')) return const Color(0xFFEC4899);
    if (s.contains('chant') || s.contains('refrain')) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  IconData _getSpeakerIcon(String speaker) {
    final s = speaker.toLowerCase();
    if (s.contains('conrad')) return Icons.record_voice_over_rounded;
    if (s.contains('katja')) return Icons.record_voice_over_rounded;
    if (s.contains('chant') || s.contains('refrain')) return Icons.music_note_rounded;
    return Icons.mic_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final speakerColor = _getSpeakerColor(line.locuteur);

    // Style de surlignage dynamique
    final cardBg = isActive
        ? (isDark ? const Color(0xFF1E2E42) : const Color(0xFFEBF5FF))
        : (isDark ? const Color(0xFF141D29) : Colors.white);

    final borderColor = isActive
        ? const Color(0xFF3B82F6)
        : (isDark ? const Color(0xFF233142) : const Color(0xFFE2E8F0));

    final hideGerman = isListenFirstMode && !isGermanRevealed;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: borderColor,
            width: isActive ? 2.0 : 1.0,
          ),
          boxShadow: [
            if (isActive)
              BoxShadow(
                color: const Color(0xFF3B82F6).withValues(alpha: isDark ? 0.35 : 0.18),
                blurRadius: 14,
                offset: const Offset(0, 4),
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // En-tête : Badge Locuteur + Badge Phrase du lot (si présent) + Indicateur Actif
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Badge locuteur
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: speakerColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: speakerColor.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_getSpeakerIcon(line.locuteur), size: 14, color: speakerColor),
                            const SizedBox(width: 5),
                            Text(
                              line.locuteur,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: speakerColor,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Badges à droite (Indicateur actif + Phrase du lot)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isActive) ...[
                            const Icon(Icons.graphic_eq_rounded, size: 16, color: Color(0xFF3B82F6)),
                            const SizedBox(width: 4),
                            const Text(
                              'En cours',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3B82F6),
                              ),
                            ),
                            if (line.hasPhraseLink) const SizedBox(width: 8),
                          ],
                          if (line.hasPhraseLink)
                            InkWell(
                              onTap: () => PhraseQuickDetailSheet.show(context, line.phraseId!),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFB703).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFFFFB703).withValues(alpha: 0.5),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.star_rounded, size: 14, color: Color(0xFFD97706)),
                                    SizedBox(width: 4),
                                    Text(
                                      'Phrase du lot',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFFD97706),
                                      ),
                                    ),
                                    SizedBox(width: 2),
                                    Icon(Icons.chevron_right_rounded, size: 14, color: Color(0xFFD97706)),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Texte allemand (avec prise en charge du mode Écoute d'abord)
                  if (hideGerman)
                    GestureDetector(
                      onTap: onReveal,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1B2433) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? const Color(0xFF2C394B) : const Color(0xFFCBD5E1),
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.headphones_rounded, size: 18, color: speakerColor),
                            const SizedBox(width: 8),
                            Text(
                              '🎧 Écoute active... Touche pour afficher',
                              style: TextStyle(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                color: isDark ? Colors.white70 : Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Text(
                      line.de,
                      style: AppTextStyles.germanPhraseSmall(isDark: isDark).copyWith(
                        fontSize: 17,
                        fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                        height: 1.4,
                      ),
                    ),

                  // Traductions conditionnelles selon le mode choisi
                  if (!hideGerman) ...[
                    // Traduction Arabe élégante (RTL & cartouche émeraude)
                    if (translationMode == TranslationDisplayMode.arabe && line.ar.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ArabicTextView(
                        text: line.ar,
                        fontSize: 16,
                        textAlign: TextAlign.start,
                      ),
                    ],

                    // Traduction Française
                    if (translationMode == TranslationDisplayMode.francais && line.fr.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        line.fr,
                        style: AppTextStyles.translation(isDark: isDark).copyWith(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
