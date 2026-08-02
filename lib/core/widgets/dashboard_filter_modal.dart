import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../i18n/app_localizations.dart';
import '../../features/trucks/domain/models/truck_model.dart';
import '../../features/dashboard/domain/models/dashboard_filter.dart';

/// Modale réutilisable pour filtrer les dashboards par date et par véhicule
class DashboardFilterModal extends StatefulWidget {
  const DashboardFilterModal({
    required this.availableTrucks,
    required this.currentFilter,
    required this.onApply,
    super.key,
  });

  final List<TruckModel> availableTrucks;
  final DashboardFilter currentFilter;
  final ValueChanged<DashboardFilter> onApply;

  /// Affiche la modale de filtre centrée dans l'écran
  static Future<void> show(
    BuildContext context, {
    required List<TruckModel> availableTrucks,
    required DashboardFilter currentFilter,
    required ValueChanged<DashboardFilter> onApply,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(
            horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 660),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: DashboardFilterModal(
              availableTrucks: availableTrucks,
              currentFilter: currentFilter,
              onApply: onApply,
            ),
          ),
        ),
      ),
    );
  }

  @override
  State<DashboardFilterModal> createState() => _DashboardFilterModalState();
}

class _DashboardFilterModalState extends State<DashboardFilterModal> {
  late DateTime? _startDate;
  late DateTime? _endDate;
  late Set<String> _selectedIds;
  bool _selectAll = false;
  String _search = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _startDate = widget.currentFilter.dateRange?.start;
    _endDate = widget.currentFilter.dateRange?.end;

    if (widget.currentFilter.selectedTruckIds == null) {
      _selectedIds = widget.availableTrucks.map((t) => t.id).toSet();
      _selectAll = true;
    } else {
      _selectedIds = Set.from(widget.currentFilter.selectedTruckIds!);
      _selectAll = _selectedIds.length == widget.availableTrucks.length;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TruckModel> get _filteredTrucks {
    if (_search.isEmpty) return widget.availableTrucks;
    final q = _search.toLowerCase();
    return widget.availableTrucks.where((t) {
      return t.immatriculation.toLowerCase().contains(q) ||
          t.numeroInterneFlotte.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _pickDate(BuildContext context, bool isStart) async {
    final initial = isStart
        ? (_startDate ?? DateTime.now())
        : (_endDate ?? _startDate ?? DateTime.now());
    final first = isStart ? DateTime(2020) : (_startDate ?? DateTime(2020));
    final last = isStart
        ? (_endDate ?? DateTime.now().add(const Duration(days: 365)))
        : DateTime.now().add(const Duration(days: 365));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            surface: AppColors.backgroundSecondary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) _endDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  void _toggleAll(bool value) {
    setState(() {
      _selectAll = value;
      if (value) {
        _selectedIds = widget.availableTrucks.map((t) => t.id).toSet();
      } else {
        _selectedIds.clear();
      }
    });
  }

  void _toggleTruck(String id, bool value) {
    setState(() {
      if (value) {
        _selectedIds.add(id);
      } else {
        _selectedIds.remove(id);
      }
      _selectAll = _selectedIds.length == widget.availableTrucks.length;
    });
  }

  void _reset() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _selectedIds = widget.availableTrucks.map((t) => t.id).toSet();
      _selectAll = true;
      _search = '';
      _searchController.clear();
    });
  }

  void _apply() {
    DateTimeRange? dateRange;
    if (_startDate != null && _endDate != null) {
      dateRange = DateTimeRange(start: _startDate!, end: _endDate!);
    } else if (_startDate != null) {
      dateRange = DateTimeRange(start: _startDate!, end: _startDate!);
    }

    // null = pas de restriction (tous sélectionnés)
    final truckIds =
        _selectAll ? null : Set<String>.from(_selectedIds);

    widget.onApply(DashboardFilter(
      dateRange: dateRange,
      selectedTruckIds: truckIds,
    ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dateFmt = DateFormat('dd/MM/yyyy');
    return Container(
      color: AppColors.backgroundSecondary,
      child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: Row(
                children: [
                  const Icon(Iconsax.filter, color: AppColors.primary, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    l10n.translate('dashboard.filter'),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _reset,
                    child: Text(
                      l10n.translate('dashboard.filterReset'),
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.surfaceBorder, height: 1),

            // ── Scrollable content ───────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Section Période ──────────────────────────────
                    _buildSectionHeader(
                        Iconsax.calendar, l10n.translate('dashboard.filterPeriod')),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildDateButton(
                              label: l10n.translate('dashboard.filterDateFrom'),
                              value: _startDate != null
                                  ? dateFmt.format(_startDate!)
                                  : l10n.translate('dashboard.filterNoDate'),
                              onTap: () => _pickDate(context, true),
                              isSet: _startDate != null,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _buildDateButton(
                              label: l10n.translate('dashboard.filterDateTo'),
                              value: _endDate != null
                                  ? dateFmt.format(_endDate!)
                                  : l10n.translate('dashboard.filterNoDate'),
                              onTap: () => _pickDate(context, false),
                              isSet: _endDate != null,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: AppColors.surfaceBorder, height: 24),

                    // ── Section Véhicules ────────────────────────────
                    if (widget.availableTrucks.isNotEmpty) ...[
                      _buildSectionHeader(
                          Iconsax.truck, l10n.translate('dashboard.filterVehicles')),
                      // "Tout sélectionner"
                      CheckboxListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg),
                        title: Text(
                          l10n.translate('dashboard.filterSelectAll'),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        value: _selectAll,
                        activeColor: AppColors.primary,
                        onChanged: (v) => _toggleAll(v ?? false),
                      ),
                      // Barre de recherche
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(
                              color: AppColors.textPrimary, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: l10n.translate('common.search'),
                            hintStyle: const TextStyle(
                                color: AppColors.textTertiary, fontSize: 13),
                            prefixIcon: const Icon(Iconsax.search_normal,
                                color: AppColors.textSecondary, size: 16),
                            filled: true,
                            fillColor: AppColors.background,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md, vertical: 8),
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
                              borderSide:
                                  const BorderSide(color: AppColors.primary),
                            ),
                          ),
                          onChanged: (v) => setState(() => _search = v),
                        ),
                      ),
                      // Liste des camions (max 200dp de hauteur)
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 220),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _filteredTrucks.length,
                          itemBuilder: (_, i) {
                            final truck = _filteredTrucks[i];
                            final label = truck.numeroInterneFlotte.isNotEmpty
                                ? '${truck.immatriculation} · ${truck.numeroInterneFlotte}'
                                : truck.immatriculation;
                            return CheckboxListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg),
                              title: Text(
                                label,
                                style: const TextStyle(
                                    color: AppColors.textPrimary, fontSize: 13),
                              ),
                              value: _selectedIds.contains(truck.id),
                              activeColor: AppColors.primary,
                              onChanged: (v) =>
                                  _toggleTruck(truck.id, v ?? false),
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),

            // ── Footer ──────────────────────────────────────────────
            const Divider(color: AppColors.surfaceBorder, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.surfaceBorder),
                        foregroundColor: AppColors.textSecondary,
                      ),
                      child: Text(l10n.translate('common.cancel')),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _apply,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      child: Text(l10n.translate('dashboard.filterApply')),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 15),
          const SizedBox(width: AppSpacing.xs),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton({
    required String label,
    required String value,
    required VoidCallback onTap,
    required bool isSet,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isSet
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.background,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isSet ? AppColors.primary : AppColors.surfaceBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSet ? AppColors.primary : AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  Iconsax.calendar_1,
                  size: 14,
                  color: isSet ? AppColors.primary : AppColors.textTertiary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      color: isSet
                          ? AppColors.primary
                          : AppColors.textTertiary,
                      fontSize: 13,
                      fontWeight:
                          isSet ? FontWeight.w600 : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Petit bouton filtre réutilisable avec badge "actif"
class FilterIconButton extends StatelessWidget {
  const FilterIconButton({
    required this.isActive,
    required this.onTap,
    super.key,
  });

  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: isActive ? AppColors.primary : AppColors.surfaceBorder,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Iconsax.filter,
                  size: 16,
                  color: isActive ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  l10n.translate('common.filter'),
                  style: TextStyle(
                    color:
                        isActive ? AppColors.primary : AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (isActive)
            Positioned(
              top: -3,
              right: -3,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.warning,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
