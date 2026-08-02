import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../domain/models/vehicle_inspection_model.dart';
import '../providers/inspection_providers.dart';
import '../widgets/inspection_form_widget.dart';

/// Écran liste des inspections véhicules
class InspectionListScreen extends ConsumerStatefulWidget {
  const InspectionListScreen({super.key});

  @override
  ConsumerState<InspectionListScreen> createState() =>
      _InspectionListScreenState();
}

class _InspectionListScreenState extends ConsumerState<InspectionListScreen> {
  VehicleState? _filterState;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final inspectionsAsync = ref.watch(filteredInspectionsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(context.responsiveHorizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(l10n),
              SizedBox(height: context.responsiveHorizontalPadding),
              _buildFilters(l10n),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: inspectionsAsync.when(
                  data: (inspections) {
                    final filtered = _applyFilter(inspections);
                    if (filtered.isEmpty) {
                      return _buildEmptyState(l10n);
                    }
                    return _buildInspectionsList(filtered, l10n);
                  },
                  loading: () => const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.primary),
                  ),
                  error: (error, _) => Center(
                    child: Text(
                      '${l10n.translate('common.error')}: $error',
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showInspectionForm(context, l10n),
        backgroundColor: AppColors.primary,
        icon: const Icon(Iconsax.add, color: Colors.white),
        label: Text(
          l10n.translate('inspection.newInspection'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.translate('inspection.title'),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.translate('inspection.subtitle'),
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildFilters(AppLocalizations l10n) {
    return Row(
      children: [
        _buildFilterChip(
          label: l10n.translate('inspection.all'),
          isSelected: _filterState == null,
          onTap: () => setState(() => _filterState = null),
          color: AppColors.primary,
        ),
        const SizedBox(width: AppSpacing.sm),
        _buildFilterChip(
          label: l10n.translate('inspection.bonEtat'),
          isSelected: _filterState == VehicleState.bonEtat,
          onTap: () => setState(() => _filterState = VehicleState.bonEtat),
          color: AppColors.success,
        ),
        const SizedBox(width: AppSpacing.sm),
        _buildFilterChip(
          label: l10n.translate('inspection.bonEtatAvecObservation'),
          isSelected: _filterState == VehicleState.bonEtatAvecObservation,
          onTap: () => setState(
              () => _filterState = VehicleState.bonEtatAvecObservation),
          color: AppColors.warning,
        ),
        const SizedBox(width: AppSpacing.sm),
        _buildFilterChip(
          label: l10n.translate('inspection.nonFonctionnel'),
          isSelected: _filterState == VehicleState.nonFonctionnel,
          onTap: () =>
              setState(() => _filterState = VehicleState.nonFonctionnel),
          color: AppColors.error,
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: isSelected ? color : AppColors.surfaceBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  List<VehicleInspectionModel> _applyFilter(
      List<VehicleInspectionModel> inspections) {
    if (_filterState == null) return inspections;
    return inspections.where((i) => i.state == _filterState).toList();
  }

  Widget _buildInspectionsList(
      List<VehicleInspectionModel> inspections, AppLocalizations l10n) {
    return ListView.separated(
      itemCount: inspections.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        return _buildInspectionCard(inspections[index], l10n);
      },
    );
  }

  Widget _buildInspectionCard(
      VehicleInspectionModel inspection, AppLocalizations l10n) {
    final color = _stateColor(inspection.state);
    final icon = _stateIcon(inspection.state);
    final stateLabel = l10n.translate('inspection.${inspection.state.name}');
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(inspection.inspectionDate);

    return Container(
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
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inspection.truckId,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Text(
                  stateLabel,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (inspection.observation != null &&
              inspection.observation!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                inspection.observation!,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          if (inspection.photoUrls != null &&
              inspection.photoUrls!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(Iconsax.camera, color: AppColors.textTertiary, size: 16),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '${inspection.photoUrls!.length} photo(s)',
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Iconsax.clipboard_text,
            size: 80,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.translate('inspection.noInspections'),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton.icon(
            onPressed: () => _showInspectionForm(context, l10n),
            icon: const Icon(Iconsax.add),
            label: Text(l10n.translate('inspection.newInspection')),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.md,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showInspectionForm(BuildContext context, AppLocalizations l10n) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: AppSpacing.sm),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textTertiary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                l10n.translate('inspection.formTitle'),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Expanded(child: InspectionFormWidget()),
          ],
        ),
      ),
    );
  }

  Color _stateColor(VehicleState state) {
    switch (state) {
      case VehicleState.bonEtat:
        return AppColors.success;
      case VehicleState.bonEtatAvecObservation:
        return AppColors.warning;
      case VehicleState.nonFonctionnel:
        return AppColors.error;
      case VehicleState.accidente:
        return AppColors.error;
      case VehicleState.autres:
        return AppColors.textSecondary;
    }
  }

  IconData _stateIcon(VehicleState state) {
    switch (state) {
      case VehicleState.bonEtat:
        return Iconsax.tick_circle;
      case VehicleState.bonEtatAvecObservation:
        return Iconsax.warning_2;
      case VehicleState.nonFonctionnel:
        return Iconsax.close_circle;
      case VehicleState.accidente:
        return Iconsax.danger;
      case VehicleState.autres:
        return Iconsax.info_circle;
    }
  }
}
