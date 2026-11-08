import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'german_text_annotator.dart';
import 'arabic_text_view.dart';

/// Personnages natifs allemands inspirés de l'univers Duolingo.
enum DuoSpeakerCharacter {
  lukas, // Homme chaleureux avec manteau caramel (style Oscar/Vikram de Duolingo)
  anna,  // Jeune femme dynamique avec veste turquoise (style Bea/Lin de Duolingo)
  max,   // Garçon enthousiaste avec casquette (style Junior de Duolingo)
  bear,  // Falstaff l'ours brun emblématique de Duolingo avec écharpe turquoise et bras croisés
}

/// Widget affichant un personnage animé style Duolingo à côté d'une bulle de dialogue
/// contenant le bouton audio et la phrase allemande.
class DuoCharacterSpeaker extends StatefulWidget {
  final String germanText;
  final String? translationText;
  final String? arabicText;
  final bool isPlaying;
  final VoidCallback onPlayAudio;
  final VoidCallback? onPlaySlow;
  final DuoSpeakerCharacter? character;
  final double characterHeight;
  final bool showTranslation;
  final bool audioOnly;
  final TextStyle? phraseStyle;

  const DuoCharacterSpeaker({
    super.key,
    required this.germanText,
    this.translationText,
    this.arabicText,
    required this.isPlaying,
    required this.onPlayAudio,
    this.onPlaySlow,
    this.character,
    this.characterHeight = 110,
    this.showTranslation = false,
    this.audioOnly = false,
    this.phraseStyle,
  });

  @override
  State<DuoCharacterSpeaker> createState() => _DuoCharacterSpeakerState();
}

class _DuoCharacterSpeakerState extends State<DuoCharacterSpeaker>
    with TickerProviderStateMixin {
  late AnimationController _talkingController;
  late AnimationController _idleController;
  late Animation<double> _mouthAnimation;
  late Animation<double> _bobAnimation;
  late Animation<double> _rippleAnimation;

  @override
  void initState() {
    super.initState();

    // Animation du personnage qui parle (mouvements de bouche & hochement doux)
    _talkingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _mouthAnimation = Tween<double>(begin: 0.1, end: 1.0).animate(
      CurvedAnimation(parent: _talkingController, curve: Curves.easeInOut),
    );

    _bobAnimation = Tween<double>(begin: 0.0, end: -4.0).animate(
      CurvedAnimation(parent: _talkingController, curve: Curves.easeInOut),
    );

    // Animation d'ondes sonores et respiration légère
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _rippleAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _idleController, curve: Curves.easeInOut),
    );

    if (widget.isPlaying) {
      _talkingController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant DuoCharacterSpeaker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _talkingController.repeat(reverse: true);
      } else {
        _talkingController.animateTo(0.0, duration: const Duration(milliseconds: 150));
      }
    }
  }

  @override
  void dispose() {
    _talkingController.dispose();
    _idleController.dispose();
    super.dispose();
  }

  DuoSpeakerCharacter _resolveCharacter() {
    if (widget.character != null) return widget.character!;
    final hash = widget.germanText.hashCode.abs();
    switch (hash % 4) {
      case 0:
        return DuoSpeakerCharacter.lukas;
      case 1:
        return DuoSpeakerCharacter.anna;
      case 2:
        return DuoSpeakerCharacter.bear;
      default:
        return DuoSpeakerCharacter.max;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final char = _resolveCharacter();

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Le Personnage animé Duolingo (format compact élégant) ──
            AnimatedBuilder(
              animation: Listenable.merge([_talkingController, _idleController]),
              builder: (context, child) {
                final bob = widget.isPlaying ? _bobAnimation.value : 0.0;
                final mouthOpen = widget.isPlaying ? _mouthAnimation.value : 0.05;
                const charH = 92.0;
                return Transform.translate(
                  offset: Offset(0, bob),
                  child: SizedBox(
                    width: charH * 0.74,
                    height: charH,
                    child: CustomPaint(
                      painter: _DuolingoCharacterPainter(
                        character: char,
                        mouthOpen: mouthOpen,
                        isDark: isDark,
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(width: 4),

            // ── 2. Flèche de la bulle de parole ────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: CustomPaint(
                size: const Size(10, 18),
                painter: _SpeechBubbleArrowPainter(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderColor: isDark ? AppColors.borderDark : const Color(0xFFE5E7EB),
                ),
              ),
            ),

            // ── 3. La Bulle de dialogue style Duolingo ─────────────────
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onPlayAudio,
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: widget.isPlaying
                            ? AppColors.primary
                            : (isDark ? AppColors.borderDark : const Color(0xFFE5E7EB)),
                        width: widget.isPlaying ? 2.2 : 1.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Ligne supérieure de la bulle : Boutons audio + indicateur
                        Row(
                          children: [
                            // Bouton Haut-Parleur Duolingo (Bleu vif #1CB0F6)
                            AnimatedBuilder(
                              animation: _idleController,
                              builder: (context, child) {
                                final scale = widget.isPlaying ? _rippleAnimation.value : 1.0;
                                return Transform.scale(
                                  scale: scale,
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: widget.onPlayAudio,
                                      customBorder: const CircleBorder(),
                                      child: Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          color: widget.isPlaying
                                              ? const Color(0xFF1899D6)
                                              : const Color(0xFF1CB0F6),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF1899D6).withValues(alpha: 0.4),
                                              blurRadius: widget.isPlaying ? 8 : 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          widget.isPlaying
                                              ? Icons.volume_up_rounded
                                              : Icons.volume_up_outlined,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),

                            // Bouton vitesse lente (Tortue / 0.65x) si fourni
                            if (widget.onPlaySlow != null) ...[
                              const SizedBox(width: 8),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: widget.onPlaySlow,
                                  customBorder: const CircleBorder(),
                                  child: Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF2C3E50) : const Color(0xFFE5F6FD),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFF1CB0F6).withValues(alpha: 0.5),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.slow_motion_video_rounded,
                                      color: Color(0xFF1CB0F6),
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(width: 8),

                            Expanded(
                              child: Text(
                                widget.isPlaying ? 'Lecture audio...' : 'Toucher pour écouter',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: widget.isPlaying
                                      ? const Color(0xFF1CB0F6)
                                      : (isDark ? Colors.white60 : const Color(0xFF6B7280)),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Texte allemand sur TOUTE la largeur de la bulle
                        if (widget.audioOnly) ...[
                          Row(
                            children: [
                              Icon(
                                widget.isPlaying ? Icons.graphic_eq_rounded : Icons.hearing_rounded,
                                size: 18,
                                color: widget.isPlaying ? const Color(0xFF1CB0F6) : AppColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  widget.isPlaying ? 'Écoute attentivement...' : 'Touche pour écouter la voix',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: widget.isPlaying
                                        ? const Color(0xFF1CB0F6)
                                        : (isDark ? Colors.white70 : const Color(0xFF4B5563)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          GermanTextView(
                            text: widget.germanText,
                            textAlign: TextAlign.start,
                            baseStyle: widget.phraseStyle ??
                                TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                                  height: 1.35,
                                  letterSpacing: -0.2,
                                ),
                          ),
                        ],
                        if (widget.showTranslation &&
                            ((widget.translationText != null && widget.translationText!.isNotEmpty) ||
                                (widget.arabicText != null && widget.arabicText!.isNotEmpty))) ...[
                          const SizedBox(height: 6),
                          if (widget.arabicText != null && widget.arabicText!.isNotEmpty)
                            ArabicTextView(
                              text: widget.arabicText!,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.arabicPrimaryDark : AppColors.arabicPrimaryLight,
                              textAlign: TextAlign.start,
                            ),
                          if (widget.translationText != null && widget.translationText!.isNotEmpty)
                            Text(
                              widget.translationText!,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Peintre de la flèche de la bulle de dialogue orientée vers le personnage.
class _SpeechBubbleArrowPainter extends CustomPainter {
  final Color color;
  final Color borderColor;

  const _SpeechBubbleArrowPainter({
    required this.color,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(0, size.height / 2)
      ..lineTo(size.width, size.height)
      ..close();

    final fillPaint = Paint()..color = color;
    canvas.drawPath(path, fillPaint);

    final borderPaint = Paint()
      ..color = borderColor
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    final borderPath = Path()
      ..moveTo(size.width, 0)
      ..lineTo(0, size.height / 2)
      ..lineTo(size.width, size.height);
    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _SpeechBubbleArrowPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.borderColor != borderColor;
}

/// Dessin vectoriel 100% net des personnages allemands style Duolingo.
class _DuolingoCharacterPainter extends CustomPainter {
  final DuoSpeakerCharacter character;
  final double mouthOpen; // 0.0 (fermé) à 1.0 (ouvert)
  final bool isDark;

  const _DuolingoCharacterPainter({
    required this.character,
    required this.mouthOpen,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    switch (character) {
      case DuoSpeakerCharacter.lukas:
        _paintLukas(canvas, w, h);
        break;
      case DuoSpeakerCharacter.anna:
        _paintAnna(canvas, w, h);
        break;
      case DuoSpeakerCharacter.max:
        _paintMax(canvas, w, h);
        break;
      case DuoSpeakerCharacter.bear:
        _paintBear(canvas, w, h);
        break;
    }
  }

  // ── Personnage 1 : Lukas (style Oscar / Vikram avec manteau caramel) ──
  void _paintLukas(Canvas canvas, double w, double h) {
    // 1. Manteau & Corps
    final coatPaint = Paint()..color = const Color(0xFFC77826); // Camel/Caramel
    final coatPath = Path()
      ..moveTo(w * 0.15, h)
      ..lineTo(w * 0.18, h * 0.65)
      ..quadraticBezierTo(w * 0.5, h * 0.58, w * 0.82, h * 0.65)
      ..lineTo(w * 0.85, h)
      ..close();
    canvas.drawPath(coatPath, coatPaint);

    // Chemise blanche centrale
    final shirtPaint = Paint()..color = Colors.white;
    final shirtPath = Path()
      ..moveTo(w * 0.40, h * 0.62)
      ..lineTo(w * 0.50, h * 0.80)
      ..lineTo(w * 0.60, h * 0.62)
      ..close();
    canvas.drawPath(shirtPath, shirtPaint);

    // Col du manteau
    final collarPaint = Paint()..color = const Color(0xFFA55A14);
    canvas.drawLine(Offset(w * 0.35, h * 0.63), Offset(w * 0.45, h * 0.78), collarPaint..strokeWidth = 3);
    canvas.drawLine(Offset(w * 0.65, h * 0.63), Offset(w * 0.55, h * 0.78), collarPaint..strokeWidth = 3);

    // 2. Tête (Visage chaleureux)
    final skinPaint = Paint()..color = const Color(0xFFFFD1A9);
    final faceRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.38),
      width: w * 0.65,
      height: h * 0.44,
    );
    canvas.drawOval(faceRect, skinPaint);

    // 3. Cheveux châtains soignés
    final hairPaint = Paint()..color = const Color(0xFF4A3326);
    final hairPath = Path()
      ..moveTo(w * 0.18, h * 0.35)
      ..quadraticBezierTo(w * 0.18, h * 0.12, w * 0.50, h * 0.12)
      ..quadraticBezierTo(w * 0.84, h * 0.12, w * 0.84, h * 0.35)
      ..quadraticBezierTo(w * 0.70, h * 0.22, w * 0.50, h * 0.24)
      ..quadraticBezierTo(w * 0.32, h * 0.22, w * 0.18, h * 0.35)
      ..close();
    canvas.drawPath(hairPath, hairPaint);

    // 4. Yeux pétillants & Sourcils
    final eyePaint = Paint()..color = const Color(0xFF2C1D11);
    canvas.drawCircle(Offset(w * 0.38, h * 0.34), 3.2, eyePaint);
    canvas.drawCircle(Offset(w * 0.62, h * 0.34), 3.2, eyePaint);

    // Reflet blanc dans les yeux
    final shinePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(w * 0.37, h * 0.33), 1.2, shinePaint);
    canvas.drawCircle(Offset(w * 0.61, h * 0.33), 1.2, shinePaint);

    // Sourcils
    final browPaint = Paint()
      ..color = const Color(0xFF4A3326)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(w * 0.32, h * 0.29), Offset(w * 0.44, h * 0.29), browPaint);
    canvas.drawLine(Offset(w * 0.56, h * 0.29), Offset(w * 0.68, h * 0.29), browPaint);

    // 5. Joues rosées Duolingo
    final blushPaint = Paint()..color = const Color(0xFFFF8C8C).withValues(alpha: 0.35);
    canvas.drawCircle(Offset(w * 0.28, h * 0.40), 5.5, blushPaint);
    canvas.drawCircle(Offset(w * 0.72, h * 0.40), 5.5, blushPaint);

    // 6. Bouche animée (parle en synchro avec l'audio)
    _paintMouth(canvas, Offset(w * 0.5, h * 0.46), w * 0.24);
  }

  // ── Personnage 2 : Anna (style Bea / Lin avec veste turquoise) ───────
  void _paintAnna(Canvas canvas, double w, double h) {
    // 1. Veste turquoise
    final coatPaint = Paint()..color = const Color(0xFF00A88F);
    final coatPath = Path()
      ..moveTo(w * 0.15, h)
      ..lineTo(w * 0.18, h * 0.64)
      ..quadraticBezierTo(w * 0.5, h * 0.56, w * 0.82, h * 0.64)
      ..lineTo(w * 0.85, h)
      ..close();
    canvas.drawPath(coatPath, coatPaint);

    // Écharpe jaune/or Duolingo
    final scarfPaint = Paint()..color = const Color(0xFFFFC83D);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w * 0.5, h * 0.64), width: w * 0.42, height: h * 0.08),
        const Radius.circular(8),
      ),
      scarfPaint,
    );

    // 2. Visage
    final skinPaint = Paint()..color = const Color(0xFFFFDFBA);
    final faceRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.38),
      width: w * 0.62,
      height: h * 0.42,
    );
    canvas.drawOval(faceRect, skinPaint);

    // 3. Cheveux bruns avec queue de cheval / mèches
    final hairPaint = Paint()..color = const Color(0xFF261D1A);
    final hairPath = Path()
      ..moveTo(w * 0.14, h * 0.42)
      ..quadraticBezierTo(w * 0.14, h * 0.10, w * 0.50, h * 0.10)
      ..quadraticBezierTo(w * 0.86, h * 0.10, w * 0.86, h * 0.42)
      ..quadraticBezierTo(w * 0.70, h * 0.20, w * 0.50, h * 0.22)
      ..quadraticBezierTo(w * 0.30, h * 0.20, w * 0.14, h * 0.42)
      ..close();
    canvas.drawPath(hairPath, hairPaint);

    // Chouchou / queue de cheval haute
    canvas.drawCircle(Offset(w * 0.84, h * 0.18), 7, Paint()..color = const Color(0xFFFFC83D));
    canvas.drawCircle(Offset(w * 0.89, h * 0.23), 10, hairPaint);

    // 4. Yeux expressifs
    final eyePaint = Paint()..color = const Color(0xFF1E1715);
    canvas.drawCircle(Offset(w * 0.38, h * 0.34), 3.2, eyePaint);
    canvas.drawCircle(Offset(w * 0.62, h * 0.34), 3.2, eyePaint);

    // Cils fins
    final lashPaint = Paint()
      ..color = const Color(0xFF1E1715)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.34, h * 0.31), Offset(w * 0.38, h * 0.32), lashPaint);
    canvas.drawLine(Offset(w * 0.66, h * 0.31), Offset(w * 0.62, h * 0.32), lashPaint);

    // Reflet blanc
    canvas.drawCircle(Offset(w * 0.37, h * 0.33), 1.2, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(w * 0.61, h * 0.33), 1.2, Paint()..color = Colors.white);

    // Pommettes
    canvas.drawCircle(Offset(w * 0.28, h * 0.40), 5.5, Paint()..color = const Color(0xFFFF7285).withValues(alpha: 0.4));
    canvas.drawCircle(Offset(w * 0.72, h * 0.40), 5.5, Paint()..color = const Color(0xFFFF7285).withValues(alpha: 0.4));

    // 5. Bouche animée
    _paintMouth(canvas, Offset(w * 0.5, h * 0.45), w * 0.22);
  }

  // ── Personnage 3 : Max (style Junior avec casquette rouge) ───────────
  void _paintMax(Canvas canvas, double w, double h) {
    // 1. T-shirt rouge Duolingo
    final shirtPaint = Paint()..color = const Color(0xFFFF4B4B);
    final shirtPath = Path()
      ..moveTo(w * 0.15, h)
      ..lineTo(w * 0.20, h * 0.66)
      ..quadraticBezierTo(w * 0.5, h * 0.60, w * 0.80, h * 0.66)
      ..lineTo(w * 0.85, h)
      ..close();
    canvas.drawPath(shirtPath, shirtPaint);

    // 2. Visage jeune
    final skinPaint = Paint()..color = const Color(0xFFFFE0BD);
    final faceRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.42),
      width: w * 0.60,
      height: h * 0.40,
    );
    canvas.drawOval(faceRect, skinPaint);

    // 3. Casquette bleue avec visière
    final capPaint = Paint()..color = const Color(0xFF1CB0F6);
    final capPath = Path()
      ..moveTo(w * 0.18, h * 0.30)
      ..quadraticBezierTo(w * 0.18, h * 0.14, w * 0.50, h * 0.14)
      ..quadraticBezierTo(w * 0.82, h * 0.14, w * 0.82, h * 0.30)
      ..close();
    canvas.drawPath(capPath, capPaint);

    // Visière de la casquette
    final visorPaint = Paint()..color = const Color(0xFF0095DE);
    final visorPath = Path()
      ..moveTo(w * 0.16, h * 0.30)
      ..lineTo(w * 0.88, h * 0.27)
      ..lineTo(w * 0.84, h * 0.33)
      ..lineTo(w * 0.18, h * 0.33)
      ..close();
    canvas.drawPath(visorPath, visorPaint);

    // 4. Yeux pétillants
    final eyePaint = Paint()..color = const Color(0xFF1F2937);
    canvas.drawCircle(Offset(w * 0.40, h * 0.38), 3.5, eyePaint);
    canvas.drawCircle(Offset(w * 0.64, h * 0.38), 3.5, eyePaint);
    canvas.drawCircle(Offset(w * 0.39, h * 0.37), 1.2, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(w * 0.63, h * 0.37), 1.2, Paint()..color = Colors.white);

    // Taches de rousseur
    final frecklePaint = Paint()..color = const Color(0xFFC47D4C);
    canvas.drawCircle(Offset(w * 0.33, h * 0.42), 1.0, frecklePaint);
    canvas.drawCircle(Offset(w * 0.36, h * 0.44), 1.0, frecklePaint);
    canvas.drawCircle(Offset(w * 0.64, h * 0.44), 1.0, frecklePaint);
    canvas.drawCircle(Offset(w * 0.67, h * 0.42), 1.0, frecklePaint);

    // 5. Bouche animée
    _paintMouth(canvas, Offset(w * 0.52, h * 0.48), w * 0.20);
  }

  // ── Personnage 4 : Falstaff (L'ours brun emblématique de Duolingo) ───
  void _paintBear(Canvas canvas, double w, double h) {
    const furColor = Color(0xFF8B5A3C);
    const darkFurColor = Color(0xFF6E4028);
    const muzzleColor = Color(0xFFD6A078);
    const scarfColor = Color(0xFF2CD5C4);

    // 1. Oreilles rondes d'ours
    final earPaint = Paint()..color = furColor;
    final innerEarPaint = Paint()..color = muzzleColor;

    // Oreille gauche
    canvas.drawCircle(Offset(w * 0.28, h * 0.20), w * 0.13, earPaint);
    canvas.drawCircle(Offset(w * 0.28, h * 0.20), w * 0.07, innerEarPaint);

    // Oreille droite
    canvas.drawCircle(Offset(w * 0.72, h * 0.20), w * 0.13, earPaint);
    canvas.drawCircle(Offset(w * 0.72, h * 0.20), w * 0.07, innerEarPaint);

    // 2. Corps / Silhouette de l'ours
    final bodyPaint = Paint()..color = furColor;
    final bodyPath = Path()
      ..moveTo(w * 0.10, h)
      ..lineTo(w * 0.15, h * 0.65)
      ..quadraticBezierTo(w * 0.50, h * 0.52, w * 0.85, h * 0.65)
      ..lineTo(w * 0.90, h)
      ..close();
    canvas.drawPath(bodyPath, bodyPaint);

    // 3. Tête ronde et massive
    final headRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.40),
      width: w * 0.68,
      height: h * 0.44,
    );
    canvas.drawOval(headRect, bodyPaint);

    // 4. Écharpe turquoise Duolingo autour du cou
    final scarfPaint = Paint()..color = scarfColor;
    final scarfPath = Path()
      ..moveTo(w * 0.20, h * 0.57)
      ..quadraticBezierTo(w * 0.50, h * 0.65, w * 0.80, h * 0.57)
      ..lineTo(w * 0.83, h * 0.68)
      ..quadraticBezierTo(w * 0.50, h * 0.76, w * 0.17, h * 0.68)
      ..close();
    canvas.drawPath(scarfPath, scarfPaint);

    // Bout de l'écharpe qui pend
    final scarfEndPath = Path()
      ..moveTo(w * 0.30, h * 0.65)
      ..lineTo(w * 0.24, h * 0.82)
      ..lineTo(w * 0.38, h * 0.80)
      ..lineTo(w * 0.38, h * 0.65)
      ..close();
    canvas.drawPath(scarfEndPath, scarfPaint);

    // 5. Bras croisés sur le ventre
    final armPaint = Paint()
      ..color = darkFurColor
      ..strokeWidth = 3.2
      ..style = PaintingStyle.stroke;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.80), width: w * 0.58, height: h * 0.20),
      0.2,
      2.74,
      false,
      armPaint,
    );

    // 6. Museau ovale beige / chamois
    final muzzleRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.46),
      width: w * 0.44,
      height: h * 0.23,
    );
    canvas.drawOval(muzzleRect, Paint()..color = muzzleColor);

    // Truffe (nez) noire arrondie
    final nosePath = Path()
      ..moveTo(w * 0.43, h * 0.40)
      ..quadraticBezierTo(w * 0.50, h * 0.38, w * 0.57, h * 0.40)
      ..quadraticBezierTo(w * 0.50, h * 0.46, w * 0.43, h * 0.40)
      ..close();
    canvas.drawPath(nosePath, Paint()..color = const Color(0xFF261810));

    // 7. Yeux expressifs d'ours
    final eyePaint = Paint()..color = const Color(0xFF261810);
    canvas.drawCircle(Offset(w * 0.37, h * 0.33), 3.2, eyePaint);
    canvas.drawCircle(Offset(w * 0.63, h * 0.33), 3.2, eyePaint);

    // Éclat blanc
    final shinePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(w * 0.39, h * 0.32), 1.2, shinePaint);
    canvas.drawCircle(Offset(w * 0.65, h * 0.32), 1.2, shinePaint);

    // 8. Bouche animée (parle en synchro)
    _paintMouth(canvas, Offset(w * 0.5, h * 0.51), w * 0.22);
  }

  // ── Bouche animée avec synchronisation labiale ──────────────────────
  void _paintMouth(Canvas canvas, Offset center, double width) {
    if (mouthOpen > 0.15) {
      // Bouche ouverte qui parle
      final openHeight = 3.0 + (mouthOpen * 9.0);
      final mouthRect = Rect.fromCenter(
        center: center,
        width: width * (0.8 + mouthOpen * 0.4),
        height: openHeight,
      );

      // Cavité buccale sombre
      final insidePaint = Paint()..color = const Color(0xFF6B1D2F);
      canvas.drawRRect(
        RRect.fromRectAndRadius(mouthRect, Radius.circular(openHeight / 2)),
        insidePaint,
      );

      // Langue rose
      if (openHeight > 6) {
        final tonguePaint = Paint()..color = const Color(0xFFFF6B81);
        canvas.drawCircle(Offset(center.dx, center.dy + openHeight * 0.22), openHeight * 0.35, tonguePaint);
      }

      // Dents du haut blanches
      if (openHeight > 5) {
        final teethPaint = Paint()..color = Colors.white;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(center.dx - width * 0.3, center.dy - openHeight * 0.48, width * 0.6, openHeight * 0.35),
            const Radius.circular(2),
          ),
          teethPaint,
        );
      }
    } else {
      // Sourire calme / fermé
      final smilePaint = Paint()
        ..color = const Color(0xFF6B1D2F)
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final smilePath = Path()
        ..moveTo(center.dx - width * 0.45, center.dy - 1.5)
        ..quadraticBezierTo(center.dx, center.dy + 4.5, center.dx + width * 0.45, center.dy - 1.5);
      canvas.drawPath(smilePath, smilePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DuolingoCharacterPainter oldDelegate) =>
      oldDelegate.mouthOpen != mouthOpen ||
      oldDelegate.character != character ||
      oldDelegate.isDark != isDark;
}
