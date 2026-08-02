import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../breakdown/domain/models/breakdown_report_model.dart';
import '../../../breakdown/presentation/providers/breakdown_providers.dart';
import '../../../fleet/presentation/providers/fleet_providers.dart';
import '../../domain/models/dashboard_filter.dart';

/// Section pannes avec PieChart par sévérité + stats par statut
/// [fleetId] — filtre par flotte. [filter] — filtre par camions.
class DirectionBreakdownsSection extends ConsumerWidget {
  const DirectionBreakdownsSection({super.key, this.fleetId, this.filter});

  final String? fleetId;
  final DashboardFilter? filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final allActive = ref.watch(activeBreakdownsStreamProvider).valueOrNull ?? [];
    final allBreakdowns = ref.watch(allBreakdownsStreamProvider).valueOrNull ?? [];

    // Filtrer par flotte si nécessaire
    Set<String>? truckIds;
    if (fleetId != null) {
      final fleetTrucks = ref.watch(fleetTrucksProvider(fleetId!)).valueOrNull ?? [];
      truckIds = fleetTrucks.map((t) => t.id).toSet();
    }

    // Appliquer le filtre véhicule du DashboardFilter
    final filterTruckIds = filter?.selectedTruckIds;
    if (filterTruckIds != null) {
      truckIds = filterTruckIds;
    }

    final filterIds = truckIds;
    final active = filterIds != null
        ? allActive.where((b) => filterIds.contains(b.truckId)).toList()
        : allActive;
    final all = filterIds != null
        ? allBreakdowns.where((b) => filterIds.contains(b.truckId)).toList()
        : allBreakdowns;

    if (all.isEmpty) {
      return Center(
        child: Text(
          l10n.translate('directionDashboard.noData'),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    // Par sévérité (pannes actives)
    final severityCounts = <BreakdownSeverity, int>{};
    for (final b in active) {
      severityCounts[b.severity] = (severityCounts[b.severity] ?? 0) + 1;
    }

    // Par statut (toutes les pannes)
    final statusCounts = <BreakdownStatus, int>{};
    for (final b in all) {
      statusCounts[b.status] = (statusCounts[b.status] ?? 0) + 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.translate('directionDashboard.bySeverity'),
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (active.isNotEmpty)
          SizedBox(
            height: 160,
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 30,
                      sections: _buildSeveritySections(severityCounts),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: severityCounts.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: _severityColor(entry.key),
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
          )
        else
          Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                l10n.translate('directionDashboard.noData'),
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            _buildMiniStat(BreakdownStatus.pending.label, '${statusCounts[BreakdownStatus.pending] ?? 0}', AppColors.warning),
            const SizedBox(width: AppSpacing.sm),
            _buildMiniStat(BreakdownStatus.inDiagnostic.label, '${statusCounts[BreakdownStatus.inDiagnostic] ?? 0}', AppColors.info),
            const SizedBox(width: AppSpacing.sm),
            _buildMiniStat(BreakdownStatus.inRepair.label, '${statusCounts[BreakdownStatus.inRepair] ?? 0}', AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            _buildMiniStat(BreakdownStatus.resolved.label, '${statusCounts[BreakdownStatus.resolved] ?? 0}', AppColors.success),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 9,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildSeveritySections(Map<BreakdownSeverity, int> counts) {
    return counts.entries.map((entry) {
      return PieChartSectionData(
        value: entry.value.toDouble(),
        color: _severityColor(entry.key),
        title: '${entry.value}',
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        radius: 40,
      );
    }).toList();
  }

  Color _severityColor(BreakdownSeverity severity) {
    return switch (severity) {
      BreakdownSeverity.low => AppColors.info,
      BreakdownSeverity.medium => AppColors.warning,
      BreakdownSeverity.high => AppColors.error,
      BreakdownSeverity.critical => const Color(0xFFB71C1C),
    };
  }
}
