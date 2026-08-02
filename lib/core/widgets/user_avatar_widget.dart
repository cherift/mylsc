import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Widget d'avatar utilisateur réutilisable.
/// Utilise [Image.network] avec errorBuilder pour être compatible web (CORS)
/// et mobile. En renderer HTML Flutter web, Image.network charge les images
/// via un vrai élément <img> HTML qui ne requiert pas de headers CORS.
class UserAvatarWidget extends StatelessWidget {
  const UserAvatarWidget({
    required this.radius,
    super.key,
    this.photoUrl,
    this.initials,
    this.backgroundColor,
    this.textColor,
    this.gradient,
  });

  final double radius;
  final String? photoUrl;
  final String? initials;
  final Color? backgroundColor;
  final Color? textColor;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;

    if (hasPhoto) {
      return ClipOval(
        child: Image.network(
          photoUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(size),
          loadingBuilder: (_, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _fallback(size);
          },
        ),
      );
    }

    return _fallback(size);
  }

  Widget _fallback(double size) {
    final bg = gradient != null
        ? null
        : (backgroundColor ?? AppColors.primary.withValues(alpha: 0.15));

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bg,
        gradient: gradient ?? AppColors.primaryGradient,
      ),
      child: Center(
        child: Text(
          (initials?.isNotEmpty ?? false) ? initials! : '?',
          style: TextStyle(
            color: textColor ?? Colors.white,
            fontSize: size * 0.35,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
