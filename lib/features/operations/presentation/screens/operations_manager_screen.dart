import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/inline_error_retry.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../trips/domain/models/trip_model.dart';
import '../../../trips/presentation/providers/trip_providers.dart';
import '../../../shifts/presentation/providers/shift_providers.dart';
import '../../../weighing/presentation/providers/weighing_providers.dart';
import '../../../breakdown/presentation/providers/breakdown_providers.dart';
import '../../../trucks/presentation/providers/truck_providers.dart';
import '../../../fuel/domain/models/fuel_request_model.dart';
import '../../../fuel/data/repositories/fuel_request_repository.dart';
import '../../../fuel/presentation/providers/fuel_request_providers.dart';

/// Écran du responsable opérations - KPIs et rapports
class OperationsManagerScreen extends ConsumerStatefulWidget {
  const OperationsManagerScreen({super.key});

  @override
  ConsumerState<OperationsManagerScreen> createState() =>
      _OperationsManagerScreenState();
}

class _OperationsManagerScreenState
    extends ConsumerState<OperationsManagerScreen> {
  bool _showSettings = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final l10n = AppLocalizations.of(context);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (_showSettings) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.backgroundSecondary,
              leading: IconButton(
                icon: const Icon(Iconsax.arrow_left,
                    color: AppColors.textPrimary),
                onPressed: () => setState(() => _showSettings = false),
              ),
              title: Text(
                l10n.translate('settings.title'),
                style: const TextStyle(color: AppColors.textPrimary),
              ),
            ),
            body: const SettingsScreen(),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(user, l10n),
                Expanded(
                  child: _buildDashboard(l10n),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text('Erreur: $error',
              style: const TextStyle(color: AppColors.error)),
        ),
      ),
    );
  }

  Widget _buildHeader(UserModel user, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.backgroundSecondary,
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceBorder),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(
              Iconsax.diagram,
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
                  l10n.translate('users.roles.responsableOperations'),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  user.fullName.isEmpty ? user.email : user.fullName,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _showSettings = true),
            icon: const Icon(Iconsax.setting_2,
                color: AppColors.textSecondary),
          ),
          IconButton(
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).signOut();
              if (mounted) {
                await Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            icon: const Icon(Iconsax.logout, color: AppColors.error),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(context.responsiveHorizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildKpiRow(l10n),
          const SizedBox(height: AppSpacing.xl),
          _buildDisputedRequestsSection(l10n),
          const SizedBox(height: AppSpacing.xl),
          _buildTripStatsSection(l10n),
          const SizedBox(height: AppSpacing.xl),
          _buildBreakdownStatsSection(l10n),
          const SizedBox(height: AppSpacing.xl),
          _buildWeighingStatsSection(l10n),
        ],
      ),
    );
  }

  Widget _buildKpiRow(AppLocalizations l10n) {
    final trucksAsync = ref.watch(activeTrucksProvider);
    final shiftsAsync = ref.watch(activeShiftsStreamProvider);
    final breakdownsAsync = ref.watch(activeBreakdownsStreamProvider);
    final tripsAsync = ref.watch(allTripsStreamProvider);

    final totalTrucks = trucksAsync.valueOrNull?.length ?? 0;
    final activeShifts = shiftsAsync.valueOrNull?.length ?? 0;
    final activeBreakdowns = breakdownsAsync.valueOrNull?.length ?? 0;
    final trips = tripsAsync.valueOrNull ?? [];
    final validatedTrips =
        trips.where((t) => t.status == TripStatus.validated).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'KPIs',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _buildKpiCard(
                icon: Iconsax.truck,
                label: l10n.translate('dashboard.vehicles'),
                value: '$totalTrucks',
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildKpiCard(
                icon: Iconsax.people,
                label: l10n.translate('shift.activeShift'),
                value: '$activeShifts',
                color: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _buildKpiCard(
                icon: Iconsax.tick_circle,
                label: l10n.translate('trip.validatedTrips'),
                value: '$validatedTrips',
                color: AppColors.info,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildKpiCard(
                icon: Iconsax.warning_2,
                label: l10n.translate('breakdown.activeBreakdowns'),
                value: '$activeBreakdowns',
                color: AppColors.error,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripStatsSection(AppLocalizations l10n) {
    final tripsAsync = ref.watch(allTripsStreamProvider);

    return tripsAsync.when(
      data: (trips) {
        final inProgress =
            trips.where((t) => t.status == TripStatus.inProgress).length;
        final pending = trips
            .where((t) => t.status == TripStatus.pendingValidation)
            .length;
        final validated =
            trips.where((t) => t.status == TripStatus.validated).length;
        final rejected =
            trips.where((t) => t.status == TripStatus.rejected).length;

        final totalTonnage = trips
            .where((t) => t.netTonnage != null)
            .fold<double>(0, (sum, t) => sum + t.netTonnage!);

        return _buildSectionCard(
          icon: Iconsax.repeat,
          title: l10n.translate('trip.title'),
          color: AppColors.primary,
          children: [
            _buildStatRow(l10n.translate('trip.inProgress'), '$inProgress',
                AppColors.info),
            _buildStatRow(l10n.translate('trip.pendingValidation'),
                '$pending', AppColors.warning),
            _buildStatRow(l10n.translate('trip.validated'), '$validated',
                AppColors.success),
            _buildStatRow(l10n.translate('trip.rejected'), '$rejected',
                AppColors.error),
            const Divider(color: AppColors.surfaceBorder),
            _buildStatRow(l10n.translate('trip.netTonnage'),
                '${totalTonnage.toStringAsFixed(1)} T', AppColors.primary),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (_, __) => InlineErrorRetry(
        onRetry: () => ref.invalidate(allTripsStreamProvider),
      ),
    );
  }

  Widget _buildBreakdownStatsSection(AppLocalizations l10n) {
    final breakdownsAsync = ref.watch(allBreakdownsStreamProvider);

    return breakdownsAsync.when(
      data: (breakdowns) {
        final pending =
            breakdowns.where((b) => b.status.name == 'pending').length;
        final inDiag =
            breakdowns.where((b) => b.status.name == 'inDiagnostic').length;
        final inRepair =
            breakdowns.where((b) => b.status.name == 'inRepair').length;
        final resolved =
            breakdowns.where((b) => b.status.name == 'resolved').length;

        return _buildSectionCard(
          icon: Iconsax.warning_2,
          title: l10n.translate('breakdown.title'),
          color: AppColors.error,
          children: [
            _buildStatRow(l10n.translate('breakdown.pending'), '$pending',
                AppColors.warning),
            _buildStatRow(l10n.translate('breakdown.inDiagnostic'),
                '$inDiag', AppColors.info),
            _buildStatRow(l10n.translate('breakdown.inRepair'),
                '$inRepair', AppColors.primary),
            _buildStatRow(l10n.translate('breakdown.resolved'),
                '$resolved', AppColors.success),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (_, __) => InlineErrorRetry(
        onRetry: () => ref.invalidate(allBreakdownsStreamProvider),
      ),
    );
  }

  Widget _buildWeighingStatsSection(AppLocalizations l10n) {
    final weighingsAsync = ref.watch(allWeighingsStreamProvider);

    return weighingsAsync.when(
      data: (weighings) {
        final mine =
            weighings.where((w) => w.location.name == 'mine').length;
        final port =
            weighings.where((w) => w.location.name == 'port').length;

        return _buildSectionCard(
          icon: Iconsax.weight,
          title: l10n.translate('weighing.title'),
          color: AppColors.info,
          children: [
            _buildStatRow(l10n.translate('weighing.mineRecords'), '$mine',
                AppColors.warning),
            _buildStatRow(l10n.translate('weighing.portRecords'), '$port',
                AppColors.info),
            _buildStatRow(
                l10n.translate('weighing.allRecords'),
                '${weighings.length}',
                AppColors.primary),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (_, __) => InlineErrorRetry(
        onRetry: () => ref.invalidate(allWeighingsStreamProvider),
      ),
    );
  }

  Widget _buildDisputedRequestsSection(AppLocalizations l10n) {
    final disputedAsync = ref.watch(disputedRequestsStreamProvider);
    final authState = ref.watch(authControllerProvider);
    final userId = authState.valueOrNull?.id ?? '';
    final userName = authState.valueOrNull?.fullName ?? '';

    return disputedAsync.when(
      data: (requests) {
        return _buildSectionCard(
          icon: Iconsax.warning_2,
          title: l10n.translate('fuel.disputedRequests'),
          color: AppColors.error,
          children: [
            if (requests.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Center(
                  child: Text(
                    l10n.translate('fuel.noDisputedRequests'),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              )
            else
              ...requests.map((request) => _buildDisputedRequestCard(
                    l10n, request, userId, userName)),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (_, __) => InlineErrorRetry(
        onRetry: () => ref.invalidate(disputedRequestsStreamProvider),
      ),
    );
  }

  Widget _buildDisputedRequestCard(
    AppLocalizations l10n,
    FuelRequestModel request,
    String userId,
    String userName,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: truck + date
          Row(
            children: [
              const Icon(Iconsax.gas_station, color: AppColors.error, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '${request.truckImmatriculation} - ${request.requestedLiters.toStringAsFixed(0)} L',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  l10n.translate('fuelRequest.disputed'),
                  style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${request.requestedByName} • ${request.formattedDate} ${request.formattedTime}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          // Fulfilled info
          if (request.fulfilledLiters != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(Iconsax.drop, color: AppColors.info, size: 16),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '${l10n.translate('fuelRequest.servedLiters')}: ${request.fulfilledLiters!.toStringAsFixed(1)} L',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
          if (request.fulfilledByName != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${l10n.translate('fuelRequest.servedBy')}: ${request.fulfilledByName}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
          // Dispute reason
          if (request.disputeReason != null &&
              request.disputeReason!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border:
                    Border.all(color: AppColors.error.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Iconsax.message_question,
                      color: AppColors.error, size: 16),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.translate('fuel.disputeReasonLabel'),
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          request.disputeReason!,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (request.validatedByName != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${l10n.translate('fuel.disputedBy')}: ${request.validatedByName}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
          // Action buttons
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () =>
                    _showResolveDialog(request, userId, userName, false),
                child: Text(
                  l10n.translate('fuel.rejectDisputed'),
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              ElevatedButton(
                onPressed: () =>
                    _showResolveDialog(request, userId, userName, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                ),
                child: Text(
                  l10n.translate('fuel.validateDisputed'),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showResolveDialog(
    FuelRequestModel request,
    String userId,
    String userName,
    bool validate,
  ) async {
    final l10n = AppLocalizations.of(context);
    final noteController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text(
          validate
              ? l10n.translate('fuel.validateDisputedConfirm')
              : l10n.translate('fuel.rejectDisputedConfirm'),
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${request.truckImmatriculation} - ${request.fulfilledLiters?.toStringAsFixed(1) ?? '-'} L',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            if (request.disputeReason != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${l10n.translate('fuel.disputeReasonLabel')}: ${request.disputeReason}',
                style: const TextStyle(
                  color: AppColors.error,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: noteController,
              maxLines: 3,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: l10n.translate('fuel.resolutionNote'),
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: const BorderSide(color: AppColors.surfaceBorder),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.translate('common.cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  validate ? AppColors.success : AppColors.error,
            ),
            child: Text(
              validate
                  ? l10n.translate('fuel.validateDisputed')
                  : l10n.translate('fuel.rejectDisputed'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final repo = FuelRequestRepository();
    await repo.resolveDisputedRequest(
      requestId: request.id,
      resolvedBy: userId,
      resolvedByName: userName,
      validate: validate,
      resolutionNote: noteController.text.trim().isEmpty
          ? null
          : noteController.text.trim(),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('fuel.disputeResolved')),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required Color color,
    required List<Widget> children,
  }) {
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
              Icon(icon, color: color, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...children,
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
