import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/widgets/inline_error_retry.dart';
import '../../domain/models/fuel_entry_model.dart';
import '../providers/fuel_providers.dart';

/// Widget pour afficher l'historique des entrées de carburant d'un véhicule
class FuelHistoryWidget extends ConsumerWidget {

  const FuelHistoryWidget({
    required this.truckId,
    this.maxEntries = 10,
    super.key,
  });
  final String truckId;
  final int maxEntries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final fuelEntriesAsync = ref.watch(fuelEntriesForTruckProvider(truckId));

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(
                  Iconsax.gas_station,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  l10n.translate('fuel.history'),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          fuelEntriesAsync.when(
            data: (entries) {
              if (entries.isEmpty) {
                return _buildEmptyState(l10n);
              }

              final displayEntries = entries.take(maxEntries).toList();

              return Column(
                children: [
                  ...displayEntries.map((entry) => _buildFuelEntryItem(entry, l10n)),
                  if (entries.length > maxEntries)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.md),
                      child: Text(
                        '+ ${entries.length - maxEntries} autres entrées',
                        style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
            error: (error, _) => Center(
              child: Text(
                'Erreur: $error',
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Icon(
            Iconsax.gas_station,
            size: 48,
            color: AppColors.textTertiary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.translate('fuel.noEntries'),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFuelEntryItem(FuelEntryModel entry, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  entry.liters.toStringAsFixed(0),
                  style: const TextStyle(
                    color: AppColors.success,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  l10n.translate('fuel.liters'),
                  style: const TextStyle(
                    color: AppColors.success,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.formattedDate,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${l10n.translate('fuel.addedBy')} ${entry.addedByName}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            entry.formattedTime,
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 12,
            ),
          ),
          if (entry.receiptPhotoUrl != null) ...[
            const SizedBox(width: AppSpacing.sm),
            const Icon(
              Iconsax.image,
              color: AppColors.info,
              size: 16,
            ),
          ],
        ],
      ),
    );
  }
}

/// Widget compact pour afficher les statistiques de carburant
class FuelStatsWidget extends ConsumerWidget {

  const FuelStatsWidget({
    required this.truckId,
    super.key,
  });
  final String truckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final statsAsync = ref.watch(fuelStatsForTruckProvider(truckId));

    return statsAsync.when(
      data: (stats) {
        final totalLiters = stats['totalLiters'] as double;
        final totalEntries = stats['totalEntries'] as int;

        if (totalEntries == 0) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Iconsax.gas_station, color: AppColors.primary, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${totalLiters.toStringAsFixed(0)} ${l10n.translate('fuel.liters')}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '($totalEntries)',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => InlineErrorRetry(
        onRetry: () => ref.invalidate(fuelEntriesForTruckProvider(truckId)),
      ),
    );
  }
}
