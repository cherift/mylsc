import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/utils/extensions.dart';
import '../../domain/models/truck_field.dart';
import '../../domain/models/truck_model.dart';
import '../providers/truck_providers.dart';
import '../utils/truck_field_value_extractor.dart';
import '../widgets/create_truck_dialog.dart';
import '../widgets/customize_columns_dialog.dart';
import 'truck_dashboard_screen.dart';

/// Écran de gestion des camions
class TruckManagementScreen extends ConsumerStatefulWidget {
  const TruckManagementScreen({super.key});

  @override
  ConsumerState<TruckManagementScreen> createState() =>
      _TruckManagementScreenState();
}

class _TruckManagementScreenState
    extends ConsumerState<TruckManagementScreen> {
  String _searchQuery = '';
  String? _filterStatus;
  String? _filterType;

  @override
  Widget build(BuildContext context) {
    final hp = context.responsiveHorizontalPadding;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(hp, hp, hp, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              SizedBox(height: context.isMobile ? AppSpacing.sm : hp),
              _buildStats(),
              SizedBox(height: context.isMobile ? AppSpacing.sm : hp),
              _buildSearchAndFilters(),
              SizedBox(height: context.isMobile ? AppSpacing.sm : AppSpacing.lg),
              Expanded(child: _buildTrucksList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context);
    final isMobile = context.isMobile;

    if (isMobile) {
      // Mobile : titre compact sur une ligne + icônes seules
      return Row(
        children: [
          Expanded(
            child: Text(
              l10n.translate('trucks.management'),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: _showCustomizeColumnsDialog,
            tooltip: l10n.translate('trucks.customize'),
            icon: const Icon(Iconsax.setting_3, color: AppColors.primary, size: 22),
            style: IconButton.styleFrom(
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            onPressed: _showCreateTruckDialog,
            tooltip: l10n.translate('trucks.newTruck'),
            icon: const Icon(Iconsax.add, color: Colors.white, size: 22),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
        ],
      );
    }

    // Tablet / Desktop : layout original avec texte
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.translate('trucks.management'),
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: AppTheme.fs(context, 24),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.translate('trucks.subtitle'),
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            OutlinedButton.icon(
              onPressed: _showCustomizeColumnsDialog,
              icon: const Icon(Iconsax.setting_3, size: 18),
              label: Text(l10n.translate('trucks.customize')),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _showCreateTruckDialog,
              icon: const Icon(Iconsax.add, size: 18),
              label: Text(l10n.translate('trucks.newTruck')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStats() {
    final l10n = AppLocalizations.of(context);
    final statsAsync = ref.watch(truckStatsByStatusProvider);

    return statsAsync.when(
      data: (stats) {
        final total = stats.values.fold(0, (sum, count) => sum + count);
        final cards = [
          _StatData(Iconsax.truck, l10n.translate('trucks.totalTrucks'), total.toString(), AppColors.primary),
          _StatData(Iconsax.tick_circle, l10n.translate('trucks.inService'), stats['enService']?.toString() ?? '0', Colors.green),
          _StatData(Iconsax.setting_3, l10n.translate('trucks.maintenance'), stats['enMaintenance']?.toString() ?? '0', Colors.orange),
          _StatData(Iconsax.warning_2, l10n.translate('trucks.broken'), stats['enPanne']?.toString() ?? '0', Colors.red),
        ];

        if (context.isMobile) {
          // Mobile : ligne horizontale scrollable de chips compacts
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: cards.map((c) => Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: _buildStatChip(c),
              )).toList(),
            ),
          );
        }
        // Tablet / Desktop : une ligne
        return Row(
          children: cards
              .expand((c) => [Expanded(child: _buildStatCard(c)), const SizedBox(width: AppSpacing.md)])
              .toList()
            ..removeLast(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Text('${l10n.translate('common.error')}: $error'),
    );
  }

  Widget _buildStatCard(_StatData data) {
    final isMobile = context.isMobile;
    return Container(
      padding: EdgeInsets.all(isMobile ? AppSpacing.sm : AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: data.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 6 : AppSpacing.sm),
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(data.icon, color: data.color, size: isMobile ? 16 : 22),
          ),
          SizedBox(width: isMobile ? 6 : AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: isMobile ? 10 : 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  data.value,
                  style: TextStyle(
                    color: data.color,
                    fontSize: isMobile ? 16 : 22,
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

  // Chip compact pour mobile (stat en ligne horizontale)
  Widget _buildStatChip(_StatData data) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: data.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(data.icon, color: data.color, size: 14),
          const SizedBox(width: 4),
          Text(
            data.value,
            style: TextStyle(color: data.color, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 4),
          Text(
            data.title,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    final l10n = AppLocalizations.of(context);
    _filterStatus ??= l10n.translate('trucks.all');
    _filterType ??= l10n.translate('trucks.all');

    final searchField = TextField(
      onChanged: (value) => setState(() => _searchQuery = value),
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: l10n.translate('trucks.searchPlaceholder'),
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIcon: const Icon(Iconsax.search_normal, color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
      ),
    );

    final statusDropdown = _buildFilterDropdown(
      label: l10n.translate('trucks.statusFilter'),
      value: _filterStatus!,
      items: [
        l10n.translate('trucks.all'),
        l10n.translate('trucks.status.enService'),
        l10n.translate('trucks.status.enMaintenance'),
        l10n.translate('trucks.status.enPanne'),
        l10n.translate('trucks.status.immobilise'),
      ],
      onChanged: (value) => setState(() => _filterStatus = value ?? _filterStatus),
    );

    final typeDropdown = _buildFilterDropdown(
      label: l10n.translate('trucks.typeFilter'),
      value: _filterType!,
      items: [
        l10n.translate('trucks.all'),
        l10n.translate('trucks.types.porteur'),
        l10n.translate('trucks.types.tracteurRoutier'),
        l10n.translate('trucks.types.benne'),
        l10n.translate('trucks.types.plateau'),
        l10n.translate('trucks.types.citerne'),
        l10n.translate('trucks.types.frigorifique'),
      ],
      onChanged: (value) => setState(() => _filterType = value ?? _filterType),
    );

    final refreshBtn = IconButton(
      onPressed: () => ref.invalidate(activeTrucksProvider),
      icon: const Icon(Iconsax.refresh, color: AppColors.textPrimary),
      tooltip: l10n.translate('common.refresh'),
    );

    if (context.isMobile) {
      return Column(
        children: [
          SizedBox(height: 48, child: searchField),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(child: statusDropdown),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: typeDropdown),
              refreshBtn,
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(flex: 2, child: SizedBox(height: 48, child: searchField)),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: statusDropdown),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: typeDropdown),
        const SizedBox(width: AppSpacing.md),
        refreshBtn,
      ],
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: DropdownButton<String>(
        value: value,
        onChanged: onChanged,
        underline: const SizedBox(),
        isExpanded: true,
        dropdownColor: AppColors.surface,
        style: const TextStyle(color: AppColors.textPrimary),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(item, overflow: TextOverflow.ellipsis),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTrucksList() {
    final trucksAsync = ref.watch(activeTrucksProvider);
    final visibleFieldsAsync = ref.watch(visibleTruckFieldsProvider);

    return trucksAsync.when(
      data: (trucks) {
        final filteredTrucks = _filterTrucks(trucks);
        if (filteredTrucks.isEmpty) return _buildEmptyState();

        // Mobile : cards empilées
        if (context.isMobile) {
          return ListView.separated(
            itemCount: filteredTrucks.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) =>
                _buildTruckMobileCard(filteredTrucks[index]),
          );
        }

        // Tablet / Desktop : table configurable
        return visibleFieldsAsync.when(
          data: (visibleFields) => Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Column(
              children: [
                _buildTableHeader(visibleFields),
                const Divider(height: 1, color: AppColors.textSecondary),
                Expanded(
                  child: ListView.separated(
                    itemCount: filteredTrucks.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AppColors.textSecondary),
                    itemBuilder: (context, index) =>
                        _buildTruckRow(filteredTrucks[index], visibleFields),
                  ),
                ),
              ],
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Text('Erreur: $error'),
        );
      },
      loading: () =>
          const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (error, stack) => Center(
        child: Text('Erreur: $error',
            style: const TextStyle(color: AppColors.textSecondary)),
      ),
    );
  }

  Widget _buildTruckMobileCard(TruckModel truck) {
    final l10n = AppLocalizations.of(context);
    return InkWell(
      onTap: () => _openTruckDashboard(truck),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(Iconsax.truck, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    truck.immatriculation,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${truck.marque} ${truck.modele}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.translate('trucks.status.${truck.statut.name}'),
                    style: const TextStyle(
                        color: AppColors.textTertiary, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Iconsax.arrow_right_3,
                color: AppColors.textSecondary, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader(List<TruckField> visibleFields) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppRadius.md),
          topRight: Radius.circular(AppRadius.md),
        ),
      ),
      child: Row(
        children: [
          ...visibleFields.map((field) {
            return Expanded(
              child: Row(
                children: [
                  Icon(field.icon, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      l10n.translate('trucks.fields.${field.key}'),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }),
          SizedBox(
            width: 60,
            child: Text(
              l10n.translate('trucks.actions'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTruckRow(TruckModel truck, List<TruckField> visibleFields) {
    final l10n = AppLocalizations.of(context);
    return InkWell(
      onTap: () => _openTruckDashboard(truck),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            ...visibleFields.map((field) {
              final value = TruckFieldValueExtractor.getValue(truck, field.key, l10n);
              final statusIcon =
                  TruckFieldValueExtractor.getStatusIcon(truck, field.key);

              return Expanded(
                child: Row(
                  children: [
                    if (statusIcon != null) ...[
                      Text(statusIcon, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                    Flexible(
                      child: Text(
                        value,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }),
            SizedBox(
              width: 60,
              child: Center(
                child: IconButton(
                  onPressed: () => _openTruckDashboard(truck),
                  icon: const Icon(Iconsax.eye, size: 18),
                  color: AppColors.primary,
                  tooltip: l10n.translate('trucks.viewDashboard'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openTruckDashboard(TruckModel truck) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => TruckDashboardScreen(truck: truck),
      ),
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Iconsax.truck,
            size: 80,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.translate('trucks.noTrucksFound'),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.translate('trucks.noTrucksMessage'),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton.icon(
            onPressed: _showCreateTruckDialog,
            icon: const Icon(Iconsax.add),
            label: Text(l10n.translate('trucks.addTruck')),
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

  List<TruckModel> _filterTrucks(List<TruckModel> trucks) {
    final l10n = AppLocalizations.of(context);
    var filtered = trucks;

    // Filtre par recherche
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((truck) {
        return truck.immatriculation.toLowerCase().contains(query) ||
            truck.marque.toLowerCase().contains(query) ||
            truck.modele.toLowerCase().contains(query) ||
            truck.numeroInterneFlotte.toLowerCase().contains(query) ||
            truck.numeroChassis.toLowerCase().contains(query);
      }).toList();
    }

    // Filtre par statut
    if (_filterStatus != l10n.translate('trucks.all')) {
      filtered = filtered.where((truck) {
        final statusLabel = l10n.translate('trucks.status.${truck.statut.name}');
        return statusLabel == _filterStatus;
      }).toList();
    }

    // Filtre par type
    if (_filterType != l10n.translate('trucks.all')) {
      filtered = filtered.where((truck) {
        final typeLabel = l10n.translate('trucks.types.${truck.type.name}');
        return typeLabel == _filterType;
      }).toList();
    }

    return filtered;
  }

  Future<void> _showCustomizeColumnsDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const CustomizeColumnsDialog(),
    );

    if ((result ?? false) && mounted) {
      // Les préférences ont été sauvegardées
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('trucks.preferencesUpdated')),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _showCreateTruckDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const CreateTruckDialog(),
    );

    if ((result ?? false) && mounted) {
      // Le camion a été créé avec succès
      // Les providers ont déjà été invalidés dans le dialog
    }
  }
}

// ─── Data helpers ─────────────────────────────────────────────────────────────

class _StatData {
  const _StatData(this.icon, this.title, this.value, this.color);
  final IconData icon;
  final String title;
  final String value;
  final Color color;
}
