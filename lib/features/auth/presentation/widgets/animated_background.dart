import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Fond animé avec particules flottantes et effets de lumière
class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({super.key});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with TickerProviderStateMixin {
  late List<ParticleModel> _particles;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _particles = List.generate(30, (index) => ParticleModel.random());

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.backgroundGradient,
      ),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          // Mettre à jour les particules
          for (final particle in _particles) {
            particle.update();
          }

          return CustomPaint(
            painter: ParticlesPainter(particles: _particles),
            child: child,
          );
        },
        child: Stack(
          children: [
            // Effet de lumière en haut à gauche
            Positioned(
              top: -200,
              left: -200,
              child: Container(
                width: 600,
                height: 600,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Effet de lumière en bas à droite
            Positioned(
              bottom: -300,
              right: -200,
              child: Container(
                width: 800,
                height: 800,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accent.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Overlay de bruit/texture
            Positioned.fill(
              child: CustomPaint(
                painter: NoisePainter(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Modèle de particule
class ParticleModel {
  ParticleModel({
    required this.x,
    required this.y,
    required this.size,
    required this.speedX,
    required this.speedY,
    required this.opacity,
    required this.color,
  });

  factory ParticleModel.random() {
    final random = math.Random();
    final isBlue = random.nextBool();
    return ParticleModel(
      x: random.nextDouble(),
      y: random.nextDouble(),
      size: random.nextDouble() * 3 + 1,
      speedX: (random.nextDouble() - 0.5) * 0.001,
      speedY: (random.nextDouble() - 0.5) * 0.001,
      opacity: random.nextDouble() * 0.5 + 0.1,
      color: isBlue ? AppColors.primary : AppColors.accent,
    );
  }
  double x;
  double y;
  double size;
  double speedX;
  double speedY;
  double opacity;
  Color color;

  void update() {
    x += speedX;
    y += speedY;

    // Rebondir sur les bords
    if (x < 0 || x > 1) {
      speedX *= -1;
      x = x.clamp(0, 1);
    }
    if (y < 0 || y > 1) {
      speedY *= -1;
      y = y.clamp(0, 1);
    }
  }
}

/// Peintre de particules
class ParticlesPainter extends CustomPainter {
  ParticlesPainter({required this.particles});
  final List<ParticleModel> particles;

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final paint = Paint()
        ..color = particle.color.withValues(alpha: particle.opacity)
        ..style = PaintingStyle.fill;

      // Dessiner la particule avec un effet de flou
      final center = Offset(
        particle.x * size.width,
        particle.y * size.height,
      );

      // Halo extérieur
      final haloPaint = Paint()
        ..color = particle.color.withValues(alpha: particle.opacity * 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawCircle(center, particle.size * 3, haloPaint);

      // Point central
      canvas.drawCircle(center, particle.size, paint);
    }

    // Dessiner des connexions entre particules proches
    final linePaint = Paint()
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < particles.length; i++) {
      for (var j = i + 1; j < particles.length; j++) {
        final p1 = particles[i];
        final p2 = particles[j];

        final dx = (p1.x - p2.x) * size.width;
        final dy = (p1.y - p2.y) * size.height;
        final distance = math.sqrt(dx * dx + dy * dy);

        if (distance < 150) {
          final opacity = (1 - distance / 150) * 0.15;
          linePaint.color = AppColors.primary.withValues(alpha: opacity);

          canvas.drawLine(
            Offset(p1.x * size.width, p1.y * size.height),
            Offset(p2.x * size.width, p2.y * size.height),
            linePaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant ParticlesPainter oldDelegate) => true;
}

/// Peintre de texture/bruit
class NoisePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42); // Seed fixe pour consistance

    final paint = Paint()..style = PaintingStyle.fill;

    // Créer un effet de grain subtil
    for (var i = 0; i < 2000; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final opacity = random.nextDouble() * 0.03;

      paint.color = Colors.white.withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), 0.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Widget de vague animée
class AnimatedWave extends StatefulWidget {
  const AnimatedWave({
    required this.color,
    super.key,
    this.height = 100,
    this.speed = 1.0,
    this.offset = 0.0,
  });
  final Color color;
  final double height;
  final double speed;
  final double offset;

  @override
  State<AnimatedWave> createState() => _AnimatedWaveState();
}

class _AnimatedWaveState extends State<AnimatedWave>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (3000 / widget.speed).round()),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: WavePainter(
            color: widget.color,
            animationValue: _controller.value + widget.offset,
          ),
          child: SizedBox(
            height: widget.height,
            width: double.infinity,
          ),
        );
      },
    );
  }
}

class WavePainter extends CustomPainter {
  WavePainter({
    required this.color,
    required this.animationValue,
  });
  final Color color;
  final double animationValue;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);

    for (double x = 0; x <= size.width; x++) {
      final y = size.height * 0.5 +
          math.sin((x / size.width * 4 * math.pi) +
                  (animationValue * 2 * math.pi)) *
              size.height *
              0.3;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}
