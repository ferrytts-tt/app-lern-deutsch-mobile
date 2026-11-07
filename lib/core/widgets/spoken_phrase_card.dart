import 'package:flutter/material.dart';
import '../services/tts_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'custom_card.dart';
import 'duo_button.dart';
import 'german_text_annotator.dart';
import 'arabic_text_view.dart';
import '../../domain/models/phrase.dart';
import '../../domain/models/topic.dart';

/// Carte pédagogique principale de présentation d'une phrase allemande parlée (Étape 2).
///
/// Respecte strictement les 4 principes du workflow plan :
/// 1. Forme parlée (`de_parle`) en grand (vraie cible d'apprentissage).
/// 2. Traduction sous bouton discret (arabe par défaut, avec support RTL et police claire).
/// 3. Forme standard (`de_standard`) masquée/dépliable (sert de pont vers le B2 telc).
/// 4. Note d'explication (`note`) pour les astuces de langue et contractions.
/// 5. Deux vitesses d'écoute audio (Normale 1.0x et Lente 0.65x).
/// 6. Bouton « Trop facile » pour sauter directement au niveau 4 (7 jours de révision).
class SpokenPhraseCard extends StatefulWidget {
  final Phrase phrase;
  final String preferredTranslationLanguage; // 'ar' par défaut, ou 'fr'
  final bool initialShowTranslation;
  final bool initialShowStandard;
  final VoidCallback? onPlayNormal;
  final VoidCallback? onPlaySlow;
  final VoidCallback? onTooEasy;
  final Widget? bottomAction;

  const SpokenPhraseCard({
    super.key,
    required this.phrase,
    this.preferredTranslationLanguage = 'ar',
    this.initialShowTranslation = false,
    this.initialShowStandard = false,
    this.onPlayNormal,
    this.onPlaySlow,
    this.onTooEasy,
    this.bottomAction,
  });

  @override
  State<SpokenPhraseCard> createState() => _SpokenPhraseCardState();
}

class _SpokenPhraseCardState extends State<SpokenPhraseCard> {
  late bool _showTranslation;
  late bool _showStandard;
  final TtsService _tts = TtsService.instance;
  bool _isPlayingNormal = false;
  bool _isPlayingSlow = false;

  @override
  void initState() {
    super.initState();
    _showTranslation = widget.initialShowTranslation;
    _showStandard = widget.initialShowStandard;

    _tts.isPlayingNotifier.addListener(_onTtsPlayingChanged);
  }

  @override
  void didUpdateWidget(covariant SpokenPhraseCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.phrase.id != widget.phrase.id) {
      _showTranslation = widget.initialShowTranslation;
      _showStandard = widget.initialShowStandard;
    }
  }

  @override
  void dispose() {
    _tts.isPlayingNotifier.removeListener(_onTtsPlayingChanged);
    super.dispose();
  }

  void _onTtsPlayingChanged() {
    if (!mounted) return;
    if (!_tts.isPlaying) {
      setState(() {
        _isPlayingNormal = false;
        _isPlayingSlow = false;
      });
    }
  }

  void _handlePlayNormal() {
    if (widget.onPlayNormal != null) {
      widget.onPlayNormal!();
      return;
    }
    setState(() {
      _isPlayingNormal = true;
      _isPlayingSlow = false;
    });
    _tts.speak(
      widget.phrase.deParle,
      phraseId: widget.phrase.id,
      slow: false,
      onDone: () {
        if (mounted) setState(() => _isPlayingNormal = false);
      },
    );
  }

  void _handlePlaySlow() {
    if (widget.onPlaySlow != null) {
      widget.onPlaySlow!();
      return;
    }
    setState(() {
      _isPlayingNormal = false;
      _isPlayingSlow = true;
    });
    _tts.speak(
      widget.phrase.deParle,
      phraseId: widget.phrase.id,
      slow: true,
      onDone: () {
        if (mounted) setState(() => _isPlayingSlow = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topic = TopicInfo.getById(widget.phrase.topic);
    final hasStandardForm = widget.phrase.deStandard.isNotEmpty &&
        widget.phrase.deStandard != widget.phrase.deParle;
    final isArabic = widget.preferredTranslationLanguage == 'ar';
    final hasArabic = widget.phrase.ar != null && widget.phrase.ar!.trim().isNotEmpty;

    return CustomCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 1. En-tête : Thème & Niveau CECR ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: topic.themeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(topic.icon, size: 16, color: topic.themeColor),
                    const SizedBox(width: 6),
                    Text(
                      topic.title,
                      style: TextStyle(
                        color: topic.themeColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.record_voice_over_rounded, size: 14, color: AppColors.primaryDark),
                    const SizedBox(width: 4),
                    Text(
                      'Allemand parlé',
                      style: TextStyle(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // ── 2. Forme parlée (de_parle) EN GRAND ──
          Center(
            child: GermanTextView(
              text: widget.phrase.deParle,
              baseStyle: AppTextStyles.germanPhrase(isDark: isDark).copyWith(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                height: 1.3,
              ),
            ),
          ),

          const SizedBox(height: 18),

          // ── 3. Bouton discret & Affichage de la traduction (arabe par défaut) ──
          if (!_showTranslation) ...[
            Center(
              child: OutlinedButton.icon(
                key: const Key('btn_show_translation'),
                onPressed: () => setState(() => _showTranslation = true),
                icon: const Icon(Icons.translate_rounded, size: 18),
                label: Text(
                  isArabic ? 'Afficher la traduction (عربي)' : 'Afficher la traduction',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.secondary,
                  side: BorderSide(
                    color: AppColors.secondary.withValues(alpha: 0.5),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
          ] else ...[
            Container(
              key: const Key('box_translation'),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E2836)
                    : const Color(0xFFF0F7FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF2C3E50) : const Color(0xFFBEE3F8),
                ),
              ),
              child: Column(
                children: [
                  // Traduction principale
                  if (isArabic && hasArabic) ...[
                    ArabicTextView(
                      key: const Key('text_translation_ar'),
                      text: widget.phrase.ar!,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.arabicPrimaryDark : AppColors.arabicPrimaryLight,
                      textAlign: TextAlign.center,
                    ),
                    if (widget.phrase.fr.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        widget.phrase.fr,
                        key: const Key('text_translation_fr_sub'),
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white60 : Colors.black54,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ] else ...[
                    // Traduction principale (autre langue)
                    Text(
                      widget.phrase.getTranslation(widget.preferredTranslationLanguage).isNotEmpty
                          ? widget.phrase.getTranslation(widget.preferredTranslationLanguage)
                          : (widget.phrase.fr.isNotEmpty ? widget.phrase.fr : (widget.phrase.ar ?? '')),
                      key: const Key('text_translation_fr'),
                      style: AppTextStyles.translation(isDark: isDark).copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (widget.phrase.fr.isNotEmpty &&
                        widget.phrase.getTranslation(widget.preferredTranslationLanguage) != widget.phrase.fr &&
                        !isArabic) ...[
                      const SizedBox(height: 6),
                      Text(
                        widget.phrase.fr,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white60 : Colors.black54,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // ── 4. Forme standard (de_standard) MASQUÉE / DÉPLIABLE ──
          if (hasStandardForm) ...[
            InkWell(
              key: const Key('btn_toggle_standard'),
              borderRadius: BorderRadius.circular(14),
              onTap: () => setState(() => _showStandard = !_showStandard),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF242A38)
                      : const Color(0xFFEDF2F7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? const Color(0xFF333E50) : const Color(0xFFCBD5E0),
                  ),
                ),
                child: Row(
                  children: [
                    const Text('🇩🇪', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Forme standard (ce que tu connais déjà)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                    Icon(
                      _showStandard ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ],
                ),
              ),
            ),
            if (_showStandard) ...[
              const SizedBox(height: 8),
              Container(
                key: const Key('box_standard_content'),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2330) : const Color(0xFFF7FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF2D3748) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hochdeutsch :',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.accentLight : AppColors.accentDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.phrase.deStandard,
                      key: const Key('text_standard_phrase'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],

          // ── 5. Note d'explication (astuces de langue, contractions) ──
          if (widget.phrase.note != null && widget.phrase.note!.trim().isNotEmpty) ...[
            Container(
              key: const Key('container_phrase_note'),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1B2F22) : const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb_rounded,
                    color: Color(0xFF2E7D32),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.phrase.note!,
                      key: const Key('text_phrase_note'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFFA5D6A7) : const Color(0xFF1B5E20),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // ── 6. Boutons Audio (Vitesse normale & Vitesse lente) ──
          Row(
            children: [
              // Bouton Vitesse Normale
              Expanded(
                child: DuoButton(
                  key: const Key('btn_audio_normal'),
                  label: 'Normal 1.0x',
                  icon: Icons.volume_up_rounded,
                  isLoading: _isPlayingNormal,
                  variant: DuoButtonVariant.primary,
                  onPressed: _handlePlayNormal,
                ),
              ),
              const SizedBox(width: 12),
              // Bouton Vitesse Lente
              Expanded(
                child: DuoButton(
                  key: const Key('btn_audio_slow'),
                  label: 'Lent 0.65x',
                  icon: Icons.slow_motion_video_rounded,
                  isLoading: _isPlayingSlow,
                  variant: DuoButtonVariant.secondary,
                  onPressed: _handlePlaySlow,
                ),
              ),
            ],
          ),

          // ── 7. Bouton « Trop facile » (Saut vers niveau 4) ──
          if (widget.onTooEasy != null) ...[
            const SizedBox(height: 14),
            DuoButton(
              key: const Key('btn_too_easy'),
              label: '⚡ Trop facile (sauter au niveau 4)',
              variant: DuoButtonVariant.outline,
              onPressed: widget.onTooEasy,
            ),
          ],

          // ── Action optionnelle supplémentaire (ex. suivant, valider) ──
          if (widget.bottomAction != null) ...[
            const SizedBox(height: 16),
            widget.bottomAction!,
          ],
        ],
      ),
    );
  }
}
