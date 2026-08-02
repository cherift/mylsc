import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../trips/domain/models/trip_model.dart';
import '../../../trips/presentation/providers/trip_providers.dart';
import '../../../breakdown/domain/models/breakdown_report_model.dart';
import '../../../breakdown/presentation/providers/breakdown_providers.dart';
import '../../../fleet/presentation/providers/fleet_providers.dart';

/// Section activité récente : 5 derniers trips + 5 dernières pannes
/// Si [fleetId] est fourni, filtre les données par flotte.
class DirectionRecentActivity extends ConsumerWidget {
  const DirectionRecentActivity({super.key, this.fleetId});

  final String? fleetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final allTrips = ref.watch(allTripsStreamProvider).valueOrNull ?? [];
    final allBreakdowns = ref.watch(allBreakdownsStreamProvider).valueOrNull ?? [];

    // Filtrer par flotte si nécessaire
    Set<String>? truckIds;
    if (fleetId != null) {
      final fleetTrucks = ref.watch(fleetTrucksProvider(fleetId!)).valueOrNull ?? [];
      truckIds = fleetTrucks.map((t) => t.id).toSet();
    }
    final trips = truckIds != null
        ? allTrips.where((t) => truckIds!.contains(t.truckId)).toList()
        : allTrips;
    final breakdowns = truckIds != null
        ? allBreakdowns.where((b) => truckIds!.contains(b.truckId)).toList()
        : allBreakdowns;

    // Trier par date et prendre les 5 derniers
    final recentTrips = List<TripModel>.from(trips)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final lastTrips = recentTrips.take(5).toList();

    final recentBreakdowns = List<BreakdownReportModel>.from(breakdowns)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final lastBreakdowns = recentBreakdowns.take(5).toList();

    if (lastTrips.isEmpty && lastBreakdowns.isEmpty) {
      return Center(
        child: Text(
          l10n.translate('directionDashboard.noData'),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (lastTrips.isNotEmpty) ...[
          Text(
            l10n.translate('directionDashboard.recentTrips'),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...lastTrips.map(_buildTripRow),
        ],
        if (lastTrips.isNotEmpty && lastBreakdowns.isNotEmpty)
          const SizedBox(height: AppSpacing.lg),
        if (lastBreakdowns.isNotEmpty) ...[
          Text(
            l10n.translate('directionDashboard.recentBreakdowns'),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...lastBreakdowns.map(_buildBreakdownRow),
        ],
      ],
    );
  }

  Widget _buildTripRow(TripModel trip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                trip.truckImmatriculation,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                trip.driverName,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: 60,
              child: Text(
                trip.netTonnage != null
                    ? '${trip.netTonnage!.toStringAsFixed(1)} T'
                    : '-',
                style: const TextStyle(
                  color: AppColors.info,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.right,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _buildStatusBadge(trip.status.label, _tripStatusColor(trip.status)),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownRow(BreakdownReportModel breakdown) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                breakdown.truckImmatriculation,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                breakdown.description,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _buildStatusBadge(
              breakdown.severity.label,
              _severityColor(breakdown.severity),
            ),
            const SizedBox(width: AppSpacing.xs),
            _buildStatusBadge(
              breakdown.status.label,
              _breakdownStatusColor(breakdown.status),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _tripStatusColor(TripStatus status) {
    return switch (status) {
      TripStatus.inProgress => AppColors.info,
      TripStatus.pendingValidation => AppColors.warning,
      TripStatus.validated => AppColors.success,
      TripStatus.rejected => AppColors.error,
    };
  }

  Color _severityColor(BreakdownSeverity severity) {
    return switch (severity) {
      BreakdownSeverity.low => AppColors.info,
      BreakdownSeverity.medium => AppColors.warning,
      BreakdownSeverity.high => AppColors.error,
      BreakdownSeverity.critical => const Color(0xFFB71C1C),
    };
  }

  Color _breakdownStatusColor(BreakdownStatus status) {
    return switch (status) {
      BreakdownStatus.pending => AppColors.warning,
      BreakdownStatus.inDiagnostic => AppColors.info,
      BreakdownStatus.inRepair => AppColors.primary,
      BreakdownStatus.resolved => AppColors.success,
      BreakdownStatus.closed => AppColors.textSecondary,
    };
  }
}
