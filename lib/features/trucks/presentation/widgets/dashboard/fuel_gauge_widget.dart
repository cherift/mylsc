import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../../core/theme/app_theme.dart';

/// Widget de jauge de carburant moderne
class FuelGaugeWidget extends StatelessWidget { // Capacité en litres

  const FuelGaugeWidget({
    required this.fuelLevel, required this.capacity, super.key,
  });
  final double fuelLevel; // 0.0 à 1.0
  final int capacity;

  @override
  Widget build(BuildContext context) {
    final currentLiters = (fuelLevel * capacity).round();
    final isLow = fuelLevel < 0.25;
    final isCritical = fuelLevel < 0.10;

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
          color: isCritical
              ? AppColors.error.withValues(alpha: 0.5)
              : isLow
                  ? AppColors.warning.withValues(alpha: 0.5)
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
                    Iconsax.gas_station,
                    color: isCritical
                        ? AppColors.error
                        : isLow
                            ? AppColors.warning
                            : AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Text(
                    'Carburant',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (isLow)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: (isCritical ? AppColors.error : AppColors.warning)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    isCritical ? 'CRITIQUE' : 'BAS',
                    style: TextStyle(
                      color: isCritical ? AppColors.error : AppColors.warning,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
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
              painter: _FuelGaugePainter(
                fuelLevel: fuelLevel,
                isLow: isLow,
                isCritical: isCritical,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${(fuelLevel * 100).round()}%',
                      style: TextStyle(
                        color: isCritical
                            ? AppColors.error
                            : isLow
                                ? AppColors.warning
                                : AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$currentLiters L',
                      style: const TextStyle(
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

          // Capacité totale
          Text(
            'Capacité: $capacity L',
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _FuelGaugePainter extends CustomPainter {

  _FuelGaugePainter({
    required this.fuelLevel,
    required this.isLow,
    required this.isCritical,
  });
  final double fuelLevel;
  final bool isLow;
  final bool isCritical;

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

    // Arc de niveau
    final levelColor = isCritical
        ? AppColors.error
        : isLow
            ? AppColors.warning
            : AppColors.primary;

    final levelPaint = Paint()
      ..shader = SweepGradient(
        startAngle: math.pi * 0.75,
        endAngle: math.pi * 2.25,
        colors: [
          levelColor.withValues(alpha: 0.5),
          levelColor,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.75,
      math.pi * 1.5 * fuelLevel,
      false,
      levelPaint,
    );

    // Effet de glow
    final glowPaint = Paint()
      ..color = levelColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 8
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.75,
      math.pi * 1.5 * fuelLevel,
      false,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _FuelGaugePainter oldDelegate) {
    return oldDelegate.fuelLevel != fuelLevel;
  }
}
