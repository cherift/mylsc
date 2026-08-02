import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';

/// Illustration vectorielle animée d'un camion
class TruckIllustration extends StatefulWidget {
  const TruckIllustration({
    super.key,
    this.width = 400,
    this.height = 280,
  });
  final double width;
  final double height;

  @override
  State<TruckIllustration> createState() => _TruckIllustrationState();
}

class _TruckIllustrationState extends State<TruckIllustration>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _dashboardController;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _dashboardController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _dashboardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Cercle de fond avec glow
          Positioned(
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.15),
                    AppColors.primary.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            )
                .animate(
                  onPlay: (controller) => controller.repeat(reverse: true),
                )
                .scale(
                  begin: const Offset(0.95, 0.95),
                  end: const Offset(1.05, 1.05),
                  duration: 3.seconds,
                  curve: Curves.easeInOut,
                ),
          ),

          // Route/Sol
          Positioned(
            bottom: 20,
            child: _buildRoad(),
          ),

          // Camion principal
          AnimatedBuilder(
            animation: _bounceController,
            builder: (context, child) {
              final bounce = math.sin(_bounceController.value * math.pi) * 3;
              return Transform.translate(
                offset: Offset(0, -bounce),
                child: child,
              );
            },
            child: _buildTruck(),
          ),

          // Indicateurs de tracking
          ..._buildTrackingIndicators(),

          // Signal GPS
          Positioned(
            top: 30,
            right: 60,
            child: _buildGpsSignal(),
          ),
        ],
      ),
    );
  }

  Widget _buildRoad() {
    return Container(
      width: 380,
      height: 8,
      decoration: BoxDecoration(
        color: AppColors.surfaceBorder,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Stack(
        children: [
          // Lignes de la route
          Positioned.fill(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                8,
                (index) => Container(
                  width: 30,
                  height: 2,
                  color: AppColors.textMuted.withValues(alpha: 0.5),
                )
                    .animate(
                      onPlay: (controller) => controller.repeat(),
                    )
                    .moveX(
                      begin: 0,
                      end: -50,
                      duration: 1.seconds,
                      delay: Duration(milliseconds: index * 100),
                    )
                    .fadeOut(
                      begin: 1,
                      duration: 1.seconds,
                      delay: Duration(milliseconds: index * 100),
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTruck() {
    return SizedBox(
      width: 220,
      height: 100,
      child: Stack(
        children: [
          // Remorque
          Positioned(
            left: 0,
            bottom: 15,
            child: Container(
              width: 130,
              height: 60,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.surface,
                    AppColors.surfaceLight,
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.surfaceBorder,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Logo sur la remorque
                  Center(
                    child: Icon(
                      Icons.local_shipping,
                      color: AppColors.primary.withValues(alpha: 0.3),
                      size: 30,
                    ),
                  ),
                  // Lignes décoratives
                  Positioned(
                    bottom: 8,
                    left: 8,
                    right: 8,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.5),
                            AppColors.accent.withValues(alpha: 0.5),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Cabine
          Positioned(
            right: 0,
            bottom: 15,
            child: Container(
              width: 80,
              height: 70,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.primaryDark,
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(12),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Pare-brise
                  Positioned(
                    top: 8,
                    left: 8,
                    right: 8,
                    child: Container(
                      height: 25,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.2),
                            Colors.white.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  // Grille avant
                  Positioned(
                    bottom: 8,
                    right: 4,
                    child: Container(
                      width: 6,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Roues
          Positioned(
            left: 20,
            bottom: 0,
            child: _buildWheel(),
          ),
          Positioned(
            left: 90,
            bottom: 0,
            child: _buildWheel(),
          ),
          Positioned(
            right: 20,
            bottom: 0,
            child: _buildWheel(),
          ),

          // Phare
          Positioned(
            right: 0,
            bottom: 30,
            child: Container(
              width: 8,
              height: 12,
              decoration: BoxDecoration(
                color: AppColors.warning,
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.warning.withValues(alpha: 0.6),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
            )
                .animate(
                  onPlay: (controller) => controller.repeat(reverse: true),
                )
                .fadeIn(duration: 500.ms)
                .then()
                .fadeOut(duration: 500.ms),
          ),
        ],
      ),
    );
  }

  Widget _buildWheel() {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.backgroundSecondary,
        border: Border.all(
          color: AppColors.textMuted,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.textTertiary,
          ),
        ),
      ),
    )
        .animate(
          onPlay: (controller) => controller.repeat(),
        )
        .rotate(
          duration: 1.seconds,
          begin: 0,
          end: 1,
        );
  }

  List<Widget> _buildTrackingIndicators() {
    return [
      // Point de localisation
      Positioned(
        top: 20,
        left: 80,
        child: _buildLocationDot(delay: 0),
      ),
      Positioned(
        top: 50,
        left: 120,
        child: _buildLocationDot(delay: 200),
      ),
      Positioned(
        top: 40,
        right: 100,
        child: _buildLocationDot(delay: 400),
      ),
    ];
  }

  Widget _buildLocationDot({required int delay}) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.success,
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.5),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
    )
        .animate(
          onPlay: (controller) => controller.repeat(reverse: true),
          delay: Duration(milliseconds: delay),
        )
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.2, 1.2),
          duration: 1.seconds,
        )
        .fadeIn(duration: 500.ms)
        .then()
        .fadeOut(duration: 500.ms);
  }

  Widget _buildGpsSignal() {
    return SizedBox(
      width: 50,
      height: 50,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Cercles d'ondes
          ...List.generate(3, (index) {
            return Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
            )
                .animate(
                  onPlay: (controller) => controller.repeat(),
                  delay: Duration(milliseconds: index * 400),
                )
                .scale(
                  begin: const Offset(0.3, 0.3),
                  end: const Offset(1.2, 1.2),
                  duration: 1200.ms,
                  curve: Curves.easeOut,
                )
                .fadeOut(duration: 1200.ms);
          }),
          // Icône GPS
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
              boxShadow: AppShadows.glow,
            ),
            child: const Icon(
              Icons.gps_fixed,
              size: 12,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget de carte miniature
class MiniMap extends StatelessWidget {
  const MiniMap({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Stack(
        children: [
          // Grille de fond
          CustomPaint(
            size: const Size(120, 80),
            painter: MapGridPainter(),
          ),
          // Point de position
          Positioned(
            top: 30,
            left: 60,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.5),
                    blurRadius: 6,
                  ),
                ],
              ),
            )
                .animate(
                  onPlay: (controller) => controller.repeat(reverse: true),
                )
                .scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1.2, 1.2),
                  duration: 1.seconds,
                ),
          ),
        ],
      ),
    );
  }
}

class MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.surfaceBorder.withValues(alpha: 0.5)
      ..strokeWidth = 0.5;

    // Lignes verticales
    for (double x = 0; x <= size.width; x += 20) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Lignes horizontales
    for (double y = 0; y <= size.height; y += 20) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Route principale
    final roadPaint = Paint()
      ..color = AppColors.textMuted.withValues(alpha: 0.3)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(0, 50)
      ..quadraticBezierTo(40, 30, 80, 40)
      ..quadraticBezierTo(100, 50, 120, 30);

    canvas.drawPath(path, roadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
