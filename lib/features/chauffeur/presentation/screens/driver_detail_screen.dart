import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../fuel/domain/models/fuel_request_model.dart';
import '../../../shifts/domain/models/shift_model.dart' hide ShiftStatus;
import '../../../shifts/presentation/providers/shift_providers.dart';
import '../../../weighing/domain/models/weighing_record_model.dart';
import '../../../weighing/presentation/providers/weighing_providers.dart';
import '../providers/driver_providers.dart';

class DriverDetailScreen extends ConsumerWidget {
  const DriverDetailScreen({required this.driver, super.key});
  final UserModel driver;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          title: Text(
            driver.fullName,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          iconTheme: const IconThemeData(color: AppColors.textPrimary),
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(
                icon: const Icon(Iconsax.timer_1),
                text: l10n.translate('drivers.shifts'),
              ),
              Tab(
                icon: const Icon(Iconsax.weight),
                text: l10n.translate('drivers.tonnage'),
              ),
              Tab(
                icon: const Icon(Iconsax.gas_station),
                text: l10n.translate('drivers.fuel'),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            _buildInfoCard(context, ref),
            Expanded(
              child: TabBarView(
                children: [
                  _ShiftsTab(driverId: driver.id),
                  _TonnageTab(driverId: driver.id),
                  _FuelTab(driverId: driver.id),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final assignmentAsync =
        ref.watch(activeAssignmentStreamForDriverProvider(driver.id));
    final shiftAsync =
        ref.watch(activeShiftStreamForDriverProvider(driver.id));

    final assignment = assignmentAsync.valueOrNull;
    final shift = shiftAsync.valueOrNull;

    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  driver.initials,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver.fullName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      driver.matricule ?? '-',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: (shift != null
                          ? AppColors.success
                          : AppColors.textSecondary)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  shift != null
                      ? l10n.translate('drivers.shiftActive')
                      : l10n.translate('drivers.filterAvailable'),
                  style: TextStyle(
                    color: shift != null
                        ? AppColors.success
                        : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(color: AppColors.surfaceBorder, height: 1),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildInfoRow(
                  Iconsax.truck,
                  l10n.translate('drivers.assignedVehicle'),
                  assignment?.truckImmatriculation ??
                      l10n.translate('drivers.noAssignment'),
                ),
              ),
              Expanded(
                child: _buildInfoRow(
                  Iconsax.user,
                  l10n.translate('drivers.manager'),
                  driver.managerName ?? '-',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _buildInfoRow(
                  Iconsax.call,
                  l10n.translate('drivers.phone'),
                  driver.phoneNumber ?? '-',
                ),
              ),
              Expanded(
                child: _buildInfoRow(
                  Iconsax.document,
                  l10n.translate('drivers.license'),
                  driver.driverLicenseNumber ?? '-',
                ),
              ),
            ],
          ),
          if (shift != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _buildInfoRow(
                    Iconsax.timer_1,
                    l10n.translate('drivers.shifts'),
                    '${shift.truckImmatriculation} - ${_formatTime(shift.startTime)}',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 16),
        const SizedBox(width: AppSpacing.xs),
        Text(
          '$label: ',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// -- Shifts Tab ---------------------------------------------------------------

class _ShiftsTab extends ConsumerWidget {
  const _ShiftsTab({required this.driverId});
  final String driverId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final shiftsAsync = ref.watch(shiftsForDriverStreamProvider(driverId));

    return shiftsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur: $e')),
      data: (shifts) {
        if (shifts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Iconsax.timer_1,
                  color: AppColors.textSecondary,
                  size: 48,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.translate('drivers.noShifts'),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        final endedShifts =
            shifts.where((s) => s.endTime != null).toList();
        final totalWork = endedShifts.fold<Duration>(
            Duration.zero, (acc, s) => acc + (s.duration ?? Duration.zero));
        final avgWork = endedShifts.isNotEmpty
            ? Duration(minutes: totalWork.inMinutes ~/ endedShifts.length)
            : Duration.zero;

        String fmtD(Duration d) =>
            '${d.inHours}h${(d.inMinutes % 60).toString().padLeft(2, '0')}';

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  _buildShiftSummaryCard(
                    l10n.translate('shift.totalWorkTime'),
                    fmtD(totalWork),
                    '${endedShifts.length} ${l10n.translate('shift.completedShifts').toLowerCase()}',
                    AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  _buildShiftSummaryCard(
                    l10n.translate('shift.averageDuration'),
                    endedShifts.isNotEmpty ? fmtD(avgWork) : '-',
                    '${shifts.length} ${l10n.translate('shift.title').toLowerCase()}',
                    AppColors.info,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                itemCount: shifts.length,
                itemBuilder: (context, index) =>
                    _buildShiftCard(context, shifts[index]),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildShiftSummaryCard(
      String title, String value, String subtitle, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildShiftCard(BuildContext context, ShiftModel shift) {
    final l10n = AppLocalizations.of(context);
    final isActive = shift.isActive;
    final duration = shift.duration;
    final durationStr = duration != null
        ? '${duration.inHours}h${(duration.inMinutes % 60).toString().padLeft(2, '0')}'
        : '-';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isActive
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.surfaceBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: (isActive ? AppColors.success : AppColors.textSecondary)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              Iconsax.truck,
              color: isActive ? AppColors.success : AppColors.textSecondary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shift.truckImmatriculation,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatDateTime(shift.startTime)} → ${shift.endTime != null ? _formatDateTime(shift.endTime!) : l10n.translate('drivers.shiftActive')}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color:
                      (isActive ? AppColors.success : AppColors.textSecondary)
                          .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  isActive
                      ? l10n.translate('drivers.shiftActive')
                      : l10n.translate('drivers.shiftEnded'),
                  style: TextStyle(
                    color:
                        isActive ? AppColors.success : AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                durationStr,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// -- Tonnage Tab --------------------------------------------------------------

class _TonnageTab extends ConsumerWidget {
  const _TonnageTab({required this.driverId});
  final String driverId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final weighingsAsync =
        ref.watch(driverWeighingsStreamProvider(driverId));

    return weighingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur: $e')),
      data: (weighings) {
        final mine = weighings
            .where((w) => w.location == WeighingLocation.mine)
            .toList();
        final port = weighings
            .where((w) => w.location == WeighingLocation.port)
            .toList();
        final mineTonnage =
            mine.fold<double>(0, (sum, w) => sum + w.weight);
        final portTonnage =
            port.fold<double>(0, (sum, w) => sum + w.weight);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  _buildTonnageCard(
                    l10n.translate('drivers.totalMineTonnage'),
                    '${mineTonnage.toStringAsFixed(1)} T',
                    '${mine.length} ${l10n.translate('drivers.mineWeighings').toLowerCase()}',
                    AppColors.info,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  _buildTonnageCard(
                    l10n.translate('drivers.totalPortTonnage'),
                    '${portTonnage.toStringAsFixed(1)} T',
                    '${port.length} ${l10n.translate('drivers.portWeighings').toLowerCase()}',
                    AppColors.accent,
                  ),
                ],
              ),
            ),
            Expanded(
              child: weighings.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Iconsax.weight,
                            color: AppColors.textSecondary,
                            size: 48,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            l10n.translate('drivers.noWeighings'),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      itemCount: weighings.length,
                      itemBuilder: (context, index) =>
                          _buildWeighingCard(context, weighings[index]),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTonnageCard(
    String title,
    String value,
    String subtitle,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeighingCard(BuildContext context, WeighingRecordModel w) {
    final isMine = w.location == WeighingLocation.mine;
    final color = isMine ? AppColors.info : AppColors.accent;
    final locationLabel = isMine ? 'Mine' : 'Port';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              isMine ? Iconsax.building_4 : Iconsax.ship,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  w.truckImmatriculation,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$locationLabel | Bon: ${w.ticketNumber ?? "-"} | ${_formatDateTime(w.createdAt)}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${w.weight.toStringAsFixed(1)} T',
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// -- Fuel Tab -----------------------------------------------------------------

class _FuelTab extends ConsumerWidget {
  const _FuelTab({required this.driverId});
  final String driverId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final fuelAsync = ref.watch(driverFuelRequestsStreamProvider(driverId));

    return fuelAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur: $e')),
      data: (requests) {
        final served = requests
            .where((r) =>
                r.status == FuelRequestStatus.fulfilled ||
                r.status == FuelRequestStatus.validated ||
                r.status == FuelRequestStatus.disputed)
            .toList();

        final totalServed =
            served.fold<double>(0, (acc, r) => acc + (r.fulfilledLiters ?? 0));
        final totalRequested =
            requests.fold<double>(0, (acc, r) => acc + r.requestedLiters);

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              color: AppColors.backgroundSecondary,
              child: Row(
                children: [
                  _buildSummaryCard(
                    l10n.translate('drivers.fuelTotalServed'),
                    '${totalServed.toStringAsFixed(0)} L',
                    '${served.length} ${l10n.translate('drivers.fuelRequests').toLowerCase()}',
                    AppColors.warning,
                    Iconsax.gas_station,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  _buildSummaryCard(
                    l10n.translate('drivers.fuelTotalRequested'),
                    '${totalRequested.toStringAsFixed(0)} L',
                    '${requests.length} ${l10n.translate('drivers.fuelRequests').toLowerCase()}',
                    AppColors.primary,
                    Iconsax.document,
                  ),
                ],
              ),
            ),
            Expanded(
              child: requests.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Iconsax.gas_station,
                              color: AppColors.textSecondary, size: 48),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            l10n.translate('drivers.noFuelRequests'),
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                      itemCount: requests.length,
                      itemBuilder: (_, i) =>
                          _buildFuelCard(context, requests[i], l10n),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard(String title, String value, String subtitle,
      Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: AppSpacing.sm),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.w700)),
            Text(title,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
            Text(subtitle,
                style: const TextStyle(
                    color: AppColors.textTertiary, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildFuelCard(
      BuildContext context, FuelRequestModel r, AppLocalizations l10n) {
    final isServed = r.status == FuelRequestStatus.fulfilled ||
        r.status == FuelRequestStatus.validated;
    final statusColor = switch (r.status) {
      FuelRequestStatus.validated => AppColors.success,
      FuelRequestStatus.fulfilled => AppColors.info,
      FuelRequestStatus.disputed => AppColors.warning,
      FuelRequestStatus.rejected => AppColors.error,
      FuelRequestStatus.pending => AppColors.textSecondary,
      FuelRequestStatus.cancelled => AppColors.textTertiary,
    };
    final statusLabel = switch (r.status) {
      FuelRequestStatus.validated => l10n.translate('fuelRequest.validated'),
      FuelRequestStatus.fulfilled => l10n.translate('fuelRequest.fulfilled'),
      FuelRequestStatus.disputed => l10n.translate('fuelRequest.disputed'),
      FuelRequestStatus.rejected => l10n.translate('fuelRequest.rejected'),
      FuelRequestStatus.pending => l10n.translate('fuelRequest.pending'),
      FuelRequestStatus.cancelled => l10n.translate('fuelRequest.cancelled'),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(Iconsax.gas_station,
                    size: 18, color: AppColors.warning),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.truckImmatriculation,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600),
                    ),
                    Text(
                      _fmt(r.createdAt),
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(color: AppColors.surfaceBorder, height: 1),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _literRow(
                  Iconsax.document,
                  l10n.translate('drivers.fuelRequested'),
                  '${r.requestedLiters.toStringAsFixed(0)} L',
                  AppColors.textSecondary,
                ),
              ),
              if (isServed && r.fulfilledLiters != null)
                Expanded(
                  child: _literRow(
                    Iconsax.gas_station,
                    l10n.translate('drivers.fuelServed'),
                    '${r.fulfilledLiters!.toStringAsFixed(0)} L',
                    AppColors.success,
                  ),
                ),
            ],
          ),
          if (r.fulfilledByName != null || r.receiptNumber != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                if (r.fulfilledByName != null)
                  Expanded(
                    child: _literRow(
                      Iconsax.user,
                      l10n.translate('drivers.fuelServedBy'),
                      r.fulfilledByName!,
                      AppColors.textSecondary,
                    ),
                  ),
                if (r.receiptNumber != null)
                  Expanded(
                    child: _literRow(
                      Iconsax.receipt,
                      l10n.translate('drivers.fuelReceipt'),
                      r.receiptNumber!,
                      AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _literRow(IconData icon, String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textTertiary),
        const SizedBox(width: 4),
        Text('$label: ',
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 12)),
        Flexible(
          child: Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  String _fmt(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
