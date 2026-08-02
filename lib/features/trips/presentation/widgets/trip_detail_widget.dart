import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/models/trip_model.dart';
import '../providers/trip_providers.dart';

/// Widget affichant le détail d'une rotation avec actions de validation
class TripDetailWidget extends ConsumerStatefulWidget {
  const TripDetailWidget({
    required this.trip,
    required this.onUpdated,
    super.key,
  });

  final TripModel trip;
  final VoidCallback onUpdated;

  @override
  ConsumerState<TripDetailWidget> createState() => _TripDetailWidgetState();
}

class _TripDetailWidgetState extends ConsumerState<TripDetailWidget> {
  bool _isProcessing = false;
  final _rejectionController = TextEditingController();

  @override
  void dispose() {
    _rejectionController.dispose();
    super.dispose();
  }

  Future<void> _validateTrip() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text(
          l10n.translate('trip.validateConfirm'),
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            child: Text(
              l10n.translate('trip.validate'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final user = ref.read(authControllerProvider).value;
    if (user == null) return;

    setState(() => _isProcessing = true);

    try {
      final repository = ref.read(tripRepositoryProvider);
      await repository.validateTrip(
        tripId: widget.trip.id,
        validatedBy: user.id,
        validatedByName: user.fullName.isEmpty ? user.email : user.fullName,
      );
      ref.invalidate(pendingTripsStreamProvider);
      ref.invalidate(allTripsStreamProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.translate('trip.validateSuccess')),
            backgroundColor: AppColors.success,
          ),
        );
        widget.onUpdated();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.translate('common.error')}: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _rejectTrip() async {
    final l10n = AppLocalizations.of(context);
    _rejectionController.clear();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text(
          l10n.translate('trip.rejectConfirm'),
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: _rejectionController,
          maxLines: 3,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: l10n.translate('trip.rejectionReasonHint'),
            hintStyle: const TextStyle(color: AppColors.textSecondary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text(
              l10n.translate('trip.reject'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final user = ref.read(authControllerProvider).value;
    if (user == null) return;

    setState(() => _isProcessing = true);

    try {
      final repository = ref.read(tripRepositoryProvider);
      await repository.rejectTrip(
        tripId: widget.trip.id,
        validatedBy: user.id,
        validatedByName: user.fullName.isEmpty ? user.email : user.fullName,
        rejectionReason: _rejectionController.text.trim().isNotEmpty
            ? _rejectionController.text.trim()
            : null,
      );
      ref.invalidate(pendingTripsStreamProvider);
      ref.invalidate(allTripsStreamProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.translate('trip.rejectSuccess')),
            backgroundColor: AppColors.warning,
          ),
        );
        widget.onUpdated();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.translate('common.error')}: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final trip = widget.trip;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              const Icon(Iconsax.routing, color: AppColors.primary, size: 24),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  l10n.translate('trip.tripDetail'),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _buildStatusBadge(trip, l10n),
            ],
          ),
          const Divider(color: AppColors.surfaceBorder, height: 24),

          // Véhicule & Chauffeur
          _buildDetailRow(
            Iconsax.truck,
            l10n.translate('trip.truck'),
            trip.truckImmatriculation,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildDetailRow(
            Iconsax.driver,
            l10n.translate('trip.driver'),
            trip.driverName,
          ),

          const Divider(color: AppColors.surfaceBorder, height: 24),

          // Pesées
          _buildWeighingSection(trip, l10n),

          const Divider(color: AppColors.surfaceBorder, height: 24),

          // Horaires
          _buildTimingSection(trip, l10n),

          // Notes
          if (trip.notes != null && trip.notes!.isNotEmpty) ...[
            const Divider(color: AppColors.surfaceBorder, height: 24),
            _buildDetailRow(
              Iconsax.document_text,
              'Notes',
              trip.notes!,
            ),
          ],

          // Rejet
          if (trip.rejectionReason != null &&
              trip.rejectionReason!.isNotEmpty) ...[
            const Divider(color: AppColors.surfaceBorder, height: 24),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Iconsax.warning_2,
                      color: AppColors.error, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.translate('trip.rejectionReason'),
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          trip.rejectionReason!,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Actions de validation
          if (trip.status == TripStatus.pendingValidation) ...[
            const SizedBox(height: AppSpacing.xl),
            _buildActionButtons(l10n),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(TripModel trip, AppLocalizations l10n) {
    final statusColor = switch (trip.status) {
      TripStatus.inProgress => AppColors.info,
      TripStatus.pendingValidation => AppColors.warning,
      TripStatus.validated => AppColors.success,
      TripStatus.rejected => AppColors.error,
    };

    final statusLabel = switch (trip.status) {
      TripStatus.inProgress => l10n.translate('trip.inProgress'),
      TripStatus.pendingValidation =>
        l10n.translate('trip.pendingValidation'),
      TripStatus.validated => l10n.translate('trip.validated'),
      TripStatus.rejected => l10n.translate('trip.rejected'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: statusColor),
      ),
      child: Text(
        statusLabel,
        style: TextStyle(
          color: statusColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeighingSection(TripModel trip, AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: _buildWeighingCard(
            l10n.translate('trip.weighingMine'),
            trip.mineWeight != null
                ? '${trip.mineWeight!.toStringAsFixed(2)} T'
                : '--',
            trip.mineWeighingId != null,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        const Icon(Iconsax.arrow_right_1,
            color: AppColors.textSecondary, size: 20),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _buildWeighingCard(
            l10n.translate('trip.weighingPort'),
            trip.portWeight != null
                ? '${trip.portWeight!.toStringAsFixed(2)} T'
                : '--',
            trip.portWeighingId != null,
          ),
        ),
      ],
    );
  }

  Widget _buildWeighingCard(String label, String value, bool hasData) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: hasData
            ? AppColors.success.withValues(alpha: 0.05)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: hasData
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.surfaceBorder,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: hasData ? AppColors.success : AppColors.textTertiary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimingSection(TripModel trip, AppLocalizations l10n) {
    return Column(
      children: [
        if (trip.departureTime != null)
          _buildTimeRow(
            l10n.translate('trip.departure'),
            _formatDateTime(trip.departureTime!),
          ),
        if (trip.arrivalTime != null) ...[
          const SizedBox(height: AppSpacing.sm),
          _buildTimeRow(
            l10n.translate('trip.arrival'),
            _formatDateTime(trip.arrivalTime!),
          ),
        ],
        if (trip.returnTime != null) ...[
          const SizedBox(height: AppSpacing.sm),
          _buildTimeRow(
            l10n.translate('trip.return'),
            _formatDateTime(trip.returnTime!),
          ),
        ],
        if (trip.netTonnage != null) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Iconsax.weight, color: Colors.white, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${l10n.translate('trip.netTonnage')}: ${trip.formattedNetTonnage}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTimeRow(String label, String value) {
    return Row(
      children: [
        const Icon(Iconsax.clock, color: AppColors.textSecondary, size: 16),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '$label: ',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildActionButtons(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isProcessing ? null : _rejectTrip,
            icon: const Icon(Iconsax.close_circle, color: AppColors.error),
            label: Text(
              l10n.translate('trip.reject'),
              style: const TextStyle(color: AppColors.error),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              side: const BorderSide(color: AppColors.error),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isProcessing ? null : _validateTrip,
            icon: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child:
                        CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Iconsax.tick_circle, color: Colors.white),
            label: Text(
              l10n.translate('trip.validate'),
              style: const TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
