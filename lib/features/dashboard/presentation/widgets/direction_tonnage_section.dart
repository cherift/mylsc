import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../fleet/presentation/providers/fleet_providers.dart';
import '../../../weighing/domain/models/weighing_record_model.dart';
import '../../../weighing/presentation/providers/weighing_providers.dart';
import '../../domain/models/dashboard_filter.dart';

/// Section tonnage Mine vs Port avec BarChart groupé 7 jours
/// [fleetId] — filtre par flotte. [filter] — filtre par date et/ou camions.
class DirectionTonnageSection extends ConsumerWidget {
  const DirectionTonnageSection({super.key, this.fleetId, this.filter});

  final String? fleetId;
  final DashboardFilter? filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final allMine = ref.watch(mineWeighingsStreamProvider).valueOrNull ?? [];
    final allPort = ref.watch(portWeighingsStreamProvider).valueOrNull ?? [];

    // Filtrer par flotte si nécessaire
    List<WeighingRecordModel> mineWeighings;
    List<WeighingRecordModel> portWeighings;
    if (fleetId != null) {
      final fleetTrucks =
          ref.watch(fleetTrucksProvider(fleetId!)).valueOrNull ?? [];
      final fleetTruckIds = fleetTrucks.map((t) => t.id).toSet();
      mineWeighings =
          allMine.where((w) => fleetTruckIds.contains(w.truckId)).toList();
      portWeighings =
          allPort.where((w) => fleetTruckIds.contains(w.truckId)).toList();
    } else {
      mineWeighings = allMine;
      portWeighings = allPort;
    }

    // Appliquer le filtre véhicule du DashboardFilter
    if (filter != null && filter!.selectedTruckIds != null) {
      mineWeighings =
          mineWeighings.where((w) => filter!.matchesTruck(w.truckId)).toList();
      portWeighings =
          portWeighings.where((w) => filter!.matchesTruck(w.truckId)).toList();
    }

    // Appliquer le filtre date pour les mini stats (totaux)
    final mineFiltered = filter != null
        ? mineWeighings
            .where((w) => filter!.matchesDate(w.createdAt))
            .toList()
        : mineWeighings;
    final portFiltered = filter != null
        ? portWeighings
            .where((w) => filter!.matchesDate(w.createdAt))
            .toList()
        : portWeighings;

    final now = DateTime.now();

    // Graphique en barres — toujours 7 jours glissants (par camion filtré)
    final dayLabels = <String>[];
    final dayMineTonnages = <double>[];
    final dayPortTonnages = <double>[];
    for (var i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day - i);
      dayLabels.add('${day.day}/${day.month}');
      final dayMine = mineWeighings.where((w) =>
          w.createdAt.year == day.year &&
          w.createdAt.month == day.month &&
          w.createdAt.day == day.day);
      final dayPort = portWeighings.where((w) =>
          w.createdAt.year == day.year &&
          w.createdAt.month == day.month &&
          w.createdAt.day == day.day);
      dayMineTonnages.add(dayMine.fold<double>(0, (sum, w) => sum + w.weight));
      dayPortTonnages.add(dayPort.fold<double>(0, (sum, w) => sum + w.weight));
    }

    final maxMine = dayMineTonnages.isEmpty
        ? 0.0
        : dayMineTonnages.reduce((a, b) => a > b ? a : b);
    final maxPort = dayPortTonnages.isEmpty
        ? 0.0
        : dayPortTonnages.reduce((a, b) => a > b ? a : b);
    final maxVal = maxMine > maxPort ? maxMine : maxPort;
    final yMax = maxVal <= 0 ? 10.0 : maxVal * 1.2;

    // Stats globales (avec filtre date si actif)
    final totalMine =
        mineFiltered.fold<double>(0, (sum, w) => sum + w.weight);
    final totalPort =
        portFiltered.fold<double>(0, (sum, w) => sum + w.weight);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Légende + titre
        Row(
          children: [
            Text(
              l10n.translate('directionDashboard.last7Days'),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const Spacer(),
            _buildLegendDot(
                AppColors.info, l10n.translate('directionDashboard.mine')),
            const SizedBox(width: AppSpacing.md),
            _buildLegendDot(
                AppColors.accent, l10n.translate('directionDashboard.port')),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 180,
          child: BarChart(
            BarChartData(
              maxY: yMax,
              barGroups: List.generate(7, (i) {
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: dayMineTonnages[i],
                      color: AppColors.info,
                      width: 8,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                    BarChartRodData(
                      toY: dayPortTonnages[i],
                      color: AppColors.accent,
                      width: 8,
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
                      if (idx < 0 || idx >= dayLabels.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          dayLabels[idx],
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
                    reservedSize: 40,
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
                    final label = rodIndex == 0
                        ? l10n.translate('directionDashboard.mine')
                        : l10n.translate('directionDashboard.port');
                    return BarTooltipItem(
                      '$label: ${rod.toY.toStringAsFixed(1)} T',
                      TextStyle(
                        color: rod.color,
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
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            _buildMiniStat(
                l10n.translate('directionDashboard.mine'),
                '${mineFiltered.length}',
                AppColors.info),
            const SizedBox(width: AppSpacing.sm),
            _buildMiniStat(
                l10n.translate('directionDashboard.tonnageMine'),
                '${totalMine.toStringAsFixed(0)} T',
                AppColors.info),
            const SizedBox(width: AppSpacing.sm),
            _buildMiniStat(
                l10n.translate('directionDashboard.port'),
                '${portFiltered.length}',
                AppColors.accent),
            const SizedBox(width: AppSpacing.sm),
            _buildMiniStat(
                l10n.translate('directionDashboard.tonnagePort'),
                '${totalPort.toStringAsFixed(0)} T',
                AppColors.accent),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm, horizontal: 4),
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
}
