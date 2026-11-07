import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Overlay de confettis festifs style Duolingo pour les fins de séance ou séries.
class DuoConfettiOverlay extends StatefulWidget {
  final Widget child;
  final bool isPlaying;
  final VoidCallback? onFinished;

  /// Permet de désactiver globalement l'animation pour les tests
  static bool enableAnimations = true;

  const DuoConfettiOverlay({
    super.key,
    required this.child,
    this.isPlaying = false,
    this.onFinished,
  });

  @override
  State<DuoConfettiOverlay> createState() => _DuoConfettiOverlayState();
}

class _DuoConfettiOverlayState extends State<DuoConfettiOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_ConfettiParticle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onFinished?.call();
      }
    });

    if (widget.isPlaying && DuoConfettiOverlay.enableAnimations) {
      _startConfetti();
    }
  }

  @override
  void didUpdateWidget(covariant DuoConfettiOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !oldWidget.isPlaying && DuoConfettiOverlay.enableAnimations) {
      _startConfetti();
    }
  }

  void _startConfetti() {
    _particles.clear();
    const colors = [
      Color(0xFF58CC02), // Vert Duo
      Color(0xFF1CB0F6), // Bleu Duo
      Color(0xFFFFC800), // Jaune Duo
      Color(0xFFFF4B4B), // Rouge Duo
      Color(0xFFCE82FF), // Violet Duo
      Color(0xFFFF9600), // Orange Duo
    ];

    for (int i = 0; i < 65; i++) {
      _particles.add(
        _ConfettiParticle(
          x: _random.nextDouble(),
          startY: -0.1 - _random.nextDouble() * 0.3,
          speed: 0.6 + _random.nextDouble() * 0.7,
          size: 7 + _random.nextDouble() * 7,
          color: colors[_random.nextInt(colors.length)],
          rotationSpeed: (_random.nextDouble() - 0.5) * 8,
          wobbleSpeed: 2 + _random.nextDouble() * 4,
          shape: _random.nextBool() ? _ParticleShape.rectangle : _ParticleShape.circle,
        ),
      );
    }

    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.isPlaying)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _ConfettiPainter(
                      progress: _controller.value,
                      particles: _particles,
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

enum _ParticleShape { rectangle, circle }

class _ConfettiParticle {
  final double x;
  final double startY;
  final double speed;
  final double size;
  final Color color;
  final double rotationSpeed;
  final double wobbleSpeed;
  final _ParticleShape shape;

  _ConfettiParticle({
    required this.x,
    required this.startY,
    required this.speed,
    required this.size,
    required this.color,
    required this.rotationSpeed,
    required this.wobbleSpeed,
    required this.shape,
  });
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final List<_ConfettiParticle> particles;

  _ConfettiPainter({required this.progress, required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final opacity = (1.0 - progress * 0.8).clamp(0.0, 1.0);

    for (final p in particles) {
      final currentY = (p.startY + progress * p.speed * 1.5) * size.height;
      final wobble = math.sin(progress * math.pi * p.wobbleSpeed) * 20;
      final currentX = p.x * size.width + wobble;

      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(currentX, currentY);
      canvas.rotate(progress * p.rotationSpeed * math.pi);

      if (p.shape == _ParticleShape.circle) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
            const Radius.circular(2),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
