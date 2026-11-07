import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../theme/app_colors.dart';

enum MascotMood {
  idle,
  happy,
  sad,
  celebrating,
  thinking,
  angry,
  sleepy,
  proud,
  confused,
}

/// Résultat intermédiaire des calculs physiques d'animation
class _PhysicsResult {
  double y = 0.0;
  double scaleX = 1.0;
  double scaleY = 1.0;
  double rotation = 0.0;
  double shadowScale = 1.0;
}

/// Mascotte animée interactive style Duolingo (l'écureuil expressif).
/// Supporte les illustrations officielles de l'écureuil (assets/images/squirrel_*.png)
/// avec micro-animations physiques (sauts dynamiques, écrasement squash & stretch,
/// halo lumineux, ombres au sol réactives, étoiles scintillantes de fête et réaction au tap),
/// ou une mascotte vectorielle interactive de secours.
class MascotWidget extends StatefulWidget {
  final MascotMood mood;
  final double size;
  final String? lottieAsset;
  final bool animate;
  final bool showAura;
  final bool showShadow;
  final VoidCallback? onTap;

  /// Permet d'activer ou désactiver globalement les animations continues (ex. lors des tests de widgets)
  static bool enableAnimations = true;

  const MascotWidget({
    super.key,
    this.mood = MascotMood.idle,
    this.size = 120,
    this.lottieAsset,
    this.animate = true,
    this.showAura = true,
    this.showShadow = true,
    this.onTap,
  });

  @override
  State<MascotWidget> createState() => _MascotWidgetState();
}

class _MascotWidgetState extends State<MascotWidget> with TickerProviderStateMixin {
  late AnimationController _motionController;
  late AnimationController _tapController;
  late AnimationController _blinkController;
  final _PhysicsResult _physics = _PhysicsResult();

  @override
  void initState() {
    super.initState();
    _motionController = AnimationController(
      vsync: this,
      duration: _getDurationForMood(widget.mood),
    );

    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    if (widget.animate && MascotWidget.enableAnimations) {
      _motionController.repeat();
      _blinkController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant MascotWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mood != widget.mood) {
      _motionController.duration = _getDurationForMood(widget.mood);
      if (widget.animate && MascotWidget.enableAnimations && !_motionController.isAnimating) {
        _motionController.repeat();
      }
    }
    if (oldWidget.animate != widget.animate) {
      if (widget.animate && MascotWidget.enableAnimations) {
        if (!_motionController.isAnimating) _motionController.repeat();
        if (!_blinkController.isAnimating) _blinkController.repeat();
      } else {
        _motionController.stop();
        _blinkController.stop();
      }
    }
  }

  @override
  void dispose() {
    _motionController.dispose();
    _tapController.dispose();
    _blinkController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.animate && MascotWidget.enableAnimations) {
      _tapController.forward(from: 0.0);
    }
    widget.onTap?.call();
  }

  static Duration _getDurationForMood(MascotMood mood) {
    switch (mood) {
      case MascotMood.celebrating:
        return const Duration(milliseconds: 1200);
      case MascotMood.happy:
        return const Duration(milliseconds: 950);
      case MascotMood.angry:
        return const Duration(milliseconds: 400);
      case MascotMood.sad:
        return const Duration(milliseconds: 2000);
      case MascotMood.thinking:
        return const Duration(milliseconds: 1800);
      case MascotMood.sleepy:
        return const Duration(milliseconds: 2400);
      case MascotMood.proud:
        return const Duration(milliseconds: 1400);
      case MascotMood.confused:
        return const Duration(milliseconds: 1200);
      case MascotMood.idle:
        return const Duration(milliseconds: 2200);
    }
  }

  static String _getAssetForMood(MascotMood mood) {
    switch (mood) {
      case MascotMood.happy:
        return 'assets/images/squirrel_happy.png';
      case MascotMood.angry:
        return 'assets/images/squirrel_angry.png';
      case MascotMood.sad:
        return 'assets/images/squirrel_sad.png';
      case MascotMood.celebrating:
        return 'assets/images/squirrel_party.png';
      case MascotMood.thinking:
        return 'assets/images/squirrel_thinking.png';
      case MascotMood.sleepy:
        return 'assets/images/squirrel_sleepy.png';
      case MascotMood.proud:
        return 'assets/images/squirrel_proud.png';
      case MascotMood.confused:
        return 'assets/images/squirrel_confused.png';
      case MascotMood.idle:
        return 'assets/images/squirrel_idle.png';
    }
  }

  static Color _getAuraColor(MascotMood mood) {
    switch (mood) {
      case MascotMood.celebrating:
        return const Color(0xFFF59E0B); // Amber / Or
      case MascotMood.happy:
        return const Color(0xFF10B981); // Émeraude vif
      case MascotMood.proud:
        return const Color(0xFF3B82F6); // Bleu éclatant
      case MascotMood.thinking:
        return const Color(0xFF8B5CF6); // Violet curieux
      case MascotMood.angry:
        return const Color(0xFFEF4444); // Rouge énergie
      case MascotMood.sad:
        return const Color(0xFF64748B); // Gris ardoise
      case MascotMood.sleepy:
        return const Color(0xFF6366F1); // Indigo calme
      case MascotMood.confused:
        return const Color(0xFFEC4899); // Rose étonné
      case MascotMood.idle:
        return const Color(0xFF06B6D4); // Cyan serein
    }
  }

  void _calculateMoodPhysics({
    required MascotMood mood,
    required double t,
    required double tapT,
    required double baseSize,
    required _PhysicsResult out,
  }) {
    double y = 0.0;
    double scaleX = 1.0;
    double scaleY = 1.0;
    double rot = 0.0;
    double shadowScale = 1.0;

    switch (mood) {
      case MascotMood.celebrating:
        // Cycle de saut de fête en 4 phases rythmées (squash & stretch)
        final maxHop = baseSize * 0.16;
        if (t < 0.42) {
          // 1. Propulsion et élévation avec rotation festive
          final p = Curves.easeOutCubic.transform(t / 0.42);
          y = -maxHop * p;
          rot = 0.06 * math.sin(p * math.pi);
          scaleX = 0.95;
          scaleY = 1.05;
          shadowScale = 1.0 - 0.45 * p;
        } else if (t < 0.68) {
          // 2. Descente rapide vers le sol
          final p = Curves.easeInQuad.transform((t - 0.42) / 0.26);
          y = -maxHop * (1.0 - p);
          rot = -0.04 * math.sin(p * math.pi);
          scaleX = 0.97;
          scaleY = 1.03;
          shadowScale = 0.55 + 0.45 * p;
        } else if (t < 0.85) {
          // 3. Écrasement élastique (squash) sur réception au sol
          final p = (t - 0.68) / 0.17;
          final squash = math.sin(p * math.pi);
          y = 0.0;
          rot = 0.0;
          scaleX = 1.0 + 0.10 * squash;
          scaleY = 1.0 - 0.10 * squash;
          shadowScale = 1.0 + 0.18 * squash;
        } else {
          // 4. Stabilisation avant le prochain saut
          y = 0.0;
          rot = 0.0;
          scaleX = 1.0;
          scaleY = 1.0;
          shadowScale = 1.0;
        }
        break;

      case MascotMood.happy:
        final hop = baseSize * 0.10;
        final p = math.sin(t * math.pi);
        y = -hop * p;
        rot = 0.03 * math.sin(t * 2 * math.pi);
        scaleX = 1.0 + (p < 0.2 ? 0.05 : -0.03 * p);
        scaleY = 1.0 + (p < 0.2 ? -0.05 : 0.03 * p);
        shadowScale = 1.0 - 0.3 * p;
        break;

      case MascotMood.thinking:
        rot = 0.07 * math.sin(t * 2 * math.pi);
        y = -baseSize * 0.03 * math.sin(t * 2 * math.pi);
        scaleX = 1.0;
        scaleY = 1.0;
        shadowScale = 1.0;
        break;

      case MascotMood.angry:
        rot = 0.06 * math.sin(t * 6 * math.pi);
        scaleX = 1.04;
        scaleY = 1.04;
        shadowScale = 1.0;
        break;

      case MascotMood.sleepy:
        final breath = math.sin(t * 2 * math.pi);
        y = baseSize * 0.02 * breath;
        scaleX = 1.0 + 0.03 * breath;
        scaleY = 1.0 - 0.02 * breath;
        shadowScale = 1.0;
        break;

      case MascotMood.proud:
        final p = math.sin(t * 2 * math.pi);
        scaleX = 1.05 + 0.02 * p;
        scaleY = 1.05 + 0.02 * p;
        y = -baseSize * 0.05 * p.abs();
        rot = 0.03 * p;
        shadowScale = 1.0;
        break;

      case MascotMood.sad:
        final p = math.sin(t * 2 * math.pi);
        y = baseSize * 0.03 * (p > 0 ? p : 0);
        scaleX = 0.96;
        scaleY = 0.96;
        shadowScale = 1.0;
        break;

      case MascotMood.confused:
        rot = 0.08 * math.sin(t * 2 * math.pi);
        y = -baseSize * 0.02 * math.sin(t * 4 * math.pi).abs();
        shadowScale = 1.0;
        break;

      case MascotMood.idle:
        final hover = math.sin(t * 2 * math.pi);
        y = -baseSize * 0.04 * hover;
        scaleX = 1.0 + 0.02 * hover;
        scaleY = 1.0 - 0.02 * hover;
        shadowScale = 1.0 - 0.15 * hover;
        break;
    }

    // Réaction tactile immédiate (super saut au tap)
    if (tapT > 0.0 && tapT < 1.0) {
      final tapJump = -baseSize * 0.22 * math.sin(tapT * math.pi);
      y += tapJump;
      scaleX *= (1.0 + 0.07 * math.sin(tapT * 2 * math.pi));
      scaleY *= (1.0 - 0.07 * math.sin(tapT * 2 * math.pi));
      shadowScale = (shadowScale - 0.45 * math.sin(tapT * math.pi)).clamp(0.2, 1.2);
    }

    out.y = y;
    out.scaleX = scaleX;
    out.scaleY = scaleY;
    out.rotation = rot;
    out.shadowScale = shadowScale;
  }

  Widget _buildSparkle({
    double? left,
    double? top,
    double? right,
    double? bottom,
    required double scale,
    required Color color,
    required double size,
  }) {
    return Positioned(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      child: Transform.scale(
        scale: scale.clamp(0.1, 1.2),
        child: Icon(
          Icons.auto_awesome,
          size: size,
          color: color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.lottieAsset != null && widget.lottieAsset!.isNotEmpty) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: Lottie.asset(
          widget.lottieAsset!,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => _buildVectorMascot(),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final assetPath = _getAssetForMood(widget.mood);
    final shouldAnimate = widget.animate && MascotWidget.enableAnimations;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: Listenable.merge([_motionController, _tapController, _blinkController]),
          builder: (context, child) {
            final t = shouldAnimate ? _motionController.value : 0.0;
            final tapT = shouldAnimate ? _tapController.value : 0.0;

            _calculateMoodPhysics(
              mood: widget.mood,
              t: t,
              tapT: tapT,
              baseSize: widget.size,
              out: _physics,
            );

            final auraColor = _getAuraColor(widget.mood);
            final auraPulse = shouldAnimate ? (0.8 + 0.2 * math.sin(t * 2 * math.pi)) : 1.0;

            return SizedBox(
              width: widget.size,
              height: widget.size,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // 1. Halo d'aura d'ambiance doux (lumière radiale)
                  if (widget.showAura)
                    Positioned.fill(
                      child: Center(
                        child: Container(
                          width: widget.size * 0.92,
                          height: widget.size * 0.92,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                auraColor.withValues(alpha: (isDark ? 0.28 : 0.18) * auraPulse),
                                auraColor.withValues(alpha: (isDark ? 0.08 : 0.05) * auraPulse),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.65, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),

                  // 2. Ombre de contact au sol dynamique (s'adapte à la hauteur du saut)
                  if (widget.showShadow)
                    Positioned(
                      bottom: widget.size * 0.04,
                      child: Container(
                        width: (widget.size * 0.54 * _physics.shadowScale).clamp(4.0, widget.size),
                        height: (widget.size * 0.11 * _physics.shadowScale).clamp(2.0, widget.size * 0.3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (isDark ? Colors.black : const Color(0xFF0F172A))
                                  .withValues(alpha: (0.30 * _physics.shadowScale).clamp(0.06, 0.38)),
                              blurRadius: (6 * _physics.shadowScale).clamp(1.0, 15.0),
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),

                  // 3. Mascotte vivante avec physique de saut, inclinaison et squash & stretch
                  Positioned(
                    bottom: widget.size * 0.07,
                    child: Transform.translate(
                      offset: Offset(0.0, _physics.y),
                      child: Transform.rotate(
                        angle: _physics.rotation,
                        alignment: Alignment.bottomCenter,
                        child: Transform.scale(
                          scaleX: _physics.scaleX,
                          scaleY: _physics.scaleY,
                          alignment: Alignment.bottomCenter,
                          child: Image.asset(
                            assetPath,
                            width: widget.size * 0.88,
                            height: widget.size * 0.88,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                            errorBuilder: (context, error, stackTrace) => _buildVectorMascot(),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 4. Étoiles et confettis étincelants pour célébrer le lot complété
                  if (widget.mood == MascotMood.celebrating && shouldAnimate) ...[
                    _buildSparkle(
                      left: widget.size * 0.04,
                      top: widget.size * 0.06,
                      scale: (0.4 + 0.6 * math.sin(t * 2 * math.pi)).abs(),
                      color: const Color(0xFFFFD700), // Or brillant
                      size: widget.size * 0.20,
                    ),
                    _buildSparkle(
                      right: widget.size * 0.02,
                      top: widget.size * 0.10,
                      scale: (0.5 + 0.5 * math.cos(t * 2 * math.pi + 1.2)).abs(),
                      color: const Color(0xFF10B981), // Émeraude vivace
                      size: widget.size * 0.18,
                    ),
                    _buildSparkle(
                      right: widget.size * 0.08,
                      bottom: widget.size * 0.24,
                      scale: (0.3 + 0.7 * math.sin(t * 2 * math.pi + 2.5)).abs(),
                      color: const Color(0xFFF43F5E), // Rose festif
                      size: widget.size * 0.15,
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildVectorMascot() {
    Widget mascot = AnimatedBuilder(
      animation: _blinkController,
      builder: (context, child) {
        final cycle = _blinkController.value;
        final isBlinking = cycle > 0.92 && cycle < 0.98;

        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _MascotPainter(
            mood: widget.mood,
            isBlinking: isBlinking,
          ),
        );
      },
    );

    return mascot;
  }
}

class _MascotPainter extends CustomPainter {
  final MascotMood mood;
  final bool isBlinking;

  _MascotPainter({
    required this.mood,
    required this.isBlinking,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    // 1. Ombre douce au sol
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx, h * 0.93), width: w * 0.65, height: h * 0.12),
      shadowPaint,
    );

    // 2. Pieds orange style Duolingo
    final footPaint = Paint()
      ..color = const Color(0xFFFF9600)
      ..style = PaintingStyle.fill;
    final footShadowPaint = Paint()
      ..color = const Color(0xFFD67E00)
      ..style = PaintingStyle.fill;

    // Pied gauche
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.32, h * 0.84, w * 0.15, h * 0.10),
        const Radius.circular(8),
      ),
      footShadowPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.32, h * 0.83, w * 0.15, h * 0.09),
        const Radius.circular(8),
      ),
      footPaint,
    );

    // Pied droit
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.53, h * 0.84, w * 0.15, h * 0.10),
        const Radius.circular(8),
      ),
      footShadowPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.53, h * 0.83, w * 0.15, h * 0.09),
        const Radius.circular(8),
      ),
      footPaint,
    );

    // 3. Corps principal (Vert vif Duolingo)
    final bodyPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    final bodyShadowPaint = Paint()
      ..color = AppColors.primaryDark
      ..style = PaintingStyle.fill;

    // Ombre du corps (couche 3D)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx, center.dy + 4), width: w * 0.72, height: h * 0.76),
        Radius.circular(w * 0.36),
      ),
      bodyShadowPaint,
    );

    // Face avant du corps
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx, center.dy), width: w * 0.72, height: h * 0.76),
        Radius.circular(w * 0.36),
      ),
      bodyPaint,
    );

    // 4. Ventre plus clair
    final bellyPaint = Paint()
      ..color = const Color(0xFF67E28E)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx, center.dy + h * 0.18), width: w * 0.44, height: h * 0.32),
      bellyPaint,
    );

    // 5. Yeux caractéristiques grands et expressifs
    final eyeWhitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final eyePupilPaint = Paint()
      ..color = const Color(0xFF1F2937)
      ..style = PaintingStyle.fill;

    final eyeGlintPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final eyeRadius = w * 0.14;
    final leftEyeCenter = Offset(w * 0.38, h * 0.40);
    final rightEyeCenter = Offset(w * 0.62, h * 0.40);

    if (isBlinking) {
      // Oeil fermé (ligne arquée)
      final blinkPaint = Paint()
        ..color = const Color(0xFF1F2937)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(leftEyeCenter.dx - eyeRadius * 0.7, leftEyeCenter.dy),
        Offset(leftEyeCenter.dx + eyeRadius * 0.7, leftEyeCenter.dy),
        blinkPaint,
      );
      canvas.drawLine(
        Offset(rightEyeCenter.dx - eyeRadius * 0.7, rightEyeCenter.dy),
        Offset(rightEyeCenter.dx + eyeRadius * 0.7, rightEyeCenter.dy),
        blinkPaint,
      );
    } else if (mood == MascotMood.happy || mood == MascotMood.celebrating) {
      // Yeux plissés de joie (^ ^)
      final happyEyePaint = Paint()
        ..color = const Color(0xFF1F2937)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0
        ..strokeCap = StrokeCap.round;

      final pathLeft = Path()
        ..moveTo(leftEyeCenter.dx - eyeRadius * 0.8, leftEyeCenter.dy + 3)
        ..quadraticBezierTo(leftEyeCenter.dx, leftEyeCenter.dy - eyeRadius * 0.9, leftEyeCenter.dx + eyeRadius * 0.8, leftEyeCenter.dy + 3);

      final pathRight = Path()
        ..moveTo(rightEyeCenter.dx - eyeRadius * 0.8, rightEyeCenter.dy + 3)
        ..quadraticBezierTo(rightEyeCenter.dx, rightEyeCenter.dy - eyeRadius * 0.9, rightEyeCenter.dx + eyeRadius * 0.8, rightEyeCenter.dy + 3);

      canvas.drawPath(pathLeft, happyEyePaint);
      canvas.drawPath(pathRight, happyEyePaint);

      // Petites joues roses
      final blushPaint = Paint()
        ..color = const Color(0xFFFF85A1).withValues(alpha: 0.6)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(leftEyeCenter.dx - 10, leftEyeCenter.dy + 14), 7, blushPaint);
      canvas.drawCircle(Offset(rightEyeCenter.dx + 10, rightEyeCenter.dy + 14), 7, blushPaint);
    } else {
      // Yeux grands ouverts
      // Fond blanc des yeux
      canvas.drawCircle(leftEyeCenter, eyeRadius, eyeWhitePaint);
      canvas.drawCircle(rightEyeCenter, eyeRadius, eyeWhitePaint);

      // Pupilles
      final pupilRadius = eyeRadius * 0.52;
      double pupilOffsetY = 0;
      double pupilOffsetX = 0;
      if (mood == MascotMood.thinking) {
        pupilOffsetY = -4;
        pupilOffsetX = 3;
      } else if (mood == MascotMood.sad) {
        pupilOffsetY = 2;
      }

      final leftPupilCenter = Offset(leftEyeCenter.dx + pupilOffsetX, leftEyeCenter.dy + pupilOffsetY);
      final rightPupilCenter = Offset(rightEyeCenter.dx + pupilOffsetX, rightEyeCenter.dy + pupilOffsetY);

      canvas.drawCircle(leftPupilCenter, pupilRadius, eyePupilPaint);
      canvas.drawCircle(rightPupilCenter, pupilRadius, eyePupilPaint);

      // Reflets brillants dans les yeux
      canvas.drawCircle(
        Offset(leftPupilCenter.dx - pupilRadius * 0.35, leftPupilCenter.dy - pupilRadius * 0.35),
        pupilRadius * 0.32,
        eyeGlintPaint,
      );
      canvas.drawCircle(
        Offset(rightPupilCenter.dx - pupilRadius * 0.35, rightPupilCenter.dy - pupilRadius * 0.35),
        pupilRadius * 0.32,
        eyeGlintPaint,
      );
    }

    // 6. Bec orange
    final beakPaint = Paint()
      ..color = const Color(0xFFFF9600)
      ..style = PaintingStyle.fill;

    final beakPath = Path()
      ..moveTo(center.dx - w * 0.08, h * 0.46)
      ..lineTo(center.dx + w * 0.08, h * 0.46)
      ..lineTo(center.dx, h * 0.57)
      ..close();

    canvas.drawPath(beakPath, beakPaint);

    // 7. Ailes sur les côtés
    final wingPaint = Paint()
      ..color = AppColors.primaryDark
      ..style = PaintingStyle.fill;

    // Aile gauche
    final leftWingPath = Path()
      ..moveTo(w * 0.16, h * 0.48)
      ..quadraticBezierTo(w * 0.08, h * 0.62, w * 0.22, h * 0.72)
      ..quadraticBezierTo(w * 0.22, h * 0.58, w * 0.16, h * 0.48);
    canvas.drawPath(leftWingPath, wingPaint);

    // Aile droite
    final rightWingPath = Path()
      ..moveTo(w * 0.84, h * 0.48)
      ..quadraticBezierTo(w * 0.92, h * 0.62, w * 0.78, h * 0.72)
      ..quadraticBezierTo(w * 0.78, h * 0.58, w * 0.84, h * 0.48);
    canvas.drawPath(rightWingPath, wingPaint);
  }

  @override
  bool shouldRepaint(covariant _MascotPainter oldDelegate) {
    return oldDelegate.mood != mood || oldDelegate.isBlinking != isBlinking;
  }
}
