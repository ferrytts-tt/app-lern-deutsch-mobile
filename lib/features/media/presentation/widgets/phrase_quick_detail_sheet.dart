import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/tts_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/arabic_text_view.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../../core/widgets/german_text_annotator.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../data/database/app_database.dart';
import '../../../../domain/models/phrase.dart';
import '../../../../domain/models/user_phrase.dart';

/// Modal rapide affichant la fiche d'une phrase du lot cliquée depuis la transcription.
class PhraseQuickDetailSheet extends StatefulWidget {
  final String phraseId;

  const PhraseQuickDetailSheet({
    super.key,
    required this.phraseId,
  });

  static Future<void> show(BuildContext context, String phraseId) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PhraseQuickDetailSheet(phraseId: phraseId),
    );
  }

  @override
  State<PhraseQuickDetailSheet> createState() => _PhraseQuickDetailSheetState();
}

class _PhraseQuickDetailSheetState extends State<PhraseQuickDetailSheet> {
  final AppDatabase _db = AppDatabase.instance;
  final TtsService _tts = TtsService.instance;

  bool _isLoading = true;
  Phrase? _phrase;
  UserPhrase? _userPhrase;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final phrase = await _db.getPhraseById(widget.phraseId);
    final up = await _db.getProgressionForPhrase(widget.phraseId);
    if (mounted) {
      setState(() {
        _phrase = phrase;
        _userPhrase = up;
        _isLoading = false;
      });
    }
  }

  PhraseStatus _mapStatus(UserPhraseStatus? status) {
    switch (status) {
      case UserPhraseStatus.nouvelle:
        return PhraseStatus.nouvelle;
      case UserPhraseStatus.fragile:
      case UserPhraseStatus.enCours:
      case UserPhraseStatus.assezSolide:
      case UserPhraseStatus.solide:
      case UserPhraseStatus.tresSolide:
        return PhraseStatus.enCours;
      case UserPhraseStatus.maitrisee:
        return PhraseStatus.maitrisee;
      case UserPhraseStatus.aSurveiller:
        return PhraseStatus.aSurveiller;
      case null:
        return PhraseStatus.nouvelle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161F2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: _isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(),
                ),
              )
            : _phrase == null
                ? Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Center(
                      child: Text(
                        'Phrase non trouvée dans le catalogue.',
                        style: AppTextStyles.bodyMedium(isDark: isDark),
                      ),
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Poignée du modal
                      Center(
                        child: Container(
                          width: 48,
                          height: 5,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white24 : Colors.black12,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),

                      // En-tête : Badge phrase du lot & Niveau SRS
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded, size: 16, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Text(
                                  'Phrase du lot (${_phrase!.id})',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          StatusBadge(
                            status: _mapStatus(_userPhrase?.status),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Phrase allemande parlée + Bouton Audio
                      CustomCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: GermanTextView(
                                    text: _phrase!.de,
                                    baseStyle: AppTextStyles.germanPhrase(isDark: isDark).copyWith(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                IconButton.filled(
                                  onPressed: () => _tts.speak(_phrase!.deParle),
                                  icon: const Icon(Icons.volume_up_rounded, color: Colors.white),
                                  style: IconButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            if (_phrase!.deStandard != _phrase!.de) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Forme standard : ${_phrase!.deStandard}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                  color: isDark ? Colors.white60 : Colors.black54,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Traduction arabe raffinée avec fond émeraude
                      if (_phrase!.ar != null && _phrase!.ar!.isNotEmpty) ...[
                        ArabicTextView(
                          text: _phrase!.ar!,
                          fontSize: 18,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                      ],

                      // Traduction française
                      Text(
                        _phrase!.fr,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.translation(isDark: isDark).copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      // Note culturelle / astuce si présente
                      if (_phrase!.note != null && _phrase!.note!.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1C2738) : const Color(0xFFF3F6FA),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark ? const Color(0xFF2E3E56) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('💡', style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _phrase!.note!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 18),

                      // Bouton d'accès à la fiche détaillée complète
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          context.push('/library/phrase/${widget.phraseId}');
                        },
                        icon: const Icon(Icons.open_in_new_rounded, size: 18),
                        label: const Text('Ouvrir la fiche complète (Pratique & Micro)'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
