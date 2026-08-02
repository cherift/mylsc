import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../domain/models/truck_model.dart';
import '../../domain/models/truck_field.dart';
import '../providers/truck_providers.dart';
import '../widgets/edit_truck_dialog.dart';
import '../widgets/dashboard/fuel_gauge_widget.dart';
import '../widgets/dashboard/speed_gauge_widget.dart';
import '../widgets/dashboard/alert_card_widget.dart';
import '../widgets/dashboard/action_button_widget.dart';
import '../widgets/dashboard/info_card_widget.dart';
import '../widgets/dashboard/dashboard_customize_dialog.dart';
import '../../../fuel/presentation/widgets/fuel_history_widget.dart';
import '../../../inspection/presentation/widgets/inspection_history_widget.dart';

/// Écran tableau de bord d'un véhicule
class TruckDashboardScreen extends ConsumerStatefulWidget {

  const TruckDashboardScreen({required this.truck, super.key});
  final TruckModel truck;

  @override
  ConsumerState<TruckDashboardScreen> createState() =>
      _TruckDashboardScreenState();
}

class _TruckDashboardScreenState extends ConsumerState<TruckDashboardScreen> {
  late TruckModel _truck;

  // Valeurs simulées pour les jauges (en attendant les balises GPS)
  double _fuelLevel = 0.65; // 65% de carburant
  double _currentSpeed = 0; // Véhicule à l'arrêt par défaut

  // Champs visibles sur le tableau de bord
  List<String> _visibleFields = [
    'kilometrageActuel',
    'heuresMoteur',
    'siteAffectation',
    'typeActivite',
    'chauffeurPrincipal',
    'prochaineMaintenancePrevue',
  ];

  @override
  void initState() {
    super.initState();
    _truck = widget.truck;
    _simulateFuelAndSpeed();
  }

  void _simulateFuelAndSpeed() {
    // Simulation basée sur le statut du véhicule
    if (_truck.statut == TruckStatus.enService) {
      _fuelLevel = 0.65;
      _currentSpeed = 45; // En mouvement
    } else if (_truck.statut == TruckStatus.enMaintenance) {
      _fuelLevel = 0.30;
      _currentSpeed = 0;
    } else if (_truck.statut == TruckStatus.enPanne) {
      _fuelLevel = 0.15;
      _currentSpeed = 0;
    } else {
      _fuelLevel = 0.50;
      _currentSpeed = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header avec infos véhicule
            SliverToBoxAdapter(
              child: _buildHeader(l10n),
            ),

            // Contenu principal
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              sliver: SliverToBoxAdapter(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Responsive: 2 colonnes sur grand écran, 1 sur petit
                    if (constraints.maxWidth > 900) {
                      return _buildWideLayout(l10n);
                    } else {
                      return _buildNarrowLayout(l10n);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(context.responsiveHorizontalPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface,
            AppColors.surface.withValues(alpha: 0.8),
          ],
        ),
        border: const Border(
          bottom: BorderSide(color: AppColors.surfaceBorder),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bouton retour et actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Retour
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Iconsax.arrow_left),
                color: AppColors.textPrimary,
                tooltip: l10n.translate('common.back'),
              ),
              // Actions
              Row(
                children: [
                  IconButton(
                    onPressed: _showCustomizeDialog,
                    icon: const Icon(Iconsax.setting_3),
                    color: AppColors.textSecondary,
                    tooltip: l10n.translate('trucks.customize'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton(
                    onPressed: _refreshData,
                    icon: const Icon(Iconsax.refresh),
                    color: AppColors.textSecondary,
                    tooltip: l10n.translate('common.refresh'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Infos principales du véhicule
          Row(
            children: [
              // Icône du véhicule avec statut
              _buildVehicleIcon(),
              const SizedBox(width: AppSpacing.lg),

              // Infos textuelles
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Immat + No interne EN PREMIER
                    Row(
                      children: [
                        Text(
                          _truck.immatriculation,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_truck.numeroInterneFlotte.isNotEmpty) ...[
                          const SizedBox(width: AppSpacing.md),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(AppRadius.xs),
                            ),
                            child: Text(
                              '#${_truck.numeroInterneFlotte}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    // Marque + modèle en secondaire
                    Text(
                      _truck.displayName,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        _buildStatusBadge(l10n),
                        const SizedBox(width: AppSpacing.md),
                        Text(
                          l10n.translate('trucks.types.${_truck.type.name}'),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleIcon() {
    final statusColor = _getStatusColor();

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            statusColor.withValues(alpha: 0.2),
            statusColor.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(
              Iconsax.truck,
              size: 40,
              color: statusColor,
            ),
          ),
          // Indicateur de statut
          Positioned(
            right: 8,
            bottom: 8,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.surface,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withValues(alpha: 0.5),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(AppLocalizations l10n) {
    final statusColor = _getStatusColor();
    final statusText = l10n.translate('trucks.status.${_truck.statut.name}');

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (_truck.statut) {
      case TruckStatus.enService:
        return AppColors.success;
      case TruckStatus.enMaintenance:
        return AppColors.warning;
      case TruckStatus.enPanne:
        return AppColors.error;
      case TruckStatus.immobilise:
        return AppColors.textMuted;
    }
  }

  Widget _buildWideLayout(AppLocalizations l10n) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Colonne gauche
        Expanded(
          child: Column(
            children: [
              _buildGaugesSection(l10n),
              const SizedBox(height: AppSpacing.lg),
              _buildAlertsSection(l10n),
              const SizedBox(height: AppSpacing.lg),
              FuelHistoryWidget(truckId: _truck.id),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        // Colonne droite
        Expanded(
          child: Column(
            children: [
              _buildActionsSection(l10n),
              const SizedBox(height: AppSpacing.lg),
              _buildInfoSection(l10n),
              const SizedBox(height: AppSpacing.lg),
              InspectionHistoryWidget(truckId: _truck.id),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(AppLocalizations l10n) {
    return Column(
      children: [
        _buildGaugesSection(l10n),
        const SizedBox(height: AppSpacing.lg),
        _buildAlertsSection(l10n),
        const SizedBox(height: AppSpacing.lg),
        _buildActionsSection(l10n),
        const SizedBox(height: AppSpacing.lg),
        _buildInfoSection(l10n),
        const SizedBox(height: AppSpacing.lg),
        FuelHistoryWidget(truckId: _truck.id),
        const SizedBox(height: AppSpacing.lg),
        InspectionHistoryWidget(truckId: _truck.id),
      ],
    );
  }

  Widget _buildGaugesSection(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Iconsax.speedometer,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l10n.translate('trucks.dashboard.gauges'),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: FuelGaugeWidget(
                  fuelLevel: _fuelLevel,
                  capacity: _truck.capaciteReservoir ?? 400,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: SpeedGaugeWidget(
                  currentSpeed: _currentSpeed,
                  maxSpeed: 120,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsSection(AppLocalizations l10n) {
    final alerts = _getAlerts(l10n);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                alerts.isEmpty ? Iconsax.tick_circle : Iconsax.warning_2,
                color: alerts.isEmpty ? AppColors.success : AppColors.warning,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l10n.translate('trucks.dashboard.alerts'),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (alerts.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    '${alerts.length}',
                    style: const TextStyle(
                      color: AppColors.warning,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (alerts.isEmpty)
            _buildNoAlertsState(l10n)
          else
            Column(
              children: alerts
                  .map((alert) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: alert,
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildNoAlertsState(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(
              Iconsax.tick_circle,
              color: AppColors.success,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.translate('trucks.dashboard.noAlerts'),
                  style: const TextStyle(
                    color: AppColors.success,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.translate('trucks.dashboard.allGood'),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _getAlerts(AppLocalizations l10n) {
    final alerts = <Widget>[];

    // Alerte carburant bas
    if (_fuelLevel < 0.25) {
      alerts.add(AlertCardWidget(
        type: AlertType.warning,
        title: l10n.translate('trucks.dashboard.lowFuel'),
        message: l10n.translate('trucks.dashboard.lowFuelMessage'),
        icon: Iconsax.gas_station,
        onAction: _showAddFuelDialog,
        actionLabel: l10n.translate('trucks.dashboard.addFuel'),
      ));
    }

    // Alerte maintenance prochaine
    if (_truck.maintenanceAVenir) {
      alerts.add(AlertCardWidget(
        type: AlertType.info,
        title: l10n.translate('trucks.dashboard.maintenanceSoon'),
        message: _truck.prochaineMaintenancePrevue != null
            ? '${l10n.translate('trucks.dashboard.scheduledFor')} ${DateFormat('dd/MM/yyyy').format(_truck.prochaineMaintenancePrevue!)}'
            : l10n.translate('trucks.dashboard.maintenanceNeeded'),
        icon: Iconsax.setting_3,
        onAction: _showMaintenanceDialog,
        actionLabel: l10n.translate('trucks.dashboard.planMaintenance'),
      ));
    }

    // Alerte visite technique expirée
    if (!_truck.visiteTechniqueValide) {
      alerts.add(AlertCardWidget(
        type: AlertType.error,
        title: l10n.translate('trucks.dashboard.technicalInspection'),
        message: l10n.translate('trucks.dashboard.technicalInspectionExpired'),
        icon: Iconsax.clipboard_close,
      ));
    }

    // Alerte assurance expirée
    if (!_truck.hasAssurance) {
      alerts.add(AlertCardWidget(
        type: AlertType.error,
        title: l10n.translate('trucks.dashboard.insurance'),
        message: l10n.translate('trucks.dashboard.insuranceExpired'),
        icon: Iconsax.shield_cross,
      ));
    }

    // Alerte véhicule en panne
    if (_truck.statut == TruckStatus.enPanne) {
      alerts.add(AlertCardWidget(
        type: AlertType.error,
        title: l10n.translate('trucks.dashboard.breakdown'),
        message: l10n.translate('trucks.dashboard.breakdownMessage'),
        icon: Iconsax.warning_2,
      ));
    }

    return alerts;
  }

  Widget _buildActionsSection(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Iconsax.flash,
                color: AppColors.accent,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l10n.translate('trucks.dashboard.quickActions'),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              ActionButtonWidget(
                icon: Iconsax.gas_station,
                label: l10n.translate('trucks.dashboard.addFuel'),
                color: AppColors.primary,
                onPressed: _showAddFuelDialog,
              ),
              ActionButtonWidget(
                icon: Iconsax.warning_2,
                label: l10n.translate('trucks.dashboard.reportBreakdown'),
                color: AppColors.error,
                onPressed: _showBreakdownDialog,
              ),
              ActionButtonWidget(
                icon: Iconsax.setting_3,
                label: l10n.translate('trucks.dashboard.maintenance'),
                color: AppColors.warning,
                onPressed: _showMaintenanceDialog,
              ),
              ActionButtonWidget(
                icon: Iconsax.edit,
                label: l10n.translate('trucks.edit'),
                color: AppColors.info,
                onPressed: _showEditDialog,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Iconsax.info_circle,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l10n.translate('trucks.dashboard.vehicleInfo'),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _showCustomizeDialog,
                icon: const Icon(Iconsax.setting_3, size: 16),
                label: Text(l10n.translate('trucks.customize')),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: _visibleFields.map((fieldKey) {
              final field = TruckFields.allFields.firstWhere(
                (f) => f.key == fieldKey,
                orElse: () => TruckFields.immatriculation,
              );
              return InfoCardWidget(
                field: field,
                truck: _truck,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }


  void _showAddFuelDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            const Icon(Iconsax.gas_station, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Text(l10n.translate('trucks.dashboard.addFuel')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.translate('trucks.dashboard.addFuelDescription'),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              decoration: InputDecoration(
                labelText: l10n.translate('trucks.dashboard.fuelQuantity'),
                suffixText: 'L',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.translate('common.cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.translate('trucks.dashboard.fuelAdded')),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: Text(l10n.translate('common.add')),
          ),
        ],
      ),
    );
  }

  void _showBreakdownDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            const Icon(Iconsax.warning_2, color: AppColors.error),
            const SizedBox(width: AppSpacing.sm),
            Text(l10n.translate('trucks.dashboard.reportBreakdown')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.translate('trucks.dashboard.breakdownDescription'),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              decoration: InputDecoration(
                labelText: l10n.translate('trucks.dashboard.breakdownDetails'),
                hintText: l10n.translate('trucks.dashboard.breakdownHint'),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.translate('common.cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () async {
              final breakdownReportedMessage =
                  l10n.translate('trucks.dashboard.breakdownReported');
              Navigator.pop(context);
              // Mettre à jour le statut du véhicule
              final repository = ref.read(truckRepositoryProvider);
              await repository.updateTruckFields(
                _truck.id,
                {'statut': TruckStatus.enPanne.name},
              );
              setState(() {
                _truck = _truck.copyWith(statut: TruckStatus.enPanne);
                _simulateFuelAndSpeed();
              });
              if (!mounted) return;
              ScaffoldMessenger.of(this.context).showSnackBar(
                SnackBar(
                  content: Text(breakdownReportedMessage),
                  backgroundColor: AppColors.error,
                ),
              );
            },
            child: Text(l10n.translate('trucks.dashboard.report')),
          ),
        ],
      ),
    );
  }

  void _showMaintenanceDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            const Icon(Iconsax.setting_3, color: AppColors.warning),
            const SizedBox(width: AppSpacing.sm),
            Text(l10n.translate('trucks.dashboard.maintenance')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.translate('trucks.dashboard.maintenanceDescription'),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Iconsax.calendar_tick,
                  color: AppColors.warning,
                ),
              ),
              title: Text(l10n.translate('trucks.dashboard.scheduleMaintenance')),
              subtitle: Text(l10n.translate('trucks.dashboard.scheduleMaintenanceDesc')),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Iconsax.document_text,
                  color: AppColors.info,
                ),
              ),
              title: Text(l10n.translate('trucks.dashboard.maintenanceHistory')),
              subtitle: Text(l10n.translate('trucks.dashboard.maintenanceHistoryDesc')),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.translate('common.close')),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => EditTruckDialog(truck: _truck),
    );

    if (result ?? false) {
      await _refreshData();
    }
  }

  Future<void> _showCustomizeDialog() async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => DashboardCustomizeDialog(
        currentFields: _visibleFields,
      ),
    );

    if (result != null) {
      setState(() {
        _visibleFields = result;
      });
    }
  }

  Future<void> _refreshData() async {
    final repository = ref.read(truckRepositoryProvider);
    final updatedTruck = await repository.getTruckById(_truck.id);
    if (updatedTruck != null && mounted) {
      setState(() {
        _truck = updatedTruck;
        _simulateFuelAndSpeed();
      });
    }
  }
}
