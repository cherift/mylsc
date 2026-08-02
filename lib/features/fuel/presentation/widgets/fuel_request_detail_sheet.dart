import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/pdf_utils.dart';
import '../../../../core/widgets/photo_picker_widget.dart' show PhotoViewerDialog;
import '../../../../core/i18n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../inspection/presentation/providers/inspection_providers.dart';
import '../../domain/models/fuel_request_model.dart';
import '../providers/fuel_request_providers.dart';

/// Bottom sheet de détail d'une demande de carburant.
/// Utilisable depuis la vue direction (FleetDetailScreen) et superviseur.
class FuelRequestDetailSheet extends ConsumerStatefulWidget {
  const FuelRequestDetailSheet({required this.request, super.key});

  final FuelRequestModel request;

  /// Affiche le bottom sheet pour une demande donnée.
  static Future<void> show(BuildContext context, FuelRequestModel request) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FuelRequestDetailSheet(request: request),
    );
  }

  @override
  ConsumerState<FuelRequestDetailSheet> createState() =>
      _FuelRequestDetailSheetState();
}

class _FuelRequestDetailSheetState
    extends ConsumerState<FuelRequestDetailSheet> {
  bool _isCancelling = false;

  /// Raccourci vers widget.request
  FuelRequestModel get request => widget.request;

  // ── Génération PDF ──────────────────────────────────────────────────────────

  Future<Uint8List> _buildPdf(FuelRequestModel r) async {
    final doc = pw.Document();

    // Fetch de la photo du bon (avant la construction synchrone du PDF)
    pw.ImageProvider? receiptImage;
    if (r.receiptPhotoUrl != null && r.receiptPhotoUrl!.isNotEmpty) {
      try {
        receiptImage = await networkImage(r.receiptPhotoUrl!);
      } catch (_) {
        receiptImage = null; // Photo indisponible : on continue sans
      }
    }

    // Couleur selon statut
    final statusHex = switch (r.status) {
      FuelRequestStatus.validated => PdfColors.green700,
      FuelRequestStatus.fulfilled => PdfColors.blue700,
      FuelRequestStatus.disputed  => PdfColors.red700,
      FuelRequestStatus.rejected  => PdfColors.grey600,
      FuelRequestStatus.cancelled => PdfColors.grey500,
      FuelRequestStatus.pending   => PdfColors.orange700,
    };

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // ── En-tête ──────────────────────────────────────────────────
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'My LSC',
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blueGrey900,
                      ),
                    ),
                    pw.Text(
                      'Gestion de Flotte',
                      style: const pw.TextStyle(
                          fontSize: 11, color: PdfColors.blueGrey500),
                    ),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: pw.BoxDecoration(
                    color: statusHex,
                    borderRadius: pw.BorderRadius.circular(20),
                  ),
                  child: pw.Text(
                    r.status.label.toUpperCase(),
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Divider(color: PdfColors.blueGrey200),
            pw.SizedBox(height: 4),
            pw.Text(
              'BON DE DEMANDE DE CARBURANT',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey800,
                letterSpacing: 1.5,
              ),
            ),
            pw.SizedBox(height: 20),

            // ── Infos véhicule ────────────────────────────────────────────
            _pdfSection('VÉHICULE & DEMANDEUR'),
            pw.SizedBox(height: 8),
            _pdfRow('Véhicule',
                r.truckFleetNumber != null
                    ? '${r.truckImmatriculation}  ·  #${r.truckFleetNumber}'
                    : r.truckImmatriculation),
            _pdfRow('Demandé par', r.requestedByName),
            _pdfRow('Date',
                '${r.formattedDate}   ${r.formattedTime}'),
            if (r.driverName != null)
              _pdfRow('Chauffeur', r.driverName!),
            if (r.reason != null && r.reason!.isNotEmpty)
              _pdfRow('Motif', r.reason!),
            pw.SizedBox(height: 16),

            // ── Litres ────────────────────────────────────────────────────
            _pdfSection('CARBURANT'),
            pw.SizedBox(height: 8),
            pw.Row(
              children: [
                _pdfLitersBlock(
                    'Litres demandés',
                    '${r.requestedLiters.toStringAsFixed(0)} L',
                    PdfColors.blueGrey700),
                if (r.fulfilledLiters != null) ...[
                  pw.SizedBox(width: 24),
                  _pdfLitersBlock(
                      'Litres servis',
                      '${r.fulfilledLiters!.toStringAsFixed(0)} L',
                      PdfColors.blue700),
                  if (r.requestedLiters != r.fulfilledLiters) ...[
                    pw.SizedBox(width: 24),
                    _pdfLitersBlock(
                        'Écart',
                        '${(r.requestedLiters - r.fulfilledLiters!).abs().toStringAsFixed(0)} L',
                        PdfColors.orange700),
                  ],
                ],
              ],
            ),
            if (r.fulfilledByName != null) ...[
              pw.SizedBox(height: 8),
              _pdfRow('Servi par', r.fulfilledByName!),
            ],
            if (r.fulfilledAt != null) ...[
              pw.SizedBox(height: 4),
              _pdfRow('Date de prise', _formatDateTime(r.fulfilledAt!)),
            ],
            if (r.receiptNumber != null) ...[
              pw.SizedBox(height: 4),
              _pdfRow('N° de reçu', r.receiptNumber!),
            ],
            if (r.verificationCode != null) ...[
              pw.SizedBox(height: 4),
              _pdfRow('Code de vérification', r.verificationCode!),
            ],
            // ── Photo du bon ──────────────────────────────────────────────
            if (receiptImage != null) ...[
              pw.SizedBox(height: 16),
              _pdfSection('PHOTO DU BON'),
              pw.SizedBox(height: 10),
              pw.ClipRRect(
                horizontalRadius: 6,
                verticalRadius: 6,
                child: pw.Image(
                  receiptImage,
                  height: 220,
                ),
              ),
            ],
            pw.SizedBox(height: 16),

            // ── Validation ────────────────────────────────────────────────
            if (r.validatedByName != null ||
                r.resolvedByName != null ||
                r.disputeReason != null) ...[
              _pdfSection('VALIDATION & RÉSOLUTION'),
              pw.SizedBox(height: 8),
              if (r.validatedByName != null)
                _pdfRow('Validé par', r.validatedByName!),
              if (r.isAutoValidated)
                _pdfRow('Auto-validation', 'Oui'),
              if (r.disputeReason != null)
                _pdfRow('Motif contestation', r.disputeReason!),
              if (r.resolvedByName != null)
                _pdfRow('Résolu par', r.resolvedByName!),
              if (r.resolutionNote != null)
                _pdfRow('Note résolution', r.resolutionNote!),
              pw.SizedBox(height: 16),
            ],

            pw.Spacer(),
            pw.Divider(color: PdfColors.blueGrey200),
            pw.SizedBox(height: 12),
            pw.Center(
              child: pw.Text(
                'Document généré le ${_nowFormatted()}  ·  My LSC',
                style: const pw.TextStyle(
                    fontSize: 9, color: PdfColors.blueGrey400),
              ),
            ),
          ],
        ),
      ),
    );

    return doc.save();
  }

  // ── Helpers PDF ─────────────────────────────────────────────────────────────

  pw.Widget _pdfSection(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blueGrey700,
          letterSpacing: 1,
        ),
      ),
    );
  }

  pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 130,
            child: pw.Text(
              label,
              style: const pw.TextStyle(
                  fontSize: 11, color: PdfColors.blueGrey500),
            ),
          ),
          pw.Text(' : ',
              style: const pw.TextStyle(
                  fontSize: 11, color: PdfColors.blueGrey400)),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey800),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfLitersBlock(String label, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color, width: 1.5),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.blueGrey500),
          ),
        ],
      ),
    );
  }

  String _nowFormatted() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}  ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  // ── Impression ──────────────────────────────────────────────────────────────

  Future<void> _print(BuildContext context) async {
    final filename =
        'carburant_${request.truckImmatriculation}_${request.formattedDate.replaceAll('/', '-')}.pdf';
    try {
      final bytes = await _buildPdf(request);
      await printOrSharePdf(bytes, filename: filename);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur impression : $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
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
        return AppColors.error;
      case FuelRequestStatus.rejected:
        return AppColors.textTertiary;
      case FuelRequestStatus.cancelled:
        return AppColors.textTertiary;
    }
  }

  // ── Annulation ──────────────────────────────────────────────────────────────

  Future<void> _cancelRequest() async {
    final l10n = AppLocalizations.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text(
          l10n.translate('fuelRequest.cancelConfirm'),
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          l10n.translate('fuelRequest.cancelConfirmMessage'),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.translate('common.cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text(
              l10n.translate('fuelRequest.cancelAction'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isCancelling = true);
    try {
      final user = ref.read(authControllerProvider).value;
      final repo = ref.read(fuelRequestRepositoryProvider);
      await repo.cancelRequest(
        requestId: request.id,
        cancelledBy: user?.id ?? '',
        cancelledByName: user?.fullName ?? '',
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.translate('fuelRequest.cancelSuccess')),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${l10n.translate('common.error')}: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final statusColor = _statusColor(request.status);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.backgroundSecondary,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.xl),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceBorder,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 8, 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                            color: statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Icon(Icons.local_gas_station,
                          color: statusColor, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.truckImmatriculation,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _StatusBadge(
                              label: request.status.label,
                              color: statusColor),
                        ],
                      ),
                    ),
                    // Bouton annuler (visible seulement si la demande est annulable)
                    if (request.status.isCancellable)
                      _isCancelling
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.error),
                            )
                          : IconButton(
                              icon: const Icon(Icons.cancel_outlined,
                                  color: AppColors.error),
                              tooltip: l10n
                                  .translate('fuelRequest.cancelAction'),
                              onPressed: _cancelRequest,
                            ),
                    // Bouton imprimer
                    IconButton(
                      icon: const Icon(Icons.print_outlined,
                          color: AppColors.primary),
                      tooltip: AppLocalizations.of(context)
                          .translate('common.print'),
                      onPressed: () => _print(context),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: AppColors.textTertiary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.surfaceBorder),
              // Scrollable body
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Infos générales ──────────────────────────────
                      _SectionTitle(
                          label: l10n.translate('fuelRequest.title')),
                      const SizedBox(height: 12),
                      _InfoRow(
                        icon: Icons.local_shipping_outlined,
                        label: 'Véhicule',
                        value: request.truckImmatriculation +
                            (request.truckFleetNumber != null
                                ? '  ·  #${request.truckFleetNumber}'
                                : ''),
                      ),
                      const SizedBox(height: 8),
                      _InfoRow(
                        icon: Icons.person_outline,
                        label: l10n.translate('fuelRequest.requestedBy'),
                        value: request.requestedByName,
                      ),
                      const SizedBox(height: 8),
                      _InfoRow(
                        icon: Icons.calendar_today_outlined,
                        label: l10n.translate('common.date'),
                        value:
                            '${request.formattedDate}   ${request.formattedTime}',
                      ),
                      if (request.reason != null &&
                          request.reason!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _InfoRow(
                          icon: Icons.notes_outlined,
                          label: l10n.translate('fuelRequest.reason'),
                          value: request.reason!,
                        ),
                      ],

                      // ── Détails carburant ─────────────────────────────
                      const SizedBox(height: 20),
                      _SectionTitle(
                          label: l10n.translate('fuelRequest.requestedLiters')
                              .replaceAll(' demandés', '')),
                      const SizedBox(height: 12),
                      // Bloc comparaison litres
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.surfaceBorder),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _LitersBlock(
                                label: l10n
                                    .translate('fuelRequest.requestedLiters'),
                                value:
                                    '${request.requestedLiters.toStringAsFixed(0)} L',
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (request.fulfilledLiters != null) ...[
                              Container(
                                  width: 1,
                                  height: 44,
                                  color: AppColors.surfaceBorder),
                              Expanded(
                                child: _LitersBlock(
                                  label: l10n
                                      .translate('fuelRequest.servedLiters'),
                                  value:
                                      '${request.fulfilledLiters!.toStringAsFixed(0)} L',
                                  color: AppColors.info,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Avertissement écart
                      if (request.fulfilledLiters != null &&
                          request.requestedLiters !=
                              request.fulfilledLiters) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 9),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            border: Border.all(
                                color:
                                    AppColors.warning.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded,
                                  color: AppColors.warning, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${l10n.translate('fuel.discrepancy')} : '
                                  '${(request.requestedLiters - request.fulfilledLiters!).abs().toStringAsFixed(0)} L',
                                  style: const TextStyle(
                                    color: AppColors.warning,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (request.fulfilledByName != null) ...[
                        const SizedBox(height: 12),
                        _InfoRow(
                          icon: Icons.local_gas_station_outlined,
                          label: l10n.translate('fuelRequest.servedBy'),
                          value: request.fulfilledByName!,
                        ),
                      ],
                      if (request.receiptNumber != null) ...[
                        const SizedBox(height: 8),
                        _InfoRow(
                          icon: Icons.receipt_outlined,
                          label: l10n.translate('fuel.receiptNumber'),
                          value: request.receiptNumber!,
                        ),
                      ],

                      // ── Code de vérification ──────────────────────────
                      if (request.verificationCode != null &&
                          request.verificationCode!.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const _SectionTitle(label: 'Code de vérification'),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1F3A),
                            borderRadius:
                                BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                              color: const Color(0xFF4B3F8A)
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.pin,
                                  size: 18, color: Color(0xFF9B87D4)),
                              const SizedBox(width: 10),
                              Text(
                                request.verificationCode!,
                                style: const TextStyle(
                                  color: Color(0xFF9B87D4),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 24,
                                  letterSpacing: 7,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // ── Photo du bon ──────────────────────────────────
                      if (request.receiptPhotoUrl != null &&
                          request.receiptPhotoUrl!.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _SectionTitle(
                            label: l10n.translate('fuel.takePhoto')
                                .replaceAll('Prendre une ', '')
                                .replaceAll(' du bon', '')
                                .replaceFirst('p', 'P')),
                        const SizedBox(height: 12),
                        _PhotoViewer(url: request.receiptPhotoUrl!),
                      ],

                      // ── Photos d'inspection véhicule (panne, état...) ──
                      _buildInspectionPhotosSection(ref, l10n),

                      // ── Validation ────────────────────────────────────
                      if (request.validatedByName != null ||
                          request.isAutoValidated) ...[
                        const SizedBox(height: 20),
                        const _SectionTitle(label: 'Validation'),
                        const SizedBox(height: 12),
                        if (request.validatedByName != null)
                          _InfoRow(
                            icon: Icons.verified_outlined,
                            label: 'Validé par',
                            value: request.validatedByName!,
                          ),
                        if (request.isAutoValidated) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.full),
                              border: Border.all(
                                  color: AppColors.success
                                      .withValues(alpha: 0.3)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.auto_mode,
                                    color: AppColors.success, size: 13),
                                SizedBox(width: 5),
                                Text(
                                  'Auto-validée',
                                  style: TextStyle(
                                    color: AppColors.success,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],

                      // ── Contestation ──────────────────────────────────
                      if (request.status == FuelRequestStatus.disputed &&
                          request.disputeReason != null) ...[
                        const SizedBox(height: 20),
                        _SectionTitle(
                            label:
                                l10n.translate('fuelRequest.disputeReason')),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                                color:
                                    AppColors.error.withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 1),
                                child: Icon(Icons.warning_amber_rounded,
                                    color: AppColors.error, size: 16),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  request.disputeReason!,
                                  style: const TextStyle(
                                    color: AppColors.error,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // ── Résolution ────────────────────────────────────
                      if (request.resolvedByName != null) ...[
                        const SizedBox(height: 20),
                        const _SectionTitle(label: 'Résolution'),
                        const SizedBox(height: 12),
                        _InfoRow(
                          icon: Icons.check_circle_outline,
                          label: 'Résolu par',
                          value: request.resolvedByName!,
                        ),
                        if (request.resolutionNote != null) ...[
                          const SizedBox(height: 8),
                          _InfoRow(
                            icon: Icons.notes_outlined,
                            label: 'Note',
                            value: request.resolutionNote!,
                          ),
                        ],
                      ],

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Photos prises lors de la dernière inspection du véhicule (état,
  /// panne...) — visibles par la direction dans le détail de la demande.
  Widget _buildInspectionPhotosSection(WidgetRef ref, AppLocalizations l10n) {
    final inspectionAsync =
        ref.watch(lastInspectionForTruckProvider(request.truckId));
    final inspection = inspectionAsync.valueOrNull;
    final photoUrls = inspection?.photoUrls ?? [];

    if (photoUrls.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        _SectionTitle(label: l10n.translate('inspection.vehiclePhotos')),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: photoUrls.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final url = photoUrls[index];
              return GestureDetector(
                onTap: () => PhotoViewerDialog.show(context, url),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: Image.network(
                    url,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 100,
                      height: 100,
                      color: AppColors.surface,
                      child: const Icon(Icons.broken_image_outlined,
                          color: AppColors.textSecondary),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Visionneuse de photo avec zoom ───────────────────────────────────────────

class _PhotoViewer extends StatelessWidget {
  const _PhotoViewer({required this.url});
  final String url;

  void _openFullscreen(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black87,
        barrierDismissible: true,
        pageBuilder: (context, _, __) => Scaffold(
          backgroundColor: Colors.black87,
          body: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 5,
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary),
                      );
                    },
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.broken_image,
                          color: AppColors.textTertiary, size: 48),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                right: 12,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundSecondary.withValues(alpha: 0.85),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close,
                        color: AppColors.textPrimary, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openFullscreen(context),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Image.network(
              url,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                );
              },
              errorBuilder: (_, __, ___) => Container(
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: const Center(
                  child: Icon(Icons.broken_image,
                      color: AppColors.textTertiary, size: 32),
                ),
              ),
            ),
          ),
          // Overlay loupe
          Positioned(
            right: 10,
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(Icons.zoom_in,
                  color: AppColors.textPrimary, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widgets utilitaires ───────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: AppColors.textTertiary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Divider(color: AppColors.surfaceBorder, height: 1),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: AppColors.textTertiary),
        const SizedBox(width: 10),
        Text(
          '$label : ',
          style: const TextStyle(
            color: AppColors.textTertiary,
            fontSize: 13,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _LitersBlock extends StatelessWidget {
  const _LitersBlock({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textTertiary,
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
      ],
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
