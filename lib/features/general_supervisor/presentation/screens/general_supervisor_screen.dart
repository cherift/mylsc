import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/widgets/inline_error_retry.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../trips/domain/models/trip_model.dart';
import '../../../trips/presentation/providers/trip_providers.dart';
import '../../../shifts/presentation/providers/shift_providers.dart';
import '../../../breakdown/presentation/widgets/breakdown_alert_widget.dart';
import '../../../breakdown/presentation/providers/breakdown_providers.dart';

/// Écran du superviseur général - vue d'ensemble de toutes les flottes
class GeneralSupervisorScreen extends ConsumerStatefulWidget {
  const GeneralSupervisorScreen({super.key});

  @override
  ConsumerState<GeneralSupervisorScreen> createState() =>
      _GeneralSupervisorScreenState();
}

class _GeneralSupervisorScreenState
    extends ConsumerState<GeneralSupervisorScreen> {
  int _currentTab = 0;
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
                  child: _buildTabContent(l10n),
                ),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomNav(l10n),
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
              Iconsax.chart_square,
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
                  l10n.translate('users.roles.superviseurGeneral'),
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

  Widget _buildTabContent(AppLocalizations l10n) {
    switch (_currentTab) {
      case 0:
        return _buildOverviewTab(l10n);
      case 1:
        return _buildTripsTab(l10n);
      case 2:
        return _buildBreakdownsTab(l10n);
      default:
        return _buildOverviewTab(l10n);
    }
  }

  Widget _buildOverviewTab(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsRow(l10n),
          const SizedBox(height: AppSpacing.lg),
          const BreakdownAlertWidget(),
          const SizedBox(height: AppSpacing.lg),
          _buildActiveShiftsCount(l10n),
          const SizedBox(height: AppSpacing.lg),
          _buildRecentTripsSection(l10n),
        ],
      ),
    );
  }

  Widget _buildStatsRow(AppLocalizations l10n) {
    final shiftsAsync = ref.watch(activeShiftsStreamProvider);
    final breakdownsAsync = ref.watch(activeBreakdownsStreamProvider);
    final tripsAsync = ref.watch(allTripsStreamProvider);

    final activeShifts = shiftsAsync.valueOrNull?.length ?? 0;
    final activeBreakdowns = breakdownsAsync.valueOrNull?.length ?? 0;
    final totalTrips = tripsAsync.valueOrNull?.length ?? 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        if (isMobile) {
          final cardW = (constraints.maxWidth - AppSpacing.md) / 2;
          return Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              SizedBox(width: cardW, child: _buildStatCard(icon: Iconsax.people, label: l10n.translate('shift.activeShift'), value: '$activeShifts', color: AppColors.success)),
              SizedBox(width: cardW, child: _buildStatCard(icon: Iconsax.warning_2, label: l10n.translate('breakdown.activeBreakdowns'), value: '$activeBreakdowns', color: AppColors.error)),
              SizedBox(width: cardW, child: _buildStatCard(icon: Iconsax.repeat, label: l10n.translate('trip.title'), value: '$totalTrips', color: AppColors.primary)),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: _buildStatCard(icon: Iconsax.people, label: l10n.translate('shift.activeShift'), value: '$activeShifts', color: AppColors.success)),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _buildStatCard(icon: Iconsax.warning_2, label: l10n.translate('breakdown.activeBreakdowns'), value: '$activeBreakdowns', color: AppColors.error)),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _buildStatCard(icon: Iconsax.repeat, label: l10n.translate('trip.title'), value: '$totalTrips', color: AppColors.primary)),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveShiftsCount(AppLocalizations l10n) {
    final shiftsAsync = ref.watch(activeShiftsStreamProvider);

    return shiftsAsync.when(
      data: (shifts) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Iconsax.people,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${l10n.translate('shift.activeShift')} (${shifts.length})',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ...shifts.take(5).map((shift) => Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          '${shift.driverName} → ${shift.truckImmatriculation}',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (error, _) => InlineErrorRetry(
        onRetry: () => ref.invalidate(activeShiftsStreamProvider),
      ),
    );
  }

  Widget _buildRecentTripsSection(AppLocalizations l10n) {
    final tripsAsync = ref.watch(allTripsStreamProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Iconsax.repeat, color: AppColors.primary, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Text(
              l10n.translate('trip.title'),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        tripsAsync.when(
          data: (trips) {
            if (trips.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Center(
                  child: Text(
                    l10n.translate('trip.noTrips'),
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 14),
                  ),
                ),
              );
            }

            return Column(
              children: trips.take(10).map((trip) {
                final statusColor = _getTripStatusColor(trip.status);
                return Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(Iconsax.repeat, color: statusColor, size: 18),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${trip.truckImmatriculation} • ${trip.driverName}',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${trip.formattedDate} • ${trip.formattedNetTonnage}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          _getTripStatusLabel(l10n, trip.status),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (error, _) => InlineErrorRetry(
            onRetry: () => ref.invalidate(allTripsStreamProvider),
          ),
        ),
      ],
    );
  }

  Widget _buildTripsTab(AppLocalizations l10n) {
    final tripsAsync = ref.watch(allTripsStreamProvider);

    return tripsAsync.when(
      data: (trips) {
        if (trips.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Iconsax.repeat,
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                    size: 64),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.translate('trip.noTrips'),
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 18),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: trips.length,
          itemBuilder: (context, index) {
            final trip = trips[index];
            final statusColor = _getTripStatusColor(trip.status);
            return Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Row(
                children: [
                  Icon(Iconsax.repeat, color: statusColor, size: 18),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${trip.truckImmatriculation} • ${trip.driverName}',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${trip.formattedDate} ${trip.formattedTime} • ${trip.formattedNetTonnage}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      _getTripStatusLabel(l10n, trip.status),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (error, _) => Center(
        child: Text('${l10n.translate('common.error')}: $error',
            style: const TextStyle(color: AppColors.error)),
      ),
    );
  }

  Widget _buildBreakdownsTab(AppLocalizations l10n) {
    final breakdownsAsync = ref.watch(allBreakdownsStreamProvider);

    return breakdownsAsync.when(
      data: (breakdowns) {
        if (breakdowns.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Iconsax.tick_circle,
                    color: AppColors.success.withValues(alpha: 0.5),
                    size: 64),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.translate('breakdown.noBreakdowns'),
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 18),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: breakdowns.length,
          itemBuilder: (context, index) {
            final b = breakdowns[index];
            final severityColor = _getSeverityColor(b.severity);
            final statusColor = _getBreakdownStatusColor(b.status);
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${b.truckImmatriculation} • ${b.reportedByName}',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          b.description,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${b.formattedDate} ${b.formattedTime}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      _getBreakdownStatusLabel(l10n, b.status),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (error, _) => Center(
        child: Text('${l10n.translate('common.error')}: $error',
            style: const TextStyle(color: AppColors.error)),
      ),
    );
  }

  Color _getTripStatusColor(TripStatus status) {
    switch (status) {
      case TripStatus.inProgress:
        return AppColors.info;
      case TripStatus.pendingValidation:
        return AppColors.warning;
      case TripStatus.validated:
        return AppColors.success;
      case TripStatus.rejected:
        return AppColors.error;
    }
  }

  String _getTripStatusLabel(AppLocalizations l10n, TripStatus status) {
    switch (status) {
      case TripStatus.inProgress:
        return l10n.translate('trip.inProgress');
      case TripStatus.pendingValidation:
        return l10n.translate('trip.pendingValidation');
      case TripStatus.validated:
        return l10n.translate('trip.validated');
      case TripStatus.rejected:
        return l10n.translate('trip.rejected');
    }
  }

  Color _getSeverityColor(dynamic severity) {
    final name = severity.toString().split('.').last;
    switch (name) {
      case 'low':
        return AppColors.info;
      case 'medium':
        return AppColors.warning;
      case 'high':
        return AppColors.error;
      case 'critical':
        return const Color(0xFFB71C1C);
      default:
        return AppColors.warning;
    }
  }

  Color _getBreakdownStatusColor(dynamic status) {
    final name = status.toString().split('.').last;
    switch (name) {
      case 'pending':
        return AppColors.warning;
      case 'inDiagnostic':
        return AppColors.info;
      case 'inRepair':
        return AppColors.primary;
      case 'resolved':
        return AppColors.success;
      case 'closed':
        return AppColors.textSecondary;
      default:
        return AppColors.warning;
    }
  }

  String _getBreakdownStatusLabel(AppLocalizations l10n, dynamic status) {
    final name = status.toString().split('.').last;
    switch (name) {
      case 'pending':
        return l10n.translate('breakdown.pending');
      case 'inDiagnostic':
        return l10n.translate('breakdown.inDiagnostic');
      case 'inRepair':
        return l10n.translate('breakdown.inRepair');
      case 'resolved':
        return l10n.translate('breakdown.resolved');
      case 'closed':
        return l10n.translate('breakdown.closed');
      default:
        return name;
    }
  }

  Widget _buildBottomNav(AppLocalizations l10n) {
    return BottomNavigationBar(
      currentIndex: _currentTab,
      onTap: (index) => setState(() => _currentTab = index),
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.backgroundSecondary,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      selectedFontSize: 12,
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Iconsax.chart_square),
          label: l10n.translate('dashboard.overview'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Iconsax.repeat),
          label: l10n.translate('trip.title'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Iconsax.warning_2),
          label: l10n.translate('breakdown.title'),
        ),
      ],
    );
  }
}
