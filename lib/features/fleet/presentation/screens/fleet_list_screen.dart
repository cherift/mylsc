import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../trucks/presentation/providers/truck_providers.dart';
import '../../../users/presentation/providers/user_management_providers.dart';
import '../../domain/models/fleet_model.dart';
import '../providers/fleet_providers.dart';
import '../widgets/fleet_form_dialog.dart';
import 'fleet_detail_screen.dart';

class FleetListScreen extends ConsumerStatefulWidget {
  const FleetListScreen({super.key});

  @override
  ConsumerState<FleetListScreen> createState() => _FleetListScreenState();
}

class _FleetListScreenState extends ConsumerState<FleetListScreen> {
  FleetModel? _selectedFleet;

  @override
  Widget build(BuildContext context) {
    // Afficher le détail inline — la sidebar du dashboard reste visible
    if (_selectedFleet != null) {
      return FleetDetailScreen(
        fleet: _selectedFleet!,
        onBack: () => setState(() => _selectedFleet = null),
      );
    }

    final l10n = AppLocalizations.of(context);
    final fleetsAsync = ref.watch(allFleetsProvider);
    final trucksAsync = ref.watch(trucksStreamProvider);
    final usersAsync = ref.watch(usersStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          l10n.translate('fleet.title'),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: IconButton(
              icon: const Icon(Icons.add_circle, color: AppColors.primary),
              tooltip: l10n.translate('fleet.createFleet'),
              onPressed: () => _showCreateDialog(context),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppColors.surfaceBorder,
          ),
        ),
      ),
      body: fleetsAsync.when(
        data: (fleets) {
          if (fleets.isEmpty) {
            return _EmptyFleetsState(
              onCreate: () => _showCreateDialog(context),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.symmetric(
              horizontal: context.responsiveHorizontalPadding,
              vertical: AppSpacing.md,
            ),
            itemCount: fleets.length,
            itemBuilder: (context, index) {
              final fleet = fleets[index];

              final truckCount = trucksAsync.whenOrNull(
                    data: (trucks) =>
                        trucks.where((t) => t.fleetId == fleet.id).length,
                  ) ??
                  0;
              final driverCount = usersAsync.whenOrNull(
                    data: (users) =>
                        users.where((u) => u.fleetId == fleet.id).length,
                  ) ??
                  0;

              final allUsers = usersAsync.valueOrNull ?? [];
              final supervisor = allUsers
                  .where((u) => u.id == fleet.supervisorId)
                  .firstOrNull;

              return _FleetCard(
                fleet: fleet,
                supervisor: supervisor,
                truckCount: truckCount,
                driverCount: driverCount,
                onTap: () => setState(() => _selectedFleet = fleet),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text(
                      '${l10n.translate('common.error')}: $e',
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (_) => const FleetFormDialog(),
    );
  }
}

class _EmptyFleetsState extends StatelessWidget {
  const _EmptyFleetsState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: const Icon(
              Icons.local_shipping_outlined,
              size: 40,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.translate('fleet.noFleets'),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton.icon(
            onPressed: onCreate,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            icon: const Icon(Icons.add, color: Colors.white, size: 18),
            label: Text(
              l10n.translate('fleet.createFleet'),
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _FleetCard extends StatelessWidget {
  const _FleetCard({
    required this.fleet,
    required this.supervisor,
    required this.truckCount,
    required this.driverCount,
    required this.onTap,
  });

  final FleetModel fleet;
  final UserModel? supervisor;
  final int truckCount;
  final int driverCount;
  final VoidCallback onTap;

  String get _supervisorDisplay {
    if (supervisor == null) return '—';
    final name =
        supervisor!.fullName.isNotEmpty ? supervisor!.fullName : supervisor!.email;
    final matricule = supervisor!.matricule;
    return (matricule != null && matricule.isNotEmpty) ? '$name #$matricule' : name;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.surfaceBorder),
          boxShadow: AppShadows.subtle,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: const Icon(
                Icons.local_shipping,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fleet.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (fleet.description != null && fleet.description!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      fleet.description!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.badge_outlined,
                          size: 13, color: AppColors.textTertiary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${l10n.translate('fleet.supervisor')}: $_supervisorDisplay',
                          style: const TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _InfoChip(
                        icon: Icons.local_shipping_outlined,
                        label: '$truckCount ${l10n.translate('fleet.trucks')}',
                      ),
                      _InfoChip(
                        icon: Icons.people_outline,
                        label: '$driverCount ${l10n.translate('fleet.drivers')}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            const Icon(Icons.chevron_right,
                color: AppColors.textTertiary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.xs),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppColors.textTertiary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
