import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart' show networkImage;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/utils/pdf_utils.dart';
import '../../../../core/widgets/photo_picker_widget.dart';
import '../../domain/models/weighing_record_model.dart';

/// Dialog de détail d'une pesée — consultation, photos, impression.
class WeighingDetailDialog extends ConsumerStatefulWidget {
  const WeighingDetailDialog({required this.record, super.key});

  final WeighingRecordModel record;

  @override
  ConsumerState<WeighingDetailDialog> createState() =>
      _WeighingDetailDialogState();
}

class _WeighingDetailDialogState
    extends ConsumerState<WeighingDetailDialog> {
  bool _isPrinting = false;

  WeighingRecordModel get r => widget.record;

  // ── Helpers d'affichage ────────────────────────────────────────────

  String _collaboratorDisplay(String name, String? matricule) {
    if (matricule != null && matricule.isNotEmpty) {
      return '$name ($matricule)';
    }
    return name;
  }

  // ── Impression PDF ─────────────────────────────────────────────────

  Future<void> _printTicket(AppLocalizations l10n) async {
    setState(() => _isPrinting = true);
    try {
      final bytes = await _buildPdf(l10n);
      final filename =
          'pesee_${r.truckImmatriculation}_${r.formattedDate.replaceAll('/', '-')}.pdf';
      await printOrSharePdf(bytes, filename: filename);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur impression : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  Future<Uint8List> _buildPdf(AppLocalizations l10n) async {
    final pdf = pw.Document();

    // Logo de l'entreprise (asset embarqué, fonctionne sur toutes les
    // plateformes y compris web).
    pw.MemoryImage? logoImage;
    try {
      final logoBytes = (await rootBundle.load('assets/images/logo.png'))
          .buffer
          .asUint8List();
      logoImage = pw.MemoryImage(logoBytes);
    } catch (_) {
      // Pas de logo : on continue sans
    }

    // Télécharger les photos — `networkImage` (package:printing) fonctionne
    // sur toutes les plateformes, contrairement à dart:io HttpClient qui
    // n'est pas supporté sur le web ("Unsupported operation").
    final photoImages = <pw.ImageProvider>[];
    if (r.photoUrls != null && r.photoUrls!.isNotEmpty) {
      for (final url in r.photoUrls!) {
        try {
          photoImages.add(await networkImage(url));
        } catch (_) {
          // Ignorer les photos non téléchargées
        }
      }
    }

    final isMine = r.location == WeighingLocation.mine;
    final locationLabel = isMine
        ? l10n.translate('weighing.mine')
        : l10n.translate('weighing.port');

    final statusLabel = switch (r.status) {
      WeighingStatus.pending => l10n.translate('weighing.pending'),
      WeighingStatus.recorded => l10n.translate('weighing.recorded'),
      WeighingStatus.validated => l10n.translate('weighing.validated'),
      WeighingStatus.rejected => l10n.translate('weighing.rejected'),
      WeighingStatus.loaded => l10n.translate('weighing.statusLoaded'),
      WeighingStatus.unloaded => l10n.translate('weighing.statusUnloaded'),
    };

    final supervisorDisplay =
        _collaboratorDisplay(r.weighedByName, r.weighedByMatricule);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(24),
        build: (ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ── En-tête entreprise (logo + nom) ───────────────────
              pw.Row(
                children: [
                  if (logoImage != null) ...[
                    pw.Image(logoImage, width: 32, height: 32),
                    pw.SizedBox(width: 8),
                  ],
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'My LSC',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: const PdfColor.fromInt(0xFF1E3A5F),
                        ),
                      ),
                      pw.Text(
                        'Gestion de Flotte',
                        style: const pw.TextStyle(
                            fontSize: 8, color: PdfColors.grey500),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 4),

              // ── En-tête bon ────────────────────────────────────────
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(
                    vertical: 10, horizontal: 12),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFF1E3A5F),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      l10n.translate('weighing.ticketTitle'),
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      '${r.formattedDate}  ${r.formattedTime}',
                      style: const pw.TextStyle(
                          color: PdfColors.grey300, fontSize: 9),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),

              // ── Infos véhicule ───────────────────────────────────
              _pdfSection(l10n.translate('weighing.vehicle'), [
                _pdfRow(l10n.translate('weighing.immatriculation'),
                    r.truckImmatriculation),
                if (r.truckFleetNumber != null &&
                    r.truckFleetNumber!.isNotEmpty)
                  _pdfRow(l10n.translate('weighing.fleetNumber'),
                      r.truckFleetNumber!),
                _pdfRow(l10n.translate('weighing.location'), locationLabel),
              ]),
              pw.SizedBox(height: 8),

              // ── Pesées ───────────────────────────────────────────
              _pdfSection(l10n.translate('weighing.weightsSection'), [
                _pdfRow(l10n.translate('weighing.emptyWeight'),
                    r.formattedEmptyWeight),
                _pdfRow(l10n.translate('weighing.loadedWeight'),
                    r.formattedLoadedWeight),
                _pdfRow(
                  l10n.translate('weighing.netWeight'),
                  r.formattedWeight,
                  valueColor: const PdfColor.fromInt(0xFF16A34A),
                  bold: true,
                ),
              ]),
              pw.SizedBox(height: 8),

              // ── Bon / Notes ──────────────────────────────────────
              if (r.ticketNumber != null || r.notes != null)
                _pdfSection(l10n.translate('weighing.details'), [
                  if (r.ticketNumber != null)
                    _pdfRow(
                        l10n.translate('weighing.ticketNumber'),
                        r.ticketNumber!),
                  if (r.notes != null)
                    _pdfRow(l10n.translate('weighing.notes'), r.notes!),
                ]),
              if (r.ticketNumber != null || r.notes != null)
                pw.SizedBox(height: 8),

              // ── Statut ───────────────────────────────────────────
              _pdfSection(l10n.translate('weighing.status'), [
                _pdfRow(l10n.translate('weighing.status'), statusLabel),
                if (r.validatedByName != null)
                  _pdfRow(l10n.translate('weighing.validatedBy'),
                      r.validatedByName!),
              ]),
              pw.SizedBox(height: 8),

              // ── Personnel ────────────────────────────────────────
              _pdfSection(l10n.translate('weighing.personnel'), [
                _pdfRow(l10n.translate('weighing.weighedBy'),
                    supervisorDisplay),
                if (r.driverName != null)
                  _pdfRow(
                    l10n.translate('weighing.driver'),
                    _collaboratorDisplay(
                        r.driverName!, r.driverMatricule),
                  ),
              ]),

              // ── Photos ───────────────────────────────────────────
              if (photoImages.isNotEmpty) ...[
                pw.SizedBox(height: 12),
                pw.Text(
                  l10n.translate('photos.title'),
                  style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: const PdfColor.fromInt(0xFF1E3A5F)),
                ),
                pw.SizedBox(height: 6),
                pw.Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: photoImages.map((img) {
                    return pw.Container(
                      width: 80,
                      height: 60,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(
                            color: PdfColors.grey300),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Image(img, fit: pw.BoxFit.cover),
                    );
                  }).toList(),
                ),
              ],

              pw.Spacer(),

              // ── Pied de page ─────────────────────────────────────
              pw.Divider(color: PdfColors.grey300),
              pw.Text(
                'Généré le ${r.formattedDate} à ${r.formattedTime}',
                style: const pw.TextStyle(
                    fontSize: 7, color: PdfColors.grey500),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _pdfSection(String title, List<pw.Widget> rows) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey200),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 7,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey500,
            ),
          ),
          pw.SizedBox(height: 5),
          ...rows,
        ],
      ),
    );
  }

  pw.Widget _pdfRow(String label, String value,
      {PdfColor? valueColor, bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 110,
            child: pw.Text(
              label,
              style: const pw.TextStyle(
                  fontSize: 8, color: PdfColors.grey600),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight:
                    bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: valueColor ?? PdfColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── UI ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Dialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg)),
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: const BoxDecoration(
              color: AppColors.backgroundSecondary,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppRadius.lg),
                topRight: Radius.circular(AppRadius.lg),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius:
                        BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(Iconsax.weight,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.truckImmatriculation,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${r.formattedDate}  ${r.formattedTime}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close,
                      color: AppColors.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // ── Body ───────────────────────────────────────────────
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(l10n),
                  const SizedBox(height: AppSpacing.md),
                  _buildWeightsCard(l10n),
                  if (r.ticketNumber != null || r.notes != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    _buildDetailsCard(l10n),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  _buildPersonnelCard(l10n),
                  if (r.photoUrls != null &&
                      r.photoUrls!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    _buildPhotosCard(l10n),
                  ],
                ],
              ),
            ),
          ),

          // ── Footer (bouton impression) ─────────────────────────
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: const BoxDecoration(
              color: AppColors.backgroundSecondary,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(AppRadius.lg),
                bottomRight: Radius.circular(AppRadius.lg),
              ),
            ),
            child: ElevatedButton(
              onPressed: _isPrinting ? null : () => _printTicket(l10n),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 48),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md)),
              ),
              child: _isPrinting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Iconsax.printer,
                            color: Colors.white, size: 18),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          l10n.translate('weighing.printTicket'),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildInfoCard(AppLocalizations l10n) {
    final isMine = r.location == WeighingLocation.mine;
    final statusColor = switch (r.status) {
      WeighingStatus.pending => AppColors.warning,
      WeighingStatus.recorded => AppColors.info,
      WeighingStatus.validated => AppColors.success,
      WeighingStatus.rejected => AppColors.error,
      WeighingStatus.loaded => AppColors.primary,
      WeighingStatus.unloaded => const Color(0xFF26A69A),
    };
    final statusLabel = switch (r.status) {
      WeighingStatus.pending => l10n.translate('weighing.pending'),
      WeighingStatus.recorded => l10n.translate('weighing.recorded'),
      WeighingStatus.validated => l10n.translate('weighing.validated'),
      WeighingStatus.rejected => l10n.translate('weighing.rejected'),
      WeighingStatus.loaded => l10n.translate('weighing.statusLoaded'),
      WeighingStatus.unloaded => l10n.translate('weighing.statusUnloaded'),
    };

    return _buildCard(
      children: [
        _buildRow(
          Iconsax.location,
          l10n.translate('weighing.location'),
          isMine
              ? l10n.translate('weighing.mine')
              : l10n.translate('weighing.port'),
        ),
        _divider(),
        Row(
          children: [
            const Icon(Iconsax.tag, color: AppColors.primary, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(l10n.translate('weighing.status'),
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: statusColor),
              ),
              child: Text(statusLabel,
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeightsCard(AppLocalizations l10n) {
    return _buildCard(
      children: [
        _buildRow(Iconsax.weight, l10n.translate('weighing.emptyWeight'),
            r.formattedEmptyWeight),
        _divider(),
        _buildRow(Iconsax.weight, l10n.translate('weighing.loadedWeight'),
            r.formattedLoadedWeight),
        _divider(),
        _buildRow(
          Iconsax.chart_2,
          l10n.translate('weighing.netWeight'),
          r.formattedWeight,
          valueColor: AppColors.success,
          bold: true,
        ),
      ],
    );
  }

  Widget _buildDetailsCard(AppLocalizations l10n) {
    return _buildCard(
      children: [
        if (r.ticketNumber != null) ...[
          _buildRow(Iconsax.receipt,
              l10n.translate('weighing.ticketNumber'), r.ticketNumber!),
          if (r.notes != null) _divider(),
        ],
        if (r.notes != null)
          _buildRow(Iconsax.document_text,
              l10n.translate('weighing.notes'), r.notes!),
      ],
    );
  }

  Widget _buildPersonnelCard(AppLocalizations l10n) {
    return _buildCard(
      children: [
        _buildRow(
          Iconsax.user,
          l10n.translate('weighing.weighedBy'),
          _collaboratorDisplay(r.weighedByName, r.weighedByMatricule),
        ),
        if (r.driverName != null) ...[
          _divider(),
          _buildRow(
            Iconsax.driving,
            l10n.translate('weighing.driver'),
            _collaboratorDisplay(r.driverName!, r.driverMatricule),
          ),
        ],
        if (r.validatedByName != null) ...[
          _divider(),
          _buildRow(Iconsax.tick_circle,
              l10n.translate('weighing.validatedBy'), r.validatedByName!),
        ],
      ],
    );
  }

  Widget _buildPhotosCard(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.translate('photos.title'),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        PhotoPickerWidget(
          photos: const [],
          existingUrls: r.photoUrls ?? [],
          onPickCamera: null,
          onPickGallery: null,
          onRemove: (_) {},
        ),
      ],
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildRow(IconData icon, String label, String value,
      {Color? valueColor, bool bold = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppColors.textPrimary,
              fontSize: 14,
              fontWeight:
                  bold ? FontWeight.w700 : FontWeight.w600,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _divider() =>
      const Divider(color: AppColors.surfaceBorder, height: 16);
}
