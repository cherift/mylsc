import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../fleet/presentation/providers/fleet_providers.dart';
import '../../domain/models/trip_model.dart';
import '../providers/trip_providers.dart';
import 'trip_detail_widget.dart';

/// Widget affichant la liste des rotations avec onglets (à valider / toutes)
/// Si [fleetId] est fourni, filtre les rotations par les véhicules de la flotte.
class TripValidationListWidget extends ConsumerStatefulWidget {
  const TripValidationListWidget({super.key, this.fleetId});

  final String? fleetId;

  @override
  ConsumerState<TripValidationListWidget> createState() =>
      _TripValidationListWidgetState();
}

class _TripValidationListWidgetState
    extends ConsumerState<TripValidationListWidget> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        _buildTabBar(l10n),
        Expanded(
          child: _selectedTab == 0
              ? _buildPendingList(l10n)
              : _buildAllList(l10n),
        ),
      ],
    );
  }

  Widget _buildTabBar(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: AppColors.backgroundSecondary,
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceBorder),
        ),
      ),
      child: Row(
        children: [
          _buildTab(
            l10n.translate('trip.pendingTrips'),
            0,
            Iconsax.clock,
          ),
          const SizedBox(width: AppSpacing.sm),
          _buildTab(
            l10n.translate('trip.allTrips'),
            1,
            Iconsax.routing,
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index, IconData icon) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedTab = index),
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Récupère les IDs des véhicules de la flotte (si fleetId fourni)
  Set<String>? _getFleetTruckIds() {
    if (widget.fleetId == null) return null;
    final trucksAsync = ref.watch(fleetTrucksProvider(widget.fleetId!));
    return trucksAsync.whenOrNull(
      data: (trucks) => trucks.map((t) => t.id).toSet(),
    );
  }

  List<TripModel> _filterByFleet(List<TripModel> trips) {
    final truckIds = _getFleetTruckIds();
    if (truckIds == null) return trips;
    return trips.where((t) => truckIds.contains(t.truckId)).toList();
  }

  Widget _buildPendingList(AppLocalizations l10n) {
    final tripsAsync = ref.watch(pendingTripsStreamProvider);

    return tripsAsync.when(
      data: (allTrips) {
        final trips = _filterByFleet(allTrips);
        if (trips.isEmpty) {
          return _buildEmptyState(l10n);
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: trips.length,
          itemBuilder: (context, index) =>
              _buildTripCard(trips[index], l10n),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (error, _) => Center(
        child: Text('${l10n.translate('common.error')}: $error',
            style: const TextStyle(color: AppColors.error)),
      ),
    );
  }

  Widget _buildAllList(AppLocalizations l10n) {
    final tripsAsync = ref.watch(allTripsStreamProvider);

    return tripsAsync.when(
      data: (allTrips) {
        final trips = _filterByFleet(allTrips);
        if (trips.isEmpty) {
          return _buildEmptyState(l10n);
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: trips.length,
          itemBuilder: (context, index) =>
              _buildTripCard(trips[index], l10n),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (error, _) => Center(
        child: Text('${l10n.translate('common.error')}: $error',
            style: const TextStyle(color: AppColors.error)),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Iconsax.routing,
              size: 64, color: AppColors.textTertiary),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.translate('trip.noTrips'),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard(TripModel trip, AppLocalizations l10n) {
    final statusColor = switch (trip.status) {
      TripStatus.inProgress => AppColors.info,
      TripStatus.pendingValidation => AppColors.warning,
      TripStatus.validated => AppColors.success,
      TripStatus.rejected => AppColors.error,
    };

    final statusLabel = switch (trip.status) {
      TripStatus.inProgress => l10n.translate('trip.inProgress'),
      TripStatus.pendingValidation =>
        l10n.translate('trip.pendingValidation'),
      TripStatus.validated => l10n.translate('trip.validated'),
      TripStatus.rejected => l10n.translate('trip.rejected'),
    };

    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: const BorderSide(color: AppColors.surfaceBorder),
      ),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: () => _showTripDetail(trip),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Iconsax.truck,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      trip.truckImmatriculation,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Icon(Iconsax.driver,
                      color: AppColors.textSecondary, size: 16),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    trip.driverName,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  if (trip.netTonnage != null) ...[
                    const Icon(Iconsax.weight,
                        color: AppColors.primary, size: 16),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      trip.formattedNetTonnage,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Iconsax.clock,
                      color: AppColors.textSecondary, size: 16),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '${trip.formattedDate} ${trip.formattedTime}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    trip.isComplete
                        ? Iconsax.tick_circle
                        : Iconsax.clock,
                    color: trip.isComplete
                        ? AppColors.success
                        : AppColors.textTertiary,
                    size: 16,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    trip.isComplete
                        ? l10n.translate('trip.complete')
                        : l10n.translate('trip.incomplete'),
                    style: TextStyle(
                      color: trip.isComplete
                          ? AppColors.success
                          : AppColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTripDetail(TripModel trip) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.xl),
            ),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: TripDetailWidget(
              trip: trip,
              onUpdated: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ),
    );
  }
}
