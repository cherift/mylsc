import 'dart:io';
import 'package:excel/excel.dart' as xl;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
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

/// Item de detail pour un KPI
class KpiDetailItem {
  const KpiDetailItem({
    required this.title,
    this.subtitle,
    this.value,
    this.color,
    this.extraData,
    this.dateTime,
    this.truckImmatriculation,
  });

  final String title;
  final String? subtitle;
  final String? value;
  final Color? color;

  /// Données supplémentaires pour l'export (clé → valeur)
  final Map<String, String>? extraData;

  final DateTime? dateTime;

  final String? truckImmatriculation;
}

/// Dialog de detail d'un KPI avec export multi-format et filtres (T.13.1)
class KpiDetailDialog extends StatefulWidget {
  const KpiDetailDialog({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
    required this.xmlRootName,
    super.key,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<KpiDetailItem> items;
  final String xmlRootName;

  @override
  State<KpiDetailDialog> createState() => _KpiDetailDialogState();
}

class _KpiDetailDialogState extends State<KpiDetailDialog> {
  DateTimeRange? _dateRange;
  String _truckFilter = '';
  String _selectedFormat = 'excel';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<KpiDetailItem> get _filteredItems {
    return widget.items.where((item) {
      // Filtre par immatriculation
      if (_truckFilter.isNotEmpty) {
        final immat = (item.truckImmatriculation ?? item.title).toLowerCase();
        if (!immat.contains(_truckFilter.toLowerCase())) return false;
      }
      // Filtre par plage de dates
      if (_dateRange != null && item.dateTime != null) {
        final dt = item.dateTime!;
        if (dt.isBefore(_dateRange!.start) ||
            dt.isAfter(_dateRange!.end.add(const Duration(days: 1)))) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  bool get _hasFilters =>
      widget.items.any((i) => i.dateTime != null || i.truckImmatriculation != null);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final filtered = _filteredItems;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 650),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.lg),
                ),
              ),
              child: Row(
                children: [
                  Icon(widget.icon, color: widget.color, size: 24),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        color: widget.color,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${filtered.length}',
                    style: TextStyle(
                      color: widget.color,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Iconsax.close_circle,
                        color: AppColors.textSecondary, size: 22),
                  ),
                ],
              ),
            ),
            if (_hasFilters) _buildFilters(context, l10n),
            // List
            Flexible(
              child: filtered.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Text(
                          l10n.translate('directionDashboard.noData'),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(
                        color: AppColors.surfaceBorder,
                        height: 1,
                      ),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.sm,
                          ),
                          child: Row(
                            children: [
                              if (item.color != null)
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(
                                      right: AppSpacing.sm),
                                  decoration: BoxDecoration(
                                    color: item.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (item.subtitle != null)
                                      Text(
                                        item.subtitle!,
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 11,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (item.value != null)
                                Text(
                                  item.value!,
                                  style: TextStyle(
                                    color: item.color ?? AppColors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            // Export buttons (popup menu multi-format)
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.surfaceBorder),
                ),
              ),
              child: _buildExportBar(context, l10n, filtered),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportBar(
      BuildContext context, AppLocalizations l10n, List<KpiDetailItem> filtered) {
    final formats = [
      (key: 'csv', label: 'CSV', icon: Iconsax.document_text),
      (key: 'excel', label: 'Excel', icon: Iconsax.document_download),
      (key: 'pdf', label: 'PDF', icon: Iconsax.document_favorite),
    ];

    return Row(
      children: [
        // Bouton Exporter
        GestureDetector(
          onTap: filtered.isEmpty
              ? null
              : () {
                  switch (_selectedFormat) {
                    case 'csv':
                      _exportCsv(context, filtered);
                    case 'excel':
                      _exportExcel(context, filtered);
                    case 'pdf':
                      _exportPdf(context, filtered);
                  }
                },
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
            decoration: BoxDecoration(
              color: filtered.isEmpty
                  ? AppColors.textTertiary
                  : widget.color,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Iconsax.export_1, color: Colors.white, size: 16),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  l10n.translate('directionDashboard.export'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        // Sélecteur de format
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Row(
              children: formats.map((fmt) {
                final isSelected = _selectedFormat == fmt.key;
                final isFirst = fmt.key == formats.first.key;
                final isLast = fmt.key == formats.last.key;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedFormat = fmt.key),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? widget.color.withValues(alpha: 0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.horizontal(
                          left: isFirst
                              ? const Radius.circular(AppRadius.md - 1)
                              : Radius.zero,
                          right: isLast
                              ? const Radius.circular(AppRadius.md - 1)
                              : Radius.zero,
                        ),
                        border: Border(
                          right: isLast
                              ? BorderSide.none
                              : const BorderSide(
                                  color: AppColors.surfaceBorder),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            fmt.icon,
                            size: 14,
                            color: isSelected
                                ? widget.color
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            fmt.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: isSelected
                                  ? widget.color
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilters(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceBorder),
        ),
      ),
      child: Column(
        children: [
          // Filtre par immatriculation
          SizedBox(
            height: 36,
            child: TextField(
              controller: _searchController,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: l10n.translate('directionDashboard.filterByTruck'),
                hintStyle: const TextStyle(
                    color: AppColors.textTertiary, fontSize: 13),
                prefixIcon: const Icon(Iconsax.search_normal,
                    color: AppColors.textTertiary, size: 16),
                suffixIcon: _truckFilter.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() => _truckFilter = '');
                        },
                        child: const Icon(Iconsax.close_circle,
                            color: AppColors.textTertiary, size: 16),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  borderSide: const BorderSide(color: AppColors.surfaceBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  borderSide: const BorderSide(color: AppColors.surfaceBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  borderSide:
                      BorderSide(color: widget.color, width: 1.5),
                ),
                filled: true,
                fillColor: AppColors.background,
              ),
              onChanged: (v) => setState(() => _truckFilter = v),
            ),
          ),
          // Filtre par date (uniquement si items ont des dates)
          if (widget.items.any((i) => i.dateTime != null)) ...[
            const SizedBox(height: AppSpacing.sm),
            GestureDetector(
              onTap: () => _pickDateRange(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: _dateRange != null
                        ? widget.color
                        : AppColors.surfaceBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Iconsax.calendar,
                        color: _dateRange != null
                            ? widget.color
                            : AppColors.textTertiary,
                        size: 16),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        _dateRange != null
                            ? '${_formatDate(_dateRange!.start)} — ${_formatDate(_dateRange!.end)}'
                            : l10n.translate(
                                'directionDashboard.filterByDate'),
                        style: TextStyle(
                          color: _dateRange != null
                              ? AppColors.textPrimary
                              : AppColors.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (_dateRange != null)
                      GestureDetector(
                        onTap: () => setState(() => _dateRange = null),
                        child: const Icon(Iconsax.close_circle,
                            color: AppColors.textTertiary, size: 16),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _dateRange,
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
    if (range != null) setState(() => _dateRange = range);
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  // ── Helpers export ──────────────────────────────────────────
  List<String> _buildCsvRow(KpiDetailItem item) {
    final fields = <String>[];
    fields.add('"${item.title}"');
    fields.add('"${item.subtitle ?? ''}"');
    fields.add('"${item.value ?? ''}"');
    if (item.extraData != null) {
      for (final v in item.extraData!.values) {
        fields.add('"$v"');
      }
    }
    return fields;
  }

  String _periodLabel(AppLocalizations l10n) {
    final dr = _dateRange;
    if (dr == null) return l10n.translate('common.exportAllPeriods');
    return '${_formatDate(dr.start)} → ${_formatDate(dr.end)}';
  }

  // ── Export CSV ──────────────────────────────────────────────
  Future<void> _exportCsv(
      BuildContext context, List<KpiDetailItem> filtered) async {
    final l10n = AppLocalizations.of(context);
    final buffer = StringBuffer();
    buffer.writeln('"${l10n.translate('common.exportPeriod')}";"${_periodLabel(l10n)}"');
    if (_truckFilter.isNotEmpty) {
      buffer.writeln('"${l10n.translate('common.exportVehicles')}";"$_truckFilter"');
    }
    buffer.writeln();
    // En-têtes
    final headerFields = ['Titre', 'Sous-titre', 'Valeur'];
    final firstWithExtra =
        filtered.firstWhere((i) => i.extraData != null, orElse: () => filtered.first);
    if (firstWithExtra.extraData != null) {
      headerFields.addAll(firstWithExtra.extraData!.keys);
    }
    buffer.writeln(headerFields.join(';'));
    for (final item in filtered) {
      buffer.writeln(_buildCsvRow(item).join(';'));
    }
    final filename =
        '${widget.xmlRootName}_${DateTime.now().millisecondsSinceEpoch}.csv';
    if (kIsWeb) {
      downloadFileWeb(buffer.toString(), filename);
      return;
    }
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsString(buffer.toString());
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], title: widget.title),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Export error: $e')));
      }
    }
  }

  // ── Export Excel ────────────────────────────────────────────
  Future<void> _exportExcel(
      BuildContext context, List<KpiDetailItem> filtered) async {
    final l10n = AppLocalizations.of(context);
    final xls = xl.Excel.createExcel();
    const sheetName = 'Export';
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

    addInfoRow(l10n.translate('common.exportPeriod'), _periodLabel(l10n));
    if (_truckFilter.isNotEmpty) {
      addInfoRow(l10n.translate('common.exportVehicles'), _truckFilter);
    }
    sheet.appendRow([xl.TextCellValue('')]);

    final headerFields = ['Titre', 'Sous-titre', 'Valeur'];
    final firstWithExtra =
        filtered.firstWhere((i) => i.extraData != null, orElse: () => filtered.first);
    if (firstWithExtra.extraData != null) {
      headerFields.addAll(firstWithExtra.extraData!.keys);
    }
    sheet.appendRow(headerFields.map(xl.TextCellValue.new).toList());

    final headerStyle = xl.CellStyle(
      bold: true,
      backgroundColorHex: xl.ExcelColor.fromHexString('#1E40AF'),
      fontColorHex: xl.ExcelColor.fromHexString('#FFFFFF'),
    );
    final headerRowIdx = sheet.maxRows - 1;
    for (var c = 0; c < headerFields.length; c++) {
      sheet
          .cell(xl.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: headerRowIdx))
          .cellStyle = headerStyle;
    }

    for (final item in filtered) {
      final row = [item.title, item.subtitle ?? '', item.value ?? ''];
      if (item.extraData != null) row.addAll(item.extraData!.values);
      sheet.appendRow(row.map(xl.TextCellValue.new).toList());
    }

    for (var c = 0; c < headerFields.length; c++) {
      sheet.setColumnWidth(c, 22);
    }

    final bytes = xls.encode();
    if (bytes == null) return;
    final filename =
        '${widget.xmlRootName}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    if (kIsWeb) {
      downloadFileBytesWeb(bytes, filename);
      return;
    }
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], title: widget.title),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Export error: $e')));
      }
    }
  }

  // ── Export PDF ──────────────────────────────────────────────
  Future<void> _exportPdf(
      BuildContext context, List<KpiDetailItem> filtered) async {
    final l10n = AppLocalizations.of(context);
    final pdf = pw.Document();

    final headerFields = ['Titre', 'Sous-titre', 'Valeur'];
    final firstWithExtra =
        filtered.firstWhere((i) => i.extraData != null, orElse: () => filtered.first);
    if (firstWithExtra.extraData != null) {
      headerFields.addAll(firstWithExtra.extraData!.keys);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        header: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              widget.title,
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              '${l10n.translate('common.exportPeriod')} : ${_periodLabel(l10n)}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
            if (_truckFilter.isNotEmpty)
              pw.Text(
                '${l10n.translate('common.exportVehicles')} : $_truckFilter',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              ),
          ],
        ),
        build: (_) => [
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(2),
              for (var i = 2; i < headerFields.length; i++)
                i: const pw.FlexColumnWidth(),
            },
            children: [
              pw.TableRow(
                decoration:
                    const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1E40AF)),
                children: headerFields
                    .map((h) => pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(h,
                              style: pw.TextStyle(
                                color: PdfColors.white,
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 9,
                              )),
                        ))
                    .toList(),
              ),
              ...filtered.asMap().entries.map((entry) {
                final isEven = entry.key.isEven;
                final item = entry.value;
                final row = [item.title, item.subtitle ?? '', item.value ?? ''];
                if (item.extraData != null) row.addAll(item.extraData!.values);
                return pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: isEven ? PdfColors.grey50 : PdfColors.white,
                  ),
                  children: row
                      .map((cell) => pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(cell,
                                style: const pw.TextStyle(fontSize: 8)),
                          ))
                      .toList(),
                );
              }),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Généré le ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
            style:
                const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
          ),
        ],
      ),
    );

    final filename =
        '${widget.xmlRootName}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    try {
      final pdfBytes = await pdf.save();
      if (kIsWeb) {
        downloadFileBytesWeb(pdfBytes, filename);
        return;
      }
      await printOrSharePdf(pdfBytes, filename: filename);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Export error: $e')));
      }
    }
  }

}
