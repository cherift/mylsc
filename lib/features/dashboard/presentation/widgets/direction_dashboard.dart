import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/widgets/dashboard_filter_modal.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../trucks/presentation/providers/truck_providers.dart';
import '../../domain/models/dashboard_filter.dart';
import 'dashboard_section_card.dart';
import 'direction_kpi_row.dart';
import 'direction_vehicles_section.dart';
import 'direction_tonnage_section.dart';
import 'direction_fuel_section.dart';
import 'direction_breakdowns_section.dart';
import 'direction_fleets_section.dart';

/// Dashboard principal de la direction - assemble toutes les sections
class DirectionDashboard extends ConsumerStatefulWidget {
  const DirectionDashboard({required this.user, super.key});

  final UserModel user;

  @override
  ConsumerState<DirectionDashboard> createState() => _DirectionDashboardState();
}

class _DirectionDashboardState extends ConsumerState<DirectionDashboard> {
  DashboardFilter _filter = const DashboardFilter();

  void _openFilter(BuildContext context) {
    final trucks = ref.read(trucksStreamProvider).valueOrNull ?? [];
    DashboardFilterModal.show(
      context,
      availableTrucks: trucks,
      currentFilter: _filter,
      onApply: (newFilter) => setState(() => _filter = newFilter),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.translate('directionDashboard.title'),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              // Bouton filtre
              FilterIconButton(
                isActive: _filter.isActive,
                onTap: () => _openFilter(context),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // KPI Row
          DirectionKpiRow(filter: _filter),
          const SizedBox(height: AppSpacing.xl),

          // Sections graphiques (responsive)
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Véhicules + Tonnage
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: DashboardSectionCard(
                            title: l10n.translate(
                                'directionDashboard.vehiclesSection'),
                            icon: Iconsax.truck,
                            child: DirectionVehiclesSection(filter: _filter),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: DashboardSectionCard(
                            title: l10n.translate(
                                'directionDashboard.tonnageSection'),
                            icon: Iconsax.weight,
                            child: DirectionTonnageSection(filter: _filter),
                          ),
                        ),
                      ],
                    )
                  else ...[
                    DashboardSectionCard(
                      title: l10n
                          .translate('directionDashboard.vehiclesSection'),
                      icon: Iconsax.truck,
                      child: DirectionVehiclesSection(filter: _filter),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    DashboardSectionCard(
                      title: l10n
                          .translate('directionDashboard.tonnageSection'),
                      icon: Iconsax.weight,
                      child: DirectionTonnageSection(filter: _filter),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),

                  // Carburant + Pannes
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: DashboardSectionCard(
                            title: l10n.translate(
                                'directionDashboard.fuelSection'),
                            icon: Iconsax.gas_station,
                            child: DirectionFuelSection(filter: _filter),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: DashboardSectionCard(
                            title: l10n.translate(
                                'directionDashboard.breakdownsSection'),
                            icon: Iconsax.warning_2,
                            child: DirectionBreakdownsSection(filter: _filter),
                          ),
                        ),
                      ],
                    )
                  else ...[
                    DashboardSectionCard(
                      title: l10n
                          .translate('directionDashboard.fuelSection'),
                      icon: Iconsax.gas_station,
                      child: DirectionFuelSection(filter: _filter),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    DashboardSectionCard(
                      title: l10n.translate(
                          'directionDashboard.breakdownsSection'),
                      icon: Iconsax.warning_2,
                      child: DirectionBreakdownsSection(filter: _filter),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),

                  // Flottes
                  DashboardSectionCard(
                    title:
                        l10n.translate('directionDashboard.fleetsSection'),
                    icon: Iconsax.truck_fast,
                    child: const DirectionFleetsSection(),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
