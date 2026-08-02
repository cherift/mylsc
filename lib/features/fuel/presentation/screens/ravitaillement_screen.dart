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
import '../../../../core/widgets/inline_error_retry.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/models/fuel_supply_entry_model.dart';
import '../providers/fuel_supply_providers.dart';
import 'direction_fuel_report_screen.dart';

/// Écran principal Ravitaillement, 2 onglets :
/// 0 – Ravitaillement : saisie + liste des livraisons de carburant au stock
/// 1 – Rapport Global : rapport de consommation multi-flottes
class RavitaillementScreen extends ConsumerStatefulWidget {
  const RavitaillementScreen({super.key});

  @override
  ConsumerState<RavitaillementScreen> createState() =>
      _RavitaillementScreenState();
}

class _RavitaillementScreenState extends ConsumerState<RavitaillementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Filtres onglet Ravitaillement
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundSecondary,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const Icon(Iconsax.gas_station,
                color: AppColors.primary, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Text(
              l10n.translate('ravitaillement.title'),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(49),
          child: Column(
            children: [
              Container(height: 1, color: AppColors.surfaceBorder),
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(text: l10n.translate('ravitaillement.tabSupply')),
                  Tab(text: l10n.translate('ravitaillement.tabReport')),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _RavitaillementTab(
            startDate: _startDate,
            endDate: _endDate,
            onDateChanged: (s, e) => setState(() {
              _startDate = s;
              _endDate = e;
            }),
          ),
          const DirectionFuelReportScreen(),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// ONGLET RAVITAILLEMENT
// ═══════════════════════════════════════════════════════════════════════

class _RavitaillementTab extends ConsumerWidget {
  const _RavitaillementTab({
    required this.startDate,
    required this.endDate,
    required this.onDateChanged,
  });

  final DateTime startDate;
  final DateTime endDate;
  final void Function(DateTime start, DateTime end) onDateChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final entriesAsync = ref.watch(fuelSupplyEntriesProvider);

    return entriesAsync.when(
      data: (allEntries) {
        final startOfDay =
            DateTime(startDate.year, startDate.month, startDate.day);
        final endOfDay =
            DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
        final filtered = allEntries
            .where((e) =>
                !e.date.isBefore(startOfDay) && !e.date.isAfter(endOfDay))
            .toList();

        final totalLiters = filtered.fold<double>(
            0, (s, e) => s + e.litersDelivered);
        final totalCost = filtered
            .where((e) => e.totalCost != null)
            .fold<double>(0, (s, e) => s + e.totalCost!);

        return Column(
          children: [
            // ── Filtres date + Ajouter ──────────────────────────────
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: const BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: AppColors.surfaceBorder)),
              ),
              child: Row(
                children: [
                  // Date range
                  Expanded(
                    child: _DateRangeRow(
                      startDate: startDate,
                      endDate: endDate,
                      onChanged: onDateChanged,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  // Ajouter
                  ElevatedButton.icon(
                    onPressed: () => _showAddDialog(context, ref, l10n),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    icon: const Icon(Icons.add,
                        color: Colors.white, size: 18),
                    label: Text(
                      l10n.translate('ravitaillement.addEntry'),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

            // ── KPI : stock disponible (temps réel) + total période ──
            Builder(builder: (context) {
              final stockAsync = ref.watch(fuelStockProvider);
              return Column(
                children: [
                  // Bandeau stock global
                  stockAsync.when(
                    data: (stock) => Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: stock.available >= 0
                            ? AppColors.success.withValues(alpha: 0.08)
                            : AppColors.error.withValues(alpha: 0.08),
                        border: const Border(
                            bottom:
                                BorderSide(color: AppColors.surfaceBorder)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Iconsax.gas_station,
                            size: 16,
                            color: stock.available >= 0
                                ? AppColors.success
                                : AppColors.error,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            l10n.translate('ravitaillement.stockAvailable'),
                            style: TextStyle(
                              color: stock.available >= 0
                                  ? AppColors.success
                                  : AppColors.error,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${NumberFormat('#,##0.0', 'fr_FR').format(stock.available)} L',
                            style: TextStyle(
                              color: stock.available >= 0
                                  ? AppColors.success
                                  : AppColors.error,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Text(
                            '(${NumberFormat('#,##0.0', 'fr_FR').format(stock.totalDelivered)} L ${l10n.translate('ravitaillement.stockIn')} − ${NumberFormat('#,##0.0', 'fr_FR').format(stock.totalDispensed)} L ${l10n.translate('ravitaillement.stockOut')})',
                            style: const TextStyle(
                                color: AppColors.textTertiary, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                      child: InlineErrorRetry(
                        onRetry: () => ref.invalidate(fuelStockProvider),
                      ),
                    ),
                  ),
                  // KPI période
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      border: const Border(
                          bottom: BorderSide(color: AppColors.surfaceBorder)),
                    ),
                    child: Row(
                      children: [
                        _KpiChip(
                          icon: Iconsax.gas_station,
                          value:
                              '${NumberFormat('#,##0.0', 'fr_FR').format(totalLiters)} L',
                          label: l10n.translate('ravitaillement.totalDelivered'),
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        _KpiChip(
                          icon: Iconsax.document_text,
                          value: '${filtered.length}',
                          label: l10n.translate('ravitaillement.deliveryCount'),
                          color: AppColors.info,
                        ),
                        if (totalCost > 0) ...[
                          const SizedBox(width: AppSpacing.lg),
                          _KpiChip(
                            icon: Iconsax.money,
                            value:
                                '${NumberFormat('#,##0', 'fr_FR').format(totalCost)} XOF',
                            label: l10n.translate('ravitaillement.totalCost'),
                            color: AppColors.warning,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            }),

            // ── Liste des livraisons ────────────────────────────────
            Expanded(
              child: filtered.isEmpty
                  ? _EmptyState(
                      message: l10n.translate('ravitaillement.noEntries'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final entry = filtered[index];
                        return _SupplyEntryCard(
                          entry: entry,
                          l10n: l10n,
                          onDelete: () async {
                            final confirmed = await _confirmDelete(
                                context, l10n);
                            if (confirmed) {
                              try {
                                await ref
                                    .read(fuelSupplyRepositoryProvider)
                                    .deleteEntry(entry.id);
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(l10n.translate(
                                          'ravitaillement.deleteBlockedValidated')),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          onValidate: entry.isValidated
                              ? null
                              : () async {
                                  final user = ref
                                      .read(authControllerProvider)
                                      .value;
                                  await ref
                                      .read(fuelSupplyRepositoryProvider)
                                      .validateEntry(
                                        entry.id,
                                        validatedById: user?.id ?? '',
                                        validatedByName:
                                            user?.fullName ?? '',
                                      );
                                },
                        );
                      },
                    ),
            ),

            // ── Exports ────────────────────────────────────────────
            if (filtered.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: const BoxDecoration(
                  border: Border(
                      top: BorderSide(color: AppColors.surfaceBorder)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _ExportButton(
                        icon: Iconsax.document_text,
                        label: 'CSV',
                        color: AppColors.info,
                        onTap: () =>
                            _exportCsv(context, filtered, l10n),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _ExportButton(
                        icon: Iconsax.document_download,
                        label: 'Excel',
                        color: AppColors.success,
                        onTap: () =>
                            _exportExcel(context, filtered, l10n),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _ExportButton(
                        icon: Iconsax.document_favorite,
                        label: 'PDF',
                        color: AppColors.error,
                        onTap: () =>
                            _exportPdf(context, filtered, l10n),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, _) => Center(
        child: Text('$e',
            style: const TextStyle(color: AppColors.error)),
      ),
    );
  }

  Future<void> _showAddDialog(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _AddSupplyDialog(l10n: l10n, ref: ref),
    );
  }

  Future<bool> _confirmDelete(
      BuildContext context, AppLocalizations l10n) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(l10n.translate('common.delete'),
            style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(l10n.translate('ravitaillement.deleteConfirm'),
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.translate('common.cancel'),
                style:
                    const TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error),
            child: Text(l10n.translate('common.delete'),
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // ── Exports ───────────────────────────────────────────────────────

  List<String> _headers(AppLocalizations l10n) => [
        l10n.translate('ravitaillement.date'),
        l10n.translate('ravitaillement.litersDelivered'),
        l10n.translate('ravitaillement.supplierName'),
        l10n.translate('ravitaillement.invoiceNumber'),
        l10n.translate('ravitaillement.pricePerLiter'),
        l10n.translate('ravitaillement.totalCost'),
        l10n.translate('ravitaillement.notes'),
      ];

  List<String> _rowFor(FuelSupplyEntryModel e) => [
        e.displayDate,
        e.litersDelivered.toStringAsFixed(1),
        e.supplierName ?? '',
        e.invoiceNumber ?? '',
        e.pricePerLiter?.toStringAsFixed(0) ?? '',
        e.totalCost?.toStringAsFixed(0) ?? '',
        e.notes ?? '',
      ];

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _exportCsv(BuildContext context,
      List<FuelSupplyEntryModel> entries, AppLocalizations l10n) async {
    final buf = StringBuffer();
    buf.writeln('"${l10n.translate('common.exportPeriod')}";"${_fmtDate(startDate)} → ${_fmtDate(endDate)}"');
    buf.writeln();
    buf.writeln(_headers(l10n).map((h) => '"$h"').join(';'));
    for (final e in entries) {
      buf.writeln(_rowFor(e).map((v) => '"$v"').join(';'));
    }
    const filename = 'ravitaillement.csv';
    if (kIsWeb) {
      downloadFileWeb(buf.toString(), filename);
      return;
    }
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsString(buf.toString());
      await SharePlus.instance.share(
          ShareParams(files: [XFile(file.path)], title: filename));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _exportExcel(BuildContext context,
      List<FuelSupplyEntryModel> entries, AppLocalizations l10n) async {
    final xls = xl.Excel.createExcel();
    xls.rename('Sheet1', 'Ravitaillement');
    final sheet = xls['Ravitaillement'];

    final infoStyle = xl.CellStyle(
      bold: true,
      backgroundColorHex: xl.ExcelColor.fromHexString('#EFF6FF'),
    );
    sheet.appendRow([
      xl.TextCellValue(l10n.translate('common.exportPeriod')),
      xl.TextCellValue('${_fmtDate(startDate)} → ${_fmtDate(endDate)}'),
    ]);
    sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).cellStyle = infoStyle;
    sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0)).cellStyle = infoStyle;
    sheet.appendRow([xl.TextCellValue('')]);

    final headers = _headers(l10n);
    sheet.appendRow(headers.map(xl.TextCellValue.new).toList());
    final hs = xl.CellStyle(
      bold: true,
      backgroundColorHex: xl.ExcelColor.fromHexString('#1E40AF'),
      fontColorHex: xl.ExcelColor.fromHexString('#FFFFFF'),
    );
    final headerRowIdx = sheet.maxRows - 1;
    for (var c = 0; c < headers.length; c++) {
      sheet
          .cell(xl.CellIndex.indexByColumnRow(
              columnIndex: c, rowIndex: headerRowIdx))
          .cellStyle = hs;
    }
    for (final e in entries) {
      sheet.appendRow(_rowFor(e).map(xl.TextCellValue.new).toList());
    }
    for (var c = 0; c < headers.length; c++) {
      sheet.setColumnWidth(c, 18);
    }
    final bytes = xls.encode();
    if (bytes == null) return;
    const filename = 'ravitaillement.xlsx';
    if (kIsWeb) {
      downloadFileBytesWeb(bytes, filename);
      return;
    }
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes);
      await SharePlus.instance.share(
          ShareParams(files: [XFile(file.path)], title: filename));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _exportPdf(BuildContext context,
      List<FuelSupplyEntryModel> entries, AppLocalizations l10n) async {
    final pdf = pw.Document();
    final headers = _headers(l10n);
    final rows = entries.map(_rowFor).toList();
    final totalL = entries.fold<double>(0, (s, e) => s + e.litersDelivered);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        header: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(l10n.translate('ravitaillement.title'),
                style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text(
              '${l10n.translate('common.exportPeriod')} : ${_fmtDate(startDate)} → ${_fmtDate(endDate)}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
            pw.Text(
              '${l10n.translate('ravitaillement.totalDelivered')} : ${NumberFormat('#,##0.0', 'fr_FR').format(totalL)} L',
              style: const pw.TextStyle(
                  fontSize: 10, color: PdfColors.grey700),
            ),
          ],
        ),
        build: (ctx) => [
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: {
              0: const pw.FlexColumnWidth(),
              for (var i = 1; i < headers.length; i++)
                i: const pw.FlexColumnWidth(),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFF1E40AF)),
                children: headers
                    .map((h) => pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(h,
                              style: pw.TextStyle(
                                  color: PdfColors.white,
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 8)),
                        ))
                    .toList(),
              ),
              ...rows.asMap().entries.map((entry) {
                return pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: entry.key.isEven
                        ? PdfColors.grey50
                        : PdfColors.white,
                  ),
                  children: entry.value
                      .map((cell) => pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(cell,
                                style:
                                    const pw.TextStyle(fontSize: 8)),
                          ))
                      .toList(),
                );
              }),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Généré le ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
            style: const pw.TextStyle(
                fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );
    const filename = 'ravitaillement.pdf';
    try {
      final bytes = await pdf.save();
      if (kIsWeb) {
        downloadFileBytesWeb(bytes, filename);
        return;
      }
      await printOrSharePdf(bytes, filename: filename);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// DIALOG : AJOUTER UNE ENTRÉE
// ═══════════════════════════════════════════════════════════════════════

class _AddSupplyDialog extends ConsumerStatefulWidget {
  const _AddSupplyDialog({required this.l10n, required this.ref});
  final AppLocalizations l10n;
  final WidgetRef ref;

  @override
  ConsumerState<_AddSupplyDialog> createState() => _AddSupplyDialogState();
}

class _AddSupplyDialogState extends ConsumerState<_AddSupplyDialog> {
  final _formKey = GlobalKey<FormState>();
  DateTime _date = DateTime.now();
  final _litersCtrl = TextEditingController();
  final _supplierCtrl = TextEditingController();
  final _invoiceCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _litersCtrl.dispose();
    _supplierCtrl.dispose();
    _invoiceCtrl.dispose();
    _priceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
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
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final user = ref.read(authControllerProvider).value;
      final repo = ref.read(fuelSupplyRepositoryProvider);
      await repo.addEntry(
        date: _date,
        litersDelivered: double.parse(_litersCtrl.text.trim()),
        supplierName: _supplierCtrl.text.trim(),
        invoiceNumber: _invoiceCtrl.text.trim(),
        pricePerLiter: _priceCtrl.text.trim().isNotEmpty
            ? double.tryParse(_priceCtrl.text.trim())
            : null,
        notes: _notesCtrl.text.trim(),
        createdById: user?.id ?? '',
        createdByName: user?.fullName ?? '',
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(widget.l10n.translate('ravitaillement.addSuccess')),
          backgroundColor: AppColors.success,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final dateStr =
        '${_date.day.toString().padLeft(2, '0')}/${_date.month.toString().padLeft(2, '0')}/${_date.year}';

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Container(
        width: 480,
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius:
                        BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(Iconsax.gas_station,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    l10n.translate('ravitaillement.addEntry'),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close,
                      color: AppColors.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const Divider(color: AppColors.surfaceBorder, height: 1),
            const SizedBox(height: AppSpacing.lg),

            // Form
            Flexible(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Date
                      GestureDetector(
                        onTap: _pickDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundSecondary,
                            borderRadius:
                                BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                                color: AppColors.surfaceBorder),
                          ),
                          child: Row(
                            children: [
                              const Icon(Iconsax.calendar,
                                  color: AppColors.primary, size: 18),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.translate(
                                          'ravitaillement.date'),
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11,
                                      ),
                                    ),
                                    Text(
                                      dateStr,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.edit_calendar_outlined,
                                  color: AppColors.textTertiary,
                                  size: 16),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Litres (requis)
                      _FormField(
                        controller: _litersCtrl,
                        label: l10n.translate(
                            'ravitaillement.litersDelivered'),
                        icon: Iconsax.drop,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                                decimal: true),
                        required: true,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return l10n.translate(
                                'ravitaillement.litersRequired');
                          }
                          if (double.tryParse(v.trim()) == null) {
                            return l10n.translate(
                                'ravitaillement.litersInvalid');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Fournisseur
                      _FormField(
                        controller: _supplierCtrl,
                        label: l10n
                            .translate('ravitaillement.supplierName'),
                        icon: Iconsax.building,
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // N° BL / Facture
                      _FormField(
                        controller: _invoiceCtrl,
                        label: l10n.translate(
                            'ravitaillement.invoiceNumber'),
                        icon: Iconsax.receipt,
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Prix / litre
                      _FormField(
                        controller: _priceCtrl,
                        label: l10n.translate(
                            'ravitaillement.pricePerLiter'),
                        icon: Iconsax.money,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                                decimal: true),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Notes
                      _FormField(
                        controller: _notesCtrl,
                        label: l10n.translate('ravitaillement.notes'),
                        icon: Iconsax.note,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),
            // Actions
            Wrap(
              alignment: WrapAlignment.end,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: Text(
                    l10n.translate('common.cancel'),
                    style: const TextStyle(
                        color: AppColors.textSecondary),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                        vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Iconsax.tick_circle, size: 18),
                  label: Text(l10n.translate('common.save')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// CARD : une entrée de ravitaillement
// ═══════════════════════════════════════════════════════════════════════

class _SupplyEntryCard extends StatelessWidget {
  const _SupplyEntryCard({
    required this.entry,
    required this.l10n,
    required this.onDelete,
    this.onValidate,
  });
  final FuelSupplyEntryModel entry;
  final AppLocalizations l10n;
  final VoidCallback onDelete;
  final VoidCallback? onValidate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: entry.isValidated
            ? AppColors.success.withValues(alpha: 0.04)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: entry.isValidated ? AppColors.success.withValues(alpha: 0.3) : AppColors.surfaceBorder,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icône
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(Iconsax.gas_station,
                color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date + litres
                Row(
                  children: [
                    Text(
                      entry.displayDate,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${NumberFormat('#,##0.0', 'fr_FR').format(entry.litersDelivered)} L',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                // Fournisseur
                if (entry.supplierName != null &&
                    entry.supplierName!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    entry.supplierName!,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                // BL + Prix
                if (entry.invoiceNumber != null ||
                    entry.pricePerLiter != null) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: AppSpacing.md,
                    children: [
                      if (entry.invoiceNumber != null)
                        _Badge(
                            icon: Iconsax.receipt,
                            text: entry.invoiceNumber!),
                      if (entry.pricePerLiter != null)
                        _Badge(
                            icon: Iconsax.money,
                            text:
                                '${NumberFormat('#,##0', 'fr_FR').format(entry.pricePerLiter)} GNF/L'),
                      if (entry.totalCost != null)
                        _Badge(
                            icon: Iconsax.wallet,
                            text:
                                '${NumberFormat('#,##0', 'fr_FR').format(entry.totalCost)} GNF',
                            color: AppColors.warning),
                    ],
                  ),
                ],
                // Notes
                if (entry.notes != null && entry.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    entry.notes!,
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                // Badge validé + validateur
                if (entry.isValidated) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.verified,
                          color: AppColors.success, size: 13),
                      const SizedBox(width: 4),
                      Text(
                        l10n.translate('ravitaillement.validatedBy') +
                            ((entry.validatedByName?.isNotEmpty ?? false)
                                ? ' ${entry.validatedByName}'
                                : ''),
                        style: const TextStyle(
                            color: AppColors.success, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Actions : valider OU supprimer (verrouillé si validé)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (entry.isValidated)
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.lock, color: AppColors.success, size: 18),
                )
              else ...[
                if (onValidate != null)
                  IconButton(
                    icon: const Icon(Icons.verified_outlined,
                        color: AppColors.success, size: 18),
                    tooltip: l10n.translate('ravitaillement.validate'),
                    onPressed: onValidate,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                const SizedBox(height: 4),
                IconButton(
                  icon: const Icon(Iconsax.trash,
                      color: AppColors.error, size: 18),
                  tooltip: l10n.translate('common.delete'),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PETITS WIDGETS UTILITAIRES
// ═══════════════════════════════════════════════════════════════════════

class _DateRangeRow extends StatelessWidget {
  const _DateRangeRow({
    required this.startDate,
    required this.endDate,
    required this.onChanged,
  });
  final DateTime startDate;
  final DateTime endDate;
  final void Function(DateTime, DateTime) onChanged;

  Future<void> _pick(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? startDate : endDate,
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
    if (picked == null) return;
    if (isStart) {
      onChanged(picked, endDate.isBefore(picked) ? picked : endDate);
    } else {
      onChanged(
          startDate.isAfter(picked) ? picked : startDate, picked);
    }
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _DateBtn(label: _fmt(startDate), onTap: () => _pick(context, true))),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Icon(Iconsax.arrow_right_1,
              color: AppColors.textTertiary, size: 14),
        ),
        Expanded(child: _DateBtn(label: _fmt(endDate), onTap: () => _pick(context, false))),
      ],
    );
  }
}

class _DateBtn extends StatelessWidget {
  const _DateBtn({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Iconsax.calendar_1,
                color: AppColors.primary, size: 14),
            const SizedBox(width: 4),
            Flexible(
              child: Text(label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiChip extends StatelessWidget {
  const _KpiChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 10),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(
      {required this.icon,
      required this.text,
      this.color = AppColors.textSecondary});
  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 2),
        Text(text,
            style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.gas_station,
              color: AppColors.textSecondary.withValues(alpha: 0.4),
              size: 56),
          const SizedBox(height: AppSpacing.md),
          Text(message,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }
}

class _ExportButton extends StatelessWidget {
  const _ExportButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding:
            const EdgeInsets.symmetric(vertical: AppSpacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      icon: Icon(icon, color: Colors.white, size: 16),
      label: Text(label,
          style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13)),
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.maxLines = 1,
    this.required = false,
    this.validator,
  });
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool required;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      validator: validator,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        labelStyle: const TextStyle(
            color: AppColors.textSecondary, fontSize: 13),
        prefixIcon:
            Icon(icon, size: 18, color: AppColors.textTertiary),
        filled: true,
        fillColor: AppColors.backgroundSecondary,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.md),
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
    );
  }
}
