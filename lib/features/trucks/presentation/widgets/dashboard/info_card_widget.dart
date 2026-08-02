import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/i18n/app_localizations.dart';
import '../../../domain/models/truck_model.dart';
import '../../../domain/models/truck_field.dart';
import '../../utils/truck_field_value_extractor.dart';

/// Widget de carte d'information pour le tableau de bord
class InfoCardWidget extends StatelessWidget {

  const InfoCardWidget({
    required this.field, required this.truck, super.key,
  });
  final TruckField field;
  final TruckModel truck;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final value = TruckFieldValueExtractor.getValue(truck, field.key, l10n);
    final statusIcon = TruckFieldValueExtractor.getStatusIcon(truck, field.key);
    final hasWarning = statusIcon != null;

    return Container(
      width: 180,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: hasWarning
            ? AppColors.warning.withValues(alpha: 0.05)
            : AppColors.surfaceLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: hasWarning
              ? AppColors.warning.withValues(alpha: 0.3)
              : AppColors.surfaceBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header avec icône
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: hasWarning
                      ? AppColors.warning.withValues(alpha: 0.15)
                      : AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: Icon(
                  field.icon,
                  size: 14,
                  color: hasWarning ? AppColors.warning : AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.translate('trucks.fields.${field.key}'),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (hasWarning)
                Text(
                  statusIcon,
                  style: const TextStyle(fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Valeur
          Text(
            value,
            style: TextStyle(
              color: hasWarning ? AppColors.warning : AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
