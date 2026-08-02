import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../trucks/domain/models/truck_model.dart';
import '../../../trucks/presentation/providers/truck_providers.dart';
import '../../../fleet/presentation/providers/fleet_providers.dart';
import '../../domain/models/dashboard_filter.dart';

/// Section véhicules avec PieChart par statut et chips par type
/// [fleetId] — filtre par flotte. [filter] — filtre par sélection de camions.
class DirectionVehiclesSection extends ConsumerWidget {
  const DirectionVehiclesSection({super.key, this.fleetId, this.filter});

  final String? fleetId;
  final DashboardFilter? filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final allTrucks = fleetId != null
        ? (ref.watch(fleetTrucksProvider(fleetId!)).valueOrNull ?? [])
        : (ref.watch(trucksStreamProvider).valueOrNull ?? []);

    // Appliquer le filtre véhicule
    final trucks = filter != null && filter!.selectedTruckIds != null
        ? allTrucks.where((t) => filter!.matchesTruck(t.id)).toList()
        : allTrucks;

    if (trucks.isEmpty) {
      return Center(
        child: Text(
          l10n.translate('directionDashboard.noData'),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    final statusCounts = <TruckStatus, int>{};
    for (final truck in trucks) {
      statusCounts[truck.statut] = (statusCounts[truck.statut] ?? 0) + 1;
    }

    final typeCounts = <TruckType, int>{};
    for (final truck in trucks) {
      typeCounts[truck.type] = (typeCounts[truck.type] ?? 0) + 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.translate('directionDashboard.byStatus'),
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 180,
          child: Row(
            children: [
              Expanded(
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 35,
                    sections: _buildPieSections(statusCounts),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: statusCounts.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _statusColor(entry.key),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${entry.key.label} (${entry.value})',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          l10n.translate('directionDashboard.byType'),
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: typeCounts.entries.map((entry) {
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Text(
                '${entry.key.label} (${entry.value})',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  List<PieChartSectionData> _buildPieSections(
      Map<TruckStatus, int> counts) {
    return counts.entries.map((entry) {
      return PieChartSectionData(
        value: entry.value.toDouble(),
        color: _statusColor(entry.key),
        title: '${entry.value}',
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        radius: 45,
      );
    }).toList();
  }

  Color _statusColor(TruckStatus status) {
    return switch (status) {
      TruckStatus.enService => AppColors.success,
      TruckStatus.enMaintenance => AppColors.warning,
      TruckStatus.enPanne => AppColors.error,
      TruckStatus.immobilise => AppColors.textSecondary,
    };
  }
}
