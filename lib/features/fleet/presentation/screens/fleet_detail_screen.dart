import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../fuel/presentation/widgets/fuel_request_detail_sheet.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../fuel/data/repositories/fuel_request_repository.dart';
import '../../../fuel/domain/models/fuel_request_model.dart';
import '../../../shifts/data/repositories/shift_repository.dart';
import '../../../trucks/domain/models/truck_model.dart';
import '../../../weighing/domain/models/weighing_record_model.dart';
import '../../../weighing/presentation/providers/weighing_providers.dart';
import '../../../weighing/presentation/widgets/weighing_detail_dialog.dart';
import '../../domain/models/fleet_model.dart';
import '../providers/fleet_providers.dart';
import '../widgets/assign_driver_dialog.dart';
import '../widgets/assign_truck_dialog.dart';
import '../widgets/fleet_form_dialog.dart';

/// Formate une date au format jj/mm/aaaa (pour affichage ET recherche).
String _formatSearchableDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

class FleetDetailScreen extends ConsumerWidget {
  const FleetDetailScreen({
    required this.fleet,
    super.key,
    this.onBack,
  });

  final FleetModel fleet;

  /// Si fourni, remplace le bouton retour natif (navigation inline sans push).
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundSecondary,
          leading: onBack != null
              ? IconButton(
                  icon: const Icon(Icons.arrow_back,
                      color: AppColors.textSecondary),
                  onPressed: onBack,
                )
              : null,
          elevation: 0,
          title: Text(
            fleet.name,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary),
              tooltip: l10n.translate('fleet.editFleet'),
              onPressed: () => showDialog<bool>(
                context: context,
                builder: (_) => FleetFormDialog(fleet: fleet),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              tooltip: l10n.translate('fleet.deleteFleet'),
              onPressed: () => _confirmDeleteFleet(context, ref, l10n, fleet),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.surfaceBorder),
                ),
              ),
              child: TabBar(
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textTertiary,
                labelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                tabs: [
                  Tab(
                    icon: const Icon(Icons.local_shipping_outlined, size: 18),
                    text: l10n.translate('fleet.trucks'),
                    iconMargin: const EdgeInsets.only(bottom: 2),
                  ),
                  Tab(
                    icon: const Icon(Icons.people_outline, size: 18),
                    text: l10n.translate('fleet.drivers'),
                    iconMargin: const EdgeInsets.only(bottom: 2),
                  ),
                  Tab(
                    icon: const Icon(Icons.local_gas_station_outlined, size: 18),
                    text: l10n.translate('fleet.fuelRequests'),
                    iconMargin: const EdgeInsets.only(bottom: 2),
                  ),
                  Tab(
                    icon: const Icon(Icons.scale_outlined, size: 18),
                    text: l10n.translate('fleet.weighings'),
                    iconMargin: const EdgeInsets.only(bottom: 2),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _TrucksTab(fleetId: fleet.id),
            _DriversTab(fleetId: fleet.id),
            _FuelRequestsTab(fleetId: fleet.id),
            _WeighingsTab(fleetId: fleet.id),
          ],
        ),
      ),
    );
  }
}

/// Barre de recherche partagée par les 4 onglets de la flotte : filtre par
/// nom de l'élément (immatriculation, chauffeur...) ou par date (jj/mm/aaaa).
class _FleetTabSearchBar extends StatelessWidget {
  const _FleetTabSearchBar({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textTertiary),
          prefixIcon: const Icon(Icons.search,
              color: AppColors.textTertiary, size: 20),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close,
                      color: AppColors.textTertiary, size: 18),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.surfaceBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.surfaceBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}

Future<void> _confirmDeleteFleet(
  BuildContext context,
  WidgetRef ref,
  AppLocalizations l10n,
  FleetModel fleet,
) async {
  final repo = ref.read(fleetRepositoryProvider);
  final dependency = await repo.checkFleetDependencies(fleet.id);

  if (!context.mounted) return;

  if (dependency != null) {
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.translate('fleet.deleteBlocked')),
        content: Text(
          dependency == 'trucks'
              ? l10n.translate('fleet.deleteBlockedTrucks')
              : l10n.translate('fleet.deleteBlockedDrivers'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.translate('common.ok')),
          ),
        ],
      ),
    );
    return;
  }

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(l10n.translate('fleet.deleteFleet')),
      content: Text(l10n.translate('fleet.deleteFleetConfirm')
          .replaceFirst('%s', fleet.name)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.translate('common.cancel')),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.translate('common.delete')),
        ),
      ],
    ),
  );

  if ((confirmed ?? false) && context.mounted) {
    await repo.deleteFleet(fleet.id);
    if (context.mounted) Navigator.of(context).pop();
  }
}

// ============ ONGLET VÉHICULES ============

class _TrucksTab extends ConsumerStatefulWidget {
  const _TrucksTab({required this.fleetId});
  final String fleetId;

  @override
  ConsumerState<_TrucksTab> createState() => _TrucksTabState();
}

class _TrucksTabState extends ConsumerState<_TrucksTab> {
  static const _pageSize = 20;

  final _searchController = TextEditingController();
  String _query = '';
  int _currentPage = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _statusColor(TruckStatus status) {
    switch (status) {
      case TruckStatus.enService:
        return AppColors.success;
      case TruckStatus.enMaintenance:
        return AppColors.warning;
      case TruckStatus.enPanne:
        return AppColors.error;
      case TruckStatus.immobilise:
        return AppColors.textTertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final trucksAsync = ref.watch(fleetTrucksProvider(widget.fleetId));

    return trucksAsync.when(
      data: (allTrucks) {
        final q = _query.trim().toLowerCase();
        final trucks = q.isEmpty
            ? allTrucks
            : allTrucks.where((t) {
                return t.immatriculation.toLowerCase().contains(q) ||
                    t.numeroInterneFlotte.toLowerCase().contains(q) ||
                    _formatSearchableDate(t.createdAt).contains(q);
              }).toList();

        final totalPages =
            trucks.isEmpty ? 1 : (trucks.length / _pageSize).ceil();
        final page = _currentPage >= totalPages ? totalPages - 1 : _currentPage;
        final pageItems =
            trucks.skip(page * _pageSize).take(_pageSize).toList();

        return Stack(
          children: [
            Column(
              children: [
                _FleetTabSearchBar(
                  controller: _searchController,
                  hint: l10n.translate('fleet.searchByNameOrDate'),
                  onChanged: (v) => setState(() {
                    _query = v;
                    _currentPage = 0;
                  }),
                ),
                Expanded(
                  child: allTrucks.isEmpty
                      ? _EmptyState(
                          icon: Icons.local_shipping_outlined,
                          message: l10n.translate('fleet.noTrucksInFleet'),
                        )
                      : trucks.isEmpty
                          ? _EmptyState(
                              icon: Icons.search_off,
                              message: l10n.translate('fleet.noSearchResults'),
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 8, 16, 88),
                              itemCount: pageItems.length,
                              itemBuilder: (context, index) {
                                final truck = pageItems[index];
                                final statusColor = _statusColor(truck.statut);
                                return _TruckCard(
                                  truck: truck,
                                  statusColor: statusColor,
                                  unassignTooltip:
                                      l10n.translate('fleet.unassign'),
                                  onUnassign: () async {
                                    final repo =
                                        ref.read(fleetRepositoryProvider);
                                    await repo
                                        .unassignTruckFromFleet(truck.id);
                                  },
                                );
                              },
                            ),
                ),
                if (trucks.isNotEmpty && totalPages > 1)
                  _PaginationBar(
                    currentPage: page,
                    totalPages: totalPages,
                    onPrevious: page > 0
                        ? () => setState(() => _currentPage = page - 1)
                        : null,
                    onNext: page < totalPages - 1
                        ? () => setState(() => _currentPage = page + 1)
                        : null,
                  ),
              ],
            ),
            Positioned(
              bottom: trucks.isNotEmpty && totalPages > 1 ? 84 : 20,
              right: 16,
              child: FloatingActionButton(
                heroTag: 'trucks_fab_${widget.fleetId}',
                backgroundColor: AppColors.primary,
                onPressed: () => showDialog<bool>(
                  context: context,
                  builder: (_) => AssignTruckDialog(fleetId: widget.fleetId),
                ),
                tooltip: l10n.translate('fleet.assignTruck'),
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, _) => Center(
        child: Text('Erreur: $e', style: const TextStyle(color: AppColors.error)),
      ),
    );
  }
}

class _TruckCard extends StatelessWidget {
  const _TruckCard({
    required this.truck,
    required this.statusColor,
    required this.unassignTooltip,
    required this.onUnassign,
  });

  final TruckModel truck;
  final Color statusColor;
  final String unassignTooltip;
  final VoidCallback onUnassign;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.surfaceBorder),
        boxShadow: AppShadows.subtle,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status-colored truck icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: statusColor.withValues(alpha: 0.3),
                ),
              ),
              child: Icon(
                Icons.local_shipping,
                color: statusColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            // Info block
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          truck.immatriculation,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _StatusBadge(label: truck.statut.label, color: statusColor),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${truck.marque} ${truck.modele}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _InfoChip(
                        icon: Icons.tag,
                        label: '#${truck.numeroInterneFlotte}',
                      ),
                      const SizedBox(width: 6),
                      _InfoChip(
                        icon: Icons.category_outlined,
                        label: truck.type.label,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Unassign button
            IconButton(
              icon: const Icon(
                Icons.remove_circle_outline,
                color: AppColors.error,
                size: 20,
              ),
              tooltip: unassignTooltip,
              onPressed: onUnassign,
            ),
          ],
        ),
      ),
    );
  }
}

// ============ ONGLET CHAUFFEURS ============

class _DriversTab extends ConsumerStatefulWidget {
  const _DriversTab({required this.fleetId});
  final String fleetId;

  @override
  ConsumerState<_DriversTab> createState() => _DriversTabState();
}

class _DriversTabState extends ConsumerState<_DriversTab> {
  static const _pageSize = 20;

  final _searchController = TextEditingController();
  String _query = '';
  int _currentPage = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final driversAsync = ref.watch(fleetDriversProvider(widget.fleetId));

    return driversAsync.when(
      data: (allDrivers) {
        final q = _query.trim().toLowerCase();
        final drivers = q.isEmpty
            ? allDrivers
            : allDrivers.where((d) {
                return d.fullName.toLowerCase().contains(q) ||
                    (d.matricule?.toLowerCase().contains(q) ?? false) ||
                    _formatSearchableDate(d.createdAt).contains(q);
              }).toList();

        final totalPages =
            drivers.isEmpty ? 1 : (drivers.length / _pageSize).ceil();
        final page = _currentPage >= totalPages ? totalPages - 1 : _currentPage;
        final pageItems =
            drivers.skip(page * _pageSize).take(_pageSize).toList();

        return Stack(
          children: [
            Column(
              children: [
                _FleetTabSearchBar(
                  controller: _searchController,
                  hint: l10n.translate('fleet.searchByNameOrDate'),
                  onChanged: (v) => setState(() {
                    _query = v;
                    _currentPage = 0;
                  }),
                ),
                Expanded(
                  child: allDrivers.isEmpty
                      ? _EmptyState(
                          icon: Icons.people_outline,
                          message: l10n.translate('fleet.noDriversInFleet'),
                        )
                      : drivers.isEmpty
                          ? _EmptyState(
                              icon: Icons.search_off,
                              message: l10n.translate('fleet.noSearchResults'),
                            )
                          : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                itemCount: pageItems.length,
                itemBuilder: (context, index) {
                  final driver = pageItems[index];
                  final name = driver.fullName.isNotEmpty
                      ? driver.fullName
                      : driver.email;
                  final subtitle =
                      driver.matricule ?? driver.phoneNumber ?? '';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: AppColors.surfaceBorder),
                      boxShadow: AppShadows.subtle,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.full),
                            ),
                            child: Center(
                              child: Text(
                                driver.initials.isNotEmpty
                                    ? driver.initials
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (subtitle.isNotEmpty) ...[
                                  const SizedBox(height: 5),
                                  Row(
                                    children: [
                                      Icon(
                                        driver.matricule != null
                                            ? Icons.badge_outlined
                                            : Icons.phone_outlined,
                                        size: 13,
                                        color: AppColors.textTertiary,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        subtitle,
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              color: AppColors.error,
                              size: 20,
                            ),
                            tooltip: l10n.translate('fleet.unassign'),
                            onPressed: () async {
                              final repo = ref.read(fleetRepositoryProvider);
                              await repo.unassignDriverFromFleet(driver.id);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
                ),
                if (drivers.isNotEmpty && totalPages > 1)
                  _PaginationBar(
                    currentPage: page,
                    totalPages: totalPages,
                    onPrevious: page > 0
                        ? () => setState(() => _currentPage = page - 1)
                        : null,
                    onNext: page < totalPages - 1
                        ? () => setState(() => _currentPage = page + 1)
                        : null,
                  ),
              ],
            ),
            Positioned(
              bottom: drivers.isNotEmpty && totalPages > 1 ? 84 : 20,
              right: 16,
              child: FloatingActionButton(
                heroTag: 'drivers_fab_${widget.fleetId}',
                backgroundColor: AppColors.primary,
                onPressed: () => showDialog<bool>(
                  context: context,
                  builder: (_) =>
                      AssignDriverDialog(fleetId: widget.fleetId),
                ),
                tooltip: l10n.translate('fleet.assignDriver'),
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, _) => Center(
        child: Text('Erreur: $e', style: const TextStyle(color: AppColors.error)),
      ),
    );
  }
}

// ============ ONGLET DEMANDES CARBURANT ============

class _FuelRequestsTab extends ConsumerStatefulWidget {
  const _FuelRequestsTab({required this.fleetId});
  final String fleetId;

  @override
  ConsumerState<_FuelRequestsTab> createState() => _FuelRequestsTabState();
}

class _FuelRequestsTabState extends ConsumerState<_FuelRequestsTab> {
  static const _pageSize = 20;

  final _searchController = TextEditingController();
  String _query = '';
  int _currentPage = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final requestsAsync = ref.watch(fleetFuelRequestsProvider(widget.fleetId));

    return requestsAsync.when(
      data: (allRequests) {
        if (allRequests.isEmpty) {
          return _EmptyState(
            icon: Icons.local_gas_station_outlined,
            message: l10n.translate('fleet.noFuelRequests'),
          );
        }
        final q = _query.trim().toLowerCase();
        final requests = q.isEmpty
            ? allRequests
            : allRequests.where((r) {
                return r.truckImmatriculation.toLowerCase().contains(q) ||
                    (r.driverName?.toLowerCase().contains(q) ?? false) ||
                    _formatSearchableDate(r.createdAt).contains(q);
              }).toList();

        final totalPages =
            requests.isEmpty ? 1 : (requests.length / _pageSize).ceil();
        final page = _currentPage >= totalPages ? totalPages - 1 : _currentPage;
        final pageItems =
            requests.skip(page * _pageSize).take(_pageSize).toList();

        return Stack(
          children: [
            Column(
              children: [
                _FleetTabSearchBar(
                  controller: _searchController,
                  hint: l10n.translate('fleet.searchByNameOrDate'),
                  onChanged: (v) => setState(() {
                    _query = v;
                    _currentPage = 0;
                  }),
                ),
                Expanded(
                  child: requests.isEmpty
                      ? _EmptyState(
                          icon: Icons.search_off,
                          message: l10n.translate('fleet.noSearchResults'),
                        )
                      : ListView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(16, 8, 16, 88),
                          itemCount: pageItems.length,
                          itemBuilder: (context, index) =>
                              _FuelRequestCard(request: pageItems[index]),
                        ),
                ),
                if (requests.isNotEmpty && totalPages > 1)
                  _PaginationBar(
                    currentPage: page,
                    totalPages: totalPages,
                    onPrevious: page > 0
                        ? () => setState(() => _currentPage = page - 1)
                        : null,
                    onNext: page < totalPages - 1
                        ? () => setState(() => _currentPage = page + 1)
                        : null,
                  ),
              ],
            ),
            Positioned(
              bottom: requests.isNotEmpty && totalPages > 1 ? 84 : 20,
              right: 16,
              child: FloatingActionButton(
                heroTag: 'fuel_fab_${widget.fleetId.hashCode}',
                backgroundColor: AppColors.primary,
                onPressed: () => showDialog<bool>(
                  context: context,
                  builder: (_) =>
                      _CreateFuelRequestDialog(fleetId: widget.fleetId),
                ),
                tooltip: l10n.translate('fleet.createFuelRequest'),
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, _) => Center(
        child: Text('Erreur: $e', style: const TextStyle(color: AppColors.error)),
      ),
    );
  }
}

class _FuelRequestCard extends StatelessWidget {
  const _FuelRequestCard({required this.request});
  final FuelRequestModel request;

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'fulfilled':
        return AppColors.info;
      case 'validated':
        return AppColors.success;
      case 'disputed':
        return AppColors.error;
      case 'rejected':
        return AppColors.textTertiary;
      default:
        return AppColors.textTertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(request.status.name);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.surfaceBorder),
        boxShadow: AppShadows.subtle,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: status + date + info button
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: statusColor.withValues(alpha: 0.08),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                _StatusBadge(label: request.status.label, color: statusColor),
                const Spacer(),
                const Icon(
                  Icons.access_time_outlined,
                  size: 12,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${request.formattedDate}  ${request.formattedTime}',
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () =>
                      FuelRequestDetailSheet.show(context, request),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.open_in_new_rounded,
                            color: AppColors.primary, size: 11),
                        SizedBox(width: 4),
                        Text(
                          'Détails',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.surfaceBorder),
          // Body
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Truck + liters row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(color: AppColors.surfaceBorder),
                      ),
                      child: const Icon(
                        Icons.local_shipping_outlined,
                        color: AppColors.textSecondary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.truckImmatriculation,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            request.requestedByName,
                            style: const TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Liters block
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              request.requestedLiters.toStringAsFixed(0),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Text(
                              'L dem.',
                              style: TextStyle(
                                color: AppColors.textTertiary,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        if (request.fulfilledLiters != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                request.fulfilledLiters!
                                    .toStringAsFixed(0),
                                style: const TextStyle(
                                  color: AppColors.info,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Text(
                                'L servis',
                                style: TextStyle(
                                  color: AppColors.textTertiary,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                // Fulfilled by
                if (request.fulfilledByName != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 13,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Servi par ${request.fulfilledByName}',
                        style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
                // Verification code
                if (request.verificationCode != null &&
                    request.verificationCode!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1F3A),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(
                        color: const Color(0xFF4B3F8A).withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.pin,
                          size: 14,
                          color: Color(0xFF9B87D4),
                        ),
                        const SizedBox(width: 7),
                        const Text(
                          'Code : ',
                          style: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          request.verificationCode!,
                          style: const TextStyle(
                            color: Color(0xFF9B87D4),
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            letterSpacing: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // Receipt photo
                if (request.receiptPhotoUrl != null &&
                    request.receiptPhotoUrl!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () =>
                        _showReceiptPhoto(context, request.receiptPhotoUrl!),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: Image.network(
                        request.receiptPhotoUrl!,
                        height: 110,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            height: 110,
                            color: AppColors.surface,
                            child: const Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.primary),
                            ),
                          );
                        },
                        errorBuilder: (_, __, ___) => Container(
                          height: 110,
                          color: AppColors.surface,
                          child: const Center(
                            child: Icon(Icons.broken_image_outlined,
                                color: AppColors.textSecondary),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showReceiptPhoto(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppColors.backgroundSecondary,
        child: InteractiveViewer(
          child: Image.network(url),
        ),
      ),
    );
  }
}

// ============ ONGLET PESÉE ============

class _WeighingsTab extends ConsumerStatefulWidget {
  const _WeighingsTab({required this.fleetId});
  final String fleetId;

  @override
  ConsumerState<_WeighingsTab> createState() => _WeighingsTabState();
}

class _WeighingsTabState extends ConsumerState<_WeighingsTab> {
  static const _pageSize = 20;

  final _searchController = TextEditingController();
  String _query = '';
  int _currentPage = 0;

  // Ajout manuel d'un véhicule de la flotte à la vue (redondant avec le
  // jeu par défaut mais garde le mécanisme pour usage futur/explicite).
  // Restreint aux véhicules de CETTE flotte uniquement — pas d'accès aux
  // véhicules d'autres flottes depuis cet écran.
  final Set<String> _extraTruckIds = {};
  final Map<String, TruckModel> _extraTrucksById = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _statusColor(WeighingStatus status) {
    switch (status) {
      case WeighingStatus.pending:
        return AppColors.warning;
      case WeighingStatus.recorded:
      case WeighingStatus.loaded:
      case WeighingStatus.unloaded:
        return AppColors.info;
      case WeighingStatus.validated:
        return AppColors.success;
      case WeighingStatus.rejected:
        return AppColors.error;
    }
  }

  // Restreint aux véhicules de CETTE flotte uniquement (pas d'accès aux
  // véhicules d'autres flottes depuis cet écran).
  Future<void> _addExtraTruck(List<TruckModel> fleetTrucks) async {
    final result = await showDialog<TruckModel>(
      context: context,
      builder: (context) => _FleetTruckSearchDialog(trucks: fleetTrucks),
    );
    if (result != null) {
      setState(() {
        _extraTruckIds.add(result.id);
        _extraTrucksById[result.id] = result;
        _currentPage = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fleetTrucksAsync = ref.watch(fleetTrucksProvider(widget.fleetId));
    final weighingsAsync = ref.watch(allWeighingsStreamProvider);

    return fleetTrucksAsync.when(
      data: (fleetTrucks) {
        final truckIds = {
          ...fleetTrucks.map((t) => t.id),
          ..._extraTruckIds,
        };

        return weighingsAsync.when(
          data: (allWeighings) {
            final fleetWeighings =
                allWeighings.where((w) => truckIds.contains(w.truckId)).toList()
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

            final q = _query.trim().toLowerCase();
            final weighings = q.isEmpty
                ? fleetWeighings
                : fleetWeighings.where((w) {
                    return w.truckImmatriculation.toLowerCase().contains(q) ||
                        (w.driverName?.toLowerCase().contains(q) ?? false) ||
                        _formatSearchableDate(w.createdAt).contains(q);
                  }).toList();

            final totalPages =
                weighings.isEmpty ? 1 : (weighings.length / _pageSize).ceil();
            final page = _currentPage >= totalPages
                ? totalPages - 1
                : _currentPage;
            final pageItems = weighings
                .skip(page * _pageSize)
                .take(_pageSize)
                .toList();

            return Column(
              children: [
                _FleetTabSearchBar(
                  controller: _searchController,
                  hint: l10n.translate('fleet.searchByNameOrDate'),
                  onChanged: (v) => setState(() {
                    _query = v;
                    _currentPage = 0;
                  }),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ..._extraTruckIds.map((id) {
                        final truck = _extraTrucksById[id];
                        return Chip(
                          label: Text(truck?.immatriculation ?? id),
                          onDeleted: () => setState(() {
                            _extraTruckIds.remove(id);
                            _extraTrucksById.remove(id);
                            _currentPage = 0;
                          }),
                        );
                      }),
                      ActionChip(
                        avatar: const Icon(Icons.add, size: 16),
                        label: Text(
                            l10n.translate('fleet.addOtherVehicle')),
                        onPressed: () => _addExtraTruck(fleetTrucks),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: fleetWeighings.isEmpty
                      ? _EmptyState(
                          icon: Icons.scale_outlined,
                          message: l10n.translate('fleet.noWeighingsInFleet'),
                        )
                      : weighings.isEmpty
                          ? _EmptyState(
                              icon: Icons.search_off,
                              message: l10n.translate('fleet.noSearchResults'),
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 8, 16, 16),
                              itemCount: pageItems.length,
                              itemBuilder: (context, index) {
                                final w = pageItems[index];
                                return _WeighingCard(
                                  weighing: w,
                                  statusColor: _statusColor(w.status),
                                );
                              },
                            ),
                ),
                if (weighings.isNotEmpty && totalPages > 1)
                  _PaginationBar(
                    currentPage: page,
                    totalPages: totalPages,
                    onPrevious: page > 0
                        ? () => setState(() => _currentPage = page - 1)
                        : null,
                    onNext: page < totalPages - 1
                        ? () => setState(() => _currentPage = page + 1)
                        : null,
                  ),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, _) => Center(
            child:
                Text('Erreur: $e', style: const TextStyle(color: AppColors.error)),
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, _) => Center(
        child: Text('Erreur: $e', style: const TextStyle(color: AppColors.error)),
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.currentPage,
    required this.totalPages,
    required this.onPrevious,
    required this.onNext,
  });

  final int currentPage;
  final int totalPages;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.surfaceBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left),
            color: AppColors.primary,
            disabledColor: AppColors.textTertiary,
          ),
          Text(
            l10n
                .translate('fleet.pageIndicator')
                .replaceAll('{current}', '${currentPage + 1}')
                .replaceAll('{total}', '$totalPages'),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right),
            color: AppColors.primary,
            disabledColor: AppColors.textTertiary,
          ),
        ],
      ),
    );
  }
}

class _WeighingCard extends StatelessWidget {
  const _WeighingCard({required this.weighing, required this.statusColor});

  final WeighingRecordModel weighing;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => WeighingDetailDialog(record: weighing),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.surfaceBorder),
          boxShadow: AppShadows.subtle,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border:
                      Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Icon(Icons.scale, color: statusColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            weighing.truckImmatriculation,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusBadge(
                            label: weighing.status.label, color: statusColor),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${weighing.location.label} • ${weighing.formattedDate} ${weighing.formattedTime}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    if (weighing.driverName != null) ...[
                      const SizedBox(height: 8),
                      _InfoChip(
                          icon: Icons.person_outline,
                          label: weighing.driverName!),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: AppColors.textTertiary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ============ SHARED WIDGETS ============

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
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
            child: Icon(icon, size: 38, color: AppColors.textTertiary),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
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

// ============ DIALOG CRÉATION DEMANDE CARBURANT ============

class _CreateFuelRequestDialog extends ConsumerStatefulWidget {
  const _CreateFuelRequestDialog({required this.fleetId});
  final String fleetId;

  @override
  ConsumerState<_CreateFuelRequestDialog> createState() =>
      _CreateFuelRequestDialogState();
}

class _CreateFuelRequestDialogState
    extends ConsumerState<_CreateFuelRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _litersController = TextEditingController();
  final _reasonController = TextEditingController();
  TruckModel? _selectedTruck;
  bool _isLoading = false;

  @override
  void dispose() {
    _litersController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTruck == null) return;

    setState(() => _isLoading = true);

    try {
      final authState = ref.read(authControllerProvider);
      final user = authState.valueOrNull;
      if (user == null) return;

      // Chercher la vacation active du camion
      final activeShift = await ShiftRepository()
          .getActiveShiftForTruck(_selectedTruck!.id);

      final repo = FuelRequestRepository();
      final liters = double.tryParse(_litersController.text.trim()) ?? 0;
      final result = await repo.createRequest(
        truckId: _selectedTruck!.id,
        truckImmatriculation: _selectedTruck!.immatriculation,
        truckFleetNumber: _selectedTruck!.numeroInterneFlotte,
        requestedBy: user.id,
        requestedByName:
            user.fullName.isNotEmpty ? user.fullName : user.email,
        requestedLiters: liters,
        reason: _reasonController.text.trim().isEmpty
            ? null
            : _reasonController.text.trim(),
        fleetId: widget.fleetId,
        shiftId: activeShift?.id,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        if (!context.mounted) return;
        final loc = AppLocalizations.of(context);
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
            title: Text(loc.translate('fleet.requestCreated')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(loc.translate('fleet.verificationCodeLabel')),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    result.verificationCode ?? '',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  loc.translate('fleet.verificationCodeHint'),
                  style: Theme.of(ctx).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(loc.translate('common.ok')),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final trucksAsync = ref.watch(fleetTrucksProvider(widget.fleetId));

    return AlertDialog(
      title: Text(l10n.translate('fleet.createFuelRequest')),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sélection du véhicule
              trucksAsync.when(
                data: (trucks) {
                  return InkWell(
                    onTap: () async {
                      if (trucks.isEmpty) return;
                      final result = await showDialog<TruckModel>(
                        context: context,
                        builder: (context) =>
                            _FleetTruckSearchDialog(trucks: trucks),
                      );
                      if (result != null) {
                        setState(() => _selectedTruck = result);
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: l10n.translate('fleet.selectTruck'),
                        border: const OutlineInputBorder(),
                        suffixIcon: const Icon(Icons.search),
                        errorText: _selectedTruck == null &&
                                _formKey.currentState != null
                            ? null
                            : null,
                      ),
                      child: Text(
                        _selectedTruck?.immatriculation ??
                            l10n.translate('fleet.selectTruck'),
                        style: TextStyle(
                          color: _selectedTruck != null
                              ? null
                              : Theme.of(context).hintColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text('Erreur: $e'),
              ),
              const SizedBox(height: 16),
              // Quantité de carburant
              TextFormField(
                controller: _litersController,
                decoration: InputDecoration(
                  labelText: l10n.translate('fleet.requestedLiters'),
                  border: const OutlineInputBorder(),
                  suffixText: 'L',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.translate('fleet.litersRequired');
                  }
                  final liters = double.tryParse(value.trim());
                  if (liters == null || liters <= 0) {
                    return l10n.translate('fuelRequest.litersInvalid');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Motif (optionnel)
              TextFormField(
                controller: _reasonController,
                decoration: InputDecoration(
                  labelText: l10n.translate('fleet.fuelReason'),
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.translate('common.cancel')),
        ),
        ElevatedButton(
          onPressed:
              _isLoading || _selectedTruck == null ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.translate('common.create')),
        ),
      ],
    );
  }
}

// ============ DIALOG RECHERCHE VÉHICULE FLOTTE ============

class _FleetTruckSearchDialog extends StatefulWidget {
  const _FleetTruckSearchDialog({required this.trucks});
  final List<TruckModel> trucks;

  @override
  State<_FleetTruckSearchDialog> createState() =>
      _FleetTruckSearchDialogState();
}

class _FleetTruckSearchDialogState extends State<_FleetTruckSearchDialog> {
  final _searchController = TextEditingController();
  List<TruckModel> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.trucks;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filter(String query) {
    final q = query.toLowerCase();
    setState(() {
      _filtered = widget.trucks
          .where((t) =>
              t.immatriculation.toLowerCase().contains(q) ||
              t.displayName.toLowerCase().contains(q))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.translate('fleet.selectTruck')),
      content: SizedBox(
        width: 400,
        height: 400,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.translate('fleet.searchTruck'),
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
              onChanged: _filter,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _filtered.isEmpty
                  ? Center(
                      child:
                          Text(l10n.translate('fleet.noTrucksInFleet')),
                    )
                  : ListView.builder(
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) {
                        final t = _filtered[index];
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(t.immatriculation.isNotEmpty
                                ? t.immatriculation[0].toUpperCase()
                                : '?'),
                          ),
                          title: Text(
                            t.immatriculation,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            t.shortName,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => Navigator.of(context).pop(t),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.translate('common.cancel')),
        ),
      ],
    );
  }
}
