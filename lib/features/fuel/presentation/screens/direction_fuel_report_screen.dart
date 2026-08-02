import 'dart:io';
import 'package:excel/excel.dart' as xl;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../../../../core/utils/file_download.dart';
import '../../../../core/utils/pdf_utils.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/inline_error_retry.dart';
import '../../../fleet/domain/models/fleet_model.dart';
import '../../../fleet/presentation/providers/fleet_providers.dart';
import '../../../trucks/domain/models/truck_model.dart';
import '../../../trucks/presentation/providers/truck_providers.dart';
import '../../domain/models/fuel_request_model.dart';
import '../providers/fuel_request_providers.dart';

/// Widget de rapport carburant pour la direction (sans Scaffold propre).
/// Peut être intégré comme onglet dans RavitaillementScreen.
/// Affiche la consommation de toutes les flottes avec filtres flotte/vehicule/date.
class DirectionFuelReportScreen extends ConsumerStatefulWidget {
  const DirectionFuelReportScreen({super.key});

  @override
  ConsumerState<DirectionFuelReportScreen> createState() =>
      _DirectionFuelReportScreenState();
}

class _DirectionFuelReportScreenState
    extends ConsumerState<DirectionFuelReportScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  // Fleet filter
  final Set<String> _selectedFleetIds = {};
  bool _selectAllFleets = true;

  // Truck filter
  final Set<String> _selectedTruckIds = {};
  bool _selectAllTrucks = true;

  bool _reportGenerated = false;
  List<_DirectionTruckSummary> _summaries = [];

  // Colonnes exclues de l'export (index dans _exportHeaders)
  final Set<int> _excludedColumnIndexes = {};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fleetsAsync = ref.watch(allFleetsProvider);
    final trucksAsync = ref.watch(trucksStreamProvider);
    final requestsAsync = ref.watch(allRequestsStreamProvider);

    return Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Date range ──
                  _buildDateRangeSection(l10n),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Fleet filter ──
                  fleetsAsync.when(
                    data: (fleets) => _buildFleetFilterSection(l10n, fleets),
                    loading: () => const SizedBox.shrink(),
                    error: (e, _) => InlineErrorRetry(
                      onRetry: () => ref.invalidate(allFleetsProvider),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Truck selection ──
                  trucksAsync.when(
                    data: (trucks) {
                      final visible = _getVisibleTrucks(trucks);
                      return _buildTruckSelectionSection(l10n, visible);
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (e, _) => InlineErrorRetry(
                      onRetry: () => ref.invalidate(trucksStreamProvider),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Generate button ──
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _generateReport(
                        trucksAsync.valueOrNull ?? [],
                        requestsAsync.valueOrNull ?? [],
                        fleetsAsync.valueOrNull ?? [],
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      icon: const Icon(Iconsax.document_text,
                          color: Colors.white, size: 18),
                      label: Text(
                        l10n.translate('fuel.reportGenerate'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Report table ──
                  if (_reportGenerated) _buildReportTable(l10n),
                  if (_reportGenerated && _summaries.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _buildColumnFilterSection(l10n),
                  ],
                ],
              ),
            ),
          ),

          // ── Export buttons ──
          if (_reportGenerated && _summaries.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.surfaceBorder),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildExportButton(
                      icon: Iconsax.document_text,
                      label: 'CSV',
                      color: AppColors.info,
                      onTap: () => _exportCsv(l10n),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _buildExportButton(
                      icon: Iconsax.document_download,
                      label: 'Excel',
                      color: AppColors.success,
                      onTap: () => _exportExcel(l10n),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _buildExportButton(
                      icon: Iconsax.document_favorite,
                      label: 'PDF',
                      color: AppColors.error,
                      onTap: () => _exportPdf(l10n),
                    ),
                  ),
                ],
              ),
            ),
        ],
    );
  }

  Widget _buildExportButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      icon: Icon(icon, color: Colors.white, size: 16),
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // DATE RANGE SECTION
  // ═══════════════════════════════════════════════════════════════

  Widget _buildDateRangeSection(AppLocalizations l10n) {
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
              const Icon(Iconsax.calendar, color: AppColors.primary, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l10n.translate('fuel.reportDateRange'),
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
              Expanded(child: _buildDateButton(_startDate, true, l10n)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Icon(Iconsax.arrow_right_1,
                    color: AppColors.textSecondary, size: 18),
              ),
              Expanded(child: _buildDateButton(_endDate, false, l10n)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton(DateTime date, bool isStart, AppLocalizations l10n) {
    final formatted =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

    return GestureDetector(
      onTap: () => _pickDate(isStart),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Row(
          children: [
            Icon(
              isStart ? Iconsax.calendar_1 : Iconsax.calendar_tick,
              color: AppColors.primary,
              size: 16,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              formatted,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(bool isStart) async {
    final initial = isStart ? _startDate : _endDate;
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
          _startDate = picked;
          if (_startDate.isAfter(_endDate)) _endDate = _startDate;
        } else {
          _endDate = picked;
          if (_endDate.isBefore(_startDate)) _startDate = _endDate;
        }
        _reportGenerated = false;
      });
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // FLEET FILTER SECTION
  // ═══════════════════════════════════════════════════════════════

  Widget _buildFleetFilterSection(
      AppLocalizations l10n, List<FleetModel> fleets) {
    if (fleets.isEmpty) return const SizedBox.shrink();

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
              const Icon(Iconsax.truck_fast, color: AppColors.accent, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.translate('fuel.reportSelectFleets'),
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
                    _selectAllFleets = !_selectAllFleets;
                    if (_selectAllFleets) {
                      _selectedFleetIds.clear();
                    }
                    _selectedTruckIds.clear();
                    _selectAllTrucks = true;
                    _reportGenerated = false;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: 2),
                  decoration: BoxDecoration(
                    color: _selectAllFleets
                        ? AppColors.accent.withValues(alpha: 0.1)
                        : AppColors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    _selectAllFleets
                        ? l10n.translate('common.all')
                        : '${_selectedFleetIds.length}',
                    style: TextStyle(
                      color: _selectAllFleets
                          ? AppColors.accent
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
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: fleets.map((fleet) {
              final isSelected =
                  _selectAllFleets || _selectedFleetIds.contains(fleet.id);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (_selectAllFleets) {
                      _selectAllFleets = false;
                      _selectedFleetIds.addAll(fleets.map((f) => f.id));
                      _selectedFleetIds.remove(fleet.id);
                    } else {
                      if (_selectedFleetIds.contains(fleet.id)) {
                        _selectedFleetIds.remove(fleet.id);
                      } else {
                        _selectedFleetIds.add(fleet.id);
                      }
                      if (_selectedFleetIds.length == fleets.length) {
                        _selectAllFleets = true;
                        _selectedFleetIds.clear();
                      }
                    }
                    _selectedTruckIds.clear();
                    _selectAllTrucks = true;
                    _reportGenerated = false;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accent.withValues(alpha: 0.1)
                        : AppColors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.accent.withValues(alpha: 0.4)
                          : AppColors.surfaceBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected ? Iconsax.tick_square : Iconsax.square,
                        color: isSelected
                            ? AppColors.accent
                            : AppColors.textSecondary,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        fleet.name,
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.accent
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
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TRUCK SELECTION SECTION
  // ═══════════════════════════════════════════════════════════════

  List<TruckModel> _getVisibleTrucks(List<TruckModel> allTrucks) {
    if (_selectAllFleets) return allTrucks;
    return allTrucks
        .where((t) =>
            t.fleetId != null && _selectedFleetIds.contains(t.fleetId))
        .toList();
  }

  Widget _buildTruckSelectionSection(
      AppLocalizations l10n, List<TruckModel> trucks) {
    if (trucks.isEmpty) return const SizedBox.shrink();

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
                  l10n.translate('fuel.reportSelectVehicles'),
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
                    _selectAllTrucks = !_selectAllTrucks;
                    if (_selectAllTrucks) _selectedTruckIds.clear();
                    _reportGenerated = false;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: 2),
                  decoration: BoxDecoration(
                    color: _selectAllTrucks
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : AppColors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    _selectAllTrucks
                        ? l10n.translate('trucks.all')
                        : '${_selectedTruckIds.length}',
                    style: TextStyle(
                      color: _selectAllTrucks
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
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: trucks.map((truck) {
              final isSelected =
                  _selectAllTrucks || _selectedTruckIds.contains(truck.id);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (_selectAllTrucks) {
                      _selectAllTrucks = false;
                      _selectedTruckIds.addAll(trucks.map((t) => t.id));
                      _selectedTruckIds.remove(truck.id);
                    } else {
                      if (_selectedTruckIds.contains(truck.id)) {
                        _selectedTruckIds.remove(truck.id);
                      } else {
                        _selectedTruckIds.add(truck.id);
                      }
                      if (_selectedTruckIds.length == trucks.length) {
                        _selectAllTrucks = true;
                        _selectedTruckIds.clear();
                      }
                    }
                    _reportGenerated = false;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
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
                        isSelected ? Iconsax.tick_square : Iconsax.square,
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
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // GENERATE REPORT
  // ═══════════════════════════════════════════════════════════════

  void _generateReport(
    List<TruckModel> allTrucks,
    List<FuelRequestModel> allRequests,
    List<FleetModel> allFleets,
  ) {
    // Fleet name map
    final fleetNames = {for (final f in allFleets) f.id: f.name};

    // Resolve visible trucks
    final visibleTrucks = _getVisibleTrucks(allTrucks);
    final effectiveTruckIds = _selectAllTrucks
        ? visibleTrucks.map((t) => t.id).toSet()
        : _selectedTruckIds;

    // Filter by date range
    final startOfDay =
        DateTime(_startDate.year, _startDate.month, _startDate.day);
    final endOfDay =
        DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);

    final relevantRequests = allRequests.where((r) =>
        effectiveTruckIds.contains(r.truckId) &&
        !r.createdAt.isBefore(startOfDay) &&
        !r.createdAt.isAfter(endOfDay));

    // Build summaries per truck
    final summaryMap = <String, _DirectionTruckSummary>{};
    for (final truck in visibleTrucks) {
      if (!effectiveTruckIds.contains(truck.id)) continue;
      summaryMap[truck.id] = _DirectionTruckSummary(
        truckId: truck.id,
        immatriculation: truck.immatriculation,
        fleetNumber: truck.numeroInterneFlotte,
        fleetName: fleetNames[truck.fleetId] ?? '',
      );
    }

    for (final request in relevantRequests) {
      final summary = summaryMap[request.truckId];
      if (summary == null) continue;
      summary.requestCount++;
      summary.totalRequestedLiters += request.requestedLiters;
      summary.countByStatus[request.status] =
          (summary.countByStatus[request.status] ?? 0) + 1;
      if (request.fulfilledLiters != null) {
        summary.totalFulfilledLiters += request.fulfilledLiters!;
        summary.litersByStatus[request.status] =
            (summary.litersByStatus[request.status] ?? 0) +
                request.fulfilledLiters!;
      }
      if (request.receiptNumber != null && request.receiptNumber!.isNotEmpty) {
        summary.receiptNumbers.add(request.receiptNumber!);
      }
    }

    setState(() {
      _summaries = summaryMap.values
          .where((s) => s.requestCount > 0)
          .toList()
        ..sort((a, b) =>
            b.totalFulfilledLiters.compareTo(a.totalFulfilledLiters));
      _reportGenerated = true;
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // REPORT TABLE
  // ═══════════════════════════════════════════════════════════════

  Widget _buildReportTable(AppLocalizations l10n) {
    if (_summaries.isEmpty) {
      return Container(
        padding: EdgeInsets.all(context.responsiveHorizontalPadding),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(Iconsax.document,
                color: AppColors.textSecondary.withValues(alpha: 0.5),
                size: 48),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.translate('fuel.reportNoData'),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    var totalRequests = 0;
    var totalRequested = 0.0;
    var totalFulfilled = 0.0;
    for (final s in _summaries) {
      totalRequests += s.requestCount;
      totalRequested += s.totalRequestedLiters;
      totalFulfilled += s.totalFulfilledLiters;
    }

    // Group by fleet for display
    final byFleet = <String, List<_DirectionTruckSummary>>{};
    for (final s in _summaries) {
      byFleet.putIfAbsent(s.fleetName, () => []).add(s);
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: const BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: AppColors.surfaceBorder)),
            ),
            child: Row(
              children: [
                const Icon(Iconsax.chart_21,
                    color: AppColors.primary, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  l10n.translate('fuel.directionReport'),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_summaries.length} ${l10n.translate('fleet.trucks').toLowerCase()}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Totals
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              border: const Border(
                  bottom: BorderSide(color: AppColors.surfaceBorder)),
            ),
            child: Row(
              children: [
                _buildTotalChip(Iconsax.document_text, '$totalRequests',
                    l10n.translate('fuelRequest.title'), AppColors.info),
                const SizedBox(width: AppSpacing.md),
                _buildTotalChip(
                    Iconsax.drop,
                    '${totalRequested.toStringAsFixed(1)} L',
                    l10n.translate('fuelRequest.requestedLiters'),
                    AppColors.warning),
                const SizedBox(width: AppSpacing.md),
                _buildTotalChip(
                    Iconsax.tick_circle,
                    '${totalFulfilled.toStringAsFixed(1)} L',
                    l10n.translate('fuel.reportTotalLiters'),
                    AppColors.success),
              ],
            ),
          ),

          // Per-fleet groups
          ...byFleet.entries.map((entry) {
            final fleetName = entry.key;
            final trucks = entry.value;
            final fleetFulfilled = trucks.fold<double>(
                0, (s, t) => s + t.totalFulfilledLiters);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fleet header
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.08),
                    border: const Border(
                        bottom:
                            BorderSide(color: AppColors.surfaceBorder)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Iconsax.truck_fast,
                          color: AppColors.accent, size: 14),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          fleetName.isEmpty
                              ? l10n.translate('fleet.title')
                              : fleetName,
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        '${fleetFulfilled.toStringAsFixed(1)} L',
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: trucks.length,
                  separatorBuilder: (_, __) =>
                      const Divider(color: AppColors.surfaceBorder, height: 1),
                  itemBuilder: (context, index) =>
                      _buildSummaryRow(trucks[index], l10n),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTotalChip(
      IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
                color: color, fontSize: 13, fontWeight: FontWeight.w700),
          ),
          Text(
            label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 10),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
      _DirectionTruckSummary summary, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(Iconsax.truck,
                    color: AppColors.primary, size: 16),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.immatriculation,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (summary.fleetNumber.isNotEmpty)
                      Text(
                        summary.fleetNumber,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${summary.totalFulfilledLiters.toStringAsFixed(1)} L',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${summary.requestCount} ${l10n.translate('fuelRequest.title').toLowerCase()}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              const SizedBox(width: 40),
              Text(
                '${l10n.translate('fuelRequest.requestedLiters')}: ${summary.totalRequestedLiters.toStringAsFixed(1)} L',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
              ),
              if (summary.totalRequestedLiters > 0 &&
                  summary.totalFulfilledLiters > 0) ...[
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '(${((summary.totalFulfilledLiters / summary.totalRequestedLiters) * 100).toStringAsFixed(0)}%)',
                  style: const TextStyle(
                      color: AppColors.textTertiary, fontSize: 11),
                ),
              ],
            ],
          ),
          if (summary.countByStatus.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const SizedBox(width: 40),
                Expanded(
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: FuelRequestStatus.values
                        .where((s) => (summary.countByStatus[s] ?? 0) > 0)
                        .map((s) => _buildStatusChip(s, summary))
                        .toList(),
                  ),
                ),
              ],
            ),
          ],
          if (summary.receiptNumbers.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                const SizedBox(width: 40),
                const Icon(Iconsax.receipt,
                    color: AppColors.textTertiary, size: 12),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    summary.receiptNumbers.join(', '),
                    style: const TextStyle(
                        color: AppColors.textTertiary, fontSize: 11),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip(
      FuelRequestStatus status, _DirectionTruckSummary summary) {
    final count = summary.countByStatus[status] ?? 0;
    final liters = summary.litersByStatus[status] ?? 0;
    final color = _statusColor(status);
    final label = l10n.translate('fuelRequest.${status.name}');
    final hasLiters = liters > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        hasLiters
            ? '$label: $count (${liters.toStringAsFixed(0)} L)'
            : '$label: $count',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _statusColor(FuelRequestStatus status) {
    switch (status) {
      case FuelRequestStatus.pending:
        return AppColors.warning;
      case FuelRequestStatus.fulfilled:
        return AppColors.info;
      case FuelRequestStatus.validated:
        return AppColors.success;
      case FuelRequestStatus.disputed:
        return Colors.deepOrange;
      case FuelRequestStatus.rejected:
        return AppColors.error;
      case FuelRequestStatus.cancelled:
        return AppColors.textSecondary;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // EXPORT HELPERS
  // ═══════════════════════════════════════════════════════════════

  String get _startFmt =>
      '${_startDate.day.toString().padLeft(2, '0')}/${_startDate.month.toString().padLeft(2, '0')}/${_startDate.year}';
  String get _endFmt =>
      '${_endDate.day.toString().padLeft(2, '0')}/${_endDate.month.toString().padLeft(2, '0')}/${_endDate.year}';

  Widget _buildColumnFilterSection(AppLocalizations l10n) {
    final headers = _exportHeaders;
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
              const Icon(Iconsax.setting_4,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.translate('fuel.reportColumnFilter'),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: List.generate(headers.length, (index) {
              final isVisible = !_excludedColumnIndexes.contains(index);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isVisible) {
                      _excludedColumnIndexes.add(index);
                    } else {
                      _excludedColumnIndexes.remove(index);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: isVisible
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : AppColors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(
                      color: isVisible
                          ? AppColors.primary.withValues(alpha: 0.4)
                          : AppColors.surfaceBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isVisible ? Iconsax.tick_square : Iconsax.square,
                        color: isVisible
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        headers[index],
                        style: TextStyle(
                          color: isVisible
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
            }),
          ),
        ],
      ),
    );
  }

  static const _statuses = FuelRequestStatus.values;

  List<String> get _exportHeaders => [
        l10n.translate('fuel.reportFleetColumn'),
        'Immatriculation',
        'N° Interne',
        'Total Demandes',
        'Litres Demandés',
        'Litres Servis',
        'Taux (%)',
        ..._statuses.expand((s) =>
            s == FuelRequestStatus.fulfilled ||
                    s == FuelRequestStatus.validated
                ? ['${s.label} (nb)', '${s.label} (L)']
                : ['${s.label} (nb)']),
        'N° Reçus',
      ];

  AppLocalizations get l10n => AppLocalizations.of(context);

  /// Index des colonnes à conserver, selon le filtre par colonne.
  List<int> get _visibleColumnIndexes => [
        for (var i = 0; i < _exportHeaders.length; i++)
          if (!_excludedColumnIndexes.contains(i)) i,
      ];

  List<String> _filterRow(List<String> row) =>
      [for (final i in _visibleColumnIndexes) row[i]];

  String _fleetsSummary(AppLocalizations l10n) {
    final names = _summaries.map((s) => s.fleetName).where((n) => n.isNotEmpty).toSet().toList();
    if (names.isEmpty || _selectAllFleets) return l10n.translate('common.exportAllFleets');
    return names.join(', ');
  }

  String _vehiclesSummaryDir(AppLocalizations l10n) {
    if (_selectAllTrucks) return l10n.translate('common.exportAllVehicles');
    final immatList = _summaries.map((s) => s.immatriculation).join(', ');
    return immatList.isEmpty ? l10n.translate('common.exportAllVehicles') : immatList;
  }

  List<String> _summaryToRow(_DirectionTruckSummary s) {
    final rate = s.totalRequestedLiters > 0
        ? ((s.totalFulfilledLiters / s.totalRequestedLiters) * 100)
            .toStringAsFixed(0)
        : '0';
    final statusValues = _statuses.expand((st) =>
        st == FuelRequestStatus.fulfilled ||
                st == FuelRequestStatus.validated
            ? [
                '${s.countByStatus[st] ?? 0}',
                (s.litersByStatus[st] ?? 0).toStringAsFixed(1),
              ]
            : ['${s.countByStatus[st] ?? 0}']);
    return [
      s.fleetName,
      s.immatriculation,
      s.fleetNumber,
      '${s.requestCount}',
      s.totalRequestedLiters.toStringAsFixed(1),
      s.totalFulfilledLiters.toStringAsFixed(1),
      rate,
      ...statusValues,
      s.receiptNumbers.join(', '),
    ];
  }

  // ═══════════════════════════════════════════════════════════════
  // EXPORT CSV
  // ═══════════════════════════════════════════════════════════════

  Future<void> _exportCsv(AppLocalizations l10n) async {
    final buffer = StringBuffer();
    buffer.writeln('"${l10n.translate('common.exportPeriod')}";"$_startFmt → $_endFmt"');
    buffer.writeln('"${l10n.translate('common.exportFleets')}";"${_fleetsSummary(l10n)}"');
    buffer.writeln('"${l10n.translate('common.exportVehicles')}";"${_vehiclesSummaryDir(l10n)}"');
    buffer.writeln();
    buffer.writeln(
        _filterRow(_exportHeaders).map((h) => '"$h"').join(';'));
    for (final s in _summaries) {
      buffer.writeln(
          _filterRow(_summaryToRow(s)).map((v) => '"$v"').join(';'));
    }

    final filename =
        'rapport_carburant_global_${_startFmt.replaceAll('/', '-')}_${_endFmt.replaceAll('/', '-')}.csv';

    if (kIsWeb) {
      downloadFileWeb(buffer.toString(), filename);
      return;
    }
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsString(buffer.toString());
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          title: l10n.translate('fuel.directionReport'),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Export error: $e')));
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // EXPORT EXCEL
  // ═══════════════════════════════════════════════════════════════

  Future<void> _exportExcel(AppLocalizations l10n) async {
    final xls = xl.Excel.createExcel();
    const sheetName = 'Rapport Carburant';
    xls.rename('Sheet1', sheetName);
    final sheet = xls[sheetName];

    final infoStyle = xl.CellStyle(
      bold: true,
      backgroundColorHex: xl.ExcelColor.fromHexString('#EFF6FF'),
    );
    void addInfoRow(String label, String value) {
      sheet.appendRow([xl.TextCellValue(label), xl.TextCellValue(value)]);
      final rowIdx = sheet.maxRows - 1;
      sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx)).cellStyle = infoStyle;
      sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIdx)).cellStyle = infoStyle;
    }

    addInfoRow(l10n.translate('common.exportPeriod'), '$_startFmt → $_endFmt');
    addInfoRow(l10n.translate('common.exportFleets'), _fleetsSummary(l10n));
    addInfoRow(l10n.translate('common.exportVehicles'), _vehiclesSummaryDir(l10n));
    sheet.appendRow([xl.TextCellValue('')]);

    final headers = _filterRow(_exportHeaders);
    sheet.appendRow(headers.map(xl.TextCellValue.new).toList());

    final headerStyle = xl.CellStyle(
      bold: true,
      backgroundColorHex: xl.ExcelColor.fromHexString('#1E40AF'),
      fontColorHex: xl.ExcelColor.fromHexString('#FFFFFF'),
    );
    final headerRowIdx = sheet.maxRows - 1;
    for (var c = 0; c < headers.length; c++) {
      sheet
          .cell(xl.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: headerRowIdx))
          .cellStyle = headerStyle;
    }

    for (final s in _summaries) {
      sheet.appendRow(
          _filterRow(_summaryToRow(s)).map(xl.TextCellValue.new).toList());
    }

    for (var c = 0; c < headers.length; c++) {
      sheet.setColumnWidth(c, 20);
    }

    final bytes = xls.encode();
    if (bytes == null) return;
    final filename =
        'rapport_carburant_global_${DateTime.now().millisecondsSinceEpoch}.xlsx';

    if (kIsWeb) {
      downloadFileBytesWeb(bytes, filename);
      return;
    }
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          title: l10n.translate('fuel.directionReport'),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Export error: $e')));
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // EXPORT PDF
  // ═══════════════════════════════════════════════════════════════

  Future<void> _exportPdf(AppLocalizations l10n) async {
    final pdf = pw.Document();

    final headers = _filterRow(_exportHeaders);
    final rows = _summaries.map((s) => _filterRow(_summaryToRow(s))).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        header: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              l10n.translate('fuel.directionReport'),
              style: pw.TextStyle(
                  fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              '${l10n.translate('common.exportPeriod')} : $_startFmt → $_endFmt',
              style: const pw.TextStyle(
                  fontSize: 9, color: PdfColors.grey600),
            ),
            pw.Text(
              '${l10n.translate('common.exportFleets')} : ${_fleetsSummary(l10n)}',
              style: const pw.TextStyle(
                  fontSize: 9, color: PdfColors.grey600),
            ),
            pw.Text(
              '${l10n.translate('common.exportVehicles')} : ${_vehiclesSummaryDir(l10n)}',
              style: const pw.TextStyle(
                  fontSize: 9, color: PdfColors.grey600),
            ),
          ],
        ),
        build: (ctx) => [
          pw.SizedBox(height: 12),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              headers.length - 1: const pw.FlexColumnWidth(2),
              for (var i = 1; i < headers.length - 1; i++)
                i: const pw.FlexColumnWidth(),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFF1E40AF)),
                children: headers
                    .map((h) => pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            h,
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 6,
                            ),
                          ),
                        ))
                    .toList(),
              ),
              ...rows.asMap().entries.map((entry) {
                final isEven = entry.key.isEven;
                return pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: isEven ? PdfColors.grey50 : PdfColors.white,
                  ),
                  children: entry.value
                      .map((cell) => pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(cell,
                                style: const pw.TextStyle(fontSize: 6)),
                          ))
                      .toList(),
                );
              }),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Généré le ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
            style: const pw.TextStyle(
                fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );

    final filename =
        'rapport_carburant_global_${DateTime.now().millisecondsSinceEpoch}.pdf';
    try {
      final pdfBytes = await pdf.save();
      if (kIsWeb) {
        downloadFileBytesWeb(pdfBytes, filename);
        return;
      }
      await printOrSharePdf(pdfBytes, filename: filename);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Export error: $e')));
      }
    }
  }
}

/// Résumé par camion pour la vue direction
class _DirectionTruckSummary {
  _DirectionTruckSummary({
    required this.truckId,
    required this.immatriculation,
    required this.fleetNumber,
    required this.fleetName,
  });

  final String truckId;
  final String immatriculation;
  final String fleetNumber;
  final String fleetName;
  int requestCount = 0;
  double totalRequestedLiters = 0;
  double totalFulfilledLiters = 0;
  final List<String> receiptNumbers = [];
  final Map<FuelRequestStatus, int> countByStatus = {};
  final Map<FuelRequestStatus, double> litersByStatus = {};
}
