import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../fleet/domain/models/fleet_model.dart';
import '../../../fleet/presentation/providers/fleet_providers.dart';
import '../../../trucks/presentation/providers/truck_providers.dart';
import '../../../users/presentation/providers/user_management_providers.dart';

/// Section flottes avec cards par flotte (véhicules, chauffeurs)
class DirectionFleetsSection extends ConsumerWidget {
  const DirectionFleetsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final fleetsAsync = ref.watch(allFleetsProvider);
    final trucksAsync = ref.watch(trucksStreamProvider);
    final usersAsync = ref.watch(usersStreamProvider);

    final fleets = fleetsAsync.valueOrNull ?? [];
    final trucks = trucksAsync.valueOrNull ?? [];
    final users = usersAsync.valueOrNull ?? [];

    if (fleets.isEmpty) {
      return Center(
        child: Text(
          l10n.translate('directionDashboard.noData'),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: fleets.map((fleet) {
        final fleetTrucks = trucks.where((t) => t.fleetId == fleet.id).length;
        final fleetDrivers = users.where((u) => u.fleetId == fleet.id).length;
        final supervisor = users.where((u) => u.id == fleet.supervisorId).firstOrNull;

        return _buildFleetCard(fleet, fleetTrucks, fleetDrivers, supervisor);
      }).toList(),
    );
  }

  String _supervisorDisplay(UserModel? supervisor) {
    if (supervisor == null) return '—';
    final name = supervisor.fullName.isNotEmpty ? supervisor.fullName : supervisor.email;
    final matricule = supervisor.matricule;
    return (matricule != null && matricule.isNotEmpty) ? '$name #$matricule' : name;
  }

  Widget _buildFleetCard(FleetModel fleet, int truckCount, int driverCount, UserModel? supervisor) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            fleet.name,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            _supervisorDisplay(supervisor),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(Iconsax.truck, size: 14, color: AppColors.info),
              const SizedBox(width: 4),
              Text(
                '$truckCount',
                style: const TextStyle(
                  color: AppColors.info,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              const Icon(Iconsax.people, size: 14, color: AppColors.success),
              const SizedBox(width: 4),
              Text(
                '$driverCount',
                style: const TextStyle(
                  color: AppColors.success,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
