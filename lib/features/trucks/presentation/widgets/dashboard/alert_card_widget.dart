import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';

/// Types d'alertes
enum AlertType {
  info,
  warning,
  error,
  success,
}

/// Widget de carte d'alerte pour le tableau de bord
class AlertCardWidget extends StatelessWidget {

  const AlertCardWidget({
    required this.type, required this.title, required this.message, required this.icon, super.key,
    this.onAction,
    this.actionLabel,
  });
  final AlertType type;
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionLabel;

  Color get _color {
    switch (type) {
      case AlertType.info:
        return AppColors.info;
      case AlertType.warning:
        return AppColors.warning;
      case AlertType.error:
        return AppColors.error;
      case AlertType.success:
        return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: _color.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // Icône
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              icon,
              color: _color,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Contenu
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: _color,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Bouton d'action
          if (onAction != null && actionLabel != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: _color,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
              ),
              child: Text(
                actionLabel!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
