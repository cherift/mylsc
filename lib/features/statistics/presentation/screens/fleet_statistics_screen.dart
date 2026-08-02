import 'dart:io';
import 'package:excel/excel.dart' as xl;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/pdf_utils.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/file_download.dart';
import '../../../../core/widgets/dashboard_filter_modal.dart';
import '../../../fleet/domain/models/fleet_model.dart';
import '../../../fleet/presentation/providers/fleet_providers.dart';
import '../../../trucks/domain/models/truck_model.dart';
import '../../../shifts/presentation/providers/shift_providers.dart';
import '../../../weighing/presentation/providers/weighing_providers.dart';
import '../../../breakdown/presentation/providers/breakdown_providers.dart';
import '../../../dashboard/domain/models/dashboard_filter.dart';
import '../../../fuel/domain/models/fuel_request_model.dart';
import '../../../fuel/presentation/providers/fuel_request_providers.dart';

// Identifiants des indicateurs affichables
const _kIndicatorTrucks = 'trucksInService';
const _kIndicatorShifts = 'activeShifts';
const _kIndicatorMine = 'tonnageMine';
const _kIndicatorPort = 'tonnagePort';
const _kIndicatorBreakdowns = 'breakdowns';
const _kIndicatorWorkTime = 'totalWorkTime';
const _kIndicatorFuelServed = 'fuelServed';

class FleetStatisticsScreen extends ConsumerStatefulWidget {
  const FleetStatisticsScreen({super.key});

  @override
  ConsumerState<FleetStatisticsScreen> createState() =>
      _FleetStatisticsScreenState();
}

class _FleetStatisticsScreenState
    extends ConsumerState<FleetStatisticsScreen> {
  final Set<String> _selectedFleetIds = {};
  bool _selectAll = true;

  // Filtre date + véhicules
  DashboardFilter _filter = const DashboardFilter();

  // Indicateurs visibles (tous actifs par défaut)
  final Set<String> _selectedIndicators = {
    _kIndicatorTrucks,
    _kIndicatorShifts,
    _kIndicatorMine,
    _kIndicatorPort,
    _kIndicatorBreakdowns,
    _kIndicatorWorkTime,
    _kIndicatorFuelServed,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fleetsAsync = ref.watch(allFleetsProvider);

    return fleetsAsync.when(
      data: (fleets) {
        if (_selectedFleetIds.isEmpty && _selectAll) {
          _selectedFleetIds.addAll(fleets.map((f) => f.id));
        }
        final selected = fleets
            .where((f) => _selectedFleetIds.contains(f.id))
            .toList();

        return Column(
          children: [
            // ── Header ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: const BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: AppColors.surfaceBorder)),
              ),
              child: Row(
                children: [
                  const Icon(Iconsax.chart_21,
                      color: AppColors.primary, size: 22),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      l10n.translate('statistics.title'),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  // Bouton sélecteur d'indicateurs
                  _buildIndicatorButton(l10n),
                  const SizedBox(width: AppSpacing.sm),
                  // Bouton filtre date/véhicules
                  FilterIconButton(
                    isActive: _filter.isActive,
                    onTap: () => _openFilter(context, selected, fleets),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  // Bouton export multi-format (stats flottes + indicateurs clés)
                  PopupMenuButton<String>(
                    onSelected: (format) {
                      if (selected.isEmpty) return;
                      switch (format) {
                        case 'csv':
                          _exportCsv(context, selected, l10n);
                        case 'excel':
                          _exportExcel(context, selected, l10n);
                        case 'pdf':
                          _exportPdf(context, selected, l10n);
                        case 'kpi_csv':
                          _exportKpiCsv(context, selected, l10n);
                        case 'kpi_excel':
                          _exportKpiExcel(context, selected, l10n);
                        case 'kpi_pdf':
                          _exportKpiPdf(context, selected, l10n);
                      }
                    },
                    itemBuilder: (_) => [
                      // ── Stats comparatives flottes ──
                      PopupMenuItem(enabled: false,
                        child: Text(l10n.translate('statistics.exportGroupStats'),
                            style: const TextStyle(color: AppColors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600))),
                      PopupMenuItem(value: 'csv',
                        child: Row(children: [const Icon(Iconsax.document_text, size: 16), const SizedBox(width: 8), Text(l10n.translate('statistics.exportCsv'))])),
                      PopupMenuItem(value: 'excel',
                        child: Row(children: [const Icon(Iconsax.document_download, size: 16), const SizedBox(width: 8), Text(l10n.translate('statistics.exportExcel'))])),
                      PopupMenuItem(value: 'pdf',
                        child: Row(children: [const Icon(Iconsax.document_favorite, size: 16), const SizedBox(width: 8), Text(l10n.translate('statistics.exportPdf'))])),
                      // ── Indicateurs clés par période ──
                      const PopupMenuDivider(),
                      PopupMenuItem(enabled: false,
                        child: Text(l10n.translate('statistics.exportGroupKpi'),
                            style: const TextStyle(color: AppColors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600))),
                      PopupMenuItem(value: 'kpi_csv',
                        child: Row(children: [const Icon(Iconsax.document_text, size: 16), const SizedBox(width: 8), Text(l10n.translate('statistics.exportCsv'))])),
                      PopupMenuItem(value: 'kpi_excel',
                        child: Row(children: [const Icon(Iconsax.document_download, size: 16), const SizedBox(width: 8), Text(l10n.translate('statistics.exportExcel'))])),
                      PopupMenuItem(value: 'kpi_pdf',
                        child: Row(children: [const Icon(Iconsax.document_favorite, size: 16), const SizedBox(width: 8), Text(l10n.translate('statistics.exportPdf'))])),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: selected.isEmpty
                            ? AppColors.textTertiary
                            : AppColors.primary,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Iconsax.export_1,
                              color: Colors.white, size: 16),
                          if (!context.isMobile) ...[
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              l10n.translate('statistics.export'),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 13),
                            ),
                          ],
                          const Icon(Icons.arrow_drop_down,
                              color: Colors.white, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Sélection des flottes (filtres)
            if (fleets.length > 1) _buildFleetFilters(fleets, l10n),
            // Tableau comparatif
            Expanded(
              child: selected.isEmpty
                  ? Center(
                      child: Text(
                        l10n.translate('statistics.noFleetSelected'),
                        style: const TextStyle(
                            color: AppColors.textSecondary),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        children: [
                          // ── Indicateurs clés + cartes par flotte ──
                          ...selected.expand((fleet) => [
                            _PeriodKpiTable(fleet: fleet),
                            const SizedBox(height: AppSpacing.sm),
                            _FleetStatsCard(
                              fleet: fleet,
                              filter: _filter,
                              visibleIndicators: _selectedIndicators,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                          ]),
                        ],
                      ),
                    ),
            ),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, _) => Center(
        child: Text('Erreur: $e',
            style: const TextStyle(color: AppColors.error)),
      ),
    );
  }

  // ── Bouton indicateurs ───────────────────────────────────────
  Widget _buildIndicatorButton(AppLocalizations l10n) {
    final isMobile = context.isMobile;
    return GestureDetector(
      onTap: () => _openIndicatorSelector(l10n),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Iconsax.setting_4,
                color: AppColors.textSecondary, size: 16),
            if (!isMobile) ...[
              const SizedBox(width: 4),
              Text(
                l10n.translate('statistics.indicators'),
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openIndicatorSelector(AppLocalizations l10n) {
    final all = [
      _kIndicatorTrucks,
      _kIndicatorShifts,
      _kIndicatorMine,
      _kIndicatorPort,
      _kIndicatorBreakdowns,
      _kIndicatorWorkTime,
      _kIndicatorFuelServed,
    ];
    final labels = {
      _kIndicatorTrucks: l10n.translate('statistics.indicatorTrucks'),
      _kIndicatorShifts: l10n.translate('statistics.indicatorShifts'),
      _kIndicatorMine: l10n.translate('statistics.indicatorTonnageMine'),
      _kIndicatorPort: l10n.translate('statistics.indicatorTonnagePort'),
      _kIndicatorBreakdowns: l10n.translate('statistics.indicatorBreakdowns'),
      _kIndicatorWorkTime: l10n.translate('statistics.indicatorWorkTime'),
      _kIndicatorFuelServed: l10n.translate('statistics.indicatorFuelServed'),
    };

    showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    color: AppColors.backgroundSecondary,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Iconsax.setting_4,
                                color: AppColors.primary, size: 18),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              l10n.translate('statistics.selectIndicators'),
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ...all.map((id) {
                          return CheckboxListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              labels[id]!,
                              style: const TextStyle(
                                  color: AppColors.textPrimary, fontSize: 14),
                            ),
                            value: _selectedIndicators.contains(id),
                            activeColor: AppColors.primary,
                            onChanged: (v) {
                              setModalState(() {
                                setState(() {
                                  if (v ?? false) {
                                    _selectedIndicators.add(id);
                                  } else if (_selectedIndicators.length > 1) {
                                    _selectedIndicators.remove(id);
                                  }
                                });
                              });
                            },
                          );
                        }),
                        const SizedBox(height: AppSpacing.md),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                              ),
                            ),
                            child: Text(l10n.translate('common.close')),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Filtre date + véhicules ──────────────────────────────────
  void _openFilter(BuildContext context, List<FleetModel> selectedFleets,
      List<FleetModel> allFleets) {
    // Collecte tous les camions des flottes sélectionnées
    final trucks = <TruckModel>[];
    for (final fleet in selectedFleets) {
      final fleetTrucks =
          ref.read(fleetTrucksProvider(fleet.id)).valueOrNull ?? [];
      trucks.addAll(fleetTrucks);
    }

    DashboardFilterModal.show(
      context,
      availableTrucks: trucks,
      currentFilter: _filter,
      onApply: (f) => setState(() => _filter = f),
    );
  }

  Widget _buildFleetFilters(
      List<FleetModel> fleets, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      decoration: const BoxDecoration(
        border: Border(
            bottom: BorderSide(color: AppColors.surfaceBorder)),
      ),
      child: Scrollbar(
        thumbVisibility: true,
        child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
          },
        ),
        child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: Row(
          children: [
            FilterChip(
              label: Text(l10n.translate('common.all'),
                  style: const TextStyle(fontSize: 12)),
              selected: _selectAll,
              onSelected: (v) => setState(() {
                _selectAll = v;
                if (v) {
                  _selectedFleetIds.addAll(fleets.map((f) => f.id));
                } else {
                  _selectedFleetIds.clear();
                }
              }),
              selectedColor: AppColors.primary.withValues(alpha: 0.15),
              checkmarkColor: AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            ...fleets.map((fleet) => Padding(
                  padding:
                      const EdgeInsets.only(right: AppSpacing.sm),
                  child: FilterChip(
                    label: Text(fleet.name,
                        style: const TextStyle(fontSize: 12)),
                    selected: _selectedFleetIds.contains(fleet.id),
                    onSelected: (v) => setState(() {
                      if (v) {
                        _selectedFleetIds.add(fleet.id);
                      } else {
                        _selectedFleetIds.remove(fleet.id);
                        _selectAll = false;
                      }
                    }),
                    selectedColor:
                        AppColors.primary.withValues(alpha: 0.15),
                    checkmarkColor: AppColors.primary,
                  ),
                )),
          ],
        ),
        ),
        ),
      ),
    );
  }

  // ── Données par flotte ─────────────────────────────────────
  _FleetData _buildFleetData(FleetModel fleet) {
    final trucks =
        ref.read(fleetTrucksProvider(fleet.id)).valueOrNull ?? [];
    final truckIds = _effectiveTruckIds(trucks);
    final inService =
        trucks.where((t) => t.statut == TruckStatus.enService).length;
    final allMine =
        ref.read(mineWeighingsStreamProvider).valueOrNull ?? [];
    final allPort =
        ref.read(portWeighingsStreamProvider).valueOrNull ?? [];
    final allBreakdowns =
        ref.read(activeBreakdownsStreamProvider).valueOrNull ?? [];
    final allShifts =
        ref.read(activeShiftsStreamProvider).valueOrNull ?? [];
    final allShiftsAll =
        ref.read(allShiftsStreamProvider).valueOrNull ?? [];
    final mine = allMine.where((w) =>
        truckIds.contains(w.truckId) &&
        (_filter.matchesDate(w.createdAt))).toList();
    final port = allPort.where((w) =>
        truckIds.contains(w.truckId) &&
        (_filter.matchesDate(w.createdAt))).toList();
    final breakdowns =
        allBreakdowns.where((b) => truckIds.contains(b.truckId)).length;
    final shifts =
        allShifts.where((s) => truckIds.contains(s.truckId)).length;
    final endedShifts = allShiftsAll
        .where((s) => truckIds.contains(s.truckId) && s.endTime != null)
        .toList();
    final totalWorkTime = endedShifts.fold<Duration>(
        Duration.zero, (acc, s) => acc + (s.duration ?? Duration.zero));
    final totalMine = mine.fold<double>(0, (s, w) => s + w.weight);
    final totalPort = port.fold<double>(0, (s, w) => s + w.weight);
    final allReqs =
        ref.read(allRequestsStreamProvider).valueOrNull ?? [];
    final totalFuelServed = allReqs
        .where((r) =>
            truckIds.contains(r.truckId) &&
            (r.status == FuelRequestStatus.fulfilled ||
                r.status == FuelRequestStatus.validated) &&
            _filter.matchesDate(r.createdAt))
        .fold<double>(0, (s, r) => s + (r.fulfilledLiters ?? 0));

    return _FleetData(
      fleet: fleet,
      trucksInService: inService,
      trucksTotal: trucks.length,
      activeShifts: shifts,
      totalMine: totalMine,
      totalPort: totalPort,
      breakdowns: breakdowns,
      totalWorkTime: totalWorkTime,
      totalFuelServed: totalFuelServed,
    );
  }

  /// Retourne les truckIds effectifs (filtre véhicule appliqué)
  Set<String> _effectiveTruckIds(List<TruckModel> fleetTrucks) {
    final all = fleetTrucks.map((t) => t.id).toSet();
    if (_filter.selectedTruckIds == null) return all;
    return all.intersection(_filter.selectedTruckIds!);
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _periodSummary(AppLocalizations l10n) {
    final dr = _filter.dateRange;
    if (dr == null) return l10n.translate('common.exportAllPeriods');
    return '${_fmtDate(dr.start)} → ${_fmtDate(dr.end)}';
  }

  String _fleetsSummaryStats(AppLocalizations l10n, List<FleetModel> selected) {
    if (_selectAll) return l10n.translate('common.exportAllFleets');
    return selected.map((f) => f.name).join(', ');
  }

  String _vehiclesSummaryStats(AppLocalizations l10n) {
    final ids = _filter.selectedTruckIds;
    if (ids == null || ids.isEmpty) return l10n.translate('common.exportAllVehicles');
    return '${ids.length} sélectionné(s)';
  }

  // ── Export CSV ──────────────────────────────────────────────
  Future<void> _exportCsv(BuildContext context,
      List<FleetModel> fleets, AppLocalizations l10n) async {
    final numFmt = NumberFormat('#,##0.0', 'fr_FR');
    final buffer = StringBuffer();
    buffer.writeln('"${l10n.translate('common.exportPeriod')}";"${_periodSummary(l10n)}"');
    buffer.writeln('"${l10n.translate('common.exportFleets')}";"${_fleetsSummaryStats(l10n, fleets)}"');
    buffer.writeln('"${l10n.translate('common.exportVehicles')}";"${_vehiclesSummaryStats(l10n)}"');
    buffer.writeln();
    final headers = _buildExportHeaders(l10n);
    buffer.writeln(headers.join(';'));
    for (final fleet in fleets) {
      final d = _buildFleetData(fleet);
      buffer.writeln(_buildExportRow(d, numFmt).join(';'));
    }
    final csvString = buffer.toString();
    final filename =
        'statistiques_flottes_${DateTime.now().millisecondsSinceEpoch}.csv';
    if (kIsWeb) {
      downloadFileWeb(csvString, filename);
      return;
    }
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsString(csvString);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          title: l10n.translate('statistics.title'),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export error: $e')),
        );
      }
    }
  }

  // ── Export Excel ────────────────────────────────────────────
  Future<void> _exportExcel(BuildContext context,
      List<FleetModel> fleets, AppLocalizations l10n) async {
    final numFmt = NumberFormat('#,##0.0', 'fr_FR');
    final xls = xl.Excel.createExcel();
    const sheetName = 'Statistiques';
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

    addInfoRow(l10n.translate('common.exportPeriod'), _periodSummary(l10n));
    addInfoRow(l10n.translate('common.exportFleets'), _fleetsSummaryStats(l10n, fleets));
    addInfoRow(l10n.translate('common.exportVehicles'), _vehiclesSummaryStats(l10n));
    sheet.appendRow([xl.TextCellValue('')]);

    final headers = _buildExportHeaders(l10n);
    sheet.appendRow(headers.map(xl.TextCellValue.new).toList());

    final headerStyle = xl.CellStyle(
      bold: true,
      backgroundColorHex: xl.ExcelColor.fromHexString('#1E40AF'),
      fontColorHex: xl.ExcelColor.fromHexString('#FFFFFF'),
    );
    final headerRowIdx = sheet.maxRows - 1;
    for (var c = 0; c < headers.length; c++) {
      sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: headerRowIdx))
          .cellStyle = headerStyle;
    }

    for (final fleet in fleets) {
      final d = _buildFleetData(fleet);
      sheet.appendRow(
          _buildExportRow(d, numFmt).map(xl.TextCellValue.new).toList());
    }

    for (var c = 0; c < headers.length; c++) {
      sheet.setColumnWidth(c, 20);
    }

    final bytes = xls.encode();
    if (bytes == null) return;
    final filename =
        'statistiques_flottes_${DateTime.now().millisecondsSinceEpoch}.xlsx';

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
          title: l10n.translate('statistics.title'),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export error: $e')),
        );
      }
    }
  }

  // ── Export PDF ──────────────────────────────────────────────
  Future<void> _exportPdf(BuildContext context,
      List<FleetModel> fleets, AppLocalizations l10n) async {
    final numFmt = NumberFormat('#,##0.0', 'fr_FR');
    final pdf = pw.Document();

    final headers = _buildExportHeaders(l10n);

    final rows = fleets.map((fleet) {
      final d = _buildFleetData(fleet);
      return _buildExportRow(d, numFmt);
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        header: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              l10n.translate('statistics.title'),
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              '${l10n.translate('common.exportPeriod')} : ${_periodSummary(l10n)}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
            pw.Text(
              '${l10n.translate('common.exportFleets')} : ${_fleetsSummaryStats(l10n, fleets)}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
            if (_filter.selectedTruckIds != null && _filter.selectedTruckIds!.isNotEmpty)
              pw.Text(
                '${l10n.translate('common.exportVehicles')} : ${_vehiclesSummaryStats(l10n)}',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              ),
          ],
        ),
        build: (ctx) => [
          pw.SizedBox(height: 12),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              for (var i = 1; i < headers.length; i++)
                i: const pw.FlexColumnWidth(),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFF1E40AF)),
                children: headers
                    .map((h) => pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            h,
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
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
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(cell,
                                style: const pw.TextStyle(fontSize: 9)),
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
        'statistiques_flottes_${DateTime.now().millisecondsSinceEpoch}.pdf';
    try {
      final pdfBytes = await pdf.save();
      if (kIsWeb) {
        downloadFileBytesWeb(pdfBytes, filename);
        return;
      }
      await printOrSharePdf(pdfBytes, filename: filename);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export error: $e')),
        );
      }
    }
  }

  // ── Helpers export ──────────────────────────────────────────
  List<String> _buildExportHeaders(AppLocalizations l10n) {
    return [
      l10n.translate('statistics.csv.fleet'),
      if (_selectedIndicators.contains(_kIndicatorTrucks))
        l10n.translate('statistics.csv.trucks'),
      if (_selectedIndicators.contains(_kIndicatorShifts))
        l10n.translate('statistics.csv.vacations'),
      if (_selectedIndicators.contains(_kIndicatorMine))
        l10n.translate('statistics.csv.tonnageMine'),
      if (_selectedIndicators.contains(_kIndicatorPort))
        l10n.translate('statistics.csv.tonnagePort'),
      if (_selectedIndicators.contains(_kIndicatorBreakdowns))
        l10n.translate('statistics.csv.breakdowns'),
      if (_selectedIndicators.contains(_kIndicatorWorkTime))
        l10n.translate('statistics.csv.workTime'),
      if (_selectedIndicators.contains(_kIndicatorFuelServed))
        l10n.translate('statistics.csv.totalFuelServed'),
    ];
  }

  List<String> _buildExportRow(_FleetData d, NumberFormat fmt) {
    return [
      '"${d.fleet.name}"',
      if (_selectedIndicators.contains(_kIndicatorTrucks))
        '${d.trucksInService}/${d.trucksTotal}',
      if (_selectedIndicators.contains(_kIndicatorShifts))
        '${d.activeShifts}',
      if (_selectedIndicators.contains(_kIndicatorMine))
        fmt.format(d.totalMine),
      if (_selectedIndicators.contains(_kIndicatorPort))
        fmt.format(d.totalPort),
      if (_selectedIndicators.contains(_kIndicatorBreakdowns))
        '${d.breakdowns}',
      if (_selectedIndicators.contains(_kIndicatorWorkTime))
        '${d.totalWorkTime.inHours}h${(d.totalWorkTime.inMinutes % 60).toString().padLeft(2, '0')}',
      if (_selectedIndicators.contains(_kIndicatorFuelServed))
        fmt.format(d.totalFuelServed),
    ];
  }

  // ── Calcul KPI période pour une flotte ──────────────────────
  List<_PRow> _computeKpiRows(
      FleetModel fleet, AppLocalizations l10n, NumberFormat numFmt) {
    final trucks = ref.read(fleetTrucksProvider(fleet.id)).valueOrNull ?? [];
    final truckIds = trucks.map((t) => t.id).toSet();
    final allShifts = ref.read(allShiftsStreamProvider).valueOrNull ?? [];
    final allMine   = ref.read(mineWeighingsStreamProvider).valueOrNull ?? [];
    final allPort   = ref.read(portWeighingsStreamProvider).valueOrNull ?? [];
    final allReqs   = ref.read(allRequestsStreamProvider).valueOrNull ?? [];
    final shifts = allShifts.where((s) => truckIds.contains(s.truckId)).toList();
    final mine   = allMine.where((w) => truckIds.contains(w.truckId)).toList();
    final port   = allPort.where((w) => truckIds.contains(w.truckId)).toList();
    final reqs   = allReqs.where((r) => truckIds.contains(r.truckId)).toList();
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart  = todayStart.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month);
    final endDay     = DateTime(now.year, now.month, now.day, 23, 59, 59);
    bool inD(DateTime? dt) => dt != null && !dt.isBefore(todayStart) && !dt.isAfter(endDay);
    bool inW(DateTime? dt) => dt != null && !dt.isBefore(weekStart)  && !dt.isAfter(endDay);
    bool inM(DateTime? dt) => dt != null && !dt.isBefore(monthStart) && !dt.isAfter(endDay);
    final served = reqs.where((r) =>
        r.status == FuelRequestStatus.fulfilled ||
        r.status == FuelRequestStatus.validated);
    return [
      _PRow(icon: Iconsax.driver,       label: l10n.translate('statistics.periodDrivers'),
            day: numFmt.format(shifts.where((s) => inD(s.startTime)).map((s) => s.driverId).toSet().length),
            week: numFmt.format(shifts.where((s) => inW(s.startTime)).map((s) => s.driverId).toSet().length),
            month: numFmt.format(shifts.where((s) => inM(s.startTime)).map((s) => s.driverId).toSet().length),
            color: AppColors.primary),
      _PRow(icon: Iconsax.route_square, label: l10n.translate('statistics.periodMine'),
            day: numFmt.format(mine.where((w) => inD(w.createdAt)).length),
            week: numFmt.format(mine.where((w) => inW(w.createdAt)).length),
            month: numFmt.format(mine.where((w) => inM(w.createdAt)).length),
            color: AppColors.info),
      _PRow(icon: Iconsax.route_square, label: l10n.translate('statistics.periodPort'),
            day: numFmt.format(port.where((w) => inD(w.createdAt)).length),
            week: numFmt.format(port.where((w) => inW(w.createdAt)).length),
            month: numFmt.format(port.where((w) => inM(w.createdAt)).length),
            color: AppColors.accent),
      _PRow(icon: Iconsax.gas_station,  label: l10n.translate('statistics.periodFuel'),
            day: '${numFmt.format(served.where((r) => inD(r.createdAt)).fold<double>(0, (s, r) => s + (r.fulfilledLiters ?? 0)).round())} L',
            week: '${numFmt.format(served.where((r) => inW(r.createdAt)).fold<double>(0, (s, r) => s + (r.fulfilledLiters ?? 0)).round())} L',
            month: '${numFmt.format(served.where((r) => inM(r.createdAt)).fold<double>(0, (s, r) => s + (r.fulfilledLiters ?? 0)).round())} L',
            color: const Color(0xFF059669)),
      _PRow(icon: Iconsax.weight,       label: l10n.translate('statistics.periodTonnageMine'),
            day: '${numFmt.format(mine.where((w) => inD(w.createdAt)).fold<double>(0, (s, w) => s + w.weight).round())} T',
            week: '${numFmt.format(mine.where((w) => inW(w.createdAt)).fold<double>(0, (s, w) => s + w.weight).round())} T',
            month: '${numFmt.format(mine.where((w) => inM(w.createdAt)).fold<double>(0, (s, w) => s + w.weight).round())} T',
            color: AppColors.warning),
      _PRow(icon: Iconsax.weight,       label: l10n.translate('statistics.periodTonnagePort'),
            day: '${numFmt.format(port.where((w) => inD(w.createdAt)).fold<double>(0, (s, w) => s + w.weight).round())} T',
            week: '${numFmt.format(port.where((w) => inW(w.createdAt)).fold<double>(0, (s, w) => s + w.weight).round())} T',
            month: '${numFmt.format(port.where((w) => inM(w.createdAt)).fold<double>(0, (s, w) => s + w.weight).round())} T',
            color: const Color(0xFF7C3AED)),
    ];
  }

  // ── Export global KPI ────────────────────────────────────────
  List<String> _kpiHeaders(AppLocalizations l10n) => [
        l10n.translate('statistics.csv.fleet'),
        l10n.translate('statistics.periodIndicator'),
        l10n.translate('statistics.periodDay'),
        l10n.translate('statistics.periodWeek'),
        l10n.translate('statistics.periodMonth'),
      ];

  Future<void> _exportKpiCsv(BuildContext context,
      List<FleetModel> fleets, AppLocalizations l10n) async {
    final numFmt = NumberFormat('#,##0', 'fr_FR');
    final buf = StringBuffer();
    buf.writeln(_kpiHeaders(l10n).map((h) => '"$h"').join(';'));
    for (final fleet in fleets) {
      for (final row in _computeKpiRows(fleet, l10n, numFmt)) {
        buf.writeln(['"${fleet.name}"', '"${row.label}"', '"${row.day}"', '"${row.week}"', '"${row.month}"'].join(';'));
      }
    }
    const filename = 'indicateurs_cles.csv';
    if (kIsWeb) { downloadFileWeb(buf.toString(), filename); return; }
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsString(buf.toString());
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], title: l10n.translate('statistics.periodTitle')));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export error: $e')));
    }
  }

  Future<void> _exportKpiExcel(BuildContext context,
      List<FleetModel> fleets, AppLocalizations l10n) async {
    final numFmt = NumberFormat('#,##0', 'fr_FR');
    final xls = xl.Excel.createExcel();
    xls.rename('Sheet1', 'Indicateurs');
    final sheet = xls['Indicateurs'];
    final headers = _kpiHeaders(l10n);
    sheet.appendRow(headers.map(xl.TextCellValue.new).toList());
    final hs = xl.CellStyle(
      bold: true,
      backgroundColorHex: xl.ExcelColor.fromHexString('#1E40AF'),
      fontColorHex: xl.ExcelColor.fromHexString('#FFFFFF'),
    );
    for (var c = 0; c < headers.length; c++) {
      sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0)).cellStyle = hs;
    }
    for (final fleet in fleets) {
      for (final row in _computeKpiRows(fleet, l10n, numFmt)) {
        sheet.appendRow([fleet.name, row.label, row.day, row.week, row.month].map(xl.TextCellValue.new).toList());
      }
    }
    for (var c = 0; c < headers.length; c++) { sheet.setColumnWidth(c, 20); }
    final bytes = xls.encode();
    if (bytes == null) return;
    const filename = 'indicateurs_cles.xlsx';
    if (kIsWeb) { downloadFileBytesWeb(bytes, filename); return; }
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes);
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], title: l10n.translate('statistics.periodTitle')));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export error: $e')));
    }
  }

  Future<void> _exportKpiPdf(BuildContext context,
      List<FleetModel> fleets, AppLocalizations l10n) async {
    final numFmt = NumberFormat('#,##0', 'fr_FR');
    final pdf = pw.Document();
    final headers = _kpiHeaders(l10n);
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      header: (ctx) => pw.Text(l10n.translate('statistics.periodTitle'),
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
      build: (ctx) => [
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {0: const pw.FlexColumnWidth(1.5), 1: const pw.FlexColumnWidth(2), for (var i = 2; i < 5; i++) i: const pw.FlexColumnWidth()},
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1E40AF)),
              children: headers.map((h) => pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(h, style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 8)),
              )).toList(),
            ),
            ...fleets.expand((fleet) {
              final rows = _computeKpiRows(fleet, l10n, numFmt);
              return rows.asMap().entries.map((entry) => pw.TableRow(
                decoration: pw.BoxDecoration(color: entry.key.isEven ? PdfColors.grey50 : PdfColors.white),
                children: [if (entry.key == 0) fleet.name else '', entry.value.label, entry.value.day, entry.value.week, entry.value.month]
                    .map((cell) => pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(cell, style: const pw.TextStyle(fontSize: 8))))
                    .toList(),
              ));
            }),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Text('Généré le ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
      ],
    ));
    const filename = 'indicateurs_cles.pdf';
    try {
      final pdfBytes = await pdf.save();
      if (kIsWeb) { downloadFileBytesWeb(pdfBytes, filename); return; }
      await printOrSharePdf(pdfBytes, filename: filename);
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export error: $e')));
    }
  }
}

// ── Modèle de données par flotte ────────────────────────────
class _FleetData {
  const _FleetData({
    required this.fleet,
    required this.trucksInService,
    required this.trucksTotal,
    required this.activeShifts,
    required this.totalMine,
    required this.totalPort,
    required this.breakdowns,
    required this.totalWorkTime,
    required this.totalFuelServed,
  });
  final FleetModel fleet;
  final int trucksInService;
  final int trucksTotal;
  final int activeShifts;
  final double totalMine;
  final double totalPort;
  final int breakdowns;
  final Duration totalWorkTime;
  final double totalFuelServed;
}

// ── Carte de statistiques pour une flotte ───────────────────
class _FleetStatsCard extends ConsumerWidget {
  const _FleetStatsCard({
    required this.fleet,
    required this.filter,
    required this.visibleIndicators,
  });

  final FleetModel fleet;
  final DashboardFilter filter;
  final Set<String> visibleIndicators;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final numFmt = NumberFormat('#,##0', 'fr_FR');

    final allTrucks =
        ref.watch(fleetTrucksProvider(fleet.id)).valueOrNull ?? [];

    // Appliquer filtre véhicule
    final trucks = filter.selectedTruckIds != null
        ? allTrucks.where((t) => filter.matchesTruck(t.id)).toList()
        : allTrucks;

    final truckIds = trucks.map((t) => t.id).toSet();
    final inService =
        trucks.where((t) => t.statut == TruckStatus.enService).length;

    final allMine =
        ref.watch(mineWeighingsStreamProvider).valueOrNull ?? [];
    final allPort =
        ref.watch(portWeighingsStreamProvider).valueOrNull ?? [];
    final allBreakdowns =
        ref.watch(activeBreakdownsStreamProvider).valueOrNull ?? [];
    final allShifts =
        ref.watch(activeShiftsStreamProvider).valueOrNull ?? [];
    final allShiftsAll =
        ref.watch(allShiftsStreamProvider).valueOrNull ?? [];

    // Filtre date + camion sur les pesées
    final mine = allMine.where((w) =>
        truckIds.contains(w.truckId) && filter.matchesDate(w.createdAt)).toList();
    final port = allPort.where((w) =>
        truckIds.contains(w.truckId) && filter.matchesDate(w.createdAt)).toList();
    final breakdowns =
        allBreakdowns.where((b) => truckIds.contains(b.truckId)).length;
    final activeShifts =
        allShifts.where((s) => truckIds.contains(s.truckId)).length;
    final endedShifts = allShiftsAll
        .where((s) => truckIds.contains(s.truckId) && s.endTime != null)
        .toList();
    final totalWorkTime = endedShifts.fold<Duration>(
        Duration.zero, (acc, s) => acc + (s.duration ?? Duration.zero));

    final totalMine = mine.fold<double>(0, (s, w) => s + w.weight);
    final totalPort = port.fold<double>(0, (s, w) => s + w.weight);

    // Construction des items selon les indicateurs sélectionnés
    final items = <_StatItem>[];
    if (visibleIndicators.contains(_kIndicatorTrucks)) {
      items.add(_StatItem(
        icon: Iconsax.truck,
        label: l10n.translate('directionDashboard.vehiclesInService'),
        value: '$inService/${trucks.length}',
        color: AppColors.success,
      ));
    }
    if (visibleIndicators.contains(_kIndicatorShifts)) {
      items.add(_StatItem(
        icon: Iconsax.clock,
        label: l10n.translate('shift.activeShift'),
        value: '$activeShifts',
        color: AppColors.primary,
      ));
    }
    if (visibleIndicators.contains(_kIndicatorMine)) {
      items.add(_StatItem(
        icon: Iconsax.weight,
        label: l10n.translate('directionDashboard.tonnageMine'),
        value: '${numFmt.format(totalMine.round())} T',
        color: AppColors.info,
      ));
    }
    if (visibleIndicators.contains(_kIndicatorPort)) {
      items.add(_StatItem(
        icon: Iconsax.weight,
        label: l10n.translate('directionDashboard.tonnagePort'),
        value: '${numFmt.format(totalPort.round())} T',
        color: AppColors.accent,
      ));
    }
    if (visibleIndicators.contains(_kIndicatorBreakdowns)) {
      items.add(_StatItem(
        icon: Iconsax.warning_2,
        label: l10n.translate('directionDashboard.activeBreakdowns'),
        value: '$breakdowns',
        color: AppColors.error,
      ));
    }
    if (visibleIndicators.contains(_kIndicatorWorkTime)) {
      final h = totalWorkTime.inHours;
      final m = totalWorkTime.inMinutes % 60;
      items.add(_StatItem(
        icon: Iconsax.timer_1,
        label: l10n.translate('statistics.indicatorWorkTime'),
        value: '${h}h${m.toString().padLeft(2, '0')}',
        color: const Color(0xFF7C3AED),
      ));
    }
    if (visibleIndicators.contains(_kIndicatorFuelServed)) {
      final allReqs =
          ref.watch(allRequestsStreamProvider).valueOrNull ?? [];
      final fuelServed = allReqs
          .where((r) =>
              truckIds.contains(r.truckId) &&
              (r.status == FuelRequestStatus.fulfilled ||
                  r.status == FuelRequestStatus.validated) &&
              filter.matchesDate(r.createdAt))
          .fold<double>(0, (s, r) => s + (r.fulfilledLiters ?? 0));
      items.add(_StatItem(
        icon: Iconsax.gas_station,
        label: l10n.translate('statistics.indicatorFuelServed'),
        value: '${numFmt.format(fuelServed.round())} L',
        color: const Color(0xFF059669),
      ));
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: const BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: AppColors.surfaceBorder)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(Iconsax.truck_fast,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  fleet.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 500;
                  if (isWide) {
                    return Row(
                      children: items
                          .map((item) => Expanded(
                                child: _buildStatCell(item),
                              ))
                          .toList(),
                    );
                  }
                  return Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.sm,
                    children: items
                        .map((item) => SizedBox(
                              width: (constraints.maxWidth - AppSpacing.md) / 2,
                              child: _buildStatCell(item),
                            ))
                        .toList(),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCell(_StatItem item) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: item.color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: item.color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.icon, color: item.color, size: 16),
          const SizedBox(height: 4),
          Text(
            item.value,
            style: TextStyle(
              color: item.color,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            item.label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _StatItem {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
}

// ── Tableau KPI Jour / Semaine / Mois (par flotte) ─────────────────────────
class _PeriodKpiTable extends ConsumerStatefulWidget {
  const _PeriodKpiTable({required this.fleet});

  final FleetModel fleet;

  @override
  ConsumerState<_PeriodKpiTable> createState() => _PeriodKpiTableState();
}

class _PeriodKpiTableState extends ConsumerState<_PeriodKpiTable> {
  int _selectedPeriod = 0; // 0=jour 1=semaine 2=mois

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final numFmt = NumberFormat('#,##0', 'fr_FR');

    // Trucks de la flotte
    final trucks =
        ref.watch(fleetTrucksProvider(widget.fleet.id)).valueOrNull ?? [];
    final truckIds = trucks.map((t) => t.id).toSet();

    // Data sources globaux filtrés par flotte
    final allShifts =
        ref.watch(allShiftsStreamProvider).valueOrNull ?? [];
    final allMine =
        ref.watch(mineWeighingsStreamProvider).valueOrNull ?? [];
    final allPort =
        ref.watch(portWeighingsStreamProvider).valueOrNull ?? [];
    final allRequests =
        ref.watch(allRequestsStreamProvider).valueOrNull ?? [];

    final shifts = allShifts.where((s) => truckIds.contains(s.truckId)).toList();
    final mine = allMine.where((w) => truckIds.contains(w.truckId)).toList();
    final port = allPort.where((w) => truckIds.contains(w.truckId)).toList();
    final requests = allRequests.where((r) => truckIds.contains(r.truckId)).toList();

    // Plages de dates
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month);
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);

    bool inDay(DateTime? dt) =>
        dt != null && !dt.isBefore(todayStart) && !dt.isAfter(endOfToday);
    bool inWeek(DateTime? dt) =>
        dt != null && !dt.isBefore(weekStart) && !dt.isAfter(endOfToday);
    bool inMonth(DateTime? dt) =>
        dt != null && !dt.isBefore(monthStart) && !dt.isAfter(endOfToday);

    // ── Chauffeurs actifs (distincts par vacation)
    final dDay = shifts.where((s) => inDay(s.startTime)).map((s) => s.driverId).toSet().length;
    final dWeek = shifts.where((s) => inWeek(s.startTime)).map((s) => s.driverId).toSet().length;
    final dMonth = shifts.where((s) => inMonth(s.startTime)).map((s) => s.driverId).toSet().length;

    // ── Rotations Mine (nb pesées)
    final mCntDay = mine.where((w) => inDay(w.createdAt)).length;
    final mCntWeek = mine.where((w) => inWeek(w.createdAt)).length;
    final mCntMonth = mine.where((w) => inMonth(w.createdAt)).length;

    // ── Rotations Port (nb pesées)
    final pCntDay = port.where((w) => inDay(w.createdAt)).length;
    final pCntWeek = port.where((w) => inWeek(w.createdAt)).length;
    final pCntMonth = port.where((w) => inMonth(w.createdAt)).length;

    // ── Carburant servis (litres)
    final served = requests.where((r) =>
        r.status == FuelRequestStatus.fulfilled ||
        r.status == FuelRequestStatus.validated);
    final fDay = served.where((r) => inDay(r.createdAt)).fold<double>(0, (s, r) => s + (r.fulfilledLiters ?? 0));
    final fWeek = served.where((r) => inWeek(r.createdAt)).fold<double>(0, (s, r) => s + (r.fulfilledLiters ?? 0));
    final fMonth = served.where((r) => inMonth(r.createdAt)).fold<double>(0, (s, r) => s + (r.fulfilledLiters ?? 0));

    // ── Tonnage Mine (T)
    final tmDay = mine.where((w) => inDay(w.createdAt)).fold<double>(0, (s, w) => s + w.weight);
    final tmWeek = mine.where((w) => inWeek(w.createdAt)).fold<double>(0, (s, w) => s + w.weight);
    final tmMonth = mine.where((w) => inMonth(w.createdAt)).fold<double>(0, (s, w) => s + w.weight);

    // ── Tonnage Port (T)
    final tpDay = port.where((w) => inDay(w.createdAt)).fold<double>(0, (s, w) => s + w.weight);
    final tpWeek = port.where((w) => inWeek(w.createdAt)).fold<double>(0, (s, w) => s + w.weight);
    final tpMonth = port.where((w) => inMonth(w.createdAt)).fold<double>(0, (s, w) => s + w.weight);

    final rows = [
      _PRow(icon: Iconsax.driver,      label: l10n.translate('statistics.periodDrivers'),     day: numFmt.format(dDay),                  week: numFmt.format(dWeek),                  month: numFmt.format(dMonth),                color: AppColors.primary),
      _PRow(icon: Iconsax.route_square, label: l10n.translate('statistics.periodMine'),        day: numFmt.format(mCntDay),               week: numFmt.format(mCntWeek),               month: numFmt.format(mCntMonth),             color: AppColors.info),
      _PRow(icon: Iconsax.route_square, label: l10n.translate('statistics.periodPort'),        day: numFmt.format(pCntDay),               week: numFmt.format(pCntWeek),               month: numFmt.format(pCntMonth),             color: AppColors.accent),
      _PRow(icon: Iconsax.weight,       label: l10n.translate('statistics.periodTonnageMine'), day: '${numFmt.format(tmDay.round())} T',  week: '${numFmt.format(tmWeek.round())} T',  month: '${numFmt.format(tmMonth.round())} T', color: AppColors.warning),
      _PRow(icon: Iconsax.weight,       label: l10n.translate('statistics.periodTonnagePort'), day: '${numFmt.format(tpDay.round())} T',  week: '${numFmt.format(tpWeek.round())} T',  month: '${numFmt.format(tpMonth.round())} T', color: const Color(0xFF7C3AED)),
      _PRow(icon: Iconsax.gas_station,  label: l10n.translate('statistics.periodFuel'),        day: '${numFmt.format(fDay.round())} L',   week: '${numFmt.format(fWeek.round())} L',   month: '${numFmt.format(fMonth.round())} L', color: const Color(0xFF059669)),
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── En-tête flotte ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              children: [
                const Icon(Iconsax.calendar_2,
                    color: AppColors.primary, size: 16),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    '${widget.fleet.name} — ${l10n.translate('statistics.periodTitle')}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.surfaceBorder, height: 1),

          LayoutBuilder(builder: (context, constraints) {
            final isWide = constraints.maxWidth > 500;

            if (isWide) {
              // ── Tableau horizontal ──────────────────────────────
              return Table(
                columnWidths: const {
                  0: FlexColumnWidth(2.2),
                  1: FlexColumnWidth(),
                  2: FlexColumnWidth(),
                  3: FlexColumnWidth(),
                },
                children: [
                  TableRow(
                    decoration: const BoxDecoration(
                        color: AppColors.backgroundSecondary),
                    children: [
                      _tc(l10n.translate('statistics.periodIndicator'), isHeader: true),
                      _tc(l10n.translate('statistics.periodDay'),        isHeader: true, centered: true),
                      _tc(l10n.translate('statistics.periodWeek'),       isHeader: true, centered: true),
                      _tc(l10n.translate('statistics.periodMonth'),      isHeader: true, centered: true),
                    ],
                  ),
                  ...rows.map((row) => TableRow(
                        decoration: const BoxDecoration(
                            border: Border(top: BorderSide(color: AppColors.surfaceBorder))),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md, vertical: AppSpacing.md),
                            child: Row(children: [
                              Icon(row.icon, color: row.color, size: 14),
                              const SizedBox(width: AppSpacing.sm),
                              Flexible(
                                child: Text(row.label,
                                    style: const TextStyle(
                                        color: AppColors.textPrimary, fontSize: 12)),
                              ),
                            ]),
                          ),
                          _vc(row.day,   row.color),
                          _vc(row.week,  row.color),
                          _vc(row.month, row.color),
                        ],
                      )),
                ],
              );
            } else {
              // ── Toggle + grille 2×3 ─────────────────────────────
              final periods = [
                l10n.translate('statistics.periodDay'),
                l10n.translate('statistics.periodWeek'),
                l10n.translate('statistics.periodMonth'),
              ];
              final vals = rows.map((r) => switch (_selectedPeriod) {
                    1 => r.week,
                    2 => r.month,
                    _ => r.day,
                  }).toList();

              return Column(children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: List.generate(3, (i) => Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedPeriod = i),
                        child: Container(
                          margin: EdgeInsets.only(right: i < 2 ? AppSpacing.xs : 0),
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: _selectedPeriod == i
                                ? AppColors.primary
                                : AppColors.backgroundSecondary,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text(periods[i],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _selectedPeriod == i ? Colors.white : AppColors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              )),
                        ),
                      ),
                    )),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: AppSpacing.sm,
                    mainAxisSpacing: AppSpacing.sm,
                    childAspectRatio: 2.2,
                    children: List.generate(rows.length, (i) => Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: rows[i].color.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: rows[i].color.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(children: [
                            Icon(rows[i].icon, color: rows[i].color, size: 13),
                            const SizedBox(width: 4),
                            Expanded(child: Text(rows[i].label,
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 9),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis)),
                          ]),
                          const SizedBox(height: 2),
                          Text(vals[i], style: TextStyle(color: rows[i].color, fontSize: 15, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    )),
                  ),
                ),
              ]);
            }
          }),
        ],
      ),
    );
  }

  // ── Helpers affichage ──
  static Widget _tc(String t, {bool isHeader = false, bool centered = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Text(t,
            textAlign: centered ? TextAlign.center : TextAlign.start,
            style: TextStyle(
              color: isHeader ? AppColors.textSecondary : AppColors.textPrimary,
              fontSize: isHeader ? 10 : 12,
              fontWeight: isHeader ? FontWeight.w600 : FontWeight.w400,
            )),
      );

  static Widget _vc(String v, Color c) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
        child: Text(v,
            textAlign: TextAlign.center,
            style: TextStyle(color: c, fontSize: 13, fontWeight: FontWeight.w700)),
      );


}

class _PRow {
  const _PRow({
    required this.icon,
    required this.label,
    required this.day,
    required this.week,
    required this.month,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String day;
  final String week;
  final String month;
  final Color color;
}

