import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../trucks/domain/models/truck_model.dart';
import '../../../trucks/presentation/providers/truck_providers.dart';
import '../../../shifts/presentation/providers/shift_providers.dart';
import '../../../weighing/presentation/providers/weighing_providers.dart';
import '../../../breakdown/domain/models/breakdown_report_model.dart';
import '../../../breakdown/presentation/providers/breakdown_providers.dart';
import '../../../fleet/presentation/providers/fleet_providers.dart';
import '../../../chauffeur/presentation/providers/driver_providers.dart';
import '../../domain/models/dashboard_filter.dart';
import 'dashboard_stat_card.dart';
import 'kpi_detail_dialog.dart';

/// Rangée de KPI principaux du dashboard direction.
/// [fleetId] — si fourni, charge les camions de cette flotte.
/// [filter]  — filtre par plage de dates et/ou par sélection de camions.
class DirectionKpiRow extends ConsumerWidget {
  const DirectionKpiRow({super.key, this.fleetId, this.filter});

  final String? fleetId;
  final DashboardFilter? filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final numFmt = NumberFormat('#,##0', 'fr_FR');

    // 1. Chargement des camions (par flotte ou tous)
    final allTrucks = fleetId != null
        ? (ref.watch(fleetTrucksProvider(fleetId!)).valueOrNull ?? [])
        : (ref.watch(trucksStreamProvider).valueOrNull ?? []);

    // 2. Application du filtre véhicule
    final trucks = filter != null && filter!.selectedTruckIds != null
        ? allTrucks.where((t) => filter!.matchesTruck(t.id)).toList()
        : allTrucks;

    final allShifts = ref.watch(activeShiftsStreamProvider).valueOrNull ?? [];
    final allShiftsToday = ref.watch(todayShiftsStreamProvider).valueOrNull ?? [];
    final allMineWeighings =
        ref.watch(mineWeighingsStreamProvider).valueOrNull ?? [];
    final allPortWeighings =
        ref.watch(portWeighingsStreamProvider).valueOrNull ?? [];
    final allBreakdowns =
        ref.watch(activeBreakdownsStreamProvider).valueOrNull ?? [];

    // 3. Filtrer par truckIds de la flotte ET du filtre véhicule
    final truckIds = trucks.map((t) => t.id).toSet();

    final shifts = allShifts
        .where((s) => truckIds.contains(s.truckId))
        .toList();

    // 4. Application du filtre date + véhicule sur les pesées
    final mineWeighings = allMineWeighings.where((w) {
      if (!truckIds.contains(w.truckId)) return false;
      return filter?.matchesDate(w.createdAt) ?? true;
    }).toList();
    final portWeighings = allPortWeighings.where((w) {
      if (!truckIds.contains(w.truckId)) return false;
      return filter?.matchesDate(w.createdAt) ?? true;
    }).toList();

    final breakdowns = allBreakdowns
        .where((b) => truckIds.contains(b.truckId))
        .toList();

    final inService =
        trucks.where((t) => t.statut == TruckStatus.enService).length;
    final totalTrucks = trucks.length;

    final activeDrivers = shifts.length;

    final allDriversList =
        ref.watch(allDriversProvider).valueOrNull ?? [];
    final totalDrivers = fleetId != null
        ? allDriversList.where((u) => u.fleetId == fleetId).length
        : allDriversList.length;

    final totalMine =
        mineWeighings.fold<double>(0, (sum, w) => sum + w.weight);
    final totalPort =
        portWeighings.fold<double>(0, (sum, w) => sum + w.weight);

    final activeBreakdowns = breakdowns.length;
    final criticalCount = breakdowns
        .where((b) => b.severity == BreakdownSeverity.critical)
        .length;

    // Si fleetId est défini → filtrer par les camions de la flotte
    // Sinon (dashboard général) → toutes les vacations du jour
    final shiftsToday = fleetId != null
        ? allShiftsToday
            .where((s) => truckIds.contains(s.truckId))
            .toList()
        : allShiftsToday;
    final activeShiftsToday =
        shiftsToday.where((s) => s.isOngoing).length;
    final totalShiftsToday = shiftsToday.length;

    // Build KPI detail items
    final vehicleItems = trucks.map((t) {
      final statusColor = switch (t.statut) {
        TruckStatus.enService => AppColors.success,
        TruckStatus.enMaintenance => AppColors.warning,
        TruckStatus.enPanne => AppColors.error,
        TruckStatus.immobilise => AppColors.textSecondary,
      };
      final statusKey = switch (t.statut) {
        TruckStatus.enService => 'trucks.status.enService',
        TruckStatus.enMaintenance => 'trucks.status.enMaintenance',
        TruckStatus.enPanne => 'trucks.status.enPanne',
        TruckStatus.immobilise => 'trucks.status.immobilise',
      };
      return KpiDetailItem(
        title: t.immatriculation,
        subtitle: '${t.marque} ${t.modele}',
        value: l10n.translate(statusKey),
        color: statusColor,
      );
    }).toList();

    final driverItems = shifts
        .map((s) => KpiDetailItem(
              title: s.driverName,
              subtitle: s.truckImmatriculation,
              color: AppColors.primary,
              truckImmatriculation: s.truckImmatriculation,
            ))
        .toList();

    final mineItems = mineWeighings
        .map((w) => KpiDetailItem(
              title: w.truckImmatriculation,
              subtitle:
                  '${w.driverName ?? "-"} | Bon: ${w.ticketNumber ?? "-"} | ${w.formattedDate}',
              value: '${numFmt.format(w.weight.round())} T',
              color: AppColors.info,
              dateTime: w.createdAt,
              truckImmatriculation: w.truckImmatriculation,
              extraData: {
                l10n.translate('trucks.fields.immatriculation'):
                    w.truckImmatriculation,
                l10n.translate('users.roles.driver'): w.driverName ?? '',
                l10n.translate('trip.netTonnage'):
                    w.weight.toStringAsFixed(2),
                l10n.translate('weighing.emptyWeight'):
                    w.emptyWeight?.toStringAsFixed(2) ?? '',
                l10n.translate('weighing.loadedWeight'):
                    w.loadedWeight?.toStringAsFixed(2) ?? '',
                l10n.translate('weighing.ticketNumber'):
                    w.ticketNumber ?? '',
                l10n.translate('weighing.date'): w.formattedDate,
                l10n.translate('weighing.weighedBy'): w.weighedByName,
              },
            ))
        .toList();

    final portItems = portWeighings
        .map((w) => KpiDetailItem(
              title: w.truckImmatriculation,
              subtitle:
                  '${w.driverName ?? "-"} | Bon: ${w.ticketNumber ?? "-"} | ${w.formattedDate}',
              value: '${numFmt.format(w.weight.round())} T',
              color: AppColors.accent,
              dateTime: w.createdAt,
              truckImmatriculation: w.truckImmatriculation,
              extraData: {
                l10n.translate('trucks.fields.immatriculation'):
                    w.truckImmatriculation,
                l10n.translate('users.roles.driver'): w.driverName ?? '',
                l10n.translate('trip.netTonnage'):
                    w.weight.toStringAsFixed(2),
                l10n.translate('weighing.emptyWeight'):
                    w.emptyWeight?.toStringAsFixed(2) ?? '',
                l10n.translate('weighing.loadedWeight'):
                    w.loadedWeight?.toStringAsFixed(2) ?? '',
                l10n.translate('weighing.ticketNumber'):
                    w.ticketNumber ?? '',
                l10n.translate('weighing.date'): w.formattedDate,
                l10n.translate('weighing.weighedBy'): w.weighedByName,
              },
            ))
        .toList();

    final breakdownItems = breakdowns.map((b) {
      final severityColor = switch (b.severity) {
        BreakdownSeverity.low => AppColors.success,
        BreakdownSeverity.medium => AppColors.warning,
        BreakdownSeverity.high => AppColors.accent,
        BreakdownSeverity.critical => AppColors.error,
      };
      final severityKey = switch (b.severity) {
        BreakdownSeverity.low => 'breakdown.severityLow',
        BreakdownSeverity.medium => 'breakdown.severityMedium',
        BreakdownSeverity.high => 'breakdown.severityHigh',
        BreakdownSeverity.critical => 'breakdown.severityCritical',
      };
      return KpiDetailItem(
        title: b.truckImmatriculation,
        subtitle: b.description,
        value: l10n.translate(severityKey),
        color: severityColor,
        truckImmatriculation: b.truckImmatriculation,
      );
    }).toList();

    final vacationItems = shiftsToday
        .map((s) => KpiDetailItem(
              title: s.driverName,
              subtitle: s.truckImmatriculation,
              value: s.isOngoing
                  ? l10n.translate('shifts.statusActive')
                  : l10n.translate('shifts.statusEnded'),
              color:
                  s.isOngoing ? AppColors.success : AppColors.textSecondary,
              dateTime: s.startTime,
              truckImmatriculation: s.truckImmatriculation,
            ))
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        final cardWidth = (constraints.maxWidth - AppSpacing.md) / 2;
        if (isWide) {
          return Row(
            children: [
              Expanded(
                child: DashboardStatCard(
                  icon: Iconsax.truck,
                  label: l10n.translate(
                      'directionDashboard.vehiclesInService'),
                  value: '$inService/$totalTrucks',
                  color: AppColors.success,
                  onTap: () => _showKpiDetail(
                    context,
                    title: l10n.translate(
                        'directionDashboard.detailVehicles'),
                    icon: Iconsax.truck,
                    color: AppColors.success,
                    items: vehicleItems,
                    xmlRootName: 'vehicles',
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: DashboardStatCard(
                  icon: Iconsax.people,
                  label:
                      l10n.translate('directionDashboard.activeDrivers'),
                  value: '$activeDrivers/$totalDrivers',
                  color: AppColors.primary,
                  onTap: () => _showKpiDetail(
                    context,
                    title: l10n.translate(
                        'directionDashboard.detailDrivers'),
                    icon: Iconsax.people,
                    color: AppColors.primary,
                    items: driverItems,
                    xmlRootName: 'drivers',
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: DashboardStatCard(
                  icon: Iconsax.weight,
                  label:
                      l10n.translate('directionDashboard.tonnageMine'),
                  value: '${numFmt.format(totalMine.round())} T',
                  color: AppColors.info,
                  onTap: () => _showKpiDetail(
                    context,
                    title: l10n.translate(
                        'directionDashboard.detailTonnageMine'),
                    icon: Iconsax.weight,
                    color: AppColors.info,
                    items: mineItems,
                    xmlRootName: 'tonnage_mine',
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: DashboardStatCard(
                  icon: Iconsax.weight,
                  label:
                      l10n.translate('directionDashboard.tonnagePort'),
                  value: '${numFmt.format(totalPort.round())} T',
                  color: AppColors.accent,
                  onTap: () => _showKpiDetail(
                    context,
                    title: l10n.translate(
                        'directionDashboard.detailTonnagePort'),
                    icon: Iconsax.weight,
                    color: AppColors.accent,
                    items: portItems,
                    xmlRootName: 'tonnage_port',
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: DashboardStatCard(
                  icon: Iconsax.warning_2,
                  label: l10n.translate(
                      'directionDashboard.activeBreakdowns'),
                  value: '$activeBreakdowns',
                  color: AppColors.error,
                  subtitle: criticalCount > 0
                      ? l10n
                          .translate('directionDashboard.criticalCount')
                          .replaceAll('{n}', '$criticalCount')
                      : null,
                  onTap: () => _showKpiDetail(
                    context,
                    title: l10n.translate(
                        'directionDashboard.detailBreakdowns'),
                    icon: Iconsax.warning_2,
                    color: AppColors.error,
                    items: breakdownItems,
                    xmlRootName: 'breakdowns',
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: DashboardStatCard(
                  icon: Iconsax.clock,
                  label: l10n.translate(
                      'directionDashboard.vacationsCount'),
                  value: '$activeShiftsToday/$totalShiftsToday',
                  color: AppColors.warning,
                  onTap: () => _showKpiDetail(
                    context,
                    title: l10n.translate(
                        'directionDashboard.detailVacations'),
                    icon: Iconsax.clock,
                    color: AppColors.warning,
                    items: vacationItems,
                    xmlRootName: 'vacations',
                  ),
                ),
              ),
            ],
          );
        }
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            SizedBox(
              width: cardWidth,
              child: DashboardStatCard(
                icon: Iconsax.truck,
                label: l10n.translate(
                    'directionDashboard.vehiclesInService'),
                value: '$inService/$totalTrucks',
                color: AppColors.success,
                onTap: () => _showKpiDetail(
                  context,
                  title: l10n
                      .translate('directionDashboard.detailVehicles'),
                  icon: Iconsax.truck,
                  color: AppColors.success,
                  items: vehicleItems,
                  xmlRootName: 'vehicles',
                ),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: DashboardStatCard(
                icon: Iconsax.people,
                label:
                    l10n.translate('directionDashboard.activeDrivers'),
                value: '$activeDrivers',
                color: AppColors.primary,
                onTap: () => _showKpiDetail(
                  context,
                  title: l10n
                      .translate('directionDashboard.detailDrivers'),
                  icon: Iconsax.people,
                  color: AppColors.primary,
                  items: driverItems,
                  xmlRootName: 'drivers',
                ),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: DashboardStatCard(
                icon: Iconsax.weight,
                label:
                    l10n.translate('directionDashboard.tonnageMine'),
                value: '${numFmt.format(totalMine.round())} T',
                color: AppColors.info,
                onTap: () => _showKpiDetail(
                  context,
                  title: l10n.translate(
                      'directionDashboard.detailTonnageMine'),
                  icon: Iconsax.weight,
                  color: AppColors.info,
                  items: mineItems,
                  xmlRootName: 'tonnage_mine',
                ),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: DashboardStatCard(
                icon: Iconsax.weight,
                label:
                    l10n.translate('directionDashboard.tonnagePort'),
                value: '${numFmt.format(totalPort.round())} T',
                color: AppColors.accent,
                onTap: () => _showKpiDetail(
                  context,
                  title: l10n.translate(
                      'directionDashboard.detailTonnagePort'),
                  icon: Iconsax.weight,
                  color: AppColors.accent,
                  items: portItems,
                  xmlRootName: 'tonnage_port',
                ),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: DashboardStatCard(
                icon: Iconsax.warning_2,
                label: l10n.translate(
                    'directionDashboard.activeBreakdowns'),
                value: '$activeBreakdowns',
                color: AppColors.error,
                subtitle: criticalCount > 0
                    ? l10n
                        .translate('directionDashboard.criticalCount')
                        .replaceAll('{n}', '$criticalCount')
                    : null,
                onTap: () => _showKpiDetail(
                  context,
                  title: l10n.translate(
                      'directionDashboard.detailBreakdowns'),
                  icon: Iconsax.warning_2,
                  color: AppColors.error,
                  items: breakdownItems,
                  xmlRootName: 'breakdowns',
                ),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: DashboardStatCard(
                icon: Iconsax.clock,
                label: l10n.translate(
                    'directionDashboard.vacationsCount'),
                value: '$activeShiftsToday/$totalShiftsToday',
                color: AppColors.warning,
                onTap: () => _showKpiDetail(
                  context,
                  title: l10n.translate(
                      'directionDashboard.detailVacations'),
                  icon: Iconsax.clock,
                  color: AppColors.warning,
                  items: vacationItems,
                  xmlRootName: 'vacations',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showKpiDetail(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required List<KpiDetailItem> items,
    required String xmlRootName,
  }) {
    showDialog<void>(
      context: context,
      builder: (_) => KpiDetailDialog(
        title: title,
        icon: icon,
        color: color,
        items: items,
        xmlRootName: xmlRootName,
      ),
    );
  }
}
