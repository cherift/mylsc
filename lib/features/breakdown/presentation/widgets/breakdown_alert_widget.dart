import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/widgets/inline_error_retry.dart';
import '../../domain/models/breakdown_report_model.dart';
import '../providers/breakdown_providers.dart';

/// Widget d'alertes pannes - affiche les pannes actives avec indicateurs de sévérité
class BreakdownAlertWidget extends ConsumerWidget {
  const BreakdownAlertWidget({super.key, this.truckId});

  /// Si fourni, filtre les pannes pour un camion spécifique
  final String? truckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    final breakdownsAsync = truckId != null
        ? ref.watch(truckBreakdownsStreamProvider(truckId!))
        : ref.watch(activeBreakdownsStreamProvider);

    return breakdownsAsync.when(
      data: (breakdowns) {
        final active = truckId != null
            ? breakdowns
                .where((b) =>
                    b.status != BreakdownStatus.closed &&
                    b.status != BreakdownStatus.resolved)
                .toList()
            : breakdowns;

        if (active.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAlertHeader(l10n, active.length),
            const SizedBox(height: AppSpacing.sm),
            ...active.map((b) => _buildAlertItem(l10n, b)),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => InlineErrorRetry(
        onRetry: () => truckId != null
            ? ref.invalidate(truckBreakdownsStreamProvider(truckId!))
            : ref.invalidate(activeBreakdownsStreamProvider),
      ),
    );
  }

  Widget _buildAlertHeader(AppLocalizations l10n, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Iconsax.warning_2, color: AppColors.error, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '${l10n.translate('breakdown.activeBreakdowns')} ($count)',
            style: const TextStyle(
              color: AppColors.error,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertItem(AppLocalizations l10n, BreakdownReportModel breakdown) {
    final severityColor = _getSeverityColor(breakdown.severity);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border(
          left: BorderSide(color: severityColor, width: 4),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getSeverityIcon(breakdown.severity),
            color: severityColor,
            size: 24,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      breakdown.truckImmatriculation,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: severityColor.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        _getSeverityLabel(l10n, breakdown.severity),
                        style: TextStyle(
                          color: severityColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  breakdown.description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${_getStatusLabel(l10n, breakdown.status)} • ${breakdown.formattedDate}',
                  style: TextStyle(
                    color: _getStatusColor(breakdown.status),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(BreakdownSeverity severity) {
    switch (severity) {
      case BreakdownSeverity.low:
        return AppColors.info;
      case BreakdownSeverity.medium:
        return AppColors.warning;
      case BreakdownSeverity.high:
        return AppColors.error;
      case BreakdownSeverity.critical:
        return const Color(0xFFB71C1C);
    }
  }

  IconData _getSeverityIcon(BreakdownSeverity severity) {
    switch (severity) {
      case BreakdownSeverity.low:
        return Iconsax.info_circle;
      case BreakdownSeverity.medium:
        return Iconsax.warning_2;
      case BreakdownSeverity.high:
        return Iconsax.danger;
      case BreakdownSeverity.critical:
        return Iconsax.flash_1;
    }
  }

  String _getSeverityLabel(
      AppLocalizations l10n, BreakdownSeverity severity) {
    switch (severity) {
      case BreakdownSeverity.low:
        return l10n.translate('breakdown.severityLow');
      case BreakdownSeverity.medium:
        return l10n.translate('breakdown.severityMedium');
      case BreakdownSeverity.high:
        return l10n.translate('breakdown.severityHigh');
      case BreakdownSeverity.critical:
        return l10n.translate('breakdown.severityCritical');
    }
  }

  Color _getStatusColor(BreakdownStatus status) {
    switch (status) {
      case BreakdownStatus.pending:
        return AppColors.warning;
      case BreakdownStatus.inDiagnostic:
        return AppColors.info;
      case BreakdownStatus.inRepair:
        return AppColors.primary;
      case BreakdownStatus.resolved:
        return AppColors.success;
      case BreakdownStatus.closed:
        return AppColors.textSecondary;
    }
  }

  String _getStatusLabel(AppLocalizations l10n, BreakdownStatus status) {
    switch (status) {
      case BreakdownStatus.pending:
        return l10n.translate('breakdown.pending');
      case BreakdownStatus.inDiagnostic:
        return l10n.translate('breakdown.inDiagnostic');
      case BreakdownStatus.inRepair:
        return l10n.translate('breakdown.inRepair');
      case BreakdownStatus.resolved:
        return l10n.translate('breakdown.resolved');
      case BreakdownStatus.closed:
        return l10n.translate('breakdown.closed');
    }
  }
}
