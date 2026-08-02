import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../domain/models/truck_field.dart';
import '../providers/truck_providers.dart';

/// Dialog pour personnaliser les colonnes affichées dans la liste des camions
class CustomizeColumnsDialog extends ConsumerStatefulWidget {
  const CustomizeColumnsDialog({super.key});

  @override
  ConsumerState<CustomizeColumnsDialog> createState() =>
      _CustomizeColumnsDialogState();
}

class _CustomizeColumnsDialogState
    extends ConsumerState<CustomizeColumnsDialog> {
  late Set<String> selectedFieldKeys;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final service = ref.read(truckDisplayPreferencesServiceProvider);
    final visibleKeys = await service.loadVisibleFields();
    setState(() {
      selectedFieldKeys = Set<String>.from(visibleKeys);
      isLoading = false;
    });
  }

  Future<void> _save() async {
    final service = ref.read(truckDisplayPreferencesServiceProvider);
    await service.saveVisibleFields(selectedFieldKeys.toList());

    // Invalider le provider pour recharger les champs visibles
    ref.invalidate(visibleTruckFieldsProvider);

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _resetToDefaults() async {
    final service = ref.read(truckDisplayPreferencesServiceProvider);
    await service.resetToDefaults();

    final defaultKeys = TruckFields.defaultFields.map((f) => f.key).toList();
    setState(() {
      selectedFieldKeys = Set<String>.from(defaultKeys);
    });
  }

  void _toggleField(TruckField field) {
    if (field.isRequired) return;

    setState(() {
      if (selectedFieldKeys.contains(field.key)) {
        selectedFieldKeys.remove(field.key);
      } else {
        selectedFieldKeys.add(field.key);
      }
    });
  }

  void _selectAll(List<TruckField> fields) {
    setState(() {
      selectedFieldKeys.addAll(fields.map((f) => f.key));
    });
  }

  void _deselectAll(List<TruckField> fields) {
    setState(() {
      for (final field in fields) {
        if (!field.isRequired) {
          selectedFieldKeys.remove(field.key);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;
    final dialogWidth = isMobile ? screenSize.width * 0.95 : 700.0;
    final contentHeight = screenSize.height * (isMobile ? 0.70 : 0.55);
    final pad = isMobile ? AppSpacing.md : AppSpacing.xl;

    if (isLoading) {
      return AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        content: SizedBox(
          width: dialogWidth,
          height: 160,
          child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        ),
      );
    }

    return AlertDialog(
      backgroundColor: AppColors.surface,
      insetPadding: EdgeInsets.all(isMobile ? 8 : 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      titlePadding: EdgeInsets.fromLTRB(pad, pad, pad, 0),
      contentPadding: EdgeInsets.fromLTRB(pad, AppSpacing.md, pad, 0),
      actionsPadding: EdgeInsets.fromLTRB(pad, AppSpacing.sm, pad, pad),
      title: _buildHeader(isMobile: isMobile),
      content: SizedBox(
        width: dialogWidth,
        height: contentHeight,
        child: Column(
          children: [
            if (!isMobile) ...[
              _buildStats(),
              const SizedBox(height: AppSpacing.md),
            ],
            Expanded(child: _buildFieldsList()),
          ],
        ),
      ),
      actions: [_buildActions(isMobile: isMobile)],
    );
  }

  Widget _buildHeader({bool isMobile = false}) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: const Icon(
            Iconsax.setting_3,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.translate('trucks.customizeColumns.title'),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.translate('trucks.customizeColumns.subtitle'),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Iconsax.close_square, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildStats() {
    final l10n = AppLocalizations.of(context);
    final totalFields = TruckFields.allFields.length;
    final selectedCount = selectedFieldKeys.length;
    final requiredCount = TruckFields.requiredFields.length;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          _buildStatItem(
            icon: Iconsax.menu,
            label: l10n.translate('trucks.customizeColumns.totalFields'),
            value: totalFields.toString(),
            color: AppColors.textSecondary,
          ),
          Container(
            height: 40,
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            color: AppColors.textSecondary.withValues(alpha: 0.2),
          ),
          _buildStatItem(
            icon: Iconsax.tick_square,
            label: l10n.translate('trucks.customizeColumns.selectedFields'),
            value: selectedCount.toString(),
            color: AppColors.primary,
          ),
          Container(
            height: 40,
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            color: AppColors.textSecondary.withValues(alpha: 0.2),
          ),
          _buildStatItem(
            icon: Iconsax.lock,
            label: l10n.translate('trucks.customizeColumns.requiredFields'),
            value: requiredCount.toString(),
            color: AppColors.accent,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldsList() {
    final fieldsByCategory = TruckFields.fieldsByCategory;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.1)),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.sm),
        itemCount: fieldsByCategory.length,
        separatorBuilder: (context, index) => const Divider(
          color: AppColors.textSecondary,
          height: 1,
        ),
        itemBuilder: (context, index) {
          final entry = fieldsByCategory.entries.elementAt(index);
          final fields = entry.value;
          if (fields.isEmpty) return const SizedBox.shrink();
          return _buildCategorySection(entry.key, fields);
        },
      ),
    );
  }

  Widget _buildCategorySection(
      TruckFieldCategory category, List<TruckField> fields) {
    final l10n = AppLocalizations.of(context);
    final selectedInCategory =
        fields.where((f) => selectedFieldKeys.contains(f.key)).length;
    final allSelected = selectedInCategory == fields.length;
    final someSelected = selectedInCategory > 0 && !allSelected;

    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      childrenPadding: const EdgeInsets.only(bottom: AppSpacing.sm),
      leading: Icon(
        allSelected
            ? Iconsax.tick_square
            : someSelected
                ? Iconsax.minus_square
                : Iconsax.square,
        color: allSelected || someSelected
            ? AppColors.primary
            : AppColors.textSecondary,
      ),
      title: Text(
        l10n.translate('trucks.customizeColumns.categories.${category.name}'),
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        '$selectedInCategory / ${fields.length} ${l10n.translate('trucks.customizeColumns.selectedFields').toLowerCase()}',
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
        ),
      ),
      trailing: PopupMenuButton<String>(
        icon: const Icon(Iconsax.more, color: AppColors.textSecondary, size: 20),
        color: AppColors.surface,
        onSelected: (value) {
          if (value == 'all') _selectAll(fields);
          if (value == 'none') _deselectAll(fields);
        },
        itemBuilder: (_) => [
          PopupMenuItem(
            value: 'all',
            child: Text(l10n.translate('trucks.customizeColumns.selectAll'),
                style: const TextStyle(color: AppColors.textPrimary)),
          ),
          PopupMenuItem(
            value: 'none',
            child: Text(l10n.translate('trucks.customizeColumns.deselectAll'),
                style: const TextStyle(color: AppColors.textPrimary)),
          ),
        ],
      ),
      children: fields
          .map(_buildFieldCheckbox)
          .toList(),
    );
  }

  Widget _buildFieldCheckbox(TruckField field) {
    final l10n = AppLocalizations.of(context);
    final isSelected = selectedFieldKeys.contains(field.key);
    final isDisabled = field.isRequired;

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
      ),
      leading: Icon(
        field.icon,
        color: isDisabled
            ? AppColors.accent
            : isSelected
                ? AppColors.primary
                : AppColors.textSecondary,
        size: 20,
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              l10n.translate('trucks.fields.${field.key}'),
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isDisabled
                    ? AppColors.accent
                    : AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
          if (isDisabled) ...[
            const SizedBox(width: AppSpacing.xs),
            const Icon(
              Iconsax.lock,
              color: AppColors.accent,
              size: 14,
            ),
          ],
        ],
      ),
      trailing: Checkbox(
        value: isSelected,
        onChanged: isDisabled ? null : (_) => _toggleField(field),
        activeColor: AppColors.primary,
        checkColor: Colors.white,
      ),
      onTap: isDisabled ? null : () => _toggleField(field),
    );
  }

  Widget _buildActions({bool isMobile = false}) {
    final l10n = AppLocalizations.of(context);

    if (isMobile) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            onPressed: _resetToDefaults,
            tooltip: l10n.translate('common.refresh'),
            icon: const Icon(Iconsax.refresh, size: 20, color: AppColors.textSecondary),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.translate('common.cancel'),
                style: const TextStyle(fontSize: 13)),
          ),
          const SizedBox(width: AppSpacing.sm),
          ElevatedButton.icon(
            onPressed: _save,
            icon: const Icon(Iconsax.tick_circle, size: 16),
            label: Text(l10n.translate('common.save'),
                style: const TextStyle(fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            ),
          ),
        ],
      );
    }

    return Wrap(
      alignment: WrapAlignment.end,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        OutlinedButton.icon(
          onPressed: _resetToDefaults,
          icon: const Icon(Iconsax.refresh, size: 18),
          label: Text(l10n.translate('common.refresh')),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            side: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.3)),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.translate('common.cancel')),
        ),
        ElevatedButton.icon(
          onPressed: _save,
          icon: const Icon(Iconsax.tick_circle, size: 18),
          label: Text(l10n.translate('common.save')),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl, vertical: AppSpacing.md),
          ),
        ),
      ],
    );
  }
}
