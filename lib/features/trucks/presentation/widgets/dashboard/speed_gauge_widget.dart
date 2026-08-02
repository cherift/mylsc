import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../../core/theme/app_theme.dart';

/// Widget de jauge de vitesse moderne
class SpeedGaugeWidget extends StatelessWidget {

  const SpeedGaugeWidget({
    required this.currentSpeed, required this.maxSpeed, super.key,
  });
  final double currentSpeed;
  final double maxSpeed;

  @override
  Widget build(BuildContext context) {
    final speedRatio = (currentSpeed / maxSpeed).clamp(0.0, 1.0);
    final isMoving = currentSpeed > 0;
    final isFast = currentSpeed > maxSpeed * 0.8;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceLight.withValues(alpha: 0.5),
            AppColors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isFast
              ? AppColors.error.withValues(alpha: 0.5)
              : AppColors.surfaceBorder,
        ),
      ),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Iconsax.speedometer,
                    color: isMoving
                        ? isFast
                            ? AppColors.error
                            : AppColors.success
                        : AppColors.textMuted,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Text(
                    'Vitesse',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: (isMoving
                          ? isFast
                              ? AppColors.error
                              : AppColors.success
                          : AppColors.textMuted)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isMoving
                            ? isFast
                                ? AppColors.error
                                : AppColors.success
                            : AppColors.textMuted,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isMoving ? 'EN MOUVEMENT' : 'ARRET',
                      style: TextStyle(
                        color: isMoving
                            ? isFast
                                ? AppColors.error
                                : AppColors.success
                            : AppColors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Jauge circulaire
          SizedBox(
            width: 120,
            height: 120,
            child: CustomPaint(
              painter: _SpeedGaugePainter(
                speedRatio: speedRatio,
                isMoving: isMoving,
                isFast: isFast,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${currentSpeed.round()}',
                      style: TextStyle(
                        color: isMoving
                            ? isFast
                                ? AppColors.error
                                : AppColors.textPrimary
                            : AppColors.textMuted,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'km/h',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Info GPS
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Iconsax.gps,
                size: 12,
                color: isMoving ? AppColors.success : AppColors.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                isMoving ? 'GPS actif' : 'GPS en veille',
                style: TextStyle(
                  color: isMoving ? AppColors.textSecondary : AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpeedGaugePainter extends CustomPainter {

  _SpeedGaugePainter({
    required this.speedRatio,
    required this.isMoving,
    required this.isFast,
  });
  final double speedRatio;
  final bool isMoving;
  final bool isFast;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const strokeWidth = 12.0;

    // Arc de fond
    final backgroundPaint = Paint()
      ..color = AppColors.surfaceBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.75,
      math.pi * 1.5,
      false,
      backgroundPaint,
    );

    if (!isMoving) return;

    // Arc de vitesse
    final speedColor = isFast ? AppColors.error : AppColors.success;

    final speedPaint = Paint()
      ..shader = SweepGradient(
        startAngle: math.pi * 0.75,
        endAngle: math.pi * 2.25,
        colors: [
          AppColors.info.withValues(alpha: 0.5),
          speedColor,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.75,
      math.pi * 1.5 * speedRatio,
      false,
      speedPaint,
    );

    // Effet de glow
    final glowPaint = Paint()
      ..color = speedColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 8
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.75,
      math.pi * 1.5 * speedRatio,
      false,
      glowPaint,
    );

    // Aiguille indicatrice
    final needleAngle = math.pi * 0.75 + (math.pi * 1.5 * speedRatio);
    final needleLength = radius - 5;
    final needleEnd = Offset(
      center.dx + needleLength * math.cos(needleAngle),
      center.dy + needleLength * math.sin(needleAngle),
    );

    final needlePaint = Paint()
      ..color = speedColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(needleEnd, 4, needlePaint);
  }

  @override
  bool shouldRepaint(covariant _SpeedGaugePainter oldDelegate) {
    return oldDelegate.speedRatio != speedRatio ||
        oldDelegate.isMoving != isMoving;
  }
}
