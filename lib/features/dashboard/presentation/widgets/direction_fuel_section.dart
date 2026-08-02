import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../fuel/domain/models/fuel_request_model.dart';
import '../../../fuel/presentation/providers/fuel_request_providers.dart';
import '../../../fleet/presentation/providers/fleet_providers.dart';
import '../../domain/models/dashboard_filter.dart';

/// Section carburant avec KPI + BarChart par statut
/// [fleetId] — filtre par flotte. [filter] — filtre par camions.
class DirectionFuelSection extends ConsumerWidget {
  const DirectionFuelSection({super.key, this.fleetId, this.filter});

  final String? fleetId;
  final DashboardFilter? filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    List<FuelRequestModel> allRequests;
    if (fleetId != null) {
      allRequests = ref.watch(fleetFuelRequestsProvider(fleetId!)).valueOrNull ?? [];
    } else {
      allRequests = ref.watch(allRequestsStreamProvider).valueOrNull ?? [];
    }

    // Appliquer les filtres véhicule et date
    final requests = filter != null
        ? allRequests
            .where((r) => filter!.matchesTruck(r.truckId))
            .where((r) => filter!.matchesDate(r.fulfilledAt ?? r.createdAt))
            .toList()
        : allRequests;

    if (requests.isEmpty) {
      return Center(
        child: Text(
          l10n.translate('directionDashboard.noData'),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    // KPI
    final totalLiters = requests
        .where((r) => r.status == FuelRequestStatus.fulfilled || r.status == FuelRequestStatus.validated)
        .fold<double>(0, (sum, r) => sum + (r.fulfilledLiters ?? 0));
    final pendingCount = requests.where((r) => r.status == FuelRequestStatus.pending).length;

    // Par statut
    final statusCounts = <FuelRequestStatus, int>{};
    for (final r in requests) {
      statusCounts[r.status] = (statusCounts[r.status] ?? 0) + 1;
    }

    final statusOrder = [
      FuelRequestStatus.pending,
      FuelRequestStatus.fulfilled,
      FuelRequestStatus.validated,
      FuelRequestStatus.disputed,
    ];

    final maxCount = statusCounts.values.isEmpty
        ? 10.0
        : statusCounts.values.reduce((a, b) => a > b ? a : b).toDouble();
    final yMax = maxCount <= 0 ? 10.0 : maxCount * 1.2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildKpiCard(
                l10n.translate('directionDashboard.totalLitersServed'),
                '${totalLiters.toStringAsFixed(0)} L',
                AppColors.info,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildKpiCard(
                l10n.translate('directionDashboard.pendingRequests'),
                '$pendingCount',
                AppColors.warning,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          height: 160,
          child: BarChart(
            BarChartData(
              maxY: yMax,
              barGroups: List.generate(statusOrder.length, (i) {
                final status = statusOrder[i];
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: (statusCounts[status] ?? 0).toDouble(),
                      color: _statusColor(status),
                      width: 28,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ],
                );
              }),
              gridData: FlGridData(
                drawVerticalLine: false,
                horizontalInterval: yMax / 4,
                getDrawingHorizontalLine: (value) => const FlLine(
                  color: AppColors.surfaceBorder,
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= statusOrder.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          statusOrder[idx].label,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 9,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${value.toInt()}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
              ),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => AppColors.backgroundSecondary,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '${rod.toY.toInt()}',
                      const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _statusColor(FuelRequestStatus status) {
    return switch (status) {
      FuelRequestStatus.pending => AppColors.warning,
      FuelRequestStatus.fulfilled => AppColors.info,
      FuelRequestStatus.validated => AppColors.success,
      FuelRequestStatus.disputed => AppColors.error,
      FuelRequestStatus.rejected => AppColors.error,
      FuelRequestStatus.cancelled => AppColors.textTertiary,
    };
  }
}
