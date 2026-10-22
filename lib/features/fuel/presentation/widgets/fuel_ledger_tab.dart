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
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/file_download.dart';
import '../../../../core/utils/pdf_utils.dart';
import '../../../../core/widgets/inline_error_retry.dart';
import '../providers/fuel_supply_providers.dart';

enum _LedgerFilter { all, credits, debits }

/// Relevé du stock carburant, façon relevé bancaire :
/// entrées (+, ravitaillements) et sorties (−, pleins servis) avec le solde
/// après chaque mouvement.
class FuelLedgerTab extends ConsumerStatefulWidget {
  const FuelLedgerTab({super.key});

  @override
  ConsumerState<FuelLedgerTab> createState() => _FuelLedgerTabState();
}

class _FuelLedgerTabState extends ConsumerState<FuelLedgerTab> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  _LedgerFilter _filter = _LedgerFilter.all;

  final _num = NumberFormat('#,##0.0', 'fr_FR');
  final _dateFmt = DateFormat('dd/MM/yyyy');
  final _dateTimeFmt = DateFormat('dd/MM/yyyy HH:mm');

  DateTime get _startOfDay =>
      DateTime(_startDate.year, _startDate.month, _startDate.day);
  DateTime get _endOfDay =>
      DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);

  String _signed(double liters) =>
      '${liters >= 0 ? '+' : '−'}${_num.format(liters.abs())} L';

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate.isBefore(picked)) _endDate = picked;
      } else {
        _endDate = picked;
        if (_startDate.isAfter(picked)) _startDate = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ledgerAsync = ref.watch(fuelLedgerProvider);

    return ledgerAsync.when(
      data: (ledger) {
        // ledger : plus récent en premier, solde après chaque mouvement
        final before = ledger.where((m) => m.date.isBefore(_startOfDay));
        final openingBalance =
            before.isEmpty ? 0.0 : before.first.balanceAfter;
        final inPeriod = ledger
            .where((m) =>
                !m.date.isBefore(_startOfDay) && !m.date.isAfter(_endOfDay))
            .toList();
        final closingBalance =
            inPeriod.isEmpty ? openingBalance : inPeriod.first.balanceAfter;
        final credits = inPeriod
            .where((m) => m.isCredit)
            .fold<double>(0, (s, m) => s + m.liters);
        final debits = inPeriod
            .where((m) => !m.isCredit)
            .fold<double>(0, (s, m) => s + m.liters);

        final visible = switch (_filter) {
          _LedgerFilter.all => inPeriod,
          _LedgerFilter.credits => inPeriod.where((m) => m.isCredit).toList(),
          _LedgerFilter.debits => inPeriod.where((m) => !m.isCredit).toList(),
        };

        final summary = (
          opening: openingBalance,
          credits: credits,
          debits: debits,
          closing: closingBalance,
        );

        return Column(
          children: [
            _buildToolbar(l10n, visible, summary),
            _buildSummary(l10n, summary),
            Expanded(
              child: visible.isEmpty
                  ? Center(
                      child: Text(
                        l10n.translate('fuelLedger.empty'),
                        style:
                            const TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: visible.length,
                      separatorBuilder: (_, __) => const Divider(
                          color: AppColors.surfaceBorder, height: 1),
                      itemBuilder: (_, i) => _buildRow(l10n, visible[i]),
                    ),
            ),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, _) => InlineErrorRetry(
        onRetry: () {
          ref
            ..invalidate(fuelSupplyEntriesProvider)
            ..invalidate(fuelLedgerProvider);
        },
      ),
    );
  }

  // ── Barre : période + filtre + export ─────────────────────────────

  Widget _buildToolbar(
    AppLocalizations l10n,
    List<FuelStockMovement> visible,
    _Summary summary,
  ) {
    Widget dateButton(bool isStart) => OutlinedButton.icon(
          onPressed: () => _pickDate(isStart),
          icon: const Icon(Iconsax.calendar, size: 16),
          label: Text(_dateFmt.format(isStart ? _startDate : _endDate)),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            side: const BorderSide(color: AppColors.surfaceBorder),
          ),
        );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.surfaceBorder)),
      ),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          dateButton(true),
          const Text('→', style: TextStyle(color: AppColors.textSecondary)),
          dateButton(false),
          SegmentedButton<_LedgerFilter>(
            segments: [
              ButtonSegment(
                value: _LedgerFilter.all,
                label: Text(l10n.translate('fuelLedger.filterAll')),
              ),
              ButtonSegment(
                value: _LedgerFilter.credits,
                label: Text(l10n.translate('fuelLedger.filterCredits')),
              ),
              ButtonSegment(
                value: _LedgerFilter.debits,
                label: Text(l10n.translate('fuelLedger.filterDebits')),
              ),
            ],
            selected: {_filter},
            showSelectedIcon: false,
            onSelectionChanged: (v) => setState(() => _filter = v.first),
          ),
          PopupMenuButton<String>(
            tooltip: l10n.translate('directionDashboard.export'),
            enabled: visible.isNotEmpty,
            onSelected: (format) => switch (format) {
              'csv' => _exportCsv(l10n, visible, summary),
              'excel' => _exportExcel(l10n, visible, summary),
              _ => _exportPdf(l10n, visible, summary),
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'csv', child: Text('CSV')),
              PopupMenuItem(value: 'excel', child: Text('Excel')),
              PopupMenuItem(value: 'pdf', child: Text('PDF')),
            ],
            child: Chip(
              avatar: const Icon(Iconsax.export_1,
                  size: 16, color: AppColors.primary),
              label: Text(l10n.translate('directionDashboard.export')),
            ),
          ),
        ],
      ),
    );
  }

  // ── Récapitulatif ─────────────────────────────────────────────────

  Widget _buildSummary(AppLocalizations l10n, _Summary summary) {
    Widget block(String label, String value, Color color) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 11)),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value,
                    style: TextStyle(
                        color: color,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        );

    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          block(l10n.translate('fuelLedger.openingBalance'),
              '${_num.format(summary.opening)} L', AppColors.textPrimary),
          block(l10n.translate('fuelLedger.totalCredits'),
              _signed(summary.credits), AppColors.success),
          block(l10n.translate('fuelLedger.totalDebits'),
              _signed(summary.debits), AppColors.error),
          block(
            l10n.translate('fuelLedger.closingBalance'),
            '${_num.format(summary.closing)} L',
            summary.closing >= 0 ? AppColors.primary : AppColors.error,
          ),
        ],
      ),
    );
  }

  // ── Ligne du relevé ───────────────────────────────────────────────

  String _labelFor(AppLocalizations l10n, FuelStockMovement m) {
    final kind = m.isCredit
        ? l10n.translate('fuelLedger.supply')
        : l10n.translate('fuelLedger.dispense');
    return m.label.isEmpty ? kind : '$kind — ${m.label}';
  }

  Widget _buildRow(AppLocalizations l10n, FuelStockMovement m) {
    final color = m.isCredit ? AppColors.success : AppColors.error;
    final details = [
      _dateTimeFmt.format(m.date),
      if (m.reference != null && m.reference!.isNotEmpty)
        '${m.isCredit ? l10n.translate('fuelLedger.invoice') : l10n.translate('fuelLedger.receipt')} ${m.reference}',
      if (m.operator != null && m.operator!.isNotEmpty) m.operator!,
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              m.isCredit ? Iconsax.arrow_down : Iconsax.arrow_up_3,
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
                  _labelFor(l10n, m),
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  details,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _signed(m.liters),
                style: TextStyle(
                    color: color, fontSize: 15, fontWeight: FontWeight.w700),
              ),
              Text(
                '${l10n.translate('fuelLedger.balance')} : ${_num.format(m.balanceAfter)} L',
                style: const TextStyle(
                    color: AppColors.textTertiary, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Exports ───────────────────────────────────────────────────────

  List<String> _headers(AppLocalizations l10n) => [
        l10n.translate('fuelLedger.colDate'),
        l10n.translate('fuelLedger.colType'),
        l10n.translate('fuelLedger.colLabel'),
        l10n.translate('fuelLedger.colReference'),
        l10n.translate('fuelLedger.colOperator'),
        l10n.translate('fuelLedger.colCredit'),
        l10n.translate('fuelLedger.colDebit'),
        l10n.translate('fuelLedger.colBalance'),
      ];

  List<String> _rowFor(AppLocalizations l10n, FuelStockMovement m) => [
        _dateTimeFmt.format(m.date),
        if (m.isCredit)
          l10n.translate('fuelLedger.supply')
        else
          l10n.translate('fuelLedger.dispense'),
        m.label,
        m.reference ?? '',
        m.operator ?? '',
        // Entrée / Sortie dans deux colonnes distinctes
        if (m.isCredit) ...[m.liters.toStringAsFixed(1), '']
        else ...['', m.liters.abs().toStringAsFixed(1)],
        m.balanceAfter.toStringAsFixed(1),
      ];

  List<MapEntry<String, String>> _headerLines(
          AppLocalizations l10n, _Summary s) =>
      [
        MapEntry(l10n.translate('common.exportPeriod'),
            '${_dateFmt.format(_startDate)} → ${_dateFmt.format(_endDate)}'),
        MapEntry(l10n.translate('fuelLedger.openingBalance'),
            '${_num.format(s.opening)} L'),
        MapEntry(l10n.translate('fuelLedger.totalCredits'), _signed(s.credits)),
        MapEntry(l10n.translate('fuelLedger.totalDebits'), _signed(s.debits)),
        MapEntry(l10n.translate('fuelLedger.closingBalance'),
            '${_num.format(s.closing)} L'),
      ];

  /// Ordre chronologique dans les exports (comme un relevé papier)
  List<FuelStockMovement> _chronological(List<FuelStockMovement> rows) =>
      rows.reversed.toList();

  Future<void> _share(String filename, {String? text, List<int>? bytes}) async {
    if (kIsWeb) {
      if (text != null) {
        downloadFileWeb(text, filename);
      } else {
        downloadFileBytesWeb(bytes!, filename);
      }
      return;
    }
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$filename');
      if (text != null) {
        await file.writeAsString(text);
      } else {
        await file.writeAsBytes(bytes!);
      }
      await SharePlus.instance
          .share(ShareParams(files: [XFile(file.path)], title: filename));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _exportCsv(AppLocalizations l10n,
      List<FuelStockMovement> rows, _Summary summary) async {
    final buf = StringBuffer();
    for (final line in _headerLines(l10n, summary)) {
      buf.writeln('"${line.key}";"${line.value}"');
    }
    buf.writeln();
    buf.writeln(_headers(l10n).map((h) => '"$h"').join(';'));
    for (final m in _chronological(rows)) {
      buf.writeln(_rowFor(l10n, m).map((v) => '"$v"').join(';'));
    }
    await _share('releve_carburant.csv', text: buf.toString());
  }

  Future<void> _exportExcel(AppLocalizations l10n,
      List<FuelStockMovement> rows, _Summary summary) async {
    final xls = xl.Excel.createExcel();
    xls.rename('Sheet1', 'Releve');
    final sheet = xls['Releve'];

    final infoStyle = xl.CellStyle(
      bold: true,
      backgroundColorHex: xl.ExcelColor.fromHexString('#EFF6FF'),
    );
    for (final line in _headerLines(l10n, summary)) {
      sheet.appendRow(
          [xl.TextCellValue(line.key), xl.TextCellValue(line.value)]);
      final r = sheet.maxRows - 1;
      for (var c = 0; c < 2; c++) {
        sheet
            .cell(xl.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r))
            .cellStyle = infoStyle;
      }
    }
    sheet.appendRow([xl.TextCellValue('')]);

    final headers = _headers(l10n);
    sheet.appendRow(headers.map(xl.TextCellValue.new).toList());
    final hs = xl.CellStyle(
      bold: true,
      backgroundColorHex: xl.ExcelColor.fromHexString('#1E40AF'),
      fontColorHex: xl.ExcelColor.fromHexString('#FFFFFF'),
    );
    final headerRow = sheet.maxRows - 1;
    for (var c = 0; c < headers.length; c++) {
      sheet
          .cell(xl.CellIndex.indexByColumnRow(
              columnIndex: c, rowIndex: headerRow))
          .cellStyle = hs;
      sheet.setColumnWidth(c, 18);
    }
    for (final m in _chronological(rows)) {
      sheet.appendRow(_rowFor(l10n, m).map(xl.TextCellValue.new).toList());
    }

    final bytes = xls.encode();
    if (bytes == null) return;
    await _share('releve_carburant.xlsx', bytes: bytes);
  }

  Future<void> _exportPdf(AppLocalizations l10n,
      List<FuelStockMovement> rows, _Summary summary) async {
    final pdf = pw.Document();
    final headers = _headers(l10n);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        header: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(l10n.translate('fuelLedger.title'),
                style: pw.TextStyle(
                    fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            for (final line in _headerLines(l10n, summary))
              pw.Text('${line.key} : ${line.value}',
                  style: const pw.TextStyle(
                      fontSize: 9, color: PdfColors.grey700)),
          ],
        ),
        build: (_) => [
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: _chronological(rows).map((m) => _rowFor(l10n, m)).toList(),
            headerStyle: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
                fontSize: 9),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1E40AF)),
            cellStyle: const pw.TextStyle(fontSize: 8),
            oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Généré le ${_dateTimeFmt.format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
          ),
        ],
      ),
    );

    try {
      final bytes = await pdf.save();
      if (kIsWeb) {
        downloadFileBytesWeb(bytes, 'releve_carburant.pdf');
        return;
      }
      await printOrSharePdf(bytes, filename: 'releve_carburant.pdf');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }
}

typedef _Summary = ({
  double opening,
  double credits,
  double debits,
  double closing,
});
