import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../../core/utils/pdf_utils.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/user_avatar_widget.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../inspection/presentation/widgets/inspection_form_widget.dart';
import '../../../shifts/presentation/widgets/shift_start_widget.dart';
import '../../../shifts/presentation/providers/shift_providers.dart';
import '../../../shifts/domain/models/driver_assignment_model.dart';
import '../../../shifts/domain/models/shift_model.dart';
import '../../../breakdown/presentation/widgets/breakdown_alert_widget.dart';
import '../../../dashboard/presentation/widgets/dashboard_section_card.dart';
import '../../../dashboard/presentation/widgets/direction_kpi_row.dart';
import '../../../dashboard/presentation/widgets/direction_vehicles_section.dart';
import '../../../dashboard/presentation/widgets/direction_tonnage_section.dart';
import '../../../dashboard/presentation/widgets/direction_fuel_section.dart';
import '../../../dashboard/presentation/widgets/direction_breakdowns_section.dart';
import '../../../fuel/domain/models/fuel_request_model.dart';
import '../../../fuel/data/repositories/fuel_request_repository.dart';
import '../../../fuel/presentation/screens/fuel_report_screen.dart';
import '../../../fuel/presentation/widgets/fuel_request_detail_sheet.dart';
import '../../../weighing/domain/models/weighing_record_model.dart';
import '../../../fleet/domain/models/fleet_model.dart';
import '../../../fleet/presentation/providers/fleet_providers.dart';
import '../../../fleet/presentation/widgets/assign_truck_dialog.dart';
import '../../../fleet/presentation/widgets/assign_driver_dialog.dart';
import '../widgets/driver_form_dialog.dart';
import '../../../trucks/domain/models/truck_model.dart';
import '../../../trucks/presentation/providers/truck_providers.dart';
import '../../../dashboard/domain/models/dashboard_filter.dart';
import '../../../../core/widgets/dashboard_filter_modal.dart';
import '../../../weighing/presentation/providers/weighing_providers.dart';

/// Dashboard du superviseur de flotte - intégré dans le dashboard principal
class FleetSupervisorDashboardScreen extends ConsumerStatefulWidget {
  const FleetSupervisorDashboardScreen({super.key});

  @override
  ConsumerState<FleetSupervisorDashboardScreen> createState() =>
      _FleetSupervisorDashboardScreenState();
}

class _FleetSupervisorDashboardScreenState
    extends ConsumerState<FleetSupervisorDashboardScreen> {
  FleetModel? _selectedFleet;
  int? _selectedAction;
  ShiftModel? _selectedShift;
  String _truckSearch = '';
  // Filtre historique des vacations (onglet "Période & Historique")
  DateTime _shiftHistoryStartDate =
      DateTime.now().subtract(const Duration(days: 30));
  DateTime _shiftHistoryEndDate = DateTime.now();
  final Set<String> _shiftHistorySelectedTruckIds = {};
  bool _shiftHistorySelectAll = true;
  bool _shiftHistoryGenerated = false;
  // Filtre de la vue d'ensemble (date + camions de la flotte)
  DashboardFilter _overviewFilter = const DashboardFilter();

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final l10n = AppLocalizations.of(context);
    final userId = authState.valueOrNull?.id;

    if (userId == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_selectedFleet == null) {
      return _buildFleetList(l10n, userId);
    }

    if (_selectedAction == null) {
      return _buildFleetHome(l10n);
    }

    return _buildActionContent(l10n, userId);
  }

  // ═══════════════════════════════════════════════════════════════
  // NIVEAU 1 — Liste des flottes du superviseur
  // ═══════════════════════════════════════════════════════════════

  Widget _buildFleetList(AppLocalizations l10n, String userId) {
    final fleetsAsync = ref.watch(fleetsBySupervisorProvider(userId));

    return fleetsAsync.when(
      data: (fleets) {
        if (fleets.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Iconsax.truck_fast,
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                    size: 64),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.translate('fleet.noFleets'),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: fleets.length,
          itemBuilder: (context, index) {
            final fleet = fleets[index];
            return _buildFleetCard(fleet, l10n);
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, _) => Center(
        child: Text('${l10n.translate('common.error')}: $e',
            style: const TextStyle(color: AppColors.error)),
      ),
    );
  }

  Widget _buildFleetCard(FleetModel fleet, AppLocalizations l10n) {
    final trucksAsync = ref.watch(fleetTrucksProvider(fleet.id));
    final driversAsync = ref.watch(fleetDriversProvider(fleet.id));

    final truckCount = trucksAsync.whenOrNull(data: (t) => t.length) ?? 0;
    final driverCount = driversAsync.whenOrNull(data: (d) => d.length) ?? 0;

    return GestureDetector(
      onTap: () => setState(() => _selectedFleet = fleet),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(
                Iconsax.truck_fast,
                color: Colors.white,
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
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (fleet.description != null &&
                      fleet.description!.isNotEmpty) ...[
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
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      _buildStatChip(
                          Iconsax.truck, '$truckCount', AppColors.primary),
                      const SizedBox(width: AppSpacing.sm),
                      _buildStatChip(
                          Iconsax.people, '$driverCount', AppColors.info),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Iconsax.arrow_right_3,
                color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // NIVEAU 2 — Accueil flotte (grille d'actions)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildFleetHome(AppLocalizations l10n) {
    final actions = [
      _ActionItem(
        icon: Iconsax.home,
        label: l10n.translate('fleet.overview'),
        color: AppColors.primary,
      ),
      _ActionItem(
        icon: Iconsax.search_status,
        label: l10n.translate('fleet.inspectionAction'),
        color: AppColors.warning,
      ),
      _ActionItem(
        icon: Iconsax.people,
        label: l10n.translate('fleet.assignmentAction'),
        color: const Color(0xFFEC4899),
      ),
      _ActionItem(
        icon: Iconsax.calendar_tick,
        label: l10n.translate('fleet.vacationAction'),
        color: const Color(0xFF8B5CF6),
      ),
      _ActionItem(
        icon: Iconsax.truck,
        label: l10n.translate('fleet.trucksAction'),
        color: AppColors.info,
      ),
      _ActionItem(
        icon: Iconsax.driver,
        label: l10n.translate('fleet.driversAction'),
        color: AppColors.success,
      ),
      _ActionItem(
        icon: Iconsax.gas_station,
        label: l10n.translate('fleet.fuelAction'),
        color: AppColors.error,
      ),
      _ActionItem(
        icon: Iconsax.chart_21,
        label: l10n.translate('fuel.report'),
        color: const Color(0xFF06B6D4),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header avec retour
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _selectedFleet = null),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: const Icon(Iconsax.arrow_left,
                      color: AppColors.textPrimary, size: 18),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedFleet!.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (_selectedFleet!.description != null &&
                        _selectedFleet!.description!.isNotEmpty)
                      Text(
                        _selectedFleet!.description!,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
              _StorageNotificationBell(fleetId: _selectedFleet!.id),
            ],
          ),
        ),
        // Grille d'actions — responsive
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: context.responsiveColumns(mobile: 2, tablet: 3, desktop: 4),
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
            ),
            itemCount: actions.length,
            itemBuilder: (context, index) {
              final action = actions[index];
              final iconSize = context.responsiveIconSize(34);
              final boxSize = context.responsiveIconSize(60);
              return GestureDetector(
                onTap: () => setState(() => _selectedAction = index),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: boxSize,
                        height: boxSize,
                        decoration: BoxDecoration(
                          color: action.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Icon(action.icon, color: action.color, size: iconSize),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                        child: Text(
                          action.label,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // NIVEAU 3 — Contenu de l'action
  // ═══════════════════════════════════════════════════════════════

  Widget _buildActionContent(AppLocalizations l10n, String userId) {
    final actionLabels = [
      l10n.translate('fleet.overview'),
      l10n.translate('fleet.inspectionAction'),
      l10n.translate('fleet.assignmentAction'),
      l10n.translate('fleet.vacationAction'),
      l10n.translate('fleet.trucksAction'),
      l10n.translate('fleet.driversAction'),
      l10n.translate('fleet.fuelAction'),
      l10n.translate('fuel.report'),
    ];

    return Column(
      children: [
        // Header avec retour
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => setState(() {
                  _selectedShift = null;
                  _selectedAction = null;
                }),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: const Icon(Iconsax.arrow_left,
                      color: AppColors.textPrimary, size: 18),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                actionLabels[_selectedAction!],
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const Divider(color: AppColors.surfaceBorder, height: 1),
        // Contenu
        Expanded(child: _buildActionWidget()),
      ],
    );
  }

  Widget _buildActionWidget() {
    switch (_selectedAction) {
      case 0:
        return _buildOverviewContent();
      case 1:
        return _buildInspectionContent();
      case 2:
        return _buildAssignmentContent();
      case 3:
        return _buildVacationsContent();
      case 4:
        return _buildTrucksContent();
      case 5:
        return _buildDriversContent();
      case 6:
        return _buildFuelRequestsContent();
      case 7:
        return FuelReportScreen(fleetId: _selectedFleet!.id);
      default:
        return const SizedBox();
    }
  }

  // ── Vue d'ensemble (dashboard filtré par flotte) ──

  void _openOverviewFilter(BuildContext context) {
    final trucks =
        ref.read(fleetTrucksProvider(_selectedFleet!.id)).valueOrNull ?? [];
    DashboardFilterModal.show(
      context,
      availableTrucks: trucks,
      currentFilter: _overviewFilter,
      onApply: (f) => setState(() => _overviewFilter = f),
    );
  }

  Widget _buildOverviewContent() {
    final l10n = AppLocalizations.of(context);
    final fid = _selectedFleet!.id;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bouton filtre aligné à droite
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilterIconButton(
                isActive: _overviewFilter.isActive,
                onTap: () => _openOverviewFilter(context),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const BreakdownAlertWidget(),
          const SizedBox(height: AppSpacing.lg),

          // KPI Row
          DirectionKpiRow(fleetId: fid, filter: _overviewFilter),
          const SizedBox(height: AppSpacing.xl),

          // Sections graphiques (responsive)
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;

              return Column(
                children: [
                  // Véhicules + Tonnage
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: DashboardSectionCard(
                            title: l10n.translate('directionDashboard.vehiclesSection'),
                            icon: Iconsax.truck,
                            child: DirectionVehiclesSection(fleetId: fid, filter: _overviewFilter),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: DashboardSectionCard(
                            title: l10n.translate('directionDashboard.tonnageSection'),
                            icon: Iconsax.weight,
                            child: DirectionTonnageSection(fleetId: fid, filter: _overviewFilter),
                          ),
                        ),
                      ],
                    )
                  else ...[
                    DashboardSectionCard(
                      title: l10n.translate('directionDashboard.vehiclesSection'),
                      icon: Iconsax.truck,
                      child: DirectionVehiclesSection(fleetId: fid, filter: _overviewFilter),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    DashboardSectionCard(
                      title: l10n.translate('directionDashboard.tonnageSection'),
                      icon: Iconsax.weight,
                      child: DirectionTonnageSection(fleetId: fid, filter: _overviewFilter),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),

                  // Carburant + Pannes
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _selectedAction = 6),
                            child: DashboardSectionCard(
                              title: l10n.translate(
                                  'directionDashboard.fuelSection'),
                              icon: Iconsax.gas_station,
                              child: DirectionFuelSection(fleetId: fid, filter: _overviewFilter),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: DashboardSectionCard(
                            title: l10n.translate(
                                'directionDashboard.breakdownsSection'),
                            icon: Iconsax.warning_2,
                            child: DirectionBreakdownsSection(fleetId: fid, filter: _overviewFilter),
                          ),
                        ),
                      ],
                    )
                  else ...[
                    GestureDetector(
                      onTap: () => setState(() => _selectedAction = 6),
                      child: DashboardSectionCard(
                        title: l10n
                            .translate('directionDashboard.fuelSection'),
                        icon: Iconsax.gas_station,
                        child: DirectionFuelSection(fleetId: fid, filter: _overviewFilter),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    DashboardSectionCard(
                      title: l10n.translate(
                          'directionDashboard.breakdownsSection'),
                      icon: Iconsax.warning_2,
                      child: DirectionBreakdownsSection(fleetId: fid, filter: _overviewFilter),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ── T.18 — Inspection avec recherche rapide ──

  Widget _buildInspectionContent() {
    final l10n = AppLocalizations.of(context);
    final trucksAsync = ref.watch(fleetTrucksProvider(_selectedFleet!.id));
    final searchController = TextEditingController();
    var searchQuery = '';

    return StatefulBuilder(
      builder: (context, setLocalState) {
        return trucksAsync.when(
          data: (trucks) {
            final filtered = searchQuery.isEmpty
                ? trucks
                : trucks.where((t) {
                    final q = searchQuery.toLowerCase();
                    return t.immatriculation.toLowerCase().contains(q) ||
                        t.numeroInterneFlotte.toLowerCase().contains(q);
                  }).toList();

            return Column(
              children: [
                // Barre de recherche rapide
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: SizedBox(
                    height: 40,
                    child: TextField(
                      controller: searchController,
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: l10n.translate('inspection.searchTruck'),
                        hintStyle: const TextStyle(
                            color: AppColors.textTertiary, fontSize: 13),
                        prefixIcon: const Icon(Iconsax.search_normal,
                            color: AppColors.textTertiary, size: 16),
                        suffixIcon: searchQuery.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  searchController.clear();
                                  setLocalState(() => searchQuery = '');
                                },
                                child: const Icon(Iconsax.close_circle,
                                    color: AppColors.textTertiary, size: 16),
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          borderSide: const BorderSide(
                              color: AppColors.surfaceBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          borderSide: const BorderSide(
                              color: AppColors.surfaceBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          borderSide: const BorderSide(
                              color: AppColors.warning, width: 1.5),
                        ),
                        filled: true,
                        fillColor: AppColors.background,
                      ),
                      onChanged: (v) => setLocalState(() => searchQuery = v),
                    ),
                  ),
                ),
                // Liste des camions filtrés → sélectionner pour inspecter
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            l10n.translate('fleet.noTrucksInFleet'),
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final truck = filtered[index];
                            final statusColor = switch (truck.statut) {
                              TruckStatus.enService => AppColors.success,
                              TruckStatus.enMaintenance => AppColors.warning,
                              TruckStatus.enPanne => AppColors.error,
                              TruckStatus.immobilise =>
                                AppColors.textSecondary,
                            };
                            return GestureDetector(
                              onTap: () => showModalBottomSheet<void>(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: AppColors.background,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(AppRadius.lg)),
                                ),
                                builder: (context) =>
                                    DraggableScrollableSheet(
                                  initialChildSize: 0.9,
                                  maxChildSize: 0.95,
                                  expand: false,
                                  builder: (context, scrollController) =>
                                      SingleChildScrollView(
                                    controller: scrollController,
                                    child: InspectionFormWidget(
                                      preselectedTruckId: truck.id,
                                    ),
                                  ),
                                ),
                              ),
                              child: Container(
                                margin: const EdgeInsets.only(
                                    bottom: AppSpacing.sm),
                                padding: const EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.md),
                                  border: Border.all(
                                      color: AppColors.surfaceBorder),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: statusColor
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(
                                            AppRadius.sm),
                                      ),
                                      child: Icon(Iconsax.search_status,
                                          color: statusColor, size: 20),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            truck.immatriculation,
                                            style: const TextStyle(
                                              color: AppColors.textPrimary,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            '${l10n.translate('trucks.fields.numeroInterne')}: ${truck.numeroInterneFlotte} • ${truck.statut.label}',
                                            style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Iconsax.arrow_right_3,
                                        color: AppColors.textSecondary,
                                        size: 16),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, _) => Center(
            child: Text('${l10n.translate('common.error')}: $e',
                style: const TextStyle(color: AppColors.error)),
          ),
        );
      },
    );
  }

  // ── Véhicules ──

  Widget _buildTrucksContent() {
    final l10n = AppLocalizations.of(context);
    final trucksAsync = ref.watch(fleetTrucksProvider(_selectedFleet!.id));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: SizedBox(
              height: 40,
              child: TextField(
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: l10n.translate('trucks.searchHint'),
                  hintStyle: const TextStyle(
                      color: AppColors.textTertiary, fontSize: 13),
                  prefixIcon: const Icon(Iconsax.search_normal,
                      color: AppColors.textTertiary, size: 16),
                  suffixIcon: _truckSearch.isNotEmpty
                      ? GestureDetector(
                          onTap: () =>
                              setState(() => _truckSearch = ''),
                          child: const Icon(Iconsax.close_circle,
                              color: AppColors.textTertiary, size: 16),
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    borderSide:
                        const BorderSide(color: AppColors.surfaceBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    borderSide:
                        const BorderSide(color: AppColors.surfaceBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    borderSide: const BorderSide(
                        color: AppColors.info, width: 1.5),
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                ),
                onChanged: (v) => setState(() => _truckSearch = v),
              ),
            ),
          ),
          Expanded(
            child: trucksAsync.when(
              data: (allTrucks) {
                final trucks = _truckSearch.isEmpty
                    ? allTrucks
                    : allTrucks.where((t) {
                        final q = _truckSearch.toLowerCase();
                        return t.immatriculation.toLowerCase().contains(q) ||
                            t.numeroInterneFlotte.toLowerCase().contains(q) ||
                            t.marque.toLowerCase().contains(q) ||
                            t.modele.toLowerCase().contains(q);
                      }).toList();

                if (trucks.isEmpty) {
                  return Center(
                    child: Text(
                      l10n.translate('fleet.noTrucksInFleet'),
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 16),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg),
                  itemCount: trucks.length,
                  itemBuilder: (context, index) {
                    final truck = trucks[index];
                    final statusColor = switch (truck.statut) {
                      TruckStatus.enService => AppColors.success,
                      TruckStatus.enMaintenance => AppColors.warning,
                      TruckStatus.enPanne => AppColors.error,
                      TruckStatus.immobilise => AppColors.textSecondary,
                    };
                    final assignmentsAsync = ref.watch(
                        assignmentsForTruckStreamProvider(truck.id));
                    return Container(
                      margin:
                          const EdgeInsets.only(bottom: AppSpacing.sm),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius:
                            BorderRadius.circular(AppRadius.md),
                        border:
                            Border.all(color: AppColors.surfaceBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: statusColor
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(
                                      AppRadius.md),
                                ),
                                child: Icon(Iconsax.truck,
                                    color: statusColor, size: 20),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      truck.immatriculation,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      '${l10n.translate('trucks.fields.numeroInterne')}: ${truck.numeroInterneFlotte} • ${truck.statut.label}',
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _buildHorsServiceButton(truck, l10n),
                            ],
                          ),
                          if (truck.horsServiceAt != null)
                            _buildHorsServiceBanner(truck, l10n),
                          assignmentsAsync.when(
                            data: (assignments) {
                              if (assignments.isEmpty) return const SizedBox();
                              return Padding(
                                padding: const EdgeInsets.only(
                                    top: AppSpacing.xs),
                                child: Wrap(
                                  spacing: AppSpacing.xs,
                                  children: assignments
                                      .map((a) => Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: AppSpacing.sm,
                                                    vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary
                                                  .withValues(alpha: 0.08),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      AppRadius.sm),
                                            ),
                                            child: Text(
                                              a.driverName,
                                              style: const TextStyle(
                                                color: AppColors.primary,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ))
                                      .toList(),
                                ),
                              );
                            },
                            loading: () => const SizedBox(),
                            error: (_, __) => const SizedBox(),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child:
                    CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => Center(
                child: Text('${l10n.translate('common.error')}: $e',
                    style: const TextStyle(color: AppColors.error)),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => showDialog<bool>(
          context: context,
          builder: (_) => AssignTruckDialog(fleetId: _selectedFleet!.id),
        ),
        tooltip: l10n.translate('fleet.assignTruck'),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // ── Chauffeurs ──

  Widget _buildDriversContent() {
    final l10n = AppLocalizations.of(context);
    final driversAsync = ref.watch(fleetDriversProvider(_selectedFleet!.id));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: driversAsync.when(
        data: (drivers) {
          if (drivers.isEmpty) {
            return Center(
              child: Text(
                l10n.translate('fleet.noDriversInFleet'),
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 16),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: drivers.length,
            itemBuilder: (context, index) {
              final driver = drivers[index];
              final assignmentsAsync = ref.watch(
                  activeAssignmentsForDriverProvider(driver.id));
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
                    // Avatar avec photo de profil si disponible
                    UserAvatarWidget(
                      radius: 24,
                      photoUrl: driver.photoUrl,
                      initials: driver.initials,
                      textColor: AppColors.primary,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            driver.fullName.isNotEmpty
                                ? driver.fullName
                                : driver.email,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            driver.matricule ?? driver.phoneNumber ?? '',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          assignmentsAsync.when(
                            data: (assignments) {
                              if (assignments.isEmpty) return const SizedBox();
                              return Wrap(
                                spacing: AppSpacing.xs,
                                children: assignments.map((a) {
                                  final rankColor = switch (a.driverRank) {
                                    DriverRank.principal => AppColors.primary,
                                    DriverRank.secondaire => AppColors.info,
                                    DriverRank.remplacant =>
                                      AppColors.textSecondary,
                                  };
                                  return Container(
                                    margin: const EdgeInsets.only(
                                        top: AppSpacing.xs),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.sm,
                                        vertical: 2),
                                    decoration: BoxDecoration(
                                      color:
                                          rankColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(
                                          AppRadius.sm),
                                    ),
                                    child: Text(
                                      '${a.truckImmatriculation} • ${l10n.translate(a.driverRank.i18nKey)}',
                                      style: TextStyle(
                                        color: rankColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                            loading: () => const SizedBox(),
                            error: (_, __) => const SizedBox(),
                          ),
                        ],
                      ),
                    ),
                    // Bouton Modifier
                    _DriverEditButton(
                      onTap: () async {
                        final result = await showDialog<bool>(
                          context: context,
                          builder: (_) => DriverFormDialog(
                            driver: driver,
                            fleetId: _selectedFleet!.id,
                          ),
                        );
                        if (result ?? false) {
                          ref.invalidate(
                              fleetDriversProvider(_selectedFleet!.id));
                        }
                      },
                    ),
                    const SizedBox.shrink(),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Text('${l10n.translate('common.error')}: $e',
              style: const TextStyle(color: AppColors.error)),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        tooltip: l10n.translate('fleet.assignDriver'),
        onPressed: () => showDialog<bool>(
          context: context,
          builder: (_) => AssignDriverDialog(fleetId: _selectedFleet!.id),
        ),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // ── Vacations ──

  Widget _buildVacationsContent() {
    if (_selectedShift != null) {
      return _buildShiftDetailView();
    }

    final l10n = AppLocalizations.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: TabBar(
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                tabs: [
                  Tab(
                    icon: const Icon(Iconsax.timer_start, size: 18),
                    text: l10n.translate('shift.ongoingTab'),
                  ),
                  Tab(
                    icon: const Icon(Iconsax.calendar, size: 18),
                    text: l10n.translate('shift.historyTab'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildOngoingShiftsTab(l10n),
                  _buildShiftHistoryTab(l10n),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: AppColors.primary,
          onPressed: _showNewShiftDialog,
          tooltip: l10n.translate('shift.newVacation'),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  // ── Onglet "Vacation en cours" ──

  Widget _buildOngoingShiftsTab(AppLocalizations l10n) {
    final shiftsAsync = ref.watch(shiftsForFleetProvider(_selectedFleet!.id));
    final trucksAsync = ref.watch(fleetTrucksProvider(_selectedFleet!.id));

    return shiftsAsync.when(
      data: (shifts) {
        final activeShifts =
            shifts.where((s) => s.status == ShiftStatus.active).toList();

        if (activeShifts.isEmpty) {
          return Center(
            child: Text(
              l10n.translate('shift.noActiveShiftsFleet'),
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 16),
            ),
          );
        }

        final trucks = trucksAsync.valueOrNull ?? [];
        final trucksById = {for (final t in trucks) t.id: t};

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: activeShifts.length,
          itemBuilder: (context, index) {
            final shift = activeShifts[index];
            return _buildOngoingShiftCard(
                shift, trucksById[shift.truckId], l10n);
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, _) => Center(
        child: Text('${l10n.translate('common.error')}: $e',
            style: const TextStyle(color: AppColors.error)),
      ),
    );
  }

  /// Carte d'une vacation en cours, colorée selon son état :
  /// rouge = camion passé en panne (inspection), jaune = pesée non encore
  /// enregistrée, vert = pesée déjà enregistrée.
  Widget _buildOngoingShiftCard(
      ShiftModel shift, TruckModel? truck, AppLocalizations l10n) {
    final weighingsAsync = ref.watch(weighingsByShiftProvider(shift.id));
    final hasWeighing = weighingsAsync.valueOrNull?.isNotEmpty ?? false;
    final isBrokenDown = truck?.statut == TruckStatus.enPanne;

    final statusColor = isBrokenDown
        ? AppColors.error
        : hasWeighing
            ? AppColors.success
            : AppColors.warning;
    final statusLabel = isBrokenDown
        ? l10n.translate('shift.statusBrokenDown')
        : hasWeighing
            ? l10n.translate('shift.statusWeighed')
            : l10n.translate('shift.statusPendingWeighing');

    final duration = shift.duration;
    final hours = duration?.inHours ?? 0;
    final minutes = (duration?.inMinutes ?? 0) % 60;

    return GestureDetector(
      onTap: () => setState(() => _selectedShift = shift),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: statusColor.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(Iconsax.timer_start, color: statusColor, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${shift.driverName} → ${shift.truckImmatriculation}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${shift.startTime.day.toString().padLeft(2, '0')}/${shift.startTime.month.toString().padLeft(2, '0')} ${shift.startTime.hour.toString().padLeft(2, '0')}:${shift.startTime.minute.toString().padLeft(2, '0')}'
                    ' • ${hours}h${minutes.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            const Icon(Iconsax.arrow_right_3,
                color: AppColors.textSecondary, size: 16),
          ],
        ),
      ),
    );
  }

  // ── Onglet "Période & Historique" ──

  Widget _buildShiftHistoryTab(AppLocalizations l10n) {
    final trucksAsync = ref.watch(fleetTrucksProvider(_selectedFleet!.id));
    final shiftsAsync = ref.watch(shiftsForFleetProvider(_selectedFleet!.id));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildShiftHistoryDateRangeSection(l10n),
          const SizedBox(height: AppSpacing.lg),
          _buildShiftHistoryTruckSelectionSection(l10n, trucksAsync),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () =>
                  setState(() => _shiftHistoryGenerated = true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              icon: const Icon(Iconsax.search_normal_1,
                  color: Colors.white, size: 18),
              label: Text(
                l10n.translate('shift.historySearch'),
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_shiftHistoryGenerated)
            _buildShiftHistoryResults(l10n, trucksAsync, shiftsAsync),
        ],
      ),
    );
  }

  Widget _buildShiftHistoryDateRangeSection(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Iconsax.calendar, color: AppColors.primary,
                  size: 18),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l10n.translate('shift.historyDateRange'),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                  child: _buildShiftHistoryDateButton(
                      _shiftHistoryStartDate, true)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Icon(Iconsax.arrow_right_1,
                    color: AppColors.textSecondary, size: 18),
              ),
              Expanded(
                  child: _buildShiftHistoryDateButton(
                      _shiftHistoryEndDate, false)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShiftHistoryDateButton(DateTime date, bool isStart) {
    final formatted =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

    return GestureDetector(
      onTap: () => _pickShiftHistoryDate(isStart),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isStart ? Iconsax.calendar_1 : Iconsax.calendar_tick,
              color: AppColors.primary,
              size: 16,
            ),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                formatted,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickShiftHistoryDate(bool isStart) async {
    final initial =
        isStart ? _shiftHistoryStartDate : _shiftHistoryEndDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            surface: AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _shiftHistoryStartDate = picked;
          if (_shiftHistoryStartDate.isAfter(_shiftHistoryEndDate)) {
            _shiftHistoryEndDate = _shiftHistoryStartDate;
          }
        } else {
          _shiftHistoryEndDate = picked;
          if (_shiftHistoryEndDate.isBefore(_shiftHistoryStartDate)) {
            _shiftHistoryStartDate = _shiftHistoryEndDate;
          }
        }
        _shiftHistoryGenerated = false;
      });
    }
  }

  Widget _buildShiftHistoryTruckSelectionSection(
      AppLocalizations l10n, AsyncValue<List<TruckModel>> trucksAsync) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Iconsax.truck, color: AppColors.info, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.translate('shift.historySelectVehicles'),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _shiftHistorySelectAll = !_shiftHistorySelectAll;
                    if (_shiftHistorySelectAll) {
                      _shiftHistorySelectedTruckIds.clear();
                    }
                    _shiftHistoryGenerated = false;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: 2),
                  decoration: BoxDecoration(
                    color: _shiftHistorySelectAll
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : AppColors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    _shiftHistorySelectAll
                        ? l10n.translate('trucks.all')
                        : '${_shiftHistorySelectedTruckIds.length}',
                    style: TextStyle(
                      color: _shiftHistorySelectAll
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          trucksAsync.when(
            data: (trucks) {
              if (trucks.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    l10n.translate('fleet.noTrucksInFleet'),
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                  ),
                );
              }

              return Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: trucks.map((truck) {
                  final isSelected = _shiftHistorySelectAll ||
                      _shiftHistorySelectedTruckIds.contains(truck.id);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_shiftHistorySelectAll) {
                          _shiftHistorySelectAll = false;
                          _shiftHistorySelectedTruckIds
                              .addAll(trucks.map((t) => t.id));
                          _shiftHistorySelectedTruckIds.remove(truck.id);
                        } else {
                          if (_shiftHistorySelectedTruckIds
                              .contains(truck.id)) {
                            _shiftHistorySelectedTruckIds.remove(truck.id);
                          } else {
                            _shiftHistorySelectedTruckIds.add(truck.id);
                          }
                          if (_shiftHistorySelectedTruckIds.length ==
                              trucks.length) {
                            _shiftHistorySelectAll = true;
                            _shiftHistorySelectedTruckIds.clear();
                          }
                        }
                        _shiftHistoryGenerated = false;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : AppColors.backgroundSecondary,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.4)
                              : AppColors.surfaceBorder,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isSelected
                                ? Iconsax.tick_square
                                : Iconsax.square,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            truck.immatriculation,
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: CircularProgressIndicator(
                    color: AppColors.primary, strokeWidth: 2),
              ),
            ),
            error: (e, _) => Text('$e',
                style:
                    const TextStyle(color: AppColors.error, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftHistoryResults(
    AppLocalizations l10n,
    AsyncValue<List<TruckModel>> trucksAsync,
    AsyncValue<List<ShiftModel>> shiftsAsync,
  ) {
    final trucks = trucksAsync.valueOrNull ?? [];
    final allShifts = shiftsAsync.valueOrNull ?? [];

    final startOfDay = DateTime(_shiftHistoryStartDate.year,
        _shiftHistoryStartDate.month, _shiftHistoryStartDate.day);
    final endOfDay = DateTime(_shiftHistoryEndDate.year,
        _shiftHistoryEndDate.month, _shiftHistoryEndDate.day, 23, 59, 59);

    final selectedIds = _shiftHistorySelectAll
        ? trucks.map((t) => t.id).toSet()
        : _shiftHistorySelectedTruckIds;

    final endedShifts = allShifts
        .where((s) => s.status == ShiftStatus.ended)
        .where((s) => selectedIds.contains(s.truckId))
        .where((s) =>
            !s.startTime.isBefore(startOfDay) &&
            !s.startTime.isAfter(endOfDay))
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));

    if (endedShifts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            l10n.translate('shift.noShiftsForPeriod'),
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ),
      );
    }

    // Regroupement par véhicule : nombre de vacations sur la période
    final countByTruck = <String, int>{};
    for (final shift in endedShifts) {
      countByTruck[shift.truckId] = (countByTruck[shift.truckId] ?? 0) + 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border:
                Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Iconsax.chart_2, color: AppColors.primary, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${l10n.translate('shift.historyTotal')}: ${endedShifts.length}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ...countByTruck.entries.map((entry) {
          final truck = trucks.firstWhere(
            (t) => t.id == entry.key,
            orElse: () => trucks.first,
          );
          final truckShifts =
              endedShifts.where((s) => s.truckId == entry.key).toList();
          return _buildShiftHistoryTruckGroup(
              truck, truckShifts, entry.value, l10n);
        }),
      ],
    );
  }

  Widget _buildShiftHistoryTruckGroup(TruckModel truck,
      List<ShiftModel> shifts, int count, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: ExpansionTile(
        tilePadding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        title: Text(
          truck.immatriculation,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${l10n.translate('shift.historyVehicleCount')}: $count',
          style:
              const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        children: shifts
            .map((s) => Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm),
                  child: _buildShiftCard(s, l10n, false),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildShiftCard(
      ShiftModel shift, AppLocalizations l10n, bool isActive) {
    final duration = shift.duration;
    final hours = duration?.inHours ?? 0;
    final minutes = (duration?.inMinutes ?? 0) % 60;

    return GestureDetector(
      onTap: () => setState(() => _selectedShift = shift),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
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
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (isActive ? AppColors.success : AppColors.textSecondary)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                isActive ? Iconsax.timer_start : Iconsax.timer_pause,
                color:
                    isActive ? AppColors.success : AppColors.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${shift.driverName} → ${shift.truckImmatriculation}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${shift.startTime.day.toString().padLeft(2, '0')}/${shift.startTime.month.toString().padLeft(2, '0')} ${shift.startTime.hour.toString().padLeft(2, '0')}:${shift.startTime.minute.toString().padLeft(2, '0')}'
                    ' • ${hours}h${minutes.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: 2),
              decoration: BoxDecoration(
                color: (isActive ? AppColors.success : AppColors.textSecondary)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                isActive
                    ? l10n.translate('shift.active')
                    : l10n.translate('shift.ended'),
                style: TextStyle(
                  color:
                      isActive ? AppColors.success : AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            const Icon(Iconsax.arrow_right_3,
                color: AppColors.textSecondary, size: 16),
          ],
        ),
      ),
    );
  }

  void _showNewShiftDialog() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          child: ShiftStartWidget(fleetId: _selectedFleet!.id),
        ),
      ),
    );
  }

  // ── Détail vacation ──

  Widget _buildShiftDetailView() {
    final l10n = AppLocalizations.of(context);
    final shift = _selectedShift!;
    final isActive = shift.status == ShiftStatus.active;
    final duration = shift.duration;
    final hours = duration?.inHours ?? 0;
    final minutes = (duration?.inMinutes ?? 0) % 60;

    final fuelAsync = ref.watch(fuelRequestsByShiftProvider(shift.id));
    final weighingsAsync = ref.watch(weighingsByShiftProvider(shift.id));

    return Column(
      children: [
        // Header retour
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              final titleRow = Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _selectedShift = null),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.surfaceBorder),
                      ),
                      child: const Icon(Iconsax.arrow_left,
                          color: AppColors.textPrimary, size: 18),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      l10n.translate('shift.shiftDetail'),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  IconButton(
                    icon:
                        const Icon(Iconsax.printer, color: AppColors.primary),
                    tooltip: l10n.translate('common.print'),
                    onPressed: () {
                      final fuel = fuelAsync.valueOrNull ?? [];
                      final weighings = weighingsAsync.valueOrNull ?? [];
                      final supervisor =
                          ref.read(authControllerProvider).valueOrNull;
                      _printShift(shift, fuel, weighings, supervisor, l10n);
                    },
                  ),
                  if (!isMobile && isActive) ...[
                    const SizedBox(width: AppSpacing.sm),
                    ElevatedButton.icon(
                      onPressed: () => _endShift(shift),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm),
                      ),
                      icon: const Icon(Iconsax.stop,
                          color: Colors.white, size: 16),
                      label: Text(
                        l10n.translate('shift.endShift'),
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ],
              );

              if (isMobile && isActive) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    titleRow,
                    const SizedBox(height: AppSpacing.sm),
                    ElevatedButton.icon(
                      onPressed: () => _endShift(shift),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.sm),
                      ),
                      icon: const Icon(Iconsax.stop,
                          color: Colors.white, size: 16),
                      label: Text(
                        l10n.translate('shift.endShift'),
                        style: const TextStyle(
                            color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ],
                );
              }
              return titleRow;
            },
          ),
        ),
        // Info vacation
        Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.success.withValues(alpha: 0.05)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isActive
                  ? AppColors.success.withValues(alpha: 0.3)
                  : AppColors.surfaceBorder,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isActive ? Iconsax.timer_start : Iconsax.timer_pause,
                color: isActive ? AppColors.success : AppColors.textSecondary,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${shift.driverName} → ${shift.truckImmatriculation}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${shift.startTime.day.toString().padLeft(2, '0')}/${shift.startTime.month.toString().padLeft(2, '0')}/${shift.startTime.year} '
                      '${shift.startTime.hour.toString().padLeft(2, '0')}:${shift.startTime.minute.toString().padLeft(2, '0')}'
                      ' • ${hours}h${minutes.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Onglets Carburant / Pesées
        Expanded(
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                TabBar(
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primary,
                  tabs: [
                    Tab(
                      icon: const Icon(Iconsax.gas_station, size: 18),
                      text: l10n.translate('shift.fuelTab'),
                    ),
                    Tab(
                      icon: const Icon(Iconsax.weight, size: 18),
                      text: l10n.translate('shift.weighingTab'),
                    ),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Onglet Carburant
                      _buildShiftFuelTab(fuelAsync, l10n),
                      // Onglet Pesées
                      _buildShiftWeighingTab(weighingsAsync, l10n),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShiftFuelTab(
      AsyncValue<List<FuelRequestModel>> fuelAsync, AppLocalizations l10n) {
    return fuelAsync.when(
      data: (requests) {
        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Iconsax.gas_station,
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                    size: 48),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.translate('shift.noFuelRequests'),
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 14),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            final userId =
                ref.watch(authControllerProvider).valueOrNull?.id ?? '';
            return _buildFuelRequestCard(request, l10n, userId);
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, _) => Center(
        child: Text('${l10n.translate('common.error')}: $e',
            style: const TextStyle(color: AppColors.error)),
      ),
    );
  }

  Widget _buildShiftWeighingTab(
      AsyncValue<List<WeighingRecordModel>> weighingsAsync,
      AppLocalizations l10n) {
    return weighingsAsync.when(
      data: (records) {
        if (records.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Iconsax.weight,
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                    size: 48),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.translate('shift.noWeighings'),
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 14),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: records.length,
          itemBuilder: (context, index) {
            final record = records[index];
            return _buildWeighingCard(record, l10n);
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, _) => Center(
        child: Text('${l10n.translate('common.error')}: $e',
            style: const TextStyle(color: AppColors.error)),
      ),
    );
  }

  Widget _buildWeighingCard(
      WeighingRecordModel record, AppLocalizations l10n) {
    final isMine = record.location == WeighingLocation.mine;
    final statusColor = switch (record.status) {
      WeighingStatus.pending => AppColors.warning,
      WeighingStatus.recorded => AppColors.info,
      WeighingStatus.validated => AppColors.success,
      WeighingStatus.rejected => AppColors.error,
      WeighingStatus.loaded => AppColors.primary,
      WeighingStatus.unloaded => const Color(0xFF26A69A),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isMine ? Iconsax.building : Iconsax.ship,
                color: isMine ? AppColors.warning : AppColors.info,
                size: 18,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '${record.location.label} • ${record.truckImmatriculation}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  record.status.label,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: 2,
            children: [
              if (record.emptyWeight != null)
                Text(
                  '${l10n.translate('weighing.emptyWeight')}: ${record.formattedEmptyWeight}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              if (record.loadedWeight != null)
                Text(
                  '${l10n.translate('weighing.loadedWeight')}: ${record.formattedLoadedWeight}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
            ],
          ),
          if (record.weight > 0) ...[
            const SizedBox(height: 2),
            Text(
              '${l10n.translate('weighing.netWeight')}: ${record.formattedWeight}',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 2),
          Text(
            '${record.formattedDate} ${record.formattedTime} • ${record.weighedByName}',
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 11),
          ),
          if (record.status == WeighingStatus.loaded &&
              record.chargedByName != null) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Iconsax.truck, size: 11, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  '${l10n.translate('weighing.chargedBy')}: ${record.chargedByName}',
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
          if (record.status == WeighingStatus.unloaded &&
              record.dischargedByName != null) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Iconsax.box, size: 11, color: Color(0xFF26A69A)),
                const SizedBox(width: 4),
                Text(
                  '${l10n.translate('weighing.dischargedBy')}: ${record.dischargedByName}',
                  style: const TextStyle(
                      color: Color(0xFF26A69A),
                      fontSize: 11,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Impression vacation ───────────────────────────────────────────────────

  Future<void> _printShift(
    ShiftModel shift,
    List<FuelRequestModel> fuelRequests,
    List<WeighingRecordModel> weighings,
    dynamic supervisor,
    AppLocalizations l10n,
  ) async {
    final fmt = DateFormat('dd/MM/yyyy HH:mm');
    final numFmt = NumberFormat('#,##0.##', 'fr_FR');
    final isActive = shift.status == ShiftStatus.active;
    final duration = shift.duration;
    final hours = duration?.inHours ?? 0;
    final minutes = (duration?.inMinutes ?? 0) % 60;

    // ── Styles PDF ──
    final titleStyle = pw.TextStyle(
      fontSize: 18,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.blueGrey800,
    );
    final sectionStyle = pw.TextStyle(
      fontSize: 12,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.blue800,
    );
    const labelStyle = pw.TextStyle(fontSize: 10, color: PdfColors.blueGrey600);
    const valueStyle = pw.TextStyle(fontSize: 10);
    final tableHeaderStyle = pw.TextStyle(
      fontSize: 9,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.white,
    );
    const tableCellStyle = pw.TextStyle(fontSize: 9);

    pw.Widget buildRow(String label, String value) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(width: 140, child: pw.Text(label, style: labelStyle)),
              pw.Expanded(child: pw.Text(value, style: valueStyle)),
            ],
          ),
        );

    pw.Widget buildSection(String title) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(height: 12),
            pw.Text(title.toUpperCase(), style: sectionStyle),
            pw.Divider(color: PdfColors.blue200),
            pw.SizedBox(height: 4),
          ],
        );

    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('RAPPORT DE VACATION', style: titleStyle),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: isActive ? PdfColors.green100 : PdfColors.grey200,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    isActive ? 'EN COURS' : 'TERMINÉE',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: isActive
                          ? PdfColors.green800
                          : PdfColors.blueGrey600,
                    ),
                  ),
                ),
              ],
            ),
            pw.Divider(color: PdfColors.blueGrey200, thickness: 1),
          ],
        ),
        footer: (_) => pw.Center(
          child: pw.Text(
            'Généré le ${fmt.format(DateTime.now())}  ·  My LSC',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.blueGrey400),
          ),
        ),
        build: (context) => [
          // ── Vacation ──
          buildSection('Informations Vacation'),
          buildRow('Camion', shift.truckImmatriculation),
          buildRow('Chauffeur', shift.driverName),
          buildRow('Début', fmt.format(shift.startTime)),
          if (shift.endTime != null)
            buildRow('Fin', fmt.format(shift.endTime!)),
          buildRow(
            'Durée',
            '${hours}h${minutes.toString().padLeft(2, '0')}',
          ),
          if (shift.startedByName != null)
            buildRow('Démarré par', shift.startedByName!),

          // ── Superviseur ──
          buildSection('Superviseur de Flotte'),
          buildRow(
            'Nom',
            ((supervisor?.fullName as String?)?.isNotEmpty ?? false)
                ? supervisor!.fullName as String
                : '-',
          ),
          buildRow(
            'Flotte',
            _selectedFleet?.name ?? '-',
          ),

          // ── Carburant ──
          buildSection('Demandes de Carburant (${fuelRequests.length})'),
          if (fuelRequests.isEmpty)
            pw.Text('Aucune demande de carburant',
                style:
                    const pw.TextStyle(fontSize: 9, color: PdfColors.blueGrey400))
          else ...[
            pw.Table(
              border: pw.TableBorder.all(
                  color: PdfColors.blueGrey200, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(1.5),
                2: const pw.FlexColumnWidth(),
                3: const pw.FlexColumnWidth(),
                4: const pw.FlexColumnWidth(1.2),
                5: const pw.FlexColumnWidth(1.2),
              },
              children: [
                pw.TableRow(
                  decoration:
                      const pw.BoxDecoration(color: PdfColors.blueGrey700),
                  children: [
                    'Date',
                    'Camion',
                    'Demandé (L)',
                    'Servi (L)',
                    'Statut',
                    'Reçu',
                  ]
                      .map((h) => pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(h, style: tableHeaderStyle),
                          ))
                      .toList(),
                ),
                ...fuelRequests.map((r) => pw.TableRow(
                      children: [
                        r.formattedDate,
                        r.truckImmatriculation,
                        numFmt.format(r.requestedLiters),
                        if (r.fulfilledLiters != null) numFmt.format(r.fulfilledLiters) else '-',
                        r.status.label,
                        r.receiptNumber ?? '-',
                      ]
                          .map((c) => pw.Padding(
                                padding: const pw.EdgeInsets.all(4),
                                child: pw.Text(c, style: tableCellStyle),
                              ))
                          .toList(),
                    )),
              ],
            ),
          ],

          // ── Pesées ──
          buildSection('Pesées (${weighings.length})'),
          if (weighings.isEmpty)
            pw.Text('Aucune pesée enregistrée',
                style:
                    const pw.TextStyle(fontSize: 9, color: PdfColors.blueGrey400))
          else ...[
            pw.Table(
              border: pw.TableBorder.all(
                  color: PdfColors.blueGrey200, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(),
                2: const pw.FlexColumnWidth(1.2),
                3: const pw.FlexColumnWidth(1.2),
                4: const pw.FlexColumnWidth(1.8),
              },
              children: [
                pw.TableRow(
                  decoration:
                      const pw.BoxDecoration(color: PdfColors.blueGrey700),
                  children: [
                    'Date',
                    'Site',
                    'Camion',
                    'Tonnage (T)',
                    'Pesé par',
                  ]
                      .map((h) => pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(h, style: tableHeaderStyle),
                          ))
                      .toList(),
                ),
                ...weighings.map((w) => pw.TableRow(
                      children: [
                        fmt.format(w.createdAt),
                        w.location.label,
                        w.truckImmatriculation,
                        numFmt.format(w.weight),
                        w.weighedByName,
                      ]
                          .map((c) => pw.Padding(
                                padding: const pw.EdgeInsets.all(4),
                                child: pw.Text(c, style: tableCellStyle),
                              ))
                          .toList(),
                    )),
              ],
            ),
          ],
        ],
      ),
    );

    final bytes = await doc.save();
    final filename =
        'vacation_${shift.truckImmatriculation}_${DateFormat('yyyyMMdd_HHmm').format(shift.startTime)}.pdf';

    await printOrSharePdf(Uint8List.fromList(bytes), filename: filename);
  }

  Future<void> _endShift(ShiftModel shift) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text(
          l10n.translate('shift.endShiftConfirm'),
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          '${shift.driverName} → ${shift.truckImmatriculation}',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.translate('common.cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(
              l10n.translate('shift.endShift'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final repository = ref.read(shiftRepositoryProvider);
      await repository.endShift(
        shift.id,
        driverId: shift.driverId,
        truckId: shift.truckId,
      );

      ref.invalidate(activeShiftForTruckProvider(shift.truckId));
      ref.invalidate(activeShiftForDriverProvider(shift.driverId));
      ref.invalidate(shiftsForFleetProvider(_selectedFleet!.id));

      if (mounted) {
        setState(() => _selectedShift = null);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('${l10n.translate('common.error')}: $e'),
          ),
        );
      }
    }
  }

  // ── Affectations ──

  Widget _buildAssignmentContent() {
    final l10n = AppLocalizations.of(context);
    final trucksAsync = ref.watch(fleetTrucksProvider(_selectedFleet!.id));
    // Maintenir le stream actif en permanence pour éviter AsyncLoading
    // lors de l'ouverture du dialogue d'affectation
    ref.watch(activeAssignmentsStreamProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: trucksAsync.when(
        data: (trucks) {
          if (trucks.isEmpty) {
            return Center(
              child: Text(
                l10n.translate('fleet.noTrucksInFleet'),
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 16),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: trucks.length,
            itemBuilder: (context, index) {
              final truck = trucks[index];
              return _buildTruckAssignmentCard(truck, l10n);
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Text('${l10n.translate('common.error')}: $e',
              style: const TextStyle(color: AppColors.error)),
        ),
      ),
    );
  }

  Widget _buildTruckAssignmentCard(TruckModel truck, AppLocalizations l10n) {
    final assignmentsAsync =
        ref.watch(assignmentsForTruckStreamProvider(truck.id));
    final activeShiftAsync = ref.watch(activeShiftForTruckProvider(truck.id));
    final hasActiveShift = activeShiftAsync.valueOrNull != null;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Truck header
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(Iconsax.truck,
                    color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      truck.immatriculation,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Row(
                      children: [
                        if (truck.numeroInterneFlotte.isNotEmpty)
                          Text(
                            truck.numeroInterneFlotte,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        if (truck.numeroInterneFlotte.isNotEmpty &&
                            (truck.radarNumber?.isNotEmpty ?? false))
                          const Text(' · ',
                              style: TextStyle(
                                  color: AppColors.textTertiary,
                                  fontSize: 12)),
                        if (truck.radarNumber?.isNotEmpty ?? false)
                          Text(
                            'Radar: ${truck.radarNumber!}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (hasActiveShift)
                Tooltip(
                  message: l10n.translate('shift.assignmentLocked'),
                  child: const Icon(Icons.lock,
                      color: AppColors.warning, size: 18),
                )
              else
                Builder(builder: (_) {
                  final assignedRanks = assignmentsAsync.valueOrNull
                          ?.map((a) => a.driverRank)
                          .toSet() ??
                      {};
                  final allRanksFilled =
                      DriverRank.values.every(assignedRanks.contains);
                  if (allRanksFilled) return const SizedBox.shrink();
                  return IconButton(
                    icon: const Icon(Iconsax.add_circle,
                        color: AppColors.primary, size: 22),
                    tooltip: l10n.translate('assignment.addDriver'),
                    onPressed: () => _showAssignDriverDialog(truck),
                  );
                }),
            ],
          ),
          // Assigned drivers
          assignmentsAsync.when(
            data: (assignments) {
              if (assignments.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(
                    l10n.translate('shift.noAssignment'),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                );
              }
              return Column(
                children: ([...assignments]
                      ..sort((a, b) =>
                          a.driverRank.index.compareTo(b.driverRank.index)))
                    .map((assignment) {
                  const rankColors = {
                    DriverRank.principal: AppColors.success,
                    DriverRank.secondaire: AppColors.primary,
                    DriverRank.remplacant: AppColors.warning,
                  };
                  final rankColor =
                      rankColors[assignment.driverRank] ?? AppColors.textSecondary;
                  return Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Row(
                      children: [
                        const SizedBox(width: AppSpacing.xl),
                        CircleAvatar(
                          radius: 14,
                          backgroundColor:
                              rankColor.withValues(alpha: 0.12),
                          child: Text(
                            assignment.driverName.isNotEmpty
                                ? assignment.driverName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: rankColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                assignment.driverName,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                l10n.translate(assignment.driverRank.i18nKey),
                                style: TextStyle(
                                  color: rankColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!hasActiveShift)
                          IconButton(
                            icon: const Icon(Iconsax.close_circle,
                                color: AppColors.error, size: 18),
                            tooltip: l10n.translate('fleet.unassign'),
                            onPressed: () =>
                                _unassignDriver(assignment.id, truck.id, l10n),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSpacing.sm),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.primary),
              ),
            ),
            error: (e, _) => Text('$e',
                style:
                    const TextStyle(color: AppColors.error, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  void _showAssignDriverDialog(TruckModel truck) {
    final l10n = AppLocalizations.of(context);
    final fleetId = _selectedFleet!.id;

    // Vérifie qu'il y a bien des chauffeurs dans la flotte
    final driversCheck = ref.read(fleetDriversProvider(fleetId));
    if ((driversCheck.valueOrNull ?? []).isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.translate('fleet.noDriversInFleet'))),
      );
      return;
    }

    String? selectedDriverId;
    var isPrimary = true;
    var selectedRank = DriverRank.principal;
    final searchController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => Consumer(
          // Consumer garantit des données réactives (ref.watch, pas ref.read)
          // → aucun délai de cache sur activeAssignments et fleetDrivers
          builder: (context, watchRef, _) {
            final allFleetDrivers =
                watchRef.watch(fleetDriversProvider(fleetId)).valueOrNull ?? [];

            // Rangs déjà pris sur CE camion + chauffeurs déjà sur ce camion
            final truckAssignments = watchRef
                    .watch(assignmentsForTruckStreamProvider(truck.id))
                    .valueOrNull ??
                [];
            final takenRanks =
                truckAssignments.map((a) => a.driverRank).toSet();
            final truckDriverIds =
                truckAssignments.map((a) => a.driverId).toSet();

            // Filtre global : uniquement chauffeurs sans affectation active
            final assignedDriverIds = watchRef
                    .watch(activeAssignmentsStreamProvider)
                    .valueOrNull
                    ?.map((a) => a.driverId)
                    .toSet() ??
                {};
            // Un chauffeur déjà sur CE camion (autre rang) est aussi exclu
            final availableDrivers = allFleetDrivers
                .where((d) =>
                    !assignedDriverIds.contains(d.id) &&
                    !truckDriverIds.contains(d.id))
                .toList();

            final availableRanks = DriverRank.values
                .where((r) => !takenRanks.contains(r))
                .toList();
            // Recale le rang sélectionné si nécessaire
            if (availableRanks.isNotEmpty &&
                !availableRanks.contains(selectedRank)) {
              selectedRank = availableRanks.first;
              isPrimary = selectedRank == DriverRank.principal;
            }

          final query = searchController.text.toLowerCase().trim();
          final filtered = availableDrivers
              .where((d) =>
                  query.isEmpty ||
                  d.fullName.toLowerCase().contains(query) ||
                  (d.matricule ?? '').toLowerCase().contains(query))
              .toList();

          return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          title: Text(
            '${l10n.translate('assignment.addDriver')} - ${truck.immatriculation}',
            style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 16),
          ),
          content: SizedBox(
            width: 400,
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Champ de recherche ──
              TextField(
                controller: searchController,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: l10n.translate('assignment.searchDriver'),
                  hintStyle: const TextStyle(
                      color: AppColors.textTertiary, fontSize: 13),
                  prefixIcon: const Icon(Iconsax.search_normal,
                      color: AppColors.textTertiary, size: 18),
                  filled: true,
                  fillColor: AppColors.backgroundSecondary,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide:
                        const BorderSide(color: AppColors.surfaceBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide:
                        const BorderSide(color: AppColors.surfaceBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 2),
                  ),
                ),
                onChanged: (_) => setDialogState(() {}),
              ),
              const SizedBox(height: AppSpacing.sm),
              // ── Liste des chauffeurs disponibles ──
              if (filtered.isEmpty)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: Center(
                    child: Text(
                      l10n.translate('assignment.noDriverAvailable'),
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border:
                          Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(
                          height: 1, color: AppColors.surfaceBorder),
                      itemBuilder: (_, i) {
                        final driver = filtered[i];
                        final isSelected =
                            selectedDriverId == driver.id;
                        return InkWell(
                          onTap: () => setDialogState(
                              () => selectedDriverId = driver.id),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm),
                            color: isSelected
                                ? AppColors.primary
                                    .withValues(alpha: 0.08)
                                : null,
                            child: Row(
                              children: [
                                Icon(
                                  isSelected
                                      ? Iconsax.tick_circle5
                                      : Iconsax.user,
                                  size: 16,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    driver.fullName.isNotEmpty
                                        ? driver.fullName
                                        : driver.email,
                                    style: TextStyle(
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.textPrimary,
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if ((driver.matricule ?? '').isNotEmpty)
                                  Text(
                                    driver.matricule!,
                                    style: const TextStyle(
                                        color: AppColors.textTertiary,
                                        fontSize: 11),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<DriverRank>(
                initialValue: selectedRank,
                dropdownColor: AppColors.surface,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  labelText: l10n.translate('assignment.rank'),
                  labelStyle: const TextStyle(
                      color: AppColors.textSecondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                items: availableRanks.map((rank) {
                  return DropdownMenuItem(
                    value: rank,
                    child: Text(l10n.translate(rank.i18nKey)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() {
                      selectedRank = value;
                      isPrimary = value == DriverRank.principal;
                    });
                  }
                },
              ),
            ],
          ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.translate('common.cancel')),
            ),
            ElevatedButton(
              onPressed: selectedDriverId == null
                  ? null
                  : () async {
                      final driver = allFleetDrivers
                          .firstWhere((d) => d.id == selectedDriverId);
                      final user =
                          ref.read(authControllerProvider).valueOrNull;
                      if (user == null) return;

                      // Capture messenger before async gap
                      final messenger = ScaffoldMessenger.of(context);

                      try {
                        final repository =
                            ref.read(shiftRepositoryProvider);
                        await repository.assignDriver(
                          truckId: truck.id,
                          truckImmatriculation: truck.immatriculation,
                          driverId: driver.id,
                          driverName: driver.fullName.isNotEmpty
                              ? driver.fullName
                              : driver.email,
                          assignedBy: user.id,
                          assignedByName: user.fullName.isNotEmpty
                              ? user.fullName
                              : user.email,
                          isPrimary: isPrimary,
                          driverRank: selectedRank,
                        );

                        // Invalider immédiatement pour éviter données périmées
                        ref.invalidate(
                            assignmentsForTruckStreamProvider(truck.id));
                        ref.invalidate(activeAssignmentsStreamProvider);

                        if (dialogContext.mounted) {
                          Navigator.of(dialogContext).pop();
                        }
                      } catch (e) {
                        final msg = e.toString();
                        final alreadyAssigned =
                            msg.contains('DRIVER_ALREADY_ASSIGNED');
                        final existingTruck = alreadyAssigned
                            ? msg.split(':').last
                            : '';
                        messenger.showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.error,
                            content: Text(
                              alreadyAssigned
                                  ? l10n
                                      .translate(
                                          'assignment.driverAlreadyAssigned')
                                      .replaceAll(
                                          '{truck}', existingTruck)
                                  : '${l10n.translate('common.error')}: $e',
                              style: const TextStyle(
                                  color: Colors.white),
                            ),
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary),
              child: Text(
                l10n.translate('common.save'),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );       // AlertDialog
          },     // Consumer builder
        ),       // Consumer
      ),         // StatefulBuilder
    );           // showDialog
  }

  Future<void> _unassignDriver(
      String assignmentId, String truckId, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text(
          l10n.translate('assignment.unassignConfirm'),
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.translate('common.cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(
              l10n.translate('fleet.unassign'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final repository = ref.read(shiftRepositoryProvider);
    await repository.unassignDriver(assignmentId);
    ref.invalidate(assignmentsForTruckStreamProvider(truckId));
    ref.invalidate(activeAssignmentsStreamProvider);
  }

  // ── Demandes carburant ──

  Widget _buildFuelRequestsContent() {
    final l10n = AppLocalizations.of(context);
    final requestsAsync =
        ref.watch(fleetFuelRequestsProvider(_selectedFleet!.id));
    final userId = ref.watch(authControllerProvider).valueOrNull?.id ?? '';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: requestsAsync.when(
        data: (requests) {
          if (requests.isEmpty) {
            return Center(
              child: Text(
                l10n.translate('fleet.noFuelRequests'),
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 16),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return _buildFuelRequestCard(request, l10n, userId);
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Text('${l10n.translate('common.error')}: $e',
              style: const TextStyle(color: AppColors.error)),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => showDialog<bool>(
          context: context,
          builder: (_) =>
              _CreateFuelRequestDialog(fleetId: _selectedFleet!.id),
        ),
        tooltip: l10n.translate('fleet.createFuelRequest'),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFuelRequestCard(
      FuelRequestModel request, AppLocalizations l10n, String userId) {
    Color statusColor;
    switch (request.status) {
      case FuelRequestStatus.pending:
        statusColor = AppColors.warning;
      case FuelRequestStatus.fulfilled:
        statusColor = AppColors.info;
      case FuelRequestStatus.validated:
        statusColor = AppColors.success;
      case FuelRequestStatus.disputed:
        statusColor = AppColors.error;
      case FuelRequestStatus.rejected:
        statusColor = AppColors.error;
      case FuelRequestStatus.cancelled:
        statusColor = AppColors.textTertiary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.gas_station, color: statusColor, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '${request.truckImmatriculation} - ${request.requestedLiters}L',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  request.status.label,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              GestureDetector(
                onTap: () => FuelRequestDetailSheet.show(context, request),
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
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${request.requestedByName} \u2022 ${request.formattedDate} ${request.formattedTime}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          if (request.verificationCode != null &&
              request.verificationCode!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                const Icon(Iconsax.shield_tick,
                    size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  'Code: ${request.verificationCode}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ],
          if (request.reason != null && request.reason!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              request.reason!,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          // Fulfilled: show served liters, receipt photo, validate/dispute buttons
          if (request.status == FuelRequestStatus.fulfilled) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border:
                    Border.all(color: AppColors.info.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Iconsax.drop,
                          color: AppColors.info, size: 16),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '${l10n.translate('fuelRequest.servedLiters')}: ${request.fulfilledLiters?.toStringAsFixed(1) ?? '-'} L',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (request.receiptNumber != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${l10n.translate('fuel.receiptNumber')}: ${request.receiptNumber}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (request.fulfilledByName != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${l10n.translate('fuelRequest.servedBy')}: ${request.fulfilledByName}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (request.receiptPhotoUrl != null &&
                      request.receiptPhotoUrl!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    GestureDetector(
                      onTap: () =>
                          _showReceiptPhoto(request.receiptPhotoUrl!),
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppRadius.sm),
                        child: Image.network(
                          request.receiptPhotoUrl!,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const SizedBox(
                              height: 120,
                              child: Center(
                                child: CircularProgressIndicator(
                                    color: AppColors.primary),
                              ),
                            );
                          },
                          errorBuilder: (context, error, _) => Container(
                            height: 120,
                            color: AppColors.surface,
                            child: const Center(
                              child: Icon(Iconsax.image,
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
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _disputeRequest(request, userId),
                  child: Text(
                    l10n.translate('fleet.dispute'),
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                ElevatedButton(
                  onPressed: () => _validateRequest(request, userId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                  ),
                  child: Text(
                    l10n.translate('fleet.validate'),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
          // Validated or disputed: show served liters
          if ((request.status == FuelRequestStatus.validated ||
                  request.status == FuelRequestStatus.disputed) &&
              request.fulfilledLiters != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(Iconsax.drop, color: AppColors.info, size: 16),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '${l10n.translate('fuelRequest.servedLiters')}: ${request.fulfilledLiters!.toStringAsFixed(1)} L',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (request.fulfilledByName != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '(${request.fulfilledByName})',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ],
          // Disputed: show reason
          if (request.status == FuelRequestStatus.disputed &&
              request.disputeReason != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Iconsax.warning_2,
                      color: AppColors.error, size: 16),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      request.disputeReason!,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showReceiptPhoto(String url) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(AppSpacing.md),
        child: Stack(
          children: [
            InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Image.network(url, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: AppSpacing.sm,
              right: AppSpacing.sm,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.backgroundSecondary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Iconsax.close_circle,
                      color: AppColors.textPrimary, size: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _validateRequest(
      FuelRequestModel request, String userId) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text(
          l10n.translate('fleet.validateConfirm'),
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          '${request.truckImmatriculation} - ${request.fulfilledLiters?.toStringAsFixed(1) ?? '-'} L',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.translate('common.cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success),
            child: Text(
              l10n.translate('fleet.validate'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final authState = ref.read(authControllerProvider);
    final userName = authState.valueOrNull?.fullName ?? '';
    final repo = FuelRequestRepository();
    await repo.validateFulfilledRequest(
      requestId: request.id,
      validatedBy: userId,
      validatedByName: userName,
    );
  }

  Future<void> _disputeRequest(
      FuelRequestModel request, String userId) async {
    final l10n = AppLocalizations.of(context);
    final reasonController = TextEditingController();

    final reason = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text(
          l10n.translate('fleet.disputeConfirm'),
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${request.truckImmatriculation} - ${request.fulfilledLiters?.toStringAsFixed(1) ?? '-'} L',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: reasonController,
              maxLines: 3,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: l10n.translate('fleet.disputeReason'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.translate('common.cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) return;
              Navigator.of(context).pop(reasonController.text.trim());
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error),
            child: Text(
              l10n.translate('fleet.dispute'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (reason == null || reason.isEmpty) return;

    final authState = ref.read(authControllerProvider);
    final userName = authState.valueOrNull?.fullName ?? '';
    final repo = FuelRequestRepository();
    await repo.disputeFulfilledRequest(
      requestId: request.id,
      validatedBy: userId,
      validatedByName: userName,
      disputeReason: reason,
    );
  }

  // ── T.25.6 — Hors service ──

  Widget _buildHorsServiceButton(TruckModel truck, AppLocalizations l10n) {
    final isHorsService = truck.horsServiceAt != null;
    return IconButton(
      icon: Icon(
        isHorsService ? Icons.warning_rounded : Icons.warning_amber_rounded,
        color: isHorsService ? AppColors.error : AppColors.textSecondary,
        size: 20,
      ),
      tooltip: isHorsService
          ? l10n.translate('shift.clearHorsService')
          : l10n.translate('shift.signalHorsService'),
      onPressed: () => isHorsService
          ? _clearHorsService(truck, l10n)
          : _signalHorsService(truck, l10n),
    );
  }

  Widget _buildHorsServiceBanner(TruckModel truck, AppLocalizations l10n) {
    final since = truck.horsServiceAt!;
    final duration = DateTime.now().difference(since);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final durationLabel = hours > 0
        ? '${hours}h${minutes.toString().padLeft(2, '0')}'
        : '${minutes}min';

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_rounded,
                color: AppColors.error, size: 14),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                '${l10n.translate('shift.horsService')} • $durationLabel'
                '${truck.horsServiceReason != null ? ' — ${truck.horsServiceReason}' : ''}',
                style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 11,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signalHorsService(
      TruckModel truck, AppLocalizations l10n) async {
    final reasons = [
      l10n.translate('shift.horsServiceReasonStrike'),
      l10n.translate('shift.horsServiceReasonAccident'),
      l10n.translate('shift.horsServiceReasonRoad'),
      l10n.translate('shift.horsServiceReasonOther'),
    ];
    String? selectedReason;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg)),
          title: Text(
            '${l10n.translate('shift.signalHorsService')} — ${truck.immatriculation}',
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: reasons
                .map((r) => InkWell(
                      onTap: () => setD(() => selectedReason = r),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.sm,
                            horizontal: AppSpacing.xs),
                        child: Row(
                          children: [
                            Icon(
                              selectedReason == r
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              color: selectedReason == r
                                  ? AppColors.error
                                  : AppColors.textSecondary,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(r,
                                  style: TextStyle(
                                    color: selectedReason == r
                                        ? AppColors.error
                                        : AppColors.textPrimary,
                                    fontSize: 13,
                                    fontWeight: selectedReason == r
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  )),
                            ),
                          ],
                        ),
                      ),
                    ))
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.translate('common.cancel')),
            ),
            ElevatedButton(
              onPressed: selectedReason == null
                  ? null
                  : () => Navigator.of(ctx).pop(true),
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: Text(l10n.translate('common.confirm'),
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || selectedReason == null) return;

    final repo = ref.read(truckRepositoryProvider);
    await repo.signalHorsService(truck.id, reason: selectedReason!);
  }

  Future<void> _clearHorsService(
      TruckModel truck, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Text(l10n.translate('shift.clearHorsService'),
            style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(truck.immatriculation,
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.translate('common.cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: Text(l10n.translate('common.confirm'),
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final repo = ref.read(truckRepositoryProvider);
    await repo.clearHorsService(truck.id);
  }
}

// ── Modèle interne pour la grille d'actions ──

class _ActionItem {
  const _ActionItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;
}

// ═══════════════════════════════════════════════════════════════
// DIALOG CRÉATION DEMANDE CARBURANT
// ═══════════════════════════════════════════════════════════════

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
  String? _selectedTruckId;
  String? _selectedTruckImmatriculation;
  String? _selectedTruckFleetNumber;
  final _litersController = TextEditingController();
  final _reasonController = TextEditingController();
  final _truckSearchController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _litersController.dispose();
    _reasonController.dispose();
    _truckSearchController.dispose();
    super.dispose();
  }

  List<TruckModel> _getFleetTrucks() {
    final trucksAsync = ref.read(fleetTrucksProvider(widget.fleetId));
    return trucksAsync.whenOrNull(data: (trucks) => trucks) ?? [];
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTruckId == null) return;

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authControllerProvider).valueOrNull;
      if (user == null) return;

      // T.28 : la vacation active n'est plus obligatoire pour créer une
      // demande de carburant — si elle existe, on l'associe simplement à la
      // demande, sinon la demande est créée sans shift/chauffeur associé.
      final activeShift = await ref
          .read(shiftRepositoryProvider)
          .getActiveShiftForTruck(_selectedTruckId!);

      final repo = FuelRequestRepository();
      final liters = double.tryParse(_litersController.text.trim()) ?? 0;
      final request = await repo.createRequest(
        truckId: _selectedTruckId!,
        truckImmatriculation: _selectedTruckImmatriculation ?? '',
        truckFleetNumber: _selectedTruckFleetNumber,
        requestedBy: user.id,
        requestedByName:
            user.fullName.isEmpty ? user.email : user.fullName,
        requestedLiters: liters,
        fleetId: widget.fleetId,
        shiftId: activeShift?.id,
        driverId: activeShift?.driverId,
        driverName: activeShift?.driverName,
        reason: _reasonController.text.trim().isNotEmpty
            ? _reasonController.text.trim()
            : null,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        // Show verification code
        final l10n = AppLocalizations.of(context);
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.translate('fleet.requestCreated')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.translate('fleet.verificationCodeLabel')),
                const SizedBox(height: 8),
                Text(
                  request.verificationCode ?? '',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.translate('fleet.verificationCodeHint'),
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.translate('common.ok')),
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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final trucks = _getFleetTrucks();

    return AlertDialog(
      title: Text(l10n.translate('fleet.createFuelRequest')),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Autocomplete<TruckModel>(
              optionsBuilder: (textEditingValue) {
                if (textEditingValue.text.isEmpty) return trucks;
                final query = textEditingValue.text.toLowerCase();
                return trucks.where((truck) =>
                    truck.immatriculation.toLowerCase().contains(query) ||
                    truck.displayName.toLowerCase().contains(query) ||
                    truck.numeroInterneFlotte.toLowerCase().contains(query));
              },
              displayStringForOption: (truck) => truck.displayName,
              fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    labelText: l10n.translate('fleet.selectTruck'),
                    hintText: l10n.translate('fuelRequest.searchTruck'),
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Iconsax.search_normal),
                    suffixIcon: controller.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Iconsax.close_circle),
                            onPressed: () {
                              controller.clear();
                              setState(() {
                                _selectedTruckId = null;
                                _selectedTruckImmatriculation = null;
                                _selectedTruckFleetNumber = null;
                              });
                            },
                          )
                        : null,
                  ),
                  validator: (_) => _selectedTruckId == null
                      ? l10n.translate('fuelRequest.truckRequired')
                      : null,
                );
              },
              onSelected: (truck) {
                setState(() {
                  _selectedTruckId = truck.id;
                  _selectedTruckImmatriculation = truck.immatriculation;
                  _selectedTruckFleetNumber = truck.numeroInterneFlotte;
                });
              },
            ),
            const SizedBox(height: 16),
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
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.translate('common.cancel')),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
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

// ── Widget bouton Modifier chauffeur ─────────────────────────────────────────

class _DriverEditButton extends StatelessWidget {
  const _DriverEditButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.edit_2, color: AppColors.primary, size: 14),
            SizedBox(width: 5),
            Text(
              'Modifier',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────

class _StorageNotificationBell extends ConsumerWidget {
  const _StorageNotificationBell({required this.fleetId});

  final String fleetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final eventsAsync = ref.watch(unreadStorageEventsProvider(fleetId));
    final count = eventsAsync.valueOrNull?.length ?? 0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Iconsax.notification, color: AppColors.textSecondary),
          onPressed: () =>
              _showStorageEventsSheet(context, ref, l10n, fleetId),
          tooltip: l10n.translate('weighing.storageNotifications'),
        ),
        if (count > 0)
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  count > 9 ? '9+' : '$count',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showStorageEventsSheet(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    String fleetId,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.backgroundSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => _StorageEventsSheet(fleetId: fleetId),
    );
  }
}

class _StorageEventsSheet extends ConsumerWidget {
  const _StorageEventsSheet({required this.fleetId});

  final String fleetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final eventsAsync = ref.watch(unreadStorageEventsProvider(fleetId));
    final events = eventsAsync.valueOrNull ?? [];

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              const Icon(Iconsax.box, color: AppColors.primary, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.translate('weighing.storageNotifications'),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (events.isNotEmpty)
                TextButton(
                  onPressed: () async {
                    final repo = ref.read(weighingRepositoryProvider);
                    await repo.markAllStorageEventsRead(fleetId);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  child: Text(
                    l10n.translate('weighing.markAllRead'),
                    style: const TextStyle(
                        color: AppColors.primary, fontSize: 13),
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.surfaceBorder),
        if (events.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              children: [
                const Icon(Iconsax.notification_bing,
                    color: AppColors.textTertiary, size: 48),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.translate('weighing.noStorageEvents'),
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 15),
                ),
              ],
            ),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: events.length,
              separatorBuilder: (_, __) => const Divider(
                  height: 1, color: AppColors.surfaceBorder),
              itemBuilder: (_, i) {
                final event = events[i];
                final ts = event['createdAt'];
                var dateStr = '';
                if (ts != null) {
                  final dt = (ts as dynamic).toDate();
                  dateStr =
                      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} '
                      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                }
                final eventType = event['eventType'] as String? ?? 'unloaded';
                final isUnloaded = eventType == 'unloaded';
                final eventColor = isUnloaded ? AppColors.warning : AppColors.success;
                final actionHint = isUnloaded
                    ? l10n.translate('storage.actionEndShift')
                    : l10n.translate('storage.actionStartShift');
                return Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: eventColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: eventColor.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: eventColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Icon(
                          isUnloaded ? Iconsax.arrow_down : Iconsax.arrow_up,
                          color: eventColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event['truckImmatriculation'] as String? ?? '',
                              style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm, vertical: 2),
                              decoration: BoxDecoration(
                                color: eventColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                              ),
                              child: Text(
                                isUnloaded
                                    ? l10n.translate('storage.eventTypeUnloaded')
                                    : l10n.translate('storage.eventTypeLoaded'),
                                style: TextStyle(
                                    color: eventColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              actionHint,
                              style: const TextStyle(
                                  color: AppColors.textSecondary, fontSize: 11),
                            ),
                            if ((event['ticketNumber'] as String?)?.isNotEmpty ?? false)
                              Text(
                                'No bon: ${event['ticketNumber']}',
                                style: const TextStyle(
                                    color: AppColors.textTertiary, fontSize: 11),
                              ),
                            const SizedBox(height: 4),
                            Text(dateStr,
                                style: const TextStyle(
                                    color: AppColors.textTertiary, fontSize: 10)),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          final repo = ref.read(weighingRepositoryProvider);
                          await repo.markStorageEventRead(event['id'] as String);
                        },
                        child: const Padding(
                          padding: EdgeInsets.only(left: AppSpacing.sm),
                          child: Icon(Iconsax.tick_circle,
                              color: AppColors.success, size: 22),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
      ],
      ),
    );
  }
}
